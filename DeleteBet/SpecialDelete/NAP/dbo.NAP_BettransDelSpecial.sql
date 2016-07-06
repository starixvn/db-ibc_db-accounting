ALTER PROCEDURE [dbo].[NAP_BettransDelSpecial]
	@MatchId				INT,
	
	@FromTransId			BIGINT, 
	@ToTransId				BIGINT, 
		
	@Handicap 				SMALLMONEY		= 9999,		-- 1, 3, 7, 8, 17, 153, 183, 1303, 1306, 1308: Handicap, Odd/Even, Over/Under...
	@Handicap155			SMALLMONEY		= 9999,		-- 155, 1316 : FT.1X2, 1H 1X2, First Ten Minutes 1X2, 2H 1X2...
	@Handicap178			SMALLMONEY		= 9999,		-- 178,197,198,204,205, 401, 402, 403, 404: 2H Over/Under...
	@OverUnder156			SMALLMONEY		= 9999,		-- 156, 1312 
	
	@LiveIndicator 			SMALLINT 		= 0,
    @LiveHomeScore 			SMALLINT 		= NULL,
    @LiveAwayScore 			SMALLINT 		= NULL,
    
    @FromTransdate			DATETIME 		= NULL,
	@ToTransdate			DATETIME 		= NULL,
	
    @BetTypes				VARCHAR(1000)	= '',
	
	@BetTeam1378			NVARCHAR(10)	= 'ALL',	-- 1, 2, 3, 7, 8, 12, 17, 20, 153,157,168,183,185,191, 1301, 1303, 1305, 1306, 1308 , 411, 501: Handicap, Odd/Even, Over/Under...
	@BetTeam515				NVARCHAR(10)	= 'ALL',	-- 5,15,160,164,167,176,177,180
	@BetTeam430				VARCHAR(120) 	= '',		-- 4, 30, 405, 413, 414: All Correct Scores
    @BetTeam6				VARCHAR(120) 	= '',		-- 6, 126, 131, 132
	@BetTeam14				VARCHAR(120) 	= '',
	@BetTeam16				VARCHAR(120) 	= '',
	@BetTeam128 			VARCHAR(120) 	= '',
	@BetTeam129 			VARCHAR(120) 	= '',		-- 129, 130
	@BetTeam136 			VARCHAR(10)		= 'ALL',	-- 136, 137, 138, 139, 184,194,203
	@BetTeam143 			VARCHAR(120)	= '',		-- 143, 144, 163
	@BetTeam154				VARCHAR(3)		= 'ALL', 	-- 154, 155, 1311, 1316 
	@BetTeam156				VARCHAR(3)		= 'ALL', 	-- 156, 1312 
	@BetTeam1302			VARCHAR(120)	= 'ALL', 	-- 1302 
	@BetTeam1317			VARCHAR(120)	= 'ALL', 	-- 1317 
	@BetTeam1318			VARCHAR(3)		= 'ALL', 	-- 1318 	
	@BetTeam1324			VARCHAR(3)		= 'ALL', 	-- 1324
	@BetTeam178				VARCHAR(10)		= 'ALL',	-- 178,197,198,204,205, 401, 402, 403, 404: 2H Over/Under...
	@BetTeam165				VARCHAR(120)	= 'ALL',	-- 165,166
	@BetTeam159				VARCHAR(120)	= 'ALL',	-- 159,179,406: All Exact Total Goals
	@BetTeam161				VARCHAR(120)	= 'ALL',	-- 161,162,181,182,407,409,412
	@BetTeam199				VARCHAR(120)	= 'ALL',	-- 199
	@BetTeam202				VARCHAR(120)	= 'ALL',	-- 202
	@BetTeam195				VARCHAR(120)	= 'ALL',	-- 195,196
	@BetTeam200				VARCHAR(120)	= 'ALL',	-- 200,201
	@BetTeam169				VARCHAR(120)	= 'ALL',	-- 169,193
	@BetTeam210				VARCHAR(10)		= 'ALL',	-- 210,173,174,188,189,190,211,212,123,214,215,133,134,135,145,146,147,148,149,150
	@BetTeam216				VARCHAR(240)	= 'ALL',	-- 216
	@BetTeam408				VARCHAR(120)	= 'ALL',	-- 171,408: Winning Margin	
	@BetTeam24				VARCHAR(120)	= 'ALL',	-- 24, 151, 186, 410: All Double Chance
	
	@Set154					VARCHAR(3)		= 'ALL', 	-- 154, 155, 1311, 1316 
	@Set156					VARCHAR(3)		= 'ALL', 	-- 156, 1312 
	@Set1317				VARCHAR(3)		= 'ALL', 	-- 1317
	@Set1318				VARCHAR(3)		= 'ALL', 	-- 1318 
	@Set1324				VARCHAR(3)		= 'ALL', 	-- 1324 
	
	@Game1324				VARCHAR(3)		= 'ALL', 	-- 1324 
	
	@BetID160				TINYINT			= 100,		--160,164,180
	
    @UserName 				NVARCHAR(50),
    @UserPassword			NVARCHAR(50),
    @UserID					INT,
    @IP						VARCHAR(15)		= '',
    @Reason					NVARCHAR(500)	= '',	
	@SecondAcceptFlag		TINYINT			= 0 ,
    
	@TransIds				VARCHAR(MAX)	= '',
	@TransIdSolds			VARCHAR(MAX)	= '', -- just for BetTrade's subticket (transid of bettype 901)  	

	@InvalidTrans			VARCHAR(MAX)	= ''	OUTPUT, -- invalid trans of BTrade
	@ErrMsg					NVARCHAR(200)	= ''	OUTPUT,
    @ErrCode				INT				= 0		OUTPUT

