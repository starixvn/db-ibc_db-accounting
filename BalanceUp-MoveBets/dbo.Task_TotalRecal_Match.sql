ALTER PROCEDURE [dbo].[Task_TotalRecal_Match]
	@matchid int,
	@bettype tinyint
AS
--DB02
SET NOCOUNT ON

Declare @Total TABLE (oddsid int PRIMARY KEY, HomeTotal money, AwayTotal money)

INSERT INTO @Total
SELECT 
	oddsid,
	SUM(case when betteam='h' then (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * b.virtualrate * (1-b.tpositiontaking)) else 0 end) homeTotal,
	SUM(case when betteam='a' then (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * b.virtualrate * (1-b.tpositiontaking)) else 0 end) awayTotal
FROM bettrans b with (nolock)
	--INNER JOIN exchange e with (nolock) ON b.currency = e.exchangeid
WHERE matchid = @matchid AND bettype = @bettype
	--AND [status] NOT IN ('VOID','REJECT') --and ruben = 0
	AND statusID NOT IN (101,102)
GROUP BY oddsid

UPDATE odds with (updlock)
SET hometotal = IsNull(t.HomeTotal, 0), awaytotal = IsNull(t.AwayTotal, 0)
FROM odds FULL OUTER JOIN @Total t ON odds.oddsid = t.oddsid 
WHERE
	odds.bettype = @bettype
	AND odds.matchid = @matchid

SET NOCOUNT OFF

GO
GRANT VIEW DEFINITION ON [dbo].[Task_TotalRecal_Match] TO [vnteam]