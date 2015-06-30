 
 
 
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@COUNT	INT,
	@step	INT,
	@mode	INT
AS
BEGIN
	/** Delete Basketball mixparlay setting sporttype = 2 bettype = 9   **/
	-- 1 - Delete data in custsetting
	-- 2 - Delete data in custoverride

	IF @mode = 1 
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custsetting' AND TYPE = 'u')
			RETURN
		DELETE FROM custsetting WITH(ROWLOCK,UPDLOCK)
		WHERE sporttype = 2 AND bettype = 9 
			AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
	END
	ELSE IF @mode = 2
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custoverride' AND TYPE = 'u')
			RETURN
		DELETE FROM custoverride WITH(ROWLOCK,UPDLOCK)
		WHERE sporttype = 2 AND bettype = 9 
			AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
	END
	ELSE
	BEGIN
		SELECT 1
	END
END



/*
DECLARE @COUNT INT, @MaxCustID INT, @Step INT

-- Remember to select maxCustID before executing

SELECT  @MaxCustID = xxx,
        @COUNT = 0,
        @Step = 20000

WHILE 1 + @Step*@COUNT < @MaxCustID
BEGIN
    EXEC dbo.Acc_ExecRep_09  @COUNT = @COUNT, @Step = @Step, @Mode = 2
     
    SELECT @COUNT = @COUNT + 1
 
    WAITFOR DELAY '000:00:01'
END


*/