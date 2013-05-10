ALTER PROCEDURE [dbo].[Admin_3rdAutoSettlement_s201]
	@ReturnErrCode bit = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(400) = '' OUTPUT
AS

/* 
Created by:[]
Date:
Task: settle
DB: DBTRANS.BODB02
	Revisions: 
		-- 20100517@Henry: Update column StatusID of Bettrans
		-- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		-- 20100825@Lukas: Update last time modify (changetime column) for match table
		-- 20101007@Henry: Change column transid from INT to BIGINT
		-- 20110106@Lukas: Re-arrange bettype
		-- 20110906@Sophia: Add Linked Server DB02.BODB02.dbo for table match

-- *** actual work for settlement of this sporttype (financial)
-- *** is to doing Dummy Transfer
-- *** real name of this SP should be Admin_3rdDummyTransfer_s201

*/

-- Financial Share Configuration 
Declare @IBCShareRate money SET @IBCShareRate = 0.85 -- IBC Share 85%

-- Get List of closed event, which not settled (dummy transaction insert) yet
DECLARE @match TABLE (matchid int, eventdate smalldatetime)
INSERT INTO @match (matchid, eventdate)
SELECT matchid, eventdate FROM DB02.BODB02.dbo.match with (nolock)
WHERE
	sporttype = 201 -- Financial Bet
	AND eventstatus <> 'completed' -- match not settled yet.
	AND closedtime < DATEADD(hour, -6, CURRENT_TIMESTAMP) -- closed longer than 6 hours ago, Match already consider Full closed.

-- ===============
-- DATA VALIDATION
-- v v v v v v v v : below
	DECLARE @bet TABLE (transid bigint)
	-- Verify None Running tickets
	INSERT INTO @bet (transid)
	SELECT transid FROM dbo.bettrans with (nolock)
	WHERE
		matchid in (select matchid FROM @match)
		--AND [status] IN (N'running', N'waiting')
		AND statusID IN (0,1)

	IF @@ROWCOUNT > 0
	BEGIN
		Select @ErrMsg = 'Some ticket(s) still running',
				@ErrCode = 101
		
		if @ReturnErrCode = 0
		BEGIN
			SELECT @ErrMsg AS Result
			SELECT * FROM @bet
		END

		return
	END

	-- Verify Result
	INSERT INTO @bet (transid)
	SELECT transid FROM dbo.bettrans with (nolock)
	WHERE
		matchid in (select matchid FROM @match)
		AND CASE
		WHEN bettype < 61 AND betteam = N'h' AND statusID = 112  AND hdp2 < hdp1 THEN 1 -- Over : won : but result < "goal"
		WHEN bettype < 61 AND betteam = N'a' AND statusID = 112  AND hdp2 > hdp1 THEN 1 -- Under: won : but result > "goal"
		WHEN bettype < 61 AND betteam = N'h' AND statusID = 113 AND hdp2 > hdp1 THEN 1 -- Over : lose: but result > "goal"
		WHEN bettype < 61 AND betteam = N'a' AND statusID = 113 AND hdp2 < hdp1 THEN 1 -- Under: lose: but result < "goal"
		WHEN bettype > 60 AND betteam = N'h' AND statusID = 112  AND (ROUND(hdp2, 0,1) %2) = 0 THEN 1 -- Odd : won : but result is Even
		WHEN bettype > 60 AND betteam = N'a' AND statusID = 112  AND (ROUND(hdp2, 0,1) %2) = 1 THEN 1 -- Even: won : but result is Odd
		WHEN bettype > 60 AND betteam = N'h' AND statusID = 113 AND (ROUND(hdp2, 0,1) %2) = 1 THEN 1 -- Odd : lose: but result is Odd
		WHEN bettype > 60 AND betteam = N'a' AND statusID = 113 AND (ROUND(hdp2, 0,1) %2) = 0 THEN 1 -- Even: lose: but result is Even
		ELSE 0 END = 1

	IF @@ROWCOUNT > 0
	BEGIN
		Select @ErrMsg = 'Some ticket(s) win/lose status not match with result',
				@ErrCode = 102
		
		if @ReturnErrCode = 0
		BEGIN
			SELECT @ErrMsg AS result
			SELECT transid, bettype, betteam, hdp1, hdp2, [status], 
				CASE
					WHEN bettype < 61 AND betteam = N'h' THEN 'Over'
					WHEN bettype < 61 AND betteam = N'a' THEN 'Under'
					WHEN bettype > 60 AND betteam = N'h' THEN 'Odd'
					WHEN bettype > 60 AND betteam = N'a' THEN 'Even'
					ELSE 'Other' END Choose,
				CASE
					WHEN bettype < 61 AND hdp2 > hdp1 THEN 'Over'
					WHEN bettype < 61 AND hdp1 > hdp2 THEN 'Under'
					WHEN bettype > 60 AND (ROUND(hdp2, 0,1) %2) = 1 THEN 'Odd'
					WHEN bettype > 60 AND (ROUND(hdp2, 0,1) %2) = 0 THEN 'Even'
				ELSE 'Other' END Result
			FROM dbo.bettrans with (nolock)
			WHERE transid IN (select transid from @bet)
		END
		return
	END
-- ^ ^ ^ ^ ^ ^ ^ ^ : above
-- DATA VALIDATION
-- ===============

-- Get Summary Value for insert into Dummy A/C
DECLARE @sum TABLE (currency tinyint, matchid int, bettype smallint, winlost money)
INSERT INTO @sum (currency, matchid, bettype, winlost)
SELECT
	b.currency, b.matchid, b.bettype,
	SUM(actual_stake - winlost - awinlost - mwinlost - swinlost - scomm)
