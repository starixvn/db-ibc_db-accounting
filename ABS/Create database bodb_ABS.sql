USE [master]
GO
/****** Object:  Database [bodb_ABS]    Script Date: 09/11/2012 08:35:13 ******/
CREATE DATABASE [bodb_ABS] ON  PRIMARY 
( NAME = N'bodb_ABS', FILENAME = N'D:\IBC_DB\bodb_ABS\bodb_ABS.mdf' , SIZE = 10240KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [abDATA] 
( NAME = N'abDATA', FILENAME = N'D:\IBC_DB\bodb_ABS\abDATA.ndf' , SIZE = 10240KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [abDATA_BK] 
( NAME = N'abDATA_BK', FILENAME = N'D:\IBC_DB\bodb_ABS\abDATA_BK.ndf' , SIZE = 10240KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [abINDEX] 
( NAME = N'abINDEX', FILENAME = N'D:\IBC_DB\bodb_ABS\abINDEX.ndf' , SIZE = 10240KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ), 
 FILEGROUP [abSumWinloss] 
( NAME = N'abSumWinloss', FILENAME = N'D:\IBC_DB\bodb_ABS\abSumWinloss.ndf' , SIZE = 10240KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ) 
 LOG ON 
( NAME = N'bodb_ABS_log', FILENAME = N'D:\IBC_DB\bodb_ABS\bodb_ABS_log.ldf' , SIZE = 10240KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
EXEC dbo.sp_dbcmptlevel @dbname=N'bodb_ABS', @new_cmptlevel=90
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [bodb_ABS].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [bodb_ABS] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [bodb_ABS] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [bodb_ABS] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [bodb_ABS] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [bodb_ABS] SET ARITHABORT OFF 
GO
ALTER DATABASE [bodb_ABS] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [bodb_ABS] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [bodb_ABS] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [bodb_ABS] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [bodb_ABS] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [bodb_ABS] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [bodb_ABS] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [bodb_ABS] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [bodb_ABS] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [bodb_ABS] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [bodb_ABS] SET  ENABLE_BROKER 
GO
ALTER DATABASE [bodb_ABS] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [bodb_ABS] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [bodb_ABS] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [bodb_ABS] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [bodb_ABS] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [bodb_ABS] SET  READ_WRITE 
GO
ALTER DATABASE [bodb_ABS] SET RECOVERY FULL 
GO
ALTER DATABASE [bodb_ABS] SET  MULTI_USER 
GO
ALTER DATABASE [bodb_ABS] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [bodb_ABS] SET DB_CHAINING OFF 
GO


USE [bodb_ABS]
GO
/****** Object:  Table [dbo].[ABCustomer]    Script Date: 09/11/2012 08:45:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABCustomer](
	[PunterID] [int] NOT NULL,
	[CustID] [int] NOT NULL,
	[updatedtime] [datetime] NOT NULL,
 CONSTRAINT [PK_ABCustomer] PRIMARY KEY CLUSTERED 
(
	[PunterID] ASC,
	[CustID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [abDATA]
) ON [abDATA]

USE [bodb_ABS]
GO
/****** Object:  Table [dbo].[ABMatch_Remark]    Script Date: 09/11/2012 08:45:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABMatch_Remark](
	[matchid] [int] NOT NULL,
	[bettype] [int] NOT NULL,
	[hdp] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[transid] [bigint] NULL
) ON [abDATA]

GO
/****** Object:  Index [CIX_matchid_bettype]    Script Date: 09/11/2012 08:45:54 ******/
CREATE CLUSTERED INDEX [CIX_matchid_bettype] ON [dbo].[ABMatch_Remark] 
(
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [abDATA]

GO

USE [bodb_ABS]
GO
/****** Object:  Table [dbo].[ABMatch_Remark_BK]    Script Date: 09/11/2012 11:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABMatch_Remark_BK](
	[matchid] [int] NOT NULL,
	[bettype] [int] NOT NULL,
	[hdp] [smallmoney] NULL,
	[odds] [smallmoney] NULL,
	[transid] [bigint] NULL
) 
GO

USE [bodb_ABS]
GO
/****** Object:  Index [CIX_matchid_bettype]    Script Date: 09/11/2012 11:12:27 ******/
CREATE CLUSTERED INDEX [CIX_matchid_bettype] ON [dbo].[ABMatch_Remark_BK] 
(
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [abEVENT_BK]
GO

USE [bodb_ABS]
GO
/****** Object:  Table [dbo].[ABPunterCode]    Script Date: 09/11/2012 08:47:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[ABPunterCode](
	[punterid] [int] IDENTITY(1,1) NOT NULL,
	[code] [varchar](10) NOT NULL,
	[currency] [int] NULL,
	[color] [varchar](7) NOT NULL,
	[fb_1] [money] NOT NULL CONSTRAINT [DF_ABPunterCode_fb_1]  DEFAULT ((0)),
	[fb_3] [money] NOT NULL CONSTRAINT [DF_ABPunterCode_fb_3]  DEFAULT ((0)),
	[enabled] [bit] NOT NULL CONSTRAINT [DF_ABPunterCode_enabled]  DEFAULT ((1)),
	[fb_5] [money] NOT NULL CONSTRAINT [DF_ABPunterCode_fb_5]  DEFAULT ((0)),
 CONSTRAINT [PK_ABPunterCode] PRIMARY KEY CLUSTERED 
(
	[punterid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [abDATA]
) ON [abDATA]

GO
SET ANSI_PADDING OFF

USE [bodb_ABS]
GO
/****** Object:  Table [dbo].[ABPunterGroup]    Script Date: 09/11/2012 08:47:57 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABPunterGroup](
	[adminid] [int] NOT NULL,
	[punterid] [int] NOT NULL,
 CONSTRAINT [PK_ABPunterGroup] PRIMARY KEY CLUSTERED 
(
	[adminid] ASC,
	[punterid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [abDATA]
) ON [abDATA]

GO
USE [bodb_ABS]
GO
/****** Object:  Table [dbo].[ABSum_winloss]    Script Date: 09/11/2012 08:48:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABSum_winloss](
	[winlostdate] [datetime] NOT NULL,
	[punterid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[currency] [int] NULL,
	[statusid] [tinyint] NULL,
	[turnover] [money] NULL,
	[comm] [money] NULL,
	[winlost] [money] NULL,
	[betcount] [int] NULL
) ON [abSumWinloss]
GO
USE [bodb_ABS]
GO
/****** Object:  Index [CIX_absum_winloss]    Script Date: 09/11/2012 08:48:31 ******/
CREATE CLUSTERED INDEX [CIX_absum_winloss] ON [dbo].[ABSum_winloss] 
(
	[winlostdate] ASC,
	[punterid] ASC,
	[leagueid] ASC,
	[matchid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [abSumWinloss]

GO

USE bodb_ABS
GO

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M01]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M02]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M03]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M04]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M05]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M06]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M07]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M08]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M09]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M10]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M11]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M12]

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M01]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M02]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M03]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M04]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M05]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M06]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M07]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M08]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M09]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M10]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M11]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M12]

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M01]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M02]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M03]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M04]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M05]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M06]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M07]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M08]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M09]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M10]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M11]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M12]

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M01]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M02]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M03]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M04]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M05]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M06]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M07]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M08]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M09]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M10]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M11]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M12]

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_Max]
GO

ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M01', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M01.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M01]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M02', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M02.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M02]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M03', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M03.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M03]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M04', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M04.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M04]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M05', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M05.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M05]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M06', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M06.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M06]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M07', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M07.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M07]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M08', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M08.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M08]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M09', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M09.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M09]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M10', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M10.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M10]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M11', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M11.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M11]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M12', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M12.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M12] 

ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M01', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M01.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M01]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M02', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M02.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M02]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M03', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M03.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M03]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M04', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M04.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M04]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M05', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M05.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M05]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M06', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M06.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M06]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M07', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M07.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M07]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M08', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M08.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M08]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M09', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M09.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M09]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M10', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M10.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M10]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M11', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M11.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M11]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M12', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M12.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M12] 


ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M01', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M01.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M01]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M02', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M02.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M02]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M03', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M03.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M03]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M04', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M04.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M04]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M05', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M05.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M05]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M06', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M06.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M06]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M07', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M07.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M07]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M08', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M08.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M08]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M09', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M09.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M09]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M10', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M10.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M10]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M11', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M11.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M11]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M12', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M12.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M12] 

ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M01', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M01.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M01]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M02', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M02.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M02]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M03', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M03.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M03]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M04', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M04.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M04]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M05', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M05.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M05]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M06', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M06.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M06]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M07', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M07.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M07]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M08', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M08.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M08]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M09', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M09.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M09]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M10', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M10.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M10]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M11', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M11.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M11]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M12', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M12.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M12] 

ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_MAX', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_MAX.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_MAX] 
GO

