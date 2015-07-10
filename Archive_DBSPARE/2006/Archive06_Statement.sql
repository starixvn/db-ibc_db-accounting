USE [bodb_Report]
GO
/****** Object:  Table [dbo].[STATEMENT_06ALL]    Script Date: 03/29/2011 02:56:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[STATEMENT_06ALL](
	[custid] [int] NULL,
	[accdate] [datetime] NULL,
	[totalamt] [money] NULL,
	[transtype] [nvarchar](50) NULL,
	[transdesc] [nvarchar](300) NULL
)

GO

/****** Object:  Index [IX_STATEMENT_06ALL]    Script Date: 03/29/2011 02:56:24 ******/
CREATE CLUSTERED INDEX [IX_STATEMENT_06ALL] ON [dbo].[STATEMENT_06ALL] 
(
	[custid] ASC,
	[accdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [STATEMENT_06ALL]
GO
GRANT SELECT ON [dbo].[STATEMENT_06ALL] TO [bodbLicenseeNet]
GO
GRANT SELECT ON [dbo].[STATEMENT_06ALL] TO [public]
--------------
USE [bodb_Report]
GO
/****** Object:  Table [dbo].[STATEMENT_07ALL]    Script Date: 03/29/2011 02:56:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[STATEMENT_07ALL](
	[custid] [int] NULL,
	[accdate] [datetime] NULL,
	[totalamt] [money] NULL,
	[transtype] [nvarchar](50) NULL,
	[transdesc] [nvarchar](300) NULL
)

GO

/****** Object:  Index [IX_STATEMENT_07ALL]    Script Date: 03/29/2011 02:56:24 ******/
CREATE CLUSTERED INDEX [IX_STATEMENT_07ALL] ON [dbo].[STATEMENT_07ALL] 
(
	[custid] ASC,
	[accdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [STATEMENT_07ALL]
GO
GRANT SELECT ON [dbo].[STATEMENT_07ALL] TO [bodbLicenseeNet]
GO
GRANT SELECT ON [dbo].[STATEMENT_07ALL] TO [public]
-------------
--2. Switch the old data out – into the staging table.

ALTER TABLE Statement SWITCH PARTITION 1 TO [STATEMENT_06ALL]
GO
--3. Alter the partition function to "remove" the boundary point for 'Jan-2008'.
ALTER PARTITION FUNCTION pf_STATEMENT_monthly() MERGE RANGE ('2006-12-31 23:59:59.997')
GO

ALTER TABLE Statement SWITCH PARTITION 1 TO [STATEMENT_07ALL]
GO
--3. Alter the partition function to "remove" the boundary point for 'Jan-2008'.
ALTER PARTITION FUNCTION pf_STATEMENT_monthly() MERGE RANGE ('2007-12-31 23:59:59.997')
GO
------------------------------
--IN DBSPARE
ALTER DATABASE [bodb_Archive06] ADD FILEGROUP [STATEMENT_06ALL]
GO
ALTER DATABASE [bodb_Archive06] ADD FILE ( NAME = N'STATEMENT_06ALL', FILENAME = N'P:\Archive\2006\STATEMENT\STATEMENT_06ALL.ndf' , SIZE = 2048KB , FILEGROWTH = 16384KB ) TO FILEGROUP [STATEMENT_06ALL]
GO
------------

CREATE TABLE [dbo].[Statement_2006](
	[custid] [int] NULL,
	[accdate] [datetime] NULL,
	[totalamt] [money] NULL,
	[transtype] [nvarchar](50) NULL,
	[transdesc] [nvarchar](300) NULL
)

GO

/****** Object:  Index [IX_Statement_2006]    Script Date: 03/29/2011 03:08:58 ******/
CREATE CLUSTERED INDEX [IX_Statement_2006] ON [dbo].[Statement_2006] 
(
	[custid] ASC,
	[accdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [STATEMENT_06ALL]
------
--IMPORT DATA
--------------
--DELETE DATA ON DB06
DROP TABLE STATEMENT_06ALL
GO
DROP TABLE STATEMENT_07ALL
-------
USE [bodb_Report]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [STATEMENT_06ALL]
GO
ALTER DATABASE [bodb_Report] REMOVE FILEGROUP [STATEMENT_06ALL]
GO
USE [bodb_Report]
GO
ALTER DATABASE [bodb_Report]  REMOVE FILE [STATEMENT_07ALL]
GO
ALTER DATABASE [bodb_Report] REMOVE FILEGROUP [STATEMENT_07ALL]
GO
