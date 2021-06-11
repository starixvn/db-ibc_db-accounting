/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20210301@Percy
	DB: DBCUST-CustDB
	Task: Grant permission
*/

USE CustDB
GO

GRANT SELECT ON dbo.Acc_GroupExtraPT_Product TO bodbAdminNet AS dbo
GO
GRANT SELECT ON dbo.Acc_GroupExtraPT2_Product TO bodbAdminNet AS dbo
GO

GRANT SELECT ON dbo.Acc_GroupExtraPTSetting TO bodbAdminNet AS dbo
GO
GRANT INSERT ON dbo.Acc_GroupExtraPTSetting TO bodbAdminNet AS dbo
GO
GRANT UPDATE ON dbo.Acc_GroupExtraPTSetting TO bodbAdminNet AS dbo
GO
GRANT DELETE ON dbo.Acc_GroupExtraPTSetting TO bodbAdminNet AS dbo
GO

GRANT SELECT ON dbo.Acc_GroupExtraPT2Setting TO bodbAdminNet AS dbo
GO
GRANT INSERT ON dbo.Acc_GroupExtraPT2Setting TO bodbAdminNet AS dbo
GO
GRANT UPDATE ON dbo.Acc_GroupExtraPT2Setting TO bodbAdminNet AS dbo
GO
GRANT DELETE ON dbo.Acc_GroupExtraPT2Setting TO bodbAdminNet AS dbo
GO