CREATE PARTITION FUNCTION pf_ABSum_Winloss_Old_monthly(DATETIME) AS
RANGE LEFT FOR VALUES
(
 '2012/01/31 23:59:00',
 '2012/02/29 23:59:00',
 '2012/03/31 23:59:00',
 '2012/04/30 23:59:00',
 '2012/05/31 23:59:00',
 '2012/06/30 23:59:00',
 '2012/07/31 23:59:00',
 '2012/08/31 23:59:00',
 '2012/09/30 23:59:00',
 '2012/10/31 23:59:00',
 '2012/11/30 23:59:00',
 '2012/12/31 23:59:00',
 '2013/01/31 23:59:00',
 '2013/02/28 23:59:00',
 '2013/03/31 23:59:00',
 '2013/04/30 23:59:00',
 '2013/05/31 23:59:00',
 '2013/06/30 23:59:00',
 '2013/07/31 23:59:00',
 '2013/08/31 23:59:00',
 '2013/09/30 23:59:00',
 '2013/10/31 23:59:00',
 '2013/11/30 23:59:00',
 '2013/12/31 23:59:00',
 '2014/01/31 23:59:00',
 '2014/02/28 23:59:00',
 '2014/03/31 23:59:00',
 '2014/04/30 23:59:00',
 '2014/05/31 23:59:00',
 '2014/06/30 23:59:00',
 '2014/07/31 23:59:00',
 '2014/08/31 23:59:00',
 '2014/09/30 23:59:00',
 '2014/10/31 23:59:00',
 '2014/11/30 23:59:00',
 '2014/12/31 23:59:00',
 '2015/01/31 23:59:00',
 '2015/02/28 23:59:00',
 '2015/03/31 23:59:00',
 '2015/04/30 23:59:00',
 '2015/05/31 23:59:00',
 '2015/06/30 23:59:00',
 '2015/07/31 23:59:00',
 '2015/08/31 23:59:00',
 '2015/09/30 23:59:00',
 '2015/10/31 23:59:00',
 '2015/11/30 23:59:00',
 '2015/12/31 23:59:00'	
)

