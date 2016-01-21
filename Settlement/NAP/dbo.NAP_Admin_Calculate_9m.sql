ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_9m] @matchid INT
	,@fth INT = NULL
	,@fta INT = NULL
	,@hth INT = NULL
	,@hta INT = NULL
	,@matchdate DATETIME
	,@action VARCHAR(10) = 'CAL'
	,@resultPS NVARCHAR(10) = NULL -- PS:Y/N;
	,@IsRefundHT BIT = 0
	,@TennisTotal TINYINT = NULL
	,@VoidTransID VARCHAR(2000) = ''
	,@UserID INT = 0
	,@mode INT = 0
	,-- new parameter, remove once already convert to new version
	-- 0 : original version, 1 : new version
	@strXML VARCHAR(MAX) = '' OUTPUT
	,@statusID TINYINT = 0
	,@winlostdate SMALLDATETIME = NULL 
	,@SelectedSet			VARCHAR(50) = NULL 
	,@TotalGameMatch		INT = NULL
	,@TotalGameHomeMatch	INT = NULL
	,@TotalGameAwayMatch	INT	= NULL 
	,@TotalGameHomeSet1		INT	= NULL 
	,@TotalGameHomeSet2		INT = NULL 
	,@TotalGameHomeSet3		INT = NULL 
	,@TotalGameHomeSet4		INT = NULL 
	,@TotalGameHomeSet5		INT = NULL 
	,@TotalGameAwaySet1		INT = NULL 
	,@TotalGameAwaySet2		INT = NULL 
	,@TotalGameAwaySet3		INT = NULL 
	,@TotalGameAwaySet4		INT = NULL 
	,@TotalGameAwaySet5		INT = NULL 
	,@SetxGameyHomeWON		VARCHAR(MAX) = NULL 
	,@SetxGameyAwayWON		VARCHAR(MAX) = NULL 
	,@SetxGameyDRAW			VARCHAR(MAX) = NULL 
	,@SetxGameyFinishedGame	VARCHAR(MAX) = NULL 	
	,@SetxGameyREFUND		VARCHAR(MAX) = NULL 
	,@SelectedSetCAL		VARCHAR(50)  = NULL
	,@SelectedSetREFUND		VARCHAR(50)  = NULL 

	,@GoalSequence			VARCHAR(50) = NULL 
	,@fthCorners			INT = NULL 
	,@ftaCorners			INT = NULL 
	,@hthCorners			INT = NULL 
	,@htaCorners			INT = NULL 	
	,@FTFCorner				VARCHAR(10)	= NULL 
	,@FTLCorner				VARCHAR(10)	= NULL 
	,@HTFCorner				VARCHAR(10)	= NULL 
	,@HTLCorner				VARCHAR(10)	= NULL
	,@penaltyshootout		VARCHAR(10)	= NULL	-- Betradar 2 - Auto BETS 
	,@matchDecidedMethod	VARCHAR(10)	= NULL
	,@1st10Min1x2			VARCHAR(10)	= NULL
	,@1stGoalTime10Min		VARCHAR(10)	= NULL
	,@1stGoalTime15Min		VARCHAR(10)	= NULL
	,@WhoAdvancesNextRound	VARCHAR(10) = NULL
	,@ExtraTimeandGoal		VARCHAR(10)	= NULL
	,@ExtraTimeYN			VARCHAR(10) = NULL
	,@PlayerSentOff			VARCHAR(10) = NULL
	,@HTPlayerSentOff		VARCHAR(10) = NULL
	,@PlayerSentOffHome		VARCHAR(10) = NULL
	,@HTPlayerSentOffHome	VARCHAR(10) = NULL
	,@PlayerSentOffAway		VARCHAR(10) = NULL
	,@HTPlayerSentOffAway	VARCHAR(10) = NULL
	,@GoalScorerFirst		VARCHAR(10) = NULL				
	,@1HNextGoal			VARCHAR(MAX)= NULL
	,@NextGoal				VARCHAR(MAX)= NULL
	,@NextGoalTime15Min		VARCHAR(MAX)= NULL
	,@ExtraNextGoal			VARCHAR(MAX)= NULL
	,@GoalScorerAnytime		VARCHAR(MAX)= NULL
	,@ResourceIDsCAL		VARCHAR(MAX)= NULL
	,@ResourceIDsREFUND		VARCHAR(MAX)= NULL
	,@ResourceIDs			VARCHAR(MAX)= NULL
