/*<info serverAlias="DBACC-bodb02" executers="Dot_Admin,Dot_Member" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[DOT_Dep_Rpt_MemberSummary_Agent]
	@fromDate smalldatetime,
	@toDate smalldatetime,
	@CustId INT,
	@agentid NVARCHAR(3500)
AS
/*
DB: DBACC.bodb02
Revisions: 
--20130723@Benson(DB06): Get Transfer_Opus data from rptDepWinlost_Transfer3rdOthers.
--20130806@Benson(DB06): fix Transfer3rd_Opus return null 
--20131107@BEnson(DB06): fix today Withdrawal Positive and negative exchange
--20140327@Benson(DB06): add HoGaming column
--20140819@Howard(DB06): Add AG Column
--20150327@Hugo(DB06)  : Add GD Report Data
--20150424@Angus(DB06)  : Add VB Report Data
--20150925@Angus(DB06)  : Add CRYSTAL Report Data
--20160721@Matthew(DB06) : Add LBKeno Report Data
--20170306@Matthew(DB06) :Add Opal Report Data
--20170605@Simon(DB06) :Add BetSoft(Amber) Report Data
--20170721@Benson(DB06): Turnover Data exclude cashout data
--20170814@ZiYang(DB06) :Add iSoftBet(Quartz) Report Data
--20171124@Angus(DB06) :Add CitiBet(Exchange) Report Data
--20180806@James(DB06) :Add Topaz(FG) Report Data
--20190313@James(DB06) :Add IMone Report Data
--20190319@Angus(DB06) :Add BTi Report Data
--20190716@James(DB06) :Add VRLottery Report Data
--20190916@Rong(DB06) :Add Sapphire Report Data
--20191218@Benson: Add select promotion column
--20191227@Benson: hotfix column of promotion not aligned
--20200107@Benson: new FG replace old FG, PartnerId 13->18 | bettype 22032,22033 -> 22042,22043
--20200317@Rong(DB06) :Add KYGaming Report Data
--20200630@James(DB06) :Add Moonstone Report Data
--20200813@Angus:Add Loyalty Program bet type in the promotion
*/
DECLARE @dbtodaydate SMALLDATETIME
SET @dbtodaydate = CONVERT(NVARCHAR(10),CURRENT_TIMESTAMP,120)

DECLARE @CutDate datetime
SELECT @CutDate =  min(winlostdate) from bodb_report.dbo.rptdepwinlost with(nolock) 

DECLARE @TodayData TABLE (
	custid int, currency int, OpeningBalance money default(0), Deposit money default(0), 
	Withdrawal money default(0), Bonus money default(0), Adjustment money default(0), Turnover money default(0), 
	DrawGame money default(0),	Outstanding money default(0),Winloss money default(0),Transfer3rd money default(0),
	ClosingBalance money default(0),Aff2MemTransfer money default(0),recommend int, mrecommend int, srecommend int, 
	actualrate float, Promotion money, Transfer3rd_Opus money, Transfer3rd_HoGaming money default(0), Transfer3rd_AG money default(0),
	Transfer3rd_GD money default(0), Transfer3rd_VB money default(0), Transfer3rd_CRYSTAL money default(0), Transfer3rd_LBKeno money default(0),
	Transfer3rd_Opal money default(0), Transfer3rd_BetSoft money default(0), Transfer3rd_iSoftBet money default(0), Transfer3rd_CitiBet money default(0),
	Transfer3rd_Topaz money default(0), Transfer3rd_IMone money default(0), Transfer3rd_BTi money default(0), Transfer3rd_VRLottery money default(0),
	Transfer3rd_Sapphire money default(0), Transfer3rd_KYGaming money default(0), Transfer3rd_Moonstone money default(0))

DECLARE @WinlostTmp TABLE (
	winlostdate datetime, custid int, currency int, OpeningBalance money default(0), Deposit money default(0), 
	Withdrawal money default(0), Bonus money default(0), Adjustment money default(0), Turnover money default(0), 
	DrawGame money default(0),	Outstanding money default(0),Winloss money default(0),Transfer3rd money default(0),
	ClosingBalance money default(0),Aff2MemTransfer money default(0), recommend int, mrecommend int, srecommend int, 
	actualrate float, Promotion money)

