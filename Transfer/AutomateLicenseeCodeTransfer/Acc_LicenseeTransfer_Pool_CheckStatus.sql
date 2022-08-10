/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_LicenseeTransfer_Pool_CheckStatus
	@EndMonthDate	DATE,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(4000) = '' OUTPUT
AS
/*
	Create: 20220803@Danny
	Task: 112454 - NAP - Automate the Finance Transfer process for Licensee 
	DB: DBTXN/bodb02

	Revisions:
		- 20220803@Danny: SELECT LicenseeTransfer_Pool status [Redmine: #175253]
		 
*/
BEGIN
	SET NOCOUNT ON

	IF EXISTS (	SELECT 1 
				FROM dbo.LicenseeTransferPool pol WITH(NOLOCK) 
				WHERE    [Status] = 'Failed'
					AND	 MonthDate = @endMonthDate 
			  )
	BEGIN
		SELECT @ErrCode		= 200
			, @ErrMsg		= 'Some transfer processes of Licensee are failed. '
	END

END
GO
