ALTER PROCEDURE [dbo].[Task_AB_Archive_Job]

AS 
/*	Created by: Jamie 
	Date: 2012-11-15
	Task: Archive AB Tables jobs 
	DB: DB052.bodb_ABS 
	
	Revisions: 
	

*/

SET NOCOUNT ON 

DECLARE	@errCode INT,
		@errMesg VARCHAR(1000) 
----Copy Match 

--EXEC dbo.Task_ABMatch_Archive @errCode = @errCode OUTPUT,@errMesg = @errMesg OUTPUT

--IF  @errCode <> 0 
--BEGIN
--	RAISERROR(@errMesg, 16,1)
--	RETURN 
--END 

--EXEC dbo.Task_ABTransaction_Archive @errCode = @errCode OUTPUT,@errMesg = @errMesg OUTPUT

--IF  @errCode <> 0 
--BEGIN
--	RAISERROR(@errMesg, 16,1)
--	RETURN 
--END 

DECLARE @maxDateSum_Old DATETIME,
		@balanceUpDay	DATETIME 

SELECT	@maxDateSum_Old = MAX(winlostdate) + 1  ---Saturday 
FROM	bodb_ABS.dbo.ABSum_winloss_Old WITH (NOLOCK)

SELECT  TOP 1 @balanceUpDay = winlostdate 
FROM	bodb02.dbo.Bettrans WITH(NOLOCK)
WHERE	bettype = 20000 and matchid = 0	and custid = 3

WHILE @maxDateSum_Old <=@balanceUpDay
BEGIN
	EXEC dbo.Task_ABSumWinloss_Archive @winlostdate = @maxDateSum_Old , @errCode = @errCode OUTPUT,@errMesg = @errMesg OUTPUT
	
	IF  @errCode <> 0 
	BEGIN
		RAISERROR(@errMesg, 16,1)
		RETURN 
	END 
	
	SELECT @maxDateSum_Old = @maxDateSum_Old + 1 

END

