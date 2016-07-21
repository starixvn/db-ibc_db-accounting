USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_29_PreCal]    Script Date: 04/12/2016 15:38:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_29_PreCal]
	(@matchids VARCHAR(2000)) WITH RECOMPILE
AS
/*
	Created: Kathy
	Date: 20140213
	Task : generate sub-ticket for combination
	DB: DBTrans.bodb02
	Original: Admin_Calculate_29_PreCal

	Revisions:
		- 20141030@Jamie: Sporting Solution for Tennis [Redmine:#23034]
		- 20150506@Kathy: Do not calculate main ticket if subticket is still waiting or rejected [Redmine:#35336]
		- 20151210@Patrick: Database - Change datatype [Redmine: #48660]
		- 20160120@Patrick: PH-AiO - Change request [Redmine: #51116]
		- 20161204@Kathy: Review SP - Combo parlay [Redmine:#55270] 
		
	Param's Explanation:
	@matchid: matchid of match to be settled
*/
BEGIN
	IF @@SERVERNAME IN (N'DB042', 'DB044') RETURN

	-- GET List of refno concern for this match  
	--Declare @tmp_mrefno TABLE (refno bigint PRIMARY KEY CLUSTERED)  
	--INSERT INTO @tmp_mrefno (refno)
	--	SELECT refno FROM dbo.bettransm WITH (ROWLOCK) WHERE matchid = @matchid   
	CREATE TABLE #temp_bettrans  
	(
		[transid] [bigint] NOT NULL
		,[refno] [bigint] PRIMARY KEY CLUSTERED
		,[N] [tinyint] NOT NULL		-- total selection (match)
		,[bitmapR] [int] NOT NULL	-- bitmapR to identify which parlay set is choosen
		,[winlostdate] [smalldatetime] NOT NULL
		)
		-- GET list of concern Ticket
		;

	WITH refnos
	AS (
		SELECT DISTINCT bm.refno
		FROM dbo.bettransm bm WITH (ROWLOCK)
		WHERE bm.matchid IN (
				SELECT val
				FROM dbo.strSplit(@matchids, ',')
				)
		AND NOT EXISTS (SELECT 1 FROM bettransm WITH(NOLOCK) WHERE refno = bm.refno AND statusID IN(1, 101)) -- dont calculate main ticket if subticket is still waiting or rejected
		)
	--INSERT INTO @temp_bettrans 
	insert into #temp_bettrans
	(
		[transid]
		,[refno]
		,[N]
		,[bitmapR]
		,[winlostdate]
		)
	SELECT distinct [transid]
		,b.[refno]
		,hdp2
		,CAST(betteam as int)
		,winlostdate
	FROM dbo.bettrans b WITH (ROWLOCK)
	WHERE b.matchid = 29 AND statusID NOT IN (101, 102) --('VOID','REJECT')
		AND betid = 0 -- main ticket of combination
		AND refno in (select refno from refnos)

	-- delete record which already created Result/Detail
	DELETE T
	FROM #temp_bettrans T
		INNER JOIN dbo.BetParlayResult pr ON T.refno = pr.refno

	-- Results list from both bettransm & bettransm14 (for only needed Combination Ticket)
	--DECLARE @parlay_base TABLE 
	CREATE TABLE #parlay_base 
	(
		refno BIGINT
		,transid BIGINT
		,winlostdate SMALLDATETIME
		,statuswinlost TINYINT
		,statusid TINYINT
		,matchid INT
		,bettype SMALLINT
		,odds MONEY
		,betteam NVARCHAR(10)
		,hdp1 SMALLMONEY
		,hdp2 SMALLMONEY
		,livehomescore SMALLINT
		,liveawayscore SMALLINT
		,liveindicator BIT
		,SetStake money
		,betcheck NVARCHAR(50) 
		,transdesc NVARCHAR(200)
		,RN TINYINT		-- set No. for selection in the combination
		UNIQUE (refno, matchid)
		)

	--INSERT INTO @parlay_base 
	;WITH _source AS (
	SELECT bm.refno
		,bm.transid
		,bm.winlostdate
		,statuswinlost
		,statusid
		,matchid
		,bettype
		,odds
		,betteam
		,hdp1
		,hdp2
		,livehomescore
		,liveawayscore
		,liveindicator
		,stake AS SetStake
		,bm.betcheck
		,bm.transdesc --CASE WHEN bm.betteam = 'AOS' THEN bm.transdesc ELSE '' END AS transdesc
		,RN = ROW_NUMBER() OVER (PARTITION BY bm.refno ORDER BY bm.matchid)
	FROM
		#temp_bettrans tb
		INNER JOIN (
			SELECT * FROM dbo.bettransm WITH (ROWLOCK)
			UNION ALL
			SELECT * FROM dbo.bettransm14 WITH (ROWLOCK)
		) AS bm ON tb.refno = bm.refno
	)
	--
	INSERT INTO #parlay_base 
	(
		refno
		,transid
		,winlostdate
		,statuswinlost
		,statusid
		,matchid
		,bettype
		,odds
		,betteam
		,hdp1
		,hdp2
		,livehomescore
		,liveawayscore
		,liveindicator
		,SetStake
		,betcheck
		,transdesc
		,RN
		)
	SELECT * FROM _source


	-- stop if got some ticket  CNT value is not match
	IF EXISTS (
			SELECT 1
			FROM #temp_bettrans tb
				INNER JOIN
				(SELECT refno, count(*) cnt FROM #parlay_base GROUP BY refno) AS SUB ON tb.refno = SUB.refno
			WHERE sub.cnt <> tb.N
			)
	BEGIN
		PRINT 'ERROR cnt <> N'

		RETURN -1
	END

	-- insert information into parlayDetail/Result
	;WITH ParlayStake AS (SELECT refno, RN, setstake FROM #parlay_base)
	INSERT INTO dbo.BetParlayDetail (
		RefNo
		,Serial
		,transid
		,winlostdate
		,statuswinlost
		,statusid
		,matchid
		,bettype
		,stake
		,odds
		,betteam
		,hdp1
		,hdp2
		,livehomescore
		,liveawayscore
		,liveindicator
		,betcheck
		,transdesc
		)
	SELECT pb.RefNo
		,rc.Serial
		,pb.transid
		,pb.winlostdate
		,statuswinlost
		,statusid
		,matchid
		,bettype
		,ps.SetStake
		,odds
		,betteam
		,hdp1
		,hdp2
		,livehomescore
		,liveawayscore
		,liveindicator
		,pb.betcheck
		,pb.transdesc
	FROM #parlay_base pb
		INNER JOIN #temp_bettrans tb ON pb.refno = tb.refno
		INNER JOIN dbo.RefCombinationSet rcs ON tb.N = rcs.N AND (tb.bitmapR & rcs.bitmapR) > 0
		INNER JOIN dbo.RefCombination rc ON rcs.N = rc.N AND rcs.R = rc.R AND pb.RN = rc.seq
		INNER JOIN ParlayStake ps ON ps.refno = tb.refno AND ps.RN = rc.R

	INSERT INTO dbo.BetParlayResult (
		RefNo
		,Serial
		,transid
		,winlostdate
		,statusid
		,Stake
		,Odds
		,mOdds
		,winlost
		,awinlost
		,mwinlost
		,swinlost
		,playercomm
		,comm
		,acomm
		,scomm
		)
	SELECT DISTINCT tb.RefNo
		,pd.Serial
		,0
		,tb.winlostdate
		,0
		,pd.stake
		,0
		,0
		,0
		,0
		,0
		,0
		,0
		,0
		,0
		,0
	FROM #temp_bettrans tb
		INNER JOIN dbo.BetParlayDetail pd ON tb.refno = pd.refno
END

GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Calculate_29_PreCal] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_29_PreCal] TO [vnteam] AS [dbo]