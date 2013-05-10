ALTER PROCEDURE [dbo].[Task_DailySummary_Verify]
	@winlostdate datetime,
	@TestMode tinyint = 1
AS

/*
Created by:Thien
Date: 20111018
Task: to verify the move bet process at tomorrow's mornings
DB: DB052.BODB02

 */

SET NOCOUNT ON

DECLARE @transid bigint
-- ====================
-- DATA VERIFICATION
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE	--[status] = 'running' 
			statusID = 0
			AND custid <> 0
			AND bettype <=19000 AND bettype <> 10 AND winlostdate <= @winlostdate
			AND currency <> 20
)
BEGIN
	SELECT DISTINCT matchid FROM bettrans (nolock)
	WHERE	winlostdate <= @winlostdate 
			--AND [status] = 'running'
			AND statusID = 0 
			AND bettype <=19000 and bettype NOT IN (9, 10, 29)

	SELECT DISTINCT 'EXEC matchname ' + CAST(bm.matchid as varchar(10)) matchid, m.eventdate, bm.matchid, ',' [Comma]
	FROM dbo.bettrans b (nolock)
		INNER JOIN dbo.bettransm bm (nolock) ON b.refno = bm.refno
		INNER JOIN dbo.match m (nolock) ON bm.matchid = m.matchid
	WHERE	b.winlostdate <= @winlostdate 
			--AND b.[status] = 'running' AND bm.[status] = 'running'
			AND b.statusID = 0 AND bm.statusID = 0 
			AND b.bettype in (9,29)
			--AND b.matchid = 0
			AND b.matchID in (9,29)
			AND b.currency <> 20
	ORDER BY m.eventdate

	IF @@ROWCOUNT > 0
	BEGIN
		PRINT '--'
		PRINT '--SELECT * FROM bettrans (nolock) WHERE status = ''running'' AND matchid IN (9,29) AND bettype IN (9,29) AND winlostdate <= ''' + CONVERT(varchar(10), @winlostdate, 120) + ''''
		PRINT '--UPDATE dbo.bettrans SET winlostdate = ''' + CONVERT(varchar(10), DATEADD(day,1,@winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
		PRINT '--'
	END

	RAISERROR ('FAILED: Have running tickets', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE srecommend <= 100 AND (scomm <> acomm OR swinlost <> 0)
	AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Incorrect Company SuperAgent setting', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE (scomm IS NULL OR acomm IS NULL OR comm IS NULL OR playercomm IS NULL
	OR swinlost IS NULL OR mwinlost IS NULL OR awinlost IS NULL OR winlost IS NULL)
	AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Null Commission/WinLost', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT currency
	FROM bettrans (nolock)
	WHERE bettype <=19000 AND winlostdate = @winlostdate
	GROUP BY currency
	HAVING COUNT(DISTINCT actualrate) > 1
)
BEGIN
	RAISERROR ('FAILED: Multiple Exchange Rate', 16, 1)
	RETURN
END
-- ====================

IF @TestMode = 1
BEGIN
	PRINT 'DATA OK'

	IF EXISTS (SELECT 1 FROM bettrans with (nolock)
		WHERE bettype = 10 
			--AND [status] = 'running'
			AND statusID = 0 
			AND winlostdate = @winlostdate)
		PRINT 'Some Outright need to moved : Run with parameter = 2'

	IF EXISTS (SELECT 1 FROM bettrans with (nolock)
		WHERE currency = 20
			AND winlostdate = @winlostdate
			AND bettype <=19000
			AND statusID = 0)
		PRINT 'Some TEST Ticket need to Refund : Run with parameter = 2'

	RETURN
END


GO
GRANT VIEW DEFINITION ON [dbo].[Task_DailySummary_Verify] TO [vnteam]