/*<info serverAlias="DBAGE-bodb_AGE" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE bodb_Age
GO

CREATE PROCEDURE [dbo].[Acc_CustomerDateLimitIns] @userId INT
	,@custId INT
	,@limitDays INT = 0
	,@minDate DATETIME = NULL
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

	SELECT @startRun = GETDATE()
		,@ActionID = 31501

	BEGIN TRY
		INSERT INTO dbo.Age_CustDateLimit (
			CustId
			,MinDate
			,LimitDays
			)
		SELECT DISTINCT @custId
			,@minDate
			,@limitDays
		FROM dbo.Age_CustDateLimit WITH (NOLOCK)
		WHERE NOT EXISTS (
				SELECT CustId
				FROM dbo.Age_CustDateLimit WITH (NOLOCK)
				WHERE CustId = @custId
				)
	END TRY

	BEGIN CATCH
		SELECT @ErrMsg = 'Error! Error when adding customer date limit.'
			,@ErrCode = 101
	END CATCH

	SELECT @LogSPData = '<Acc_CustomerDateLimitIns custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' + 'LimitDays="' + COALESCE(CAST(@limitDays AS VARCHAR(10)), SPACE(1)) + '" ' + 'minDate="' + COALESCE(CAST(@minDate AS VARCHAR(20)), SPACE(1)) + '" ' + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' + 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP @UserID = @userID
		,@CustID = @custID
		,@ActionID = @ActionID
		,@TrackingValue = @LogSPData
		,@duration = @duration
END
GO


