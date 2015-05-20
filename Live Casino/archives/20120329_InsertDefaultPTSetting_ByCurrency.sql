

/*
Insert PT/Comm setting for particular currency

For customer game setting:
	1. Insert default PT setting on IBC database
	2. Insert Bet setting on Live CS database also
	3. Make customer is sync
		3.1 Insert default data to LVCustSetting, CustFinance table (on Live CS database)
		3.2 Update SyncLiveCasino = 1 on Custinfo table ( on IBC database)

Note: This script only can do step 1 & 3.2
*/

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@currency	INT,
	@minCustID	INT,	
	@Count		INT,
	@Step		INT,
	@mode		INT = 0
AS
/*	
	 1 - Insert PT Setting (CustSettingGame)
	 2 - Insert Min PT Setting (CustOverrideGame)
	 3 - Update Sync Live Casino	 
*/
BEGIN	
	SET NOCOUNT ON 
	
	IF @mode = 1	-- Insert PT Setting (CustSettingGame)
	BEGIN
		IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('CustSetting','CustSettingGame','custinfo') AND TYPE = 'u') <> 3
			RETURN
		INSERT INTO CustSettingGame(CustID, Bettype, Sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking)
		SELECT cs.custid, 1101, 162, alivepositiontaking, mlivepositiontaking, slivepositiontaking,0,0,0,0, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
		FROM CustSetting cs WITH(NOLOCK)
			INNER JOIN custinfo c WITH(NOLOCK) ON cs.custid = c.custid
		WHERE cs.custid BETWEEN @minCustID + @step*@COUNT AND @minCustID + @step*(@COUNT + 1) - 1
			AND cs.bettype = 1 AND cs.sporttype = 1
			AND c.currency = @currency
	END
	ELSE IF @mode = 2	-- Insert Min PT Setting (CustOverrideGame)
	BEGIN
		IF (SELECT COUNT(1) FROM sys.objects WHERE NAME IN ('CustOverride','CustOverrideGame','Custinfo') AND TYPE = 'u') <> 3
			RETURN		
		INSERT INTO CustOverrideGame(CustID, Bettype, Sporttype, minpositiontaking)
		SELECT co.CustID, 1101, 162, co.minlivepositiontaking
		FROM CustOverride co WITH(NOLOCK)
				INNER JOIN custinfo c WITH(NOLOCK) ON co.custid = c.custid
		WHERE co.custid BETWEEN @minCustID + @step*@COUNT AND @minCustID + @step*(@COUNT + 1) - 1
			AND co.bettype = 1 AND co.sporttype = 1
			AND c.currency = @currency
	END
	ELSE IF @mode = 3	-- Update Sync Live Casino	 
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custinfo' AND TYPE = 'u')
			RETURN
		UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
		SET syncLiveCasino = 1
		WHERE custid BETWEEN @minCustID + @step*@COUNT AND @minCustID + @step*(@COUNT + 1) - 1
			AND currency = @currency
	END
END

 

/*

	 1 - Insert PT Setting (CustSettingGame)
	 2 - Insert Min PT Setting (CustOverrideGame)
	 3 - Update Sync Live Casino	 

DECLARE @COUNT INT, @MaxCustID INT, @Step INT, @minCustID INT, @currency INT

-- Remember to select maxCustID before executing
-- select min(custid),max(custid) from custinfo with(nolock) where currency = xxxx
SELECT  @MaxCustID = 6001462,
		@minCustID = 20,
		@currency = xxxx,
        @COUNT = 0,
        @Step = 20000

WHILE @minCustid + @step*@count <= @maxcustid
BEGIN
    EXEC dbo.Acc_ExecRep_09  @currency = @currency, @minCustID = @minCustID, @COUNT = @COUNT, @Step = @Step, @Mode = 1
     
    SELECT @COUNT = @COUNT + 1
 
    WAITFOR DELAY '000:00:01'
END



*/

 