USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_BetListCB_Details]
	@RefNo		BIGINT,
	@CustId		INT
AS

/*
	Created by: Kos
	Date: 2015-09-01
	Task: Get details info for Colossus Bet ticket
	DB: DBAGE.bodb02
	Original: 
	
	Revisions: 
*/

BEGIN
	SET NOCOUNT ON

	SELECT transid, 
		transdate,
		bettype,
		hdp1 AS Sold, 
		(winlost - stake) AS WinLost,
		statusid,
		status
	FROM bettransm WITH (NOLOCK)
	WHERE refno = @RefNo AND custid = @CustId

	UNION

	SELECT transid, 
		transdate,
		bettype,
		hdp1 AS Sold, 
		(winlost - stake) AS WinLost,
		statusid,
		status
	FROM bettransm14 WITH (NOLOCK)
	WHERE refno = @RefNo
	
	UNION 
	
	SELECT transid, 
		transdate,
		bettype,
		hdp1 AS Sold, 
		(winlost - stake) AS WinLost,
		statusid,
		status
	FROM DBARC.bodb_archive.dbo.bettransm WITH (NOLOCK)
	WHERE refno = @RefNo

END

GO
GRANT EXECUTE ON [dbo].[Acc_BetListCB_Details] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetListCB_Details] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Acc_BetListCB_Details] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetListCB_Details] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetListCB_Details] TO [vnteam] 
