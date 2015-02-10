USE [bodb_report]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

USE [bodb_report]
GO

ALTER DATABASE [bodb_report] ADD FILEGROUP [rptStatement]
GO

ALTER DATABASE [bodb_report] ADD FILE (
	NAME = N'rptStatement_01'
	,FILENAME = N'D:\IBC_DB\bodb_Report\STATEMENT\rptStatement_01.ndf'
	,SIZE = 3072 KB
	,FILEGROWTH = 10240 KB
	) TO FILEGROUP [rptStatement]
GO

CREATE TABLE [dbo].[rptStatement] (
	[WinlostDate] [DATE] NOT NULL
	,[Custid] [int] NOT NULL
	,[OpeningBalance] [money] NULL
	,[VoidAmt] [money] NULL
	,[Turnover] [money] NULL
	,[NetTurnover] [money] NULL
	,[TransferAmt] [money] NULL
	,[Winlost] [money] NULL
	,[Comm] [money] NULL
	,[ClosingBalance] [money] NULL
	,CONSTRAINT [CIX_rptStatement_winlostdate_custid] PRIMARY KEY CLUSTERED 
		([WinlostDate] ASC, [Custid] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [rptStatement]
	) ON [rptStatement]
GO
