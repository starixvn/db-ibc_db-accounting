USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Admin_3rdCalculate_s151_Refund]    Script Date: 06/15/2009 21:34:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Admin_3rdCalculate_s151_Refund]
	@ProgramID varchar(10),
	@raceNumber int,
	@eventdate smalldatetime
AS
/*
	Create:
	Task:
	DB: DBTrans.BODB02
	
	Revisions:
		-- 20100427@Henry: Update column StatusID of Bettrans,bettransm
		-- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
*/


BEGIN
	SET NOCOUNT ON;

	-- Get race no outright.orid
	DECLARE @Horse TABLE (orid int)
	INSERT INTO @Horse (orid)
	SELECT orid FROM DB02.bodb02.dbo.outright with (nolock)
	WHERE
		eventdate = @eventdate 
		AND ProgramID = @programID 
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND oddsstatus IN ('running','suspend','closed')

	-- Refund ticket
	UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET
		[status] = 'Refund',
		statusID = 103,
		winlost=actual_stake,
		livehomescore=0, liveawayscore=0,
		awinlost=0, mwinlost=0, swinlost=0,
		playercomm=0, comm=0, acomm=0, scomm=0,
		ruben=1
	FROM @Horse h
    WHERE 
		bettrans.matchid = h.orid
        AND bettrans.bettype IN (31, 32, 33)
		--AND bettrans.[status] NOT IN (N'VOID', N'REJECT')
		AND bettrans.[statusID] NOT IN (101,102)

	--Refund for bettransm
	UPDATE dbo.bettransm with (ROWLOCK, UPDLOCK)
	SET
		[status] = 'Refund',
		statusID = 103,
		winlost=stake,
		livehomescore=0, liveawayscore=0,
		awinlost=0, mwinlost=0, swinlost=0,
		playercomm=0, comm=0, acomm=0, scomm=0,
		ruben=1
	FROM @Horse h
    WHERE 
		bettransm.matchid = h.orid
        AND bettransm.bettype IN (31, 32)
		--AND bettransm.[status] NOT IN (N'VOID', N'REJECT')
		AND bettransm.[statusID] NOT IN (101,102)

END

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdCalculate_s151_Refund] TO [vnteam]