/******* DELETE TESTING DATA FIRST ***********

	DELETE FROM custsetting3rd
	WHERE sporttype = 161 and bettype in (88,89,90)

	DELETE FROM custoverride3rd
	WHERE sporttype = 161 and bettype in (88,89,90)
********************************************/

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@fromCustID	int,
	@toCustID int
AS
BEGIN	
	DECLARE @bettype TABLE(bettype SMALLINT)
	INSERT INTO @bettype 
			  SELECT 88
	UNION ALL SELECT 89
	UNION ALL SELECT 90
	
	IF (SELECT COUNT('') FROM sys.objects WHERE NAME IN ('custsetting3rd','custsetting') AND TYPE = 'u') <> 2
	RETURN

	-- custsetting3rd - all customers
	INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
	SELECT  cs3.custid, b.bettype, 161
		,CASE WHEN b.bettype = 88 THEN cs.apositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 88 THEN cs.mpositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 88 THEN cs.spositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 90 THEN 0 ELSE cs.playerdiscount END
		,CASE WHEN b.bettype = 90 THEN 0 ELSE cs.discount END
		,CASE WHEN b.bettype = 90 THEN 0 ELSE cs.adiscount END
		,CASE WHEN b.bettype = 90 THEN 0 ELSE cs.sdiscount END
		,CASE WHEN b.bettype = 90 THEN 0 ELSE cs3.minbet END
		,CASE WHEN b.bettype = 90 THEN 0 ELSE cs3.maxbet END
		,CASE WHEN b.bettype = 88 THEN cs.autopositiontaking ELSE 0 END 
		,CASE WHEN b.bettype = 88 THEN cs.isautopositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 88 THEN cs.autompositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 88 THEN cs.isautompositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 89 THEN cs.alivepositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 89 THEN cs.mlivepositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 89 THEN cs.slivepositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 89 THEN cs.autolivepositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 89 THEN cs.isautolivepositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 89 THEN cs.autolivempositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 89 THEN cs.isautolivempositiontaking ELSE 0 END
	FROM custsetting cs WITH(NOLOCK) 		
		INNER JOIN custsetting3rd cs3 WITH(NOLOCK) ON cs.custid = cs3.custid
		CROSS JOIN @bettype b
	WHERE cs.sporttype = 1 
		AND cs.bettype = 1				
		AND cs3.sporttype = 161 
		AND cs3.bettype = 81
		AND cs3.custid BETWEEN @fromCustID AND @toCustID


	IF (SELECT COUNT('') FROM sys.objects WHERE NAME IN ('custoverride3rd','custoverride') AND TYPE = 'u') <> 2 
	RETURN
	-- custoverride3rd - AGENTs only
	INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
	SELECT co.custid, b.bettype, 161
		,CASE WHEN b.bettype = 88 THEN co.minpositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 88 THEN co.maxpositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 89 THEN co.minlivepositiontaking ELSE 0 END
		,CASE WHEN b.bettype = 89 THEN co.maxlivepositiontaking WHEN b.bettype = 90 THEN 0.9 ELSE 0 END
	FROM custoverride co WITH(NOLOCK)
		CROSS JOIN @bettype b
	WHERE co.sporttype = 1 
		AND co.bettype = 1
		AND co.custid BETWEEN @fromCustID AND @toCustID
END

GO
/* 
DECLARE @COUNT INT, @MaxCustID INT, @Step INT, @fromCustID int, @toCustID int

select @MaxCustID = max(custid) from custinfo with(nolock)
SELECT  @COUNT = 0,
        @Step = 20000 

WHILE 1 + @Step*@COUNT < @MaxCustID
BEGIN
	SELECT @fromCustID = 1 + @step*@COUNT, @toCustID = @step*(@COUNT + 1)
    EXEC dbo.Acc_ExecRep_09 @fromCustID = @fromCustID, @toCustID = @toCustID
     
    SELECT @COUNT = @COUNT + 1
    WAITFOR DELAY '000:00:03'
END

*/