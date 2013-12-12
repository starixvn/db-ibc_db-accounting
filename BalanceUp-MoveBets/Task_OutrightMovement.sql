ALTER PROCEDURE [dbo].[Task_OutrightMovement]	
AS

/*
	Created by: [Viet]
	Date:
	Task: daily outright movement
	DB: DBTRANS.BODB02
	Revisions:
        - 20131108@Elodie: Splitting bodb02 into CustDB (call exchange by link database)	
*/

SET NOCOUNT ON

	declare @winlostdate datetime
	select @winlostdate = DATEADD(dd, DATEDIFF(dd, 0, CURRENT_TIMESTAMP), 0)

	IF DATEPART(HOUR, CURRENT_TIMESTAMP) < 4 RETURN
		--SELECT @winlostdate = DATEADD(day, -1, @winlostdate)
		
	Declare @outright TABLE (orid int)

	INSERT INTO @outright 
	SELECT distinct matchid FROM bettrans with(nolock)
	WHERE bettype = 10 
		AND statusID = 0 
		AND winlostdate < @winlostdate

	IF @@ROWCOUNT = 0 RETURN
			
	UPDATE O
	SET eventdate = @winlostdate, changeTime = CURRENT_TIMESTAMP
	FROM DB02.bodb02.dbo.outright O WITH (UPDLOCK, ROWLOCK)
	WHERE orid IN (SELECT orid FROM @outright)

	UPDATE b
	SET winlostdate = @winlostdate
		,actualrate = e.actualrate
	FROM bettrans b WITH(UPDLOCK, ROWLOCK) 
		inner join CustDB.dbo.exchange e with(nolock) on b.currency = e.exchangeid	
	WHERE bettype = 10 AND matchid IN (SELECT orid FROM @outright)

	DECLARE @Doing varchar(4000)
	SET @Doing = '[Task_OutrightMovement] - Moving eventdate for outright: ' + 
	STUFF((
		SELECT ',' + cast(orid as varchar(12)) 
		FROM @outright 
		FOR XML PATH('')
	), 1,1,'')

	EXEC dbo.WriteLog_UserLog @UserID = 862400, @Doing = @Doing 
 


GO
GRANT VIEW DEFINITION ON [dbo].[Task_OutrightMovement] TO [vnteam] AS [dbo]