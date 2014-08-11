/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_9999]    Script Date: 08/07/2014 14:07:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_9999] @matchid INT
	,@bettype SMALLINT
	,@fth	INT = NULL
	,@fta	INT = NULL
	,@hth	INT = NULL
	,@hta	INT = NULL
	,@betcount INT = 0
	,@IsSettleAbandonedMatchIBC BIT = 0 -- IBC
	,@IsSettleAbandonedMatch BIT = 0 -- BetDaq
	,@IsSettleAbandonedMatchBetFair BIT = 0 -- BetFair
	,@IsHTCal BIT = 0
	,@isRefundHT BIT = 0
AS
/*
	Created by: Kathy
	Date: 20140618
	Task: Settlement for BetRadar [Redmine:#17142]
	DB: DBTXN.BODB02
	
	Revisions:
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]
		
*/
BEGIN
	SET NOCOUNT ON
	
	IF @betcount = 0 AND @@servername NOT LIKE N'DBIOM%' RETURN

	IF @@servername IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

	DECLARE @modds SMALLMONEY
		,@commWinRate SMALLMONEY
		,@commLostRate SMALLMONEY		
		,@csFT NVARCHAR(10) -- FT correct score
		,@csHT NVARCHAR(10) -- HT correct score
	
	SELECT @csHT =  CASE WHEN @hth + @hta >= 4 THEN '4+' 
						 ELSE CAST(@hth AS nvarchar(1)) + ':' + CAST(@hta AS nvarchar(1))
					END
		  ,@csFT =  CASE WHEN @fth + @fta >=4 THEN '4+'
					     ELSE CAST(@fth AS nvarchar(1)) + ':' + CAST(@fta AS nvarchar(1))
					END

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232') AND EXISTS (
			SELECT *
			FROM sys.databases
			WHERE NAME = 'LASDB'
			)
	BEGIN
		IF (@IsSettleAbandonedMatch = 0 AND @IsSettleAbandonedMatchBetFair = 0 ) or @IsSettleAbandonedMatchIBC = 1
		BEGIN
			DECLARE @LASCommand NVARCHAR(1000)
				,@createdDate DATETIME

			SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_9999] @matchid = ' + CONVERT(NVARCHAR(10), @matchid) 
																	+ ', @bettype = ' + CONVERT(NVARCHAR(10), @bettype) 
																	+ ', @fth = ' + convert(nvarchar(10),@fth) 
																	+ ', @fta = ' + convert(nvarchar(10),@fta) 
																	+ ', @hth = ' + convert(nvarchar(10),@hth) 
																	+ ', @hta = ' + convert(nvarchar(10),@hta) 
																	+ ', @betcount = ' + CONVERT(NVARCHAR(10), @betcount)
																	+ ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(10), @IsSettleAbandonedMatchIBC)
																	+ ', @IsHTCal = ' + CONVERT(NVARCHAR(10), @IsHTCal)
																	+ ', @IsRefundHT = ' + CONVERT(NVARCHAR(10), @IsRefundHT)
				,@createdDate = GETDATE()

			EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_9999'
				,@SQLCommand = @LASCommand
				,@CreatedDate = @createdDate
				,@StatusID = 0 -- waiting
				,@MatchID = @matchid
				,@Bettype = @bettype
				,@Status = 'waiting'
				,@BetCount = @betcount
		END
	END

	UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
	SET @modds = modds = CASE WHEN @IsSettleAbandonedMatch = 0 AND @IsSettleAbandonedMatchBetfair = 0 AND @IsSettleAbandonedMatchIBC = 0
								THEN CASE bettype
										WHEN 133 THEN -- Home To Win Both Halves
													 CASE 
														WHEN betteam = 'y' AND (@hth > @hta) AND ((@fth - @hth) > (@fta - @hta)) THEN 1
														WHEN betteam = 'n' AND ((@hth <= @hta) OR ((@fth - @hth) <= (@fta - @hta))) THEN 1
														ELSE -1
													  END
										WHEN 134 THEN -- Away To Win Both Halves
													 CASE 
														WHEN betteam = 'y' AND (@hta > @hth) AND ((@fta - @hta) > (@fth - @hth)) THEN 1
														WHEN betteam = 'n' AND ((@hta <=@hth) OR ((@fta - @hta) <= (@fth - @hth))) THEN 1
														ELSE -1
													  END		
										WHEN 140 THEN -- Highest Scoring Half
													 CASE 
														WHEN betteam = '1h' AND (@hth + @hta) > (@fth - @hth + @fta - @hta) THEN 1
														WHEN betteam = 'tie' AND (@hth + @hta) = (@fth - @hth + @fta - @hta) THEN 1
														WHEN betteam = '2h' AND (@hth + @hta) < (@fth - @hth + @fta - @hta) THEN 1
														ELSE -1
													 END		
										WHEN 141 THEN -- Highest Scoring Half Home Team
													 CASE 
														WHEN betteam = '1h' AND @hth > (@fth - @hth) THEN 1
														WHEN betteam = 'tie' AND @hth = (@fth - @hth) THEN 1
														WHEN betteam = '2h' AND @hth < (@fth - @hth) THEN 1
														ELSE -1
													 END			
										WHEN 142 THEN -- Highest Scoring Half Away Team
													 CASE 
														WHEN betteam = '1h' AND @hta > (@fta - @hta) THEN 1
														WHEN betteam = 'tie' AND @hta = (@fta - @hta) THEN 1
														WHEN betteam = '2h' AND @hta < (@fta - @hta) THEN 1
														ELSE -1
													 END  
										WHEN 145 THEN -- Both Teams To Score
													 CASE 
														WHEN betteam = 'y' AND (@fth > 0) AND (@fta > 0) THEN 1
														WHEN betteam = 'n' AND ((@fth = 0) OR (@fta = 0)) THEN 1
														ELSE -1
													 END 
										WHEN 146 THEN -- 2nd Half Both Teams To Score
													 CASE 
														WHEN betteam = 'y' AND (@fth - @hth) > 0 AND (@fta - @hta) > 0 THEN 1
														WHEN betteam = 'n' AND ((@fth - @hth) = 0 OR (@fta - @hta) = 0) THEN 1
														ELSE -1
													 END
										WHEN 147 THEN -- Home To Score In Both Halves 
													 CASE 
														WHEN betteam = 'y' AND @hth > 0 AND (@fth - @hth) > 0 THEN 1
														WHEN betteam = 'n' AND (@hth = 0 OR (@fth - @hth) = 0) THEN 1
														ELSE -1
													 END
										WHEN 148 THEN -- Away To Score In Both Halves 
													 CASE 
														WHEN betteam = 'y' AND @hta > 0 AND (@fta - @hta) > 0 THEN 1
														WHEN betteam = 'n' AND (@hta = 0 OR (@fta - @hta) = 0) THEN 1
														ELSE -1
													 END
										WHEN 149 THEN -- Home To Win Either Half 
													 CASE 
														WHEN betteam = 'y' AND ((@hth > @hta) OR (@fth - @hth) > (@fta - @hta)) THEN 1
														WHEN betteam = 'n' AND (@hth <= @hta) AND (@fth - @hth) <=(@fta - @hta) THEN 1
														ELSE -1
													 END
										WHEN 150 THEN -- Away To Win Either Half
													 CASE 
														WHEN betteam = 'y' AND ((@hta > @hth) OR (@fta - @hta) > (@fth - @hth)) THEN 1
														WHEN betteam = 'n' AND (@hta <= @hth) AND (@fta - @hta) <= (@fth - @hth) THEN 1
														ELSE -1
													 END 
										WHEN 152 THEN -- Half Time/Full Time Correct Score
													 CASE 
														WHEN betteam = @csHT + '/' + @csFT THEN 1
														ELSE -1
													 END 																
									 END											
							WHEN @IsSettleAbandonedMatch = 1 OR @IsSettleAbandonedMatchBetfair = 1 OR @IsSettleAbandonedMatchIBC = 1 
								THEN CASE bettype
										WHEN 133 THEN
													 CASE 
														WHEN betteam = 'y' AND @hth <= @hta THEN -1
														WHEN betteam = 'n' AND @hth <= @hta THEN 1
													 END
										WHEN 134 THEN
													 CASE
														WHEN betteam = 'y' AND @hta <= @hth THEN -1
														WHEN betteam = 'n' AND @hta <= @hth THEN 1
													 END
										WHEN 140 THEN 
													 CASE
														WHEN (betteam = '1h' OR betteam = 'tie') AND (@hth + @hta) < (@fth - @hth + @fta - @hta) THEN -1
														WHEN betteam = '2h' AND (@hth + @hta) < (@fth - @hth + @fta - @hta) THEN 1 
													 END
										WHEN 141 THEN
													 CASE
														WHEN (betteam = '1h' OR betteam = 'tie') AND @hth < (@fth - @hth) THEN -1
														WHEN betteam = '2h' AND @hth < (@fth - @hth) THEN 1
													 END
										WHEN 142 THEN 
													 CASE 
														WHEN (betteam = '1h' OR betteam = 'tie') AND @hta < (@fta - @hta) THEN -1
														WHEN betteam = '2h' AND @hta < (@fta - @hta) THEN 1
													 END 
										WHEN 145 THEN 
													 CASE 
														WHEN @IsHTCal = 1 OR @IsRefundHT = 1 THEN -- suspended in 2nd half/ 3x30 match
																				CASE 
																					WHEN betteam = 'y' AND @fth > 0 AND @fta > 0 THEN 1
																					WHEN betteam = 'n' AND @fth > 0 AND @fta > 0 THEN -1
																				END
														WHEN @IsHTCal = 0 THEN -- suspended in 1st half
																				CASE  
																					WHEN betteam = 'y' AND @hth > 0 AND @hta > 0 THEN 1
																					WHEN betteam = 'n' AND @hth > 0 AND @hta > 0 THEN -1
																				END
													 END 
										WHEN 146 THEN 
													 CASE 
														WHEN betteam = 'y' AND (@fth - @hth) > 0 AND (@fta - @hta) > 0 THEN 1
														WHEN betteam = 'n' AND (@fth - @hth) > 0 AND (@fta - @hta) > 0 THEN -1
													 END
										WHEN 147 THEN 
													 CASE 
														WHEN betteam = 'y' AND @hth = 0 THEN -1
														WHEN betteam = 'n' AND @hth = 0 THEN 1
														WHEN betteam = 'y' AND @hth > 0 and (@fth - @hth) > 0 THEN 1
														WHEN betteam = 'n' AND @hth > 0 and (@fth - @hth) > 0 THEN -1
													 END
										WHEN 148 THEN 
													 CASE
														WHEN betteam = 'y' AND @hta = 0 THEN -1
														WHEN betteam = 'n' AND @hta = 0 THEN 1
														WHEN betteam = 'y' AND @hta > 0 AND (@fta - @hta) > 0 THEN 1
														WHEN betteam = 'n' AND @hta > 0 AND (@fta - @hta) > 0 THEN -1 
													 END
										WHEN 149 THEN 
													 CASE 
														WHEN betteam = 'y' AND @hth > @hta THEN 1
														WHEN betteam = 'n' AND @hth > @hta THEN -1
													 END
										WHEN 150 THEN 
													 CASE 
														WHEN betteam = 'y' AND @hta > @hth THEN 1
														WHEN betteam = 'n' AND @hta > @hth THEN -1
													 END
										WHEN 152 THEN
													 CASE 
														WHEN @IsHTCal = 0 AND @IsRefundHT = 0 THEN 
																									CASE
																										WHEN LEFT(betteam,2) = '4+' AND (@hth + @hta) >= 4 THEN 1
																										WHEN LEFT(betteam,2) <> '4+' AND (LEFT(LEFT(betteam,3),1) < @hth OR RIGHT(LEFT(betteam,3),1) < @hta) THEN -1
																									END
														ELSE CASE 
																WHEN betteam = '4+/4+' AND (@hth + @hta) >= 4 AND (@fth + @fta) >= 4 THEN 1
																WHEN LEFT(betteam,3) <> @csHT  THEN -1		
																WHEN RIGHT(betteam,2) = '4+' AND (@fth + @fta) >= 4 THEN 1
																WHEN RIGHT(betteam,2) <>'4+' AND (LEFT(RIGHT(betteam,3),1) < @fth OR RIGHT(RIGHT(betteam,3),1) < @fta) THEN -1																																																
															 END
													END													
									 END
						END										
		,@commWinRate = CASE comstatus
			WHEN '0' THEN 1 -- 0: pay normal, both win/lost -- 1: pay 'double' ONLY on lost
			WHEN '1' THEN 0
			ELSE 1
			END
		,@commLostRate = CASE comstatus
			WHEN '0' THEN 1
			WHEN '1' THEN 2
			ELSE 1
			END
		,winlost = CASE 
			WHEN @modds > 0 THEN actual_stake + stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE CASE 
							WHEN bettype IN (133, 134, 140, 141, 142, 145, 146, 147, 148, 149, 150, 152) THEN odds - 1
							ELSE odds 
							END
					END
				)
			WHEN @modds < 0 THEN 0
			END
		,aWinLost = CASE 
			WHEN @modds > 0 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE CASE 
							WHEN bettype IN (133, 134, 140, 141, 142, 145, 146, 147, 148, 149, 150, 152) THEN odds - 1
							ELSE odds
							END
					END
					) * - apositiontaking
			WHEN @modds < 0 THEN actual_stake * apositiontaking
			END
		,mWinLost = CASE 
			WHEN @modds > 0 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE CASE 
							WHEN bettype IN (133, 134, 140, 141, 142, 145, 146, 147, 148, 149, 150, 152) THEN odds - 1
							ELSE odds 
							END
					END
					) * - mpositiontaking
			WHEN @modds < 0 THEN actual_stake * mpositiontaking
			END
		,sWinLost = CASE 
			WHEN @modds > 0 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE CASE 
							WHEN bettype IN (133, 134, 140, 141, 142, 145, 146, 147, 148, 149, 150, 152) THEN odds - 1
							ELSE odds 
							END
					END
					) * - spositiontaking
			WHEN @modds < 0 THEN actual_stake * spositiontaking
			END
		,PlayerComm = CASE 
			WHEN @modds > 0 THEN @commWinRate * playerdiscount * stake
			WHEN @modds < 0 THEN @commLostRate * playerdiscount * stake
			END
		,Comm = CASE 
			WHEN @modds > 0 THEN @commWinRate * discount * stake * (1 - apositiontaking)
			WHEN @modds < 0 THEN @commLostRate * discount * stake * (1 - apositiontaking)
			END
		,aComm = CASE 
			WHEN @modds > 0 THEN @commWinRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
			WHEN @modds < 0 THEN @commLostRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
			END
		,sComm = CASE 
			WHEN @modds > 0 THEN @commWinRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
			WHEN @modds < 0 THEN @commLostRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
			END
		,STATUS = CASE 
			WHEN @modds > 0 THEN 'WON'
			WHEN @modds < 0 THEN 'LOSE'
			END
		,StatusID = CASE 
			WHEN @modds > 0 THEN 112 --WON
			WHEN @modds < 0 THEN 113 --LOSE
			END
		,ruben = 1
	WHERE matchid = @matchid 
	AND bettype = @bettype 
	AND statusID NOT IN (101, 102) -- reject, void
	AND 1 = CASE WHEN @IsSettleAbandonedMatch = 0 AND @IsSettleAbandonedMatchBetFair = 0 AND @IsSettleAbandonedMatchIBC = 0 
						AND ((@isRefundHT = 1 AND bettype IN (145)) -- settle only bettype 145 when match has been refunded HT
								OR ( @isRefundHT = 0 AND bettype IN (133, 134, 140, 141, 142, 145, 146, 147, 148, 149, 150, 152)) 
							)
					THEN 1
				 WHEN (
						(@IsSettleAbandonedMatch = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156))
						OR (@IsSettleAbandonedMatchBetFair = 1 AND custid IN (2331, 1077687, 115770, 15523642))
						OR (@IsSettleAbandonedMatchIBC = 1 AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) AND recommend <> 1688156))
					)			
					THEN CASE WHEN @IsHTCal = 0 -- Suspended in 1st Half
									AND 
									(
										(bettype = 145 AND @hth > 0 AND @hta > 0) 
										OR (bettype = 152 AND (											
																	(LEFT(betteam,2) = '4+' AND (@hth + @hta) >=4)
																	OR 
																	(LEFT(betteam,2) <> '4+' AND (LEFT(LEFT(betteam,3),1) < @hth OR RIGHT(LEFT(betteam,3),1) < @hta))
																) 
											)
									)
								 THEN 1
							  WHEN @isRefundHT = 1 -- 3x30 match: refundHT, Settle determined ticket
									AND bettype = 145
									AND @fth > 0 AND @fta > 0
								 THEN 1
							  WHEN @IsHTCal = 1 -- suspended in 2nd Half
									AND 1 = CASE WHEN bettype = 133 AND @hth <= @hta THEN 1
												WHEN bettype = 134 AND @hta <= @hth THEN 1
												WHEN bettype = 140 AND (@hth + @hta) < (@fth - @hth + @fta - @hta) THEN 1
												WHEN bettype = 141 AND @hth < (@fth - @hth) THEN 1
												WHEN bettype = 142 AND @hta < (@fta - @hta) THEN 1
												WHEN bettype = 145 AND @fth > 0 AND @fta > 0 THEN 1
												WHEN bettype = 146 AND (@fth - @hth) > 0 AND (@fta - @hta) > 0 THEN 1
												WHEN bettype = 147 AND ((@hth = 0) OR (@hth > 0 AND (@fth - @hth) > 0)) THEN 1
												WHEN bettype = 148 AND ((@hta = 0) OR (@hta > 0 AND (@fta - @hta) > 0)) THEN 1
												WHEN bettype = 149 AND @hth > @hta THEN 1
												WHEN bettype = 150 AND @hta > @hth THEN 1
												WHEN bettype = 152 
													AND ( 
																(betteam = '4+/4+' AND (@hth + @hta) >= 4 AND (@fth + @fta) >= 4) 
																OR
																(LEFT(betteam,3) <> @csHT )
																OR
																(RIGHT(betteam,2) = '4+' AND (@fth + @fta) >= 4)
																OR
																(RIGHT(betteam,2) <>'4+' AND (LEFT(RIGHT(betteam,3),1) < @fth OR RIGHT(RIGHT(betteam,3),1) < @fta))
															)
														
														THEN 1 
												ELSE 0
											END 
								 THEN 1							 
							  ELSE 0
						 END
				 ELSE 0
			END 
END





GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_9999] TO [vnteam] AS [dbo]