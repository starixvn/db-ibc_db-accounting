 CREATE PROCEDURE dbo.ReGen_BetParlay
	@transid bigint,
	@betid bigint,
	@refno bigint
AS
/*
	Created by: Joe
	Date: 201108
	Task: re-generate the result and detail info for system parlay
	DB: DB06.BODB_archive
	Original: 
	
	Revisions: 	
*/

/*
must create these temptable before call this sp

CREATE TABLE #betParlayDetail (
	RefNo bigint, Serial int, transid int, winlostdate smalldatetime,
	statuswinlost tinyint, statusid tinyint,
	matchid int, bettype smallint, stake money, odds smallmoney, betteam nvarchar(10),
	hdp1 smallmoney, hdp2 smallmoney,
	livehomescore smallint, liveawayscore smallint, liveindicator bit
	--, CONSTRAINT [CIX_BetParlayDetail] PRIMARY KEY CLUSTERED ( [RefNo], [Serial], [MatchID] )
)

CREATE TABLE #betParlayResult (
	RefNo bigint, Serial int, winlostdate smalldatetime,
	statusid tinyint, stake money, Odds money, mOdds money,
	winlost money, awinlost money, mwinlost money, swinlost money,
	playercomm money, comm money, acomm money, scomm money
	--, CONSTRAINT [CIX_BetParlayResult] PRIMARY KEY CLUSTERED ( [RefNo], [Serial] )
)


*/
-- betid = 0 : main ticket
-- betid > 0 : sub-ticket
IF @betid > 0 SET @transid = @betid

Declare @temp_bettrans TABLE (
		transid bigint, refno bigint PRIMARY KEY, stake money, N tinyint, cnt smallint, bitmap smallint, winlostdate smalldatetime, 
		apositiontaking smallmoney, mpositiontaking smallmoney, spositiontaking smallmoney,
		playerdiscount decimal(9,8), discount decimal(9,8), adiscount decimal(9,8), sdiscount decimal(9,8),
		UNIQUE (transid)
	)
INSERT INTO @temp_bettrans
SELECT
	transid, refno, stake, LEN(betteam) AS N, CAST(hdp1 as smallint) AS cnt, CAST(hdp2 as smallint) AS bitmap, winlostdate,
	apositiontaking, mpositiontaking, spositiontaking,
	playerdiscount, discount, adiscount, sdiscount
FROM
	dbo.bettrans_bk with (nolock)
WHERE
	transid = @transid

Declare @stake money
SELECT @stake = stake/cnt FROM @temp_bettrans

-- Results list from both bettransm & bettransm14 (for only needed Combination Ticket)
Declare @parlay_base TABLE (
		refno bigint, transid int, winlostdate smalldatetime, statuswinlost tinyint, statusid tinyint,
		matchid int, bettype smallint, odds smallmoney, betteam nvarchar(10), hdp1 smallmoney, hdp2 smallmoney,
		livehomescore smallint, liveawayscore smallint, liveindicator bit,
		RN tinyint, -- set No. for selection in the combination
		CNT tinyint, -- total selection count, base on bettransm/14
		bCNT tinyint -- total selection count, stored in bettrans
		UNIQUE (refno, matchid)
	)

INSERT INTO @parlay_base (
	refno, transid, winlostdate, statuswinlost, statusid,
	matchid, bettype, odds, betteam, hdp1, hdp2,
	livehomescore, liveawayscore, liveindicator
	)
	SELECT bm.refno, bm.transid, bm.winlostdate, statuswinlost, statusid,
	matchid, bettype, odds, betteam, hdp1, hdp2,
	livehomescore, liveawayscore, liveindicator
	FROM dbo.bettransm bm with (rowlock)
	WHERE refno = @refno

-- prepare Seq of each refno
;WITH sub AS (SELECT ROW_NUMBER() OVER (PARTITION BY refno ORDER BY matchid) RN, refno, matchid FROM @parlay_base)
UPDATE pb
SET RN = sub.RN
FROM sub
INNER JOIN @parlay_base pb ON sub.refno = pb.refno AND sub.matchid = pb.matchid


-- prepare N
;WITH sub AS (SELECT refno, count(*) cnt FROM @parlay_base GROUP BY refno)
UPDATE pb
SET CNT = sub.cnt, bCNT = t.N
FROM sub
INNER JOIN @parlay_base pb ON sub.refno = pb.refno
INNER JOIN @temp_bettrans t ON t.refno = pb.refno

-- stop if got some ticket  CNT value is not match
IF EXISTS (SELECT * FROM @parlay_base WHERE CNT <> bCNT)
BEGIN
	PRINT 'ERROR cnt <> bcnt'
	RETURN -1
END

-- insert information into parlayDetail/Result
INSERT INTO #BetParlayDetail
	(RefNo, Serial, transid, winlostdate, statuswinlost, statusid, 
	matchid, bettype, stake, odds, betteam, hdp1, hdp2,
	livehomescore, liveawayscore, liveindicator)
SELECT 
	pb.RefNo, rc.Serial, pb.transid, pb.winlostdate, statuswinlost, statusid, 
	matchid, bettype, @stake, odds, betteam, hdp1, hdp2,
	livehomescore, liveawayscore, liveindicator
FROM
	@parlay_base pb
	INNER JOIN @temp_bettrans tb ON pb.refno = tb.refno
	INNER JOIN bodb02.dbo.RefCombination rc with (nolock) ON pb.RN = rc.seq AND pb.CNT = rc.N AND (tb.bitmap&rc.bitmap) > 0

INSERT INTO #BetParlayResult
(RefNo, Serial, winlostdate, statusid, Stake, Odds, mOdds,
winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm)
SELECT
	PR.refno, Serial, PR.winlostdate, statusID, @stake, PR.odds, PR.modds,
	CASE
		WHEN statusID = 0 THEN 0
		ELSE @stake * mOdds
		END,
	CASE 
		WHEN mOdds = 0  THEN  @stake * apositiontaking
		WHEN mOdds <> 1 THEN -@stake * apositiontaking*(mOdds-1)
		ELSE 0
		END,
	CASE
		WHEN mOdds = 0  THEN  @stake * mpositiontaking
		WHEN mOdds <> 1 THEN -@stake * mpositiontaking*(mOdds-1)
		ELSE 0
		END,
	CASE
		WHEN mOdds = 0  THEN  @stake * spositiontaking 
		WHEN mOdds <> 1 THEN -@stake * spositiontaking*(mOdds-1)
		ELSE 0
		END,

	CASE WHEN statusID IN (112,113) THEN @stake * playerdiscount	ELSE 0 END,
	CASE WHEN statusID IN (112,113) THEN @stake * discount *(1-apositiontaking)	ELSE 0 END,  
	CASE WHEN statusID IN (112,113) THEN @stake * adiscount*(1-apositiontaking-mpositiontaking)	ELSE 0 END,  
	CASE WHEN statusID IN (112,113) THEN @stake * sdiscount*(1-apositiontaking-mpositiontaking-spositiontaking)	ELSE 0 END
FROM
	@temp_bettrans tb
	INNER JOIN dbo.betParlayResult_Archive PR ON tb.refno = PR.refno
	
	
GO
GRANT EXECUTE ON [dbo].[ReGen_BetParlay] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[ReGen_BetParlay] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[ReGen_BetParlay] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[ReGen_BetParlay] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[ReGen_BetParlay] TO [vnteam] 
