ALTER PROCEDURE [dbo].[Acc_Rpt_WinLossDaily_ComEx14]
@winlostdate	DATETIME,
--@currency		INT = 43
@System varchar(50) = 'ACCTHAI'--ACCTHAI or ACCINDO
AS
/*
	Created by:Jamie
	Date: 2010-06-05
	Task: Daily WinLoss for Site by Currency
	DB: DBACC/BODB02
	Revisions:
		- 20101119@Henry: change parameter @Currency int to @GroupName varchar
		- 20110516@Lukas: re-arrange bettype
		- 20110822@Elly: - Correct Turnover of sports book since Sep 01, 2011
		- 20110913@Jamie: Refer to DB053 instead of DB052
		- 20120206@Sophia:	Get Stake for Turnover instead of actual_stake. 
							Remove @NegativeBetEffectiveDate
		- 20130121@Dan: call to DBAGE/bodb_AGE for Acc_CustGroup					

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @tmpSuperList TABLE( custID INT, username VARCHAR(30))

	/*
	INSERT INTO @tmpSuperList(CustID, username)
	SELECT	custID, username 
	FROM	custinfo WITH (NOLOCK)
	WHERE	currency = @currency 
			AND roleid = 4 
			AND dbo.f_isDummySuper(custID) = 0
	*/
	INSERT INTO @tmpSuperList(CustID, username)
	SELECT custID,username FROM custinfo (NOLOCK)
	WHERE 
	custid in (SELECT custid from DBAGE.bodb_AGE.dbo.Acc_CustGroup WITH(nolock) WHERE GroupName = @System)
	

	SELECT	b.SRecommend CustID,
			t.username,
			SUM(CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END) totalTO,
			SUM((CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END)*(1 - b.tpositiontaking)) ComTO,
			SUM((CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END)*b.spositiontaking) SAgTO,
			SUM((CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END)*b.mpositiontaking) MAgTO,
			SUM((CASE WHEN b.liveawayscore = 0 AND b.bettype IN (33,43) THEN ABS(b.stake)/2 ELSE ABS(b.stake) END)*b.apositiontaking) AgTO,
			
			-SUM(b.winlost - b.actual_stake + b.awinlost + b.mwinlost + b.swinlost + b.scomm) ComWinlost,
			SUM(b.swinlost + b.scomm - b.acomm) SAgWinlost,
			SUM(b.mwinlost + b.acomm - b.comm) MAgWinlost,
			SUM(b.awinlost + b.comm - b.playercomm) AgWinlost

	FROM	Bettrans14 b WITH (NOLOCK)
			INNER JOIN @tmpSuperList t ON b.srecommend = t.custID 
	WHERE	b.winlostdate = @winlostdate
			AND b.ruben = 1
			AND b.bettype < 19999
			AND b.statusID NOT IN (101,102,103,121)
	GROUP BY b.SRecommend, t.username 
	ORDER BY t.username
	
END

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinLossDaily_ComEx14] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinLossDaily_ComEx14] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_WinLossDaily_ComEx14] TO [vnteam]