AS
	/*
	Created by: Kathy
	Task : Special Delete
	DB: DBTXN/bodb02
	Original:

	Revisions:
		- 20140102@Kathy: Add username2 column [Redmine:#10270]
		- 20140121@Elodie: Apply LAS system for special delete function [Redmine:#10701]
		- 20140411@Kathy: - Separate tickets of Bet Fair, OneExchange 3rd parties [Redmine:#10128]
						  - Add 2 new bettypes 1H Total Goal and 1H First Goal/ Last Goal (126, 127) [Redmine:#14749]
		- 20140701@Kathy: Apply BetRadar - change @BetTypes to varchar(1000) [Redmine:#18219]
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]		
		- 20140806@Kathy: Support new 11 bettypes [Redmine:#19955]
		- 20140929@Kathy: - Offer new bettypes from Sportting Solutions and new IBC bettypes [Redmine:#23129]
						  - Add moneyline in filter
		- 20141125@Kathy: Add betid column [Redmine:##26489]
		- 20141204@Kathy: Remove codes which are used in checking permission on DBPolicy [Redmine:#27058]	
		- 20150402@Dominic: Add new 60 bettypes [Redmine:#27214]
		- 20150615@Dominic: BetTrade Integration 	[Redmine:#36964]			
		- 20150806@Kathy: Using new balance table (BalCreditSportsPending,BalDebitSportsPending) [Redmine:#40125]
		- 20150917@Patrick: #43565: Show error-message in case user clicks void button but no tickets are found
		- 20151008@Kathy: insert bettrade tickets to send API [Redmine:#43233]
		- 20151021@Kathy: Do not show ticket 901 if its owner is not BetTrade account(betdaqid = 0)[Redmine:#43233]
		- 20151103@Kathy: Enhance performance [Redmine:#43233]
		- 20150712@Kathy: - Apply 28 Live Bettypes(PH) [Redmine: #48110]
						  - Database - Change datatype [Redmine: #48660]
		- 20150119@Kathy: Changes for phase 1.2 of PH All in One: bettype 4,30,413,414,405 [Redmine:#50932]	  
		- 20160112@Patrick: Support Cricket [Redmine: #50688]
		- 20160401@Bobby: #55354 - Update changes for new message structure
		- 20160405@Kathy: Allow to void settled ticket [Redmine:#54344]
		- 20160706@Kathy: Get Refno for Lucky Single Ticket [R
		
	Param's Explanation: Special bet delete option
		- @SecondAcceptFlag: 
		  + 0: All tickets
		  + 1: Normal tickets only
		  + 2: SA tickets only
     
		-@LiveIndicator:
		 + 0: Dead
		 + 1: Live
		 + 2: All

	*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @isITAdmin			BIT = 0
			,@isExistBT			BIT = 0
			,@isExistOutright 	BIT = 0
			,@isExistMatch		BIT = 0
			,@avaiableProcess	BIT = 0
			
	CREATE TABLE #tblBettype (bettype SMALLINT PRIMARY KEY)	
	
	CREATE TABLE #tblTransIds (transid BIGINT PRIMARY KEY)	
	
	CREATE TABLE #tblTransIdSolds (grouptransid BIGINT, transid BIGINT PRIMARY KEY)
	
	CREATE TABLE #tblMatchProcess (matchid INT, KeyID TINYINT)
	
	CREATE TABLE #BetDelete (
		grouptransid		BIGINT,
		transid				BIGINT PRIMARY KEY, 
		custid				INT, 
		recommend			INT, 
		mrecommend			INT, 
		srecommend			INT, 
		betfrom				NVARCHAR(1),
		statusID			INT, 
		status				NVARCHAR(10), 
		username			VARCHAR(30),
		username2			VARCHAR(50),
		SecAcceptFlag		BIT, 
		creator				INT,
		creatorName			VARCHAR(30), 
		hdp1 				SMALLMONEY,  
		hdp2 				SMALLMONEY,
		bettype 			SMALLINT, 
		betteam 			NVARCHAR(10),
		betcheck			NVARCHAR(50),
		odds				MONEY, 
		OddsType			INT,
		transdate			DATETIME,
		IsLiveIndicator		BIT,
		livehomescore 		SMALLINT, 
		liveawayscore 		SMALLINT,
		Stake				MONEY,
		CurrencyName		VARCHAR(10),
		betid				BIGINT,
		betdaqid			BIGINT,
		TransDesc			NVARCHAR(1000),
		refno				BIGINT
		)
	DECLARE @tblInvalidTrans TABLE (transid BIGINT) -- store invalid BT transid
	
	DECLARE @Remark			VARCHAR(500)
			,@KeyID			INT
			,@eventdate		DATETIME --Check settled Date
			,@LogData		NVARCHAR(500)
	
	SET @InvalidTrans = ''
			
	-- Check password	
	IF NOT EXISTS (SELECT 1
					FROM custDB.dbo.customer WITH(NOLOCK)
					WHERE userpwd = @UserPassword
						AND custid = @UserID
						AND roleid>=5)
	BEGIN
		SELECT @LogData ='fail to void bet for matchid ' + CONVERT(VARCHAR(20), 
			@MatchId) + ' from ' + CONVERT(VARCHAR(20), @FromTransId) + ' to ' + CONVERT(VARCHAR(20), @ToTransId) + ' reason: ' + @Reason
			
		EXEC WriteLog_UserLog 
			@UserID = @UserID, 
			@Doing	= @LogData
			
		SELECT @ErrMsg = 'Sorry. You can not process void bet due to either wrong password or insufficient permission!'
			,@ErrCode  = 101   
		
		RETURN
	END	
			
	BEGIN TRY
		INSERT INTO #tblTransIds (transid)
		SELECT DISTINCT val FROM dbo.strSplit(@TransIds,',')		
		
		IF ISNULL(@TransIdSolds,'') <> ''
			INSERT INTO #tblTransIdSolds(grouptransid, transid)
			SELECT  refno, transid
			FROM	dbo.bettrans sub WITH(NOLOCK)
			WHERE	transid IN (SELECT val FROM dbo.strSplit(@TransIdSolds,','))
					AND bettype = 901
	END TRY
	BEGIN CATCH
		SELECT	@ErrCode = 101
				,@ErrMsg = 'Invalid TransIds.'
		
		RETURN
	END CATCH
	
	INSERT INTO #tblBettype(bettype)
	SELECT  val
	FROM	dbo.strSplit(@BetTypes, '^')
	
	-- check and not allow attempt to void tickets of this match while it's being calculated
	---------------------------------------------------------------------------
	IF EXISTS(SELECT TOP 1 1 FROM #tblBettype WHERE bettype = 10) -- bettype 10: outright
	BEGIN 	
		SELECT @KeyID 			= 2
			,@isExistOutright 	= 1
			, @isExistMatch		= 0
	END
	ELSE
	BEGIN 	
		SELECT @KeyID 			= 1
			,@isExistOutright 	= 0
			, @isExistMatch		= 1
	END
	
	INSERT INTO #tblMatchProcess (matchid, KeyID)
	SELECT @matchid AS matchid
		, @KeyID 	AS KeyID
		
	-- checking SD proccess
	EXEC dbo.NAP_Admin_CheckingProcess
		@isExistOutright 	= @isExistOutright
		, @isExistMatch		= @isExistMatch
		, @avaiableProcess 	= @avaiableProcess OUTPUT
		, @ErrCode			= @ErrCode OUTPUT
		, @ErrMsg			= @ErrMsg OUTPUT

	IF(@ErrCode <> 0 OR @avaiableProcess = 0) 
		RETURN
		

	------------------***** Insert all data into #BetDelete *****------------------
	-- bettype <> 4 - Handicap(1), Over/Under(3), 1st Handicap(7), 1st Over/Under(8) - FT.1X2(5)/ 1st 1X2(15)
	INSERT INTO #BetDelete (
			grouptransid	
			,transid			
			,custid			
			,recommend		
			,mrecommend		
			,srecommend		
			,betfrom			
			,statusID		
			,status			
			,SecAcceptFlag
			,creator
			,hdp1 			
			,hdp2 			
			,bettype 		
			,betteam 		
			,betcheck		
			,odds			
			,OddsType		
			,transdate		
			,IsLiveIndicator	
			,livehomescore 	
			,liveawayscore 	
			,Stake			
			,CurrencyName	
			,betid			
			,betdaqid
			,refno
	)
	SELECT	b.transid
			,b.transid
			,b.custid
			,b.recommend
			,b.mrecommend
			,b.srecommend
			,b.betfrom
			,b.statusID
			,b.STATUS
			,b.SecAcceptFlag
			,b.creator
			,b.hdp1
			,b.hdp2
			,b.bettype
			,b.betteam
			,b.betcheck
			,b.odds
			,b.oddstype
			,b.transdate
			,b.liveindicator
			,b.livehomescore
			,b.liveawayscore
			,b.stake
			,b.CurrencyName
			,b.betid
			,b.betdaqid
			,b.refno
	FROM	dbo.bettrans b WITH (NOLOCK)
		INNER JOIN #tblTransIds t 
			ON	t.transid = b.transid
		INNER JOIN #tblBettype tp 
			ON	tp.bettype = b.bettype		
	WHERE	b.matchid=@matchid 
			AND b.transid between @FromTransId AND @ToTransId
			AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
			AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END 
			AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END 
			AND b.transdate between CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END
								AND CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
			AND b.betteam = CASE WHEN b.bettype IN (1,2, 3,7,8,12, 17, 20, 153, 157, 168, 183, 185, 191, 1301, 1303, 1305, 1306, 1308, 411, 501) THEN CASE WHEN @BetTeam1378 = 'ALL' THEN b.betteam ELSE @BetTeam1378 END
								WHEN b.bettype IN (5,15,160,164,167,176,177,180) THEN CASE WHEN @BetTeam515 = 'ALL' THEN b.betteam ELSE @BetTeam515 END
								ELSE b.betteam END 
			AND CASE 
					WHEN b.bettype IN (171,408) AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam408 = 'All' THEN betteam ELSE @BetTeam408 END,'^'))  THEN 1
					WHEN  b.bettype IN (24, 151, 186, 410) AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam24 = 'All' THEN betteam ELSE @BetTeam24 END,'^')) THEN 1
					WHEN b.bettype NOT IN (171,408,24, 151, 186, 410) THEN 1
					ELSE 0
					END = 1
			AND CASE WHEN b.bettype IN (160,164,180) 
							THEN CASE WHEN @BetID160=100 THEN ISNULL(b.betID ,0)
							ELSE 
								CASE WHEN b.bettype = 160 THEN (816000 + @BetID160) 
									 WHEN b.bettype = 164 THEN (816400 + @BetID160)
									 WHEN b.bettype = 180 THEN (818000 + @BetID160)
								END
							END
					ELSE ISNULL(b.betID,0)
				END = ISNULL(b.betID,0)
			AND b.bettype NOT IN(4,6,14,16,30, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 
									143, 144, 145, 146, 147, 148, 149, 150,
									154, 155, 156, 159, 161, 162, 163, 165, 166, 169, 
									173, 174, 178, 179, 181, 182, 184, 188, 189, 
									190, 193, 194, 195, 196, 197, 198, 199,
									200, 201, 202, 203, 204, 205, 210, 211, 212, 213, 214, 215, 216,
									1302, 1311, 1312, 1316, 1317, 1318, 1324,
									401, 402, 403, 404, 405, 406, 407, 409, 412, 413, 414)
			AND CASE WHEN b.bettype IN (1,3,7,8, 17, 153, 183, 1303, 1306, 1308) THEN CASE WHEN @Handicap = 9999 THEN 1
															WHEN @Handicap = (hdp1 + hdp2) THEN 1
														ELSE 0 END 
				ELSE 1 END = 1
			AND ISNULL(b.SecAcceptFlag, 0)  = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(b.SecAcceptFlag, 0)  
															 WHEN 1 THEN 0 
															 WHEN 2 THEN 1 END
					 
	-- bettype = 4,30,405, 413, 414 -- Correct score
	IF EXISTS( SELECT TOP 1 1 FROM #tblBettype WHERE bettype IN (4,30,405,413,414) ) 
		INSERT INTO #BetDelete(
				grouptransid	
				,transid			
				,custid			
				,recommend		
				,mrecommend		
				,srecommend		
				,betfrom			
				,statusID		
				,status			
				,SecAcceptFlag		
				,creator					
				,hdp1 			
				,hdp2 			
				,bettype 		
				,betteam 		
				,betcheck		
				,odds			
				,OddsType		
				,transdate		
				,IsLiveIndicator	
				,livehomescore 	
				,liveawayscore 	
				,Stake			
				,CurrencyName	
				,betid			
				,betdaqid
				,TransDesc
				,refno
		)
		SELECT	b.transid
				,b.transid
				,b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,b.betfrom
				,b.statusID
				,b.STATUS
				,b.SecAcceptFlag
				,b.creator			
				,b.hdp1
				,b.hdp2
				,b.bettype
				,b.betteam
				,b.betcheck
				,b.odds
				,b.oddstype
				,b.transdate
				,b.liveindicator
				,b.livehomescore
				,b.liveawayscore
				,b.stake
				,b.CurrencyName
				,b.betid
				,b.betdaqid
				,b.transdesc
				,b.refno
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #tblTransIds t 
				ON	t.transid = b.transid
			INNER JOIN #tblBettype tp 
				ON	tp.bettype = b.bettype				
		WHERE	b.matchid=@matchid
				AND b.transid between @FromTransId AND @ToTransId
				AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
				AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
				AND b.bettype in (4,30,405,413,414)
				AND (@betteam430 = 'ALL' 
					OR (
						(b.bettype IN (4, 405,413,414) 
							OR (b.bettype = 30 AND b.betteam NOT IN ('4:0', '0:4'))
						) AND b.betteam IN (SELECT val FROM dbo.strSplit(@betteam430,'^'))
					)
					OR (b.bettype = 30 AND b.betteam = '4:0' AND '4:0up' IN (SELECT val FROM dbo.strSplit(@betteam430,'^')))
					OR (b.bettype = 30 AND b.betteam = '0:4' AND '0:4up' IN (SELECT val FROM dbo.strSplit(@betteam430,'^')))
				)
				AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
															 WHEN 1 THEN 0 
															 WHEN 2 THEN 1 END


	-- bettype = 6: Total Goal; 126: 1st Total Goal, 131: Home Team Total Goal; 132:  Away Team Total Goal
	IF EXISTS( SELECT TOP 1 1 FROM #tblBettype WHERE bettype IN (6, 126, 131, 132) )
		INSERT INTO #BetDelete (
				grouptransid	
				,transid			
				,custid			
				,recommend		
				,mrecommend		
				,srecommend		
				,betfrom			
				,statusID		
				,status			
				,SecAcceptFlag	
				,creator					
				,hdp1 			
				,hdp2 			
				,bettype 		
				,betteam 		
				,betcheck		
				,odds			
				,OddsType		
				,transdate		
				,IsLiveIndicator	
				,livehomescore 	
				,liveawayscore 	
				,Stake			
				,CurrencyName	
				,betid			
				,betdaqid
				,refno
		)
		SELECT	b.transid
				,b.transid
				,b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,b.betfrom
				,b.statusID
				,b.STATUS
				,b.SecAcceptFlag	
				,b.creator			
				,b.hdp1
				,b.hdp2
				,b.bettype
				,b.betteam
				,b.betcheck
				,b.odds
				,b.oddstype
				,b.transdate
				,b.liveindicator
				,b.livehomescore
				,b.liveawayscore
				,b.stake
				,b.CurrencyName
				,b.betid
				,b.betdaqid
				,b.refno
		FROM	dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #tblTransIds t 
				ON	t.transid = b.transid
			INNER JOIN #tblBettype tp 
				ON	tp.bettype = b.bettype				
			LEFT JOIN dbo.strSplit(@betteam6,'^') AS bt 
				ON	bt.val=b.betteam
		WHERE	b.matchid=@matchid
				AND b.transid between @FromTransId AND @ToTransId	
				AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
				AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 	
				AND b.bettype IN (6, 126, 131, 132)
				AND (@betteam6='All' OR bt.val IS NOT NULL)
				AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
															 WHEN 1 THEN 0 
															 WHEN 2 THEN 1 END

	-- bettype = 14: First Goal/Last Goal; 127: 1st FGLG
	IF EXISTS( SELECT TOP 1 1 FROM #tblBettype WHERE bettype IN (14, 127) )
		INSERT INTO #BetDelete  (
				grouptransid	
				,transid			
				,custid			
				,recommend		
				,mrecommend		
				,srecommend		
				,betfrom			
				,statusID		
				,status			
				,SecAcceptFlag	
				,creator					
				,hdp1 			
				,hdp2 			
				,bettype 		
				,betteam 		
				,betcheck		
				,odds			
				,OddsType		
				,transdate		
				,IsLiveIndicator	
				,livehomescore 	
				,liveawayscore 	
				,Stake			
				,CurrencyName	
				,betid			
				,betdaqid
				,refno
		)
		SELECT	b.transid
				,b.transid
				,b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,b.betfrom
				,b.statusID
				,b.STATUS
				,b.SecAcceptFlag
				,b.creator				
				,b.hdp1
				,b.hdp2
				,b.bettype
				,b.betteam
				,b.betcheck
				,b.odds
				,b.oddstype
				,b.transdate
				,b.liveindicator
				,b.livehomescore
				,b.liveawayscore
				,b.stake
				,b.CurrencyName
				,b.betid
				,b.betdaqid
				,b.refno
		FROM	dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #tblTransIds t 
				ON	t.transid = b.transid
			INNER JOIN #tblBettype tp 
				ON	tp.bettype = b.bettype		
			LEFT JOIN dbo.strSplit(@betteam14,'^') AS bt 
				ON	b.betteam=CONVERT(VARCHAR(3),bt.val)
		WHERE	b.matchid=@matchid
				AND b.transid between @FromTransId AND @ToTransId
				AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
				AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
				AND b.bettype IN (14, 127)
				AND (@betteam14='All' OR bt.val IS NOT NULL)
				AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END

	-- bettype = 16: HT/FT
	IF EXISTS( SELECT TOP 1 1 FROM #tblBettype WHERE bettype = 16 )
		INSERT INTO #BetDelete(
				grouptransid	
				,transid			
				,custid			
				,recommend		
				,mrecommend		
				,srecommend		
				,betfrom			
				,statusID		
				,status			
				,SecAcceptFlag	
				,creator					
				,hdp1 			
				,hdp2 			
				,bettype 		
				,betteam 		
				,betcheck		
				,odds			
				,OddsType		
				,transdate		
				,IsLiveIndicator	
				,livehomescore 	
				,liveawayscore 	
				,Stake			
				,CurrencyName	
				,betid			
				,betdaqid
				,refno
		)
		SELECT	b.transid
				,b.transid
				,b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,b.betfrom
				,b.statusID
				,b.STATUS
				,b.SecAcceptFlag
				,b.creator								
				,b.hdp1
				,b.hdp2
				,b.bettype
				,b.betteam
				,b.betcheck
				,b.odds
				,b.oddstype
				,b.transdate
				,b.liveindicator
				,b.livehomescore
				,b.liveawayscore
				,b.stake
				,b.CurrencyName
				,b.betid
				,b.betdaqid
				,b.refno
		FROM	dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #tblTransIds t 
				ON	t.transid = b.transid
			INNER JOIN #tblBettype tp 
				ON	tp.bettype = b.bettype		
			LEFT JOIN dbo.strSplit(@betteam16,'^') AS bt 
				ON	bt.val=b.betteam
		WHERE	b.matchid=@matchid
				AND b.transid between @FromTransId AND @ToTransId		
				AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator	
				AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
				AND b.bettype = 16
				AND (@betteam16='All' OR bt.val IS NOT NULL)
				AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 then ISNULL(SecAcceptFlag,0) 
															WHEN 1 THEN 0 
															WHEN 2 THEN 1 END				
													 									
	-- bettype = 128, 129, 130, 136, 137, 138, 139, 143, 144, 163, 184,194,203
	IF EXISTS( SELECT TOP 1 1 FROM #tblBettype WHERE bettype IN (128, 129, 130, 136, 137, 138, 139, 143, 144, 163, 184,194,203) )
		INSERT INTO #BetDelete(
				grouptransid	
				,transid			
				,custid			
				,recommend		
				,mrecommend		
				,srecommend		
				,betfrom			
				,statusID		
				,status			
				,SecAcceptFlag	
				,creator						
				,hdp1 			
				,hdp2 			
				,bettype 		
				,betteam 		
				,betcheck		
				,odds			
				,OddsType		
				,transdate		
				,IsLiveIndicator	
				,livehomescore 	
				,liveawayscore 	
				,Stake			
				,CurrencyName	
				,betid			
				,betdaqid
				,refno
		)
		SELECT	b.transid
				,b.transid
				,b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,b.betfrom
				,b.statusID
				,b.STATUS
				,b.SecAcceptFlag
				,b.creator				
				,b.hdp1
				,b.hdp2
				,b.bettype
				,b.betteam
				,b.betcheck
				,b.odds
				,b.oddstype
				,b.transdate
				,b.liveindicator
				,b.livehomescore
				,b.liveawayscore
				,b.stake
				,b.CurrencyName
				,b.betid
				,b.betdaqid
				,b.refno
		FROM	dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #tblTransIds t 
				ON	t.transid = b.transid
			INNER JOIN #tblBettype tp 
				ON	tp.bettype = b.bettype		
		WHERE	b.matchid=@matchid            
				AND b.transid between @FromTransId AND @ToTransId		
				AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator	
				AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
				AND b.bettype in (128, 129, 130, 136, 137, 138, 139, 143, 144, 163, 184,194,203)
				AND(
					(
					  b.bettype IN(128)
					  AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam128 = 'All' THEN betteam ELSE @BetTeam128 END,'^'))  
					)			
					OR
					(
					  b.bettype IN (129, 130) 
					  AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam129 = 'All' THEN betteam ELSE @BetTeam129 END,'^'))  
					)
					OR
					(
					  b.bettype IN (136, 137, 138, 139, 184,194,203) 
					  AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam136 = 'All' THEN betteam ELSE @BetTeam136 END,'^'))  
					)
					OR
					(
					  b.bettype IN (143, 144, 163) 
					  AND b.betteam  IN (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @BetTeam143 = 'All' THEN betteam ELSE @BetTeam143 END,'^'))  
					)
				)
				AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 then ISNULL(SecAcceptFlag,0) 
															WHEN 1 THEN 0 
															WHEN 2 THEN 1 END	
																						
	-- bettype = 154, 155, 156, 1302, 1311, 1312, 1316, 1317, 1318, 1324
	IF EXISTS( SELECT TOP 1 1 FROM #tblBettype WHERE bettype IN (154, 155, 156, 1302, 1311, 1312, 1316, 1317, 1318, 1324) )
		INSERT INTO #BetDelete(
				grouptransid	
				,transid			
				,custid			
				,recommend		
				,mrecommend		
				,srecommend		
				,betfrom			
				,statusID		
				,status			
				,SecAcceptFlag	
				,creator										
				,hdp1 			
				,hdp2 			
				,bettype 		
				,betteam 		
				,betcheck		
				,odds			
				,OddsType		
				,transdate		
				,IsLiveIndicator	
				,livehomescore 	
				,liveawayscore 	
				,Stake			
				,CurrencyName	
				,betid			
				,betdaqid
				,refno
		)
		SELECT	b.transid
				,b.transid
				,b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,b.betfrom
				,b.statusID
				,b.STATUS
				,b.SecAcceptFlag	
				,b.creator							
				,b.hdp1
				,b.hdp2
				,b.bettype
				,b.betteam
				,b.betcheck
				,b.odds
				,b.oddstype
				,b.transdate
				,b.liveindicator
				,b.livehomescore
				,b.liveawayscore
				,b.stake
				,b.CurrencyName
				,b.betid
				,b.betdaqid
				,b.refno
		FROM	dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #tblTransIds t 
				ON	t.transid = b.transid
			INNER JOIN #tblBettype tp 
				ON	tp.bettype = b.bettype					
		WHERE	b.matchid=@matchid           
				AND b.transid between @FromTransId AND @ToTransId		
				AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator	
				AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 
				AND b.bettype IN (154, 155, 156, 1302, 1311, 1312, 1316, 1317, 1318, 1324)
				AND (
					(
					  b.bettype IN (154, 155, 1311, 1316)	
					  AND b.betid = CASE WHEN @Set154 = 'ALL' THEN b.betid ELSE @Set154 END
					  AND (@BetTeam154 = 'ALL' OR b.betteam = @BetTeam154)
					)
					OR
					(
					  b.bettype IN (156, 1312)
					  AND b.betid = CASE WHEN @Set156 = 'ALL' THEN b.betid ELSE @Set156 END
					  AND (@BetTeam156 = 'ALL' OR b.betteam = @BetTeam156)
					)
					OR
					(
					  b.bettype = 1302 
					  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam1302 = 'ALL' THEN b.betteam ELSE @BetTeam1302 END, '^'))
					)
					OR
					(
					  b.bettype = 1318
					  AND b.betid = CASE WHEN @Set1318 = 'ALL' THEN b.betid ELSE @Set1318 END
					  AND (@BetTeam1318 = 'ALL' OR b.betteam = @BetTeam1318)
					)
					OR
					(
					  b.bettype = 1317
					  AND b.betid = CASE WHEN @Set1317 = 'ALL' THEN b.betid ELSE @Set1317 END
					  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam1317 = 'ALL' THEN b.betteam ELSE @BetTeam1317 END, '^'))
					)
					OR
					(
					  b.bettype = 1324
					  AND LEFT(b.betid, 3) = CASE WHEN @Set1324 = 'ALL' THEN LEFT(betid, 3) ELSE @Set1324 END -- Set
					  AND ((@Game1324 = 'ALL') OR (@Game1324 = '13' AND RIGHT(betid,2) >=13) OR (RIGHT(betid, 2) = @Game1324)) -- Game	
					  AND (@BetTeam1324 = 'ALL' OR b.betteam = @BetTeam1324)
					)
				)
				AND 1 = CASE WHEN b.bettype IN (155, 1316) THEN CASE 
															WHEN @Handicap155 = 9999 THEN 1
															WHEN @Handicap155 = (hdp1 + hdp2) THEN 1
															ELSE 0 
													 END
							WHEN b.bettype IN (156, 1312) THEN CASE
															WHEN @OverUnder156 = 9999 THEN 1
															WHEN @OverUnder156 = hdp1 THEN 1
															ELSE 0
													 END
							ELSE 1 
					END
				AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END	

	--178,197,198,204,205, 401, 402, 403, 404
	IF EXISTS( SELECT TOP 1 1 FROM #tblBettype WHERE bettype IN (178,197,198,204,205, 401, 402, 403, 404) )
		INSERT INTO #BetDelete(
				grouptransid	
				,transid			
				,custid			
				,recommend		
				,mrecommend		
				,srecommend		
				,betfrom			
				,statusID		
				,status			
				,SecAcceptFlag	
				,creator									
				,hdp1 			
				,hdp2 			
				,bettype 		
				,betteam 		
				,betcheck		
				,odds			
				,OddsType		
				,transdate		
				,IsLiveIndicator	
				,livehomescore 	
				,liveawayscore 	
				,Stake			
				,CurrencyName	
				,betid			
				,betdaqid
				,refno
		)
		SELECT	b.transid
				,b.transid
				,b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,b.betfrom
				,b.statusID
				,b.STATUS
				,b.SecAcceptFlag
				,b.creator				
				,b.hdp1
				,b.hdp2
				,b.bettype
				,b.betteam
				,b.betcheck
				,b.odds
				,b.oddstype
				,b.transdate
				,b.liveindicator
				,b.livehomescore
				,b.liveawayscore
				,b.stake
				,b.CurrencyName
				,b.betid
				,b.betdaqid
				,b.refno
		FROM	dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #tblTransIds t 
				ON	t.transid = b.transid
			INNER JOIN #tblBettype tp 
				ON	tp.bettype = b.bettype		
			LEFT JOIN dbo.strSplit(@betteam6,'^') AS bt ON bt.val=b.betteam
		WHERE	b.matchid=@matchid
				AND b.transid between @FromTransId AND @ToTransId	
				AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
				AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 	
				AND b.bettype IN (178,197,198,204,205, 401, 402, 403, 404)
				AND (
					  (b.bettype IN (178,197,198,204,205, 401, 402, 403, 404)	
						AND (@BetTeam178 = 'ALL' OR b.betteam = @BetTeam178)
					  )
					)
				AND 1 = CASE WHEN b.bettype IN (178,197,198,204,205, 401, 402, 403, 404) THEN CASE
															WHEN @Handicap178 = 9999 THEN 1
															WHEN @Handicap178 = hdp1 THEN 1
															ELSE 0
													 END
							ELSE 1 
					END
				AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
															 WHEN 1 THEN 0 
															 WHEN 2 THEN 1 END				 
													 
	--133,134,135,145,146,147,148,149,150,159,161,162,165,166,169,173,174,179,181,182,188,189,190,193,195,196,199,200,201,202,210,211,212,213,214,215,216,406,407,409,412
	IF EXISTS( SELECT TOP 1 1 FROM #tblBettype WHERE bettype IN (133,134,135,145,146,147,148,149,150,159,161,162,165,166,169,173,174,179,181,182,188,189,190,193,195,196,199,200,
								201,202,210,211,212,213,214,215,216,406,407,409,412) )
		INSERT INTO #BetDelete(
				grouptransid	
				,transid			
				,custid			
				,recommend		
				,mrecommend		
				,srecommend		
				,betfrom			
				,statusID		
				,status			
				,SecAcceptFlag		
				,creator					
				,hdp1 			
				,hdp2 			
				,bettype 		
				,betteam 		
				,betcheck		
				,odds			
				,OddsType		
				,transdate		
				,IsLiveIndicator	
				,livehomescore 	
				,liveawayscore 	
				,Stake			
				,CurrencyName	
				,betid			
				,betdaqid
				,refno
		)
		SELECT	b.transid
				,b.transid
				,b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,b.betfrom
				,b.statusID
				,b.STATUS
				,b.SecAcceptFlag
				,b.creator								
				,b.hdp1
				,b.hdp2
				,b.bettype
				,b.betteam
				,b.betcheck
				,b.odds
				,b.oddstype
				,b.transdate
				,b.liveindicator
				,b.livehomescore
				,b.liveawayscore
				,b.stake
				,b.CurrencyName
				,b.betid
				,b.betdaqid
				,b.refno
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #tblTransIds t 
				ON	t.transid = b.transid
			INNER JOIN #tblBettype tp 
				ON	tp.bettype = b.bettype				
		WHERE	b.matchid=@matchid
				AND b.transid between @FromTransId AND @ToTransId	
				AND CASE WHEN @LiveIndicator = 2 THEN @LiveIndicator ELSE b.liveindicator END = @LiveIndicator
				AND b.livehomescore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveHomeScore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @LiveAwayScore IS NOT NULL AND @LiveIndicator = 1 THEN @LiveAwayScore ELSE b.liveawayscore END	
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveIndicator = 1 THEN @ToTransdate ELSE b.transdate END 	
				AND b.bettype IN (133,134,135,145,146,147,148,149,150,159,161,162,165,166,169,173,174,179,181,182,188,189,190,193,195,196,199,200,
								201,202,210,211,212,213,214,215,216,406,407,409,412)
				AND (
						(
						  b.bettype IN (165,166)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam165 = 'ALL' THEN b.betteam ELSE @BetTeam165 END, '^'))
						)
						OR
						(
						  b.bettype IN (159,406)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam159 = 'ALL' THEN b.betteam ELSE @BetTeam159 END, '^'))
						)
						OR
						(
						  b.bettype IN (179)
						  AND 
						  (
							(b.betteam <>  'G4' AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam159 = 'ALL' THEN b.betteam ELSE @BetTeam159 END, '^')))
							OR
							(
								b.betteam = 'G4'
								AND
								'G4&Over' IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam159 = 'ALL' THEN 'G4&Over' ELSE @BetTeam159 END, '^'))
							)
						  )
						)
						OR
						(
						  b.bettype IN (161,162,181,182,407,409,412)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam161 = 'ALL' THEN b.betteam ELSE @BetTeam161 END, '^'))
						)
						OR
						(
						  b.bettype IN (199)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam199 = 'ALL' THEN b.betteam ELSE @BetTeam199 END, '^'))
						)
						OR
						(
						  b.bettype IN (202)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam202 = 'ALL' THEN b.betteam ELSE @BetTeam202 END, '^'))
						)
						OR
						(
						  b.bettype IN (195,196)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam195 = 'ALL' THEN b.betteam ELSE @BetTeam195 END, '^'))
						)
						OR
						(
						  b.bettype IN (200,201)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam200 = 'ALL' THEN b.betteam ELSE @BetTeam200 END, '^'))
						)
						OR
						(
						  b.bettype IN (169,193)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam169 = 'ALL' THEN b.betteam ELSE @BetTeam169 END, '^'))
						)
						OR
						(
						  b.bettype IN (210,173,174,188,189,190,211,212,213,214,215,133,134,135,145,146,147,148,149,150)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam210 = 'ALL' THEN b.betteam ELSE @BetTeam210 END, '^'))
						)
						OR
						(
						  b.bettype IN (216)
						  AND b.betteam IN (SELECT CONVERT(VARCHAR, val) FROM dbo.strSplit(CASE WHEN @BetTeam216 = 'ALL' THEN b.betteam ELSE @BetTeam216 END, '^'))
						)
					)
				AND ISNULL(SecAcceptFlag,0) = CASE @SecondAcceptFlag WHEN 0 THEN ISNULL(SecAcceptFlag,0) 
															 WHEN 1 THEN 0 
			
															 WHEN 2 THEN 1 END															
		
	------------------***** End of insert all data into #BetDelete *****------------------
	--------------------------------------------------------------------------------------

	DELETE FROM #BetDelete WHERE statusID IN (102, 101) -- VOID, REJECT
	
	-- delete main ticket if it's BT but subticket is not exists in SOLD list
	DELETE
	FROM	#BetDelete
	OUTPUT	DELETED.grouptransid
	INTO	@tblInvalidTrans (transid)
	WHERE	grouptransid NOT IN (SELECT grouptransid FROM #tblTransIdSolds)
			AND betdaqid = 0 
	
	-- delete main ticket if it's not BT but have subticket in SOLD list
	DELETE
	FROM	#BetDelete
	OUTPUT	DELETED.grouptransid
	INTO	@tblInvalidTrans
	WHERE	transid IN (SELECT grouptransid FROM #tblTransIdSolds)
			AND betdaqid = -1 
		
	 --check no data
	IF NOT EXISTS (SELECT TOP 1 1 FROM #BetDelete)
	BEGIN

		SELECT	@ErrCode = 99
				,@ErrMsg = 'No ticket found.'
		
	END
	ELSE
	BEGIN
		DELETE 
		FROM	#tblTransIdSolds 
		WHERE	grouptransid IN (SELECT transid FROM @tblInvalidTrans)
		
		-- return invalid transId	
		SELECT @InvalidTrans = @InvalidTrans + CAST(transid AS VARCHAR(20)) + ','
		FROM @tblInvalidTrans
		
		IF @InvalidTrans <> ''
			SET @InvalidTrans = 'Failed to void the ticket(s): ' + LEFT(@InvalidTrans,LEN(@InvalidTrans) -1)
		
		--- check exists BT or not
		SELECT @isExistBT 	= MAX (CASE WHEN betdaqid = 0 THEN 1 ELSE 0 END)
		FROM #BetDelete
		
		------------------***** Begin Special Delete *****------------------		                                                                                                                                               
		CREATE TABLE #BeforeUpd (
				custid		 INT,
				balance		 MONEY)
			
		CREATE TABLE #AfterUpd(
					custid		 INT,
					balance		 MONEY)

		DECLARE @tblDebitPending TVP_BalanceList
		DECLARE @tblCreditPending TVP_BalanceList
		
		IF (@isExistBT = 1 AND EXISTS (SELECT TOP 1 1 FROM #tblTransIdSolds))
		BEGIN
			INSERT INTO #BetDelete (
					grouptransid	
					,transid			
					,custid			
					,recommend		
					,mrecommend		
					,srecommend		
					,betfrom			
					,statusID		
					,status			
					,SecAcceptFlag		
					,creator								
					,hdp1 			
					,hdp2 			
					,bettype 		
					,betteam 		
					,betcheck		
					,odds			
					,OddsType		
					,transdate		
					,IsLiveIndicator	
					,livehomescore 	
					,liveawayscore 	
					,Stake			
					,CurrencyName	
					,betid			
					,betdaqid
			)	
			SELECT  tmpmain.transid
					,sub.transid
					,sub.custid
					,tmpmain.recommend
					,tmpmain.mrecommend
					,tmpmain.srecommend
					,tmpmain.betfrom
					,sub.statusid
					,'SOLD'
					,tmpmain.SecAcceptFlag		
					,sub.creator						
					,tmpmain.hdp1
					,tmpmain.hdp2
					,tmpmain.bettype
					,tmpmain.betteam
					,tmpmain.betcheck
					,tmpmain.odds
					,tmpmain.OddsType
					,sub.transdate
					,tmpmain.IsLiveIndicator
					,tmpmain.livehomescore
					,tmpmain.liveawayscore
					,tmpmain.Stake
					,tmpmain.CurrencyName
					,sub.betid
					,tmpmain.betdaqid
			FROM	dbo.bettrans sub WITH(NOLOCK)
				INNER JOIN #BetDelete tmpmain 
					ON	sub.refno = tmpmain.transid
						AND sub.bettype = 901
						AND tmpmain.betdaqid = 0			
						AND sub.matchid = @matchid
			WHERE sub.transid IN (SELECT transid FROM #tblTransIdSolds)
		END	
		
		-- Step 1: Backup into zzzbettrans
		-- 1.1. Backup main ticket
		INSERT INTO zzzbettrans (transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,
					winlost,livehomescore,liveawayscore,liveindicator,betteam,creator, refno, 
					winlostdate,betfrom,betcheck,checktime,matchid, bettype)
		SELECT  main.transid, main.custid, CURRENT_TIMESTAMP, main.oddsid, main.hdp1, main.hdp2, main.odds, main.stake, main.status, 
				main.winlost, main.livehomescore, main.liveawayscore, main.liveindicator, main.betteam, main.creator , main.refno, 
				main.winlostdate, main.betfrom, main.betcheck, main.checktime, main.matchid, main.bettype
		FROM	dbo.bettrans main WITH (nolock)
			INNER JOIN #BetDelete tmpmain 
				ON	main.transid = tmpmain.transid 
					AND main.transid = tmpmain.grouptransid
					AND main.matchid = @matchid
		
		-- 1.2. Back up BetTrade's subtickets (901,902,903)  
		INSERT INTO zzzbettrans (transid,custid,transdate,oddsid,hdp1,hdp2,odds,stake,status,
					winlost,livehomescore,liveawayscore,liveindicator,betteam,creator, refno, 
					winlostdate,betfrom,betcheck,checktime,matchid, bettype)
		SELECT  sub.transid, sub.custid, CURRENT_TIMESTAMP, sub.oddsid, sub.hdp1, sub.hdp2, sub.odds, sub.stake, sub.status, 
				sub.winlost, sub.livehomescore, sub.liveawayscore, sub.liveindicator, sub.betteam, sub.creator , sub.refno, 
				sub.winlostdate, sub.betfrom, sub.betcheck, sub.checktime, sub.matchid, sub.bettype
		FROM	bettrans sub WITH (nolock)
			INNER JOIN #BetDelete tmpmain		
				ON	sub.refno = tmpmain.transid
					AND sub.matchid = @matchid
		WHERE	sub.bettype IN (901, 902, 903)
				AND tmpmain.betdaqid = 0		
			
		-- Capture balance before updating Bettrans
		INSERT INTO #BeforeUpd (custid, balance)
		SELECT	custid, SUM (winlost - actual_stake + playercomm) balance
		FROM (
			SELECT	main.custid, main.winlost, main.actual_stake, main.playercomm
			FROM	bettrans main WITH (NOLOCK)
				INNER JOIN #BetDelete tmpmain
					ON	main.transid = tmpmain.transid 
						AND main.transid = tmpmain.grouptransid
						AND main.matchid = @matchid
			UNION ALL
			SELECT	sub.custid, sub.winlost, sub.actual_stake, sub.playercomm
			FROM	bettrans sub WITH (NOLOCK)
					INNER JOIN #BetDelete tmpmain with(NOLOCK)
						ON	sub.refno = tmpmain.transid
							AND sub.bettype IN (901, 902, 903)
							AND tmpmain.betdaqid = 0
							AND sub.matchid = @matchid
		) tmp
		GROUP BY custid
		
		-- Step 2: Update bettrans
		-- 2.1. Update main ticket
		UPDATE	main
			SET winlost		= main.actual_stake
				,ruben			= 1
				,statuswinlost	= 6
				,creator		= @UserID
				,awinlost		= 0
				,mwinlost		= 0
				,swinlost		= 0
				,playercomm		= 0
				,comm			= 0
				,acomm			= 0
				,scomm			= 0
				,statusID		= 102       
				,status			= 'VOID'
		FROM	dbo.bettrans main WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #BetDelete tmpmain
				ON	main.transid = tmpmain.transid 
					AND main.transid = tmpmain.grouptransid
					AND main.matchid = @matchid
					
		IF (@isExistBT = 1)
		BEGIN
			-- 2.2. Update BetTrade's subtickets (901,902,903) 
			UPDATE	sub
				SET winlost			= sub.actual_stake
					,ruben			= 1
					,statuswinlost	= 6
					,creator		= @UserID
					--,awinlost		= 0 -- will update awinlost after doing Step3: Update BetTrade selling
					,mwinlost		= 0
					,swinlost		= 0
					,playercomm		= 0
					,comm			= 0
					,acomm			= 0
					,scomm			= 0
					,statusID		= 102 
					,status			= 'VOID'      
			FROM	dbo.bettrans sub WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #BetDelete tmpmain 
				ON	tmpmain.transid = sub.refno
					AND sub.bettype IN (901, 902, 903)
					AND tmpmain.betdaqid = 0
					AND sub.matchid = @matchid
		END
		
		-- Capture balance after updating Bettrans
		INSERT INTO #AfterUpd (custid, balance)
		SELECT	custid, SUM (winlost - actual_stake + playercomm) balance
		FROM (
			SELECT	main.custid, main.winlost, main.actual_stake, main.playercomm
			FROM	bettrans main WITH (NOLOCK)
				INNER JOIN #BetDelete tmpmain
					ON	main.transid = tmpmain.transid 
						AND main.transid = tmpmain.grouptransid
						AND main.matchid = @matchid
			UNION ALL
			SELECT	sub.custid, sub.winlost, sub.actual_stake, sub.playercomm
			FROM	bettrans sub WITH (NOLOCK)
					INNER JOIN #BetDelete tmpmain with(NOLOCK)
						ON	sub.refno = tmpmain.transid
							AND sub.bettype IN (901, 902, 903)
							AND tmpmain.betdaqid = 0
							AND sub.matchid = @matchid
		) tmp
		GROUP BY custid

		-- Compare balance
		INSERT INTO @tblCreditPending (custID, balance)
		SELECT		a.custid, (a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) > 0	

		IF @@rowcount <> 0
			EXEC dbo.Dot_BalancePendingCreditIns 
				@BalancePending = @tblCreditPending
				,@Type			= 1 -- Sports
		
		INSERT INTO @tblDebitPending (custID, balance)
		SELECT		a.custid, ABS(a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) < 0
		
		IF @@rowcount <> 0
			EXEC dbo.Dot_BalancePendingDebitIns 
				@BalancePending = @tblDebitPending
				,@Type			= 1 -- Sports
		
		
		IF (@isExistBT = 1)
		BEGIN
			-- STEP 3: Update BetTrade selling information	
			-- 3.1. Insert BetTradeSellingCancel
			INSERT INTO [dbo].[BetTradeSellingCancelled](
					[TicketID]
					,[Remark]
					,[BTBuyBack]
					,[BTComission]
					,[AfterBalance]
					,[Owner]
					,[Cancelled]
					,[ChangeDate]
					,[CreateDate]
					,TradeID)
			SELECT	sub.refno
					, 'SB void ticket due to ' + @Reason
					,sub.awinlost
					,0
					,(SELECT ISNULL(SUM(CASE 
									WHEN ruben = 1
										THEN winlost - actual_stake + playercomm
									ELSE 0
									END), 0)
									FROM dbo.bettrans WITH (NOLOCK)
									WHERE custid = sub.custid
									)
					,'SB'
					,1
					,GETDATE()
					,GETDATE()
					,bts.TradeID
			FROM	#BetDelete tmpmain
				INNER JOIN bettrans sub WITH(NOLOCK)
					ON	sub.refno = tmpmain.transid 
						AND sub.BetType = 901
						AND tmpmain.betdaqid = 0
						AND sub.matchid = @matchid
				INNER JOIN [dbo].[BetTradeSelling] bts WITH(NOLOCK)
					ON	bts.TicketID = tmpmain.transid
				LEFT JOIN [dbo].[BetTradeSellingCancelled] btc WITH(NOLOCK) 
					ON	btc.[TicketID] = tmpmain.transid
			WHERE	btc.[BTBuyBack] IS NULL 
					AND (bts.Status = 'Accept' OR bts.Status = 'Confirm')
				
			-- 3.2. Update BetTradeSellingCancel 
			UPDATE	bts
			SET
					[Remark] = 'SB void ticket due to ' + @Reason,
					[BTBuyBack] = sub.awinlost,
					[BTComission] = 0,
					[Owner] = 'SB',
					[Cancelled] = 1,
					[ChangeDate] = GETDATE(),
					AfterBalance = (SELECT ISNULL(SUM(CASE 
										WHEN ruben = 1
											THEN winlost - actual_stake + playercomm
										ELSE 0
										END), 0)
										FROM dbo.bettrans WITH (NOLOCK)
										WHERE custid = sub.custid
										)
			FROM	[dbo].[BetTradeSellingCancelled] bts WITH (ROWLOCK, UPDLOCK)
				INNER JOIN bettrans sub WITH(NOLOCK)
					ON	sub.refno = bts.[TicketID]
						AND sub.matchid = @matchid
				INNER JOIN #BetDelete tmpsub
					ON sub.transid = tmpsub.transid
			WHERE	sub.bettype = 901

			--Step 4: Update winlost: BetTrade's subtickets (901,902,903) 
			UPDATE	sub
				SET awinlost		= 0     
			FROM	bettrans sub WITH (ROWLOCK, UPDLOCK)
				INNER JOIN #BetDelete tmpmain
					ON	sub.refno = tmpmain.transid
						AND sub.bettype IN (901, 902, 903)
						AND tmpmain.betdaqid = 0
						AND sub.matchid = @matchid
						
			--Step 5:  Insert bettrade tickets to send API
			DECLARE @session NVARCHAR(50) = CAST (NEWID() AS NVARCHAR(50))
			;WITH cteMainTicket
			AS(
				SELECT  transid
				FROM	#BetDelete
				WHERE	betdaqid = 0
						AND grouptransid = transid
			)
			
			INSERT INTO dbo.BettradeAPI (
				transid
				,matchid
				,[Session]
				,[action]
				,buybackNo
				,Payout
				,Remark
			)
			SELECT	b.TicketID
					,b.MatchID
					,@session
					,'VOID'
					,b.BuyBackNo
					,b.PayOut
					,'SB void ticket due to ' + @Reason
			FROM	dbo.BetTradeSelling b WITH(NOLOCK)
			WHERE	b.TicketID IN (SELECT transid FROM cteMainTicket)
					AND b.[Status] IN ('Accept', 'Confirm')
		END
		
		--------
		-- update totalbets
		DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)
		INSERT INTO @Total
			SELECT oddsid,
				SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) 
						 ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
				SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) 
						 ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
			FROM bettrans b WITH (nolock)
				INNER JOIN custDB.dbo.exchange e WITH (nolock) ON b.currency = e.exchangeid
			WHERE bettype IN (1,3,7,8) AND ruben = 0 AND oddsid <> 0 AND matchid = @MatchId
			GROUP BY oddsid

		UPDATE odds WITH (rowlock, updlock)
		SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
		FROM @Total t WHERE odds.oddsid = t.oddsid AND odds.matchid = @MatchId
					   
	------------------***** End of Special Delete *****------------------
		SELECT @LogData ='void bet for matchid ' + CONVERT(VARCHAR(20), @MatchId) 
				+ ' from ' + CONVERT(VARCHAR(20), @FromTransId) + ' to ' 
				+ CONVERT(VARCHAR(20), @ToTransId) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) 
				+ ' reason: ' + @Reason
				
		EXEC WriteLog_UserLog 
			@UserID = @UserID
			,@Doing = @LogData

		-- Match info
		IF EXISTS(SELECT TOP 1 1 FROM #tblBettype WHERE bettype = 10)  --Outright
		BEGIN
			SELECT MATCH.teamid AS homeid,
				0 AS awayid,
				MATCH.matchcode,
				MATCH.eventdate,
				MATCH.leagueid,
				GETDATE() AS DATETIME,
				CONVERT(BIT,0) AS IsNeutral,
				1 AS IsOutright
			FROM
				Outright AS MATCH WITH (NOLOCK)
			WHERE 
				MATCH.orid = @MatchId
		END   
		ELSE
		BEGIN
			SELECT MATCH.homeid,
				MATCH.awayid,
				MATCH.matchcode,
				MATCH.eventdate,
				MATCH.leagueid,
				GETDATE() AS DATETIME,
				ISNULL(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
				0 AS IsOutright
			FROM
				MATCH WITH (NOLOCK)
			WHERE 
				MATCH.matchid = @MatchId
		END
		
		
		-- CHECK IT GROUP or NOT ?   
		IF EXISTS (SELECT TOP 1 1 FROM DBPOLICY.bodb02.dbo.accCustomer_1 a WHERE a.GroupID = 1 AND a.custid = @UserID) -- Check UserID in IT group
		BEGIN  
			SELECT @isITAdmin = 1   
		END  		
			,al.refno
		
		;WITH CTE_CustIdAll AS (
			SELECT DISTINCT t.custid
			FROM #BetDelete b
			CROSS APPLY (
				VALUES (custid)
				,(creator)
				,(recommend)
				,(mrecommend)
				,(srecommend)
			) AS t (custid)
		), CTE_CustInfo AS (
			SELECT ci.custid
				, ci.username
				, ci.username2
				, ci.site
				, ci.currency
			FROM CustDB.dbo.Customer ci WITH(NOLOCK)
				INNER JOIN CTE_CustIdAll ca ON ci.custid = ca.custid
			,al.refno
			
		)
		SELECT	al.odds
			,al.OddsType
			,al.transdate
			,al.bettype
			,al.betfrom
			,al.transid AS refno
			,al.betteam
			,al.betcheck
			,al.hdp1
			,al.hdp2
			,al.betfrom
			,al.IsLiveIndicator
			,al.livehomescore
			,al.liveawayscore
			,cr.username AS creator
			,al.Stake
			,al.CurrencyName
			,al.status
			,al.SecAcceptFlag
			,al.betid
			,al.grouptransid
			,al.transid
			,al.TransDesc
			,al.custid
			,al.recommend
			,al.mrecommend
			,al.srecommend
			-----------------------------
			,ci.currency
			,ci.username
			,ci.username2
			,ci.username AS CustUserName
			,ci.username2 as CustUserName2
			,ag.UserName AS AgUserName
			,ma.UserName AS MagUserName
			,su.Username AS SagUserName
			---------------------------------------
			,CASE 
				WHEN al.custid IN (1077687,2331,115770,15523642,15042477,16041068,16041058) THEN 'Betfair' 
				ELSE su.site 
			END AS EmailGroup
			,su.site 
			,CASE WHEN s.custid IS NOT NULL THEN 1 ELSE 0 END AS IsDeposit
			,CASE WHEN al.betdaqid = 0 THEN 1 ELSE 0 END AS isBetTrade
			,@isITAdmin	AS IsITSupport
				
			,al.refno
		FROM	#BetDelete al
			INNER JOIN CTE_CustInfo ci WITH(NOLOCK)
				ON al.custid = ci.custid
			INNER JOIN CTE_CustInfo cr WITH(NOLOCK)
				ON	al.creator = cr.custid	
			INNER JOIN CTE_CustInfo ag WITH(NOLOCK)
				ON al.recommend = ag.custid
			INNER JOIN CTE_CustInfo ma WITH(NOLOCK)
				ON al.mrecommend = ma.custid
			INNER JOIN CTE_CustInfo su WITH(NOLOCK)
				ON al.srecommend = su.custid
			LEFT JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK) 
				ON al.srecommend = s.custid
			,al.refno
			,al.refno
			,al.refno
		
			,al.refno
		ORDER BY al.grouptransid, al.transid
		
		DROP TABLE #BeforeUpd
		DROP TABLE #AfterUpd
	
	END
	------ releasing SD process
	EXEC dbo.NAP_Admin_CheckingProcess
		@isExistOutright 	= @isExistOutright
		, @isExistMatch		= @isExistMatch
		, @IsReleased		= 1
		
	
	DROP TABLE #tblBettype
	DROP TABLE #tblTransIds
	DROP TABLE #tblTransIdSolds
	DROP TABLE #tblMatchProcess
	DROP TABLE #BetDelete
	
	RETURN
END

GO
GRANT EXECUTE ON [dbo].[NAP_BettransDelSpecial] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_BettransDelSpecial] TO [vnteam] AS [dbo]