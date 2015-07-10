ALTER PROCEDURE [dbo].[Admin_3rdDummyTransfer_s151_ToteFixed] 
	@ProgramID varchar(10),
	@raceNumber int,
	@EventDate smalldatetime
AS

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
		AND oddsstatus = 'closed'

SELECT TOP 1 @orid = orid, @leagueid = leagueid
FROM @Horse ORDER BY Placing

-- Get Summary Value for insert into Dummy A/C
DECLARE @sum TABLE (	currency	tinyint, 
						bettype		tinyint, 
						stake		money, 
						winlost		money, 
						scomm		money, 
						CommRate	smallmoney,
						IBCWinloss	money
					)
INSERT INTO @sum (currency, bettype, stake, winlost, scomm,IBCWinloss)
	SELECT
		b.currency, b.bettype,
		SUM(CASE WHEN b.bettype = 33 THEN bm.stake ELSE b.actual_stake*(1-b.tpositiontaking -isnull(b.oddsspread,0)) END),
		SUM(CASE WHEN b.bettype = 33 THEN bm.winlost ELSE b.winlost*(1-b.tpositiontaking-isnull(b.oddsspread,0))END),
		SUM(b.scomm),
		SUM(CASE WHEN b.bettype = 33 THEN bm.WLIBC ELSE (b.winlost-b.actual_stake)*isnull(b.oddsspread,0) END) 
	FROM
		dbo.bettrans b with (nolock)
		INNER JOIN @Horse h ON b.matchid = h.orid
		LEFT JOIN (
			SELECT	refno,
					SUM(CASE WHEN bettype = 32 and liveawayscore = 0 THEN 0 ELSE stake*(1-tpositiontaking -isnull(oddsspread,0)) END) stake,
					SUM(CASE WHEN bettype = 32 and liveawayscore = 0 THEN 0 ELSE winlost*(1-tpositiontaking -isnull(oddsspread,0)) END) winlost,
					SUM((winlost -stake)*isnull(oddsspread,0)) WLIBC
			FROM	bettransm (nolock)
			WHERE	ruben = 1
			GROUP BY	refno
		)bm ON bm.refno = b.transid 
	WHERE
		b.[status] NOT IN (N'void', N'reject', N'refund')
		AND b.bettype IN (31,32,33)
	GROUP BY
		b.currency, b.bettype

---------------------------------------------------
-- Get Summary Value for insert into Dummy A/C For BW
DECLARE @sumBW TABLE (currency tinyint, bettype tinyint, stake money, winlost money, scomm money, IBCWinloss	money)
INSERT INTO @sumBW (currency, bettype, stake, winlost, scomm, IBCWinloss)
	SELECT
		b.currency, b.bettype,
		SUM(CASE WHEN b.bettype = 43 THEN bm.stake	ELSE b.actual_stake*(1-b.tpositiontaking-isnull(b.oddsspread,0)) END),
		SUM(CASE WHEN b.bettype = 43 THEN bm.winlost ELSE b.winlost*(1-b.tpositiontaking -isnull(b.oddsspread,0)) END),
		SUM(b.scomm),
		SUM( CASE WHEN b.bettype = 43 THEN bm.WLIBC ELSE (b.winlost-b.actual_stake)*isnull(b.oddsspread,0)END)		
	FROM
		dbo.bettrans b with (nolock)
		INNER JOIN @Horse h ON b.matchid = h.orid
		LEFT JOIN (
			SELECT	refno,
					SUM(CASE WHEN bettype = 42 and liveawayscore = 0 THEN 0 ELSE stake*(1-tpositiontaking -isnull(oddsspread,0))END) stake,
					SUM(CASE WHEN bettype = 42 and liveawayscore = 0 THEN 0 ELSE winlost*(1-tpositiontaking -isnull(oddsspread,0)) END) winlost,
					SUM((winlost -stake)*isnull(oddsspread,0)) WLIBC
			FROM	bettransm (nolock)
			WHERE	ruben = 1
			GROUP BY	refno
		)bm ON bm.refno = b.transid 
	WHERE
		b.[status] NOT IN (N'void', N'reject', N'refund')
		AND b.bettype IN (41,42,43)
	GROUP BY
		b.currency, b.bettype


