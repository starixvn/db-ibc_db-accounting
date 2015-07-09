USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_ABTransaction_Archive_Job]    Script Date: 12/13/2012 03:54:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 ALTER PROCEDURE [dbo].[Task_ABTransaction_Archive_Job]
 @winlostdate	DATETIME 

 AS	
	/*
		Created: Jamie 
		Date: 2012-10-18
		Task: Archive transactions for ABS
		DB: DB06.BODB02
		
		Revisions:
			- 20121213@Dan: Change linked server from DB052-->DBABS
		
		Parameters Explanation:
	*/

SET NOCOUNT ON 

DECLARE	@MinDate		DATETIME,
		@MaxDate		DATETIME,	-- MAX(ABTrans_BK) + 1 
		@BalanceUpDay	DATETIME 
		
SELECT	@BalanceUpDay = MAX(winlostdate)
FROM	bodb02.dbo.Bettrans WITH (NOLOCK)
WHERE	Custid = 2  --SA-RM 
		AND bettype = 20000
		AND matchid = 0 
		
SELECT	@MaxDate = MAX(Winlostdate) + 1 
FROM	bodb_archive.dbo.bettrans_bk b WITH (NOLOCK)
		INNER JOIN DBABS.bodb_ABS.dbo.ABTransaction_BK t WITH (NOLOCK) ON b.transid = t.transid 


IF @MaxDate IS NULL SELECT @MaxDate = DATEADD(DAY,-8,@BalanceUpDay) 

IF @MaxDate < @BalanceUpDay
BEGIN 
	WHILE(@MaxDate <=@BalanceUpDay)
	BEGIN
		PRINT @MaxDate
		EXEC [dbo].[Task_ABTransaction_Archive] @winlostdate = @MaxDate
		SET	@MaxDate = @MaxDate + 1 
	END
END 