DECLARE @WinlostTmp_CastOutTurnover TABLE (
	custid int, Turnover money default(0), winlostdate datetime
)
--Get Transfer 3rd Winlost data
DECLARE @WinlostTransfer3rd TABLE(
	CustId int , winlostdate datetime, Transfer3rd_Opus money, Transfer3rd_HoGaming money, Transfer3rd_AG money,
	Transfer3rd_GD money, Transfer3rd_VB money, Transfer3rd_CRYSTAL money, Transfer3rd_LBKeno money, Transfer3rd_Opal money, Transfer3rd_BetSoft money,
	Transfer3rd_iSoftBet money, Transfer3rd_CitiBet money, Transfer3rd_Topaz money, Transfer3rd_IMone money, Transfer3rd_BTi money, Transfer3rd_VRLottery money,
	Transfer3rd_Sapphire money, Transfer3rd_KYGaming money, Transfer3rd_Moonstone money)

IF (@fromDate < @CutDate) OR (@toDate < @CutDate)
BEGIN
	INSERT INTO @WinlostTmp
	SELECT b.winlostdate, b.custid, b.currency, b.OpeningBalance, b.Deposit, b.Withdrawal, b.Bonus, b.Adjustment, b.Turnover, b.DrawGame, b.Outstanding, 
		   b.Winloss, b.Transfer3rd, b.ClosingBalance, b.Aff2MemTransfer, b.recommend, b.mrecommend, b.srecommend, b.actualrate, b.Promotion
	FROM bodb_Report.dbo.rptDepWinlost_bk b WITH(NOLOCK)
	WHERE  (winlostdate BETWEEN @fromDate AND @toDate)
		AND b.custid = @Custid AND b.recommend IN (SELECT val FROM strSplit(@agentid,',')) 

	INSERT INTO @WinlostTmp_CastOutTurnover
	SELECT custid, SUM(turnover), winlostdate
	FROM bodb_Report.dbo.rptDepWinlostByProduct_BK WITH(NOLOCK)
	WHERE (winlostdate BETWEEN @fromDate AND @toDate)
		AND custid = @Custid AND sporttype = -6
	GROUP BY winlostdate, custid

	INSERT INTO @WinlostTransfer3rd (CustId, winlostdate, Transfer3rd_Opus, Transfer3rd_HoGaming, Transfer3rd_AG, Transfer3rd_GD, Transfer3rd_VB,
	Transfer3rd_CRYSTAL, Transfer3rd_LBKeno, Transfer3rd_Opal, Transfer3rd_BetSoft, Transfer3rd_iSoftBet, Transfer3rd_CitiBet, Transfer3rd_Topaz,
	Transfer3rd_IMone, Transfer3rd_BTi, Transfer3rd_VRLottery, Transfer3rd_Sapphire, Transfer3rd_KYGaming, Transfer3rd_Moonstone)
	SELECT custid, winlostdate, SUM(CASE PartnerId WHEN 2 THEN TransferAmount ELSE 0 END), -- oops
								SUM(CASE PartnerId WHEN 1 THEN TransferAmount ELSE 0 END), --HoGaming
								SUM(CASE PartnerId WHEN 3 THEN TransferAmount ELSE 0 END), --AG
								SUM(CASE PartnerId WHEN 4 THEN TransferAmount ELSE 0 END), --GD
								SUM(CASE PartnerId WHEN 5 THEN TransferAmount ELSE 0 END), --VB
								SUM(CASE PartnerId WHEN 7 THEN TransferAmount ELSE 0 END), --CRYSTAL
								SUM(CASE PartnerId WHEN 8 THEN TransferAmount ELSE 0 END), --LBKeno
								SUM(CASE PartnerId WHEN 9 THEN TransferAmount ELSE 0 END), --Opal
								SUM(CASE PartnerId WHEN 10 THEN TransferAmount ELSE 0 END), --BetSoft(Amber)
								SUM(CASE PartnerId WHEN 11 THEN TransferAmount ELSE 0 END), --iSoftBet(Quartz)
								SUM(CASE PartnerId WHEN 12 THEN TransferAmount ELSE 0 END), --CitiBet(Exchange)
								SUM(CASE WHEN PartnerId IN (13,18) THEN TransferAmount ELSE 0 END), --Topaz(FG)
								SUM(CASE PartnerId WHEN 14 THEN TransferAmount ELSE 0 END), --IMone
								SUM(CASE PartnerId WHEN 15 THEN TransferAmount ELSE 0 END), --BTi
								SUM(CASE PartnerId WHEN 16 THEN TransferAmount ELSE 0 END), --VRLottery
								SUM(CASE PartnerId WHEN 17 THEN TransferAmount ELSE 0 END), --Sapphire
								SUM(CASE PartnerId WHEN 19 THEN TransferAmount ELSE 0 END), --KYGaming
								SUM(CASE PartnerId WHEN 20 THEN TransferAmount ELSE 0 END)  --Moonstone
	FROM bodb_Report.dbo.rptDepWinlost_Transfer3rdOthers_bk  WITH (NOLOCK) 
	WHERE  (winlostdate BETWEEN @fromDate AND @toDate)	
		AND custid = @Custid AND recommend IN (SELECT val FROM strSplit(@agentid,','))  
	GROUP BY winlostdate,CustId

