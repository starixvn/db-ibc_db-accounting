/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_LicenseeTransferCode_Update
	@TransferMonthDate	SMALLDATETIME,
	@EndMonthDate		DATE,
	@currentDate		DATETIME,
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				VARCHAR(4000) = '' OUTPUT,
	@Environment		VARCHAR(50) =	'LOCAL'

AS
/*
	Create: 20220803@Danny
	Task: 112454 - NAP - Automate the Finance Transfer process for Licensee 
	DB: DBTXN/bodb02

	Revisions:
		- 20220803@Danny: Update LicenseeTransferCode status [Redmine: #175253]
		 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE  @newStatus					VARCHAR(10) = 'New'
			,@statusInProgress			VARCHAR(10) = 'InProgress'
			,@completedStatus			VARCHAR(10) = 'Completed'
			,@failedStatus				VARCHAR(10) = 'Failed'

	DECLARE @strLicInfoCompleted VARCHAR(MAX)
	SELECT @strLicInfoCompleted = CAST((
			SELECT DISTINCT 
				LicenseeName AS '@l',
				ToCustID AS '@c',
				FromDate AS '@fd'
			FROM (
				SELECT pol.LicenseeName, pol.ToCustID, c.FromDate
					,SUM (CASE WHEN [Status] = @completedStatus THEN 1 ELSE 0 END) AS CompletedCount
					,SUM (CASE WHEN [Status] = @failedStatus THEN 1 ELSE 0 END) AS FailedCount
					,SUM (CASE WHEN [Status] = @newStatus THEN 1 ELSE 0 END) AS NewCount
				FROM dbo.LicenseeTransferPool pol WITH(NOLOCK)
					INNER JOIN DBCUST.bodb_licensee.dbo.LicenseeTransferCode c WITH(NOLOCK)
						ON c.LicenseeName = pol.LicenseeName AND pol.ToCustID = c.CustId 
							AND @TransferMonthDate BETWEEN c.FromDate AND c.ToDate
				WHERE MonthDate = @endMonthDate 
					AND (
							( pol.LicenseeName IN ('Athena000', 'spondemo', 'SampleSite') AND @Environment IN ('LOCAL','UAT','SIT') )
							OR @Environment  = 'PROD'
						)
				GROUP BY pol.LicenseeName, pol.ToCustID, c.FromDate
			) AS r
			WHERE r.FailedCount = 0 AND r.NewCount = 0 -- ALL completed
			FOR XML PATH('r'), ROOT('root'), TYPE
	) AS VARCHAR(MAX))

	EXEC DBCUST.bodb_licensee.dbo.Acc_LicenseeTransfer_Update
		@LicenseeInfo		= @strLicInfoCompleted
		,@LastMonthDate		= @endMonthDate
		,@LastTransferDate	= @currentDate
		,@ErrCode			= @ErrCode OUTPUT
		,@ErrMsg			= @ErrMsg OUTPUT
END
GO