-- =================
-- DUMMY GEN & CHECK
-- v v v v v v v v v : below

	-- Get Dummy User Array
	DECLARE @Dummy TABLE ([type] tinyint, [desc] varchar(10), currency tinyint, username nvarchar(50), custid int, recommend int, mrecommend int, srecommend int, actualrate float)
	-- [type] 0:TurnOver 1:WinLost 2:CommSA 3:CommIBC 4:Comm3rd
	--		  5:IBCWinLoss 6:PGIFree 7:AmtoteFree 8:FeeDue2 

	INSERT INTO @Dummy -- TurnOver for Horseracing
		SELECT 0, 'TurnOver', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'TO4HR' + e.currency

	INSERT INTO @Dummy -- Dividend Receivables for Horseracing
		SELECT 1, 'WinLost', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'DivRec4HR' + e.currency

	INSERT INTO @Dummy -- Commission Expense for Horseracing
		SELECT 2, 'CommSA', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommExp4HR' + e.currency

	INSERT INTO @Dummy -- Commission Income from Horseracing
		SELECT 3, 'CommIBC', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommIncFrHR' + e.currency

	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 4, 'Comm3rd', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommRecFrPhu' + e.currency

	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 5, 'IBCWinLoss', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'WLFrPT' + e.currency

	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 6, 'PGIFee', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'PGIFee' + e.currency
	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 7, 'AmtoteFee', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'AmtoteFee' + e.currency

	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 8, 'FeeDue2', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'FeeDue2' + e.currency


	-- Get Dummy User Array BW 
	DECLARE @DummyBW TABLE ([type] tinyint, [desc] varchar(10), currency tinyint, username nvarchar(50), custid int, recommend int, mrecommend int, srecommend int, actualrate float)
	-- [type] 0:TurnOver 1:WinLost 2:CommSA 3:CommIBC 4:Comm3rd
	--		  5:IBCWinLoss 6:PGIFree 7:AmtoteFree 8:FeeDue2 

	INSERT INTO @DummyBW -- TurnOver for Horseracing
		SELECT 0, 'TurnOver', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'TO4BW' + e.currency

	INSERT INTO @DummyBW -- Amount BW owes IBC from winning bets placed by IBC 
		SELECT 1, 'WinLost', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'Payout4BW' + e.currency

	INSERT INTO @DummyBW -- Commission Expense for Horseracing
		SELECT 2, 'CommSA', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommExp4Fixed' + e.currency

	INSERT INTO @DummyBW -- Commission Income from BW
		SELECT 3, 'CommIBC', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommIncFrFixed' + e.currency

	INSERT INTO @DummyBW -- Commission Receivables from Phumelela
		SELECT 4, 'Comm3rd', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommRecFrBW' + e.currency


	INSERT INTO @DummyBW -- Commission Receivables from Phumelela
		SELECT 5, 'IBCWinLoss', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate
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

	-- Obtain commission value
	-- CommID : MinStake field
	-- Win    : MaxStake field
	-- Place  : MaxStakeOU field
	Declare @WinCommRate smallmoney, @PlaceCommRate smallmoney
	SELECT @WinCommRate = CAST(maxstake as smallmoney), @PlaceCommRate = CAST(maxstakeou as smallmoney)
	FROM dbo.league with (nolock)
	WHERE leagueid = @leagueid

	UPDATE @sum
	SET CommRate = CASE
		WHEN bettype = 31 THEN  @WinCommRate  -- Win   : uses CommRate
		WHEN bettype = 32 THEN  @PlaceCommRate -- Place : uses CommRate of CommID = 2
		WHEN bettype = 33 THEN (@WinCommRate + @PlaceCommRate) / 2 -- Each Way = Win & Place : calculate average commission rate
		END

