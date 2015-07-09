USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_BalanceUp]    Script Date: 05/23/2011 05:32:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_BalanceUp]
	@fdate as datetime,
	@continue as bit = 0
AS

/*
Created: 
Task : 

DB: DBTRANS.bodb02
Original:

Revisions:
	-- 20110523@Henry: change bettype to new range
	-- 20110826@Sophia: Add Linked Server DB02 for table match, odd, livescore. Change Server to DBTRANS instead of DB02.
	
Param's Explanation: 

*/	

SET @fdate = CONVERT(nvarchar(10), @fdate, 120)
IF (DATEPART(weekday, @fdate) <> 2) AND (@continue = 0)
BEGIN
	PRINT 'Input date is not Monday'
	PRINT 'If you really want to continue, call with @continue = 1'
	RETURN
END

--- DATA VERIFY
IF EXISTS (SELECT * FROM Customer with (nolock) WHERE (recommend is null or mrecommend is null or srecommend is null) AND roleid <= 2)
BEGIN
	SELECT 'Some Customer/Agent records have NULL AgentID' Result
	SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
		FROM customer with (nolock)
		WHERE roleid <= 2
		AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
	RETURN
END
IF EXISTS (SELECT * FROM customer with (nolock) WHERE (recommend is NULL or mrecommend is null or srecommend is null) AND roleid = 3)
BEGIN
	SELECT 'Some Master records have NULL AgentID' Result
	SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
		FROM customer with (nolock)
		WHERE roleid = 3
		AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
	RETURN
END
IF EXISTS (SELECT * FROM customer with (nolock) WHERE (recommend is NULL or mrecommend is null or srecommend is null) AND roleid = 4)
BEGIN
	SELECT 'Some SuperAgent records have NULL AgentID' Result
	SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
		FROM customer with (nolock)
		WHERE roleid = 4
		AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
	RETURN
END
IF EXISTS (SELECT * FROM bettrans with (nolock) WHERE (srecommend is null or mrecommend is null or recommend is null) AND winlostdate < @fdate)
BEGIN
	SELECT 'Some records in BetTrans have NULL AgentID' Result
	SELECT transid, custid, recommend, mrecommend, srecommend, currency
		FROM bettrans with (nolock)
		WHERE (recommend is NULL or mrecommend is NULL or srecommend is NULL) AND winlostdate < @fdate
	RETURN
END

IF EXISTS (SELECT * FROM bettrans with (nolock) WHERE (swinlost is null or mwinlost is null or awinlost is null or winlost is null) AND winlostdate < @fdate)
BEGIN
	SELECT 'Some records in BetTrans have NULL winlost' Result
	RETURN
END
IF EXISTS (SELECT * FROM bettrans with (nolock) WHERE (scomm is null or acomm is null or comm is null or playercomm is null) AND winlostdate < @fdate)
BEGIN
	SELECT 'Some records in BetTrans have NULL commission' Result
	RETURN
END

IF EXISTS (SELECT * FROM bettrans with (nolock) WHERE (scomm <> acomm OR swinlost <> 0) AND bettype <= 9 AND winlostdate < @fdate AND srecommend <= 100)
BEGIN
	SELECT 'Some records in BetTrans have incorrect Company SuperAgent setting' Result
	SELECT transid, srecommend, sdiscount, adiscount, spositiontaking, scomm, acomm, swinlost 
		FROM bettrans with (nolock)
		WHERE (scomm <> acomm OR swinlost <> 0) AND bettype <= 19000 AND winlostdate < @fdate AND srecommend <= 100
	RETURN
END

--- START --- START --- START ---
--- START --- START --- START ---
--- START --- START --- START ---
-- verify @fdate
Declare @testdate datetime
SET @testdate = CONVERT(varchar(10), @fdate, 120)
IF @testdate <> @fdate
BEGIN
	SELECT 'ERROR: Input parameter is DATE value with TIME.' Result
	RETURN
END

EXEC dbo.balancecheck
-- doing backup
Declare @suffix varchar(10)
SET @suffix = 'bbu' + RIGHT(CONVERT(varchar(10), @fdate,120),5)
EXEC dbo.Task_BackupFULL @suffix
-- doing backup : end

