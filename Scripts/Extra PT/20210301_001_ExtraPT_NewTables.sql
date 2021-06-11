/*<info serverAlias="DBPOL-NAP_UserControl"></info>*/
/*
	Created: 20210301@Percy
	DB: DBPOL-NAP_UserControl
	Task: New tables for auto set primary extra pt group
*/

USE NAP_UserControl
GO

CREATE TABLE dbo.EaGroupHeadline
(
	GroupHeadlineId	INT NOT NULL,
	GroupId			INT NOT NULL,
	GroupName		VARCHAR(100) NOT NULL,
	SiteId			INT NOT NULL,
	ExchangeId		INT NOT NULL,
	GroupTypeId		TINYINT,
	EffectiveDate	DATETIME,
	EndDate			DATETIME,
	CONSTRAINT PK_EaGroupHeadline PRIMARY KEY CLUSTERED
	(
		GroupHeadlineId ASC,
		GroupId ASC,
		GroupName ASC,
		SiteId ASC,
		ExchangeId ASC
	)
) ON NAP_UserControl_table
GO

GRANT SELECT ON dbo.EaGroupHeadline TO bodbAdminNet AS dbo
GO
GRANT INSERT ON dbo.EaGroupHeadline TO bodbAdminNet AS dbo
GO
GRANT UPDATE ON dbo.EaGroupHeadline TO bodbAdminNet AS dbo
GO
GRANT DELETE ON dbo.EaGroupHeadline TO bodbAdminNet AS dbo
GO

CREATE TABLE dbo.Acc_CustGroup_Queue
(
	CustId		INT NOT NULL,
	GroupName	VARCHAR(50) NOT NULL,
	EndDate		DATE,
	CreatedTime DATETIME CONSTRAINT DF_Acc_CustGroup_Queue_CreatedTime DEFAULT(GETDATE()),
	CONSTRAINT PK_Acc_CustGroup_Queue PRIMARY KEY
	(
		CustId ASC,
		GroupName ASC
	)
) ON NAP_UserControl_table
GO

GRANT SELECT ON dbo.Acc_CustGroup_Queue TO bodbAdminNet AS dbo
GO
GRANT INSERT ON dbo.Acc_CustGroup_Queue TO bodbAdminNet AS dbo
GO
GRANT UPDATE ON dbo.Acc_CustGroup_Queue TO bodbAdminNet AS dbo
GO
GRANT DELETE ON dbo.Acc_CustGroup_Queue TO bodbAdminNet AS dbo
GO