-- Record Transfer Value  (gain -> winlost, paid -> actual_stake)
-- 0:TurnOver - 3rd gain from member   (balance with member's stake)
-- 1:WinLost  - 3rd paid to member     (balance with member's winlost)
-- 2:CommSA   - ibc paid to agent      (balance with scomm)
-- 3:CommIBC  - ibc gain from 3rd
-- 4:Comm3rd  - 3rd paid to ibc
-- 5:IBCWinLoss - winloss from IBC PT
-- 6:PGIFee
-- 7: AmtoteFee
-- 8:FeeDue2 = PGIFee + AmtoteFee
INSERT INTO bettrans (
	custid, recommend, mrecommend, srecommend, matchid, bettype, winlostdate, ruben, [status],
	actual_stake,
	winlost,
	awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
	tpositiontaking, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount,
	oddsid, betteam, hdp1, hdp2, odds, modds, betfrom, stake, transdesc,
	actualrate, virtualrate, currency, refno
	)
SELECT
	c.custid, c.recommend, c.mrecommend, c.srecommend, @orid, s.bettype, @EventDate, 1, 'done',
	CASE c.[type]	WHEN 0 THEN 0 
					WHEN 1 THEN s.WinLost 
					WHEN 2 THEN s.scomm 
					WHEN 3 THEN 0 
					WHEN 4 THEN s.CommRate * s.stake             
					WHEN 5 THEN (CASE WHEN s.IBCWinloss > 0	THEN s.IBCWinloss	ELSE 0	END)	
					WHEN 6 THEN 0				
					WHEN 7 THEN 0				
					WHEN 8 THEN s.stake*(0.005+0.0033) 
					ELSE 0 END,
	CASE c.[type]	WHEN 0 THEN s.stake                       
					WHEN 1 THEN 0 
					WHEN 2 THEN 0 
					WHEN 3 THEN s.CommRate * s.stake   
					WHEN 4 THEN 0 
					WHEN 5 THEN (CASE WHEN s.IBCWinloss < 0 THEN ABS(s.IBCWinloss)	ELSE 0 END)
					WHEN 6 THEN s.stake*0.005
					WHEN 7 THEN s.stake*0.0033	
					WHEN 8 THEN 0						
					ELSE 0 END,
	0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	@orid, 'horse', 0, 0, 0, 0, 'i', 0, 'Tote HorseDummy ' + c.[desc] + ' for Race ' + CAST(@raceNumber as varchar(20)) + ' of ' + @ProgramID + ':' + CAST(@leagueid as varchar(20)) + ':' + CAST(s.bettype as varchar(20)),
	c.actualrate, c.actualrate, c.currency, 100000000000
FROM
	@sum AS s
	INNER JOIN @Dummy AS c ON s.currency = c.currency



INSERT INTO bettrans (
	custid, recommend, mrecommend, srecommend, matchid, bettype, winlostdate, ruben, [status],
	actual_stake,
	winlost,
	awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
	tpositiontaking, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount,
	oddsid, betteam, hdp1, hdp2, odds, modds, betfrom, stake, transdesc,
	actualrate, virtualrate, currency, refno
	)
SELECT
	c.custid, c.recommend, c.mrecommend, c.srecommend, @orid, s.bettype, @EventDate, 1, 'done',
	CASE c.[type]	WHEN 0 THEN 0 
					WHEN 1 THEN s.WinLost 
					WHEN 2 THEN s.scomm 
					WHEN 3 THEN 0 
					WHEN 4 THEN 0.06 * s.stake    --ibc GET 6% on Turnover          
					WHEN 5 THEN (CASE WHEN s.IBCWinloss > 0	THEN s.IBCWinloss	ELSE 0	END)	
					ELSE 0 END,
	CASE c.[type]	WHEN 0 THEN s.stake                       
					WHEN 1 THEN 0 
					WHEN 2 THEN 0 
					WHEN 3 THEN 0.06 * s.stake   
					WHEN 4 THEN 0 
					WHEN 5 THEN (CASE WHEN s.IBCWinloss < 0 THEN ABS(s.IBCWinloss)	ELSE 0 END)
					ELSE 0 END,
	0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	@orid, 'horse', 0, 0, 0, 0, 'i', 0, 'BW HorseDummy ' + c.[desc] + ' for Race ' + CAST(@raceNumber as varchar(20)) + ' of ' + @ProgramID + ':' + CAST(@leagueid as varchar(20)) + ':' + CAST(s.bettype as varchar(20)),
	c.actualrate, c.actualrate, c.currency, 100000000000
FROM
	@sumBW AS s
	INNER JOIN @DummyBW AS c ON s.currency = c.currency



GO
GRANT EXECUTE ON [dbo].[Admin_3rdDummyTransfer_s151_ToteFixed] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdDummyTransfer_s151_ToteFixed] TO [ITTim]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdDummyTransfer_s151_ToteFixed] TO [ITVivi]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdDummyTransfer_s151_ToteFixed] TO [vnteam]