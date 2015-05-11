ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
    @COUNT INT,
    @Step INT
AS


IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE name = 'custinfo')
BEGIN
	RETURN
END

--Copy maxpermatch151_OT, disableOpenTote 
UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
SET MaxPerMatch151_OT = ISNULL(MaxPerMatch151,0),
	disableOpenTote = DisableHorseRacing
WHERE
 custid BETWEEN  1 + @Step*@COUNT AND  @Step*(@COUNT +  1)


GO




---------------------------------------------------------------------
---               Script call [Acc_ExecRep_09]
---------------------------------------------------------------------
DECLARE @COUNT INT, @MaxCustID INT, @Step INT

SELECT @MaxCustID = MAX(custid) + 100,
        @COUNT = 0,
        @Step = 20000
FROM custinfo(NOLOCK)

WHILE 1 + @Step*@COUNT < @MaxCustID
BEGIN
    EXEC dbo.Acc_ExecRep_09 @COUNT = @COUNT, @Step = @Step
	  
    SELECT @COUNT = @COUNT + 1
    
    WAITFOR DELAY '00:00:01'
END  
