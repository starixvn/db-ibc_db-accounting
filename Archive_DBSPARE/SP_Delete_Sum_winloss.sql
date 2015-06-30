 USE [bodb_Archive]
GO
/****** Object:  Table [dbo].[sum_winloss_2005]    Script Date: 12/02/2009 03:11:55 ******/
DROP TABLE [dbo].[sum_winloss_2005]
GO
--wait for a while
USE [bodb_Archive]
GO
ALTER DATABASE [bodb_Archive]  REMOVE FILE [bodb_Archive_SUM_2005]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [SUM_2005]
GO
--------------
 USE [bodb_Archive]
GO
/****** Object:  Table [dbo].[sum_winloss_2006]    Script Date: 12/02/2009 03:11:55 ******/
DROP TABLE [dbo].[sum_winloss_2006]
GO
--wait for a while
USE [bodb_Archive]
GO
ALTER DATABASE [bodb_Archive]  REMOVE FILE [bodb_Archive_SUM_2006]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [SUM_2006]
GO
----
 USE [bodb_Archive]
GO
/****** Object:  Table [dbo].[sum_winloss_2007]    Script Date: 12/02/2009 03:11:55 ******/
DROP TABLE [dbo].[sum_winloss_2007]
GO
--wait for a while
USE [bodb_Archive]
GO
ALTER DATABASE [bodb_Archive]  REMOVE FILE [bodb_Archive_SUM_2007]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [SUM_2007]
GO
-------------------------------------------------------
--2008
--MOVE OUT DATA FROM SUM_WINLOSS_OLD

--When we need to move out the data into sum_winloss_2008.
--Let's say we need to move data of Jan-2008

--1. Create staging table SUM_08M01 on the same [SUM_08M01] filegroup.
--Need to check the field names which might be changed already
CREATE TABLE [dbo].[SUM_08M01](
    [keyid] [INT] IDENTITY(1,1) NOT NULL,
    [winlostdate] [DATETIME] NULL,
    [username] [NVARCHAR](50) NULL,
    [custid] [INT] NULL,
    [roleid] [INT] NULL,
    [recommend] [INT] NULL,
    [mrecommend] [INT] NULL,
    [srecommend] [INT] NULL,
    [turnover] [MONEY] NULL,
    [winlost] [MONEY] NULL,
    [awinlost] [MONEY] NULL,
    [mwinlost] [MONEY] NULL,
    [swinlost] [MONEY] NULL,
    [playercomm] [MONEY] NULL,
    [comm] [MONEY] NULL,
    [acomm] [MONEY] NULL,
    [scomm] [MONEY] NULL,
    [BetCount] [INT] NULL CONSTRAINT [DF_SUM_08M01_BetCount]  DEFAULT ((0)),
    [grosscomm] [MONEY] NULL CONSTRAINT [DF_SUM_08M01_grosscomm]  DEFAULT ((0)),
    [sporttype] [TINYINT] NOT NULL CONSTRAINT [DF_SUM_08M01_sporttype]  DEFAULT ((0)),
    [bettype] [TINYINT] NOT NULL CONSTRAINT [DF_SUM_08M01_bettype]  DEFAULT ((0))
)

GO

