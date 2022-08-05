/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceCrossTransferMulUpd_WrtieLog]
    @UserID			INT,    
    @FileName		VARCHAR(100),
    @FileSize		INT,
    @Ip				VARCHAR(45) = '',
	@TotalUsers		INT, -- Number of user success
    @ErrCode		INT = 0 OUTPUT ,
    @ErrMsg			NVARCHAR(200) = '' OUTPUT
AS 
/*
Created: 
Task : Init. SP
DB: DBTXN/BODB02
Original: 
Revisions:	
	- 20220805@Danny: insert transfer transaction.
*/
BEGIN
    SELECT @TotalUsers = -@TotalUsers
    
	DECLARE @Doing nvarchar(500)
	
	SELECT @Doing ='<Acc_FinanceCrossTransferMulUpd TotalUser="'
            + CONVERT(VARCHAR(20), @TotalUsers) + '" FileName="' + @FileName
            + '" Size="' + CONVERT(VARCHAR(20), @FileSize) + '" />'			
            
    BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @TotalUsers, @ToCustID = 0, @IP = @IP, @Doing = @Doing
	END TRY
	BEGIN CATCH
		select @Doing = '<Acc_FinanceCrossTransferMulUpd TotalUser="' + CONVERT(VARCHAR(20), @TotalUsers) + 
						'" FileName="' + @FileName + 
						'" Size="' + CONVERT(VARCHAR(20), @FileSize) + 
						'" ErrMsg="' + error_message() + '" />'
						
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = @TotalUsers, @ToCustID = 0, @IP = @IP, @Doing = @Doing
	END CATCH
END