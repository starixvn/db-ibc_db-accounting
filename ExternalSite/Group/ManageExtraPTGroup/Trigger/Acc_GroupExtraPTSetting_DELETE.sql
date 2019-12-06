USE [CustDB]
GO

ALTER TRIGGER [dbo].[Acc_GroupExtraPTSetting_DELETE] ON [dbo].[Acc_GroupExtraPTSetting]
AFTER DELETE
AS

/*
	Created: 20180831@Sophia
	DB: DBCUST.CUSTDB

	Revisions:
		- 20180831@Sophia: Copy data from Acc_GroupExtraPTSetting to Acc_GroupExtraCommRateSetting for Poker Games [RedmineID: #100168]
		- 20191201@Percy: Remove Poker Games (inactive products), add UplineId (CN88) [RedmineID: #]
*/

BEGIN
	SET NOCOUNT ON
	
END
GO