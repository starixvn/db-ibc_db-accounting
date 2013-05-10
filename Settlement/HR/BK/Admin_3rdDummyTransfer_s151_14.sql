ALTER PROCEDURE [dbo].[Admin_3rdDummyTransfer_s151_14] 
	@leagueid	int,
	@raceNumber int,
	@EventDate	smalldatetime
AS
/*	Created: Jamie
	Date: 2009-11-09
	Task: Dummy Transfer for bettrans14 
	DB: DBTRANS.BODB02  
	
	Revisions:
		- 20100422@Jamie: Get Comm Rate and Fees from LeagueDetail and remove Dummy PGIFee
		- 20100427@Thien: rename variables: PhuTurnOver, PhuWinLost, PhuComm --> PartnerTurnOver, PartnerWinLost, PartnerComm
		                    to facilitate our understanding
		-- 20100522@Henry: Change to use StatusID instead of Status in WHERE statement
		-- 20110107@Lukas: Re-arrange bettype
		-- 20110225@Jamie: Change data type ToteCommWin, ToteCommPlace, ToteFee from smallmoney to decimal 
		-- 20110906@Sophia: Add Linked Server DB02.BODB02.dbo for table Outright, LeagueDetail
*/
 
SET NOCOUNT ON
-- Get List of involve Horse for this race.
DECLARE @Runner TABLE (orid int, placing tinyint, leagueid int)
INSERT INTO @Runner (orid, placing, leagueid)
	SELECT orid, placing, leagueid
	FROM DB02.BODB02.dbo.outright14 with (nolock)
	WHERE
		leagueid = @leagueid
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND eventdate = @EventDate
		AND oddsstatus = 'completed'


	-- Obtain commission value
	-- CommID : MinStake field
	-- Win    : MaxStake field
	-- Place  : MaxStakeOU field
	Declare @WinCommRate decimal(9,8), @PlaceCommRate decimal(9,8), @ToteFee decimal(9,8)
	SELECT	@WinCommRate = ToteCommWin, @PlaceCommRate = ToteCommPlace, @ToteFee = ToteFee 
	FROM	DB02.BODB02.dbo.LeagueDetail with (nolock)
	WHERE	leagueID = @leagueid AND ProgramDate = @EventDate

-- Get Summary Value for insert into Dummy A/C
--DECLARE @sum TABLE (currency tinyint, bettype tinyint, IsPlaceRefund bit, stake money, winlost money, scomm money, CommRate smallmoney)
DECLARE @sum  TABLE (currency smallint, bettype smallint, PartnerTurnOver money, PartnerWinLost money, PartnerComm money, IBCWinLost money, scomm money)
INSERT INTO @sum (currency, bettype, PartnerTurnOver, PartnerWinLost, PartnerComm, IBCWinLost, scomm)
	SELECT
		b.currency, b.bettype, 
		SUM(actual_stake * (1-tpositiontaking-oddsspread)) PartnerTurnOver,
		SUM(winlost      * (1-tpositiontaking-oddsspread)) PartnerWinLost,
		SUM(actual_stake * (1-tpositiontaking-oddsspread) * CASE bettype WHEN 31 THEN @WinCommRate ELSE @PlaceCommRate END) PartnerComm,
		SUM((winlost-actual_stake) * oddsspread) IBCWinLost,
		--SUM(CASE WHEN bettype = 33 AND liveawayscore = 0 THEN actual_stake/2 ELSE actual_stake END),
		--SUM(CASE WHEN bettype = 33 AND liveawayscore = 0 THEN winlost - (actual_stake/2) ELSE winlost END),
		SUM(scomm)
	FROM
		dbo.bettrans14 b with (nolock)
		INNER JOIN @Runner h ON b.matchid = h.orid
	WHERE
		--b.[status] NOT IN (N'void', N'reject', N'refund', N'done')
		b.statusID NOT IN (102,101,103,121)
		AND b.bettype IN (31,32)
	GROUP BY
		b.currency, b.bettype



DECLARE @sumM TABLE (currency smallint, bettype smallint, PartnerTurnOver money, PartnerWinLost money, PartnerComm money, IBCWinLost money, scomm money)
INSERT INTO @sumM (currency, bettype, PartnerTurnOver, PartnerWinLost, PartnerComm, IBCWinLost, scomm)
	SELECT
		bb.currency, b.bettype,
		SUM(b.stake * (1-b.tpositiontaking-b.oddsspread)) PartnerTurnOver,
		SUM(b.winlost      * (1-b.tpositiontaking-b.oddsspread)) PartnerWinLost,
		SUM(b.stake * (1-b.tpositiontaking-b.oddsspread) * CASE b.bettype WHEN 31 THEN @WinCommRate ELSE @PlaceCommRate END) PartnerComm,
		SUM((b.winlost-b.stake) * b.oddsspread) IBCWinLost,
		SUM(b.scomm)
	FROM
		dbo.bettransm14 b with (nolock)
		INNER JOIN dbo.bettrans14 bb with (nolock) ON b.refno = bb.transid AND bb.bettype = 33
		INNER JOIN @Runner h ON bb.matchid = h.orid
	WHERE
		--b.[status] NOT IN (N'void', N'reject', N'refund')
		b.statusID NOT IN (102,101,103)
		AND b.bettype IN (31,32)
	GROUP BY
		bb.currency, b.bettype


