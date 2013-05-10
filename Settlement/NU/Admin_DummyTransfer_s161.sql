ALTER PROCEDURE [dbo].[Admin_DummyTransfer_s161]
	@matchid_ int
AS

Declare @matchid int
SET @matchid = @matchid_

-- Get List of involve Horse for this race.  
Declare @EventDate datetime
SELECT @EventDate = eventdate FROM dbo.match with (nolock)
WHERE matchid = @matchid
  
-- Get Summary Value for insert into Dummy A/C  
--DECLARE @sum TABLE (currency tinyint, bettype tinyint, IsPlaceRefund bit, stake money, winlost money, scomm money, CommRate smallmoney)  
DECLARE @sum  TABLE (currency tinyint, bettype tinyint, IBCWinLost money, scomm money, AgentWinLost money)  
INSERT INTO @sum (currency, bettype, IBCWinLost, scomm, AgentWinLost)  
	SELECT  
		b.currency, b.bettype,   
		SUM(winlost-actual_stake) IBCWinLost,  
		SUM(scomm),
		SUM(awinlost+mwinlost+swinlost) AgentWinLost
	FROM  
		dbo.bettrans b with (nolock)
	WHERE
		b.matchid = @matchid
		AND b.[statusID] NOT IN (101,102,103)
	GROUP BY  
		b.currency, b.bettype  
  
-- =================  
-- DUMMY GEN & CHECK  
-- v v v v v v v v v : below  
  
	-- Get Dummy User Array  
	DECLARE @Dummy TABLE ([type] tinyint, [desc] varchar(15), currency tinyint, username nvarchar(50), custid int, recommend int, mrecommend int, srecommend int, actualrate float, CurrencyName nvarchar(50))  
	-- [type] 1:WinLost 2:CommSA
  
	INSERT INTO @Dummy
		SELECT 1, 'WinLost', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency  
		FROM dbo.custinfo c with (nolock)  
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid  
		WHERE  
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND   
			c.username LIKE 'NUBET' + e.currency  
  
	INSERT INTO @Dummy
		SELECT 2, 'CommSA', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency  
		FROM dbo.custinfo c with (nolock)  
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid  
		WHERE  
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND   
			c.username LIKE 'NUBET' + e.currency  

	INSERT INTO @Dummy
		SELECT 3, 'AgentWinLost', c.currency, c.username, c.custid, c.recommend, c.mrecommend, c.srecommend, e.actualrate, e.currency  
		FROM dbo.custinfo c with (nolock)  
			INNER JOIN dbo.exchange e with (nolock) ON c.currency = e.exchangeid  
		WHERE  
			e.exchangeid IN (SELECT distinct currency FROM @sum) AND   
			c.username LIKE 'NUBET' + e.currency  
  

  
	-- Check for none-exists Dummy A/C for target currency  
	DECLARE @DummyCheck TABLE (currency tinyint)  
	INSERT INTO @DummyCheck  
	SELECT s.currency  
	FROM  
		(SELECT distinct currency FROM @sum) AS s  
		FULL JOIN @Dummy c ON s.currency = c.currency  
	GROUP BY s.currency  
	HAVING IsNull(count(*),0) < 3
  
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
-- 1:IBCWinLost - ibc paid back to member
-- 2:CommSA     - ibc paid to agent      (balance with scomm)  
-- 3:AgentWinlost (balance with awinlost+mwinlost+swinlost)
INSERT INTO bettrans (  
	custid, creator, recommend, mrecommend, srecommend, matchid, bettype, winlostdate, ruben, [status], statusID,  
	actual_stake,  
	stake,  
	winlost,  
	awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,  
	tpositiontaking, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount,  
	oddsid, betteam, hdp1, hdp2, odds, modds, betfrom, transdesc,  
	actualrate, virtualrate, currency, refno, username, currencyName  
	)

SELECT  
	c.custid, c.custid, c.recommend, c.mrecommend, c.srecommend, @matchid, s.bettype, @EventDate, 1, 'done', 121,  
	CASE c.[type]  
		WHEN 1 THEN CASE WHEN s.IBCWinLost > 0 THEN s.IBCWinLost ELSE 0 END
		WHEN 2 THEN s.scomm
		WHEN 3 THEN CASE WHEN s.AgentWinLost > 0 THEN s.AgentWinLost ELSE 0 END
	END,  
	CASE c.[type]  
		WHEN 1 THEN CASE WHEN s.IBCWinLost > 0 THEN s.IBCWinLost ELSE 0 END
		WHEN 2 THEN s.scomm
		WHEN 3 THEN CASE WHEN s.AgentWinLost > 0 THEN s.AgentWinLost ELSE 0 END
	END,  
	CASE c.[type]  
		WHEN 1 THEN CASE WHEN s.IBCWinLost < 0 THEN -s.IBCWinLost ELSE 0 END
		WHEN 2 THEN 0  
		WHEN 3 THEN CASE WHEN s.AgentWinLost < 0 THEN -s.AgentWinLost ELSE 0 END
	END,

	0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	@matchid, '0', 0, 0, 0, 0, 'i', 'NumberGames-Dummy ' + c.[desc] + ':' + CAST(@matchid as varchar(50)) + ':' + CAST(s.bettype as varchar(20)),
	c.actualrate, c.actualrate, c.currency, 100000000000, c.username, c.currencyName
FROM
	@sum AS s
	INNER JOIN @Dummy AS c ON s.currency = c.currency


GO
GRANT VIEW DEFINITION ON [dbo].[Admin_DummyTransfer_s161] TO [vnteam]