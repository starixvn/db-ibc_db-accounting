ALTER PROCEDURE [dbo].[Acc_Rpt_WinLossDetail_ComEx] 
	--@currency int = 43,--Thai Currency
	@System varchar(50) = 'ACCTHAI',--ACCTHAI or ACCINDO
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@showSB bit=1,
	@showCasino bit=0,
	@showP2P bit=0,
	@showRB bit=0,
	@showFI bit=0, --unused
	@showNG BIT=0,
	@showBI BIT=0,
	@showVS BIT=0,
	@showLiveCasino BIT = 0,
	@BalanceUpDay SMALLDATETIME	
AS

/*
Created by: Jamie
Date: 2010-06-01
Task : Super Winloss Detail
DB: DBAGE/bodb02
Revisions:
	- 20100925@Henry: Add Bingo and Number Game
	- 20101119@Henry: change parameter @Currency int to @GroupName varchar
	- 20110315@Johnson: change parameter @showHR to @showRB
	- 20110516@Lukas: re-arrange bettype
	- 20110811@Johnson: add more bettype for number game
	- 20110823@Elly: - Correct Turnover of sports book since Sep 01, 2011
	- 20111202@Sophia:  . Change the range of sportsbook 
						. Change the range of P2P
						. Remove @NegativeBetEffectiveDate
	- 20120202@Sophia: Add Live Casino 
  	- 20120608@Elodie: Change the gross commission for P2P
  	- 20120814@Elodie: Add Virtual Sports report
  					   Remove finance product
  	- 20120814@Elodie: Add Sporting Solution Product (bettype: 1301 -> 1334)
  	- 20130121@Dan: add linked server DBSUM for bodb_Summary, call to DBAGE/bodb_AGE for Acc_CustGroup
*/

SET NOCOUNT ON

--DECLARE #tmpSuperList TABLE( custID INT)
CREATE TABLE #tmpSuperList (custid INT)
/*
INSERT INTO #tmpSuperList(CustID)
SELECT	custID 
FROM	custinfo WITH (NOLOCK)
WHERE	currency = @currency 
		AND roleid = 4 
		AND dbo.f_isDummySuper(custID) = 0
*/

INSERT INTO #tmpSuperList(CustID)
SELECT custID 
FROM bodb_AGE.dbo.Acc_CustGroup WITH (NOLOCK)
WHERE GroupName = @System

DECLARE @ComWinLossDetails TABLE(CustID int, Turnover money, GrossComm money, MemberWinLost money, 
	PlayerComm money, MemberTotal money, AgWinLost money, AgComm money, AgTotal money, 
	MAgWinLost money, MAgComm money, MAgTotal money, SAgWinLost money, SAgComm money, SAgTotal money, Company money)

DECLARE @TmpCond TABLE(sporttype INT, bettype INT)
DECLARE @TmpCondSumWL TABLE(sporttype INT, bettype INT)
IF @ShowSB = 1
BEGIN
	--Bettrans
	INSERT INTO @TmpCond(Sporttype, Bettype)
	SELECT 0 AS sporttype, typeid FROM bettype (NOLOCK)
	WHERE	typeid < 31 OR typeid BETWEEN 120 AND 999 or typeid between 1301 and 1334
	--Sum_winloss
	INSERT INTO @TmpCondSumWL(sporttype, Bettype)
	VALUES(0,0)	
END
IF @ShowCasino = 1
BEGIN
	INSERT INTO @TmpCond(sporttype, Bettype)
	VALUES(251,71)
	--Sum_winloss
	INSERT INTO @TmpCondSumWL(sporttype, Bettype)
	VALUES(251,71)
END
IF @ShowP2P = 1
BEGIN
	INSERT INTO @TmpCond(sporttype, Bettype)
	VALUES(253,1000)
	--Sum_winloss
	INSERT INTO @TmpCondSumWL(sporttype, Bettype)
	VALUES(253,1000)
END
--RaceBook
IF @ShowRB = 1
BEGIN
	--Bettrans
	INSERT INTO @TmpCond(Sporttype, Bettype)
		SELECT 151 AS sporttype, typeid FROM bettype (NOLOCK)
		WHERE typeid IN (31,32,33,41,42,43)
	
	--Sum_winloss
	INSERT INTO @TmpCondSumWL(Sporttype, Bettype)
		SELECT 151, 0	
	
END
--IF @ShowFI = 1
--BEGIN	
--	--Bettrans
--	INSERT INTO @TmpCond(Sporttype, Bettype)
--	SELECT 201 AS sporttype, typeid FROM bettype (NOLOCK)
--	WHERE typeid IN (51,52,53,54,55,56,61,62,63,64,65,66)
--	--Sum_winloss
--	INSERT INTO @TmpCondSumWL(Sporttype, Bettype)
--	VALUES(201,0)
--END

