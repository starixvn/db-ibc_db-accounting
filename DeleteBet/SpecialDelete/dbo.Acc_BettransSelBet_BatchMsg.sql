USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Acc_BettransSelBet_BatchMsg]    Script Date: 06/15/2015 09:09:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_BettransSelBet_BatchMsg] (
	@transids VARCHAR(MAX)
) 
AS
/*  
    Created by: Daniel  
 Date:   
 Original: DBA_SelBet_BatchMsg  
 Task: Select batch msg  
 DB: DBACC/BODB02  
  
 History:  
  - 20100823@Khoa: add more @transids  
  - 20101007@Henry: Change column transid from INT to BIGINT  
  - 20140224@Elodie: Apply LAS system [Redmine:#10701]  
  - 20150403@Kathy: Support uploading msg for ticket has been moved in bettrans14
  - 20150615@Dominic: Exclude 3 sub-tickets of BetTrade (901,902,903)  
  - 20150625@Dominic: Add ticket from translog/translog14 [Redmine:#38200]  
  - 20160317@bobby.nguyen: #54218 - Upload bacth message enhancement
  
 Explanation's Param:  
  
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @InvalidTransID 	VARCHAR(MAX)
	
	CREATE TABLE #transidList (transid BIGINT)

	CREATE TABLE #BettypeMatrix (
		[ProductID]		[TINYINT]
		,[Bettype]		[SMALLINT]
		,[EventType]	[TINYINT]
		,[SubProduct]	[VARCHAR](500)
	)
	
	CREATE TABLE #BetDelete  (
		transid BIGINT
		, refno BIGINT
		, bettype SMALLINT
		, custid INT
		, recommend INT
		, mrecommend INT
		, srecommend INT
		, betfrom NVARCHAR(1)
	)
	
	

	INSERT INTO #transidList
	SELECT DISTINCT (CONVERT(BIGINT, val))
	FROM dbo.strSplit(@transids, ',')

	-- Gather BettypeMatrix
	INSERT INTO #BettypeMatrix
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5
		
	INSERT INTO #BetDelete (
		transid
		, refno
		, bettype
		, custid
		, recommend
		, mrecommend
		, srecommend
		, betfrom
	)
	-- search by translog.translogid just running tickets
	/*	
		- Keno			: ProductId = 8
		- Gold Deluxe	: ProductId = 12
		- Colossus Bet	: ProductId = 15
		- Cockfighting	: ProductId = 19
		- SB - MG		: SubProduct = MG-SuperLive
	*/
	SELECT b.translogid
		, b.translogid
		, b.gameid
		, b.custid
		, b.recommend
		, b.mrecommend
		, b.srecommend
		, b.betfrom
	FROM dbo.translog AS b WITH (NOLOCK)
		INNER JOIN #transidList t 
		ON b.translogid	= t.transid
		INNER JOIN #BettypeMatrix bt
		ON b.gameid 	= bt.bettype
		
	WHERE b.statusid			IN (0, 1)
		AND (bt.ProductId 		IN (8, 12, 15, 19)
			OR bt.SubProduct 	IN ('MG-SuperLive') 		
		)
		
	-- search by bettrans.transid -> all status
	UNION ALL 
	SELECT 
		b.transid
		, b.refno
		, b.bettype
		, b.custid
		, b.recommend
		, b.mrecommend
		, b.srecommend
		, b.betfrom
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN #transidList t 
		ON b.transid 	= t.transid
		INNER JOIN #BettypeMatrix bt
		ON b.bettype 	= bt.bettype
		
	WHERE bt.ProductId 		NOT IN (8, 12, 15, 19)
		AND bt.SubProduct 	NOT IN ('MG-SuperLive')
		AND bt.Bettype 		NOT IN (901, 902, 903)
		
	-- search by bettrans.refno -> just settled tickets
	UNION ALL 
	SELECT 
		b.transid
		, b.refno
		, b.bettype
		, b.custid
		, b.recommend
		, b.mrecommend
		, b.srecommend
		, b.betfrom
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN dbo.translog tl WITH(NOLOCK)
		ON b.custid 	= tl.custid
			AND b.refno = tl.translogid
		INNER JOIN #transidList t 
		ON tl.translogid = t.transid
		INNER JOIN #BettypeMatrix bt
		ON b.bettype 	= bt.bettype
		
	WHERE bt.ProductId 		IN (8, 12, 15, 19)
		AND bt.SubProduct 	IN ('MG-SuperLive')
		AND tl.statusid		NOT IN (0, 1)
		
	-- search by bettrans14.transid
	UNION ALL 
	SELECT 
		b.transid
		, b.refno
		, b.bettype
		, b.custid
		, b.recommend
		, b.mrecommend
		, b.srecommend
		, b.betfrom
	FROM bettrans14 b WITH (NOLOCK)
		INNER JOIN #transidList t 
		ON b.transid = t.transid
		INNER JOIN #BettypeMatrix bt
		ON b.bettype 	= bt.bettype
		
	WHERE bt.ProductId 		NOT IN (8, 12, 15, 19)
		AND bt.SubProduct 	NOT IN ('MG-SuperLive')
		AND bt.Bettype 		NOT IN (901, 902, 903)
	
	-- search by bettrans14.refno
	UNION ALL 
	SELECT 
		b.transid
		, b.refno
		, b.bettype
		, b.custid
		, b.recommend
		, b.mrecommend
		, b.srecommend
		, b.betfrom
	FROM dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN dbo.translog14 tl WITH(NOLOCK)
		ON b.custid 	= tl.custid
			AND b.refno = tl.translogid
		INNER JOIN #transidList t 
		ON tl.translogid = t.transid
		INNER JOIN #BettypeMatrix bt
		ON b.bettype 	= bt.bettype
		
	WHERE bt.ProductId 		IN (8, 12, 15, 19)
		AND bt.SubProduct 	IN ('MG-SuperLive')
		
	-- search by bettransLC.transid
	/*
		- AG Casino			: ProductId = 11
		- AllBet			: ProductId = 21
	*/
	UNION ALL
	SELECT b.transid
		, b.RefNo
		, b.gameid
		, b.custid
		, b.recommend
		, b.mrecommend
		, b.srecommend
		, b.betfrom
	FROM dbo.bettransLC b WITH (NOLOCK)
		INNER JOIN #transidList t 
		ON b.transid 		= t.transid
		INNER JOIN #BettypeMatrix bt
		ON b.gameid 		= bt.bettype
		
	WHERE bt.ProductId IN (11, 21)
	
	UNION ALL
	SELECT b.transid
		, b.RefNo
		, b.gameid
		, b.custid
		, b.recommend
		, b.mrecommend
		, b.srecommend
		, b.betfrom
	FROM dbo.bettransLC14 b WITH (NOLOCK)
		INNER JOIN #transidList t 
		ON b.transid 		= t.transid
		INNER JOIN #BettypeMatrix bt
		ON b.gameid 		= bt.bettype
		
	WHERE bt.ProductId IN (11, 21)
	
	-- search by bettransRNG.transid
	/*	
		- OneRNG Casino			: ProductId = 6
		- Microgaming - LC		: ProductId = 13
		- Microgaming - RNG		: ProductId = 17
	*/
	UNION ALL
	SELECT b.transid
		, b.RefNo
		, b.gameid
		, b.custid
		, b.recommend
		, b.mrecommend
		, b.srecommend
		, b.betfrom
	FROM dbo.bettransRNG b WITH (NOLOCK)
		INNER JOIN #transidList t 
		ON b.transid 		= t.transid
		INNER JOIN #BettypeMatrix bt
		ON b.gameid 		= bt.bettype
		
	WHERE bt.ProductId IN (6, 13, 17)
	
	UNION ALL
	SELECT b.transid
		, b.RefNo
		, b.gameid
		, b.custid
		, b.recommend
		, b.mrecommend
		, b.srecommend
		, b.betfrom
	FROM dbo.bettransRNG14 b WITH (NOLOCK)
		INNER JOIN #transidList t 
		ON b.transid 		= t.transid
		INNER JOIN #BettypeMatrix bt
		ON b.gameid 		= bt.bettype
		
	WHERE bt.ProductId IN (6, 13, 17)
	
	;WITH CTE_CustInfo AS 
	(
		SELECT DISTINCT ct.custid, ci.username
		FROM #BetDelete bd
			CROSS APPLY (
				VALUES(custid)
				,(recommend)
				,(mrecommend)
				,(srecommend)
			) ct (custid)
			INNER JOIN dbo.custinfo ci WITH(NOLOCK)
			ON ct.custid = ci.custid
	)
	SELECT bd.transid
		, bd.custid
		, mem.UserName AS CustUserName
		, bd.recommend
		, ag.UserName AS AgUserName
		, bd.mrecommend
		, mag.UserName AS MagUserName
		, bd.srecommend
		, sag.Username AS SagUserName
	FROM #BetDelete bd
		INNER JOIN CTE_CustInfo mem 
			ON bd.custid = mem.custid
		INNER JOIN CTE_CustInfo ag 
			ON bd.recommend = ag.custid
		INNER JOIN CTE_CustInfo mag 
			ON bd.mrecommend = mag.custid
		INNER JOIN CTE_CustInfo sag
			ON bd.srecommend = sag.custid
	
	--Gte invalid transids
	SELECT @InvalidTransID = COALESCE(@InvalidTransID + '^', '') + CAST(b.transid AS VARCHAR(20))
	FROM #transidList b
		LEFT JOIN #BetDelete bd
		ON b.transid = bd.transid
	WHERE bd.transid IS NULL

	SELECT @InvalidTransID AS InvalidTransID
	
	RETURN
END
GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelBet_BatchMsg] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelBet_BatchMsg] TO [vnteam] AS [dbo]
GO