/****** Object:  Index [CIX_sum_winloss]    Script Date: 11/15/2009 01:14:36 ******/
CREATE CLUSTERED INDEX [CIX_sum_winloss] ON [dbo].[SUM_08M01]
(
    [winlostdate] ASC,
    [srecommend] ASC,
    [mrecommend] ASC,
    [recommend] ASC,
    [roleid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SUM_08M01]
GO

--2. Switch the old data out – into the staging table.
ALTER TABLE sum_winloss_old SWITCH PARTITION 1 TO SUM_08M01

--3. Alter the partition function to "remove" the boundary point for 'Jan-2008'.
ALTER PARTITION FUNCTION pf_SUM_monthly() MERGE RANGE ('2008-01-31 23:59:59.997')

--4. Export data to sum_winloss_2008

--5. Drop table SUM_08M01
Drop table SUM_08M01

--6. Drop [SUM_08M01] filegroup
USE [bodb_Summary]
GO
ALTER DATABASE [bodb_Summary]  REMOVE FILE [SUM_08M01]
GO
ALTER DATABASE [bodb_Summary] REMOVE FILEGROUP [SUM_08M01]
GO
--------------------------
USE [bodb_Summary]
GO
/****** Object:  Table [dbo].[SUM2_08M07]    Script Date: 03/28/2011 05:13:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SUM2_08M07](
	[keyid] [bigint] IDENTITY(1,1) NOT NULL,
	[winlostdate] [smalldatetime] NULL,
	[username] [nvarchar](50) NULL,
	[custid] [int] NULL,
	[roleid] [int] NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[turnover] [money] NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[BetCount] [int] NULL CONSTRAINT [DF_SUM2_08M072_BetCount]  DEFAULT ((0)),
	[grosscomm] [money] NULL CONSTRAINT [DF_SUM2_08M072_grosscomm]  DEFAULT ((0)),
	[sporttype] [smallint] NOT NULL CONSTRAINT [DF_SUM2_08M072_sporttype]  DEFAULT ((0)),
	[bettype] [smallint] NOT NULL CONSTRAINT [DF_SUM2_08M072_bettype]  DEFAULT ((0))
)

GO

/****** Object:  Index [CIX_sum_winloss]    Script Date: 03/28/2011 05:13:05 ******/
CREATE CLUSTERED INDEX [CIX_sum_winloss] ON [dbo].[SUM2_08M07] 
(
	[winlostdate] ASC,
	[srecommend] ASC,
	[mrecommend] ASC,
	[recommend] ASC,
	[roleid] ASC,
	[sporttype] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SUM2_08M07]
GO
GRANT SELECT ON [dbo].[SUM2_08M07] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[SUM2_08M07] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[SUM2_08M07] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[SUM2_08M07] TO [bodbExtAccNet]
--------
--2. Switch the old data out – into the staging table.

ALTER TABLE sum_winloss_old SWITCH PARTITION 1 TO SUM2_08M07
GO
--3. Alter the partition function to "remove" the boundary point for 'Jan-2008'.
ALTER PARTITION FUNCTION pf_SUM2_monthly() MERGE RANGE ('2008-07-31 23:59:00.000')
GO

ALTER TABLE sum_winloss_old SWITCH PARTITION 1 TO SUM2_08M08
GO
ALTER PARTITION FUNCTION pf_SUM2_monthly() MERGE RANGE ('2008-08-31 23:59:00.000')
GO

ALTER TABLE sum_winloss_old SWITCH PARTITION 1 TO SUM2_08M09
GO
ALTER PARTITION FUNCTION pf_SUM2_monthly() MERGE RANGE ('2008-09-30 23:59:00.000')
GO

ALTER TABLE sum_winloss_old SWITCH PARTITION 1 TO SUM2_08M10
GO
ALTER PARTITION FUNCTION pf_SUM2_monthly() MERGE RANGE ('2008-10-31 23:59:00.000')
GO

ALTER TABLE sum_winloss_old SWITCH PARTITION 1 TO SUM2_08M11
GO
ALTER PARTITION FUNCTION pf_SUM2_monthly() MERGE RANGE ('2008-11-30 23:59:00.000')
GO

ALTER TABLE sum_winloss_old SWITCH PARTITION 1 TO SUM2_08M12
GO
ALTER PARTITION FUNCTION pf_SUM2_monthly() MERGE RANGE ('2008-12-31 23:59:00.000')
GO
--------
DROP TABLE SUM2_08M07
GO
DROP TABLE SUM2_08M08
GO
DROP TABLE SUM2_08M09
GO
DROP TABLE SUM2_08M10
GO
DROP TABLE SUM2_08M11
GO
DROP TABLE SUM2_08M12
GO
-----------

ALTER DATABASE [bodb_Summary]  REMOVE FILE [SUM2_08M07]
GO
ALTER DATABASE [bodb_Summary] REMOVE FILEGROUP [SUM2_08M07]
GO
ALTER DATABASE [bodb_Summary]  REMOVE FILE [SUM2_08M08]
GO
ALTER DATABASE [bodb_Summary] REMOVE FILEGROUP [SUM2_08M08]
GO
ALTER DATABASE [bodb_Summary]  REMOVE FILE [SUM2_08M09]
GO
ALTER DATABASE [bodb_Summary] REMOVE FILEGROUP [SUM2_08M09]
GO
ALTER DATABASE [bodb_Summary]  REMOVE FILE [SUM2_08M10]
GO
ALTER DATABASE [bodb_Summary] REMOVE FILEGROUP [SUM2_08M10]
GO
ALTER DATABASE [bodb_Summary]  REMOVE FILE [SUM2_08M11]
GO
ALTER DATABASE [bodb_Summary] REMOVE FILEGROUP [SUM2_08M11]
GO
ALTER DATABASE [bodb_Summary]  REMOVE FILE [SUM2_08M12]
GO
ALTER DATABASE [bodb_Summary] REMOVE FILEGROUP [SUM2_08M12]
GO
----------------------------
--1. Create staging table SUM2_09M07 on the same [SUM2_09M07] filegroup.
--Need to check the field names which might be changed already
USE [bodb_Summary]
GO
/****** Object:  Table [dbo].[SUM2_09M07]    Script Date: 08/13/2011 05:13:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SUM2_09M07](
	[keyid] [bigint] IDENTITY(1,1) NOT NULL,
	[winlostdate] [smalldatetime] NULL,
	[username] [nvarchar](50) NULL,
	[custid] [int] NULL,
	[roleid] [int] NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[turnover] [money] NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[BetCount] [int] NULL CONSTRAINT [DF_SUM2_09M072_BetCount]  DEFAULT ((0)),
	[grosscomm] [money] NULL CONSTRAINT [DF_SUM2_09M072_grosscomm]  DEFAULT ((0)),
	[sporttype] [smallint] NOT NULL CONSTRAINT [DF_SUM2_09M072_sporttype]  DEFAULT ((0)),
	[bettype] [smallint] NOT NULL CONSTRAINT [DF_SUM2_09M072_bettype]  DEFAULT ((0))
)

GO

/****** Object:  Index [CIX_sum_winloss]    Script Date: 08/13/2011 05:13:34 ******/
CREATE CLUSTERED INDEX [CIX_sum_winloss] ON [dbo].[SUM2_09M07] 
(
	[winlostdate] ASC,
	[srecommend] ASC,
	[mrecommend] ASC,
	[recommend] ASC,
	[roleid] ASC,
	[sporttype] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SUM2_09M07]
GO
