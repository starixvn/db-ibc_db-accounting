/*
	1. Modify SP Acc_ExecRep_09
	2. Call SP (@mode=0) to delete all existed setting (if any)
	3. Call SP (@mode=1) to update CustInfo.Maxpermatch161
	4. Call SP (mode=2) to INSERT data into table CustOverride3rd
	5. Call SP (mode=2) to INSERT data into table CustSetting3rd
*/


/*----------------------------------------------------------
	1. Modify SP Acc_ExecRep_09	
----------------------------------------------------------*/
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]   
    @mode varchar(20),
    @fromID INT = 0,
    @toID INT = 0
AS
/*
 *   @mode = 0: delete all settings for number game from custsetting3rd and custoverride3rd
 *   @mode = 1: update CustInfo.Maxpermatch161   
 *   @mode = 2: insert into custoverride3rd
 *   @mode = 3: Insert into custsetting3rd
 */

IF @Mode = 0
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustSetting3rd')
	BEGIN
		DELETE FROM CustSetting3rd WHERE sporttype = 161 and bettype between 81 and 87 and custid=custid
	END
	
	IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustOverride3rd')
	BEGIN
		DELETE FROM CustOverride3rd WHERE sporttype = 161 and bettype between 81 and 87 and custid=custid
	END
END
ELSE IF @Mode = 1 AND EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'Custinfo')
BEGIN
	UPDATE Custinfo WITH(rowlock, updlock)
	SET maxpermatch161 = isnull(maxpermatch,0)
	WHERE CustID between @fromID and @toID	
END
ELSE IF @Mode = 2 AND EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustOverride3rd')
BEGIN
    -- bettype: 81 (DEAD: First ball over/under; LIVE: NONE)
    INSERT INTO CustOverride3rd (custid, bettype, sporttype, minpositiontaking, maxpositiontaking)
    SELECT custid, 81, 161, minpositiontaking, maxpositiontaking
    FROM CustOverride WITH(nolock)
    WHERE sporttype = 1 AND bettype = 1 AND custid BETWEEN @fromID AND @toID

    -----------------------------------------------------
    -- bettype: 83 (DEAD: First ball odd/even; LIVE: NONE)
    INSERT INTO CustOverride3rd (custid, bettype, sporttype, minpositiontaking, maxpositiontaking)
    SELECT custid, 83, 161, minpositiontaking, maxpositiontaking
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
    INSERT INTO CustOverride3rd (custid, bettype, sporttype, minlivepositiontaking, maxlivepositiontaking)
    SELECT custid, 87, 161, minlivepositiontaking, maxlivepositiontaking
    FROM CustOverride WITH(nolock)
    WHERE sporttype = 1 AND bettype = 1 AND custid BETWEEN @fromID AND @toID   
END
ELSE IF @Mode = 3 AND EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'CustSetting3rd')
BEGIN   
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
        isautompositiontaking
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
        isautompositiontaking
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
        isautolivempositiontaking
    FROM custsetting WITH(nolock)
    WHERE sporttype = 1
        AND bettype = 1
        AND custid BETWEEN @fromID AND @toID
END

GO
GRANT EXECUTE ON [dbo].[Acc_ExecRep_09] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_09] TO [vnteam]
GO

/*
-- delete all existed setting (if any)	
EXEC dbo.Acc_ExecRep_09 @mode = 0
GO
------------------

DECLARE @COUNT INT, @MaxCustID INT, @Step INT, @fromid INT, @toid INT

-- Remember to select maxCustID before executing

SELECT  @MaxCustID = 3046796,
        @COUNT = 0,
        @Step = 100000

WHILE 1 + @Step*@COUNT < @MaxCustID
BEGIN
	select @fromid = @Step*@COUNT + 1, @toid = @step * (@count+1)     
	
	EXEC dbo.Acc_ExecRep_09 @mode = 1, @fromID = @fromid, @toID = @toid --update CustInfo.Maxpermatch161
	EXEC dbo.Acc_ExecRep_09 @mode = 2, @fromID = @fromid, @toID = @toid -- CustOverride3rd
	EXEC dbo.Acc_ExecRep_09 @mode = 3, @fromID = @fromid, @toID = @toid -- CustSetting3rd

    SELECT @COUNT = @COUNT + 1
 
    WAITFOR DELAY '000:00:05'
END
*/
-- check CustInfo.Maxpermatch161
select custid from custinfo with(nolock) where maxpermatch161<>maxpermatch

