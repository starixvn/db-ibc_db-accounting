/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_LicenseeTransfer_Pool_UpdateStatus
	@Status		VARCHAR(10),
	@Error		VARCHAR(200),
	@EndMonthDate	DATE,
	@FromCustId	INT,
	@ToCustID	INT
AS
/*
	Create: 20220803@Danny
	Task: 112454 - NAP - Automate the Finance Transfer process for Licensee 
	DB: DBTXN/bodb02

	Revisions:
		- 20220803@Danny: Update LicenseeTransfer_Pool status [Redmine: #175253]
		 
*/
BEGIN
	SET NOCOUNT ON

	UPDATE dbo.LicenseeTransferPool WITH(ROWLOCK, UPDLOCK)
	SET	 [Status] = @Status, Error = @Error
	WHERE MonthDate = @EndMonthDate	
		AND FromCustId = @fromCustID 
		AND ToCustID = @toCustId

END
GO