END

IF (@fromDate >= @CutDate) OR (@toDate >= @CutDate)
BEGIN
	INSERT INTO @WinlostTmp
	SELECT b.winlostdate, b.custid, b.currency, b.OpeningBalance, b.Deposit, b.Withdrawal, b.Bonus, b.Adjustment, b.Turnover, b.DrawGame, b.Outstanding, 
		   b.Winloss, b.Transfer3rd, b.ClosingBalance, b.Aff2MemTransfer, b.recommend, b.mrecommend, b.srecommend, b.actualrate, b.Promotion
	FROM bodb_Report.dbo.rptDepWinlost b WITH(NOLOCK)
	WHERE  (winlostdate between @fromDate AND @toDate)
		AND winlostdate <> @dbtodaydate
		AND b.custid = @Custid	AND b.recommend IN (SELECT val FROM strSplit(@agentid,',')) 

	INSERT INTO @WinlostTmp_CastOutTurnover
	SELECT custid, SUM(turnover), winlostdate
	FROM bodb_Report.dbo.rptDepWinlostByProduct WITH(NOLOCK)
	WHERE (winlostdate between @fromDate AND @toDate)
		AND winlostdate <> @dbtodaydate
		AND custid = @Custid AND sporttype = -6
	GROUP BY winlostdate, custid

	INSERT INTO @WinlostTransfer3rd (CustId, winlostdate, Transfer3rd_Opus, Transfer3rd_HoGaming, Transfer3rd_AG, Transfer3rd_GD, Transfer3rd_VB,
	Transfer3rd_CRYSTAL, Transfer3rd_LBKeno, Transfer3rd_Opal, Transfer3rd_BetSoft, Transfer3rd_iSoftBet, Transfer3rd_CitiBet, Transfer3rd_Topaz,
	Transfer3rd_IMone, Transfer3rd_BTi, Transfer3rd_VRLottery, Transfer3rd_Sapphire, Transfer3rd_KYGaming, Transfer3rd_Moonstone)
	SELECT custid, winlostdate, SUM(CASE PartnerId WHEN 2 THEN TransferAmount ELSE 0 END) , -- oops
								SUM(CASE PartnerId WHEN 1 THEN TransferAmount ELSE 0 END) , --HoGaming
								SUM(CASE PartnerId WHEN 3 THEN TransferAmount ELSE 0 END) , --AG
								SUM(CASE PartnerId WHEN 4 THEN TransferAmount ELSE 0 END) ,  --GD
								SUM(CASE PartnerId WHEN 5 THEN TransferAmount ELSE 0 END),   --VB
								SUM(CASE PartnerId WHEN 7 THEN TransferAmount ELSE 0 END),  --CRYSTAL
								SUM(CASE PartnerId WHEN 8 THEN TransferAmount ELSE 0 END),  --LBKeno
								SUM(CASE PartnerId WHEN 9 THEN TransferAmount ELSE 0 END),  --Opal
								SUM(CASE PartnerId WHEN 10 THEN TransferAmount ELSE 0 END),  --BetSoft(Amber)
								SUM(CASE PartnerId WHEN 11 THEN TransferAmount ELSE 0 END),  --iSoftBet(Quartz)
								SUM(CASE PartnerId WHEN 12 THEN TransferAmount ELSE 0 END),  --CitiBet(Exchange)
								SUM(CASE WHEN PartnerId IN (13,18) THEN TransferAmount ELSE 0 END),  --Topaz(FG)
								SUM(CASE PartnerId WHEN 14 THEN TransferAmount ELSE 0 END),  --IMone
								SUM(CASE PartnerId WHEN 15 THEN TransferAmount ELSE 0 END),  --BTi
								SUM(CASE PartnerId WHEN 16 THEN TransferAmount ELSE 0 END),  --VRLottery
								SUM(CASE PartnerId WHEN 17 THEN TransferAmount ELSE 0 END),  --Sapphire
								SUM(CASE PartnerId WHEN 19 THEN TransferAmount ELSE 0 END),  --KYGaming
								SUM(CASE PartnerId WHEN 20 THEN TransferAmount ELSE 0 END)   --Moonstone
	FROM bodb_Report.dbo.rptDepWinlost_Transfer3rdOthers WITH (NOLOCK) 
	WHERE  (winlostdate BETWEEN @fromDate AND @toDate) AND winlostdate <> @dbtodaydate
		AND custid = @Custid AND recommend IN (SELECT val FROM strSplit(@agentid,','))  
	GROUP BY winlostdate,CustId