IF @ShowNG = 1
BEGIN
	--Bettrans
	INSERT INTO @TmpCond(Sporttype, Bettype)
	SELECT 161 AS sporttype, typeid FROM bettype (NOLOCK)
	WHERE typeid BETWEEN 81 AND 120

	--Sum_winloss
	INSERT INTO @TmpCondSumWL(Sporttype, Bettype)
	VALUES(161,0)
END
IF @ShowBI = 1
BEGIN
	INSERT INTO @TmpCond(sporttype, Bettype)
	VALUES(252,73)

	--Sum_winloss
	INSERT INTO @TmpCondSumWL(Sporttype, Bettype)
	VALUES(252,73)
END	

IF @showLiveCasino = 1
BEGIN
	--Bettrans
	INSERT INTO @TmpCond(Sporttype, Bettype)
	SELECT 162 AS sporttype, typeid FROM bettype (NOLOCK)
	WHERE typeid BETWEEN 1101 AND 1199

	--Sum_winloss
	INSERT INTO @TmpCondSumWL(Sporttype, Bettype)
	VALUES(162,0)
END
	
IF @showVS = 1
BEGIN
	--Bettrans
	INSERT INTO @TmpCond(Sporttype, Bettype)
	SELECT 180 AS sporttype, typeid FROM bettype (NOLOCK)
	WHERE typeid BETWEEN 1201 AND 1299

	--Sum_winloss
	INSERT INTO @TmpCondSumWL(Sporttype, Bettype)
	VALUES(180,0)
END