-- check custoverride3rd
select c.custid -- DEAD BALL
from CustOverride3rd c3 with(nolock)
	inner join CustOverride c with(nolock) on c3.custid = c.custid
where c.sporttype=1 
	and c.bettype=1 
	and c3.sporttype=161 
	and c3.bettype in (81,83,85,86)
	and (c.minpositiontaking <> c3.minpositiontaking OR c.maxpositiontaking <> c3.maxpositiontaking)

-- check custoverride3rd
select c.custid -- LIVE BALL
from CustOverride3rd c3 with(nolock)
	inner join CustOverride c with(nolock) on c3.custid = c.custid
where c.sporttype=1 
	and c.bettype=1 
	and c3.sporttype=161 
	and c3.bettype in (85,86,87)
	and (c.minlivepositiontaking <> c3.minlivepositiontaking OR c.maxlivepositiontaking <> c3.maxlivepositiontaking)

-- check CustSetting3rd (DEAD BALL)
select c.custid
from CustSetting3rd c3 with(nolock)
	inner join CustSetting c with(nolock) on c3.custid = c.custid
where c.sporttype=1 
	and c.bettype=1 
	and c3.sporttype=161 
	and c3.bettype in (81,83,85,86)
	and (c.apositiontaking <> c3.apositiontaking
			OR c.mpositiontaking <> c3.mpositiontaking
			OR c.spositiontaking <> c3.spositiontaking
			OR c.playerdiscount <> c3.playerdiscount
			OR c.minbet <> c3.minbet
			OR c.maxbet <> c3.maxbet
			OR c.autopositiontaking <> c3.autopositiontaking
			OR c.isautopositiontaking <> c3.isautopositiontaking
			OR c.autompositiontaking <> c3.autompositiontaking
			OR c.isautompositiontaking <> c3.isautompositiontaking			
		)

-- check CustSetting3rd (LIVE BALL)
select c.custid
from CustSetting3rd c3 with(nolock)
	inner join CustSetting c with(nolock) on c3.custid = c.custid
where c.sporttype=1
	and c.bettype=1
	and c3.sporttype=161 
	and c3.bettype in (85,86,87)
	and (c.minbet <> c3.minbet
			OR c.maxbet <> c3.maxbet
			OR c.alivepositiontaking <> c3.alivepositiontaking
			OR c.mlivepositiontaking <> c3.mlivepositiontaking
			OR c.slivepositiontaking <> c3.slivepositiontaking
			OR c.autolivepositiontaking <> c3.autolivepositiontaking
			OR c.isautolivepositiontaking <> c3.isautolivepositiontaking
			OR c.autolivempositiontaking <> c3.autolivempositiontaking
			OR c.isautolivempositiontaking <> c3.isautolivempositiontaking
		)
