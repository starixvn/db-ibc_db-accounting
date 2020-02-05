/*<info serverAlias="DBCUST-CustDB" ></info>*/

USE [CustDB]
GO
/*
   Created: Malcolm
	Date: 2020-02-04
	Task:   Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	DB: DBCUST/CustDB

	Revisions:
		- 20200122@Malcolm:  Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	Parameter's explaination:
*/
CREATE TABLE [dbo].[CS_ReportPermission](
	[CustID] [int] NOT NULL,
	[IsViewAllPeriod] [bit] NULL
	CONSTRAINT [PK_CS_ReportPermission] PRIMARY KEY CLUSTERED ([CustID]) ON [DATA]
) ON [DATA]
GO

