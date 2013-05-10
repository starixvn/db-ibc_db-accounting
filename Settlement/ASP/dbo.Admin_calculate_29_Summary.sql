
ALTER PROCEDURE [dbo].[Admin_Calculate_29_Summary]
AS
/*
	created:
	Task:
	DB: DBTrans.bodb02
	
	Revisions:
		- 20120327@Joe: Set agency ID = 0 when delete sub ticket 
		- 20121213@Lukas: review new Joe's method once settled for system parlay
*/
BEGIN
	DECLARE @ExistRecord TABLE (
		transid bigint PRIMARY KEY CLUSTERED,
		refno bigint, betid bigint,
		winlostdate smalldatetime,
		Used bit DEFAULT 0,
		Moved bit DEFAULT 0
		)

	INSERT INTO @ExistRecord (transid, refno, betid, winlostdate)
	SELECT b.transid, b.refno, b.betid, b.winlostdate
	FROM dbo.bettrans b with (nolock)
	WHERE 
		b.matchid = 29
		AND b.refno IN (SELECT refno FROM dbo.BetParlayResultSummary with (nolock))

	INSERT INTO @ExistRecord (transid, refno, betid, winlostdate, Moved)
	SELECT b.transid, b.refno, b.betid, b.winlostdate, 1
	FROM dbo.bettrans14 b with (nolock)
	WHERE 
		b.matchid = 29
		AND b.refno IN (SELECT refno FROM dbo.BetParlayResultSummary with (nolock))


	Declare @statusID tinyint

--- part for new method / update once - no sub
	Declare @OneRecord TABLE (refno bigint PRIMARY KEY, transid bigint)
	INSERT INTO @OneRecord (refno, transid)
	SELECT refno, MIN(transid)
	FROM @ExistRecord er
	GROUP BY refno
	HAVING COUNT(*) = 1
	
	;WITH PRS AS (
		SELECT
			O.transid, O.refno, MAX(winlostdate) winlostdate, SUM(stake) totalStake,
			SUM(odds) odds, SUM(modds) modds, SUM(CASE statusID WHEN 0 THEN stake ELSE 0 END) RunningStake, COUNT(*) TicketCount,
			SUM(winlost) winlost, SUM(awinlost) awinlost, SUM(mwinlost) mwinlost, SUM(swinlost) swinlost,
			SUM(playercomm) playercomm, SUM(comm) comm, SUM(acomm) acomm, SUM(scomm) scomm
		FROM  
			dbo.BetParlayResult pr WITH(NOLOCK)
			INNER JOIN @OneRecord O ON pr.refno = O.refno
		GROUP BY
			O.transid, O.refno
	)	

	UPDATE B
	SET 
		winlostdate = prs.winlostdate,
		modds = prs.modds,
		actual_stake = prs.totalStake,
		betdaqid = prs.totalStake,
		@statusID = statusID = CASE
			WHEN prs.runningStake > 0 THEN 0
			WHEN prs.winlost = prs.totalStake THEN 111
			WHEN prs.winlost > prs.totalStake THEN 112
			WHEN prs.winlost < prs.totalStake THEN 113
			END,
		[status] = CASE @statusID
			WHEN 0 THEN 'running'
			WHEN 111 THEN 'DRAW'
			WHEN 112 THEN 'WON'
			WHEN 113 THEN 'LOSE'
			END,
		ruben    = CASE @statusID WHEN 0 THEN 0 ELSE 1 END,
		winlost  = CASE @statusID WHEN 0 THEN 0 ELSE prs.winlost END,
		awinlost = CASE @statusID WHEN 0 THEN 0 ELSE prs.awinlost END,
		mwinlost = CASE @statusID WHEN 0 THEN 0 ELSE prs.mwinlost END,
		swinlost = CASE @statusID WHEN 0 THEN 0 ELSE prs.swinlost END,
		playercomm = CASE @statusID WHEN 0 THEN 0 ELSE prs.playercomm END,
		comm     = CASE @statusID WHEN 0 THEN 0 ELSE prs.comm END,
		acomm    = CASE @statusID WHEN 0 THEN 0 ELSE prs.acomm END,
		scomm    = CASE @statusID WHEN 0 THEN 0 ELSE prs.scomm END
	FROM dbo.bettrans B with (rowlock)
		INNER JOIN PRS with (nolock) ON B.transid = PRS.transid
	WHERE
		   (prs.runningStake > 0 AND B.statusID > 0) -- set back to running
		OR (prs.runningStake = 0 AND B.statusID = 0) -- setting it
		OR -- update result
		(
		(prs.runningStake = 0 AND B.statusID > 0) AND
			(  B.winlostdate <> prs.winlostdate
			OR B.winlost <> prs.winlost OR B.awinlost <> prs.awinlost OR B.mwinlost <> prs.mwinlost OR B.swinlost <> prs.swinlost
			OR B.playercomm <> prs.playercomm OR B.comm <> prs.comm OR B.acomm <> prs.acomm OR B.scomm <> prs.scomm
			)
		)

	DELETE FROM @ExistRecord
	WHERE refno IN (SELECT refno FROM @OneRecord)


