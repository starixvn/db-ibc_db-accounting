/*<info serverAlias="DBAGE-bodb_AGE" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE bodb_Age
GO

CREATE PROCEDURE [dbo].[Acc_CustomerDateLimitDel] @userId INT
	,@custId INT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20180426@Razor
	DB: DBAGE/bodb_AGE
	Task: 

	Revisions:
		-20180522@Razor: init - [Readmine: #95553]
		
	Param's Explanation:		
		• @custId: the ID of customer.
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
		,@endRun DATETIME
		,@duration INT
		,@LogSPData VARCHAR(max)
		,@ActionID INT
		,@minDate DATETIME
		,@limitDays INT

	SELECT @startRun = GETDATE()
		,@ActionID = 31502

	SELECT @minDate = MinDate
		,@limitDays = LimitDays
	FROM dbo.Age_CustDateLimit WITH (NOLOCK)
	WHERE CustId = @custID

	IF (
			@minDate IS NOT NULL
			OR @limitDays IS NOT NULL
			)
	BEGIN
		BEGIN TRY
			DELETE
			FROM dbo.Age_CustDateLimit
			WHERE CustId = @custID
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg = 'Error! Error when deleting customer date limit.'
				,@ErrCode = 101
		END CATCH

		SELECT @LogSPData = '<Acc_CustomerDateLimitDel custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' + 'LimitDays="' + COALESCE(CAST(@limitDays AS VARCHAR(10)), SPACE(1)) + '" ' + 'minDate="' + COALESCE(CAST(@minDate AS VARCHAR(20)), SPACE(1)) + '" ' + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' + 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'

		SET @endRun = GETDATE()
		SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP @UserID = @userID
			,@CustID = @custID
			,@ActionID = @ActionID
			,@TrackingValue = @LogSPData
			,@duration = @duration
	END
END
GO