FROM
	dbo.bettrans b with (nolock)
	INNER JOIN @match m ON b.matchid = m.matchid
WHERE
	--b.[status] NOT IN (N'void', N'reject')
	b.[status] NOT IN (101,102)

GROUP BY
	b.currency, b.matchid, b.bettype


-- =================
-- DUMMY GEN & CHECK
-- v v v v v v v v v : below

	-- Get Dummy User Array
	DECLARE @Dummy3rd TABLE (currency tinyint, username nvarchar(50), custid int, recommend int, mrecommend int, srecommend int, actualrate float, CurrencyName nvarchar(50))
	INSERT INTO @Dummy3rd
	SELECT c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, actualrate, e.currency
	FROM dbo.custinfo c with (nolock)
		INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
	WHERE
		e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
		c.username LIKE 'FI3rdShare' + e.currency

	DECLARE @DummyIBC TABLE (currency tinyint, username nvarchar(50), custid int, recommend int, mrecommend int, srecommend int, actualrate float, CurrencyName nvarchar(50))
	INSERT INTO @DummyIBC
	SELECT c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, actualrate, e.currency
	FROM dbo.custinfo c with (nolock)
		INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
	WHERE
		e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
		c.username LIKE 'FIIBCShare' + e.currency


	-- Check for none-exists Dummy A/C for target currency
	DECLARE @DummyCheck TABLE (currency tinyint)
	INSERT INTO @DummyCheck
	SELECT s.currency
	FROM
		(SELECT distinct currency FROM @sum) AS s
		FULL JOIN @DummyIBC [ibc] ON s.currency = [ibc].currency
		FULL JOIN @Dummy3rd [3rd] ON s.currency = [3rd].currency
	WHERE
		IsNull([ibc].currency, 0) = 0 OR
		IsNull([3rd].currency, 0) = 0

	IF @@ROWCOUNT > 0
	BEGIN
		Select @ErrMsg = 'Dummy Account Missing',
				@ErrCode = 103
		
		if @ReturnErrCode = 0
		BEGIN
			SELECT @ErrMsg AS Result
			SELECT * FROM @DummyCheck
		END
		-- report error SP
		RETURN
	END

-- ^ ^ ^ ^ ^ ^ ^ ^ ^ : above
-- DUMMY GEN & CHECK
-- =================


/* DEBUG
select * from @match
select * from @Sum
select * from @DummyIBC
select * from @Dummy3rd
*/

-- Record Transfer Value
-- IF value is positive : insert value into winlost
-- IF value is negative : insert abs(value) into actual_stake
Declare @3rdShareRate money SET @3rdShareRate = 1 - @IBCShareRate

INSERT INTO bettrans (
	custid, recommend, mrecommend, srecommend, matchid, bettype, winlostdate, ruben, [status],statusID,
	actual_stake,
	winlost,
	awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
	tpositiontaking, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount,
	oddsid, betteam, hdp1, hdp2, odds, modds, betfrom, stake, transdesc,
	actualrate, virtualrate, currency, refno, username, currencyName
	)
SELECT
	c.custid, c.recommend, c.mrecommend, c.srecommend, s.matchid, s.bettype, m.eventdate, 1, 'done',121,
	CASE WHEN winlost < 0 THEN abs(winlost * @IBCShareRate) ELSE 0 END,
	CASE WHEN winlost > 0 THEN winlost * @IBCShareRate ELSE 0 END,
	0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 'h', 0, 0, 0, 0, 'i', 0, 'Financial IBC Dummy Record (' + CAST(@IBCShareRate as varchar(10)) + ' of ' + CAST(winlost as nvarchar(50)) + ') for ' + CAST(s.matchid as varchar(20)) + ':' + CAST(s.bettype as varchar(20)),
	c.actualrate, c.actualrate, c.currency, 100000000000, c.username, c.currencyName
FROM
	@sum AS s
	INNER JOIN @match AS m ON s.matchid = m.matchid
	INNER JOIN @DummyIBC AS c ON s.currency = c.currency

INSERT INTO bettrans (
	custid, recommend, mrecommend, srecommend, matchid, bettype, winlostdate, ruben, [status],statusID,
	actual_stake,
	winlost,
	awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
	tpositiontaking, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount,
	oddsid, betteam, hdp1, hdp2, odds, modds, betfrom, stake, transdesc,
	actualrate, virtualrate, currency, refno, username, currencyName
	)
SELECT
	c.custid, c.recommend, c.mrecommend, c.srecommend, s.matchid, s.bettype, m.eventdate, 1, 'done',121,
	CASE WHEN winlost < 0 THEN abs(winlost * @3rdShareRate) ELSE 0 END,
	CASE WHEN winlost > 0 THEN winlost * @3rdShareRate ELSE 0 END,
	0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 'h', 0, 0, 0, 0, 'i', 0, 'Financial 3rd Dummy Record (' + CAST(@3rdShareRate as varchar(10)) + ' of ' + CAST(winlost as nvarchar(50))  + ') for ' + CAST(s.matchid as varchar(20)) + ':' + CAST(s.bettype as varchar(20)),
	c.actualrate, c.actualrate, c.currency, 100000000000, c.username, c.currencyName
FROM
	@sum AS s
	INNER JOIN @match AS m ON s.matchid = m.matchid
	INNER JOIN @Dummy3rd AS c ON s.currency = c.currency
	

-- Mark Financial Event as settled
UPDATE DB02.BODB02.dbo.match WITH(ROWLOCK,UPDLOCK)
SET eventstatus = 'completed', 
	ruben = 1,
	changetime = getdate()
WHERE matchid IN (SELECT matchid FROM @match)

-- UserLog
-- EXEC dbo.LogFile

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdAutoSettlement_s201] TO [vnteam]