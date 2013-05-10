CREATE PROCEDURE [dbo].[Acc_FinanceTransferMulDelTmpExcel]	
	@UserID INT,	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT	
AS
/*
Created: Johnny
Task : Delete All Data of table Acc_CustFinanceTransfer belong @UserID
DB: DBACC/BODB_ACC
Original: 
Revisions:	
	- 20130201@Elodie: Change link server DB03 to DBPOLICY
	- 20130224@Lukas: move SP to new database bodb_acc
*/
SET NOCOUNT ON
		
	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[AutomateFinanceTransfer]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
		
	IF EXISTS (SELECT 1 FROM dbo.Acc_CustFinanceTransfer WHERE UserID=@UserID)
	BEGIN
		DELETE FROM dbo.Acc_CustFinanceTransfer WHERE UserID=@UserID
		
		IF @@ERROR <> 0
		BEGIN
			SELECT	@ErrMsg = 'Delete process is unsuccessful.',
					@ErrCode = 103
			RETURN			
		END
	END

GO
GRANT EXECUTE ON [dbo].[Acc_FinanceTransferMulDelTmpExcel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_FinanceTransferMulDelTmpExcel] TO [vnteam]