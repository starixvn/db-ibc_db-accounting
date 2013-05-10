
ALTER PROCEDURE [dbo].[Admin_Calculate_VS_181_Refund]
	@matchid int	
AS
/*
	Created by: Victor
	Date:[20130114]
	Task: Settlement (Refund)
	DB: DBTRANS.bodb02
	
	Revisions:		

*/
SET NOCOUNT ON

IF @@SERVERNAME not in ('DB042', 'DB043', 'DB044')
BEGIN
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
    WHERE 
		bettransm.matchid = @matchid
        AND bettransm.bettype IN (1231,1232)
		AND bettransm.[statusID] NOT IN (101,102)
END


IF @@SERVERNAME not in ('DB042', 'DB043', 'DB044')
BEGIN
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
    WHERE 
		bettrans.matchid = @matchid
        AND bettrans.bettype IN (1231,1232,1233)
		AND bettrans.[statusID] NOT IN (101,102)
END