END

IF (@toDate >= @dbtodaydate)
BEGIN 
	DECLARE @TodayOpeningBalance MONEY
	SELECT @TodayOpeningBalance = d.ClosingBalance
	FROM bodb_report.dbo.rptdepwinlost d WITH(NOLOCK)
	WHERE d.custid = @CustId AND d.winlostdate = DATEADD(dd, -1, @dbtodaydate)
	
	INSERT INTO @TodayData (custid, currency, recommend, mrecommend, srecommend, OpeningBalance, Deposit, Aff2MemTransfer, Withdrawal, Bonus, Adjustment,
							Transfer3rd, Turnover, DrawGame, Outstanding, Winloss, Transfer3rd_Opus, Transfer3rd_HoGaming, Transfer3rd_AG, Transfer3rd_GD, Transfer3rd_VB, Transfer3rd_CRYSTAL, Transfer3rd_LBKeno, Transfer3rd_Opal,
							Transfer3rd_BetSoft, Transfer3rd_iSoftBet, Transfer3rd_CitiBet, Transfer3rd_Topaz, Transfer3rd_IMone, Transfer3rd_BTi, Transfer3rd_VRLottery, Transfer3rd_Sapphire, Transfer3rd_KYGaming, Transfer3rd_Moonstone, Promotion)
	SELECT b.custid, b.currency, b.recommend, b.mrecommend, b.srecommend,
		   @TodayOpeningBalance, -- OpeningBalance
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype = 22001 THEN winlost-actual_stake ELSE 0 END), -- Deposit
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype = 21006 THEN winlost-actual_stake ELSE 0 END), -- Aff2MemTransfer
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22002,22003) THEN winlost-actual_stake ELSE 0 END)*-1, -- Withdrawal
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype = 22004 THEN winlost-actual_stake ELSE 0 END), -- Bonus
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (21001,21002,21003,21004,21005,22005) THEN winlost-actual_stake ELSE 0 END), -- Adjustment
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22006,22007) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype < 19999 AND bettype <> 911 AND [status] NOT IN ('VOID', 'REJECT', 'Refund') THEN stake ELSE 0 END), -- Turnover
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype < 19999 AND [status] = 'DRAW' THEN stake ELSE 0 END), -- DrawGame
		   SUM(CASE WHEN bettype < 19999 AND ruben = 0 THEN actual_stake ELSE 0 END), -- Outstanding
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype < 19999 AND bettype NOT IN (17000,17003) AND ruben = 1 THEN winlost-actual_stake+playercomm ELSE 0 END), -- Winloss
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22010,22011) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd Opus
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22008,22009) THEN winlost-actual_stake ELSE 0 END),-- Transfer3rd HoGaming
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22014,22015) THEN winlost-actual_stake ELSE 0 END),-- Transfer3rd AG
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22016,22017) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd GD
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22018,22019) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd VB
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22020,22021) THEN winlost-actual_stake ELSE 0 END),-- Transfer3rd CRYSTAL
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22022,22023) THEN winlost-actual_stake ELSE 0 END),-- Transfer3rd LBKeno
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22024,22025) THEN winlost-actual_stake ELSE 0 END),-- Transfer3rd Opal
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22026,22027) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd BetSoft(Amber)
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22028,22029) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd iSoftBet(Quartz)
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22030,22031) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd CitiBet(Exchange)
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22032,22033,22042,22043) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd Topaz(FG)
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22034,22035) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd IMone
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22036,22037) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd BTi
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22038,22039) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd VRLottery
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22040,22041) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd Sapphire
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22044,22045) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd KYGaming
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (22046,22047) THEN winlost-actual_stake ELSE 0 END), -- Transfer3rd Moonstone
		   SUM(CASE WHEN winlostdate = @dbtodaydate AND bettype IN (17000,17003) THEN winlost-actual_stake ELSE 0 END)	-- Promotion, Royalty Program
	FROM bodb02.dbo.bettrans b WITH(NOLOCK)
	WHERE b.custid = @CustId AND b.recommend in (SELECT val FROM strSplit(@agentid,',')) 
	GROUP BY b.custid, b.currency, b.recommend, b.mrecommend, b.srecommend

	UPDATE d
	SET ClosingBalance = OpeningBalance + Deposit + Aff2MemTransfer - Withdrawal + Bonus + Adjustment - Outstanding + Winloss + Transfer3rd + Transfer3rd_Opus + Transfer3rd_HoGaming + Transfer3rd_AG + Transfer3rd_GD + Transfer3rd_VB + Transfer3rd_CRYSTAL + Transfer3rd_LBKeno + Transfer3rd_Opal + Transfer3rd_BetSoft + Transfer3rd_iSoftBet + Transfer3rd_CitiBet + Transfer3rd_Topaz + Transfer3rd_IMone + Transfer3rd_BTi + Transfer3rd_VRLottery + Transfer3rd_Sapphire + Promotion + Transfer3rd_KYGaming + Transfer3rd_Moonstone,
		actualrate = e.ActualRate
	FROM @TodayData d 
		INNER JOIN exchangedailyoanda e WITH(NOLOCK) ON d.currency = e.ExchangeId
