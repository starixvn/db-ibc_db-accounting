ALTER PROCEDURE [dbo].[Task_DailySummary_Job]
AS
	Declare @WeekDay tinyint
	SET @WeekDay = DATEPART(weekday, CURRENT_TIMESTAMP)

	Declare @Todaym1 datetime, @Todaym2 datetime, @Todaym3 datetime, @Todaym4 datetime
	SET @Todaym1 = DATEADD(day, -1, CONVERT(varchar(10), CURRENT_TIMESTAMP, 120))
	SET @Todaym2 = DATEADD(day, -1, @Todaym1)
	SET @Todaym3 = DATEADD(day, -1, @Todaym2)
	SET @Todaym4 = DATEADD(day, -1, @Todaym3)

	-- Server Time : Monday (2)
	-- Local Time  : Tuesday's morning
	--IF @WeekDay = 2
	--BEGIN
		
	--END
	-- Server Time : Tuesday (3)
	-- Local Time  : Wednesday's morning
	IF @WeekDay = 3
	BEGIN
		EXEC dbo.Task_DailySummary @Todaym4 -- Friday
		EXEC dbo.Task_DailySummary @Todaym3 -- Saturday
	END
	-- Server Time : Wednesday (4)
	-- Local Time  : Thursday's morning
	ELSE IF @WeekDay = 4
	BEGIN
		EXEC dbo.Task_DailySummary @Todaym3 -- Sunday
		EXEC dbo.Task_DailySummary @Todaym2 -- Monday
	END
	-- Server Time : Friday (6)
	-- Local Time  : Saturday's morning
	ELSE IF @WeekDay = 6
	BEGIN
		EXEC dbo.Task_DailySummary @Todaym3 -- Tuesday
		EXEC dbo.Task_DailySummary @Todaym2 -- Wednesday
		EXEC dbo.Task_DailySummary @Todaym1 -- Thursday
	END

	ELSE
	BEGIN
		RETURN -1
	END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_DailySummary_Job] TO [vnteam]