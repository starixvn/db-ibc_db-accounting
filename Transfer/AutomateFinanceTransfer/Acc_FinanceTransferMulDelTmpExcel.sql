/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_FinanceTransferMulDelTmpExcel]	
	@UserID INT,	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT	
AS
/*
Created: Johnny
Task : Delete All Data of table Acc_CustFinanceTransfer belong @UserID
DB: DBACC/BODB02 -> DBCUST.CustDB
Original: 
Revisions:	
	- 20130201@Elodie: Change link server DB03 to DBPOLICY
	- 20130224@Lukas: move Acc_CustFinanceTransfer to new database bodb_acc
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
*/
SET NOCOUNT ON
		
	--Check permission for account site
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[AutomateFinanceTransfer]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
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