/*
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
AS

IF EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name = 'Custinfo')
BEGIN

	-- correct CustInfo.Maxpermatch161
	update custinfo with(updlock,rowlock)
	set maxpermatch161 = isnull(maxpermatch,0)
	where maxpermatch161 <> maxpermatch

	IF exists (SELECT * FROM dbo.sysobjects WHERE name = 'CustSetting3rd')
	BEGIN
		-- correct CustOverride3rd (dead ball)
		update c3
		set minpositiontaking = c.minpositiontaking,
			maxpositiontaking = c.maxpositiontaking
		FROM CustOverride3rd c3 with(rowlock, updlock)
			INNER JOIN CustOverride c with(nolock) on c3.custid = c.custid
		WHERE c.sporttype=1 
			and c.bettype=1
			and c3.sporttype=161
			and c3.bettype in (81,83,85,86)
			and (c.minpositiontaking <> c3.minpositiontaking OR c.maxpositiontaking <> c3.maxpositiontaking)

		-- correct CustOverride3rd (live ball)
		update c3
		set minlivepositiontaking = c.minlivepositiontaking,
			maxlivepositiontaking = c.maxlivepositiontaking
		FROM CustOverride3rd c3 with(rowlock, updlock)
			INNER JOIN CustOverride c with(nolock) on c3.custid = c.custid
		WHERE c.sporttype=1 
			and c.bettype=1
			and c3.sporttype=161
			and c3.bettype in (85,86,87)
			and (c.minlivepositiontaking <> c3.minlivepositiontaking OR c.maxlivepositiontaking <> c3.maxlivepositiontaking)

		-- correct CustSetting3rd (dead ball)
		update c3
		set apositiontaking = c.apositiontaking,
			mpositiontaking = c.mpositiontaking,
			spositiontaking = c.spositiontaking,
			playerdiscount = c.playerdiscount,
			minbet = c.minbet,
			maxbet = c.maxbet,
			autopositiontaking = c.autopositiontaking,
			isautopositiontaking = c.isautopositiontaking,
			autompositiontaking = c.autompositiontaking,
			isautompositiontaking = c.isautompositiontaking
		FROM CustSetting3rd c3 with(rowlock, updlock)
			INNER JOIN CustSetting c with(nolock) on c3.custid = c.custid
		WHERE c.sporttype=1 
			and c.bettype=1
			and c3.sporttype=161
			and c3.bettype in (81,83,85,86)
			and (c.apositiontaking <> c3.apositiontaking
				OR c.mpositiontaking <> c3.mpositiontaking
				OR c.spositiontaking <> c3.spositiontaking
				OR c.playerdiscount <> c3.playerdiscount
				OR c.minbet <> c3.minbet
				OR c.maxbet <> c3.maxbet
				OR c.autopositiontaking <> c3.autopositiontaking
				OR c.isautopositiontaking <> c3.isautopositiontaking
				OR c.autompositiontaking <> c3.autompositiontaking
				OR c.isautompositiontaking <> c3.isautompositiontaking)

			-- correct CustSetting3rd (live ball)
		update c3
		set minbet = c.minbet,
			maxbet = c.maxbet,
			alivepositiontaking = c.alivepositiontaking,
			mlivepositiontaking = c.mlivepositiontaking,
			slivepositiontaking = c.slivepositiontaking,
			autolivepositiontaking = c.autolivepositiontaking,
			isautolivepositiontaking = c.isautolivepositiontaking,
			autolivempositiontaking = c.autolivempositiontaking,
			isautolivempositiontaking = c.isautolivempositiontaking
		FROM CustSetting3rd c3 with(rowlock, updlock)
			INNER JOIN CustSetting c with(nolock) on c3.custid = c.custid
		WHERE c.sporttype=1 
			and c.bettype=1
			and c3.sporttype=161
			and c3.bettype in (85,86,87)
			and (c.minbet <> c3.minbet
				OR c.maxbet <> c3.maxbet
				OR c.alivepositiontaking <> c3.alivepositiontaking
				OR c.mlivepositiontaking <> c3.mlivepositiontaking
				OR c.slivepositiontaking <> c3.slivepositiontaking
				OR c.autolivepositiontaking <> c3.autolivepositiontaking
				OR c.isautolivepositiontaking <> c3.isautolivepositiontaking
				OR c.autolivempositiontaking <> c3.autolivempositiontaking
				OR c.isautolivempositiontaking <> c3.isautolivempositiontaking)
	END
END

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_09] TO [vnteam]
GO
*/