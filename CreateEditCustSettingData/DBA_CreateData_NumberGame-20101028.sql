ALTER PROCEDURE [dbo].[Acc_ExecRep_09]   
    @COUNT INT,
    @Step INT,
    @Mode VARCHAR(10)
AS

RETURN
/*
    Task: Copy Bet Settings and PT settings
		+ from Parlay-BASKETBALL to parlay-Mixed Sports
		+ from Soccer's handicap to NUMBER Game
    @mode = 0: delete all settings from CustSetting/CustOverride/CustSetting3rd/CustOverride3rd
    @mode = 1: update bet setting for CustInfo.MaxPerMatch99MP, CustInfo.maxbermatch161
    @mode = 2: insert PT into CustSetting/CustOverride/CustSetting3rd/CustOverride3rd
    @mode = 3: delete PT parlay-basketball from CustSetting and CustOverride (ONLY RUN WHEN PARLAY MIXED SPORTS OK)
*/

DECLARE @fromID int, @toID int
SELECT @fromID = 1 + @Step*@COUNT, @toID = @Step*(@COUNT + 1)
IF @Mode = 0
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustSetting')
    BEGIN
        DELETE FROM CustSetting WITH (UPDLOCK,ROWLOCK)
        WHERE    sporttype = 99 and bettype = 9 --and custid = custid
                and custid BETWEEN @fromID and @toID		
    END

    IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustOverride')
    BEGIN
        DELETE FROM CustOverride WITH (UPDLOCK,ROWLOCK)
        WHERE sporttype = 99 and bettype = 9 --and custid = custid
              and custid BETWEEN @fromID and @toID
    END

	IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustSetting3rd')
	BEGIN
		DELETE FROM CustSetting3rd WHERE sporttype = 161 and bettype between 81 and 87 and custid BETWEEN @fromID and @toID
	END
	
	IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustOverride3rd')
	BEGIN
		DELETE FROM CustOverride3rd WHERE sporttype = 161 and bettype between 81 and 87 and custid BETWEEN @fromID and @toID
	END
END
ELSE IF @Mode = 1 AND EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'Custinfo')
BEGIN
    UPDATE Custinfo WITH(rowlock, updlock)
    SET MaxPerMatch99MP = isnull(maxpermatch2,0),
		maxpermatch161 = isnull(maxpermatch,0)
    WHERE CustID between @fromID and @toID
    
    RETURN
END
ELSE IF @Mode = 2 AND EXISTS (    SELECT COUNT(*) FROM dbo.sysobjects
                                WHERE name in ('CustSetting','CustOverride','CustSetting3rd','CustOverride3rd')
                                    and xtype = 'U'
                                HAVING COUNT(*) = 4)
BEGIN
--CustSetting
    INSERT INTO CustSetting
        (   custid,
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
            isautompositiontaking
           ,[alivepositiontaking]
           ,[mlivepositiontaking]
           ,[slivepositiontaking]
           ,[groupa]
           ,[groupb]
           ,[groupc]
           ,[groupd]
           ,[groupe]
           ,[groupf]
           ,[autolivepositiontaking]
           ,[isautolivepositiontaking]
           ,[autolivempositiontaking]
           ,[isautolivempositiontaking]
           )
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
            isautompositiontaking,
            0,0,0,0,0,0,0,0,0,0,0,0,0
    FROM custsetting cs WITH (NOLOCK)
    WHERE sporttype = 2 AND bettype = 9 AND custid BETWEEN @fromID and @toID

--CustOverride
    INSERT INTO CustOverride
                ( custid, bettype, sporttype, minpositiontaking, maxpositiontaking, [minlivepositiontaking], [maxlivepositiontaking])
    SELECT  custid, 9, 99, minpositiontaking, maxpositiontaking, 0, 0
    FROM CustOverride WITH (NOLOCK)
    WHERE sporttype = 2 AND bettype = 9 AND custid BETWEEN @fromID and @toID

