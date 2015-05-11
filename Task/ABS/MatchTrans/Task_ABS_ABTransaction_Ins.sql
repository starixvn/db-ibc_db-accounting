USE [bodb_ABS]
GO
/****** Object:  StoredProcedure [dbo].[Task_ABS_ABTransaction_Ins]    Script Date: 12/17/2012 02:50:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_ABS_ABTransaction_Ins]
AS
/*
	Created: Viet
	Date: 20121030
	Task: Insert data to ABTransaction and ABMatch_Remark
	DB: DB052.bodb_abs
	
	Revisions:
		- 20121227@Johnson: get betteam for ABMatch_remark
	Paramters Explanation:
*/
SET NOCOUNT ON	
	declare @smallID BIGINT, @maxtransID bigint, @currentDate DATETIME
	-- scan each transid twice to prevent missing by locking
	SELECT @smallID = cast(isnull(vvalue,0) as bigint)
	FROM ABSettings with(rowlock) 
	WHERE vname = 'ABTransaction'	
		
	SELECT @maxtransID = max(transid) FROM bodb02.dbo.bettrans with(nolock) 
			  
	UPDATE ABSettings with(rowlock, updlock)
	SET vvalue = vvalue2
		,vvalue2 = cast(@maxtransID as varchar(200))
	WHERE vname = 'ABTransaction'
			
	DECLARE @tempTransaction as TABLE(transid bigint, punterid int, custid int, matchid int, bettype smallint, transdate datetime)
	DECLARE @tempMatch as TABLE(matchid INT, bettype smallint, transid BIGINT)			  
	
	INSERT INTO @tempTransaction(transid, punterid, custid, matchid, bettype, transdate)
	SELECT b.transid, ab.punterid , ab.custid, b.matchid, b.bettype, b.transdate
	FROM dbo.ABPunterCode p WITH(NOLOCK)
		INNER JOIN dbo.ABCustomer ab WITH(NOLOCK) ON p.punterid = ab.punterid
		INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK, INDEX=IXU_transid) ON ab.custid = b.custid
		INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
	WHERE p.enabled = 1
		AND b.transid between @smallID and @maxtransID
		AND b.bettype IN (1,3,5,7,8,15)
		AND m.sporttype = 1

	SELECT @currentDate = DATEADD(dd, DATEDIFF(dd, 0, CURRENT_TIMESTAMP), 0)
	
	INSERT INTO dbo.ABTransaction (transid, punterid, custid, matchid, bettype)
	SELECT transid, punterid, custid, matchid, bettype
	FROM @tempTransaction
	WHERE transid not in (	-- exclude existed rows in ABTransaction
					select transid 
					from dbo.ABTransaction with(rowlock)
					where transid >= @smallID
				)
	
	IF @@ROWCOUNT = 0 RETURN
	

	INSERT INTO @tempMatch(matchid, bettype, transid)
	SELECT DISTINCT b.matchid, b.bettype, 0
	FROM @tempTransaction b
		LEFT JOIN dbo.ABMatch_Remark m with(nolock) on b.matchid = m.matchid and b.bettype = m.bettype
	WHERE b.transdate >= @currentDate
		AND m.transid is NULL
		
	IF @@ROWCOUNT = 0 RETURN		
	
	;WITH s AS (
		SELECT b.matchid, b.bettype, min(b.transid) as transid
		FROM bodb02.dbo.bettrans b with(nolock)
			inner join @tempMatch t on t.matchid = b.matchid and t.bettype = b.bettype
		GROUP BY b.matchid, b.bettype
	)
	UPDATE d
	SET transid = s.transid
	FROM @tempMatch d
		INNER JOIN s on d.matchid = s.matchid and d.bettype = s.bettype
		
	INSERT INTO dbo.ABMatch_remark(matchid,bettype,hdp,odds,transid,betteam)
	SELECT 
		b.matchid, 
		b.bettype, 
		CASE WHEN b.bettype IN (1,7) THEN CASE WHEN betteam = 'h' THEN b.hdp2 - b.hdp1 ELSE b.hdp1 - b.hdp2 END
			WHEN b.bettype IN (5,15) THEN NULL 
			ELSE b.hdp1 END,
		b.odds, 
		b.transid,
		b.betteam
	FROM bodb02.dbo.bettrans b WITH(NOLOCK)
	WHERE transID IN (SELECT transID FROM @tempMatch)
	

SET NOCOUNT OFF	
