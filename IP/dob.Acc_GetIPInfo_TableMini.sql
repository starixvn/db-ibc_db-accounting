/*<info serverAlias="DBCUST-IPDB" executers="bodbAdmin,bodbAdminNet,bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/

USE [IPDB]
GO
ALTER PROCEDURE [dbo].[Acc_GetIPInfo_TableMini]
	@isIPV6 BIT = 0,
	@IPNumber BIGINT
AS
/*
	Created by: Alvin
	Date: 2019-11-07
	Task: Get IP Info from table IP Mini
	DB: DB02.IPDB 
	Original: GetIPInfo_TableMini
	Revisions:	
	- 20191107@Alvin: Init
	
*/
BEGIN
	SET NOCOUNT ON

	IF @isIPV6 = 0
	BEGIN
		SELECT countrySHORT, countryLONG
		FROM ipTable_mini WITH (NOLOCK)
		WHERE @IPNumber BETWEEN ipFrom AND ipTo
	END
	ELSE
	BEGIN
		SELECT TOP 0 countrySHORT, countryLONG
		FROM ipTable_mini WITH (NOLOCK)
		WHERE @IPNumber BETWEEN ipFrom AND ipTo
	END
END