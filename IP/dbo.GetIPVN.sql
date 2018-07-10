/*<info serverAlias="DBCUST-IPDB" executers="bodbAdmin,bodbAdminNet,bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
 USE [IPDB]
GO

ALTER PROCEDURE [dbo].[GetIPVN]
AS
/*
Created: HuyNguyen
Task : Get IP VN ranges 
DB: DBCUST.IPDB
Original:Accounting site
Revisions:
	- 20150205@Johnson: get IP VN from IPTable [redmine: #30656]
	- 20180710@Razor: Get IP VN from IP table mini
*/		
	SET NOCOUNT ON

	SELECT ipFROM,ipTO, 0 as isManual from ipTable_mini with (nolock)
	WHERE countrySHORT = 'vn'
GO