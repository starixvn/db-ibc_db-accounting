/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet"  isFunction="0" isNested="0"></info>*/
USE [CustDB]
GO

CREATE TABLE [dbo].[CS_ReportPermission](
	[CustID] [int] NOT NULL,
	[IsViewAllPeriod] [bit] NULL
	CONSTRAINT [PK_CS_ReportPermission] PRIMARY KEY CLUSTERED ([CustID]) ON [DATA]
) ON [DATA]
GO

