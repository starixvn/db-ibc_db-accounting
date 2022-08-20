/*<info serverAlias="DBCTG-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Acc_ExchangeRate_InvalidTransfer_Del]
	@refNo  bigint = null
AS
/*
	Created: N/A
	Task : 
	DB: DBCTG.bodb02

	Revisions:
		- 20220818@Danny: Create SP [Redmine:99462]				   
*/
BEGIN
	SET NOCOUNT ON 
	IF EXISTS (SELECT 1 FROM dbo.Acc_ExchangeRate_InvalidTransfer WITH(NOLOCK) WHERE refno = @refNo )
	BEGIN 
		DELETE dbo.Acc_ExchangeRate_InvalidTransfer WITH(ROWLOCK, UPDLOCK) WHERE refno = @refNo
	END 
END