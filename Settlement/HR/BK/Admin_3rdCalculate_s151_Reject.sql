ALTER PROCEDURE [dbo].[Admin_3rdCalculate_s151_Reject]
	@programID varchar(10),
	@raceNumber tinyint,
    @EventDate smalldatetime
AS
/*
Created by:[]
Date:
Task: Reject HR bets
DB: DBTrans.BODB02

	Revisions:
		-- 20100517@Henry: Update column StatusID of Bettrans
		-- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		-- 20101007@Henry: Change column transid from INT to BIGINT
*/
BEGIN
	SET NOCOUNT ON;

	-- get outright.orid
	DECLARE @Horse TABLE (orid int)
	INSERT INTO @Horse (orid)
	SELECT orid FROM DB02.bodb02.dbo.outright with (nolock)
	WHERE
		eventdate = @eventdate 
		AND ProgramID = @programID 
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND oddsstatus = 'closed'

	declare @tbltransid as table (transid bigint)

	-- reject ticket
	UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET
		[status] = N'reject',
		statusID = 101,
		winlost = actual_stake,
		awinlost = 0, mwinlost = 0, swinlost = 0,
		playercomm = 0, comm = 0, acomm = 0, scomm = 0,
		ruben = 1,
		transdesc = 'system reject waiting bet ' + transdesc
	output deleted.transid into @tbltransid
	FROM @Horse h	
    WHERE 
		bettrans.matchid = h.orid
        AND bettrans.bettype IN (31, 32, 33)
		--AND bettrans.[status] = N'waiting'
		AND bettrans.[statusID] = 1
	
	UPDATE dbo.bettransm with (ROWLOCK, UPDLOCK)
	SET
		[status] = N'reject',
		statusID = 101,
		winlost = stake,
		awinlost = 0, mwinlost = 0, swinlost = 0,
		playercomm = 0, comm = 0, acomm = 0, scomm = 0,
		ruben = 1	
	FROM @Horse h	
    WHERE 
		bettransm.matchid = h.orid
        AND bettransm.bettype IN (31, 32)
		AND bettransm.refno in (select transid from @tbltransid)

	-- LOG reject ticket
	IF EXISTS(SELECT transid FROM @tbltransid)
	BEGIN
		INSERT INTO dbo.userlog (userid,doing)
		SELECT 151, '3rd_Result transid:' + CAST(transid as varchar(20)) + ' Success:0 FailedMsg: system reject waiting bet'
		FROM @tbltransid
	END

END
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdCalculate_s151_Reject] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Admin_3rdCalculate_s151_Reject] TO [Dot_3rdparty]
GO
