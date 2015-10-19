USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Match_Update]
(
	@Command VARCHAR(100),
	@MatchID INT,
	@FTHome SMALLINT = NULL,
	@FTAway SMALLINT = NULL,
	@HTHome SMALLINT = NULL,
	@HTAway SMALLINT = NULL,
	@BetStatus		NVARCHAR(50)= NULL,
	@GoalRecord		VARCHAR(50)	= NULL,
	@SelectedSet	VARCHAR(50)	= NULL, 
	@Action VARCHAR(10)			= NULL,
	@FTDone BIT = 0,
	@HTDone BIT = 0,
	@NoneCornerBetDone	BIT = 0, 
	@HTNoneCornerBetDone	BIT = 0,
	@isExcludeCorner	BIT = 0,
	@isExistRunningCornerBet BIT = 0,
	@RowCount INT = 0 OUTPUT,
	@Creator INT = 0
) 
AS
/*
	Created: Kathy
	Date: 20140213
	Task : Update information into match table (when run settlement)
	DB: DBPRO/bodb02
	Original: Admin_Match_Update

	Revisions:
		- 20140423@Kathy: Modify betstatus value (Offer 1H FGLG) [Redmine:#14449]
		- 20140618@Kathy: Remove PenaltyShootout string, correct betstatus in case match has been refunded [Redmine:#17142]  
		- 20140825@Kathy: Only update HT part of goalrecord when calculating HT
		- 20140912@Kathy: Correct betstatus when calculate FT '3x30' match [Redmine:#22399]
		- 20141013@Jamie: Sporting Solution for Tennis [Redmine:#23034]
		- 20150618@Jamie: Offer the option Exclude Corner tickets [Feature #38099]
		- 20150918@Johnson: Check status of corner tickets when settle FT [Redmine: #43806]
		
*/
BEGIN
	SET NOCOUNT ON 
	SET @BetStatus = ISNULL(@BetStatus, N'')
	
	IF @Command = 'NAP_Admin_Settlement_1-UNDO'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET  eventstatus	= CASE WHEN Sporttype = 5 AND @SelectedSet NOT LIKE '%6%' THEN eventstatus 
								   ELSE 'running' END 
			,finalhomescore = CASE WHEN Sporttype = 5 AND @SelectedSet NOT LIKE '%6%' THEN finalhomescore
								   ELSE NULL END 
			,finalawayscore = CASE WHEN Sporttype = 5 AND @SelectedSet NOT LIKE '%6%' THEN finalawayscore
								   ELSE NULL END 
			,hthomescore	= NULL
			,htawayscore	= NULL
			,betstatus		= CASE WHEN Sporttype = 5 AND @SelectedSet NOT LIKE '%6%' THEN @BetStatus
								   ELSE N'' END 
			,GoalRecord		= ''
			,changetime		= GETDATE(), settleTime = GETDATE()
		WHERE matchid = @MatchID-- and eventstatus = 'completed'
	END
	IF @Command = 'NAP_Admin_Settlement_1-CAL'
	BEGIN
		UPDATE dbo.match with (ROWLOCK,UPDLOCK)
		SET
			finalhomescore = @FTHome, finalawayscore = @FTAway,
			hthomescore = @HTHome, htawayscore = @HTAway,
		--	betstatus = CASE WHEN @action = 'CAL-FT' AND CHARINDEX('Refund HT;',betstatus)>0 THEN 'Refund HT;' + ISNULL(@betstatus,'') ELSE @betstatus END,
			betstatus = ISNULL(@betstatus,''),
			goalrecord = CASE WHEN @goalrecord IS NULL OR @goalrecord = '' THEN goalrecord 
							  WHEN @action = 'CAL-HT' AND ISNULL(GoalRecord,'') <> '' THEN REPLACE(GoalRecord,LEFT(GoalRecord,CHARINDEX(';',GoalRecord)),(LEFT(@goalrecord,CHARINDEX(';',@goalrecord)))) -- only update HT part
							  ELSE @goalrecord END,
			eventstatus = CASE	WHEN @action = 'CAL' AND Sporttype NOT IN (1,5)		THEN N'completed'
								WHEN @action = 'CAL' AND Sporttype = 1 AND @isExcludeCorner = 0 THEN N'completed'
								WHEN @action = 'CAL' AND Sporttype = 1 AND @isExcludeCorner = 1 AND @isExistRunningCornerBet = 0 THEN N'completed'
								WHEN @action = 'CAL' AND Sporttype = 5 AND @SelectedSet LIKE '%6%'THEN N'completed'
								WHEN @action = 'CAL-HT' AND @FTDone = 1 AND @isExcludeCorner = 0 THEN N'completed'
								WHEN @action = 'CAL-HT' AND @FTDone = 1 AND @isExcludeCorner = 1 AND @isExistRunningCornerBet = 0 THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1 AND @isExcludeCorner = 0 THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1 AND @isExcludeCorner = 1 AND @isExistRunningCornerBet = 0 THEN N'completed'								
							ELSE eventstatus END,
			changetime = GETDATE(),
			settleTime = CASE 
							WHEN @action = 'CAL' THEN GETDATE()
							WHEN @action = 'CAL-FT' THEN GETDATE()
							ELSE settleTime END	
		WHERE matchid = @MatchID
		
	END
	IF @Command = 'NAP_Admin_Settlement_Refund_All'
	BEGIN
		DECLARE @Sporttype INT 
		SELECT @betstatus = CASE WHEN charindex('PS:',betstatus) > 0 THEN STUFF(betstatus, CHARINDEX('PS:',betstatus),5,'') -- PS:Y; or PS:N;
								 ELSE ISNULL(betstatus,'')
							END
			,@Sporttype = sporttype
		FROM match with(NOLOCK)
		WHERE matchid = @matchid

		IF @sporttype <> 5 
		BEGIN
			UPDATE match WITH(ROWLOCK,UPDLOCK) 
			SET eventstatus='Completed', ruben=1, finalhomescore=0, finalawayscore=0, hthomescore=0, htawayscore=0 
				,betstatus = 'Refund;' + CASE  WHEN CHARINDEX('Refund;',@betstatus) > 0 THEN REPLACE(@betstatus,'Refund;','')
											WHEN CHARINDEX('Refund FT;',@betstatus) > 0 THEN REPLACE(@betstatus,'Refund FT;','')
											WHEN CHARINDEX('Refund HT;',@betstatus)>0 THEN REPLACE(@betstatus,'Refund HT;','')
											ELSE @betstatus
										END
				,GoalRecord =''
				,changetime = GETDATE(), settleTime = GETDATE()
			WHERE matchid=@MatchID
		END 
		ELSE 
		BEGIN
			IF @SelectedSet LIKE '%6%'
			BEGIN 
				SET @BetStatus =''
				DECLARE	@tmpSelectedSet	TABLE(
					 SetIndex	TINYINT IDENTITY(1,1)
					,Score		VARCHAR(10)
				)

				DECLARE	@tmpResultSet TABLE(
					 SetIndex	TINYINT	
					,Score		VARCHAR(10)
				)


				INSERT INTO @tmpSelectedSet(Score)
						  SELECT '0-0'
				UNION ALL SELECT '0-0'
				UNION ALL SELECT '0-0'
				UNION ALL SELECT '0-0'
				UNION ALL SELECT '0-0'


				INSERT INTO @tmpResultSet(SetIndex,Score)
				SELECT RIGHT(ResourceID,1),ISNULL(HomeValue,0) +'-'+ISNULL(AwayValue,0)
				FROM	ResultDetail WITH (NOLOCK)
				WHERE	matchID = @MatchID
						AND SettlementStatusID > 0
						AND ResourceID LIKE '0[1-5]'
				UPDATE	@tmpSelectedSet
				SET		Score = s2.Score 
				FROM	@tmpSelectedSet s
						INNER JOIN @tmpResultSet s2 ON s.SetIndex = s2.SetIndex 

				SELECT @betstatus= @betstatus + Score + ','
				FROM   @tmpSelectedSet

				IF RIGHT(@betstatus,1)=',' 
					SELECT @betstatus= LEFT(@betstatus,LEN(@betstatus)-1)

				IF	@betstatus='0-0,0-0,0-0,0-0,0-0' 
					SELECT @betstatus=''

			END


			UPDATE match WITH(ROWLOCK,UPDLOCK) 
			SET eventstatus= CASE WHEN @SelectedSet LIKE '%6%' THEN N'Completed'
								  ELSE eventstatus END 
				, ruben = CASE WHEN @SelectedSet LIKE '%6%' THEN 1 
							   ELSE ruben END  
				, finalhomescore= CASE WHEN @SelectedSet LIKE '%6%' THEN 0 
									   ELSE finalhomescore END 
				, finalawayscore= CASE WHEN @SelectedSet LIKE '%6%' THEN 0 
									   ELSE finalawayscore END	
				, hthomescore=0
				, htawayscore=0 
				,betstatus = CASE WHEN @SelectedSet LIKE '%6%' THEN 'Refund;'
								  ELSE '' END 
								+ CASE	WHEN CHARINDEX('Refund;',@betstatus) > 0 AND @SelectedSet LIKE '%6%' THEN REPLACE(@betstatus,'Refund;','')
										ELSE @betstatus END
				,GoalRecord =''
				,changetime = GETDATE(), settleTime = GETDATE()
			WHERE matchid=@MatchID
		END
	END
	IF @Command = 'NAP_Admin_Settlement_RefundFT'
	BEGIN
		SELECT @betstatus = CASE WHEN charindex('PS:',betstatus) > 0 THEN STUFF(betstatus, CHARINDEX('PS:',betstatus),5,'') -- PS:Y; or PS:N;
								 ELSE ISNULL(betstatus, '')
							END
		FROM match with(NOLOCK)
		WHERE matchid = @matchid

		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET finalhomescore=0, finalawayscore=0, 
			betstatus = CASE WHEN CHARINDEX('Refund;', @betstatus) > 0 
									THEN @betstatus 
							 ELSE 'Refund FT;' + CASE WHEN CHARINDEX('Refund HT;',@betstatus) > 0 
															THEN REPLACE(@betstatus, 'Refund HT;', '') 
													  ELSE REPLACE(@betstatus, 'Refund FT;', '')
												 END
						END,
			eventstatus = 'Completed', changetime = GETDATE(), settleTime = GETDATE()
		WHERE matchid=@MatchID AND @HTDone = 1

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	IF @Command = 'NAP_Admin_Settlement_RefundHT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET hthomescore=0, htawayscore=0, 
			betstatus = CASE WHEN CHARINDEX('Refund;', betstatus) > 0 
									THEN betstatus 
							 ELSE 'Refund HT;' + CASE WHEN CHARINDEX('Refund FT;',betstatus) > 0 
															THEN REPLACE(ISNULL(betstatus,''), 'Refund FT;', '') 
													  ELSE REPLACE(ISNULL(betstatus,''), 'Refund HT;', '')
												 END
						END,
			changetime = GETDATE()
		WHERE matchid=@MatchID

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	IF @Command = 'NAP_Admin_Settlement_FGLG'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK)
		SET	betstatus = case when right(@BetStatus,1) = ';' THEN @betstatus
							 ELSE @betstatus + ';'
						END
			,GoalRecord = CASE WHEN @goalrecord IS NULL OR @goalrecord = '' THEN goalrecord 
							   WHEN @action = 'CAL-HT' AND ISNULL(GoalRecord,'') <> '' THEN REPLACE(GoalRecord,LEFT(GoalRecord,CHARINDEX(';',GoalRecord)),(LEFT(@goalrecord,CHARINDEX(';',@goalrecord)))) -- only update HT part
							   ELSE @goalrecord 
						  END
			--,goalrecord = @GoalRecord
			,changetime = GETDATE()
		WHERE matchid = @MatchID
		
	END
	IF @Command = 'NAP_Admin_Settlement_Refund_FGLG'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK) SET betstatus = @BetStatus, changetime = GETDATE() WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_Parlay'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK) SET multiple=multiple, changetime = GETDATE() WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_135'
	BEGIN
		UPDATE dbo.match with(ROWLOCK, UPDLOCK)
		SET betstatus = CASE WHEN CHARINDEX('PS:',betstatus) > 0 THEN STUFF(betstatus, CHARINDEX('PS:',betstatus),5,@betstatus) -- PS:Y/N;
							 ELSE RTRIM(ISNULL(betstatus,''))  + @betstatus
						END
			,changetime = GETDATE()
			,settletime = GETDATE()
		WHERE matchid = @matchid
	END
	IF @Command = 'NAP_Admin_Settlement_Corner-CAL'
	BEGIN
		UPDATE dbo.Match WITH (UPDLOCK,ROWLOCK)
		SET		eventstatus = CASE WHEN @Action ='CAL' AND @NoneCornerBetDone = 1 THEN N'completed'
								   ELSE eventstatus END 
				,changetime = CURRENT_TIMESTAMP
				,settletime = CURRENT_TIMESTAMP
		WHERE MatchID = @MatchID 
	END
	IF @Command = 'NAP_Admin_Settlement_s161-Refund'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET betstatus = 'Refund',
			eventstatus = 'Completed', changetime = CURRENT_TIMESTAMP, settleTime = CURRENT_TIMESTAMP
		WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s161-Refund_FT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET eventstatus = 'Completed',
			betstatus = 'Refund FT',
			changetime = CURRENT_TIMESTAMP

		WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s161-CAL'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			betstatus = '',
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s162-Refund'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET betstatus = 'Refund',
			eventstatus = 'Completed', changetime = CURRENT_TIMESTAMP, settleTime = CURRENT_TIMESTAMP
		WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s162-CAL'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s162-1102-CAL'
	BEGIN
		select @BetStatus = Resource_en from RefResource with (rowlock) 
		where refid ='RouNumProperty' and 
		resourceid in (select Finalhomescore from  match with (rowlock) where matchid = @MatchID)
		
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			betstatus = @BetStatus,
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_SS-CAL'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_VS_181-CAL'
	BEGIN
		UPDATE dbo.VSRaceInfo WITH(ROWLOCK,UPDLOCK)
		SET					
			calculate = 1,
			eventstatus = 'Completed',
			betstatus = NULL ,
			changetime = CURRENT_TIMESTAMP
		WHERE EventID = @MatchID

		UPDATE [dbo].[VSOutright] WITH(ROWLOCK,UPDLOCK)
		SET					
			eventstatus = 'Completed',			
			changetime = CURRENT_TIMESTAMP
		WHERE EventID = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_VS_181-Refund'
	BEGIN
		UPDATE dbo.VSRaceInfo WITH(ROWLOCK,UPDLOCK)
		SET	
			betstatus = 'Refund',			
			eventstatus = 'Completed',
			calculate = 1,
			changetime = CURRENT_TIMESTAMP
		WHERE EventID = @MatchID

		UPDATE [dbo].[VSOutright] WITH(ROWLOCK,UPDLOCK)
		SET					
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP
		WHERE EventID = @MatchID
	END	
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Match_Update] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Match_Update] TO [vnteam] AS [dbo]