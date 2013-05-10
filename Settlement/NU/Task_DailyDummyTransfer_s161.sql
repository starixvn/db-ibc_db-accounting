ALTER PROCEDURE [dbo].[Task_DailyDummyTransfer_s161]
	@date smalldatetime
AS

/*
	Created by: Viet
	Date: 17 Dec 2010
	Task: Transfer Dummy for number game (daily) 
	DB: DBO2.BODB02
	
	Revisions:		
		- 20110628@Viet: Deleted existed dummy transactions before adding
		- 20110711@Joe : add index hint CIX_matchid_bettype
		- 20110817@Viet: Expand numbergame's bettypes
		- 20120522@Lukas: from 2012-06-01 insert dummy balance into bettrans2 instead of bettrans
*/
IF @date < '2012-06-01'
BEGIN
	DELETE b
	FROM dbo.bettrans b WITH (INDEX=CIX_matchid_bettype)
		INNER JOIN dbo.match m with (nolock)
		ON b.matchid = m.matchid AND m.sporttype = 161 AND b.bettype = 81
	WHERE
		b.statusid = 121
	and b.winlostdate = @date
END	
	DELETE b
	FROM dbo.bettrans2 b WITH(ROWLOCK,UPDLOCK)
		INNER JOIN dbo.match m with (nolock)
		ON b.matchid = m.matchid AND m.sporttype = 161 AND b.bettype = 81
	WHERE
		b.statusid = 121
	and b.winlostdate = @date

Declare @matchid int
SELECT top 1 @matchid = b.matchid
FROM dbo.bettrans b with(nolock, INDEX=CIX_matchid_bettype)
	INNER JOIN dbo.match m with (nolock) ON b.matchid = m.matchid
where b.winlostdate = @date
	and b.bettype between 81 and 120
	and b.statusid in (111,112,113)

DECLARE @sum as TABLE (currency tinyint primary key, winlost money, username nvarchar(50), custid int, recommend int, mrecommend int, srecommend int, actualrate float, CurrencyName nvarchar(50))  

INSERT INTO @sum(currency, actualrate, currencyname, winlost)
SELECT currency,actualrate, currencyname,
	isnull(sum(winlost-actual_stake+scomm+awinlost+mwinlost+swinlost),0) winlost
FROM dbo.bettrans b with (rowlock, INDEX=CIX_matchid_bettype)
	inner join dbo.match m with(nolock) on b.matchid = m.matchid	
WHERE m.sporttype=161
	AND b.[statusID] NOT IN (101,102,103)
	and b.winlostdate = @date
GROUP BY b.currency,actualrate, currencyname

UPDATE s
	set username = c.username,
		custid = c.custid,
		recommend = c.recommend,
		mrecommend = c.mrecommend,
		srecommend = c.srecommend
FROM @sum s
	inner join custinfo c with (nolock) on s.currency = c.currency
WHERE c.username like 'NUBET' + currencyname
  
IF @date < '2012-06-01'
BEGIN
-- Record Transfer Value  (gain -> winlost, paid -> actual_stake)  
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
		custid, custid, recommend, mrecommend, srecommend, @matchid, 81, @date, 1, 'done', 121,  
		CASE WHEN winlost > 0 THEN winlost ELSE 0 END,  
		CASE WHEN winlost > 0 THEN winlost ELSE 0 END,  
		CASE WHEN winlost < 0 THEN -winlost ELSE 0 END,
		0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		@matchid, '0', 0, 0, 0, 0, 'i', 'NumberGames-Dummy transfer',
		actualrate, actualrate, currency, 100000000000, username, currencyName
	FROM @sum
END
	-- Record Transfer Value  (gain -> winlost, paid -> actual_stake)  
	INSERT INTO bettrans2 (  
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
		custid, custid, recommend, mrecommend, srecommend, @matchid, 81, @date, 1, 'done', 121,  
		CASE WHEN winlost > 0 THEN winlost ELSE 0 END,  
		CASE WHEN winlost > 0 THEN winlost ELSE 0 END,  
		CASE WHEN winlost < 0 THEN -winlost ELSE 0 END,
		0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		@matchid, '0', 0, 0, 0, 0, 'i', 'NumberGames-Dummy transfer',
		actualrate, actualrate, currency, 100000000000, username, currencyName
	FROM @sum



GO
GRANT EXECUTE ON [dbo].[Task_DailyDummyTransfer_s161] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_DailyDummyTransfer_s161] TO [vnteam]