USE bodb02
Go

ALTER PROCEDURE [dbo].[Acc_BetsSelBetList_ByTransID]    
	@CustID int,  
	@TransID bigint
AS    
	/*  
	Created by: Henry  
	Date: 2008 
	Task: Bet List By TransID  
	DB: DBAGE/bodb02   
	Original:  Acc_BetsSelBetList   

	Revisions:  
	- 20091229@[Henry]: newly created  
	- 20100409@Daniel:   
	+ Support Mini game   
			+ Fix search Casino & Mini game by bettrans.refno instead  
	 - 20100501@Daniel: Remove support Mini game, add agent W/L amount, agent's commission amount columns  
	- 20100524@Jamie: Show currency2's exchange rate for OpenTote   
	-- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement  
	- 20100611@Henry: Change mix-parlay match from 0 to 9  
	- 20100907@Henry: Add IBC Bingo bettype  
	- 20101130@Henry: Add column betid for number game  
	- 20101201@Henry: Return winlost-actual_stake for column winlost  
	- 20110408@Amy: Change function to get Odds value and odds type  
	- 20110516@Lukas: re-arrange bettype  
	- 20110711@Johnson: show exchange rate for SA Tote(Pool Currency)  
	- 20110802@Johnson: - Add column actual_stake into betlist  
	   - Add new bettype combination mix parlay  
	- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running  
	- 20111207@Sophia: Add P2P  
	- 20120120@Sophia: Add Showtime for Table-hand-shoe of Live Casino  
	   Add sub detail for Live Casino  
	- 20120217@Daniel: Allow to delete mix palay bet (whole ticket)  
	- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino  
	- 20120410@Hurri: change matchid 0 -> 1000 for bettype 1000  
	- 20120417@Johnson: Correct column transid for p2p    
	- 20120424@Lukas: show transid of main-ticket for sub-tickets of system parlay   
	- 20120507@Jamie: Fix p2p to get transID   
	- 20120606@Sophia: Change datatype of stake to money   
	- 20120626@Lukas: exclude outright from sportbook ( in case of matchid = orid)  
	- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype,f_GetChoice for odds, Oddstype, betteam  
	- 20120927@Johnson: get commstatus column to check double comm losing  
	- 20130121@Dan: change linked server DB06 to DBARC   
	- 20130227@Elodie: Add Virtual HR product  
	- 20130705@Kathy: Update matchid for RnG Casino (71) and Bingo (73)
	- 20130724@Elodie: Get winlostdate field
	- 20130726@Elodie: Define data for bettrans, bettrans14 or bettrans_bk by winlostdate field
					   Enhance performance
	- 20140307@Dom: Add Keno
	- 20140318@Dom: #13487 Prevent user to delete LAS ticket in bet list accounting site
	- 20140908@Dom:	[Redmine #22012] Update VS conditions
	- 20141103@Dom: Apply sport bettype matrix
	- 20150122@Dom: HotFix #29646 Fix bug virtual HR
	- 20150415@Sophia: Get Betcheck for Betradar
	- 20150506@Tom: Support Gold Deluxe Product [#34847]
	- 20150506@Bobby: Add transdesc column for metric gaming bettypes (801-899)
	- 20150615@Edward: Support for BetTrade
	- 20150707@Bobby: Exclude Metric Gaming running ticket from bettrans table
	- 20150625@Edward: Support for MicroGamming
*/   
BEGIN

	SET NOCOUNT ON    
	--list of bettype not allowed to delete  
	DECLARE @tableBettypeNotAllowDelete  TABLE(typeid int not null)  
	INSERT INTO @tableBettypeNotAllowDelete (typeid)   
	SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION  ALL
	SELECT 51 UNION ALL SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54 UNION ALL SELECT 55 UNION ALL SELECT 56 UNION  ALL
	SELECT 61 UNION ALL SELECT 62 UNION ALL SELECT 63 UNION ALL SELECT 64 UNION ALL SELECT 65 UNION SELECT 66  

	--End  

	DECLARE @refno BIGINT  
	Declare @Data TABLE (  
		bettype   int,  
		transid   bigint,   
		betid   bigint,  
		refno   nvarchar(50),   
		matchcode  nvarchar(50),  
		race   nvarchar(20),  
		eventdate  smalldatetime,  
		virtualrate  float,  
		isShowOTExRate bit,  
		sdiscount  smallmoney,  
		adiscount  smallmoney,  
		discount  smallmoney,  
		homeid   int,   
		awayid   int,   
		settleTime  datetime,  
		hdp1   smallmoney,   
		hdp2   smallmoney,   
		odds   smallmoney,  
		finalodds  smallmoney,  
		finalodds2  smallmoney,  
		OddsType  tinyint,  
		status   nvarchar(50),   
		comstatus  nvarchar(50),  
		stake   money,  
		actual_stake money,  
		transdate  datetime,  
		betteam   nvarchar(50),  
		spositiontaking smallmoney,  
		mpositiontaking smallmoney,  
		apositiontaking smallmoney,  
		spositiontaking2 smallmoney,  
		mpositiontaking2 smallmoney,  
		apositiontaking2 smallmoney,  
		liveindicator  bit,  
		modds   smallmoney,  
		custid   int,  
		livehomescore int,   
		liveawayscore int,   
		finalhomescore int,   
		finalawayscore int,   
		leagueid  int,   
		sporttype  smallint,   
		ip    nvarchar(15),   
		betfrom   nvarchar (1),  
		matchid   int,  
		isNeutral  bit,  
		allowdelete  bit,  
		winlost   money,  
		commission  money,  
		scomm   money,   
		acomm   money,  
		comm   money,  
		awinlost  money,  
		mwinlost  money,  
		swinlost  money,  
		showtime  nvarchar(50),
		winlostdate		smalldatetime,
		BetCheck	NVARCHAR(50),
		transdesc		NVARCHAR(300)  
	)  

	DECLARE @DetailData TABLE (  
		refno   nvarchar(50),   
		odds   smallmoney,   
		stake   money,  
		status   nvarchar(50),  
		apositiontaking smallmoney,   
		mpositiontaking smallmoney,   
		spositiontaking smallmoney,  
		bettype   smallint,  
		betteam   nvarchar(50),
		TransDesc		varchar(300)  
	)  

	DECLARE @WinlostDate smalldatetime, @MoveBetsDay smalldatetime, @BalanceUpDay smalldatetime, @bettype int
	DECLARE @tmp TABLE (BalanceUpDay smalldatetime, MoveBetsDay smalldatetime) 
	INSERT INTO @tmp(BalanceUpDay, MoveBetsDay)
	EXEC Age_SelBalanceUpDay

	--list of LAS agent not allowed to delete
	DECLARE @strLASAgent varchar(1000)
	EXEC DBLAS.LASDB.dbo.Las_Get_recommend @StringRec = @strLASAgent output
	SELECT val as CustID 
	INTO #LASAgent
	FROM dbo.strSplit(@strLASAgent,'^')
	--END 

	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT)
	INSERT INTO @SportBettype
	EXEC dbo.Acc_SportBettypeMatrix_Sel @mode=4

	SELECT @MoveBetsDay = MoveBetsDay, @BalanceUpDay = BalanceUpDay FROM @tmp
		
	-- FROM translog
	SELECT TOP 1 
		@WinlostDate 	= bt.winlostdate
		, @bettype 		= bt.gameID 
		, @refno 		= bt.translogid
	from dbo.translog bt with (nolock)
		INNER JOIN @SportBettype sp 
		ON bt.gameID = sp.bettype
	where bt.custid 	= @Custid
		AND translogid 	= @transid 
		AND statusID 	= 0
		AND (sp.productid IN (8, 12,13)
			OR sp.bettype BETWEEN 801 AND 899
		)
		
	-- FROM bettrans
	IF(@WinlostDate IS NULL)
	BEGIN
		SELECT TOP 1 
		@WinlostDate 		= bt.winlostdate
		, @bettype 			= bt.bettype 
		, @refno 			= bt.refno
		from dbo.bettrans bt with (nolock)
			INNER JOIN @SportBettype sp 
			ON bt.bettype 	= sp.bettype
		where bt.custid 	= @Custid
			AND (
				bt.transid 	= @transid 
				OR (
					bt.refno = @transid 
					AND (sp.productid IN (6,7,8,9,12,13) OR sp.bettype BETWEEN 801 AND 899)
				)
			)
			--exclude metric gaming running ticket
			AND (bt.bettype NOT BETWEEN 801 AND 806 OR (bt.bettype BETWEEN 801 AND 806 AND bt.statusID NOT IN (0, 1)))
	END
	-- FROM bettrans14
	IF(@WinlostDate IS NULL)
	BEGIN
		SELECT TOP 1 
		@WinlostDate 		= bt.winlostdate
		, @bettype 			= bt.bettype 
		, @refno 			= bt.refno
		from dbo.bettrans14 bt with (nolock)
			INNER JOIN @SportBettype sp 
			ON bt.bettype 	= sp.bettype
		where bt.custid 	= @Custid
			AND (
				bt.transid 	= @transid 
				OR (
					bt.refno = @transid 
					AND (sp.productid IN (6,7,8,9,12,13) OR sp.bettype BETWEEN 801 AND 899)
				)
			)
	END
	-- FROM bettrans_bk
	IF(@WinlostDate IS NULL)
	BEGIN
		SELECT TOP 1 
		@WinlostDate 		= bt.winlostdate
		, @bettype 			= bt.bettype 
		, @refno 			= bt.refno
		from DBARC.bodb_archive.dbo.bettrans_bk bt with (nolock)
			INNER JOIN @SportBettype sp 
			ON bt.bettype 	= sp.bettype
		where bt.custid 	= @Custid
			AND (
				bt.transid 	= @transid 
				OR (
					bt.refno = @transid 
					AND (sp.productid IN (6,7,8,9,12,13) OR sp.bettype BETWEEN 801 AND 899)
				)
			)
		
	END

	IF(@WinlostDate IS NULL) GOTO OutputResult;
	
	/*
	IF exists(  
	select top 1 1 from bettrans with (nolock)   
	where (transid = @TransID OR (refno = @transid AND bettype IN (71, 73, 1000) and matchid IN (0, 71, 73, 1000))) --20120405@Hurri  
	AND custid = @Custid  
	)  
		SELECT @WinlostDate = winlostdate, @bettype = bettype ,@refno = refno
		from bettrans with (nolock)   
		where (transid = @TransID OR (refno = @transid AND bettype IN (71, 73, 1000) and matchid IN (0, 71, 73, 1000))) --20120405@Hurri  
		AND custid = @Custid
	ELSE IF exists(  
	select top 1 1 from bettrans14 with (nolock)   
	where (transid = @TransID OR (refno = @transid AND bettype IN (71,73, 1000) and matchid IN (0,71, 73, 1000))) --20120405@Hurri  
	AND custid = @Custid  
	)
		SELECT @WinlostDate = winlostdate, @bettype = bettype ,@refno = refno
		from bettrans14 with (nolock)   
		where (transid = @TransID OR (refno = @transid AND bettype IN (71,73, 1000) and matchid IN (0,71, 73, 1000))) --20120405@Hurri  
		AND custid = @Custid
	ELSE IF exists(  
	select top 1 1 from DBARC.bodb_archive.dbo.bettrans_bk with (nolock)   
	where (transid = @TransID OR (refno = @transid AND bettype IN (71,73,1000) and matchid IN (0, 71, 73, 1000))) --20120405@Hurri  
	AND custid = @Custid  
	)
		SELECT @WinlostDate = winlostdate, @bettype = bettype ,@refno = refno
		from DBARC.bodb_archive.dbo.bettrans_bk with (nolock)   
		where (transid = @TransID OR (refno = @transid AND bettype IN (71,73,1000) and matchid IN (0, 71, 73, 1000))) --20120405@Hurri  
		AND custid = @Custid  

	---------Process Keno & Gold Delux----------------
	ELSE IF exists(  
	select top 1 1 from bettrans bt with (nolock)
	INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
	where (transid = @TransID OR (refno = @transid AND sp.productid IN (8,12))) --Dom
	AND custid = @Custid  
	) 
		SELECT @WinlostDate = winlostdate, @bettype = bt.bettype ,@refno = refno
			from bettrans bt with (nolock)
			INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype
			where (transid = @TransID OR (refno = @transid AND sp.productid IN (8,12))) --Dom
			AND custid = @Custid
	ELSE IF exists(  
	select top 1 1 from translog bt with (nolock)   
		INNER JOIN @SportBettype sp ON bt.gameID = sp.bettype
	where translogid = @TransID AND sp.productid IN (8,12) --Dom
	AND custid = @Custid  and statusID = 0
	)
		SELECT @WinlostDate = winlostdate, @bettype = gameID ,@refno = translogid
			from translog bt with (nolock)   
			INNER JOIN @SportBettype sp ON bt.gameID = sp.bettype
			where translogid = @TransID  AND sp.productid IN (8,12) --Dom
			AND custid = @Custid and statusID = 0
	ELSE IF exists(  
	select top 1 1 from bettrans14 bt with (nolock)   
	INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
	where (transid = @TransID OR (refno = @transid AND sp.productid IN (8,12))) --Dom
	AND custid = @Custid  
	)
	BEGIN
		SELECT @WinlostDate = winlostdate, @bettype = bt.bettype ,@refno = refno
		from bettrans14 bt with (nolock)   
		INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
		where (transid = @TransID OR (refno = @transid AND sp.productid IN (8,12))) --Dom
		AND custid = @Custid
		print 'btttt14'
	END
	ELSE IF exists(  
	select top 1 1 from DBARC.bodb_archive.dbo.bettrans_bk bt with (nolock)    
		INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
	where (transid = @TransID OR (refno = @transid AND sp.productid IN (8,12))) --20120405@Hurri  
	AND custid = @Custid  
	)
		SELECT @WinlostDate = winlostdate, @bettype = bt.bettype ,@refno = refno
		from DBARC.bodb_archive.dbo.bettrans_bk bt with (nolock)   
		INNER JOIN @SportBettype sp ON bt.bettype = sp.bettype 
		where (transid = @TransID OR (refno = @transid AND sp.productid IN (8,12))) --20120405@Hurri  
		AND custid = @Custid

	--select @WinlostDate,@bettype
	*/
	
	--Bettrans
	IF @WinlostDate > @MoveBetsDay  
	BEGIN  
	--IF @bettype < 19001 and @bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/) 
	--	and @bettype NOT IN (SELECT bettype FROM @SportBettype s WHERE s.ProductID = 5 AND s.EventType = 3)
	--	and @bettype NOT IN (SELECT bettype FROM @SportBettype s WHERE s.ProductID = 8 )
		--AND @bettype NOT BETWEEN 1501 AND 1599 
		--AND @bettype NOT IN(SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	IF(EXISTS (SELECT TOP 1 1 FROM @SportBettype WHERE eventtype = 1 AND bettype = @bettype ))
	BEGIN
		--Sportbooks  
		INSERT INTO @Data  
		SELECT   
			b.bettype,  
			b.transid,  
			isnull(b.BetID,0) as BetID,  
			b.refno,  
			m.matchcode,  
			'' as race,  
			m.eventdate as eventdate,  
			0 as virtualrate,  
			0 as isShowOTExRate,  
			b.sdiscount,  
			b.adiscount,  
			b.discount,   
			m.homeid,  
			m.awayid,  
			ISNULL(b.checktime,'') settleTime,  
			b.hdp1,  
			b.hdp2,  
			b.odds,     
			0 finalodds,  
			0 finalodds2,  
			b.OddsType,    
			CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'  
			ELSE b.status   
			END as status,  
			CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
			stake,  
			b.actual_stake,  
			b.transdate,  
			b.betteam,   
			b.spositiontaking,     
			b.mpositiontaking,     
			b.apositiontaking,  
			0 spositiontaking2,  
			0 mpositiontaking2,  
			0 apositiontaking2,     
			b.liveindicator,     
			b.modds,     
			b.custid,  
			b.livehomescore,   
			b.liveawayscore,   
			m.finalhomescore,   
			m.finalawayscore,   
			m.leagueid,  
			m.sporttype,  
			b.ip,  
			b.betfrom,  
			b.matchid,  
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
			--CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END as allowdelete,  
			CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or statusID NOT IN(0, 1, 112, 113, 111) or b.recommend IN (SELECT custid from #LASAgent) THEN 0 ELSE 1 END as allowdelete,  
			(b.winlost-b.actual_stake)  winlost,  
			b.playercomm as commission,  
			(b.scomm - b.acomm) as scomm,  
			(b.acomm - b.comm) as acomm,  
			(b.comm - b.playercomm) as comm,  
			b.awinlost,  
			b.mwinlost,  
			b.swinlost,  
			m.showtime,
			b.winlostdate,
			b.BetCheck,
			CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc   
		from   
			bettrans as b with (nolock)   
			inner join match as m with (nolock) on b.matchid = m.matchid --phuong.nguyen, remove left join match_remark  
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		where    
			b.custid = @Custid AND
			s.EventType=1 AND
			--b.bettype < 19001 and 
			--b.bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/) and 
			--b.bettype NOT BETWEEN 1501 and 1599 AND
			--b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) AND
			--s.eventtype = 1 AND
			(b.transid 	= @TransID  
				OR ( @bettype BETWEEN 801 AND 899 AND b.refno = @refno )
			)
			--exclude metric gaming running ticket
			AND (b.bettype NOT BETWEEN 801 AND 806 OR (b.bettype BETWEEN 801 AND 806 AND b.statusID NOT IN (0, 1)))
			
		UNION ALL -- translog metric gaming
		SELECT   
			b.gameid AS bettype,  
			b.translogid AS transid,  
			0 AS BetID,  
			b.translogid AS refno,  
			m.matchcode,  
			'' as race,  
			m.eventdate,  
			0 as virtualrate,  
			0 as isShowOTExRate,  
			b.sdiscount,  
			b.adiscount,  
			b.discount,   
			m.homeid,  
			m.awayid,  
			'' AS settleTime,  
			0 AS hdp1,  
			0 AS hdp2,  
			b.odds,     
			0 finalodds,  
			0 finalodds2,  
			--0 AS OddsType,    
			CASE WHEN b.gameid IN (801,803,804,805,806) THEN CONVERT(TINYINT, ISNULL(b.custom1, 0))  ELSE 0 END AS OddsType,
			b.status,  
			0 AS comstatus,  
			stake,  
			b.actual_stake,  
			b.transdate,  
			'' AS betteam,   
			b.spositiontaking,     
			b.mpositiontaking,     
			b.apositiontaking,  
			0 spositiontaking2,  
			0 mpositiontaking2,  
			0 apositiontaking2,     
			0 AS liveindicator,     
			0 AS modds,     
			b.custid,  
			0 AS livehomescore,   
			0 AS liveawayscore,   
			m.finalhomescore,   
			m.finalawayscore,   
			m.leagueid,  
			m.sporttype,  
			b.ip,  
			'' AS betfrom,  
			b.eventID,  
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
			CASE WHEN b.gameID in (SELECT typeid FROM @tableBettypeNotAllowDelete) or statusID NOT IN(0, 1, 112, 113, 111) or b.recommend IN (SELECT custid from #LASAgent) THEN 0 ELSE 1 END as allowdelete,  
			0 AS winlost,  
			0 AS commission,  
			0 AS scomm,  
			0 AS acomm,  
			0 AS comm,  
			0 AS awinlost,  
			0 AS mwinlost,  
			0 AS swinlost,  
			m.showtime,
			b.winlostdate,
			'' AS BetCheck,
			b.transdesc   
		from   
			dbo.translog as b with (nolock)   
			inner join dbo.match as m with (nolock) 
			on b.eventid = m.matchid
			INNER JOIN @SportBettype s 
			ON s.Bettype = b.gameid
		where    
			b.custid 			= @Custid 
			AND s.Bettype 		BETWEEN 801 AND 899
			AND b.translogid 	= @TransID 
			AND b.statusID		IN (0,1)		
	
	UPDATE betList
	SET betList.Odds	= originBetList.Odds
		,betList.Stake	= originBetList.Stake
		,betList.comm	= CASE WHEN betList.Bettype = 902 THEN ISNULL(commBetList.awinlost,0) ELSE betList.comm END
		,betList.BetID	= originBetList.Bettype
	FROM @Data AS betList
		INNER JOIN bettrans AS originBetList WITH(NOLOCK) ON betList.RefNO = originBetList.TransID
		LEFT JOIN @Data AS commBetList ON betList.RefNO = commBetList.RefNO AND commBetList.Bettype = 903
	WHERE betList.Sporttype = 1 AND betList.Bettype IN (901, 902)	

	END
	--Mix Parlay 
	IF @bettype = 9 
	INSERT INTO @Data  
		select   
		9 bettype,     
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		'' matchcode,    
		'' as race,  
		'' as eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,    
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
		b.stake,     
		b.actual_stake,  
		b.transdate transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,    
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,    
		0 liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,  
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		0 as sporttype,   
		b.ip,  
		b.betfrom,  
		0 matchid,   
		CONVERT(BIT,0) as IsNeutral,  
		CASE WHEN statusID = 0 and b.recommend NOT IN (SELECT custid from #LASAgent) THEN 1 ELSE 0 END as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc 		
	from bettrans as b with (nolock)     
	where    
		b.custid = @Custid    
		--and matchid=0    
		and matchid = 9  
		and bettype = 9    
		and b.transid = @TransID  

	IF @bettype = 29
	--Combination Mix Parlay  
	SELECT @refno = refno  
	FROM bettrans b WITH(NOLOCK)  
	WHERE b.custid = @Custid    
		--and matchid=0    
		and matchid = 29  
		and bettype = 29    
		and b.transid = @TransID  
	  
	--- Casino  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 6 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.betid transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		CONVERT(varchar(50), b.refno) matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,    
		b.actual_stake,   
		b.transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		251 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc       
	from bettrans b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid    
		--AND matchid in (0, 71)  
		--AND bettype = 71        --20120405@Hurri  
		--AND s.ProductID = 6
		--AND b.refno = @TransID  
		AND b.refno = @refno

	--IBC Bingo  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 7 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.betid transid,   
		isnull(b.BetID,0) as BetID,    
		b.refno,  
		CONVERT(varchar(50), b.refno) as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,     
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		252 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc         
	from bettrans b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid    
		--AND matchid in (0, 73) 
		--AND bettype = 73  
		AND s.ProductID = 7
		--AND b.refno = @TransID  
		AND b.refno = @refno

	--IBC Keno  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 8 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.betid transid,   
		isnull(b.BetID,0) as BetID,    
		b.refno,  
		CONVERT(varchar(50), b.refno) as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,     
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		d.ChoiceId betteam,   
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 
		0,    
		0 as leagueid,    
		202 as sporttype,   
		b.ip,  
		b.betfrom,  
		d.GameId matchid,
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate ,
		b.BetCheck,
		'' AS transdesc        
	from bettrans b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
	where     
		b.custid = @Custid    
		--AND bettype BETWEEN 1501 AND 1599
		AND s.ProductID = 8
		--AND b.refno = @TransID  
		AND b.refno = @refno
	UNION ALL	-- translog
	select 
		b.gameid bettype,   
		0 as transid, 
		0 as betid,
		b.translogid ,
		'' as matchcode,   
		'' as race,
		'' as eventdate, 
		0,
		0,
		sdiscount,
		adiscount,
		discount,	 
		0 as homeid,   
		0 as awayid,  
		'' settleTime, 
		0 hdp1,
		0 hdp2,
		b.odds,   
		0 finalodds,
		0 finalodds2,
		'' OddsType,  
		b.status,  
		0 as comstatus, 
		b.stake,  
		b.actual_stake,    
		b.transdate,   
		d.ChoiceId betteam,   
		b.spositiontaking,  
		b.mpositiontaking,   
		b.apositiontaking, 
		0 spositiontaking2,
		0 mpositiontaking2,
		0 apositiontaking2,   
		0 liveindicator,   
		0 modds,   
		b.custid,
		0 livehomescore, 
		0 liveawayscore,
		0 as finalhomescore, 
		0 as finalawayscore,  
		0 as leagueid,  
		202 as sporttype, 
		b.ip,
		b.betfrom,
		d.GameId matchid,
		CONVERT(BIT,0) as IsNeutral,
		0 as allowdelete,
		(-b.actual_stake)  winlost,
		0 as commission,
		0,
		0,
		0,
		0,
		0,
		0,
		'' as showtime,
		b.winlostdate,
		'' as BetCheck,
		'' AS transdesc  	 
	from translog b with (nolock)   
	INNER JOIN @SportBettype s ON s.Bettype = b.gameID
	outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.gameid) d
	where	b.custid = @Custid  
		--AND b.gameID BETWEEN 1501 AND 1599
		AND s.ProductID = 8
		AND b.statusID = 0
		AND b.translogid = @TransID  

	--- P2P  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 9 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		bettype,     
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		'' matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,    
		b.actual_stake,   
		b.transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		253 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate ,
		b.BetCheck,
		'' AS transdesc        
	from bettrans b with (nolock)     
	where     
		b.custid = @Custid    
		AND matchid = 1000  
		AND bettype = 1000  
		AND b.transid = @TransID  
	 
	--Outright  
	IF @bettype = 10
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,  
		isnull(b.BetID,0) as BetID,     
		b.refno,  
		odds.matchcode,   
		odds.groupmatch as race,  
		odds.eventdate as eventdate,  
		 0 as virtualrate,  
		0 as isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,     
		0 as homeid,  
		odds.teamid as awayid,  
		'' settleTime,   
		b.hdp1,   
		b.hdp2,   
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,   
		b.actual_stake,    
		b.transdate transdate,     
		b.betteam,     
		b.spositiontaking,     
		b.mpositiontaking,     
		b.apositiontaking,  
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,      
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,  
		b.liveawayscore,  
		0, 0,    
		odds.leagueid,  
		l.sporttype,  
		b.ip ,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		--CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or b.status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END as allowdelete,  
		CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or b.statusID NOT IN(0, 1, 112, 113, 111)  or b.recommend IN (SELECT custid from #LASAgent) THEN 0 ELSE 1 END as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc  
	from bettrans as b with (nolock)     
		inner join outright as odds with (nolock) on b.matchid=odds.orid     
		inner join league l with (nolock) on odds.leagueid=l.leagueid       
	where b.bettype = 10  
		and b.custid = @Custid      
		and b.transid = @TransID  
	 
	--HR  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 2 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		odds.matchcode,   
		odds.groupmatch as race,  
		odds.eventdate as eventdate,  
		b.virtualrate,  
		--isnumeric(odds.programID) as isShowOTExRate,  
		CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,     
		odds.teamid as homeid,
		0 as awayid,  
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		bm.finalodds,  
		bm.finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,     
		b.actual_stake,  
		b.transdate transdate,     
		b.betteam,     
		CASE WHEN b.bettype IN (33,43) THEN bm.spositiontaking ELSE b.spositiontaking END,     
		CASE WHEN b.bettype IN (33,43) THEN bm.mpositiontaking ELSE b.mpositiontaking END ,     
		CASE WHEN b.bettype IN (33,43) THEN bm.apositiontaking ELSE b.apositiontaking END,   
		CASE WHEN b.bettype IN (33,43) THEN bm.spositiontaking2 ELSE 0 END ,     
		CASE WHEN b.bettype IN (33,43) THEN bm.mpositiontaking2 ELSE 0 END,     
		CASE WHEN b.bettype IN (33,43) THEN bm.apositiontaking2 ELSE 0 END,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,  
		b.liveawayscore,  
		0, 0,    
		odds.leagueid,  
		l.sporttype,  
		b.ip ,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		--CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or b.status NOT IN('running', 'waiting', 'WON', 'LOSE', 'DRAW') THEN 0 ELSE 1 END as allowdelete,  
		CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or b.statusID NOT IN(0, 1, 112, 113, 111) or b.recommend IN (SELECT custid from #LASAgent) THEN 0 ELSE 1 END as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc        
	from bettrans as b with (nolock)     
		inner join outright as odds with (nolock) on b.matchid=odds.orid     
		inner join league l with (nolock) on odds.leagueid=l.leagueid    
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype  
		left join (     
			SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,  
			  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2  
			FROM bettransm t WITH (NOLOCK)  
			  INNER JOIN bettransm f WITH (NOLOCK) ON t.refno = f.refno   
			WHERE t.bettype in (31,41) AND f.bettype in (32,42)  
			) bm on b.transid = bm.refno   
	where s.ProductID = 2 --b.bettype in (31,32,33,41,42,43)  
		and b.custid = @Custid        
		and b.transid = @TransID  
	order by b.transid    

	-- Virtual HR  
	--IF @bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) 
	IF EXISTS(SELECT TOP 1 1 FROM @SportBettype s WHERE s.ProductID = 5 AND s.EventType = 3 AND s.bettype = @bettype)
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,  
		'' as BetID,  
		b.refno,  
		o.RacerNum matchcode, --Horse Number  
		b.oddsid as Race, --Outright ID  
		'' eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,   
		o.RacerID as homeID,   
		0 as awayID,  
		'' settleTime,  
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		b.OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		stake,  
		b.actual_stake,  
		b.transdate,  
		'' betteam,   	
		CASE WHEN b.bettype = 1233 THEN bm.spositiontaking ELSE b.spositiontaking END,     
		CASE WHEN b.bettype = 1233 THEN bm.mpositiontaking ELSE b.mpositiontaking END ,     
		CASE WHEN b.bettype = 1233 THEN bm.apositiontaking ELSE b.apositiontaking END,   
		CASE WHEN b.bettype = 1233 THEN bm.spositiontaking2 ELSE 0 END ,     
		CASE WHEN b.bettype = 1233 THEN bm.mpositiontaking2 ELSE 0 END,     
		CASE WHEN b.bettype = 1233 THEN bm.apositiontaking2 ELSE 0 END,       
		0 liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,   
		0 finalhomescore,   
		0 finalawayscore,   
		r.leagueid,  
		r.sporttype,  
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT (BIT, 0) AS IsNeutral,  
		CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or statusID NOT IN(0, 1, 112, 113, 111) or b.recommend IN (SELECT custid from #LASAgent) THEN 0 ELSE 1 END as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		r.EventTime showtime, -- Race Name  	
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc  
	from   
		bettrans as b with (nolock)   
		INNER JOIN VSOutright o WITH (NOLOCK) ON b.oddsid = o.Orid  
		INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID  
		INNER JOIN @SportBettype s ON s.BetType = b.BetType 
		left join (     
			SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
			  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
			FROM bettransm t WITH (NOLOCK)  
			  INNER JOIN bettransm f WITH (NOLOCK) ON t.refno = f.refno   
			WHERE t.bettype = 1231 AND f.bettype = 1232 
			) bm on b.refno = bm.refno   
	where    
		b.custid = @Custid and  
		--b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and   
		s.ProductID = 5 AND
		s.EventType = 3 AND
		b.transid = @TransID  

	--Gold Deluxe
	IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 12 AND Bettype = @Bettype)
		BEGIN
			INSERT INTO @Data  
			select   
				b.bettype,     
				b.transid,   
				isnull(b.BetID,0) as BetID,    
				b.refno,  
				'' as matchcode,     
				'' as race,  
				'' as eventdate,   
				0 as virtualrate,  
				0 as isShowOTExRate,  
				sdiscount,  
				adiscount,  
				discount,    
				0 as homeid,     
				0 as awayid,    
				'' settleTime,   
				b.hdp1,  
				b.hdp2,  
				b.odds,     
				0 finalodds,  
				0 finalodds2,  
				'' OddsType,    
				b.status,  
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,     
				b.stake,     
				b.actual_stake,  
				b.transdate,     
				b.betteam,   
				b.spositiontaking,    
				b.mpositiontaking,     
				b.apositiontaking,   
				0 spositiontaking2,  
				0 mpositiontaking2,  
				0 apositiontaking2,     
				b.liveindicator,     
				b.modds,     
				b.custid,  
				b.livehomescore,   
				b.liveawayscore,  
				0, 
				0,    
				0 as leagueid,    
				255 as sporttype,   
				b.ip,  
				b.betfrom,  
				b.matchid,
				CONVERT(BIT,0) as IsNeutral,  
				0 as allowdelete,  
				(b.winlost-b.actual_stake)  winlost,  
				b.playercomm as commission,  
				(b.scomm - b.acomm) as scomm,  
				(b.acomm - b.comm) as acomm,  
				(b.comm - b.playercomm) as comm,  
				b.awinlost,  
				b.mwinlost,  
				b.swinlost,  
				'' as showtime,
				b.winlostdate ,
				b.BetCheck,
				'' AS transdesc        
			from dbo.bettrans b with (nolock)     
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where     
				b.custid = @Custid    
				AND s.ProductID = 12
				AND b.refno = @refno

			UNION ALL	-- translog
			select 
				b.gameid bettype,   
				b.translogid as transid, 
				0 as betid,
				b.translogid AS refno,
				'' as matchcode,   
				'' as race,
				'' as eventdate, 
				0,
				0,
				sdiscount,
				adiscount,
				discount,	 
				0 as homeid,   
				0 as awayid,  
				'' settleTime, 
				0 hdp1,
				0 hdp2,
				b.odds,   
				0 finalodds,
				0 finalodds2,
				'' OddsType,  
				b.status,  
				0 as comstatus, 
				b.stake,  
				b.actual_stake,    
				b.transdate,   
				b.GameID3rd betteam,   
				b.spositiontaking,  
				b.mpositiontaking,   
				b.apositiontaking, 
				0 spositiontaking2,
				0 mpositiontaking2,
				0 apositiontaking2,   
				0 liveindicator,   
				0 modds,   
				b.custid,
				0 livehomescore, 
				0 liveawayscore,
				0 as finalhomescore, 
				0 as finalawayscore,  
				0 as leagueid,  
				255 as sporttype, 
				b.ip,
				b.betfrom,
				NULL matchid,
				CONVERT(BIT,0) as IsNeutral,
				0 as allowdelete,
				(-b.actual_stake)  winlost,
				0 as commission,
				0,
				0,
				0,
				0,
				0,
				0,
				'' as showtime,
				b.winlostdate,
				b.GameID3rd as BetCheck,
				'' AS transdesc  	 
			from dbo.translog b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.gameID
			where	b.custid = @Custid  
				AND s.ProductID = 12
				AND b.statusID = 0
				AND b.translogid = @refno
		END

	-- MicroGamming
	IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 13 AND Bettype = @Bettype)
		BEGIN
			INSERT INTO @Data  
			select   
				b.bettype,     
				b.transid,   
				isnull(b.BetID,0) as BetID,    
				b.refno,  
				'' as matchcode,     
				'' as race,  
				'' as eventdate,   
				0 as virtualrate,  
				0 as isShowOTExRate,  
				sdiscount,  
				adiscount,  
				discount,    
				0 as homeid,     
				0 as awayid,    
				'' settleTime,   
				b.hdp1,  
				b.hdp2,  
				b.odds,     
				0 finalodds,  
				0 finalodds2,  
				'' OddsType,    
				b.status,  
				CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,     
				b.stake,     
				b.actual_stake,  
				b.transdate,     
				b.betteam,   
				b.spositiontaking,    
				b.mpositiontaking,     
				b.apositiontaking,   
				0 spositiontaking2,  
				0 mpositiontaking2,  
				0 apositiontaking2,     
				b.liveindicator,     
				b.modds,     
				b.custid,  
				b.livehomescore,   
				b.liveawayscore,  
				0, 
				0,    
				0 as leagueid,    
				203 as sporttype,   
				b.ip,  
				b.betfrom,  
				b.matchid,
				CONVERT(BIT,0) as IsNeutral,  
				0 as allowdelete,  
				(b.winlost-b.actual_stake)  winlost,  
				b.playercomm as commission,  
				(b.scomm - b.acomm) as scomm,  
				(b.acomm - b.comm) as acomm,  
				(b.comm - b.playercomm) as comm,  
				b.awinlost,  
				b.mwinlost,  
				b.swinlost,  
				'' as showtime,
				b.winlostdate ,
				b.BetCheck,
				'' AS transdesc        
			from dbo.bettrans b with (nolock)     
			INNER JOIN @SportBettype s ON s.Bettype = b.bettype
			where     
				b.custid = @Custid    
				AND s.ProductID = 13
				AND b.refno = @refno

			UNION ALL	-- translog
			select 
				b.gameid bettype,   
				b.translogid as transid, 
				0 as betid,
				b.translogid AS refno,
				'' as matchcode,   
				'' as race,
				'' as eventdate, 
				0,
				0,
				sdiscount,
				adiscount,
				discount,	 
				0 as homeid,   
				0 as awayid,  
				'' settleTime, 
				0 hdp1,
				0 hdp2,
				b.odds,   
				0 finalodds,
				0 finalodds2,
				'' OddsType,  
				b.status,  
				0 as comstatus, 
				b.stake,  
				b.actual_stake,    
				b.transdate,   
				b.GameID3rd betteam,   
				b.spositiontaking,  
				b.mpositiontaking,   
				b.apositiontaking, 
				0 spositiontaking2,
				0 mpositiontaking2,
				0 apositiontaking2,   
				0 liveindicator,   
				0 modds,   
				b.custid,
				0 livehomescore, 
				0 liveawayscore,
				0 as finalhomescore, 
				0 as finalawayscore,  
				0 as leagueid,  
				203 as sporttype, 
				b.ip,
				b.betfrom,
				NULL matchid,
				CONVERT(BIT,0) as IsNeutral,
				0 as allowdelete,
				(-b.actual_stake)  winlost,
				0 as commission,
				0,
				0,
				0,
				0,
				0,
				0,
				'' as showtime,
				b.winlostdate,
				b.GameID3rd as BetCheck,
				'' AS transdesc  	 
			from dbo.translog b with (nolock)   
			INNER JOIN @SportBettype s ON s.Bettype = b.gameID
			where	b.custid = @Custid  
				AND s.ProductID = 13
				AND b.statusID = 0
				AND b.translogid = @refno
		END
	END  

	--Bettrans14  
	ELSE IF @WinlostDate <= @MoveBetsDay and @WinlostDate >= @BalanceUpDay 
	BEGIN  
	--IF @bettype < 19001 and @bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/)
	--	and @bettype NOT IN (SELECT bettype FROM @SportBettype s WHERE s.ProductID = 5 AND s.EventType = 3)		
	--	and @bettype NOT IN (SELECT bettype FROM @SportBettype s WHERE s.ProductID = 8 )
	--AND @bettype NOT IN(SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	--AND @bettype NOT BETWEEN 1501 and 1599 
	IF(EXISTS (SELECT TOP 1 1 FROM @SportBettype WHERE eventtype = 1 AND bettype = @bettype ))
	--Sportbooks  
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,  
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		m.matchcode,  
		'' as race,  
		m.eventdate as eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,   
		m.homeid,  
		m.awayid,  
		ISNULL(b.checktime,'') settleTime,  
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		b.OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		stake,  
		b.actual_stake,  
		b.transdate,  
		b.betteam,   
		b.spositiontaking,     
		b.mpositiontaking,     
		b.apositiontaking,  
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,   
		m.finalhomescore,   
		m.finalawayscore,   
		m.leagueid,  
		m.sporttype,  
		b.ip,  
		b.betfrom,  
		b.matchid,  
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		m.showtime,
		b.winlostdate,
		b.BetCheck,
		CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc        
	from   
		bettrans14 as b with (nolock)   
		inner join match14 as m with (nolock) on b.matchid = m.matchid  
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where    
		b.custid = @Custid and  
		--b.bettype < 19001 and b.bettype NOT IN (31,32,33,10/*, 1231,1232,1233,1237,1238*/) 
		--AND b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
		--AND b.bettype not BETWEEN 1501 and 1500 
		s.EventType = 1 AND
		--b.transid = @TransID  
		(b.transid 	= @TransID  
				OR ( @bettype BETWEEN 801 AND 899 AND b.refno = @refno )
			)
	
	UPDATE betList
	SET betList.Odds	= originBetList.Odds
		,betList.Stake	= originBetList.Stake
		,betList.comm	= CASE WHEN betList.Bettype = 902 THEN ISNULL(commBetList.awinlost,0) ELSE betList.comm END
		,betList.BetID	= originBetList.Bettype
	FROM @Data AS betList
		INNER JOIN bettrans14 AS originBetList WITH(NOLOCK) ON betList.RefNO = originBetList.TransID
		LEFT JOIN @Data AS commBetList ON betList.RefNO = commBetList.RefNO AND commBetList.Bettype = 903
	WHERE betList.Sporttype = 1 AND betList.Bettype IN (901, 902)

	--Mix Parlay  
	IF @bettype = 9
	INSERT INTO @Data  
	select   
		9 bettype,     
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		'' matchcode,    
		'' as race,  
		'' as eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,     
		b.stake,     
		b.actual_stake,  
		b.transdate transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,    
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,    
		0 liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,  
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		0 as sporttype,   
		b.ip,  
		b.betfrom,  
		0 matchid,   
		CONVERT(BIT,0) as IsNeutral,  
		CASE WHEN statusID = 0 and b.recommend NOT IN (SELECT custid from #LASAgent) THEN 1 ELSE 0 END as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc
		
	from bettrans14 as b with (nolock)     
	where    
		b.custid = @Custid    
		--and matchid=0    
		and matchid = 9  
		and bettype = 9    
		and b.transid = @TransID  

	--Combination Mix Parlay 
	IF @bettype = 29 
	SELECT @refno = refno  
	FROM bettrans14 b WITH(NOLOCK)  
	WHERE b.custid = @Custid    
		--and matchid=0    
		and matchid = 29  
		and bettype = 29    
		and b.transid = @TransID   
	 
	--- Casino  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 6 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.betid transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		CONVERT(varchar(50), b.refno) matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,    
		b.actual_stake,   
		b.transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		251 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc         
	from bettrans14 b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid   
		--AND matchid in (0, 71) 
		--AND bettype = 71        --20120405@Hurri
		AND s.ProductID = 6
		--AND b.refno = @TransID  
		AND b.refno = @refno  

	--IBC Bingo  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 7 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.betid transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		CONVERT(varchar(50), b.refno) as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		252 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc        
	from bettrans14 b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid   
		--AND matchid in (0, 73)  
		--AND bettype = 73  
		AND s.ProductID = 7 
		--AND b.refno = @TransID  
		AND b.refno = @refno  

	--IBC Keno
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 8 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.betid transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		CONVERT(varchar(50), b.refno) as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		d.ChoiceId betteam,   
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		202 as sporttype,   
		b.ip,  
		b.betfrom,  
		d.GameId matchid,
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc         
	from bettrans14 b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
	where     
		b.custid = @Custid   
		--AND bettype BETWEEN 1501 AND 1599  
		--AND b.refno = @TransID  
		AND b.refno = @refno  
		AND s.ProductID = 8
		AND b.statusID NOT IN (0,1)					
	--- P2P  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 9 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		bettype,     
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		'' matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,    
		b.actual_stake,   
		b.transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		253 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc         
	from bettrans14 b with (nolock)     
	where     
		b.custid = @Custid   
		AND matchid = 1000  
		AND bettype = 1000  
		AND b.transid = @TransID  

	--Outright  
	IF @bettype = 10
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,  
		isnull(b.BetID,0) as BetID,      
		b.refno,  
		odds.matchcode,   
		odds.groupmatch as race,  
		odds.eventdate as eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,     
		0 as homeid,  
		odds.teamid as awayid,  
		'' settleTime,   
		b.hdp1,   
		b.hdp2,   
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,     
		b.actual_stake,  
		b.transdate transdate,     
		b.betteam,     
		b.spositiontaking,     
		b.mpositiontaking,     
		b.apositiontaking,  
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,      
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,  
		b.liveawayscore,  
		0, 0,    
		odds.leagueid,  
		l.sporttype,  
		b.ip ,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc     
	from bettrans14 as b with (nolock)     
		inner join outright14 as odds with (nolock) on b.matchid=odds.orid     
		inner join league l with (nolock) on odds.leagueid=l.leagueid       
	where b.bettype = 10  
		and b.custid = @Custid      
		and b.transid = @TransID  
	 
	--HR  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 2 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		odds.matchcode,   
		odds.groupmatch as race,  
		odds.eventdate as eventdate,  
		b.virtualrate,  
		--isnumeric(odds.programID) as isShowOTExRate,  
		CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,     
		odds.teamid as homeid,
		0 as awayid, 
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		bm.finalodds,  
		bm.finalodds2,  
		'' OddsType,    
		b.status,    
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
		b.stake,   
		b.actual_stake,    
		b.transdate transdate,     
		b.betteam,     
		CASE WHEN b.bettype IN (33,43) THEN bm.spositiontaking ELSE b.spositiontaking END,     
		CASE WHEN b.bettype IN (33,43) THEN bm.mpositiontaking ELSE b.mpositiontaking END ,     
		CASE WHEN b.bettype IN (33,43) THEN bm.apositiontaking ELSE b.apositiontaking END,   
		CASE WHEN b.bettype IN (33,43) THEN bm.spositiontaking2 ELSE 0 END ,     
		CASE WHEN b.bettype IN (33,43) THEN bm.mpositiontaking2 ELSE 0 END,     
		CASE WHEN b.bettype IN (33,43) THEN bm.apositiontaking2 ELSE 0 END,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,  
		b.liveawayscore,  
		0, 0,    
		odds.leagueid,  
		l.sporttype,  
		b.ip ,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc        
	from bettrans14 as b with (nolock)     
		inner join outright14 as odds with (nolock) on b.matchid=odds.orid     
		inner join league l with (nolock) on odds.leagueid=l.leagueid      
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		left join (     
			SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,  
			  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2  
			FROM bettransm14 t WITH (NOLOCK)  
			  INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno   
			WHERE t.bettype in (31,41) AND f.bettype in (32,42)  
			) bm on b.transid = bm.refno   
	where s.ProductID = 2 --b.bettype in (31,32,33,41,42,43)  
		and b.custid = @Custid        
		and b.transid = @TransID  
	order by b.transid    

	-- Virtual HR  
	--IF @bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	IF EXISTS(SELECT TOP 1 1 FROM @SportBettype s WHERE s.ProductID = 5 AND s.EventType = 3 AND s.bettype = @bettype)
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,  
		'' as BetID,  
		b.refno,  
		o.RacerNum matchcode, --Horse Number  
		b.oddsid as Race, --Outright ID  
		'' eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,   
		o.RacerID as homeID,   
		0 as awayID,  
		'' settleTime,  
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		b.OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		stake,  
		b.actual_stake,  
		b.transdate,  
		'' betteam,   
		CASE WHEN b.bettype = 1233 THEN bm.spositiontaking ELSE b.spositiontaking END,     
		CASE WHEN b.bettype = 1233 THEN bm.mpositiontaking ELSE b.mpositiontaking END ,     
		CASE WHEN b.bettype = 1233 THEN bm.apositiontaking ELSE b.apositiontaking END,   
		CASE WHEN b.bettype = 1233 THEN bm.spositiontaking2 ELSE 0 END ,     
		CASE WHEN b.bettype = 1233 THEN bm.mpositiontaking2 ELSE 0 END,     
		CASE WHEN b.bettype = 1233 THEN bm.apositiontaking2 ELSE 0 END,   
		0 liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,   
		0 finalhomescore,   
		0 finalawayscore,   
		r.leagueid,  
		r.sporttype,  
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT (BIT, 0) AS IsNeutral,  
		CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or statusID NOT IN(0, 1, 112, 113, 111) or b.recommend IN (SELECT custid from #LASAgent) THEN 0 ELSE 1 END as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		r.EventTime showtime, -- Race Name   
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc  
	from   
		bettrans14 as b with (nolock)   
		INNER JOIN VSOutright14 o WITH (NOLOCK) ON b.oddsid = o.Orid  
		INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID  
		INNER JOIN @SportBettype s ON s.BetType = b.BetType 
		left join (     
			SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
			  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
			FROM bettransm14 t WITH (NOLOCK)  
			  INNER JOIN bettransm14 f WITH (NOLOCK) ON t.refno = f.refno   
			WHERE t.bettype = 1231 AND f.bettype = 1232 
			) bm on b.refno = bm.refno  
	where    
		b.custid = @Custid AND  
		s.ProductID = 5 AND
		s.EventType = 3 AND
		--b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and   
		b.transid = @TransID  
	 --Gold Deluxe
	IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 12 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.transid,   
		isnull(b.BetID,0) as BetID,    
		b.refno,  
		'' as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,     
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		b.betteam,   
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 
		0,    
		0 as leagueid,    
		255 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate ,
		b.BetCheck,
		'' AS transdesc        
	from dbo.bettrans14 b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid    
		AND s.ProductID = 12
		AND b.refno = @refno 

	-- MicroGamming
	IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 13 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.transid,   
		isnull(b.BetID,0) as BetID,    
		b.refno,  
		'' as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,     
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		b.betteam,   
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 
		0,    
		0 as leagueid,    
		203 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate ,
		b.BetCheck,
		'' AS transdesc        
	from dbo.bettrans14 b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid    
		AND s.ProductID = 13
		AND b.refno = @refno 
	END  
	--bettrans_bk  
	ELSE IF @WinlostDate < @BalanceUpDay 
	BEGIN  
	--Sportbooks  
	--IF @bettype < 19001 and @bettype NOT IN (31,32,33,10/*, 1231, 1232, 1233, 1237, 1238*/) 
	--and @bettype NOT IN (SELECT bettype FROM @SportBettype s WHERE s.ProductID = 5 AND s.EventType = 3)
	--and @bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	IF(EXISTS (SELECT TOP 1 1 FROM @SportBettype WHERE ProductID = 1 AND eventtype = 1 AND bettype = @bettype ))
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,  
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		m.matchcode,  
		'' as race,  
		m.eventdate as eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,   
		m.homeid,  
		m.awayid,  
		ISNULL(b.checktime,'') settleTime,  
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		b.OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		stake,  
		b.actual_stake,  
		b.transdate,  
		b.betteam,   
		b.spositiontaking,     
		b.mpositiontaking,     
		b.apositiontaking,  
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,   
		m.finalhomescore,   
		m.finalawayscore,   
		m.leagueid,  
		m.sporttype,  
		b.ip,  
		b.betfrom,  
		b.matchid,  
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		m.showtime,
		b.winlostdate,
		b.BetCheck,
		CASE WHEN b.bettype BETWEEN 801 AND 899 THEN b.transdesc ELSE '' END AS transdesc        
	from   
		DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)   
		inner join DBARC.bodb_archive.dbo.match_BK as m with (nolock) on b.matchid = m.matchid  
		INNER JOIN @SportBettype s ON s.BetType = b.BetType 
	where    
		b.custid = @Custid and  
		s.EventType = 1 AND
		--b.bettype < 19001 and b.bettype NOT IN (31,32,33,10/*, 1231, 1232, 1233, 1237, 1238*/) and   
		--b.bettype NOT IN (SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and
		--b.transid = @TransID  
		(b.transid 	= @TransID  
				OR ( @bettype BETWEEN 801 AND 899 AND b.refno = @refno )
			) 

	UPDATE betList
	SET betList.Odds	= originBetList.Odds
		,betList.Stake	= originBetList.Stake
		,betList.comm	= CASE WHEN betList.Bettype = 902 THEN ISNULL(commBetList.awinlost,0) ELSE betList.comm END
		,betList.BetID	= originBetList.Bettype
	FROM @Data AS betList
		INNER JOIN DBARC.bodb_archive.dbo.bettrans_bk AS originBetList WITH(NOLOCK) ON betList.RefNO = originBetList.TransID
		LEFT JOIN @Data AS commBetList ON betList.RefNO = commBetList.RefNO AND commBetList.Bettype = 903
	WHERE betList.Sporttype = 1 AND betList.Bettype IN (901, 902)

	--Mix Parlay  
	IF @bettype = 9
	INSERT INTO @Data  
	select   
		9 bettype,     
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		'' matchcode,    
		'' as race,  
		'' as eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,   
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,    
		b.stake,    
		b.actual_stake,   
		b.transdate transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,    
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,    
		0 liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,  
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		0 as sporttype,   
		b.ip,  
		b.betfrom,  
		0 matchid,   
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc         
	from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
	where    
		b.custid = @Custid    
		--and matchid=0    
		and matchid = 9  
		and bettype = 9    
		and b.transid = @TransID  

	--Combination Mix Parlay 
	IF @bettype = 29 
	SELECT @refno = refno  
	FROM DBARC.bodb_archive.dbo.bettrans_bk b WITH(NOLOCK)  
	WHERE b.custid = @Custid    
		--and matchid=0    
		and matchid = 29  
		and bettype = 29    
		and b.transid = @TransID  

	--- Casino  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 6 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.betid transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		CONVERT(varchar(50), b.refno) matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,   
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,    
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		251 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc         
	from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid    
		AND s.ProductID = 6
		--AND matchid in (0, 71)  
		--AND bettype = 71        --20120405@Hurri  
		--AND b.refno = @TransID  
		AND b.refno = @refno  

	--- IBC Bingo 
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 7 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.betid transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		CONVERT(varchar(50), b.refno) as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,   
		b.actual_stake,    
		b.transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		252 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc        
	from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid    
		--AND matchid in (0, 73)  
		--AND bettype = 73  
		AND s.ProductID = 7
		--AND b.refno = @TransID  
		AND b.refno = @refno  

	--- IBC keno 
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 8 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.betid transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		CONVERT(varchar(50), b.refno) as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,   
		b.actual_stake,    
		b.transdate,     
		d.ChoiceId betteam,   
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		202 as sporttype,   
		b.ip,  
		b.betfrom,  
		d.GameId matchid,
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc        
	from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	outer apply dbo.[f_ParseTransDesc](b.TransDesc, b.bettype) d
	where     
		b.custid = @Custid    
		AND s.ProductID = 8
		--AND bettype BETWEEN 1501 AND 1599
		--AND b.refno = @TransID  
		AND b.refno = @refno  

	--- P2P  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 9 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		bettype,     
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		'' matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		b.betteam,     
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 0,    
		0 as leagueid,    
		253 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc         
	from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
	where     
		b.custid = @Custid    
		AND matchid = 1000  
		AND bettype = 1000  
		AND b.transid = @TransID  
	 

	--Outright  
	IF @bettype = 10
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		odds.matchcode,   
		odds.groupmatch as race,  
		odds.eventdate as eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,     
		0 as homeid,  
		odds.teamid as awayid,  
		'' settleTime,   
		b.hdp1,   
		b.hdp2,   
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,     
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		b.stake,     
		b.actual_stake,  
		b.transdate transdate,     
		b.betteam,     
		b.spositiontaking,     
		b.mpositiontaking,     
		b.apositiontaking,  
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,      
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,  
		b.liveawayscore,  
		0, 0,    
		odds.leagueid,  
		l.sporttype,  
		b.ip ,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc        
	from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)     
		inner join DBARC.bodb_archive.dbo.Outright_bk as odds with (nolock) on b.matchid=odds.orid     
		inner join league l with (nolock) on odds.leagueid=l.leagueid       
	where b.bettype = 10  
		and b.custid = @Custid      
		and b.transid = @TransID     

	--HR  
	ELSE IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 2 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,     
		isnull(b.BetID,0) as BetID,  
		b.refno,  
		odds.matchcode,   
		odds.groupmatch as race,  
		odds.eventdate as eventdate,  
		b.virtualrate,  
		--isnumeric(odds.programID) as isShowOTExRate,  
		CASE WHEN b.currency2 IS NULL THEN CONVERT(BIT,0) ELSE CONVERT(BIT,1) END AS isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,     
		odds.teamid as homeid,
		0 as awayid,   
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		bm.finalodds,  
		bm.finalodds2,  
		'' OddsType,    
		b.status,   
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,    
		b.stake,    
		b.actual_stake,   
		b.transdate transdate,     
		b.betteam,     
		CASE WHEN b.bettype IN (33,43) THEN bm.spositiontaking ELSE b.spositiontaking END,     
		CASE WHEN b.bettype IN (33,43) THEN bm.mpositiontaking ELSE b.mpositiontaking END ,     
		CASE WHEN b.bettype IN (33,43) THEN bm.apositiontaking ELSE b.apositiontaking END,   
		CASE WHEN b.bettype IN (33,43) THEN bm.spositiontaking2 ELSE 0 END ,     
		CASE WHEN b.bettype IN (33,43) THEN bm.mpositiontaking2 ELSE 0 END,     
		CASE WHEN b.bettype IN (33,43) THEN bm.apositiontaking2 ELSE 0 END,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,  
		b.liveawayscore,  
		0, 0,    
		odds.leagueid,  
		l.sporttype,  
		b.ip ,  
		b.betfrom,  
		b.matchid,  
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,   
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate ,
		b.BetCheck,
		'' AS transdesc       
	from DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)   
		inner join DBARC.bodb_archive.dbo.Outright_bk as odds with (nolock) on b.matchid=odds.orid     
		inner join league l with (nolock) on odds.leagueid=l.leagueid      
		INNER JOIN @SportBettype s ON s.Bettype = b.bettype
		left join (     
			SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking, t.finalodds,  
			  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2, f.finalodds finalodds2  
			FROM DBARC.bodb_archive.dbo.bettransm t WITH (NOLOCK)  
			  INNER JOIN DBARC.bodb_archive.dbo.bettransm f WITH (NOLOCK) ON t.refno = f.refno   
			WHERE t.bettype in (31,41) AND f.bettype in (32,42)  
			) bm on b.transid = bm.refno   
	where s.ProductID = 2 --b.bettype in (31,32,33,41,42,43)  
		and b.custid = @Custid        
		and b.transid = @TransID  
	order by b.transid   

	-- Virtual HR  
	IF EXISTS(SELECT TOP 1 1 FROM @SportBettype s WHERE s.ProductID = 5 AND s.EventType = 3 AND s.bettype = @bettype)
	--IF @bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype())
	INSERT INTO @Data  
	select   
		b.bettype,  
		b.transid,  
		'' as BetID,  
		b.refno,  
		o.RacerNum matchcode, --Horse Number  
		b.oddsid as Race, --Outright ID  
		'' eventdate,  
		0 as virtualrate,  
		0 as isShowOTExRate,  
		b.sdiscount,  
		b.adiscount,  
		b.discount,   
		o.RacerID as homeID,   
		0 as awayID,  
		'' settleTime,  
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		b.OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,  
		stake,  
		b.actual_stake,  
		b.transdate,  
		'' betteam,     
		CASE WHEN b.bettype = 1233 THEN bm.spositiontaking ELSE b.spositiontaking END,     
		CASE WHEN b.bettype = 1233 THEN bm.mpositiontaking ELSE b.mpositiontaking END ,     
		CASE WHEN b.bettype = 1233 THEN bm.apositiontaking ELSE b.apositiontaking END,   
		CASE WHEN b.bettype = 1233 THEN bm.spositiontaking2 ELSE 0 END ,     
		CASE WHEN b.bettype = 1233 THEN bm.mpositiontaking2 ELSE 0 END,     
		CASE WHEN b.bettype = 1233 THEN bm.apositiontaking2 ELSE 0 END,      
		0 liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,   
		0 finalhomescore,   
		0 finalawayscore,   
		r.leagueid,  
		r.sporttype,  
		b.ip,  
		b.betfrom,  
		b.matchid,  
		CONVERT (BIT, 0) AS IsNeutral,  
		CASE WHEN b.bettype in (SELECT typeid FROM @tableBettypeNotAllowDelete) or statusID NOT IN(0, 1, 112, 113, 111) or b.recommend IN (SELECT custid from #LASAgent) THEN 0 ELSE 1 END as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		r.EventTime showtime, -- Race Name   	
		b.winlostdate,
		b.BetCheck,
		'' AS transdesc  
	from   
		DBARC.bodb_archive.dbo.bettrans_bk as b with (nolock)   
		INNER JOIN DBARC.bodb_archive.dbo.VSOutright_bk o WITH (NOLOCK) ON b.oddsid = o.Orid  
		INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID  
		INNER JOIN @SportBettype s ON s.BetType = b.BetType 
		left join (     
			SELECT t.refno, t.apositiontaking , t.mpositiontaking, t.spositiontaking,
			  f.apositiontaking apositiontaking2, f.mpositiontaking mpositiontaking2, f.spositiontaking spositiontaking2
			FROM DBARC.bodb_archive.dbo.bettransm t WITH (NOLOCK)  
			  INNER JOIN DBARC.bodb_archive.dbo.bettransm f WITH (NOLOCK) ON t.refno = f.refno   
			WHERE t.bettype = 1231 AND f.bettype = 1232 
			) bm on b.refno = bm.refno  
	where    
		b.custid = @Custid AND  
		s.ProductID=5 AND 
		s.EventType=3 AND
		--b.bettype in (/*1231, 1232, 1233, 1237, 1238*/SELECT  bettype FROM dbo.f_VSHorseRacingByBettype()) and   
		b.transid = @TransID  

	 --Gold Deluxe
	IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 12 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.transid,   
		isnull(b.BetID,0) as BetID,    
		b.refno,  
		'' as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,     
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		b.betteam,   
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 
		0,    
		0 as leagueid,    
		255 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate ,
		b.BetCheck,
		'' AS transdesc        
	from DBARC.bodb_archive.dbo.bettrans_bk b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid    
		AND s.ProductID = 12
		AND b.refno = @refno

	 --Gold Deluxe
	IF EXISTS (SELECT TOP 1 1 FROM  @SportBettype s  WHERE ProductID = 13 AND Bettype = @Bettype)
	INSERT INTO @Data  
	select   
		b.bettype,     
		b.transid,   
		isnull(b.BetID,0) as BetID,    
		b.refno,  
		'' as matchcode,     
		'' as race,  
		'' as eventdate,   
		0 as virtualrate,  
		0 as isShowOTExRate,  
		sdiscount,  
		adiscount,  
		discount,    
		0 as homeid,     
		0 as awayid,    
		'' settleTime,   
		b.hdp1,  
		b.hdp2,  
		b.odds,     
		0 finalodds,  
		0 finalodds2,  
		'' OddsType,    
		b.status,  
		CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,     
		b.stake,     
		b.actual_stake,  
		b.transdate,     
		b.betteam,   
		b.spositiontaking,    
		b.mpositiontaking,     
		b.apositiontaking,   
		0 spositiontaking2,  
		0 mpositiontaking2,  
		0 apositiontaking2,     
		b.liveindicator,     
		b.modds,     
		b.custid,  
		b.livehomescore,   
		b.liveawayscore,  
		0, 
		0,    
		0 as leagueid,    
		203 as sporttype,   
		b.ip,  
		b.betfrom,  
		b.matchid,
		CONVERT(BIT,0) as IsNeutral,  
		0 as allowdelete,  
		(b.winlost-b.actual_stake)  winlost,  
		b.playercomm as commission,  
		(b.scomm - b.acomm) as scomm,  
		(b.acomm - b.comm) as acomm,  
		(b.comm - b.playercomm) as comm,  
		b.awinlost,  
		b.mwinlost,  
		b.swinlost,  
		'' as showtime,
		b.winlostdate ,
		b.BetCheck,
		'' AS transdesc        
	from DBARC.bodb_archive.dbo.bettrans_bk b with (nolock)     
	INNER JOIN @SportBettype s ON s.Bettype = b.bettype
	where     
		b.custid = @Custid    
		AND s.ProductID = 13
		AND b.refno = @refno

	END  

	---- get data of systemp parlay  
	IF @refno IS NOT NULL 
	BEGIN  
		-- tickets in bettrans   
		INSERT INTO @Data  
		select   
			29 bettype,     
			CASE WHEN ISNULL(b.betid,0) = 0 THEN b.transid ELSE b.betID END as transid,     
			isnull(b.BetID,0) as BetID,  
			b.refno,  
			'' matchcode,    
			'' as race,  
			'' as eventdate,  
			0 as virtualrate,  
			0 as isShowOTExRate,  
			sdiscount,  
			adiscount,  
			discount,    
			0 as homeid,     
			0 as awayid,    
			'' settleTime,   
			b.hdp1,  
			b.hdp2,  
			b.odds,     
			0 finalodds,  
			0 finalodds2,  
			'' OddsType,    
			b.status,    
			CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
			b.stake,     
			b.actual_stake,  
			b.transdate transdate,     
			b.betteam,     
			b.spositiontaking,    
			b.mpositiontaking,     
			b.apositiontaking,    
			0 spositiontaking2,  
			0 mpositiontaking2,  
			0 apositiontaking2,    
			0 liveindicator,     
			b.modds,     
			b.custid,  
			b.livehomescore,  
			b.liveawayscore,  
			0, 0,    
			0 as leagueid,    
			0 as sporttype,   
			b.ip,  
			b.betfrom,  
			0 matchid,   
			CONVERT(BIT,0) as IsNeutral,  
			0 as allowdelete,  
			(b.winlost-b.actual_stake)  winlost,  
			b.playercomm as commission,  
			(b.scomm - b.acomm) as scomm,  
			(b.acomm - b.comm) as acomm,  
			(b.comm - b.playercomm) as comm,  
			b.awinlost,  
			b.mwinlost,  
			b.swinlost,  
			'' as showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc          
		FROM bettrans as b with (nolock)     
		WHERE    
			b.custid = @Custid    
			--and matchid=0    
			and matchid = 29  
			and bettype = 29    
			and b.refno = @refno   

		--- 'At' check if subtickets in bettrans14    
		INSERT INTO @Data  
		select   
			29 bettype,     
			CASE WHEN ISNULL(b.betid,0) = 0 THEN b.transid ELSE b.betID END as transid,  
			isnull(b.BetID,0) as BetID,  
			b.refno,  
			'' matchcode,    
			'' as race,  
			'' as eventdate,  
			0 as virtualrate,  
			0 as isShowOTExRate,  
			sdiscount,  
			adiscount,  
			discount,    
			0 as homeid,     
			0 as awayid,    
			'' settleTime,   
			b.hdp1,  
			b.hdp2,  
			b.odds,     
			0 finalodds,  
			0 finalodds2,  
			'' OddsType,    
			b.status,    
			CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,   
			b.stake,     
			b.actual_stake,  
			b.transdate transdate,     
			b.betteam,     
			b.spositiontaking,    
			b.mpositiontaking,     
			b.apositiontaking,    
			0 spositiontaking2,  
			0 mpositiontaking2,  
			0 apositiontaking2,    
			0 liveindicator,     
			b.modds,     
			b.custid,  
			b.livehomescore,  
			b.liveawayscore,  
			0, 0,    
			0 as leagueid,    
			0 as sporttype,   
			b.ip,  
			b.betfrom,  
			0 matchid,   
			CONVERT(BIT,0) as IsNeutral,  
			0 as allowdelete,  
			(b.winlost-b.actual_stake)  winlost,  
			b.playercomm as commission,  
			(b.scomm - b.acomm) as scomm,  
			(b.acomm - b.comm) as acomm,  
			(b.comm - b.playercomm) as comm,  
			b.awinlost,  
			b.mwinlost,  
			b.swinlost,  
			'' as showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc         
		from bettrans14 as b with (nolock)     
		where    
			b.custid = @Custid    
			--and matchid=0    
			and matchid = 29  
			and bettype = 29    
			and b.refno = @refno   

		--- '14' check if subtickets in bettrans_bk   
		INSERT INTO @Data  
		select   
			29 bettype,     
			CASE WHEN ISNULL(b.betid,0) = 0 THEN b.transid ELSE b.betID END AS transid,         
			isnull(b.BetID,0) as BetID,  
			b.refno,  
			'' matchcode,    
			'' as race,  
			'' as eventdate,  
			0 as virtualrate,  
			0 as isShowOTExRate,  
			sdiscount,  
			adiscount,  
			discount,    
			0 as homeid,     
			0 as awayid,    
			'' settleTime,   
			b.hdp1,  
			b.hdp2,  
			b.odds,     
			0 finalodds,  
			0 finalodds2,  
			'' OddsType,    
			b.status,   
			CASE WHEN b.comstatus = '1' THEN 1 ELSE 0 END as comstatus,    
			b.stake,   
			b.actual_stake,    
			b.transdate transdate,     
			b.betteam,     
			b.spositiontaking,    
			b.mpositiontaking,     
			b.apositiontaking,    
			0 spositiontaking2,  
			0 mpositiontaking2,  
			0 apositiontaking2,    
			0 liveindicator,     
			b.modds,     
			b.custid,  
			b.livehomescore,  
			b.liveawayscore,  
			0, 0,    
			0 as leagueid,    
			0 as sporttype,   
			b.ip,  
			b.betfrom,  
			0 matchid,   
			CONVERT(BIT,0) as IsNeutral,  
			0 as allowdelete,  
			(b.winlost-b.actual_stake)  winlost,  
			b.playercomm as commission,  
			(b.scomm - b.acomm) as scomm,  
			(b.acomm - b.comm) as acomm,  
			(b.comm - b.playercomm) as comm,  
			b.awinlost,  
			b.mwinlost,  
			b.swinlost,  
			'' as showtime,
			b.winlostdate,
			b.BetCheck,
			'' AS transdesc         
		FROM DBARC.bodb_archive.dbo.bettrans_bk b WITH(NOLOCK)  
		WHERE  b.custid = @Custid    
			--and matchid=0    
			and matchid = 29  
			and bettype = 29    
			and b.refno = @refno   
	END  
	
	DELETE @Data WHERE sporttype = 1 AND bettype = 903

	OutputResult:
	SELECT * 
	FROM @Data  
	ORDER BY transid    
	

	IF EXISTS (SELECT TOP 1 1 
			FROM @SportBettype sp 
				INNER JOIN @Data d
					ON d.bettype = sp.bettype 
			WHERE ProductID in (4,12)) 
	BEGIN
		IF @WinlostDate > @MoveBetsDay  
		BEGIN
			INSERT INTO @DetailData  
			SELECT   
				BG.refno,
				BG.odds,   
				BG.stake,  
				BG.status,  
				BG.apositiontaking,   
				BG.mpositiontaking,   
				BG.spositiontaking,  
				BG.bettype,  
				BG.betteam,
				BG.TransDesc     
			FROM dbo.bettransg BG with (NOLOCK)  
					INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4)
					INNER JOIN @Data B ON BG.CustID = B.CustID AND (sp.Productid in (4) AND BG.refno = B.refno AND BG.bettype = B.bettype)					
			UNION ALL
			SELECT   
				BG.refno,
				BG.odds,   
				BG.stake,  
				BG.status,  
				BG.apositiontaking,   
				BG.mpositiontaking,   
				BG.spositiontaking,  
				BG.bettype,  
				BG.betteam,
				BG.TransDesc     
			FROM dbo.bettransg BG with (NOLOCK)  
					INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (12)
					INNER JOIN @Data B ON BG.CustID = B.CustID AND (sp.Productid in (12) AND BG.refno = B.transid AND BG.bettype = B.bettype)	
		END
		ELSE IF @WinlostDate <= @MoveBetsDay and @WinlostDate >= @BalanceUpDay 
		BEGIN
			INSERT INTO @DetailData  
			SELECT   
				BG.refno,
				BG.odds,   
				BG.stake,  
				BG.status,  
				BG.apositiontaking,   
				BG.mpositiontaking,   
				BG.spositiontaking,  
				BG.bettype,  
				BG.betteam,
				BG.TransDesc     
			FROM dbo.bettransg14 BG with (NOLOCK)  
				INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4)
				INNER JOIN @Data B1 ON (BG.refno = B1.refno AND BG.bettype = B1.bettype AND sp.Productid in (4))
			UNION ALL 
			SELECT   
				BG.refno,
				BG.odds,   
				BG.stake,  
				BG.status,  
				BG.apositiontaking,   
				BG.mpositiontaking,   
				BG.spositiontaking,  
				BG.bettype,  
				BG.betteam,
				BG.TransDesc     
			FROM dbo.bettransg14 BG with (NOLOCK)  
				INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (12)
				INNER JOIN @Data B2 ON BG.refno = B2.transid AND BG.bettype = B2.bettype AND sp.Productid in (12)
		END
		ELSE
		BEGIN
			INSERT INTO @DetailData  
			SELECT   
				BG.refno,
				BG.odds,   
				BG.stake,  
				BG.status,  
				BG.apositiontaking,   
				BG.mpositiontaking,   
				BG.spositiontaking,  
				BG.bettype,  
				BG.betteam,
				BG.TransDesc     
			FROM DBARC.bodb_archive.dbo.bettransg BG with (NOLOCK)  
				INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (4)
				INNER JOIN @Data B1 ON BG.refno = B1.refno AND BG.bettype = B1.bettype AND sp.Productid in (4)
			UNION ALL 
			SELECT
				BG.refno,
				BG.odds,   
				BG.stake,  
				BG.status,  
				BG.apositiontaking,   
				BG.mpositiontaking,   
				BG.spositiontaking,  
				BG.bettype,  
				BG.betteam,
				BG.TransDesc     
			FROM DBARC.bodb_archive.dbo.bettransg BG with (NOLOCK)  
				INNER JOIN @SportBettype sp ON BG.bettype = sp.bettype AND sp.Productid in (12)
				INNER JOIN @Data B2 ON BG.refno = B2.transid AND BG.bettype = B2.bettype AND sp.Productid in (12)
		END
	END
	   
	SELECT * FROM @DetailData  
END
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_ByTransID] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_ByTransID] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetsSelBetList_ByTransID] TO [vnteam] 
