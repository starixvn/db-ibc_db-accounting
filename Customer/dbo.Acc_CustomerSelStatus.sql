 USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerSelDisableHR]    Script Date: 02/26/2009 08:44:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_CustomerSelStatus]
	@CustID int
AS
/*
Created: 20090125@nqminh
Task : Select customer's status
DB: DB05.bodb02
Original:

Revisions:
    - 20090411@PhuongDoan: Add casino status    
    - 20090731@nqminh: Add outright status    
	- 20090806@huynguyen: Add closed, autosuspend, DisableAutoMPT
Param's Explanation:
• @CustID: customer id.   
*/

SET NOCOUNT ON

SELECT ISNULL(reject,0) AS Suspend,
	   ISNULL (closed,0) As Closed,
	   ISNULL (autosuspend,0) As AutoSuspend,	
	   ISNULL (cm.DisableAutoMPT ,0) As DisableAutoMPT,	
	   ISNULL(DisableHorseracing,0) AS DisableHorseracing,
	   ISNULL(DisableFinancial,0) AS DisableFI,
	   ISNULL(SyncCasino,0) AS SyncCasino,
	   ISNULL(DisableCasino,0) AS DisableCasino,
	   ISNULL(DisableOutright,0) AS DisableOutright
FROM custinfo as ci WITH (nolock)
	Left JOIN CustMaster as cm with (NOLOCK) on ci.CustID = cm.custid
WHERE ci.CustID = @CustID


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbAdminNet]
 