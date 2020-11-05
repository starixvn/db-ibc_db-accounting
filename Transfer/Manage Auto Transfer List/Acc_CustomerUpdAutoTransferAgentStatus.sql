/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0"></info>*/
 ALTER PROCEDURE [dbo].[Acc_CustomerUpdAutoTransferAgentStatus]
	@custid	INT
 AS
	/*
		Created: Johnson
		Date: 2014-10-15
		Task: Update transfer status after clear balance
		DB: DBCUST/CustDB
		
		Revision:
		
		Parameter's Explanation:
			
	*/
BEGIN
	SET NOCOUNT ON
	
	UPDATE Acc_ClearBalanceList WITH(UPDLOCK,ROWLOCK)
	SET status = 'completed', 
		LastTransfer = GETDATE(),
		msg = ''
	WHERE custid = @custid
	
END
GO 


