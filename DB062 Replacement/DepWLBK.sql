ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLBK_MAX] 
 GO 
	ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWL_MAX', FILENAME = N'M:\IBC_DB\bodb_Report\DepWLBK\DepWLBK_MAX.ndf' , SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [DepWLBK_MAX] 
 GO 
--------
ALTER DATABASE [bodb_Report] ADD FILEGROUP [DepWLBK_Index] 
 GO 
	ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLBK_Index_01', FILENAME = N'M:\IBC_DB\bodb_Report\DepWLBK\DepWLBK_Index_01.ndf' , SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [DepWLBK_Index] 
 GO 
 ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLBK_Index_02', 
FILENAME = N'M:\IBC_DB\bodb_Report\DepWLBK\DepWLBK_Index_02.ndf' , 
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [DepWLBK_Index] 
GO
 ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLBK_Index_03', 
FILENAME = N'M:\IBC_DB\bodb_Report\DepWLBK\DepWLBK_Index_03.ndf' , 
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [DepWLBK_Index] 
GO
 ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLBK_Index_04', 
FILENAME = N'M:\IBC_DB\bodb_Report\DepWLBK\DepWLBK_Index_04.ndf' , 
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [DepWLBK_Index] 
GO
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'DepWLBK_Index_05', 
FILENAME = N'M:\IBC_DB\bodb_Report\DepWLBK\DepWLBK_Index_05.ndf' , 
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [DepWLBK_Index] 

-----------
CREATE PARTITION FUNCTION pf_DepWLBK_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(  
    
    '2008/01/31 23:59:00'    
)

--Create partition schema
CREATE PARTITION SCHEME ps_DepWLBK_monthly
AS PARTITION pf_DepWLBK_monthly
TO
    ( 
	[DepWLBK_08M01],	
	[DepWLBK_MAX]
	
 )                
GO
-------
--Excel Script
-------
CREATE TABLE [dbo].[rptDepWinlost_bk2](
	[winlostdate] [smalldatetime] NOT NULL,
	[custid] [int] NOT NULL,
	[currency] [int] NOT NULL,
	[OpeningBalance] [money] NULL,
	[Deposit] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk2_Deposit]  DEFAULT ((0)),
	[Withdrawal] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk2_Withdrawal]  DEFAULT ((0)),
	[Aff2MemTransfer] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk2_Aff2MemTransfer]  DEFAULT ((0)),
	[Bonus] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk2_Bonus]  DEFAULT ((0)),
	[Adjustment] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk2_Adjustment]  DEFAULT ((0)),
	[Turnover] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk2_Turnover]  DEFAULT ((0)),
	[Outstanding] [money] NULL,
	[Winloss] [money] NOT NULL,
	[ClosingBalance] [money] NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[actualrate] [float] NULL,
	[Transfer3rd] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk2_Transfer3rd]  DEFAULT ((0)),
	[DrawGame] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_bk2_DrawGame]  DEFAULT ((0))
) ON [DepWL_bk]

GO

/****** Object:  Index [CIX_rptDepWinlost_bk2]    Script Date: 12/13/2010 08:35:53 ******/
CREATE UNIQUE CLUSTERED INDEX [CIX_rptDepWinlost_bk2] ON [dbo].[rptDepWinlost_bk2] 
(
	[winlostdate] ASC,
	[custid] ASC,
	[currency] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)  ON [ps_DepWLBK_monthly]([winlostdate])
GO

/****** Object:  Index [IX_srecommend]    Script Date: 12/13/2010 08:35:53 ******/
CREATE NONCLUSTERED INDEX [IX_srecommend] ON [dbo].[rptDepWinlost_bk2] 
(
	[srecommend] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DepWLBK_Index]
GO

/****** Object:  Index [IX_Winlostdate]    Script Date: 12/13/2010 08:35:53 ******/
CREATE NONCLUSTERED INDEX [IX_Winlostdate] ON [dbo].[rptDepWinlost_bk2] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DepWLBK_Index]
-------



EXEC SP_RENAME 'rptDepWinlost_bk', 'rptDepWinlost_bk_del'
GO
EXEC SP_RENAME 'rptDepWinlost_bk2', 'rptDepWinlost_bk'
------------
drop table rptDepWinlost_bk_del
--------
USE [bodb_Report]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk_02]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk_03]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk_04]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk_05]
GO
ALTER DATABASE [bodb_Report] REMOVE FILEGROUP [DepWL_bk]
GO
USE [bodb_Report]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk_Index]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk_Index_02]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk_Index_03]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk_Index_04]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [DepWL_bk_Index_05]
GO
ALTER DATABASE [bodb_Report] REMOVE FILEGROUP [DepWL_bk_Index]
GO
