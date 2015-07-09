USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_ABMatchRemark_Ins]    Script Date: 10/29/2012 16:36:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_ABMatchRemark_Ins]
AS
/*
	Created: Johnson
	Date: 10Nov2011
	Task: Insert info of ABMatch_Remark
	DB: DB052.BODB02
	
	Revisions:
		- 20120315@Jamie: Optimize Search Match 
		- 20120613@Johnson: Optimize code
		- 20121029@Viet: revise SP
	Paramters Explanation:
*/
SET NOCOUNT ON
	DECLARE @currentDate DATETIME   
	SELECT @currentDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)	
	DECLARE @tmpBet TABLE(matchid INT, bettype smallint, transid BIGINT)

	INSERT INTO @tmpBet (matchid, bettype, transid)
	SELECT DISTINCT b.matchid, b.bettype, 0
	FROM bettrans b WITH(NOLOCK)
		INNER JOIN (SELECT TOP 1000 transid from ABTransaction with(nolock) order by transid desc
			) ab on b.transid = ab.transid
		LEFT JOIN ABMatch_Remark m with(nolock) on b.matchid = m.matchid and b.bettype = m.bettype
	WHERE b.matchid > 29
		AND b.bettype IN (1,7,3,8,5,15)		
		AND b.transdate >= @currentDate
		AND m.transid is NULL

	IF @@ROWCOUNT = 0 RETURN

	;WITH s AS (
		SELECT b.matchid, b.bettype, min(b.transid) as transid
		FROM bettrans b with(nolock)
			inner join @tmpBet t on t.matchid = b.matchid and t.bettype = b.bettype
		GROUP BY b.matchid, b.bettype
	)
	UPDATE d
	SET transid = s.transid
	FROM @tmpBet d
		INNER JOIN s on d.matchid = s.matchid and d.bettype = s.bettype

	INSERT INTO ABMatch_Remark (matchid, bettype, hdp , odds, transid)	
	SELECT 
		b.matchid, 
		b.bettype, 
		CASE WHEN b.bettype IN (1,7) THEN CASE WHEN betteam = 'h' THEN b.hdp2 - b.hdp1 ELSE b.hdp1 - b.hdp2 END
			WHEN b.bettype IN (5,15) THEN NULL 
			ELSE b.hdp1 END,
		b.odds, 
		b.transid
	FROM bettrans b WITH(NOLOCK)
	WHERE transID IN ( SELECT transID FROM @tmpBet)	

GO
GRANT VIEW DEFINITION ON [dbo].[Task_ABMatchRemark_Ins] TO [vnteam]