--IN DBSPARE
ALTER DATABASE [bodb_Archive07] ADD FILEGROUP [STATEMENT_07ALL]
GO
ALTER DATABASE [bodb_Archive07] ADD FILE ( NAME = N'STATEMENT_07ALL', FILENAME = N'P:\Archive\2007\STATEMENT\STATEMENT_07ALL.ndf' , SIZE = 2048KB , FILEGROWTH = 16384KB ) TO FILEGROUP [STATEMENT_07ALL]
GO
------------

CREATE TABLE [dbo].[Statement_2007](
	[custid] [int] NULL,
	[accdate] [datetime] NULL,
	[totalamt] [money] NULL,
	[transtype] [nvarchar](50) NULL,
	[transdesc] [nvarchar](300) NULL
)

GO

/****** Object:  Index [IX_Statement_2007]    Script Date: 03/29/2011 03:08:58 ******/
CREATE CLUSTERED INDEX [IX_Statement_2007] ON [dbo].[Statement_2007] 
(
	[custid] ASC,
	[accdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [STATEMENT_07ALL]
------
--IMPORT DATA