-- CustSetting3rd
    -- bettype: 81 (DEAD: First ball over/under; LIVE: NONE)
    INSERT INTO CustSetting3rd (
        custid,
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
        isautompositiontaking
		,[alivepositiontaking]
       ,[mlivepositiontaking]
       ,[slivepositiontaking]
       ,[autolivepositiontaking]
       ,[isautolivepositiontaking]
       ,[autolivempositiontaking]
       ,[isautolivempositiontaking]
    )
    SELECT
        custid,
        81, -- bettype
        161,-- sporttype        
        apositiontaking,
        mpositiontaking,
        spositiontaking,
        0,
        0,
        0,
        0,
        minbet,
        maxbet,
        autopositiontaking,
        isautopositiontaking,
        autompositiontaking,
        isautompositiontaking,
		0,0,0,0,0,0,0
    FROM custsetting WITH(nolock)
    WHERE sporttype = 1
        AND bettype = 1
        AND custid BETWEEN @fromID AND @toID

    -----------------------------------------------------
    -- bettype: 83 (DEAD: First ball odd/even; LIVE: NONE)
    INSERT INTO CustSetting3rd (
        custid,
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
        isautompositiontaking
		,[alivepositiontaking]
        ,[mlivepositiontaking]
        ,[slivepositiontaking]
        ,[autolivepositiontaking]
        ,[isautolivepositiontaking]
        ,[autolivempositiontaking]
        ,[isautolivempositiontaking]
    )
    SELECT
        custid,
        83, -- bettype
        161,-- sporttype        
        apositiontaking,
        mpositiontaking,
        spositiontaking,
        0,
        0,
        0,
        0,
        minbet,
        maxbet,
        autopositiontaking,
        isautopositiontaking,
        autompositiontaking,
        isautompositiontaking,
		0,0,0,0,0,0,0
    FROM custsetting WITH(nolock)
    WHERE sporttype = 1
        AND bettype = 1
        AND custid BETWEEN @fromID AND @toID

    -----------------------------------------------------
    -- bettype: 85 (DEAD: Over/Under FT; LIVE: Over/Under)
    INSERT INTO CustSetting3rd (
        custid,
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
        isautompositiontaking,
        alivepositiontaking,
        mlivepositiontaking,
        slivepositiontaking,
        autolivepositiontaking,
        isautolivepositiontaking,
        autolivempositiontaking,
        isautolivempositiontaking

    )
    SELECT
        custid,
        85, -- bettype
        161,-- sporttype        
        apositiontaking,
        mpositiontaking,
        spositiontaking,
        0,
        0,
        0,
        0,
        minbet,
        maxbet,
        autopositiontaking,
        isautopositiontaking,
        autompositiontaking,
        isautompositiontaking,
        alivepositiontaking,
        mlivepositiontaking,
        slivepositiontaking,
        autolivepositiontaking,
        isautolivepositiontaking,
        autolivempositiontaking,
        isautolivempositiontaking
    FROM custsetting WITH(nolock)
    WHERE sporttype = 1
        AND bettype = 1
        AND custid BETWEEN @fromID AND @toID

    -----------------------------------------------------
    -- bettype: 86 (DEAD: Odd/Even FT; LIVE: Odd/Even)
    INSERT INTO CustSetting3rd (
        custid,
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
        isautompositiontaking,
        alivepositiontaking,
        mlivepositiontaking,
        slivepositiontaking,
        autolivepositiontaking,
        isautolivepositiontaking,
        autolivempositiontaking,
        isautolivempositiontaking

    )
    SELECT
        custid,
        86, -- bettype
        161,-- sporttype                
        apositiontaking,
        mpositiontaking,
        spositiontaking,
        0,
        0,
        0,
        0,
        minbet,
        maxbet,
        autopositiontaking,
        isautopositiontaking,
        autompositiontaking,
        isautompositiontaking,
        alivepositiontaking,
        mlivepositiontaking,
        slivepositiontaking,
        autolivepositiontaking,
        isautolivepositiontaking,
        autolivempositiontaking,
        isautolivempositiontaking
    FROM custsetting WITH(nolock)
    WHERE sporttype = 1
        AND bettype = 1
        AND custid BETWEEN @fromID AND @toID
   

    -- bettype: 87 (NONE; LIVE: HI/LO)
    INSERT INTO CustSetting3rd (
        custid,
        bettype,
        sporttype,
        playerdiscount,
        discount,
        adiscount,
        sdiscount,
        minbet,
        maxbet,       
        alivepositiontaking,
        mlivepositiontaking,
        slivepositiontaking,
        autolivepositiontaking,
        isautolivepositiontaking,
        autolivempositiontaking,
        isautolivempositiontaking
		,[apositiontaking]
        ,[mpositiontaking]
        ,[spositiontaking]
		,[autopositiontaking]
        ,[isautopositiontaking]
        ,[autompositiontaking]
        ,[isautompositiontaking]
    )
    SELECT
        custid,
        87, -- bettype
        161,-- sporttype        
        0,
        0,
        0,
        0,
        minbet,
        maxbet,
        alivepositiontaking,
        mlivepositiontaking,
        slivepositiontaking,
        autolivepositiontaking,
        isautolivepositiontaking,
        autolivempositiontaking,
        isautolivempositiontaking,
		0,0,0,0,0,0,0
    FROM custsetting WITH(nolock)
    WHERE sporttype = 1
        AND bettype = 1
        AND custid BETWEEN @fromID AND @toID