END

    UPDATE @WinlostTmp 
    SET Turnover = (A.Turnover - B.Turnover)    
    FROM @WinlostTmp AS A INNER JOIN @WinlostTmp_CastOutTurnover AS B 
		ON A.Custid = B.Custid AND A.winlostdate = B.winlostdate

SELECT b.*, ISNULL(o.Transfer3rd_Opus,0) as Transfer3rd_Opus, ISNULL(o.Transfer3rd_HoGaming,0) AS Transfer3rd_HoGaming, ISNULL(o.Transfer3rd_AG,0) AS Transfer3rd_AG,
	   ISNULL(o.Transfer3rd_GD, 0) AS Transfer3rd_GD, ISNULL(o.Transfer3rd_VB, 0) AS Transfer3rd_VB, ISNULL(o.Transfer3rd_CRYSTAL, 0) AS Transfer3rd_CRYSTAL,
	   ISNULL(o.Transfer3rd_LBKeno, 0) AS Transfer3rd_LBKeno,ISNULL(o.Transfer3rd_Opal, 0) AS Transfer3rd_Opal, ISNULL(o.Transfer3rd_BetSoft, 0) AS Transfer3rd_BetSoft,
	   ISNULL(o.Transfer3rd_iSoftBet, 0) AS Transfer3rd_iSoftBet, ISNULL(o.Transfer3rd_CitiBet, 0) AS Transfer3rd_CitiBet, ISNULL(o.Transfer3rd_Topaz, 0) AS Transfer3rd_Topaz,
	   ISNULL(o.Transfer3rd_IMone, 0) AS Transfer3rd_IMone, ISNULL(o.Transfer3rd_BTi, 0) AS Transfer3rd_BTi, ISNULL(o.Transfer3rd_VRLottery, 0) AS Transfer3rd_VRLottery,
	   ISNULL(o.Transfer3rd_Sapphire, 0) AS Transfer3rd_Sapphire, ISNULL(o.Transfer3rd_KYGaming, 0) AS Transfer3rd_KYGaming, ISNULL(o.Transfer3rd_Moonstone, 0) AS Transfer3rd_Moonstone
FROM @WinlostTmp b
	LEFT JOIN @WinlostTransfer3rd o ON b.winlostdate = o.winlostdate
UNION
SELECT @dbtodaydate, d.* FROM @TodayData d
ORDER BY b.winlostdate
GO