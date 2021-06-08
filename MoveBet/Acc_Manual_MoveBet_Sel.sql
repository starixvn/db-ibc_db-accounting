/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  dbo.Acc_Manual_MoveBet_Sel
	@FromDate    SMALLDATETIME = NULL,
	@ToDate      SMALLDATETIME = NULL,
	@IsDefault	 BIT 

AS

/*
Created: 20210204@Danny
Task :  NAP Manage MoveBet select
DB: DBTXN-bodb02
Original:

	Revisions:
		- 20210204@Danny: Initialize SP [Redmine: #150053]

	Param's Explanation:
	- @FromDate	: User input in UI
	- @ToDate	: User input in UI
		
	EXEC Acc_Manual_MoveBet_Sel @IsDefault = 1
*/

BEGIN
    SET NOCOUNT ON

	-- Default MB schedule
	 CREATE TABLE #DefaultMovebetConfig
	 (
		_weekDay SmallInt, 
		IsBackDay1 BIT,  
		IsBackDay2 BIT,
		IsBackDay3 BIT,
		IsBackDay4 BIT,
		IsBackDay5 BIT,
		IsBackDay6 BIT,
		IsBackDay7 BIT,   
	)

	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (1, 0, 0, 0,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (2, 0, 0, 1,1,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (3, 0, 0, 1,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (4, 0, 0, 1,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (5, 0, 0, 0,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (6, 0, 0, 1,1,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (7, 0, 0, 1,0,0,0,0)
	--End  Default MB schedule


	IF @IsDefault = 1 
	BEGIN
		SELECT
				t._weekDay  
				,t.IsBackDay1 
				,t.IsBackDay2 
				,t.IsBackDay3 
				,t.IsBackDay4
				,t.IsBackDay5
				,t.IsBackDay6
				,t.IsBackDay7
	from		#DefaultMovebetConfig t
	END
	ELSE
	BEGIN


		DECLARE @calendarTable TABLE (scheduleDate smalldatetime, weekday_ tinyint)

		;WITH CTE_Winlostdate (winlostdate ) AS
		(
			SELECT @FromDate AS winlostdate
			UNION ALL
			SELECT DATEADD(DAY, 1, winlostdate)
			FROM CTE_Winlostdate
			WHERE winlostdate < @ToDate
		)
		INSERT INTO @calendarTable(scheduleDate, weekday_)
		select  winlostdate, DATEPART(WEEKDAY, winlostdate) from CTE_Winlostdate
		OPTION (MAXRECURSION 0)


		select		t.scheduleDate  
					,t.weekday_  
					,IsBackDay1 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay1 ELSE dc.IsBackDay1 END
					,IsBackDay2 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay2 ELSE dc.IsBackDay2 END
					,IsBackDay3 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay3 ELSE dc.IsBackDay3 END
					,IsBackDay4 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay4 ELSE dc.IsBackDay4 END
					,IsBackDay5 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay5 ELSE dc.IsBackDay5 END
					,IsBackDay6 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay6 ELSE dc.IsBackDay6 END
					,IsBackDay7 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.IsBackDay7 ELSE dc.IsBackDay7 END
		from		@calendarTable t
		left join	#DefaultMovebetConfig dc ON dc._weekDay = t.weekday_
		left join	dbo.Acc_ManualMovebetConfig mc ON t.scheduleDate = mc.MBDate

		DROP TABLE #DefaultMovebetConfig

	END

END

