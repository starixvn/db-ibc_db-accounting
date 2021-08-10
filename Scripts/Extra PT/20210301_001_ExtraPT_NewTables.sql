/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20210301@Percy
	DB: DBCUST-CustDB
	Task: New tables for auto set primary extra pt group
*/

USE CustDB
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
) ON DATA
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
) ON DATA
GO