--- END : part for new method / update once - no sub


	Declare @FinishList TABLE (refno bigint PRIMARY KEY CLUSTERED, FinishDate smalldatetime, runningStake money)
	INSERT INTO @FinishList
	SELECT refno, MAX(winlostdate), SUM(runningStake)
	FROM dbo.BetParlayResultSummary with (rowlock)
	GROUP BY refno
	--HAVING SUM(runningStake) = 0

	-- sub record which already exists in bettrans
	-- but doesn't required anymore (not exists in BetParlayResultSummary)
	-- will mark for delete (update custid to zero)
	INSERT INTO dbo.BetParlayResultSummary (refno, transid, winlostdate, [action])
	SELECT refno, transid, winlostdate, 'D'
	FROM @ExistRecord ER
	WHERE NOT EXISTS (SELECT 1 FROM dbo.BetParlayResultSummary PRS WHERE PRS.refno = ER.refno AND PRS.winlostdate = ER.winlostdate)
	AND ER.BetID > 0

	-- if main ticket winlostdate <> FinishDate of combination
	-- we will put main ticket on to FinishDate
	-- so, existing record of that date need to delete
	;WITH CTE as (
		SELECT er.refno, er.transid, fl.FinishDate as winlostdate
		FROM @ExistRecord er
			INNER JOIN @FinishList fl ON er.refno = fl.refno AND er.betid = 0
		--WHERE er.winlostdate < fl.FinishDate
	) INSERT INTO dbo.BetParlayResultSummary (refno, transid, winlostdate, [action])
	--SELECT CTE.*, 'D',
	SELECT ER.refno, ER.transid, ER.winlostdate, 'D'
	FROM CTE INNER JOIN @ExistRecord ER ON CTE.refno = ER.refno AND CTE.winlostdate = ER.winlostdate
	WHERE BetID > 0
