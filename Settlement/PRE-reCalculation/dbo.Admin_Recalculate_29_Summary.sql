 
 
ALTER PROCEDURE [dbo].[Admin_Recalculate_29_Summary]
AS
/*
	Created: 20111116@Lukas
	Task : 
	DB: DB052.BODB_REVIEW
	Original: 
	Revisions:	 
	Param's Explanation:
*/
BEGIN
	DECLARE @ExistRecord TABLE (
		transid bigint PRIMARY KEY CLUSTERED,
		refno bigint, betid bigint,
		winlostdate smalldatetime,
		Used bit DEFAULT 0
		)

	INSERT INTO @ExistRecord (transid, refno, betid, winlostdate)
	SELECT b.transid, b.refno, b.betid, b.winlostdate
	FROM dbo.bettrans b with (nolock)
	WHERE 
		b.matchid = 29
		AND b.refno IN (SELECT refno FROM dbo.BetParlayResultSummary with (nolock))

	Declare @FinishList TABLE (refno bigint PRIMARY KEY CLUSTERED, FinishDate smalldatetime)
	INSERT INTO @FinishList
	SELECT refno, MAX(winlostdate)
	FROM dbo.BetParlayResultSummary with (rowlock)
	GROUP BY refno
	HAVING SUM(runningStake) = 0

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
		SELECT er.refno, er.transid, er.winlostdate
		FROM @ExistRecord er
			INNER JOIN @FinishList fl ON er.refno = fl.refno AND er.betid = 0
		WHERE er.winlostdate <> fl.FinishDate
	) INSERT INTO dbo.BetParlayResultSummary (refno, transid, winlostdate, [action])
	SELECT CTE.*, 'D'
	FROM CTE INNER JOIN @ExistRecord ER ON CTE.refno = ER.refno AND CTE.winlostdate = ER.winlostdate
	WHERE BetID > 0


	-- update transid of main ticket into Summary
	UPDATE PRS
	SET transid = ER.transid,
		[action] = 'U'
	FROM dbo.BetParlayResultSummary PRS with (rowlock)
		INNER JOIN @FinishList FL ON PRS.refno = FL.refno AND PRS.winlostdate = FL.finishdate
		INNER JOIN @ExistRecord ER ON PRS.refno = ER.refno AND ER.betid = 0

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
	Declare @statusID tinyint
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
		winlost = prs.winlost, awinlost = prs.awinlost,  mwinlost = prs.mwinlost, swinlost = prs.swinlost,
		playercomm = prs.playercomm, comm = prs.comm, acomm = prs.acomm, scomm = prs.scomm,

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
			B.winlostdate <> prs.winlostdate OR B.actual_stake <> prs.stake OR B.winlost <> prs.winlost
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
		odds, modds, stake, actual_stake, [status], statusID, ruben,
		winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
		apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount,
		oddsid, hdp1, hdp2, livehomescore, liveawayscore, liveindicator, betteam, creator, comstatus, betfrom, betcheck,
		recommend, mrecommend, srecommend, IP, transdesc, Username,
		actualrate, virtualrate, currency, currency2, CurrencyName, oddstype
	)
	SELECT
		b.custid, CURRENT_TIMESTAMP, 29, 29, PRS.refno, B.transid, PRS.winlostdate,
		PRS.odds, PRS.modds, 0, PRS.stake,
		[status] = CASE WHEN prs.winlost = prs.stake THEN 'DRAW' WHEN prs.winlost > prs.stake THEN 'WON' WHEN prs.winlost < prs.stake THEN 'LOSE' END,
		statusID = CASE WHEN prs.winlost = prs.stake THEN 111 WHEN prs.winlost > prs.stake THEN 112 WHEN prs.winlost < prs.stake THEN 113 END,
		1,
		PRS.winlost, PRS.awinlost, PRS.mwinlost, PRS.swinlost, PRS.playercomm, PRS.comm, PRS.acomm, PRS.scomm,
		b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking, b.playerdiscount, b.discount, b.adiscount, b.sdiscount,
		0,0,0,   0,0,0,   b.betteam, b.creator, 'm', b.betfrom, '', b.recommend, b.mrecommend, b.srecommend, b.IP, '', b.UserName,
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