-- =====================
--   CALCULATE BALANCE
-- =====================
BEGIN TRANSACTION
	delete from dbo.balancetable;

	-- Member
	insert into dbo.balancetable(custid, amount)
	select 	bettrans.custid custid, 
		sum(winlost-actual_stake + playercomm) amount
	from
		dbo.bettrans with (nolock)
		--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
	where
		ruben = 1 and
		winlostdate < @fdate and
		bettrans.custid <> bettrans.recommend and
		bettrans.custid <> bettrans.mrecommend and
		bettrans.custid <> bettrans.srecommend
	group by bettrans.custid;

	-- Agent
	insert into dbo.balancetable (custid, amount)
	select	bettrans.recommend custid,
		sum(case
		when bettrans.custid=bettrans.recommend then winlost-actual_stake
		else awinlost+comm-playercomm
		end) amount
	from
		dbo.bettrans with (nolock)
		--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
	where
		ruben=1 and 
		winlostdate < @fdate
	group by bettrans.recommend;

	-- Master
	insert into dbo.balancetable (custid, amount)
	select	bettrans.mrecommend custid,
		sum(case
		when bettrans.custid=bettrans.mrecommend then winlost-actual_stake
		else mwinlost+acomm-comm
		end) amount
	from
		dbo.bettrans with (nolock)
		--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
	where
		ruben=1 and 
		winlostdate < @fdate
	group by bettrans.mrecommend;

	-- Super
	insert into dbo.balancetable (custid, amount)
	select	bettrans.srecommend custid,
		sum(case
		when bettrans.custid=bettrans.srecommend then winlost-actual_stake
		else swinlost+scomm-acomm
		end) amount
	from
		dbo.bettrans with (nolock)
		--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
	where
		ruben=1 and 
		winlostdate < @fdate
	group by bettrans.srecommend;
COMMIT TRANSACTION

BEGIN TRANSACTION
	-- Delete NO-Balance record
	delete from balancetable where amount = 0
	AND awinlost = 0 AND mwinlost = 0 AND swinlost = 0
	AND playercomm = 0 AND comm = 0 AND acomm = 0 AND scomm = 0
		--abs(amount) < 0.01

	-- Update needed value
	update balancetable
	set
		recommend = c.recommend,
		mrecommend= c.mrecommend,
		srecommend= c.srecommend,
		currency  = c.currency,
		UserName  = c.username,
		CurrencyName = e.currency,
		actualrate = e.actualrate
	from dbo.custinfo c, dbo.exchange e
	where
		c.custid = balancetable.custid
		AND c.currency = e.exchangeid

	-- copy data, ready for insertion
	INSERT INTO dbo.balancetable_tmp
	SELECT @fdate, * FROM dbo.balancetable
COMMIT TRANSACTION

-- =====================
--   CLEAN OLD RECORDS
-- =====================

	-- move to ExecRep_00
	-- delete from bettrans where ruben=1 and winlostdate < @fdate 
	EXEC ExecRep_00 @fdate

--insert into sbo.dbo.match select * from match where matchid not in (select distinct matchid from bettrans where bettype between 1 and 8) and kickofftime < @fdate
--insert into sbo.dbo.odds select * from odds where matchid not in (select matchid from match)
delete from DB02.bodb02.dbo.match where matchid not in (select distinct matchid from bettrans where bettype <= 19000) 	and kickofftime < @fdate
delete from DB02.bodb02.dbo.odds where matchid not in (select matchid from match)
delete from DB02.bodb02.dbo.liveScore where matchid not in (select matchid from match (nolock) union all select matchid from match14 (nolock))

WAITFOR DELAY '000:03:00.000'

-- ======================
--   INSERT NEW BALANCE
-- ======================

SET NOCOUNT ON

Declare @loop varchar(1)
SET @loop = 'y'
WHILE @loop = 'y'
BEGIN
	BEGIN TRANSACTION
	DELETE TOP(15000) FROM dbo.balanceTable_tmp
	
	IF @@ROWCOUNT = 0 SET @loop = 'n'
	COMMIT TRANSACTION

	WAITFOR DELAY '000:00:04.00'
END

SET NOCOUNT OFF


EXEC dbo.balancecheck


-- end comment





GO
GRANT VIEW DEFINITION ON [dbo].[Task_BalanceUp] TO [vnteam]