/*	;WITH CTE as (
		SELECT er.refno, er.transid, er.winlostdate
		FROM @ExistRecord er
			INNER JOIN @FinishList fl ON er.refno = fl.refno AND er.betid = 0
		WHERE er.winlostdate <> fl.FinishDate
	) INSERT INTO dbo.BetParlayResultSummary (refno, transid, winlostdate, [action])
	SELECT CTE.*, 'D'
	FROM CTE INNER JOIN @ExistRecord ER ON CTE.refno = ER.refno AND CTE.winlostdate = ER.winlostdate
	WHERE BetID > 0	*/


	-- update transid of main ticket into Summary
	UPDATE PRS
	SET transid = ER.transid,
		[action] = 'U'
	FROM dbo.BetParlayResultSummary PRS with (rowlock)
		INNER JOIN @FinishList FL ON PRS.refno = FL.refno AND PRS.winlostdate = FL.finishdate AND FL.runningStake = 0
		INNER JOIN @ExistRecord ER ON PRS.refno = ER.refno AND ER.betid = 0 AND PRS.transid IS NULL

	UPDATE PRS
	SET transid = ER.transid,
		[action] = 'U'
	FROM dbo.BetParlayResultSummary PRS with (rowlock)
		INNER JOIN @ExistRecord ER ON PRS.refno = ER.refno AND ER.betid = 0
	WHERE
		PRS.runningStake > 0

	-- remove record which already update transid into Summary
	UPDATE ER
	SET Used = 1
	FROM @ExistRecord ER
	WHERE transid IN (SELECT transid FROM dbo.BetParlayResultSummary)

	-- leftover ticket in ExistRecord, is record can be update
	UPDATE PRS
	SET transid = ER.transid,
		[action] = 'U'
	FROM dbo.BetParlayResultSummary PRS with (rowlock)
		INNER JOIN @ExistRecord ER ON PRS.refno = ER.refno AND PRS.winlostdate = ER.winlostdate
	WHERE
		ER.Used = 0


	---
	--- now, we can perform insert/update/delete accordingly on [Action]
	---
	BEGIN TRANSACTION

	UPDATE B
	SET custid = 0,
		actual_stake = 0,
		winlost = 0, awinlost = 0, mwinlost = 0, swinlost = 0,
		playercomm = 0, comm = 0, acomm = 0, scomm = 0
	FROM dbo.bettrans B with (rowlock)
		INNER JOIN dbo.BetParlayResultSummary PRS with (rowlock) ON B.transid = PRS.transid
	WHERE
		[action] = 'D'

	UPDATE B
	SET custid = prs.custid,
		actual_stake = prs.stake,
		betdaqid = prs.totalStake,
		winlost = prs.winlost, awinlost = prs.awinlost,  mwinlost = prs.mwinlost, swinlost = prs.swinlost,
		playercomm = prs.playercomm, comm = prs.comm, acomm = prs.acomm, scomm = prs.scomm,
		modds = prs.modds,
		winlostdate = prs.winlostdate,
		@statusID = statusID = CASE
			WHEN prs.runningStake > 0 THEN 0
			WHEN prs.winlost = prs.stake THEN 111
			WHEN prs.winlost > prs.stake THEN 112
			WHEN prs.winlost < prs.stake THEN 113
			END,
		[status] = CASE @statusID
			WHEN 0 THEN 'running'
			WHEN 111 THEN 'DRAW'
			WHEN 112 THEN 'WON'
			WHEN 113 THEN 'LOSE'
			END,
		ruben = CASE @statusID WHEN 0 THEN 0 ELSE 1 END
	FROM dbo.bettrans B with (rowlock)
		INNER JOIN dbo.BetParlayResultSummary PRS with (rowlock) ON B.transid = PRS.transid
	WHERE
		[action] = 'U'
		AND 
		(
			B.winlostdate <> prs.winlostdate OR B.actual_stake <> prs.stake 
			OR B.winlost <> prs.winlost OR B.awinlost <> prs.awinlost OR B.mwinlost <> prs.mwinlost OR B.swinlost <> prs.swinlost
			OR B.playercomm <> prs.playercomm OR B.comm <> prs.comm OR B.acomm <> prs.acomm OR B.scomm <> prs.scomm
			OR
			B.BetID = 0
		)


	-- insert new record of sub-ticket into bettrans
	;WITH MainTicket AS (
	SELECT * FROM dbo.bettrans with (nolock)
	WHERE transid IN (SELECT transid FROM @ExistRecord WHERE betid = 0)
	)
	INSERT INTO dbo.bettrans (
		custid, transdate, matchid, bettype, refno, betid, winlostdate,
		odds, modds, stake, actual_stake, betdaqid,
		[status], statusID, ruben,
		winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
		apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount,
		oddsid, hdp1, hdp2, livehomescore, liveawayscore, liveindicator, betteam, creator, comstatus, betfrom, betcheck,
		recommend, mrecommend, srecommend, IP, transdesc, Username,
		actualrate, virtualrate, currency, currency2, CurrencyName, oddstype
	)
	SELECT
		b.custid, CURRENT_TIMESTAMP, 29, 29, PRS.refno, B.transid, PRS.winlostdate,
		PRS.odds, PRS.modds, 0, PRS.stake, PRS.totalStake,
		[status] = CASE WHEN prs.winlost = prs.stake THEN 'DRAW' WHEN prs.winlost > prs.stake THEN 'WON' WHEN prs.winlost < prs.stake THEN 'LOSE' END,
		statusID = CASE WHEN prs.winlost = prs.stake THEN 111 WHEN prs.winlost > prs.stake THEN 112 WHEN prs.winlost < prs.stake THEN 113 END,
		1,
		PRS.winlost, PRS.awinlost, PRS.mwinlost, PRS.swinlost, PRS.playercomm, PRS.comm, PRS.acomm, PRS.scomm,
		b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, b.playerdiscount, b.discount, b.adiscount, b.sdiscount,
		0,0,0,   0,0,0,   b.betteam, b.creator, b.comstatus, b.betfrom, '', b.recommend, b.mrecommend, b.srecommend, b.IP, '', b.UserName,
		b.actualrate, b.virtualrate, b.currency, b.currency2, b.CurrencyName, b.oddstype
	FROM dbo.BetParlayResultSummary PRS with (rowlock)
		INNER JOIN MainTicket B ON PRS.refno = B.refno
	WHERE
		[action] = 'I'

	COMMIT TRANSACTION


	DELETE FROM dbo.BetParlayResultSummary

END

/* Joe : Self-Note
when ticket start to have result
possible case
1. have winlostdate same as main ticket's winlostdate (most likely mean, single date parlay)
2. have winlostdate less than main ticket's winlostdate

for 1. action to perform is update
for 2. action to perform is UPSERT

after consequence settle which case combination to finished
possible case
1. have winlostdate same as main ticket's winlostdate
2. have winlostdate less than main ticket's winlostdate

for 1. action to perform is update
for 2. action to perform is set existing ticket's custid to 0, before update
*/

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_29_Summary] TO [vnteam]


