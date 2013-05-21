ALTER PROCEDURE [dbo].[Acc_TicketUpd_stest]
	@ReqNo varchar(5),
	@ReportName nvarchar(1000),
	@Remark nvarchar(max),
	@dateline smalldatetime,
	@assignee varchar(50),
	@status varchar(20),
	@RemarkByPreparer nvarchar(max),
	@LastModifiedBy varchar(50) -- username	
AS
/*
	Created: Viet
	Date: 16May2013
	Task: modify a ticket	
	DB: bodb_acc
	
	Revisions:		
*/
SET NOCOUNT ON	
	
	SET @Dateline = DATEADD(dd, DATEDIFF(d, 0, @Dateline), 0)
	
	UPDATE dbo.RptTickets with(rowlock, updlock)
	SET ReportName = @ReportName
		,Remark = @Remark
		,dateline = @dateline
		,assignee = @assignee
		,status = @status
		,RemarkByPreparer = @RemarkByPreparer
		,LastModified = CURRENT_TIMESTAMP
		,LastModifiedBy = @LastModifiedBy
	WHERE ReqNo = @ReqNo
					



GO
GRANT EXECUTE ON [dbo].[Acc_TicketUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_TicketUpd] TO [vnteam] AS [dbo]