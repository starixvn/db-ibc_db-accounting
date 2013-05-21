ALTER PROCEDURE [dbo].[Acc_TicketSelHistory]	
	@ReqNo varchar(5) = NULL
AS
/*
	Created: Viet
	Date: 21May2013
	Task: 
	DB: bodb_ACC
	
	Revisions:		
*/
SET NOCOUNT ON

	IF @ReqNo IS NULL
	BEGIN
		SELECT UpdateTime, ReqNo, Requestor, ReqDate, ReportName, Remark, Dateline, Assignee, 
			Status, RemarkByPreparer, LastModifiedBy, isDeleted, LastModified
		FROM dbo.RptTickets_history with(nolock)		
		ORDER BY ReqNo, UpdateTime desc
	END
	ELSE BEGIN
		SELECT UpdateTime, ReqNo, Requestor, ReqDate, ReportName, Remark, Dateline, Assignee, 
			Status, RemarkByPreparer, LastModifiedBy, isDeleted, LastModified
		FROM dbo.RptTickets_history with(nolock)
		WHERE ReqNo = @ReqNo
		ORDER BY UpdateTime desc
	END
					

GO
GRANT EXECUTE ON [dbo].[Acc_TicketSelHistory] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_TicketSelHistory] TO [vnteam] AS [dbo]