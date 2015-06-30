ALTER PROCEDURE [dbo].[Admin_3rdDummyTransfer_s151_FOdds] 
	@ProgramID varchar(10),
	@raceNumber int,
	@EventDate smalldatetime
AS
/*
	created by:
	Date:
	DB: DBTRANS.BODB02
	Revisions:
		- 20110106@Lukas: Re-arrange bettype
*/
-- Get List of involve Horse for this race.
Declare @orid int, @leagueid int
DECLARE @Horse TABLE (orid int, placing tinyint, leagueid int)
INSERT INTO @Horse (orid, placing, leagueid)
	SELECT orid, placing, leagueid
	FROM dbo.outright with (nolock)
	WHERE
		ProgramID = @ProgramID
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND eventdate = @EventDate
		AND oddsstatus = 'completed'

SELECT TOP 1 @orid = orid, @leagueid = leagueid
FROM @Horse ORDER BY Placing


-- Obtain commission value
Declare @WinCommRate smallmoney, @PlaceCommRate smallmoney
SELECT @WinCommRate = 0.06, @PlaceCommRate = 0.06



-- Get Summary Value for insert into Dummy A/C
--DECLARE @sum TABLE (currency tinyint, bettype tinyint, IsPlaceRefund bit, stake money, winlost money, scomm money, CommRate smallmoney)
DECLARE @sum  TABLE (currency tinyint, bettype smallint, TurnOver3rd money, WinLost3rd money, Comm3rd money, IBCWinLost money, scomm money)
INSERT INTO @sum (currency, bettype, TurnOver3rd, WinLost3rd, Comm3rd, IBCWinLost, scomm)
	SELECT
		b.currency, b.bettype, 
		SUM(actual_stake * (1-tpositiontaking-oddsspread)) TurnOver3rd,
		SUM(winlost      * (1-tpositiontaking-oddsspread)) WinLost3rd,
		SUM(actual_stake * (1-tpositiontaking-oddsspread) * CASE bettype WHEN 41 THEN @WinCommRate ELSE @PlaceCommRate END) Comm3rd,
		SUM((winlost-actual_stake) * oddsspread) IBCWinLost,
		SUM(scomm)
	FROM
		dbo.bettrans b with (nolock)
		INNER JOIN @Horse h ON b.matchid = h.orid
	WHERE
		b.[status] NOT IN (N'void', N'reject', N'refund')
		AND b.bettype IN (41,42)
	GROUP BY
		b.currency, b.bettype

DECLARE @sumM TABLE (currency tinyint, bettype smallint, TurnOver3rd money, WinLost3rd money, Comm3rd money, IBCWinLost money, scomm money)
INSERT INTO @sumM (currency, bettype, TurnOver3rd, WinLost3rd, Comm3rd, IBCWinLost, scomm)
	SELECT
		bb.currency, b.bettype,
		SUM(b.stake * (1-b.tpositiontaking-b.oddsspread)) TurnOver3rd,
		SUM(b.winlost      * (1-b.tpositiontaking-b.oddsspread)) WinLost3rd,
		SUM(b.stake * (1-b.tpositiontaking-b.oddsspread) * CASE b.bettype WHEN 41 THEN @WinCommRate ELSE @PlaceCommRate END) Comm3rd,
		SUM((b.winlost-b.stake) * b.oddsspread) IBCWinLost,
		SUM(b.scomm)
	FROM
		dbo.bettransm b with (nolock)
		INNER JOIN dbo.bettrans bb with (nolock) ON b.refno = bb.transid AND bb.bettype = 33
		INNER JOIN @Horse h ON bb.matchid = h.orid
	WHERE
		b.[status] NOT IN (N'void', N'reject', N'refund')
		AND b.bettype IN (41,42)
	GROUP BY
		bb.currency, b.bettype


INSERT INTO @sum (currency, bettype, TurnOver3rd, WinLost3rd, Comm3rd, IBCWinLost, scomm)
	SELECT currency, 43, SUM(TurnOver3rd), SUM(WinLost3rd), SUM(Comm3rd), SUM(IBCWinLost), SUM(scomm)
	FROM @sumM
	GROUP BY currency


