ALTER PROCEDURE [dbo].[Acc_ExecRep_09]   
    @COUNT INT,
    @Step INT,
    @Mode VARCHAR(10)
AS
/*==============================================

  Copy Mix Parlay PT from Basketball (sporttype = 2; bettype = 9)
    to Mixed sports (sporttype = 99; bettype = 9)
  =============================================*/

/*
    Task: Copy Bet Settings and PT settings from Parlay-BASKETBALL (sporttype = 2; bettype = 9)
          TO Parlay-Mixed sports (sporttype = 99; bettype = 9)
    @mode = 0: delete all settings from CustSetting and CustOverride
    @mode = 1: update bet setting for CustInfo.MaxPerMatch99MP
    @mode = 2: insert PT into CustSetting and CustOverride
    @mode = 3: delete PT parlay-basketball from CustSetting and CustOverride (ONLY RUN WHEN PARLAY MIXED SPORTS OK)
*/


IF @Mode = 0
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustSetting')
    BEGIN
        DELETE FROM CustSetting WITH (UPDLOCK,ROWLOCK)
        WHERE    sporttype = 99 and bettype = 9 --and custid = custid
                and custid BETWEEN 1 + @Step*@COUNT AND @Step*(@COUNT + 1)
    END

    IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustOverride')
    BEGIN
        DELETE FROM CustOverride WITH (UPDLOCK,ROWLOCK)
        WHERE sporttype = 99 and bettype = 9 --and custid = custid
              and custid BETWEEN 1 + @Step*@COUNT AND @Step*(@COUNT + 1)
    END
END
ELSE IF @Mode = 1 AND EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'Custinfo')
BEGIN
    UPDATE Custinfo WITH(rowlock, updlock)
    SET MaxPerMatch99MP = maxpermatch2
    WHERE MaxPerMatch99MP <> ISNULL(Maxpermatch2,0) AND maxpermatch2 IS NOT NULL
            and CustID BETWEEN 1 + @Step*@COUNT AND @Step*(@COUNT + 1)
END
ELSE IF @Mode = 2 AND EXISTS (    SELECT COUNT(*) FROM dbo.sysobjects
                                WHERE name in ('CustSetting','CustOverride')
                                    and xtype = 'U'
                                HAVING COUNT(*) = 2)
BEGIN
--CustSetting
    INSERT INTO CustSetting
        (    custid,
            bettype,
            sporttype,
            apositiontaking,
            mpositiontaking,
            spositiontaking,
            playerdiscount,
            discount,
            adiscount,
            sdiscount,
            minbet,
            maxbet,
            autopositiontaking,
            isautopositiontaking,
            autompositiontaking,
            isautompositiontaking)
    SELECT  custid,
            9, 99,
            apositiontaking,
            mpositiontaking,
            spositiontaking,
            playerdiscount,
            discount,
            adiscount,
            sdiscount,
            minbet,
            maxbet,
            autopositiontaking,
            isautopositiontaking,
            autompositiontaking,
            isautompositiontaking
    FROM custsetting cs WITH (NOLOCK)
    WHERE sporttype = 2 AND bettype = 9 AND custid BETWEEN 1 + @Step*@COUNT AND @Step*(@COUNT + 1)

--CustOverride
    INSERT INTO CustOverride
                ( custid, bettype, sporttype, minpositiontaking, maxpositiontaking)
    SELECT  custid, 9, 99, minpositiontaking, maxpositiontaking
    FROM CustOverride WITH (NOLOCK)
    WHERE sporttype = 2 AND bettype = 9 AND custid BETWEEN 1 + @Step*@COUNT AND @Step*(@COUNT + 1)
END
ELSE IF @Mode = 3
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustSetting')
    BEGIN
        DELETE FROM CustSetting WITH (UPDLOCK,ROWLOCK)
        WHERE    sporttype = 2 and bettype = 9
                and custid BETWEEN 1 + @Step*@COUNT AND @Step*(@COUNT + 1)
    END

    IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustOverride')
    BEGIN
        DELETE FROM CustOverride WITH (UPDLOCK,ROWLOCK)
        WHERE sporttype = 2 and bettype = 9
              and custid BETWEEN 1 + @Step*@COUNT AND @Step*(@COUNT + 1)
    END
END
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_09] TO [vnteam]
GO

----------------
/*
DECLARE @COUNT INT, @MaxCustID INT, @Step INT
SELECT @MaxCustID = MAX(custid) FROM custinfo(nolock)

SELECT  @COUNT = 0,
        @Step = 30000

WHILE 1 + @Step*@COUNT < @MaxCustID
BEGIN
    EXEC dbo.Acc_ExecRep_09 @COUNT = @COUNT, @Step = @Step, @Mode = 0
     
    SELECT @COUNT = @COUNT + 1
 
    WAITFOR DELAY '000:00:01'
END
*/