-- CustOverride3rd
    -- bettype: 81 (DEAD: First ball over/under; LIVE: NONE)
    INSERT INTO CustOverride3rd (custid, bettype, sporttype, minpositiontaking, maxpositiontaking, [minlivepositiontaking], [maxlivepositiontaking])
    SELECT custid, 81, 161, minpositiontaking, maxpositiontaking, 0, 0
    FROM CustOverride WITH(nolock)
    WHERE sporttype = 1 AND bettype = 1 AND custid BETWEEN @fromID AND @toID

    -----------------------------------------------------
    -- bettype: 83 (DEAD: First ball odd/even; LIVE: NONE)
    INSERT INTO CustOverride3rd (custid, bettype, sporttype, minpositiontaking, maxpositiontaking, [minlivepositiontaking], [maxlivepositiontaking])
    SELECT custid, 83, 161, minpositiontaking, maxpositiontaking, 0, 0
    FROM CustOverride WITH(nolock)
    WHERE sporttype = 1 AND bettype = 1 AND custid BETWEEN @fromID AND @toID
    
    -----------------------------------------------------
    -- bettype: 85 (DEAD: Over/Under FT; LIVE: Over/Under)
    INSERT INTO CustOverride3rd (custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
    SELECT custid, 85, 161, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
    FROM CustOverride WITH(nolock)
    WHERE sporttype = 1 AND bettype = 1 AND custid BETWEEN @fromID AND @toID   

    -----------------------------------------------------
    -- bettype: 86 (DEAD: Odd/Even FT; LIVE: Odd/Even)
    INSERT INTO CustOverride3rd (custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
    SELECT custid, 86, 161, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
    FROM CustOverride WITH(nolock)
    WHERE sporttype = 1 AND bettype = 1 AND custid BETWEEN @fromID AND @toID   

    -----------------------------------------------------
    -- bettype: 87 (NONE; LIVE: HI/LO)
    INSERT INTO CustOverride3rd (custid, bettype, sporttype, minlivepositiontaking, maxlivepositiontaking, minpositiontaking, maxpositiontaking)
    SELECT custid, 87, 161, minlivepositiontaking, maxlivepositiontaking, 0, 0
    FROM CustOverride WITH(nolock)
    WHERE sporttype = 1 AND bettype = 1 AND custid BETWEEN @fromID AND @toID
    
    RETURN
END
ELSE IF @Mode = 3
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustSetting')
    BEGIN
        DELETE FROM CustSetting WITH (UPDLOCK,ROWLOCK)
        WHERE    sporttype = 2 and bettype = 9
                and custid BETWEEN @fromID and @toId
    END

    IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustOverride')
    BEGIN
        DELETE FROM CustOverride WITH (UPDLOCK,ROWLOCK)
        WHERE sporttype = 2 and bettype = 9
              and custid BETWEEN @fromID and @toId
    END
    
    RETURN
END
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_09] TO [vnteam]
GO

/*
DECLARE @COUNT INT, @MaxCustID INT, @Step INT, @fromid INT, @toid INT

-- Remember to select maxCustID before executing

SELECT  @MaxCustID = xxxxx,
        @COUNT = 0,
        @Step = 200000

EXEC dbo.Acc_ExecRep_09 @mode = 0, @COUNT = @COUNT, @Step = @Step

WHILE 1 + @Step*@COUNT < @MaxCustID
BEGIN
		
	EXEC dbo.Acc_ExecRep_09 @mode = 1, @COUNT = @COUNT, @Step = @Step
	EXEC dbo.Acc_ExecRep_09 @mode = 2, @COUNT = @COUNT, @Step = @Step

    SELECT @COUNT = @COUNT + 1
 
    WAITFOR DELAY '000:00:02'
END

--print 'COUNT: ' + CAST(@COUNT as varchar(10)) + ' --- STEP: ' + CAST(@Step as varchar(10))

*/