IF @Todate >= @BalanceUpDay
BEGIN 
    INSERT INTO @ComWinLossDetails
	    SELECT
		    SRecommend,			
			SUM(case when b.liveawayscore = 0 and b.bettype in(33,43) then b.stake/2 else ABS(b.stake) end),	
		    sum(case when b.bettype = 1000 THEN oddsspread else scomm/(1-tpositiontaking) end) as GrossComm,		    
		    sum(winlost-actual_stake), --MemberWinlost
		    sum(playercomm), -- PlayerComm
		    isnull(sum(winlost-actual_stake), 0) + isnull(sum(playercomm), 0), --MemberTotal
		    sum(awinlost), -- AgWinlost
		    isnull(sum(comm-playercomm),0), --AgComm
		    isnull(sum(awinlost+comm-playercomm), 0), --AgTotal			
		    sum(mwinlost), -- MAgWinlost
		    sum(acomm)-sum(comm), --MAgComm
		    isnull(sum(mwinlost), 0) + isnull(sum(acomm), 0)-sum(comm), --MAgTotal
		    sum(swinlost), -- SAgWinlost
		    isnull(sum(scomm),0) -isnull(sum(acomm),0), --SAgComm
		    isnull(sum(swinlost), 0) + isnull(sum(scomm), 0)-sum(acomm), --SAgTotal
		    -(isnull(sum(swinlost), 0) + isnull(sum(awinlost), 0) + isnull(sum(mwinlost), 0) + isnull(sum(scomm), 0) + isnull(sum(winlost-actual_stake), 0)) --Company				
	    FROM
			(SELECT SRecommend, b.liveawayscore, b.bettype ,b.stake,
					0 as oddsspread, tpositiontaking, winlost,actual_stake,
					playercomm, awinlost, comm, mwinlost, acomm, swinlost, scomm	
			 FROM dbo.bettrans b WITH (NOLOCK) INNER JOIN @TmpCond t ON b.bettype = t.bettype
			 WHERE  b.winlostdate between @FromDate and @todate and
					b.srecommend in (SELECT custID FROM #tmpSuperList) and
					b.ruben = 1 and
					b.statusID not in (101, 102, 103)   
					AND t.bettype <> 1000
			 UNION ALL
			 SELECT SRecommend, b.liveawayscore, b.bettype, b.stake,
					oddsspread, tpositiontaking, winlost,actual_stake,
					playercomm, awinlost, comm, mwinlost, acomm, swinlost, scomm	
			 FROM dbo.bettrans b WITH (NOLOCK) INNER JOIN @TmpCond t ON b.bettype = t.bettype
			 WHERE  b.winlostdate between @FromDate and @todate and
					b.srecommend in (SELECT custID FROM #tmpSuperList) and
					b.ruben = 1 and
					b.statusID not in (101, 102, 103)   
					AND t.bettype = 1000 AND matchid = 1000
			) b
	    GROUP BY SRecommend, b.bettype
		
	if @BalanceUpDay < @FromDate
	    select @BalanceUpDay=@FromDate
		
    INSERT INTO @ComWinLossDetails
	    SELECT
		    CustID,			
		    sum(TurnOver), -- TurnOver
		    sum(grosscomm) as GrossComm,
		    sum(winlost), --MemberWinlost
		    sum(playercomm), -- PlayerComm
		    isnull(sum(winlost), 0) + isnull(sum(playercomm), 0), --MemberTotal
		    sum(awinlost), -- AgWinlost
		    isnull(sum(comm-playercomm),0), --AgComm
		    isnull(sum(awinlost+comm-playercomm), 0), --AgTotal		
		    sum(mwinlost), -- MAgWinlost
		    sum(acomm)-sum(comm), --MAgComm
		    isnull(sum(mwinlost), 0) + isnull(sum(acomm), 0)-sum(comm), --MAgTotal
		    sum(swinlost), -- SAgWinlost
		    isnull(sum(scomm),0) -isnull(sum(acomm),0), --SAgComm
		    isnull(sum(swinlost), 0) + isnull(sum(scomm), 0)-sum(acomm), --SAgTotal
		    -(isnull(sum(swinlost), 0) + isnull(sum(awinlost), 0) + isnull(sum(mwinlost), 0) + isnull(sum(scomm), 0) + isnull(sum(winlost), 0)) --Company					
	    FROM
		    dbo.sum_winloss b WITH (NOLOCK) INNER JOIN @TmpCondSumWL t ON b.sporttype = t.sporttype AND b.bettype = t.bettype
	    WHERE
		    winlostdate between @BalanceUpDay and @todate			
		    and SRecommend IN (SELECT custID FROM #tmpSuperList)
		    and RoleID = 4
	    GROUP BY CustID
END

IF @FromDate < @BalanceUpDay 
BEGIN
	if @ToDate >= DATEADD(dd, -1, @BalanceUpDay)
		select @ToDate = DATEADD(dd, -1, @BalanceUpDay)
	
    INSERT INTO @ComWinLossDetails
	    SELECT
		    CustID,			
		    sum(TurnOver), -- TurnOver
		    sum(grosscomm) as GrossComm,
		    sum(winlost), --MemberWinlost
		    sum(playercomm), -- PlayerComm
		    isnull(sum(winlost), 0) + isnull(sum(playercomm), 0), --MemberTotal
		    sum(awinlost), -- AgWinlost
		    isnull(sum(comm-playercomm),0), --AgComm
		    isnull(sum(awinlost+comm-playercomm), 0), --AgTotal		
		    sum(mwinlost), -- MAgWinlost
		    sum(acomm)-sum(comm), --MAgComm
		    isnull(sum(mwinlost), 0) + isnull(sum(acomm), 0)-sum(comm), --MAgTotal
		    sum(swinlost), -- SAgWinlost
		    isnull(sum(scomm),0) -isnull(sum(acomm),0), --SAgComm
		    isnull(sum(swinlost), 0) + isnull(sum(scomm), 0)-sum(acomm), --SAgTotal
		    -(isnull(sum(swinlost), 0) + isnull(sum(awinlost), 0) + isnull(sum(mwinlost), 0) + isnull(sum(scomm), 0) + isnull(sum(winlost), 0)) --Company								
	    FROM
		    DBSUM.bodb_Summary.dbo.Sum_WinLoss_Old b WITH(NOLOCK) INNER JOIN @TmpCondSumWL t ON b.sporttype = t.sporttype AND b.bettype = t.bettype
	    WHERE
		    winlostdate between @fromdate and @ToDate			
		    and SRecommend IN (SELECT custID FROM #tmpSuperList)
		    and RoleID = 4
	    GROUP BY CustID

END	

SELECT
	w.CustID, 
	c.UserName, 
	sum(TurnOver) as Turnover,
	sum(GrossComm) as GrossComm,
	sum(MemberWinLost) as MemberWinlost,
	sum(PlayerComm) as PlayerComm,
	sum(MemberTotal) as MemberTotal,
	sum(AgWinlost) as AgWinlost,
	sum(AgComm) as AgComm,
	sum(AgTotal) as AgTotal,
	sum(MAgWinlost) as MAgWinlost,
	sum(MAgComm) as MAgComm,
	sum(MAgTotal) as MAgTotal,
	sum(SAgWinlost) as SAgWinlost,
	sum(SAgComm) as SAgComm,
	sum(SAgTotal) as SAgTotal,
	sum(Company) as Company	
FROM @ComWinLossDetails w INNER JOIN custinfo c WITH(NOLOCK) ON w.CustID = c.CustID 
Group by w.CustID, c.UserName
order by c.Username

DROP TABLE #tmpSuperList



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinLossDetail_ComEx] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinLossDetail_ComEx] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_WinLossDetail_ComEx] TO vnteam