INSERT INTO @sum (currency, bettype, PartnerTurnOver, PartnerWinLost, PartnerComm, IBCWinLost, scomm)
	SELECT currency, 33, SUM(PartnerTurnOver), SUM(PartnerWinLost), SUM(PartnerComm), SUM(IBCWinLost), SUM(scomm)
	FROM @sumM
	GROUP BY currency


-- =================
-- DUMMY GEN & CHECK
-- v v v v v v v v v : below

	-- Get Dummy User Array
	DECLARE @Dummy TABLE ([type] tinyint, [desc] varchar(10), currency tinyint, username nvarchar(50), custid int, recommend int, mrecommend int, srecommend int, actualrate float, CurrencyName nvarchar(50))
	-- [type] 0:TurnOver 1:WinLost 2:CommSA 3:CommIBC 4:Comm3rd
	-- 5:IBCPos 6:PGIFee 7:AmtoteFee 8:TotalFee

	INSERT INTO @Dummy -- TurnOver for Horseracing
		SELECT 0, 'TurnOver', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'TO4HR' + e.currency

	INSERT INTO @Dummy -- Dividend Receivables for Horseracing
		SELECT 1, 'WinLost', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'DivRec4HR' + e.currency

	INSERT INTO @Dummy -- Commission Expense for Horseracing
		SELECT 2, 'CommSA', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommExp4HR' + e.currency

	INSERT INTO @Dummy -- Commission Income from Horseracing
		SELECT 3, 'CommIBC', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommIncFrHR' + e.currency

	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 4, 'Comm3rd', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'CommRecFrPhu' + e.currency

	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 5, 'IBCPos', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'WLFrPT' + e.currency

--	INSERT INTO @Dummy -- Commission Receivables from Phumelela
--		SELECT 6, 'PGIFee', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
--		FROM dbo.custinfo c with (nolock)
--			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
--		WHERE
--			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
--			c.username LIKE 'PGIFee' + e.currency
	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 7, 'AmtoteFee', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'AmtoteFee' + e.currency

	INSERT INTO @Dummy -- Commission Receivables from Phumelela
		SELECT 8, 'TotalFee', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency
		FROM dbo.custinfo c with (nolock)
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid
		WHERE
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND 
			c.username LIKE 'FeeDue2' + e.currency


-- Record Transfer Value  (gain -> winlost, paid -> actual_stake)
-- 0:TurnOver - TurnOver send to 3rd
-- 1:WinLost  - 3rd paid back to member (According to PositionTaking)
-- 2:CommSA   - ibc paid to agent      (balance with scomm)
-- 3:CommIBC  - ibc gain from 3rd
-- 4:Comm3rd  - 3rd paid to ibc
-- 5:IBCPos   - ibc winlost
-- 6,7,8:Fee

declare @dummyTrans table (custid int, actual_stake money, winlost money, bettype int)

INSERT INTO @dummyTrans (custid, actual_stake, winlost, bettype)
SELECT c.custid,
	CASE c.[type]
	    WHEN 0 THEN 0
	    WHEN 1 THEN s.PartnerWinLost
	    WHEN 2 THEN s.scomm
	    WHEN 3 THEN 0
	    WHEN 4 THEN s.PartnerComm
	    WHEN 5 THEN CASE WHEN s.IBCWinLost > 0 THEN  s.IBCWinLost ELSE 0 END
	    --WHEN 6 THEN 0
	    WHEN 7 THEN 0
	    WHEN 8 THEN @ToteFee * s.PartnerTurnOver
	END,
	CASE c.[type]
	    WHEN 0 THEN s.PartnerTurnOver
	    WHEN 1 THEN 0
	    WHEN 2 THEN 0
	    WHEN 3 THEN s.PartnerComm
	    WHEN 4 THEN 0
	    WHEN 5 THEN CASE WHEN s.IBCWinLost < 0 THEN -s.IBCWinLost ELSE 0 END
	    --WHEN 6 THEN 0
	    WHEN 7 THEN @ToteFee * s.PartnerTurnOver
	    WHEN 8 THEN 0
	END, s.bettype
	
FROM
	@sum AS s
	INNER JOIN @Dummy AS c ON s.currency = c.currency

UPDATE	b WITH (UPDLOCK, ROWLOCK)
SET		actual_stake = d.actual_stake,
		stake = d.actual_stake,	
		winlost = d.winlost
FROM	bettrans14 b
		INNER JOIN @dummyTrans d ON b.custid = d.custid AND b.bettype = d.bettype 
		INNER JOIN @Runner h ON b.matchid = h.orid

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdDummyTransfer_s151_14] TO [vnteam]