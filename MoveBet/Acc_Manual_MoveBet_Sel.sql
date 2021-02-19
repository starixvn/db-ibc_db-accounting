/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  dbo.Acc_Manual_MoveBet_Sel
	@FromDate    SMALLDATETIME = NULL,
	@ToDate      SMALLDATETIME = NULL,
	@IsDefault	 BIT 

AS

/*
Created: 20210204@Danny
Task :  NAP Manage MoveBet select
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20210204@Danny: Initialize SP [Redmine: #150053]
		
*/

BEGIN
    SET NOCOUNT ON

	-- Default MB schedule
	 CREATE TABLE #DefaultMovebetConfig
	 (
		_weekDay SmallInt, 
		Isbackday1 BIT,  
		Isbackday2 BIT,
		Isbackday3 BIT,
		Isbackday4 BIT,
		Isbackday5 BIT,
		Isbackday6 BIT,
		Isbackday7 BIT,   
	)

	Insert into #DefaultMovebetConfig(_weekDay,Isbackday1, Isbackday2, Isbackday3,Isbackday4, Isbackday5,Isbackday6,Isbackday7)  VALUES (1, 0, 0, 0,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,Isbackday1, Isbackday2, Isbackday3,Isbackday4, Isbackday5,Isbackday6,Isbackday7)  VALUES (2, 0, 0, 1,1,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,Isbackday1, Isbackday2, Isbackday3,Isbackday4, Isbackday5,Isbackday6,Isbackday7)  VALUES (3, 0, 0, 1,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,Isbackday1, Isbackday2, Isbackday3,Isbackday4, Isbackday5,Isbackday6,Isbackday7)  VALUES (4, 0, 0, 1,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,Isbackday1, Isbackday2, Isbackday3,Isbackday4, Isbackday5,Isbackday6,Isbackday7)  VALUES (5, 0, 0, 0,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,Isbackday1, Isbackday2, Isbackday3,Isbackday4, Isbackday5,Isbackday6,Isbackday7)  VALUES (6, 0, 0, 1,1,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,Isbackday1, Isbackday2, Isbackday3,Isbackday4, Isbackday5,Isbackday6,Isbackday7)  VALUES (7, 0, 0, 1,0,0,0,0)
	--End  Default MB schedule


	IF @IsDefault = 1 
	BEGIN
		SELECT
				t._weekDay  
				,t.Isbackday1 
				,t.Isbackday2 
				,t.Isbackday3 
				,t.Isbackday4
				,t.Isbackday5
				,t.Isbackday6
				,t.Isbackday7
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
					,Isbackday1 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday1 ELSE dc.Isbackday1 END
					,Isbackday2 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday2 ELSE dc.Isbackday2 END
					,Isbackday3 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday3 ELSE dc.Isbackday3 END
					,Isbackday4 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday4 ELSE dc.Isbackday4 END
					,Isbackday5 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday5 ELSE dc.Isbackday5 END
					,Isbackday6 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday6 ELSE dc.Isbackday6 END
					,Isbackday7 = CASE WHEN mc.MBDate IS NOT NULL THEN mc.Isbackday7 ELSE dc.Isbackday7 END
		from		@calendarTable t
		left join	#DefaultMovebetConfig dc ON dc._weekDay = t.weekday_
		left join	dbo.Acc_ManualMovebetConfig mc ON t.scheduleDate = mc.MBDate

		DROP TABLE #DefaultMovebetConfig

	END

END

