USE [CustDB]
GO

CREATE TABLE [dbo].[CS_ReportPermission](
	[CustID] [int] NOT NULL,
	[IsViewAllPeriod] [bit] NULL
	CONSTRAINT PK_CS_ReportPermission PRIMARY KEY([CustID])
) 
GO