CREATE PARTITION SCHEME ps_ABSum_Winloss_Old_monthly
AS PARTITION pf_ABSum_Winloss_Old_monthly
TO
(
	[abSumWinlossOld_12M01],
	[abSumWinlossOld_12M02],
	[abSumWinlossOld_12M03],
	[abSumWinlossOld_12M04],
	[abSumWinlossOld_12M05],
	[abSumWinlossOld_12M06],
	[abSumWinlossOld_12M07],
	[abSumWinlossOld_12M08],
	[abSumWinlossOld_12M09],
	[abSumWinlossOld_12M10],
	[abSumWinlossOld_12M11],
	[abSumWinlossOld_12M12],
	
	[abSumWinlossOld_13M01],
	[abSumWinlossOld_13M02],
	[abSumWinlossOld_13M03],
	[abSumWinlossOld_13M04],
	[abSumWinlossOld_13M05],
	[abSumWinlossOld_13M06],
	[abSumWinlossOld_13M07],
	[abSumWinlossOld_13M08],
	[abSumWinlossOld_13M09],
	[abSumWinlossOld_13M10],
	[abSumWinlossOld_13M11],
	[abSumWinlossOld_13M12],
	
	[abSumWinlossOld_14M01],
	[abSumWinlossOld_14M02],
	[abSumWinlossOld_14M03],
	[abSumWinlossOld_14M04],
	[abSumWinlossOld_14M05],
	[abSumWinlossOld_14M06],
	[abSumWinlossOld_14M07],
	[abSumWinlossOld_14M08],
	[abSumWinlossOld_14M09],
	[abSumWinlossOld_14M10],
	[abSumWinlossOld_14M11],
	[abSumWinlossOld_14M12],

	[abSumWinlossOld_15M01],
	[abSumWinlossOld_15M02],
	[abSumWinlossOld_15M03],
	[abSumWinlossOld_15M04],
	[abSumWinlossOld_15M05],
	[abSumWinlossOld_15M06],
	[abSumWinlossOld_15M07],
	[abSumWinlossOld_15M08],
	[abSumWinlossOld_15M09],
	[abSumWinlossOld_15M10],
	[abSumWinlossOld_15M11],
	[abSumWinlossOld_15M12],
	[abSumWinlossOld_MAX]
)
GO