-- =================
-- DUMMY GEN & CHECK
-- v v v v v v v v v : below

	-- Get Dummy User Array
	DECLARE @Dummy TABLE ([type] tinyint, [desc] varchar(10), currency tinyint, username nvarchar(50), custid int, recommend int, mrecommend int, srecommend int, actualrate float, CurrencyName nvarchar(50))
	-- [type] 0:TurnOver 1:WinLost 2:CommSA 3:CommIBC 4:Comm3rd
	-- 5:IBCPos

	INSERT INTO @Dummy -- TurnOver for Horseracing
		SELECT 0, 'TurnOver', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'TO4BW' + e.currency

	INSERT INTO @Dummy -- Dividend Receivables for Horseracing
		SELECT 1, 'WinLost', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'Payout4BW' + e.currency

	INSERT INTO @Dummy -- Commission Expense for Horseracing
		SELECT 2, 'CommSA', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommExp4Fixed' + e.currency

	INSERT INTO @Dummy -- Commission Income from Horseracing
		SELECT 3, 'CommIBC', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommIncFrFixed' + e.currency

	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 4, 'Comm3rd', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommRecFrBW' + e.currency

	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 5, 'IBCPos', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'WLFrFixed' + e.currency


	-- Check for none-exists Dummy A/C for target currency
	DECLARE @DummyCheck TABLE (currency tinyint)
	INSERT INTO @DummyCheck
	SELECT s.currency
	FROM
		(SELECT distinct currency FROM @sum) AS s
		FULL JOIN @Dummy c ON s.currency = c.currency
	GROUP BY s.currency
	HAVING IsNull(count(*),0) < 9

	IF @@ROWCOUNT > 0
	BEGIN
		SELECT 'Dummy Account Missing' AS Result
		SELECT * FROM @DummyCheck

		-- report error SP
		RETURN
	END

-- ^ ^ ^ ^ ^ ^ ^ ^ ^ : above
-- DUMMY GEN & CHECK
-- =================


-- Record Transfer Value  (gain -> winlost, paid -> actual_stake)
-- 0:TurnOver - TurnOver send to 3rd
-- 1:WinLost  - 3rd paid back to member (According to PositionTaking)
-- 2:CommSA   - ibc paid to agent      (balance with scomm)
-- 3:CommIBC  - ibc gain from 3rd
-- 4:Comm3rd  - 3rd paid to ibc
-- 5:IBCPos   - ibc winlost

INSERT INTO bettrans (
	custid, creator, recommend, mrecommend, srecommend, matchid, bettype, winlostdate, ruben, [status],
	actual_stake,
	stake,
	winlost,
	awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
	tpositiontaking, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount,
	oddsid, betteam, hdp1, hdp2, odds, modds, betfrom, transdesc,
	actualrate, virtualrate, currency, refno, username, currencyName
	)
SELECT
	c.custid, c.custid, c.recommend, c.mrecommend, c.srecommend, @orid, s.bettype, @EventDate, 1, 'done',
	CASE c.[type]
	    WHEN 0 THEN 0
	    WHEN 1 THEN s.WinLost3rd
	    WHEN 2 THEN s.scomm
	    WHEN 3 THEN 0
	    WHEN 4 THEN s.Comm3rd
	    WHEN 5 THEN CASE WHEN s.IBCWinLost > 0 THEN  s.IBCWinLost ELSE 0 END	    
	END,
	CASE c.[type]
	    WHEN 0 THEN 0
	    WHEN 1 THEN s.WinLost3rd
	    WHEN 2 THEN s.scomm
	    WHEN 3 THEN 0
	    WHEN 4 THEN s.Comm3rd
	    WHEN 5 THEN CASE WHEN s.IBCWinLost > 0 THEN  s.IBCWinLost ELSE 0 END	    
	END,
	CASE c.[type]
	    WHEN 0 THEN s.TurnOver3rd
	    WHEN 1 THEN 0
	    WHEN 2 THEN 0
	    WHEN 3 THEN s.Comm3rd
	    WHEN 4 THEN 0
	    WHEN 5 THEN CASE WHEN s.IBCWinLost < 0 THEN -s.IBCWinLost ELSE 0 END	   
	END,
	0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	@orid, 'horse', 0, 0, 0, 0, 'i', 'HorseDummyFixed ' + c.[desc] + ' for Race ' + CAST(@raceNumber as varchar(20)) + ' of ' + @ProgramID + ':' + CAST(@leagueid as varchar(20)) + ':' + CAST(s.bettype as varchar(20)),
	c.actualrate, c.actualrate, c.currency, 100000000000, c.username, c.currencyName
FROM
	@sum AS s
	INNER JOIN @Dummy AS c ON s.currency = c.currency

GO
GRANT EXECUTE ON [dbo].[Admin_3rdDummyTransfer_s151_FOdds] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Admin_3rdDummyTransfer_s151_FOdds] TO [Dot_3rdparty]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdDummyTransfer_s151_FOdds] TO [vnteam]