WITH RECOMPILE
AS
/*
	Created by: Kathy
	Date: 20140213
	Task: Calculate Mix Parlay 
	DB: DBTRANS.BODB02
	Original: Admin_Calculate_9m
	
	Revision:
		- 20140426@Kathy: Add 1H Total Goal and 1H FGLG bettypes (126, 127) [Redmine:#14449]
		- 20140623@Kathy: Apply BetRadar [Redmine:#17142]
		- 20140720@Kathy: Apply BetRadar - PenaltyShootout(135) [Redmine:#17142]
		- 20140811@Kathy: Support new 11 bettypes [Redmine:#19667]
		- 20140820@Jamie: Correct bettype 143, 144 [Redmine:#19667]
		- 20140909@Kathy: Exclude virtual racing (bettype 1231,1232,1233, 1237, 1238), outright (bettype 10, 31, 32, 33), 
							sportting solution (from 1301 -> 1334), keno (1501 -> 1599)
		- 20141023@Jamie: Sporting Solution for Tennis [Redmine:#23034]
		- 20141204@Jamie: Sportting Solution settlement - Change rule Set x Correct Score [Redmine:#23034]
		- 20150407@Kathy: Don't update 'waiting' ticket when do "Undo" action [Redmine:#33493]
		- 20150206@Jamie: Auto Settlement Betradar phase 2 [Redmine: #27212]
		- 20150505@Jamie: Converting error [HotFix #35259]
		- 20150608@Kathy: Add more mode Recover for recover parlay tickets [Redmine:#35539]
		- 20151019@Kathy: Refund HT/FT & 2nd FT bettypes in case of match 3x30 [Redmine:#45626]
		- 20151124@Patrick: Apply 28 Live Bettypes for Settlement [Redmine:#47843]
		- 20151210@Patrick: Database - Change datatype [Redmine: #48660]
		- 20160120@Patrick: PH-AiO - Change request [Redmine: #51116]

	Param's Explanation:
		@IsRefundHT: whether or not match has been refunded HT
		@resultPS: match result of penalty shootout
*/
BEGIN
	IF @@SERVERNAME IN ('DB042', 'DB043', 'DB044') RETURN


	IF @mode = 1
	BEGIN
		DECLARE @odds MONEY
		DECLARE @commWinRate SMALLMONEY
				,@commLostRate SMALLMONEY
		DECLARE @oldstatusID TINYINT
				,@oldwinlost MONEY
				,@winlost MONEY
		DECLARE @xml XML

		-- get modds from XML string [edited by viet @ 20121213]
		SET @xml = convert(XML, @strXML)

		DECLARE @cal_modds AS TABLE (
			transid BIGINT PRIMARY KEY
			,modds MONEY
			,loseCnt TINYINT
			)

		INSERT INTO @cal_modds (
			transid
			,modds
			,loseCnt
			)
		SELECT T.C.value('./@t', 'bigint')
			,-- transid
			isnull(T.C.value('./@m', 'money'), 0)
			,-- modds
			isnull(T.C.value('./@l', 'tinyint'), 0) -- lostCnt
		FROM @xml.nodes('/root/r') AS T(C)

		UPDATE T
		SET statusID = @statusID
			,[status] = CASE @statusID
				WHEN 0 THEN 'running'
				WHEN 103 THEN 'Refund'
				WHEN 111 THEN 'DRAW'
				WHEN 112 THEN 'WON'
				WHEN 113 THEN 'LOSE'
				END
			,ruben = CASE @statusID
				WHEN 0 THEN 0
				ELSE 1
				END
			,winlostdate = @winlostdate
			,@odds = CASE 
				WHEN loseCnt > 0 THEN 0
				WHEN @statusID = 0 THEN 0
				ELSE m.modds
				END
			,modds = @odds
			,@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
				WHEN '0' THEN 1
				WHEN '1' THEN 0
				ELSE 1
				END
			,@commLostRate = CASE comstatus
				WHEN '0' THEN 1
				WHEN '1' THEN 2
				ELSE 1
				END
			,@winlost = winlost = CASE 
				WHEN loseCnt > 0 THEN 0
				WHEN @statusID = 0 THEN 0
				ELSE stake * @odds
				END
			,awinlost = CASE 
				WHEN @statusID = 113 AND loseCnt > 0 THEN stake * apositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * apositiontaking * (@odds - 1)
				ELSE 0
				END
			,mwinlost = CASE 
				WHEN @statusID = 113 AND loseCnt > 0 THEN stake * mpositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * mpositiontaking * (@odds - 1)
				ELSE 0
				END
			,swinlost = CASE 
				WHEN @statusID = 113 AND loseCnt > 0 THEN stake * spositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * spositiontaking * (@odds - 1)
				ELSE 0
				END
			,playercomm = CASE @statusID
				WHEN 112 THEN @commWinRate * stake * playerdiscount
				WHEN 113 THEN @commLostRate * stake * playerdiscount
				ELSE 0
				END
			,comm = CASE @statusID
				WHEN 112 THEN @commWinRate * discount * stake * (1 - apositiontaking)
				WHEN 113 THEN @commLostRate * discount * stake * (1 - apositiontaking)
				ELSE 0
				END
			,acomm = CASE @statusID
				WHEN 112 THEN @commWinRate * adiscount * stake * (1 - apositiontaking - mpositiontaking)
				WHEN 113 THEN @commLostRate * adiscount * stake * (1 - apositiontaking - mpositiontaking)
				ELSE 0
				END
			,scomm = CASE @statusID
				WHEN 112 THEN @commWinRate * sdiscount * stake * (1 - apositiontaking - mpositiontaking - spositiontaking)
				WHEN 113 THEN @commLostRate * sdiscount * stake * (1 - apositiontaking - mpositiontaking - spositiontaking)
				ELSE 0
				END
		FROM dbo.bettrans T
			INNER JOIN @cal_modds m ON T.transid = m.transid

		RETURN
	END -- IF @mode = 1

	-------------------------------------------------------------------------
	-------------------------------------------------------------------------
	DECLARE @modds MONEY

	UPDATE BM
	SET bettype = o.bettype
	FROM dbo.bettransm BM WITH (UPDLOCK)
		INNER JOIN dbo.odds o WITH (NOLOCK) ON BM.oddsid = o.oddsid
	WHERE BM.matchid = @matchid AND BM.bettype <> o.bettype

	-- ===================================================
	IF @action = 'REFUND'
	BEGIN
		UPDATE dbo.bettransm
		SET winlostdate = @matchdate
			,[status] = 'Refund'
			,statuswinlost = 0
			,ruben = 1
			,statusID = 103
		WHERE matchid = @matchid 
		AND bettype NOT IN (14, 127) 
		AND statusID NOT IN (101, 102)
		AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		--AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
		AND 1 = CASE WHEN @SelectedSetREFUND IS NULL AND @SelectedSetCAL IS NULL THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%1%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '801%' THEN 1  --Exclude 1324
					 WHEN @SelectedSetREFUND LIKE '%2%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '802%' THEN 1
					 WHEN @SelectedSetREFUND LIKE '%3%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '803%' THEN 1
					 WHEN @SelectedSetREFUND LIKE '%4%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '804%' THEN 1
					 WHEN @SelectedSetREFUND LIKE '%5%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '805%' THEN 1
					 WHEN @SelectedSetREFUND LIKE '%6%' AND Bettype IN (1,2,3,20,153,1301,1302,1303,1305,1306,1308) THEN 1 
					 ELSE 0 END
		AND bettype NOT BETWEEN 1501 and 1599 -- Keno
		AND 1 = CASE WHEN @ResourceIDsREFUND IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1  
				WHEN @ResourceIDsREFUND IS NOT NULL 
					AND Bettype IN (160,164,169,180) 
					AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(20)),2,5),@ResourceIDsREFUND)>0 THEN 1 
			WHEN @ResourceIDsREFUND IS NOT NULL 
						AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) 
						AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDsREFUND)>0 THEN 1 
			ELSE 0 END   --Betradar 2 Auto Bettype
		

		UPDATE dbo.BetParlayDetail
		SET winlostdate = @matchdate
			,statuswinlost = 0
			,statusID = 103
		WHERE matchid = @matchid 
		AND bettype NOT IN (14, 127) 
		AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		--AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
		AND 1 = CASE WHEN @SelectedSetREFUND IS NULL AND @SelectedSetCAL IS NULL THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%1%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '801%' THEN 1  --Exclude 1324
					 WHEN @SelectedSetREFUND LIKE '%2%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '802%' THEN 1
					 WHEN @SelectedSetREFUND LIKE '%3%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '803%' THEN 1
					 WHEN @SelectedSetREFUND LIKE '%4%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '804%' THEN 1
					 WHEN @SelectedSetREFUND LIKE '%5%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318) AND betcheck LIKE '805%' THEN 1
					 WHEN @SelectedSetREFUND LIKE '%6%' AND Bettype IN (1,2,3,20,153,1301,1302,1303,1305,1306,1308) THEN 1 
					 ELSE 0 END
		AND bettype NOT BETWEEN 1501 and 1599 -- Keno
		AND statusID NOT IN (101, 102)
		AND 1 = CASE WHEN @ResourceIDsREFUND IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1  
				WHEN @ResourceIDsREFUND IS NOT NULL 
					AND Bettype IN (160,164,169,180) 
					AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(20)),2,5),@ResourceIDsREFUND)>0 THEN 1 
			WHEN @ResourceIDsREFUND IS NOT NULL 
						AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) 
						AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDsREFUND)>0 THEN 1 
			ELSE 0 END   --Betradar 2 Auto Bettype
		
	END
			-- ===================================================
	ELSE IF @action = 'REFUND-FT'
	BEGIN
		UPDATE dbo.bettransm
		SET winlostdate = @matchdate
			,[status] = 'Refund'
			,statuswinlost = 0
			,ruben = 1
			,statusID = 103
		WHERE matchid = @matchid 
		AND bettype NOT IN (7, 8, 12, 15, 21, 30, 14, 126, 127, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209,403,404,410,411,412,414) 
		AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
		AND bettype NOT BETWEEN 1501 and 1599 -- Keno
		AND statusID NOT IN (101, 102)
		AND 1 = CASE WHEN @ResourceIDsREFUND IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1  
				WHEN @ResourceIDsREFUND IS NOT NULL 
					AND Bettype IN (160,164,169,180) 
					AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(20)),2,5),@ResourceIDsREFUND)>0 THEN 1 
			WHEN @ResourceIDsREFUND IS NOT NULL 
						AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) 
						AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDsREFUND)>0 THEN 1 
			ELSE 0 END   --Betradar 2 Auto Bettype

		UPDATE dbo.BetParlayDetail
		SET winlostdate = @matchdate
			,statuswinlost = 0
			,statusID = 103
		WHERE matchid = @matchid 
		AND bettype NOT IN (7, 8, 12, 15, 21, 30, 14, 126, 127, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209,403,404,410,411,412,414) 
		AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
		AND bettype NOT BETWEEN 1501 and 1599 -- Keno
		AND statusID NOT IN (101, 102)
		AND 1 = CASE WHEN @ResourceIDsREFUND IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1  
				WHEN @ResourceIDsREFUND IS NOT NULL 
					AND Bettype IN (160,164,169,180) 
					AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(20)),2,5),@ResourceIDsREFUND)>0 THEN 1 
			WHEN @ResourceIDsREFUND IS NOT NULL 
						AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) 
						AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDsREFUND)>0 THEN 1 
			ELSE 0 END   --Betradar 2 Auto Bettype
	END
	ELSE IF @action = 'REFUND-HT'
	BEGIN
		-- Refund sub tickets of 11 bet types (FT) from BetRadar in case '30x3' match has been suspended
		UPDATE dbo.bettransm
		SET winlostdate = @matchdate
			,[status] = 'Refund'
			,statuswinlost = 0
			,ruben = 1
			,statusID = 103
		WHERE matchid = @matchid 
		AND (bettype IN (7, 8, 12, 15, 21, 30, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209,403,404,410,411,412,414) 
				OR (bettype IN (16, 128, 133, 134, 140, 141, 142, 146, 147, 148, 149, 150, 152,177,178,183,184,185,186,187,189,190,405) AND @IsRefundHT = 1)
			)
		AND statusID NOT IN (101, 102)
		AND 1 = CASE WHEN @ResourceIDsREFUND IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1  
				WHEN @ResourceIDsREFUND IS NOT NULL 
					AND Bettype IN (160,164,169,180) 
					AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(20)),2,5),@ResourceIDsREFUND)>0 THEN 1 
			WHEN @ResourceIDsREFUND IS NOT NULL 
						AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) 
						AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDsREFUND)>0 THEN 1 
			ELSE 0 END   --Betradar 2 Auto Bettypes 

		UPDATE dbo.BetParlayDetail
		SET winlostdate = @matchdate
			,statuswinlost = 0
			,statusID = 103
		WHERE matchid = @matchid 
		AND (bettype IN (7, 8, 12, 15, 21, 30, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209,403,404,410,411,412,414) 
				OR (bettype IN (16, 128, 133, 134, 140, 141, 142, 146, 147, 148, 149, 150, 152,177,178,183,184,185,186,187,189,190,405) AND @IsRefundHT = 1)
			)
		AND statusID NOT IN (101, 102)
		AND 1 = CASE WHEN @ResourceIDsREFUND IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1  
				WHEN @ResourceIDsREFUND IS NOT NULL 
					AND Bettype IN (160,164,169,180) 
					AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(20)),2,5),@ResourceIDsREFUND)>0 THEN 1 
			WHEN @ResourceIDsREFUND IS NOT NULL 
						AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) 
						AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDsREFUND)>0 THEN 1 
			ELSE 0 END   --Betradar 2 Auto Bettype

	END
			-- ===================================================
	ELSE IF @action = 'VOID'
	BEGIN
		DECLARE @transtbl TABLE (transid BIGINT)

		INSERT INTO @transtbl
		SELECT CONVERT(BIGINT, val)
		FROM dbo.strSplit(@VoidTransID, ',')

		UPDATE dbo.bettransm
		SET winlost = CASE 
				WHEN odds > 0 THEN stake
				ELSE stake * ABS(odds)
				END
			,ruben = 1
			,statuswinlost = 0
			,STATUS = 'VOID'
			,creator = @UserID
			,statusID = 102
			,winlostdate = @matchdate
		WHERE matchid = @matchid AND statusID NOT IN (101, 102) AND transid IN (
				SELECT transid
				FROM @transtbl
				)

		UPDATE dbo.BetParlayDetail
		SET statuswinlost = 0
			,statusID = 102
			,winlostdate = @matchdate
		WHERE matchid = @matchid AND statusID NOT IN (101, 102) AND transid IN (
				SELECT transid
				FROM @transtbl
				)
	END
	ELSE IF @action = 'RECOVER'
	BEGIN
		DECLARE @tblTransIds TABLE (transid BIGINT)
		
		INSERT INTO @tblTransIds
		SELECT CONVERT(BIGINT, val)
		FROM dbo.strSplit(@VoidTransId, ',')
		
		UPDATE dbo.bettransm WITH (ROWLOCK, UPDLOCK)
			SET	winlost = 0
				,ruben = 0
				,statuswinlost = NULL
				,status = 'running'
				,statusID = 0
				,winlostdate = NULL
		WHERE	matchid = @matchid
				AND statusID = 102
				AND transid IN (SELECT transid FROM @tblTransIds)
				
		
		UPDATE	dbo.BetParlayDetail WITH(ROWLOCK, UPDLOCK)
			SET winlostdate = NULL
				,statuswinlost = NULL
				,statusid = 0
		WHERE	matchid = @matchid 
				AND statusID = 102
				AND transid IN (SELECT transid FROM @tblTransIds)
		
	END
			-- ===================================================
	ELSE IF @action = 'UNDO'
	BEGIN
		UPDATE dbo.bettransm
		SET [status] = 'running'
			,statuswinlost = 0
			,ruben = 0
			,statusID = 0
		WHERE matchid = @matchid 
		AND statusID NOT IN (101, 102, 1)
		AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		AND bettype NOT BETWEEN 1501 and 1599 -- Keno
		AND 1 = CASE WHEN @SelectedSet IS NULL THEN 1 
					 WHEN @SelectedSet LIKE '%1%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '801%' THEN 1 
					 WHEN @SelectedSet LIKE '%2%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '802%' THEN 1
					 WHEN @SelectedSet LIKE '%3%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '803%' THEN 1
					 WHEN @SelectedSet LIKE '%4%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '804%' THEN 1
					 WHEN @SelectedSet LIKE '%5%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '805%' THEN 1
					 WHEN @SelectedSet LIKE '%6%' AND Bettype IN (1,2,3,20,153,1301,1302,1303,1305,1306,1308) THEN 1 
					 ELSE 0 END
		AND 1 = CASE WHEN @ResourceIDs IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1 
					 WHEN @ResourceIDs IS NOT NULL AND Bettype IN (160,164,169,180) AND CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(20)),2,5),@ResourceIDs)>0 THEN 1 
					 WHEN @ResourceIDs IS NOT NULL AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDs)>0 THEN 1 
					 ELSE 0 END 

		UPDATE dbo.BetParlayDetail
		SET statuswinlost = 0
			,statusID = 0
		WHERE matchid = @matchid 
		AND statusID NOT IN (101, 102)
		AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		AND bettype NOT BETWEEN 1501 and 1599 -- Keno
		AND 1 = CASE WHEN @SelectedSet IS NULL THEN 1 
					 WHEN @SelectedSet LIKE '%1%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '801%' THEN 1 
					 WHEN @SelectedSet LIKE '%2%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '802%' THEN 1
					 WHEN @SelectedSet LIKE '%3%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '803%' THEN 1
					 WHEN @SelectedSet LIKE '%4%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '804%' THEN 1
					 WHEN @SelectedSet LIKE '%5%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '805%' THEN 1
					 WHEN @SelectedSet LIKE '%6%' AND Bettype IN (1,2,3,20,153,1301,1302,1303,1305,1306,1308) THEN 1 
					 ELSE 0 END
		AND 1 = CASE WHEN @ResourceIDs IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1 
					 WHEN @ResourceIDs IS NOT NULL AND Bettype IN (160,164,169,180) AND CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(20)),2,5),@ResourceIDs)>0 THEN 1 
					 WHEN @ResourceIDs IS NOT NULL AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDs)>0 THEN 1 
					 ELSE 0 END 
	END
			-- ===================================================
			-- ===================================================
	ELSE IF @action = 'CAL'
	BEGIN
		DECLARE  @csHTFT NVARCHAR(10) -- HT/FT correct score
	
		SELECT @csHTFT = CASE WHEN @hth + @hta >= 4 THEN '4+' 
							ELSE CAST(@hth AS nvarchar(10)) + ':' + CAST(@hta AS nvarchar(10))
							END 
					+ '/'
					+ CASE WHEN @fth + @fta >=4 THEN '4+'
						    ELSE CAST(@fth AS nvarchar(10)) + ':' + CAST(@fta AS nvarchar(10))
							END
		DECLARE @FirstGoal NVARCHAR(50) 
		SELECT	@FirstGoal=''
		SELECT	@FirstGoal = LEFT(REPLACE(ISNULL(@GoalSequence,''),';',''),1) --172  --@GoalSequence = GoalRecord 

		DECLARE	 @TotalGameHomeSetx	INT
				,@TotalGameAwaySetx INT  
				,@isRefundGame	BIT 

		UPDATE dbo.bettransm WITH (UPDLOCK)
		SET 
			 @isRefundGame	= CASE WHEN  Bettype = 1324 AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(10)),2,4),@SetxGameyREFUND)>0 THEN 1 ELSE 0 END 
			,@TotalGameHomeSetx	= CASE WHEN betCheck = '801' THEN @TotalGameHomeSet1
									   WHEN betCheck = '802' THEN @TotalGameHomeSet2
									   WHEN betCheck = '803' THEN @TotalGameHomeSet3
									   WHEN betCheck = '804' THEN @TotalGameHomeSet4
									   WHEN betCheck = '805' THEN @TotalGameHomeSet5
									   ELSE @TotalGameHomeSetx 
									   END 
			,@TotalGameAwaySetx = CASE WHEN betCheck = '801' THEN @TotalGameAwaySet1
									   WHEN betCheck = '802' THEN @TotalGameAwaySet2
									   WHEN betCheck = '803' THEN @TotalGameAwaySet3
									   WHEN betCheck = '804' THEN @TotalGameAwaySet4
									   WHEN betCheck = '805' THEN @TotalGameAwaySet5
									   ELSE @TotalGameAwaySetx
									   END 
			,@modds = CASE bettype
				WHEN 1 THEN -- Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
						END
				WHEN 7 THEN -- 1st Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@hth - livehomescore) - (@hta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
						END
				WHEN 3 THEN -- Over/Under
					CASE betteam
						WHEN N'h' THEN (CASE 
								WHEN ISNULL(@TennisTotal,0)=0 THEN @fth + @fta
								ELSE @TennisTotal END
								) - hdp1
						WHEN N'a' THEN hdp1 - (CASE 
								WHEN ISNULL(@TennisTotal,0)=0 THEN @fth + @fta
								ELSE @TennisTotal END
								)
						END
				WHEN 8 THEN -- 1st Over/Under
					CASE betteam
						WHEN N'h' THEN (@hth + @hta) - hdp1
						WHEN N'a' THEN hdp1 - (@hth + @hta)
						END
				WHEN 2 THEN -- Odd/Even
					CASE 
						WHEN (betteam = N'h') AND (
								(CASE 
									WHEN ISNULL(@TennisTotal,0)=0 THEN @fth + @fta
									ELSE @TennisTotal END
									) & 1 = 1
								) THEN 1
						WHEN (betteam = N'a') AND (
								(CASE 
									WHEN ISNULL(@TennisTotal,0)=0 THEN @fth + @fta
									ELSE @TennisTotal END
									) & 1 = 0
								) THEN 1
						ELSE - 1
						END
				WHEN 12 THEN -- 1st Odd/Even
					CASE 
						WHEN (betteam = N'h') AND ((@hth + @hta) & 1 = 1) THEN 1
						WHEN (betteam = N'a') AND ((@hth + @hta) & 1 = 0) THEN 1
						ELSE - 1
						END
				WHEN 4 THEN -- Correct Score
					CASE 
						WHEN betteam = (CAST(@fth AS VARCHAR(4)) + ':' + CAST(@fta AS VARCHAR(4))) THEN 1
						WHEN betteam = '5:0' AND (@fth - @fta) >= 5 THEN 1
						WHEN betteam = '0:5' AND (@fth - @fta) <= - 5 THEN 1
						ELSE - 1
						END
				WHEN 30 THEN -- 1st Correct Score
					CASE 
						WHEN betteam = (CAST(@hth AS VARCHAR(4)) + ':' + CAST(@hta AS VARCHAR(4))) THEN 1
						WHEN betteam = '4:0' AND (@hth - @hta) >= 4 THEN 1 -- 4UP for 1st Correct Score
						WHEN betteam = '0:4' AND (@hth - @hta) <= - 4 THEN 1 -- 4UP for 1st Correct Score
						WHEN betteam = '5:0' AND (@hth - @hta) >= 5 THEN 1
						WHEN betteam = '0:5' AND (@hth - @hta) <= - 5 THEN 1
						ELSE - 1
						END
				
				WHEN 16 THEN -- HT/FT
					CASE 
						WHEN betteam = CASE 
								WHEN @hth = @hta THEN '0'
								WHEN @hth > @hta THEN '1'
								ELSE '2'
								END + ':' + CASE 
								WHEN @fth = @fta THEN '0'
								WHEN @fth > @fta THEN '1'
								ELSE '2'
								END THEN 1
						ELSE - 1
						END
				WHEN 5 THEN -- 1x2
					CASE 
						WHEN (betteam = N'1') AND (@fth > @fta) THEN 1
						WHEN (betteam = N'2') AND (@fta > @fth) THEN 1
						WHEN (betteam = N'x') AND (@fth = @fta) THEN 1
						ELSE - 1
						END
				WHEN 15 THEN -- 1st 1x2
					CASE 
						WHEN (betteam = N'1') AND (@hth > @hta) THEN 1
						WHEN (betteam = N'2') AND (@hta > @hth) THEN 1
						WHEN (betteam = N'x') AND (@hth = @hta) THEN 1
						ELSE - 1
						END
				WHEN 6 THEN -- Total Goal
					CASE 
						WHEN (CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END >= cast(left(betteam, 1) AS INT) AND CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END <= (CASE 
									WHEN right(betteam, 1) = 'r' THEN 999
									ELSE cast(right(betteam, 1) AS INT) END
									)
								) THEN 1
						ELSE - 1
						END
				WHEN 126 THEN -- 1H total goal
					CASE WHEN (
								CASE WHEN @TennisTotal IS NULL THEN @hth + @hta ELSE @TennisTotal END >= CAST(LEFT(betteam,1) AS int) AND
								CASE WHEN @TennisTotal IS NULL then @hth + @hta ELSE @TennisTotal END <= (
									CASE when RIGHT(betteam,1)= 'r' then 999 ELSE CAST(RIGHT(betteam,1)AS int) END 
									)
							) then 1 ELSE -1 END 
				WHEN 13 THEN -- Clean Sheet
					CASE 
						WHEN betteam = 'hy' AND @fta = 0 THEN 1
						WHEN betteam = 'hn' AND @fta > 0 THEN 1
						WHEN betteam = 'ay' AND @fth = 0 THEN 1
						WHEN betteam = 'an' AND @fth > 0 THEN 1
						ELSE - 1
						END
				WHEN 20 THEN -- Money Line
					CASE betteam
						WHEN N'h' THEN @fth - @fta
						ELSE @fta - @fth
						END
				WHEN 21 THEN -- 1st Money Line
					CASE betteam
						WHEN N'h' THEN @hth - @hta
						ELSE @hta - @hth
						END
				WHEN 24 THEN -- Double Chance
					CASE 
						WHEN betteam = '1X' AND (@fth - @fta) >= 0 THEN 1
						WHEN betteam = '2X' AND (@fth - @fta) <= 0 THEN 1
						WHEN betteam = '12' AND (@fth - @fta) <> 0 THEN 1
						ELSE - 1
						END
				WHEN 25 THEN -- Draw No Bet
					CASE 
						WHEN (@fth - @fta) = 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE - 1
						END
				WHEN 26 THEN -- Both/One/Neither team to score
					CASE 
						WHEN betteam = 'b' AND (@fth > 0 AND @fta > 0) THEN 1
						WHEN betteam = 'o' AND ((@fth > 0 AND @fta = 0) OR (@fta > 0 AND @fth = 0)) THEN 1
						WHEN betteam = 'n' AND (@fth = 0 AND @fta = 0) THEN 1
						ELSE - 1
						END
				WHEN 27 THEN -- To win to nil
					CASE 
						WHEN betteam = 'h' AND (@fth > @fta AND @fta = 0) THEN 1
						WHEN betteam = 'a' AND (@fta > @fth AND @fth = 0) THEN 1
						ELSE - 1
						END
				WHEN 28 THEN -- 3-way handicap
					CASE 
						WHEN betteam = '1' AND (hdp2 - hdp1 + @fth - @fta) > 0 THEN 1
						WHEN betteam = '2' AND (hdp1 - hdp2 + @fta - @fth) > 0 THEN 1
						WHEN betteam = 'x' AND ((hdp1 - hdp2) - (@fth - @fta)) = 0 THEN 1
						ELSE - 1
						END
				WHEN 121 THEN -- home no bet
					CASE 
						WHEN (@fth - @fta) > 0 THEN 0
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE - 1
						END
				WHEN 122 THEN -- away no bet
					CASE 
						WHEN (@fth - @fta) < 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						ELSE - 1
						END
				WHEN 123 THEN -- draw/no draw
					CASE 
						WHEN betteam = 'h' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) <> 0 THEN 1
						ELSE - 1
						END
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
				WHEN 151 THEN -- 1st Half Double Chance
					CASE 
						WHEN betteam = '1x' AND (@hth - @hta) >= 0 THEN 1
						WHEN betteam = '2x' AND (@hta - @hth) >= 0 THEN 1
						WHEN betteam = '12' AND (@hth - @hta) <> 0 THEN 1
						ELSE -1
						END
				WHEN 152 THEN -- Half Time/Full Time Correct Score
					CASE 
						WHEN betteam = @csHTFT THEN 1
						ELSE -1
						END 
				WHEN 135 THEN -- Penalty Shootout
					CASE 
						WHEN betteam = @penaltyshootout THEN 1
						ELSE -1
						END		
				WHEN 128 THEN -- HT/FT Odd/Even
					CASE
						WHEN betteam = 'oo' AND (@hth + @hta) % 2 = 1 AND (@fth + @fta) % 2 = 1 THEN 1
						WHEN betteam = 'oe' AND (@hth + @hta) % 2 = 1 AND (@fth + @fta) % 2 = 0 THEN 1
						WHEN betteam = 'eo' AND (@hth + @hta) % 2 = 0 AND (@fth + @fta) % 2 = 1 THEN 1
						WHEN betteam = 'ee' AND (@hth + @hta) % 2 = 0 AND (@fth + @fta) % 2 = 0 THEN 1
						ELSE -1
						END				
				WHEN 129 THEN -- 1H Exact Goal
					CASE
						WHEN betteam = '5&over' AND (@hth + @hta) >= 5 THEN 1
						WHEN betteam <> '5&over' AND cast(betteam as INT) = (@hth + @hta) THEN 1
						ELSE -1
						END
				WHEN 130 THEN --  Exact Goal
					CASE 
						WHEN betteam = '7&over' AND (@fth + @fta) >= 7 THEN 1
						WHEN betteam <> '7&over' AND cast(betteam AS INT) = (@fth + @fta) THEN 1
						ELSE -1
						END
				WHEN 131 THEN -- Home Team Total Goal 
					CASE
						WHEN cast(LEFT(betteam,1) as INT) <= @fth 
							AND case when right(betteam,1) = 'r' 
										then 999 
									 else cast(RIGHT(betteam,1) as int) 
									 END >= @fth THEN 1
						ELSE -1
						END		
				WHEN 132 THEN -- Away Team Total Goal
					CASE 
						WHEN cast(left(betteam,1) as int) <= @fta	
							AND case when right(betteam,1) = 'r'
										then 999
									 else cast(right(betteam,1) as int)
									 END >= @fta THEN 1
						ELSE -1
						END
				WHEN 136 THEN -- 1H Home Team Odd/Even			
					CASE	
						WHEN betteam = 'o' and (@hth % 2) = 1 THEN 1
						WHEN betteam = 'e' and (@hth % 2) = 0 THEN 1
						ELSE -1
						END
				WHEN 137 THEN -- Home Team Odd/Even
					CASE
						WHEN betteam = 'o' and (@fth % 2) = 1 THEN 1
						WHEN betteam = 'e' and (@fth % 2) = 0 THEN 1
						ELSE -1
						END 
				WHEN 138 THEN -- 1H Away Team Odd/Even 			
					CASE	
						WHEN betteam = 'o' and (@hta % 2) = 1 THEN 1
						WHEN betteam = 'e' and (@hta % 2) = 0 THEN 1
						ELSE -1
						END
				WHEN 139 THEN -- Away Team Odd/Even
					CASE
						WHEN betteam = 'o' and (@fta % 2) = 1 THEN 1
						WHEN betteam = 'e' and (@fta % 2) = 0 THEN 1
						ELSE -1
						END 
				WHEN 143 THEN -- 1H Result/Total Goals
					CASE
						WHEN betteam = 'ho' and (@hth - @hta) > 0 THEN (@hth+ @hta) - hdp1
						WHEN betteam = 'hu' and (@hth - @hta) > 0 THEN hdp1 - (@hth+ @hta) 
						WHEN betteam = 'ao' and (@hth - @hta) < 0 THEN (@hth+ @hta) - hdp1
						WHEN betteam = 'au' and (@hth - @hta) < 0 THEN hdp1 - (@hth+ @hta) 
						WHEN betteam = 'do' and (@hth - @hta) = 0 THEN (@hth+ @hta) - hdp1
						WHEN betteam = 'du' AND (@hth - @hta) = 0 THEN hdp1 - (@hth+ @hta) 
						ELSE -1
						END		
				WHEN 144 THEN -- Result/Total Goals
					CASE
						WHEN betteam = 'ho' and (@fth - @fta) > 0 THEN (@fth+ @fta) - hdp1
						WHEN betteam = 'hu' and (@fth - @fta) > 0 THEN hdp1 - (@fth+ @fta)
						WHEN betteam = 'ao' and (@fth - @fta) < 0 THEN (@fth+ @fta) - hdp1
						WHEN betteam = 'au' and (@fth - @fta) < 0 THEN hdp1 - (@fth+ @fta)
						WHEN betteam = 'do' and (@fth - @fta) = 0 THEN (@fth+ @fta) - hdp1
						WHEN betteam = 'du' AND (@fth - @fta) = 0 THEN hdp1 - (@fth+ @fta)
						ELSE -1
						END		
				-- Tennis New bet types 		
				WHEN 153 THEN -- Match Games Handicap
					CASE betteam 
						WHEN N'h' THEN (hdp2 - hdp1) + (@TotalGameHomeMatch - livehomescore) - (@TotalGameAwayMatch - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@TotalGameHomeMatch - livehomescore) + (@TotalGameAwayMatch - liveawayscore)
						END 
				WHEN 154 THEN -- Set x Winner
					CASE betteam 
						WHEN N'h' THEN (@TotalGameHomeSetx - @TotalGameAwaySetx)
						WHEN N'a' THEN (@TotalGameAwaySetx - @TotalGameHomeSetx)
						END 
				WHEN 155 THEN -- Set x Game Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@TotalGameHomeSetx - livehomescore) - (@TotalGameAwaySetx - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@TotalGameHomeSetx - livehomescore) + (@TotalGameAwaySetx - liveawayscore)
						END
				WHEN 156 THEN --Set x Total Games Over/Under 
					CASE betteam 
						WHEN N'o' THEN (@TotalGameHomeSetx + @TotalGameAwaySetx) - hdp1 
						WHEN N'u' THEN hdp1 - (@TotalGameHomeSetx + @TotalGameAwaySetx) 
						END
				-- Betradar 2 
				WHEN 160 THEN 
					CASE WHEN CHARINDEX((SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,5) + betteam),@NextGoal)> 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 164 THEN 
					CASE WHEN CHARINDEX((SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,5) + betteam),@ExtraNextGoal)> 0 THEN 1 
						 ELSE - 1 
						 END

				WHEN 168 THEN 
					CASE WHEN Betteam = @WhoAdvancesNextRound THEN 1 
						 ELSE - 1
						 END 
				WHEN 169 THEN 
					CASE WHEN CHARINDEX((SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,5) + betteam),@NextGoalTime15Min)> 0 THEN 1 
						 ELSE - 1 
						 END
				WHEN 173 THEN 
					CASE WHEN Betteam = @ExtraTimeYN THEN 1 
						 ELSE - 1
						 END 

				WHEN 174 THEN 
					CASE WHEN Betteam = @ExtraTimeandGoal THEN 1 
						 ELSE - 1
						 END 
				WHEN 175 THEN 
					CASE WHEN Betteam = @matchDecidedMethod THEN 1 
						 ELSE - 1
						 END 

				WHEN 176 THEN 
					CASE WHEN Betteam = @1st10Min1x2 THEN 1 
						 ELSE - 1
						 END 

				WHEN 180 THEN 
					CASE WHEN CHARINDEX((SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,5) + betteam),@1HNextGoal)> 0 THEN 1 
						 ELSE - 1 
						 END
				WHEN 192 THEN 
					CASE WHEN Betteam = @1stGoalTime10Min THEN 1 
						 ELSE - 1
						 END 
				WHEN 193 THEN 
					CASE WHEN Betteam = @1stGoalTime15Min THEN 1 
						 ELSE - 1
						 END 
				WHEN 210 THEN 
					CASE WHEN Betteam = @PlayerSentOff THEN 1 
						 ELSE - 1
						 END 
				WHEN 211 THEN 
					CASE WHEN Betteam = @HTPlayerSentOff THEN 1 
						 ELSE - 1
						 END 
				WHEN 212 THEN 
					CASE WHEN Betteam = @PlayerSentOffHome THEN 1 
						 ELSE - 1
						 END 

				WHEN 213 THEN 
					CASE WHEN Betteam = @HTPlayerSentOffHome THEN 1 
						 ELSE - 1
						 END 

				WHEN 214 THEN 
					CASE WHEN Betteam = @PlayerSentOffAway THEN 1 
						 ELSE - 1
						 END 

				WHEN 215 THEN 
					CASE WHEN Betteam = @HTPlayerSentOffAway THEN 1 
						 ELSE - 1
						 END 

				WHEN 216 THEN 
					CASE WHEN CHARINDEX(betteam,@GoalScorerAnytime)>0 THEN 1 
						 ELSE - 1
						 END 

				WHEN 217 THEN 
					CASE WHEN Betteam = @GoalScorerFirst THEN 1 
						 ELSE - 1
						 END 

				-- Betradar 2 Manual Bettype 
				WHEN 157 THEN 
					CASE WHEN betteam =N'h' AND ((@fth + @fta) &1) = 1 THEN 1 
						 WHEN betteam =N'a' AND ((@fth + @fta) &1) = 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 159 THEN 
					CASE WHEN betteam LIKE 'G[0-5]' AND ((@fth + @fta) = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G6' AND ((@fth + @fta) >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 161 THEN 
					CASE WHEN betteam LIKE 'G[0-2]' AND (@fth = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G3' AND (@fth >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 162 THEN 
					CASE WHEN betteam LIKE 'G[0-2]' AND (@fta = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G3' AND (@fta >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 163 THEN 
					CASE WHEN betteam = 'ho' AND (@fth -@fta) > 0 THEN (@fth + @fta) - hdp1
						 WHEN betteam = 'hu' AND (@fth -@fta) > 0 THEN hdp1 - (@fth + @fta)
						 WHEN betteam = 'ao' AND (@fth -@fta) < 0 THEN (@fth + @fta) - hdp1
						 WHEN betteam = 'au' AND (@fth -@fta) < 0 THEN hdp1 - (@fth + @fta)
						 WHEN betteam = 'do' AND (@fth -@fta) = 0 THEN (@fth + @fta) - hdp1
						 WHEN betteam = 'du' AND (@fth -@fta) = 0 THEN hdp1 - (@fth + @fta)	
						 ELSE -1 
						 END 
				WHEN 165 THEN 
					CASE 
						WHEN betteam = (CAST(@hth AS VARCHAR(4)) + ':' + CAST(@hta AS VARCHAR(4))) THEN 1
						ELSE - 1
						END				
				WHEN 166 THEN 
					CASE 
						WHEN betteam = (CAST(@fth AS VARCHAR(4)) + ':' + CAST(@fta AS VARCHAR(4))) THEN 1
						ELSE - 1
						END	
				WHEN 167 THEN 
					CASE 
						WHEN (betteam = N'1') AND (@fth > @fta) THEN 1
						WHEN (betteam = N'2') AND (@fta > @fth) THEN 1
						WHEN (betteam = N'x') AND (@fth = @fta) THEN 1
						ELSE - 1
						END
				WHEN 170 THEN		
					CASE 
						WHEN betteam =N'h' AND (@fth > 0 AND @fta = 0) THEN 1
						WHEN betteam =N'a' AND (@fth = 0 AND @fta > 0) THEN 1
						WHEN betteam =N'b' AND (@fth > 0 AND @fta > 0) THEN 1
						WHEN betteam =N'n' AND (@fth = 0 AND @fta = 0) THEN 1
						ELSE -1
						END 
				WHEN 171 THEN	
					CASE 
						WHEN betteam = 'h1' AND (@fth -@fta) = 1 THEN 1		--171 
						WHEN betteam = 'h2' AND (@fth -@fta) = 2 THEN 1 
						WHEN betteam = 'h3' AND (@fth -@fta) >=3 THEN 1 
						WHEN betteam = 'd' AND (@fth -@fta) =0 THEN 1 
						WHEN betteam = 'a1' AND (@fth -@fta) =-1 THEN 1 
						WHEN betteam = 'a2' AND (@fth -@fta) =-2 THEN 1 
						WHEN betteam = 'a3' AND (@fth -@fta)<=-3 THEN 1 
						ELSE - 1					
						END
				WHEN 172 THEN	
					CASE 
						WHEN betteam = 'HH' AND @FirstGoal='H' AND (@fth - @fta) >0 THEN 1 
						WHEN betteam = 'DH' AND @FirstGoal='H' AND (@fth - @fta) =0 THEN 1
						WHEN betteam = 'AH' AND @FirstGoal='H' AND (@fth - @fta) <0 THEN 1
						WHEN betteam = 'HA' AND @FirstGoal='A' AND (@fth - @fta) >0 THEN 1
						WHEN betteam = 'DA' AND @FirstGoal='A' AND (@fth - @fta) =0 THEN 1
						WHEN betteam = 'AA' AND @FirstGoal='A' AND (@fth - @fta) <0 THEN 1
						WHEN betteam = 'NO' AND @fth =0 AND @fta= 0 THEN 1
						ELSE - 1
						END
				WHEN 177 THEN	
					CASE 
						WHEN (betteam = N'1') AND ((@fth -@hth) -(@fta - @hta))>0 THEN 1
						WHEN (betteam = N'2') AND ((@fth -@hth) -(@fta - @hta))<0 THEN 1
						WHEN (betteam = N'x') AND ((@fth -@hth) -(@fta - @hta))=0 THEN 1
						ELSE - 1
						END
				WHEN 178 THEN 
					CASE betteam 
						WHEN N'o' THEN ((@fth + @fta) - (@hth + @hta)) - hdp1 
						WHEN N'u' THEN hdp1 - ((@fth + @fta) - (@hth + @hta)) 
						END
				WHEN 179 THEN 
					CASE 
						WHEN betteam LIKE 'G[0-3]' AND (@hth + @hta) = CAST(RIGHT(betteam,1)AS TINYINT) THEN 1 
						WHEN betteam ='G4' AND (@hth + @hta) >=CAST(RIGHT(betteam,1)AS TINYINT) THEN 1 
						ELSE -1
						END 
				WHEN 181 THEN 
					CASE 
						 WHEN betteam LIKE 'G[0-2]' AND (@hth = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G3' AND (@hth >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 182 THEN 
					CASE 
						 WHEN betteam LIKE 'G[0-2]' AND (@hta = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G3' AND (@hta >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 183 THEN 
					CASE 
						WHEN betteam =N'h' THEN (hdp2 - hdp1) + ((@fth - @hth) - livehomescore) - ((@fta - @hta) - liveawayscore)
						WHEN betteam =N'a' THEN (hdp1 - hdp2) - ((@fth - @hth) - livehomescore) + ((@fta - @hta) - liveawayscore)
						END
				WHEN 184 THEN 
					CASE WHEN betteam =N'o' AND ((@fth + @fta - @hth - @hta) &1) = 1 THEN 1 
						 WHEN betteam =N'e' AND ((@fth + @fta - @hth - @hta) &1) = 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 185 THEN -- Draw No Bet
					CASE 
						WHEN ((@fth -@hth) -(@fta - @hta)) = 0 THEN 0
						WHEN betteam = 'h' AND ((@fth -@hth) -(@fta - @hta)) > 0 THEN 1
						WHEN betteam = 'a' AND ((@fth -@hth) -(@fta - @hta)) < 0 THEN 1
						ELSE - 1
						END
				WHEN 186 THEN -- Double Chance
					CASE 
						WHEN betteam = 'HD' AND ((@fth -@hth) -(@fta - @hta)) >= 0 THEN 1
						WHEN betteam = 'DA' AND ((@fth -@hth) -(@fta - @hta)) <= 0 THEN 1
						WHEN betteam = 'HA' AND ((@fth -@hth) -(@fta - @hta)) <> 0 THEN 1
						ELSE - 1
						END
				WHEN 187 THEN
					CASE 
						WHEN betteam LIKE 'G[0-1]' AND ((@fth + @fta) - (@hth + @hta)) = CAST(RIGHT(betteam,1)AS TINYINT) THEN 1
						WHEN betteam ='G2'AND ((@fth + @fta) - (@hth + @hta)) >=CAST(RIGHT(betteam,1)AS TINYINT) THEN 1
						ELSE - 1
						END
				WHEN 188 THEN 
					CASE 
						WHEN betteam = 'Y' AND @hth > 0 AND @hta > 0 THEN 1 
						WHEN betteam = 'N' AND (@hth = 0 OR @hta = 0) THEN 1 
						ELSE - 1
						END
				WHEN 189 THEN	
					CASE 
						WHEN betteam ='y' AND (@hth + @hta - 1.5) > 0 AND ((@fth-@hth) + (@fta -@hta) - 1.5)>0 THEN 1 
						WHEN betteam ='n' AND ((@hth + @hta - 1.5) <=0 OR ((@fth-@hth) + (@fta -@hta) - 1.5)<=0) THEN 1 
						ELSE -1 
						END  
				WHEN 190 THEN -- Both Halves Under 1.5 Yes/No  [190]
					CASE 
						WHEN betteam ='y' AND (@hth + @hta - 1.5) < 0 AND ((@fth-@hth) + (@fta -@hta) - 1.5)<0 THEN 1  
						WHEN betteam ='n' AND ((@hth + @hta - 1.5) >=0 OR ((@fth-@hth) + (@fta -@hta) - 1.5)>=0) THEN 1 
						ELSE -1 
					END	
				WHEN 191 THEN 
					CASE 
						WHEN (@hth - @hta) = 0 THEN 0
						WHEN betteam = 'h' AND (@hth - @hta) > 0 THEN 1
						WHEN betteam = 'a' AND (@hth - @hta) < 0 THEN 1
						ELSE -1
						END
				WHEN 194 THEN
					CASE 
						WHEN betteam =N'o' AND ((@fthCorners + @ftaCorners) &1) = 1 THEN 1 
						WHEN betteam =N'e' AND ((@fthCorners + @ftaCorners) &1) = 0 THEN 1 
						ELSE - 1 
						END   
				WHEN 195 THEN 
					CASE 
						WHEN betteam = '0-2' AND @fthCorners <=2 THEN 1			
						WHEN betteam = '3-4' AND @fthCorners IN (3, 4) THEN 1	
						WHEN betteam = '5-6' AND @fthCorners IN(5, 6) THEN 1	
						WHEN betteam = '7-over' AND @fthCorners >= 7 THEN 1		
						ELSE -1
						END 
				WHEN 196 THEN 
					CASE 
						WHEN betteam = '0-2' AND @ftaCorners <=2 THEN 1			
						WHEN betteam = '3-4' AND @ftaCorners IN (3, 4) THEN 1	
						WHEN betteam = '5-6' AND @ftaCorners IN(5, 6) THEN 1	
						WHEN betteam = '7-over' AND @ftaCorners >= 7 THEN 1		
						ELSE -1
						END 
				WHEN 197 THEN 
					CASE	
						WHEN betteam = N'o' THEN @fthCorners-hdp1	
						WHEN betteam = N'u' THEN hdp1-@fthCorners	
						ELSE -1
						END
				WHEN 198 THEN
					CASE	
						WHEN betteam = N'o' THEN @ftaCorners-hdp1	
						WHEN betteam = N'u' THEN hdp1-@ftaCorners	
						ELSE -1
						END
				WHEN 199 THEN 
					CASE 
						WHEN betteam ='0-8' AND (@fthCorners + @ftaCorners) <=8 THEN 1
						WHEN betteam ='9-11' AND (@fthCorners + @ftaCorners) IN(9,10,11) THEN 1
						WHEN betteam ='12-over' AND (@fthCorners + @ftaCorners)>=12 THEN 1 
					ELSE -1
					END
				WHEN 200 THEN
					CASE 
						WHEN betteam = '0-1' AND @hthCorners <= 1 THEN 1	
						WHEN betteam ='2' AND @hthCorners = 2 THEN 1
						WHEN betteam ='3' AND @hthCorners = 3 THEN 1
						WHEN betteam ='4-over' AND @hthCorners >=4 THEN 1
						ELSE -1
						END
				WHEN 201 THEN
					CASE 
						WHEN betteam = '0-1' AND @htaCorners <= 1 THEN 1	
						WHEN betteam ='2' AND @htaCorners = 2 THEN 1
						WHEN betteam ='3' AND @htaCorners = 3 THEN 1
						WHEN betteam ='4-over' AND @htaCorners >=4 THEN 1
						ELSE -1
						END
				WHEN 202 THEN
					CASE 
						WHEN betteam ='0-4' AND  (@hthCorners+@htaCorners)<=4 THEN 1
						WHEN betteam = '5-6' AND (@hthCorners+@htaCorners) IN(5, 6) THEN 1
						WHEN betteam ='7-over' AND (@hthCorners+@htaCorners) >= 7 THEN 1	
						ELSE -1
						END
				WHEN 203 THEN 
					CASE 
						WHEN betteam =N'o' AND ((@hthCorners + @htaCorners) &1) = 1 THEN 1 
						WHEN betteam =N'e' AND ((@hthCorners + @htaCorners) &1) = 0 THEN 1 
						ELSE - 1 
						END  

				WHEN 204 THEN 
					CASE 
						WHEN betteam = N'o' THEN @hthCorners-hdp1	
						WHEN betteam = N'u' THEN hdp1-@hthCorners	
						ELSE -1
						END
				WHEN 205 THEN 
					CASE 
						WHEN betteam = N'o' THEN @htaCorners-hdp1	
						WHEN betteam = N'u' THEN hdp1-@htaCorners	
						ELSE -1
						END	
				WHEN 206 THEN
					CASE 
						WHEN betteam = @FTFCorner THEN 1
						ELSE -1 
						END
				WHEN 207 THEN
					CASE 
						WHEN betteam = @HTFCorner THEN 1
						ELSE -1 
						END
				WHEN 208 THEN
					CASE 
						WHEN betteam = @FTLCorner THEN 1
						ELSE -1 
						END
				WHEN 209 THEN
					CASE 
						WHEN betteam = @HTLCorner THEN 1
						ELSE -1 
						END
				WHEN 401 THEN --Home Team Over/Under
					CASE
						WHEN betteam = 'o' THEN @fth - hdp1
						WHEN betteam = 'u' THEN hdp1 - @fth
						ELSE -1 END
				WHEN 402 THEN --Away Team Over/Under
					CASE
						WHEN betteam = 'o' THEN @fta - hdp1
						WHEN betteam = 'u' THEN hdp1 - @fta
						ELSE -1 END
				WHEN 403 THEN --1H Home Team Over/Under
					CASE
						WHEN betteam = 'o' THEN @hth - hdp1
						WHEN betteam = 'u' THEN hdp1 - @hth
						ELSE -1 END
				WHEN 404 THEN --1H Away Team Over/Under
					CASE
						WHEN betteam = 'o' THEN @hta - hdp1
						WHEN betteam = 'u' THEN hdp1 - @hta
						ELSE -1 END
				WHEN 405 THEN --2H Correct Score
					CASE
						WHEN betteam = CAST((@fth - @hth) AS NVARCHAR(6)) + ':' + CAST((@fta - @hta) AS NVARCHAR(6)) THEN 1
						WHEN betteam = 'AOS' --Any Other Scores
							AND CHARINDEX(CAST((@fth - @hth) AS NVARCHAR(6)) + ':' + CAST((@fta - @hta) AS NVARCHAR(6)), transdesc) < 0 THEN 1
						ELSE -1	END
				WHEN 406 THEN --Exact Total Goals
					CASE 
						WHEN betteam LIKE 'G[0-5]' AND ((@fth + @fta) = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						WHEN betteam ='G6' AND ((@fth + @fta) >= CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						ELSE -1 
						END 
				WHEN 407 THEN --Exact Home Team Goals
					CASE 
						WHEN betteam LIKE 'G[0-2]' AND (@fth = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						WHEN betteam ='G3' AND (@fth >= CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						ELSE - 1 
						END 
				WHEN 408 THEN --Winning Margin	
					CASE 
						WHEN betteam = 'H1' AND (@fth - @fta) = 1 THEN 1
						WHEN betteam = 'H2' AND (@fth - @fta) = 2 THEN 1 
						WHEN betteam = 'H3' AND (@fth - @fta) >= 3 THEN 1
						WHEN betteam = 'D' AND (@fth - @fta) = 0 AND (@fth + @fta) <> 0 THEN 1
						WHEN betteam = 'A1' AND (@fth - @fta) = -1 THEN 1 
						WHEN betteam = 'A2' AND (@fth - @fta) = -2 THEN 1 
						WHEN betteam = 'A3' AND (@fth - @fta) <= -3 THEN 1 
						WHEN betteam = 'NG' AND @fth = 0 AND @fta = 0 THEN 1
						ELSE - 1
						END
				WHEN 409 THEN --Exact Away Team Goals
					CASE 
						WHEN betteam LIKE 'G[0-2]' AND (@fta = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						WHEN betteam ='G3' AND (@fta >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						ELSE - 1 
						END 
				WHEN 410 THEN --1H Double Chance	
					CASE 
						WHEN betteam = '1x' AND (@hth - @hta) >= 0 THEN 1
						WHEN betteam = '12' AND (@hth - @hta) <> 0 THEN 1 
						WHEN betteam = '2x' AND (@hth - @hta) <= 0 THEN 1
						ELSE - 1					
						END		 
				WHEN 411 THEN --1H Draw No Bet
					CASE 
						WHEN (@hth - @hta) = 0 THEN 0
						WHEN betteam = 'h' AND (@hth - @hta) > 0 THEN 1
						WHEN betteam = 'a' AND (@hth - @hta) < 0 THEN 1
						ELSE -1
						END
				WHEN 412 THEN --Exact 1st Half Goal
					CASE 
						WHEN betteam <> '3&over' AND CAST(betteam AS INT) = (@hth + @hta) THEN 1
						WHEN betteam = '3&over' AND (@hth + @hta) >= 3 THEN 1
						ELSE -1
						END
				WHEN 413 THEN --Correct Score (aos)
					CASE 
						WHEN betteam NOT IN ('AOS')
							AND (@fth > LEFT(betteam,1) OR @fta > RIGHT(betteam,1)) THEN -1
						WHEN betteam = 'AOS'
							AND CHARINDEX(CAST(@fth AS VARCHAR) + ':' + CAST(@fta AS VARCHAR), transdesc) < 0 THEN 1
						ELSE -1
						END
				WHEN 414 THEN --1H Correct Score (aos)
					CASE
						WHEN betteam NOT IN ('AOS')
							AND (@hth > LEFT(betteam,1) OR @hth > RIGHT(betteam,1)) THEN -1
						WHEN betteam = 'AOS'
							AND CHARINDEX(CAST(@hth AS VARCHAR) + ':' + CAST(@hth AS VARCHAR), transdesc) < 0 THEN 1
						ELSE -1
						END

				-- Tennis Sporting Solution 
				WHEN 1301 THEN -- Match Winner 
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
						END
				WHEN 1302 THEN -- Match Correct Score 
					CASE 
						WHEN betteam = (CAST(@fth AS VARCHAR(4)) + CAST(@fta AS VARCHAR(4))) THEN 1
						ELSE - 1
						END
				WHEN 1303 THEN -- Set Handicap 
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
						END
				WHEN 1305 THEN -- Match Total Games Odd/Even
					CASE WHEN betteam = N'h' AND (@TotalGameHomeMatch + @TotalGameAwayMatch)%2 = 1 THEN 1 
						 WHEN betteam = N'a' AND (@TotalGameHomeMatch + @TotalGameAwayMatch)%2 = 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 1306 THEN -- Match Total Games Over/Under - 1306
					CASE betteam 
						WHEN N'h' THEN  (@TotalGameHomeMatch + @TotalGameAwayMatch) - hdp1 
						WHEN N'a' THEN  hdp1 - (@TotalGameHomeMatch + @TotalGameAwayMatch) 
						END 
				WHEN 1308 THEN  -- Match Games Handicap - 1308
					CASE betteam 
						WHEN N'h' THEN (hdp2 - hdp1) + (@TotalGameHomeMatch - livehomescore) - (@TotalGameAwayMatch - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@TotalGameHomeMatch - livehomescore) + (@TotalGameAwayMatch - liveawayscore)
						END 
				WHEN 1311 THEN -- Set x Winner - 1311
					CASE betteam 
						WHEN N'h' THEN (@TotalGameHomeSetx - @TotalGameAwaySetx)
						WHEN N'a' THEN (@TotalGameAwaySetx - @TotalGameHomeSetx)
						END 
				WHEN 1312 THEN --Set x Total Games Over/Under - 1312
					CASE betteam 
						WHEN N'o' THEN (@TotalGameHomeSetx + @TotalGameAwaySetx) - hdp1 
						WHEN N'u' THEN hdp1 - (@TotalGameHomeSetx + @TotalGameAwaySetx) 
						END
				WHEN 1316 THEN -- Set x Game Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@TotalGameHomeSetx - livehomescore) - (@TotalGameAwaySetx - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@TotalGameHomeSetx - livehomescore) + (@TotalGameAwaySetx - liveawayscore)
						END
				WHEN 1317 THEN -- Set x Correct Score
					CASE 
						WHEN betteam = (CASE WHEN @TotalGameHomeSetx > 7 AND (@TotalGameHomeSetx - @TotalGameAwaySetx)>=2 THEN 'haos'
											 WHEN @TotalGameAwaySetx > 7 AND (@TotalGameAwaySetx - @TotalGameHomeSetx)>=2 THEN 'aaos'
											 ELSE (CAST(@TotalGameHomeSetx AS VARCHAR(4)) + CAST(@TotalGameAwaySetx AS VARCHAR(4))) 
											 END) THEN 1
						ELSE - 1
						END
				WHEN 1318 THEN -- Set x Total Games Odd/Even
					CASE WHEN betteam = N'o' AND (@TotalGameHomeSetx + @TotalGameAwaySetx)%2 = 1 THEN 1 
						 WHEN betteam = N'e' AND (@TotalGameHomeSetx + @TotalGameAwaySetx)%2 = 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 1324 THEN -- Set x Game y Winner 
					CASE WHEN betteam =N'h' AND CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,4),@SetxGameyHomeWON)>0 THEN 1 
						 WHEN betteam =N'a' AND CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,4),@SetxGameyAwayWON)>0 THEN 1   
						 WHEN CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,4),@SetxGameyDRAW)>0 THEN 0 
						 WHEN CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,4),@SetxGameyREFUND)>0 THEN 0
						 ELSE -1 END		
				ELSE NULL -- Not support bettype
				END
			,-- CASE bettype
			-- ========================
			ruben = CASE 
				WHEN @modds IS NULL THEN 0
				ELSE 1
				END
			,winlostdate = @matchdate
			,[status] = CASE 
				WHEN @modds IS NULL THEN N'running'
				WHEN @modds = 0 AND @isRefundGame = 0 THEN N'DRAW'
				WHEN @modds = 0 AND @isRefundGame = 1 THEN N'Refund'
				WHEN @modds < 0 THEN N'LOSE'
				WHEN @modds > 0 THEN N'WON'
				END
			,statusID = CASE 
				WHEN @modds IS NULL THEN 0
				WHEN @modds = 0 AND @isRefundGame = 0 THEN 111
				WHEN @modds = 0 AND @isRefundGame = 1 THEN 103 
				WHEN @modds < 0 THEN 113
				WHEN @modds > 0 THEN 112
				END
			,statuswinlost = CASE 
				WHEN @modds <= - 0.5 THEN 4 -- LOSE
				WHEN @modds >= 0.5 THEN 2 -- WIN
				WHEN @modds > 0 THEN 1 -- Half WIN
				WHEN @modds < 0 THEN 3 -- Half LOSE
				ELSE 0 -- DRAW
				END
		-- ========================
		FROM dbo.bettransm WITH (INDEX = IX_matchid)
		WHERE matchid = @matchid AND bettype NOT IN (14, 127) AND statusID NOT IN (101, 102)
		--AND bettype = CASE WHEN ISNULL(@resultPS, '') = '' AND bettype <> 135 THEN bettype
		--				   WHEN ISNULL(@resultPS, '') <> '' THEN 135
		--			  END
		AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		--AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
		AND 1 = CASE WHEN @SelectedSetCAL IS NULL AND @SelectedSetREFUND IS NULL THEN 1 
					 WHEN @SelectedSetCAL LIKE '%1%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '801%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%2%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '802%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%3%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '803%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%4%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '804%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%5%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '805%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%6%' AND Bettype IN (1,2,3,20,153,1301,1302,1303,1305,1306,1308) THEN 1
					 WHEN @SelectedSetREFUND LIKE '%1%' AND Bettype = 1324 AND betcheck LIKE '801%' THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%2%' AND Bettype = 1324 AND betcheck LIKE '802%' THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%3%' AND Bettype = 1324 AND betcheck LIKE '803%' THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%4%' AND Bettype = 1324 AND betcheck LIKE '804%' THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%5%' AND Bettype = 1324 AND betcheck LIKE '805%' THEN 1  
					 ELSE 0 
					 END 
		AND 1 = CASE WHEN @ResourceIDsCAL IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1  
				WHEN @ResourceIDsCAL IS NOT NULL 
						AND Bettype IN (160,164,169,180) 
						AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(20)),2,5),@ResourceIDsCAL)>0 THEN 1 
				WHEN @ResourceIDsCAL IS NOT NULL 
							AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) 
							AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDsCAL)>0 THEN 1 
				ELSE 0 END  --Betradar 2 Auto Bettypes 
		AND bettype NOT BETWEEN 1501 and 1599 -- Keno


		-- BetParlayDetail
		UPDATE pd
		SET 
			 @isRefundGame	= CASE WHEN  Bettype = 1324 AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(10)),2,4),@SetxGameyREFUND)>0 THEN 1 ELSE 0 END 
			,@TotalGameHomeSetx	= CASE WHEN betCheck = '801' THEN @TotalGameHomeSet1
									   WHEN betCheck = '802' THEN @TotalGameHomeSet2
									   WHEN betCheck = '803' THEN @TotalGameHomeSet3
									   WHEN betCheck = '804' THEN @TotalGameHomeSet4
									   WHEN betCheck = '805' THEN @TotalGameHomeSet5
									   ELSE @TotalGameHomeSetx 
									   END 
			,@TotalGameAwaySetx = CASE WHEN betCheck = '801' THEN @TotalGameAwaySet1
									   WHEN betCheck = '802' THEN @TotalGameAwaySet2
									   WHEN betCheck = '803' THEN @TotalGameAwaySet3
									   WHEN betCheck = '804' THEN @TotalGameAwaySet4
									   WHEN betCheck = '805' THEN @TotalGameAwaySet5
									   ELSE @TotalGameAwaySetx
									   END 
			,@modds = CASE bettype
				WHEN 1 THEN -- Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
						END
				WHEN 7 THEN -- 1st Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@hth - livehomescore) - (@hta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
						END
				WHEN 3 THEN -- Over/Under
					CASE betteam
						WHEN N'h' THEN (CASE 
								WHEN ISNULL(@TennisTotal,0)=0 THEN @fth + @fta
								ELSE @TennisTotal END
								) - hdp1
						WHEN N'a' THEN hdp1 - (CASE 
								WHEN ISNULL(@TennisTotal,0)=0 THEN @fth + @fta
								ELSE @TennisTotal END
								)
						END
				WHEN 8 THEN -- 1st Over/Under
					CASE betteam
						WHEN N'h' THEN (@hth + @hta) - hdp1
						WHEN N'a' THEN hdp1 - (@hth + @hta)
						END
				WHEN 2 THEN -- Odd/Even
					CASE 
						WHEN (betteam = N'h') AND (
								(CASE 
									WHEN ISNULL(@TennisTotal,0)=0 THEN @fth + @fta
									ELSE @TennisTotal END
									) & 1 = 1
								) THEN 1
						WHEN (betteam = N'a') AND (
								(CASE 
									WHEN ISNULL(@TennisTotal,0)=0 THEN @fth + @fta
									ELSE @TennisTotal END
									) & 1 = 0
								) THEN 1
						ELSE - 1
						END
				WHEN 12 THEN -- 1st Odd/Even
					CASE 
						WHEN (betteam = N'h') AND ((@hth + @hta) & 1 = 1) THEN 1
						WHEN (betteam = N'a') AND ((@hth + @hta) & 1 = 0) THEN 1
						ELSE - 1
						END
				WHEN 4 THEN -- Correct Score
					CASE 
						WHEN betteam = (CAST(@fth AS VARCHAR(4)) + ':' + CAST(@fta AS VARCHAR(4))) THEN 1
						WHEN betteam = '5:0' AND (@fth - @fta) >= 5 THEN 1
						WHEN betteam = '0:5' AND (@fth - @fta) <= - 5 THEN 1
						ELSE - 1
						END
				WHEN 30 THEN -- 1st Correct Score
					CASE 
						WHEN betteam = (CAST(@hth AS VARCHAR(4)) + ':' + CAST(@hta AS VARCHAR(4))) THEN 1
						WHEN betteam = '4:0' AND (@hth - @hta) >= 4 THEN 1 -- 4UP for 1st Correct Score
						WHEN betteam = '0:4' AND (@hth - @hta) <= - 4 THEN 1 -- 4UP for 1st Correct Score
						WHEN betteam = '5:0' AND (@hth - @hta) >= 5 THEN 1
						WHEN betteam = '0:5' AND (@hth - @hta) <= - 5 THEN 1
						ELSE - 1
						END
				WHEN 16 THEN -- HT/FT
					CASE 
						WHEN betteam = CASE 
								WHEN @hth = @hta THEN '0'
								WHEN @hth > @hta THEN '1'
								ELSE '2'
								END + ':' + CASE 
								WHEN @fth = @fta THEN '0'
								WHEN @fth > @fta THEN '1'
								ELSE '2'
								END THEN 1
						ELSE - 1
						END
				WHEN 5 THEN -- 1x2
					CASE 
						WHEN (betteam = N'1') AND (@fth > @fta) THEN 1
						WHEN (betteam = N'2') AND (@fta > @fth) THEN 1
						WHEN (betteam = N'x') AND (@fth = @fta) THEN 1
						ELSE - 1
						END
				WHEN 15 THEN -- 1st 1x2
					CASE 
						WHEN (betteam = N'1') AND (@hth > @hta) THEN 1
						WHEN (betteam = N'2') AND (@hta > @hth) THEN 1
						WHEN (betteam = N'x') AND (@hth = @hta) THEN 1
						ELSE - 1
						END
				WHEN 6 THEN -- Total Goal
					CASE 
						WHEN (CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END >= cast(left(betteam, 1) AS INT) AND CASE 
								WHEN @TennisTotal IS NULL THEN @fth + @fta
								ELSE @TennisTotal END <= (CASE 
									WHEN right(betteam, 1) = 'r' THEN 999
									ELSE cast(right(betteam, 1) AS INT) END
									)
								) THEN 1
						ELSE - 1
						END
				when 126 then -- 1H Total Goal
					case when (
							case when @TennisTotal IS NULL then @hth+@hta else @TennisTotal end >= cast(left(betteam,1)as int) and
							case when @TennisTotal IS NULL then @hth+@hta else @TennisTotal end <= (
									case when right(betteam,1) = 'r' then 999 else 
									cast(right(betteam,1) as int) end
									)
							)  
					then 1 else -1 end
				WHEN 13 THEN -- Clean Sheet
					CASE 
						WHEN betteam = 'hy' AND @fta = 0 THEN 1
						WHEN betteam = 'hn' AND @fta > 0 THEN 1
						WHEN betteam = 'ay' AND @fth = 0 THEN 1
						WHEN betteam = 'an' AND @fth > 0 THEN 1
						ELSE - 1
						END
				WHEN 20 THEN -- Money Line
					CASE betteam
						WHEN N'h' THEN @fth - @fta
						ELSE @fta - @fth
						END
				WHEN 21 THEN -- 1st Money Line
					CASE betteam
						WHEN N'h' THEN @hth - @hta
						ELSE @hta - @hth
						END
				WHEN 24 THEN -- Double Chance
					CASE 
						WHEN betteam = '1X' AND (@fth - @fta) >= 0 THEN 1
						WHEN betteam = '2X' AND (@fth - @fta) <= 0 THEN 1
						WHEN betteam = '12' AND (@fth - @fta) <> 0 THEN 1
						ELSE - 1
						END
				WHEN 25 THEN -- Draw No Bet
					CASE 
						WHEN (@fth - @fta) = 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE - 1
						END
				WHEN 26 THEN -- Both/One/Neither team to score
					CASE 
						WHEN betteam = 'b' AND (@fth > 0 AND @fta > 0) THEN 1
						WHEN betteam = 'o' AND ((@fth > 0 AND @fta = 0) OR (@fta > 0 AND @fth = 0)) THEN 1
						WHEN betteam = 'n' AND (@fth = 0 AND @fta = 0) THEN 1
						ELSE - 1
						END
				WHEN 27 THEN -- To win to nil
					CASE 
						WHEN betteam = 'h' AND (@fth > @fta AND @fta = 0) THEN 1
						WHEN betteam = 'a' AND (@fta > @fth AND @fth = 0) THEN 1
						ELSE - 1
						END
				WHEN 28 THEN -- 3-way handicap
					CASE 
						WHEN betteam = '1' AND (hdp2 - hdp1 + @fth - @fta) > 0 THEN 1
						WHEN betteam = '2' AND (hdp1 - hdp2 + @fta - @fth) > 0 THEN 1
						WHEN betteam = 'x' AND ((hdp1 - hdp2) - (@fth - @fta)) = 0 THEN 1
						ELSE - 1
						END
				WHEN 121 THEN -- home no bet
					CASE 
						WHEN (@fth - @fta) > 0 THEN 0
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE - 1
						END
				WHEN 122 THEN -- away no bet
					CASE 
						WHEN (@fth - @fta) < 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						ELSE - 1
						END
				WHEN 123 THEN -- draw/no draw
					CASE 
						WHEN betteam = 'h' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) <> 0 THEN 1
						ELSE - 1
						END
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
				WHEN 151 THEN -- 1st Half Double Chance
					CASE 
						WHEN betteam = '1x' AND (@hth - @hta) >= 0 THEN 1
						WHEN betteam = '2x' AND (@hta - @hth) >= 0 THEN 1
						WHEN betteam = '12' AND (@hth - @hta) <> 0 THEN 1
						ELSE -1
						END
				WHEN 152 THEN -- Half Time/Full Time Correct Score
					CASE 
						WHEN betteam = @csHTFT THEN 1
						ELSE -1
						END 
				WHEN 135 THEN -- Penalty Shootout
					CASE
						WHEN betteam = @penaltyshootout THEN 1
						ELSE -1
						END
				WHEN 128 THEN -- HT/FT Odd/Even
					CASE
						WHEN betteam = 'oo' AND (@hth + @hta) % 2 = 1 AND (@fth + @fta) % 2 = 1 THEN 1
						WHEN betteam = 'oe' AND (@hth + @hta) % 2 = 1 AND (@fth + @fta) % 2 = 0 THEN 1
						WHEN betteam = 'eo' AND (@hth + @hta) % 2 = 0 AND (@fth + @fta) % 2 = 1 THEN 1
						WHEN betteam = 'ee' AND (@hth + @hta) % 2 = 0 AND (@fth + @fta) % 2 = 0 THEN 1
						ELSE -1
						END				
				WHEN 129 THEN -- 1H Exact Goal
					CASE
						WHEN betteam = '5&over' AND (@hth + @hta) >= 5 THEN 1
						WHEN betteam <> '5&over' AND cast(betteam as INT) = (@hth + @hta) THEN 1
						ELSE -1
						END
				WHEN 130 THEN --  Exact Goal
					CASE 
						WHEN betteam = '7&over' AND (@fth + @fta) >= 7 THEN 1
						WHEN betteam <> '7&over' AND cast(betteam AS INT) = (@fth + @fta) THEN 1
						ELSE -1
						END
				WHEN 131 THEN -- Home Team Total Goal 
					CASE
						WHEN cast(LEFT(betteam,1) as INT) <= @fth 
							AND case when right(betteam,1) = 'r' 
										then 999 
									 else cast(RIGHT(betteam,1) as int) 
									 END >= @fth THEN 1
						ELSE -1
						END		
				WHEN 132 THEN -- Away Team Total Goal
					CASE 
						WHEN cast(left(betteam,1) as int) <= @fta	
							AND case when right(betteam,1) = 'r'
										then 999
									 else cast(right(betteam,1) as int)
									 END >= @fta THEN 1
						ELSE -1
						END
				WHEN 136 THEN -- 1H Home Team Odd/Even			
					CASE	
						WHEN betteam = 'o' and (@hth % 2) = 1 THEN 1
						WHEN betteam = 'e' and (@hth % 2) = 0 THEN 1
						ELSE -1
						END
				WHEN 137 THEN -- Home Team Odd/Even
					CASE
						WHEN betteam = 'o' and (@fth % 2) = 1 THEN 1
						WHEN betteam = 'e' and (@fth % 2) = 0 THEN 1
						ELSE -1
						END 
				WHEN 138 THEN -- 1H Away Team Odd/Even 			
					CASE	
						WHEN betteam = 'o' and (@hta % 2) = 1 THEN 1
						WHEN betteam = 'e' and (@hta % 2) = 0 THEN 1
						ELSE -1
						END
				WHEN 139 THEN -- Away Team Odd/Even
					CASE
						WHEN betteam = 'o' and (@fta % 2) = 1 THEN 1
						WHEN betteam = 'e' and (@fta % 2) = 0 THEN 1
						ELSE -1
						END 
				WHEN 143 THEN -- 1H Result/Total Goals
					CASE
						WHEN betteam = 'ho' and (@hth - @hta) > 0 THEN (@hth+ @hta) - hdp1
						WHEN betteam = 'hu' and (@hth - @hta) > 0 THEN hdp1 - (@hth+ @hta) 
						WHEN betteam = 'ao' and (@hth - @hta) < 0 THEN (@hth+ @hta) - hdp1
						WHEN betteam = 'au' and (@hth - @hta) < 0 THEN hdp1 - (@hth+ @hta) 
						WHEN betteam = 'do' and (@hth - @hta) = 0 THEN (@hth+ @hta) - hdp1
						WHEN betteam = 'du' AND (@hth - @hta) = 0 THEN hdp1 - (@hth+ @hta) 
						ELSE -1
						END	
				WHEN 144 THEN -- Result/Total Goals
					CASE
						WHEN betteam = 'ho' and (@fth - @fta) > 0 THEN (@fth+ @fta) - hdp1
						WHEN betteam = 'hu' and (@fth - @fta) > 0 THEN hdp1 - (@fth+ @fta)
						WHEN betteam = 'ao' and (@fth - @fta) < 0 THEN (@fth+ @fta) - hdp1
						WHEN betteam = 'au' and (@fth - @fta) < 0 THEN hdp1 - (@fth+ @fta)
						WHEN betteam = 'do' and (@fth - @fta) = 0 THEN (@fth+ @fta) - hdp1
						WHEN betteam = 'du' AND (@fth - @fta) = 0 THEN hdp1 - (@fth+ @fta)
						ELSE -1
						END

				-- Tennis New bet types 		
				WHEN 153 THEN -- Match Games Handicap
					CASE betteam 
						WHEN N'h' THEN (hdp2 - hdp1) + (@TotalGameHomeMatch - livehomescore) - (@TotalGameAwayMatch - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@TotalGameHomeMatch - livehomescore) + (@TotalGameAwayMatch - liveawayscore)
						END 
				WHEN 154 THEN -- Set x Winner
					CASE betteam 
						WHEN N'h' THEN (@TotalGameHomeSetx - @TotalGameAwaySetx)
						WHEN N'a' THEN (@TotalGameAwaySetx - @TotalGameHomeSetx)
						END 
				WHEN 155 THEN -- Set x Game Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@TotalGameHomeSetx - livehomescore) - (@TotalGameAwaySetx - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@TotalGameHomeSetx - livehomescore) + (@TotalGameAwaySetx - liveawayscore)
						END
				WHEN 156 THEN --Set x Total Games Over/Under 
					CASE betteam 
						WHEN N'o' THEN (@TotalGameHomeSetx + @TotalGameAwaySetx) - hdp1 
						WHEN N'u' THEN hdp1 - (@TotalGameHomeSetx + @TotalGameAwaySetx) 
						END

				--- Betradar 2 
				WHEN 160 THEN 
					CASE WHEN CHARINDEX((SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,5) + betteam),@NextGoal)> 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 164 THEN 
					CASE WHEN CHARINDEX((SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,5) + betteam),@ExtraNextGoal)> 0 THEN 1 
						 ELSE - 1 
						 END

				WHEN 168 THEN 
					CASE WHEN Betteam = @WhoAdvancesNextRound THEN 1 
						 ELSE - 1
						 END 
				WHEN 169 THEN 
					CASE WHEN CHARINDEX((SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,5) + betteam),@NextGoalTime15Min)> 0 THEN 1 
						 ELSE - 1 
						 END
				WHEN 173 THEN 
					CASE WHEN Betteam = @ExtraTimeYN THEN 1 
						 ELSE - 1
						 END 

				WHEN 174 THEN 
					CASE WHEN Betteam = @ExtraTimeandGoal THEN 1 
						 ELSE - 1
						 END 
				WHEN 175 THEN 
					CASE WHEN Betteam = @matchDecidedMethod THEN 1 
						 ELSE - 1
						 END 

				WHEN 176 THEN 
					CASE WHEN Betteam = @1st10Min1x2 THEN 1 
						 ELSE - 1
						 END 

				WHEN 180 THEN 
					CASE WHEN CHARINDEX((SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,5) + betteam),@1HNextGoal)> 0 THEN 1 
						 ELSE - 1 
						 END
				WHEN 192 THEN 
					CASE WHEN Betteam = @1stGoalTime10Min THEN 1 
						 ELSE - 1
						 END 
				WHEN 193 THEN 
					CASE WHEN Betteam = @1stGoalTime15Min THEN 1 
						 ELSE - 1
						 END 
				WHEN 210 THEN 
					CASE WHEN Betteam = @PlayerSentOff THEN 1 
						 ELSE - 1
						 END 
				WHEN 211 THEN 
					CASE WHEN Betteam = @HTPlayerSentOff THEN 1 
						 ELSE - 1
						 END 
				WHEN 212 THEN 
					CASE WHEN Betteam = @PlayerSentOffHome THEN 1 
						 ELSE - 1
						 END 

				WHEN 213 THEN 
					CASE WHEN Betteam = @HTPlayerSentOffHome THEN 1 
						 ELSE - 1
						 END 

				WHEN 214 THEN 
					CASE WHEN Betteam = @PlayerSentOffAway THEN 1 
						 ELSE - 1
						 END 

				WHEN 215 THEN 
					CASE WHEN Betteam = @HTPlayerSentOffAway THEN 1 
						 ELSE - 1
						 END 

				WHEN 216 THEN 
					CASE WHEN CHARINDEX(betteam,@GoalScorerAnytime)>0 THEN 1 
						 ELSE - 1
						 END 

				WHEN 217 THEN 
					CASE WHEN Betteam = @GoalScorerFirst THEN 1 
						 ELSE - 1
						 END 

				-- Betradar 2 Manual Bettype 
				WHEN 157 THEN 
					CASE WHEN betteam =N'h' AND ((@fth + @fta) &1) = 1 THEN 1 
						 WHEN betteam =N'a' AND ((@fth + @fta) &1) = 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 159 THEN 
					CASE WHEN betteam LIKE 'G[0-5]' AND ((@fth + @fta) = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G6' AND ((@fth + @fta) >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 161 THEN 
					CASE WHEN betteam LIKE 'G[0-2]' AND (@fth = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G3' AND (@fth >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 162 THEN 
					CASE WHEN betteam LIKE 'G[0-2]' AND (@fta = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G3' AND (@fta >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 163 THEN 
					CASE WHEN betteam = 'ho' AND (@fth -@fta) > 0 THEN (@fth + @fta) - hdp1
						 WHEN betteam = 'hu' AND (@fth -@fta) > 0 THEN hdp1 - (@fth + @fta)
						 WHEN betteam = 'ao' AND (@fth -@fta) < 0 THEN (@fth + @fta) - hdp1
						 WHEN betteam = 'au' AND (@fth -@fta) < 0 THEN hdp1 - (@fth + @fta)
						 WHEN betteam = 'do' AND (@fth -@fta) = 0 THEN (@fth + @fta) - hdp1
						 WHEN betteam = 'du' AND (@fth -@fta) = 0 THEN hdp1 - (@fth + @fta)	
						 ELSE -1 
						 END 
				WHEN 165 THEN 
					CASE 
						WHEN betteam = (CAST(@hth AS VARCHAR(4)) + ':' + CAST(@hta AS VARCHAR(4))) THEN 1
						ELSE - 1
						END				
				WHEN 166 THEN 
					CASE 
						WHEN betteam = (CAST(@fth AS VARCHAR(4)) + ':' + CAST(@fta AS VARCHAR(4))) THEN 1
						ELSE - 1
						END	
				WHEN 167 THEN 
					CASE 
						WHEN (betteam = N'1') AND (@fth > @fta) THEN 1
						WHEN (betteam = N'2') AND (@fta > @fth) THEN 1
						WHEN (betteam = N'x') AND (@fth = @fta) THEN 1
						ELSE - 1
						END
				WHEN 170 THEN		
					CASE 
						WHEN betteam =N'h' AND (@fth > 0 AND @fta = 0) THEN 1
						WHEN betteam =N'a' AND (@fth = 0 AND @fta > 0) THEN 1
						WHEN betteam =N'b' AND (@fth > 0 AND @fta > 0) THEN 1
						WHEN betteam =N'n' AND (@fth = 0 AND @fta = 0) THEN 1
						ELSE -1
						END 
				WHEN 171 THEN	
					CASE 
						WHEN betteam = 'h1' AND (@fth -@fta) = 1 THEN 1		--171 
						WHEN betteam = 'h2' AND (@fth -@fta) = 2 THEN 1 
						WHEN betteam = 'h3' AND (@fth -@fta) >=3 THEN 1 
						WHEN betteam = 'd' AND (@fth -@fta) =0 THEN 1 
						WHEN betteam = 'a1' AND (@fth -@fta) =-1 THEN 1 
						WHEN betteam = 'a2' AND (@fth -@fta) =-2 THEN 1 
						WHEN betteam = 'a3' AND (@fth -@fta)<=-3 THEN 1 
						ELSE - 1					
						END
				WHEN 172 THEN	
					CASE 
						WHEN betteam = 'HH' AND @FirstGoal='H' AND (@fth - @fta) >0 THEN 1 
						WHEN betteam = 'DH' AND @FirstGoal='H' AND (@fth - @fta) =0 THEN 1
						WHEN betteam = 'AH' AND @FirstGoal='H' AND (@fth - @fta) <0 THEN 1
						WHEN betteam = 'HA' AND @FirstGoal='A' AND (@fth - @fta) >0 THEN 1
						WHEN betteam = 'DA' AND @FirstGoal='A' AND (@fth - @fta) =0 THEN 1
						WHEN betteam = 'AA' AND @FirstGoal='A' AND (@fth - @fta) <0 THEN 1
						WHEN betteam = 'NO' AND @fth =0 AND @fta= 0 THEN 1
						ELSE - 1
						END
				WHEN 177 THEN	
					CASE 
						WHEN (betteam = N'1') AND ((@fth -@hth) -(@fta - @hta))>0 THEN 1
						WHEN (betteam = N'2') AND ((@fth -@hth) -(@fta - @hta))<0 THEN 1
						WHEN (betteam = N'x') AND ((@fth -@hth) -(@fta - @hta))=0 THEN 1
						ELSE - 1
						END

				WHEN 178 THEN 
					CASE betteam 
						WHEN N'o' THEN ((@fth + @fta) - (@hth + @hta)) - hdp1 
						WHEN N'u' THEN hdp1 - ((@fth + @fta) - (@hth + @hta)) 
						END
				WHEN 179 THEN 
					CASE 
						WHEN betteam LIKE 'G[0-3]' AND (@hth + @hta) = CAST(RIGHT(betteam,1)AS TINYINT) THEN 1 
						WHEN betteam ='G4' AND (@hth + @hta) >=CAST(RIGHT(betteam,1)AS TINYINT) THEN 1 
						ELSE -1
						END 
				WHEN 181 THEN 
					CASE 
						 WHEN betteam LIKE 'G[0-2]' AND (@hth = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G3' AND (@hth >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 182 THEN 
					CASE 
						 WHEN betteam LIKE 'G[0-2]' AND (@hta = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 WHEN betteam ='G3' AND (@hta >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						 ELSE - 1 
						 END 
				WHEN 183 THEN 
					CASE 
						WHEN betteam =N'h' THEN (hdp2 - hdp1) + ((@fth - @hth) - livehomescore) - ((@fta - @hta) - liveawayscore)
						WHEN betteam =N'a' THEN (hdp1 - hdp2) - ((@fth - @hth) - livehomescore) + ((@fta - @hta) - liveawayscore)
						END
				WHEN 184 THEN 
					CASE WHEN betteam =N'o' AND ((@fth + @fta - @hth - @hta) &1) = 1 THEN 1 
						 WHEN betteam =N'e' AND ((@fth + @fta - @hth - @hta) &1) = 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 185 THEN -- Draw No Bet
					CASE 
						WHEN ((@fth -@hth) -(@fta - @hta)) = 0 THEN 0
						WHEN betteam = 'h' AND ((@fth -@hth) -(@fta - @hta)) > 0 THEN 1
						WHEN betteam = 'a' AND ((@fth -@hth) -(@fta - @hta)) < 0 THEN 1
						ELSE - 1
						END
				WHEN 186 THEN -- Double Chance
					CASE 
						WHEN betteam = 'HD' AND ((@fth -@hth) -(@fta - @hta)) >= 0 THEN 1
						WHEN betteam = 'DA' AND ((@fth -@hth) -(@fta - @hta)) <= 0 THEN 1
						WHEN betteam = 'HA' AND ((@fth -@hth) -(@fta - @hta)) <> 0 THEN 1
						ELSE - 1
						END
				WHEN 187 THEN
					CASE 
						WHEN betteam LIKE 'G[0-1]' AND ((@fth + @fta) - (@hth + @hta)) = CAST(RIGHT(betteam,1)AS TINYINT) THEN 1
						WHEN betteam ='G2'AND ((@fth + @fta) - (@hth + @hta)) >=CAST(RIGHT(betteam,1)AS TINYINT) THEN 1
						ELSE - 1
						END
				WHEN 188 THEN 
					CASE 
						WHEN betteam = 'Y' AND @hth > 0 AND @hta > 0 THEN 1 
						WHEN betteam = 'N' AND (@hth = 0 OR @hta = 0) THEN 1 
						ELSE - 1
						END
				WHEN 189 THEN	
					CASE 
						WHEN betteam ='y' AND (@hth + @hta - 1.5) > 0 AND ((@fth-@hth) + (@fta -@hta) - 1.5)>0 THEN 1 
						WHEN betteam ='n' AND ((@hth + @hta - 1.5) <=0 OR ((@fth-@hth) + (@fta -@hta) - 1.5)<=0) THEN 1 
						ELSE -1 
						END  
				WHEN 190 THEN -- Both Halves Under 1.5 Yes/No  [190]
					CASE 
						WHEN betteam ='y' AND (@hth + @hta - 1.5) < 0 AND ((@fth-@hth) + (@fta -@hta) - 1.5)<0 THEN 1  
						WHEN betteam ='n' AND ((@hth + @hta - 1.5) >=0 OR ((@fth-@hth) + (@fta -@hta) - 1.5)>=0) THEN 1 
						ELSE -1 
					END	
				WHEN 191 THEN 
					CASE 
						WHEN (@hth - @hta) = 0 THEN 0
						WHEN betteam = 'h' AND (@hth - @hta) > 0 THEN 1
						WHEN betteam = 'a' AND (@hth - @hta) < 0 THEN 1
						ELSE -1
						END
				WHEN 194 THEN
					CASE 
						WHEN betteam =N'o' AND ((@fthCorners + @ftaCorners) &1) = 1 THEN 1 
						WHEN betteam =N'e' AND ((@fthCorners + @ftaCorners) &1) = 0 THEN 1 
						ELSE - 1 
						END   
				WHEN 195 THEN 
					CASE 
						WHEN betteam = '0-2' AND @fthCorners <=2 THEN 1			
						WHEN betteam = '3-4' AND @fthCorners IN (3, 4) THEN 1	
						WHEN betteam = '5-6' AND @fthCorners IN(5, 6) THEN 1	
						WHEN betteam = '7-over' AND @fthCorners >= 7 THEN 1		
						ELSE -1
						END 
				WHEN 196 THEN 
					CASE 
						WHEN betteam = '0-2' AND @ftaCorners <=2 THEN 1			
						WHEN betteam = '3-4' AND @ftaCorners IN (3, 4) THEN 1	
						WHEN betteam = '5-6' AND @ftaCorners IN(5, 6) THEN 1	
						WHEN betteam = '7-over' AND @ftaCorners >= 7 THEN 1		
						ELSE -1
						END 
				WHEN 197 THEN 
					CASE	
						WHEN betteam = N'o' THEN @fthCorners-hdp1	
						WHEN betteam = N'u' THEN hdp1-@fthCorners	
						ELSE -1
						END
				WHEN 198 THEN
					CASE	
						WHEN betteam = N'o' THEN @ftaCorners-hdp1	
						WHEN betteam = N'u' THEN hdp1-@ftaCorners	
						ELSE -1
						END
				WHEN 199 THEN 
					CASE 
						WHEN betteam ='0-8' AND (@fthCorners + @ftaCorners) <=8 THEN 1
						WHEN betteam ='9-11' AND (@fthCorners + @ftaCorners) IN(9,10,11) THEN 1
						WHEN betteam ='12-over' AND (@fthCorners + @ftaCorners)>=12 THEN 1 
					ELSE -1
					END
				WHEN 200 THEN
					CASE 
						WHEN betteam = '0-1' AND @hthCorners <= 1 THEN 1	
						WHEN betteam ='2' AND @hthCorners = 2 THEN 1
						WHEN betteam ='3' AND @hthCorners = 3 THEN 1
						WHEN betteam ='4-over' AND @hthCorners >=4 THEN 1
						ELSE -1
						END
				WHEN 201 THEN
					CASE 
						WHEN betteam = '0-1' AND @htaCorners <= 1 THEN 1	
						WHEN betteam ='2' AND @htaCorners = 2 THEN 1
						WHEN betteam ='3' AND @htaCorners = 3 THEN 1
						WHEN betteam ='4-over' AND @htaCorners >=4 THEN 1
						ELSE -1
						END
				WHEN 202 THEN
					CASE 
						WHEN betteam ='0-4' AND  (@hthCorners+@htaCorners)<=4 THEN 1
						WHEN betteam = '5-6' AND (@hthCorners+@htaCorners) IN(5, 6) THEN 1
						WHEN betteam ='7-over' AND (@hthCorners+@htaCorners) >= 7 THEN 1	
						ELSE -1
						END
				WHEN 203 THEN 
					CASE 
						WHEN betteam =N'o' AND ((@hthCorners + @htaCorners) &1) = 1 THEN 1 
						WHEN betteam =N'e' AND ((@hthCorners + @htaCorners) &1) = 0 THEN 1 
						ELSE - 1 
						END  

				WHEN 204 THEN 
					CASE 
						WHEN betteam = N'o' THEN @hthCorners-hdp1	
						WHEN betteam = N'u' THEN hdp1-@hthCorners	
						ELSE -1
						END
				WHEN 205 THEN 
					CASE 
						WHEN betteam = N'o' THEN @htaCorners-hdp1	
						WHEN betteam = N'u' THEN hdp1-@htaCorners	
						ELSE -1
						END	
				WHEN 206 THEN
					CASE 
						WHEN betteam = @FTFCorner THEN 1
						ELSE -1 
						END
				WHEN 207 THEN
					CASE 
						WHEN betteam = @HTFCorner THEN 1
						ELSE -1 
						END
				WHEN 208 THEN
					CASE 
						WHEN betteam = @FTLCorner THEN 1
						ELSE -1 
						END
				WHEN 209 THEN
					CASE 
						WHEN betteam = @HTLCorner THEN 1
						ELSE -1 
						END
				WHEN 401 THEN --Home Team Over/Under
					CASE
						WHEN betteam = 'o' THEN @fth - hdp1
						WHEN betteam = 'u' THEN hdp1 - @fth
						ELSE -1 END
				WHEN 402 THEN --Away Team Over/Under
					CASE
						WHEN betteam = 'o' THEN @fta - hdp1
						WHEN betteam = 'u' THEN hdp1 - @fta
						ELSE -1 END
				WHEN 403 THEN --1H Home Team Over/Under
					CASE
						WHEN betteam = 'o' THEN @hth - hdp1
						WHEN betteam = 'u' THEN hdp1 - @hth
						ELSE -1 END
				WHEN 404 THEN --1H Away Team Over/Under
					CASE
						WHEN betteam = 'o' THEN @hta - hdp1
						WHEN betteam = 'u' THEN hdp1 - @hta
						ELSE -1 END
				WHEN 405 THEN --2H Correct Score
					CASE
						WHEN betteam = CAST((@fth - @hth) AS NVARCHAR(6)) + ':' + CAST((@fta - @hta) AS NVARCHAR(6)) THEN 1
						WHEN betteam = 'AOS' --Any Other Scores
							AND CHARINDEX(CAST((@fth - @hth) AS NVARCHAR(6)) + ':' + CAST((@fta - @hta) AS NVARCHAR(6)), transdesc) < 0 THEN 1
						ELSE -1
						END
				WHEN 406 THEN --Exact Total Goals
					CASE 
						WHEN betteam LIKE 'G[0-5]' AND ((@fth + @fta) = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						WHEN betteam ='G6' AND ((@fth + @fta) >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						ELSE -1 
						END 
				WHEN 407 THEN --Exact Home Team Goals
					CASE 
						WHEN betteam LIKE 'G[0-2]' AND (@fth = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						WHEN betteam ='G3' AND (@fth >= CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						ELSE - 1 
						END 
				WHEN 408 THEN --Winning Margin	
					CASE 
						WHEN betteam = 'H1' AND (@fth - @fta) = 1 THEN 1
						WHEN betteam = 'H2' AND (@fth - @fta) = 2 THEN 1 
						WHEN betteam = 'H3' AND (@fth - @fta) >= 3 THEN 1 
						WHEN betteam = 'D' AND (@fth - @fta) = 0 AND (@fth + @fta) <> 0 THEN 1
						WHEN betteam = 'A1' AND (@fth - @fta) = -1 THEN 1 
						WHEN betteam = 'A2' AND (@fth - @fta) = -2 THEN 1 
						WHEN betteam = 'A3' AND (@fth - @fta) <= -3 THEN 1 
						WHEN betteam = 'NG' AND @fth = 0 AND @fta = 0 THEN 1
						ELSE - 1					
						END
				WHEN 409 THEN --Exact Away Team Goals
					CASE 
						WHEN betteam LIKE 'G[0-2]' AND (@fta = CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						WHEN betteam ='G3' AND (@fta >=CAST(RIGHT(betteam,1)AS TINYINT)) THEN 1 
						ELSE - 1 
						END 
				WHEN 410 THEN --1H Double Chance	
					CASE 
						WHEN betteam = '1x' AND (@hth - @hta) >= 0 THEN 1
						WHEN betteam = '12' AND (@hth - @hta) <> 0 THEN 1 
						WHEN betteam = '2x' AND (@hth - @hta) <= 0 THEN 1
						ELSE - 1					
						END		 
				WHEN 411 THEN --1H Draw No Bet
					CASE 
						WHEN (@hth - @hta) = 0 THEN 0
						WHEN betteam = 'h' AND (@hth - @hta) > 0 THEN 1
						WHEN betteam = 'a' AND (@hth - @hta) < 0 THEN 1
						ELSE -1
						END
				WHEN 412 THEN --Exact 1st Half Goal
					CASE 
						WHEN betteam <> '3&over' AND CAST(betteam AS INT) = (@hth + @hta) THEN 1
						WHEN betteam = '3&over' AND (@hth + @hta) >= 3 THEN 1
						ELSE -1
						END
				WHEN 413 THEN --Correct Score (aos)
					CASE 
						WHEN betteam NOT IN ('AOS')
							AND (@fth > LEFT(betteam,1) OR @fta > RIGHT(betteam,1)) THEN -1
						WHEN betteam = 'AOS'
							AND CHARINDEX(CAST(@fth AS VARCHAR) + ':' + CAST(@fta AS VARCHAR), transdesc) < 0 THEN 1
						ELSE -1
						END
				WHEN 414 THEN --1H Correct Score (aos)
					CASE
						WHEN betteam NOT IN ('AOS')
							AND (@hth > LEFT(betteam,1) OR @hth > RIGHT(betteam,1)) THEN -1
						WHEN betteam = 'AOS'
							AND CHARINDEX(CAST(@hth AS VARCHAR) + ':' + CAST(@hth AS VARCHAR), transdesc) < 0 THEN 1
						ELSE -1
						END

				-- Tennis Sporting Solution 
				WHEN 1301 THEN -- Match Winner 
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
						END
				WHEN 1302 THEN -- Match Correct Score 
					CASE 
						WHEN betteam = (CAST(@fth AS VARCHAR(4)) + CAST(@fta AS VARCHAR(4))) THEN 1
						ELSE - 1
						END
				WHEN 1303 THEN -- Set Handicap 
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
						END
				WHEN 1305 THEN -- Match Total Games Odd/Even
					CASE WHEN betteam = N'h' AND (@TotalGameHomeMatch + @TotalGameAwayMatch)%2 = 1 THEN 1 
						 WHEN betteam = N'a' AND (@TotalGameHomeMatch + @TotalGameAwayMatch)%2 = 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 1306 THEN -- Match Total Games Over/Under - 1306
					CASE betteam 
						WHEN N'h' THEN  (@TotalGameHomeMatch + @TotalGameAwayMatch) - hdp1 
						WHEN N'a' THEN  hdp1 - (@TotalGameHomeMatch + @TotalGameAwayMatch) 
						END 
				WHEN 1308 THEN  -- Match Games Handicap - 1308
					CASE betteam 
						WHEN N'h' THEN (hdp2 - hdp1) + (@TotalGameHomeMatch - livehomescore) - (@TotalGameAwayMatch - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@TotalGameHomeMatch - livehomescore) + (@TotalGameAwayMatch - liveawayscore)
						END 
				WHEN 1311 THEN -- Set x Winner - 1311
					CASE betteam 
						WHEN N'h' THEN (@TotalGameHomeSetx - @TotalGameAwaySetx)
						WHEN N'a' THEN (@TotalGameAwaySetx - @TotalGameHomeSetx)
						END 
				WHEN 1312 THEN --Set x Total Games Over/Under - 1312
					CASE betteam 
						WHEN N'o' THEN (@TotalGameHomeSetx + @TotalGameAwaySetx) - hdp1 
						WHEN N'u' THEN hdp1 - (@TotalGameHomeSetx + @TotalGameAwaySetx) 
						END
				WHEN 1316 THEN -- Set x Game Handicap
					CASE betteam
						WHEN N'h' THEN (hdp2 - hdp1) + (@TotalGameHomeSetx - livehomescore) - (@TotalGameAwaySetx - liveawayscore)
						WHEN N'a' THEN (hdp1 - hdp2) - (@TotalGameHomeSetx - livehomescore) + (@TotalGameAwaySetx - liveawayscore)
						END
				WHEN 1317 THEN -- Set x Correct Score
					CASE 
						WHEN betteam = (CASE WHEN @TotalGameHomeSetx > 7 AND (@TotalGameHomeSetx - @TotalGameAwaySetx)>=2 THEN 'haos'
											 WHEN @TotalGameAwaySetx > 7 AND (@TotalGameAwaySetx - @TotalGameHomeSetx)>=2 THEN 'aaos'
											 ELSE (CAST(@TotalGameHomeSetx AS VARCHAR(4)) + CAST(@TotalGameAwaySetx AS VARCHAR(4))) 
											 END) THEN 1
						ELSE - 1
						END
				WHEN 1318 THEN -- Set x Total Games Odd/Even
					CASE WHEN betteam = N'o' AND (@TotalGameHomeSetx + @TotalGameAwaySetx)%2 = 1 THEN 1 
						 WHEN betteam = N'e' AND (@TotalGameHomeSetx + @TotalGameAwaySetx)%2 = 0 THEN 1 
						 ELSE - 1 
						 END 
				WHEN 1324 THEN -- Set x Game y Winner 
					CASE WHEN betteam =N'h' AND CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,4),@SetxGameyHomeWON)>0 THEN 1 
						 WHEN betteam =N'a' AND CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,4),@SetxGameyAwayWON)>0 THEN 1   
						 WHEN CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,4),@SetxGameyDRAW)>0 THEN 0 
						 WHEN CHARINDEX(SUBSTRING(CAST(betcheck AS VARCHAR(10)),2,4),@SetxGameyREFUND)>0 THEN 0
						 ELSE -1 END
				ELSE NULL -- Not support bettype
				END
			,-- CASE bettype
			-- ========================
			winlostdate = @matchdate
			,statusID = CASE 
				WHEN @modds IS NULL THEN 0
				WHEN @modds = 0 AND @isRefundGame = 0 THEN 111
				WHEN @modds = 0 AND @isRefundGame = 1 THEN 103 
				WHEN @modds < 0 THEN 113
				WHEN @modds > 0 THEN 112
				END
			,statuswinlost = CASE 
				WHEN @modds <= - 0.5 THEN 4 -- LOSE
				WHEN @modds >= 0.5 THEN 2 -- WIN
				WHEN @modds > 0 THEN 1 -- Half WIN
				WHEN @modds < 0 THEN 3 -- Half LOSE
				ELSE 0 -- DRAW
				END
		-- ========================
		FROM dbo.BetParlayDetail pd WITH (UPDLOCK, INDEX = IX_matchid)
		WHERE bettype not IN (14, 127) AND matchid = @matchid AND statusID NOT IN (101, 102)
		--AND pd.bettype = CASE WHEN ISNULL(@resultPS, '') = '' AND bettype <> 135 THEN pd.bettype
		--					  WHEN ISNULL(@resultPS, '') <> '' THEN 135
		--			     END
		AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		AND 1 = CASE WHEN @SelectedSetCAL IS NULL AND @SelectedSetREFUND IS NULL THEN 1 
					 WHEN @SelectedSetCAL LIKE '%1%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '801%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%2%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '802%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%3%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '803%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%4%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '804%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%5%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND betcheck LIKE '805%' THEN 1 
					 WHEN @SelectedSetCAL LIKE '%6%' AND Bettype IN (1,2,3,20,153,1301,1302,1303,1305,1306,1308) THEN 1
					 WHEN @SelectedSetREFUND LIKE '%1%' AND Bettype = 1324 AND betcheck LIKE '801%' THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%2%' AND Bettype = 1324 AND betcheck LIKE '802%' THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%3%' AND Bettype = 1324 AND betcheck LIKE '803%' THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%4%' AND Bettype = 1324 AND betcheck LIKE '804%' THEN 1 
					 WHEN @SelectedSetREFUND LIKE '%5%' AND Bettype = 1324 AND betcheck LIKE '805%' THEN 1  
					 ELSE 0 
					 END 

		AND 1 = CASE WHEN @ResourceIDsCAL IS NULL AND Bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217) THEN 1  
					 WHEN @ResourceIDsCAL IS NOT NULL 
							AND Bettype IN (160,164,169,180) 
							AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(20)),2,5),@ResourceIDsCAL)>0 THEN 1 
					WHEN @ResourceIDsCAL IS NOT NULL 
								AND Bettype IN (135,168,173,174,175,176,192,193,210,211,212,213,214,215,216,217) 
								AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDsCAL)>0 THEN 1 
					ELSE 0 END   --Betradar 2 Auto Bettypes 
							
		AND bettype NOT BETWEEN 1501 and 1599 -- Keno
		
	END
END
	-- ===================================================
	-- ===================================================
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_9m] TO [vnteam] AS [dbo]