CREATE TABLE [dbo].[ABSum_winloss_Old](
	[winlostdate] [datetime] NOT NULL,
	[punterid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[bettype] [int] NOT NULL,
	[currency] [int] NULL,
	[statusid] [tinyint] NULL,
	[turnover] [money] NULL,
	[comm] [money] NULL,
	[winlost] [money] NULL,
	[betcount] [int] NULL
) 

CREATE CLUSTERED INDEX [CIX_ABSum_winloss_Old] ON [dbo].[ABSum_winloss_Old] 
(
	[winlostdate] ASC,
	[punterid] ASC,
	[leagueid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) 
ON ps_ABSum_Winloss_Old_monthly(winlostdate)


USE [bodb_ABS]
GO
/****** Object:  Table [dbo].[ABSum_winloss2]    Script Date: 09/11/2012 08:53:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABSum_winloss2](
	[winlostdate] [datetime] NOT NULL,
	[punterid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[bettype] [int] NOT NULL,
	[currency] [int] NULL,
	[statusid] [tinyint] NULL,
	[turnover] [money] NULL,
	[comm] [money] NULL,
	[winlost] [money] NULL,
	[betcount] [int] NULL
) ON [abSumWinloss]
GO

USE [bodb_ABS]
GO
/****** Object:  Index [CIX_ABSum_winloss2]    Script Date: 09/11/2012 08:54:12 ******/
CREATE CLUSTERED INDEX [CIX_ABSum_winloss2] ON [dbo].[ABSum_winloss2] 
(
	[winlostdate] ASC,
	[punterid] ASC,
	[leagueid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [abSumWinloss]

USE [bodb_ABS]
GO
/****** Object:  Table [dbo].[ABTransaction]    Script Date: 09/11/2012 08:54:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABTransaction](
	[transid] [bigint] NOT NULL,
	[punterid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[remark] [nvarchar](100) NULL,
 CONSTRAINT [PK_ABTransaction] PRIMARY KEY CLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [abDATA]
) ON [abDATA]

GO
USE [bodb_ABS]
GO
/****** Object:  Table [dbo].[ABTransaction_BK]    Script Date: 09/11/2012 08:54:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ABTransaction_BK](
	[transid] [bigint] NOT NULL,
	[punterid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[remark] [nvarchar](100) NULL,
 CONSTRAINT [PK_ABTransaction_BK] PRIMARY KEY CLUSTERED 
(
	[transid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [abDATA_BK]
) ON [abDATA_BK]

