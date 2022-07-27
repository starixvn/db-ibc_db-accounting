/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[SiteDb_Acc_balance_revert]
(
	@Refno					BIGINT,
	@IP						varchar(45)='',
	@UserID					INT,
	@ErrCode				INT				= 0  OUTPUT,
	@ErrMsg					NVARCHAR(200)	= '' OUTPUT
) AS
/*
Task: Check input
Created: 
DB: DBTXN/bodb02
Revisions:
	- 20220719@Danny: Init. SP rollback [Redmine: #175253]
						   
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Amt MONEY = 0, @CustID INT, @rn TINYINT = 1, @RoleID TINYINT
	DECLARE @TransIDs AS TABLE (transID BIGINT)	
	DECLARE @CustRollback AS TABLE (CustId INT, Amt MONEY, rn TINYINT)	

	INSERT INTO @CustRollback (CustId, Amt, rn)
	SELECT CustID ,SUM(winlost - Actual_Stake), ROW_NUMBER() OVER(ORDER BY CustID)
	FROM dbo.transfer WITH(NOLOCK)
	WHERE	refno = @Refno
	GROUP BY CustID

	INSERT INTO @TransIDs(transID)
	SELECT transid FROM dbo.transfer WITH(NOLOCK) WHERE	refno = @Refno

	WHILE EXISTS (SELECT TOP 1 1 FROM @CustRollback WHERE rn = @rn)
	BEGIN

		SELECT	@CustID = CustID, @Amt = Amt
		FROM	@CustRollback 
		WHERE rn = @rn

		SELECT @RoleID = RoleID 
		FROM CustDB.dbo.Customer WITH(NOLOCK) WHERE CustID = @CustID

		IF @Amt > 0 AND @RoleID = 1
			EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Amt, @Type = 2, @IsForced = 1, @ErrCode = @ErrCode OUTPUT
		
		IF @Amt < 0 AND @RoleID = 1
		BEGIN
			DECLARE @balance MONEY
			SELECT @balance =  ABS(@Amt)
			EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @balance, @Type = 2
		END

		SELECT @rn = @rn + 1

	END

	-- transfer
	UPDATE dbo.Transfer WITH(ROWLOCK, UPDLOCK)
	SET		custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME()
	where refno = @refno 
	
	UPDATE Transfer_Coll WITH(ROWLOCK, UPDLOCK)
	SET		custid = 0, Debit = 0, Credit = 0, RepUpdateTime = SYSDATETIME()
	WHERE   TransID IN (SELECT TransID FROM @TransIDs)
		
	UPDATE TransferInfo WITH(ROWLOCK,  UPDLOCK)
	SET		IsDel = 1, RepUpdateTime = SYSDATETIME()
	WHERE  TransID IN (SELECT TransID FROM @TransIDs)

	DECLARE @LogData nvarchar(200)
	Select @LogData = 'Revert transaction for :' + convert(varchar(20), @CustID) + ' Ref.NO ' + convert(varchar(20), @RefNo) 

	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
	END TRY
	BEGIN CATCH
		Select @LogData = @LogData + ' ErrMsg=' + error_message()
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
	END CATCH

END
GO

