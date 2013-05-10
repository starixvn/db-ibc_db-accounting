  USE [master]
GO

/****** Object:  Login [bodbAdminNet]    Script Date: 01/21/2010 03:36:38 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [bodbAdminNet] WITH PASSWORD=N'', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

GO
/****** Object:  Login [bodbDownlineNet]    Script Date: 01/21/2010 03:36:39 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [bodbDownlineNet] WITH PASSWORD=N'', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

GO
/****** Object:  Login [bodbDownlineNetView]    Script Date: 01/21/2010 03:36:39 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [bodbDownlineNetView] WITH PASSWORD=N'', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
 


/****** Object:  Login [Dot_3rdparty]    Script Date: 01/21/2010 03:36:40 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [Dot_3rdparty] WITH PASSWORD=N'ÊØíýpø=¸IIº<x=#}Û ¯æÜ%à Q', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
ALTER LOGIN [Dot_3rdparty] DISABLE
GO
/****** Object:  Login [Dot_Admin]    Script Date: 01/21/2010 03:36:41 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [Dot_Admin] WITH PASSWORD=N'', DEFAULT_DATABASE=[bodb02], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER LOGIN [Dot_Admin] DISABLE
GO
/****** Object:  Login [Dot_Member]    Script Date: 01/21/2010 03:36:41 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [Dot_Member] WITH PASSWORD=N'', DEFAULT_DATABASE=[bodb02], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER LOGIN [Dot_Member] DISABLE
GO
/****** Object:  Login [Dot_RefUser]    Script Date: 01/21/2010 03:36:41 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [Dot_RefUser] WITH PASSWORD=N'þ:kGÝì°(°3²æ;GÞÂKçt<}', DEFAULT_DATABASE=[bodb02], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER LOGIN [Dot_RefUser] DISABLE
GO
/****** Object:  Login [dwrs]    Script Date: 01/21/2010 03:36:42 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [dwrs] WITH PASSWORD=N'¦û6Xk°6_uÛfW,9¬§roQ;', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER LOGIN [dwrs] DISABLE

/****** Object:  Login [julien]    Script Date: 01/21/2010 03:36:42 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [julien] WITH PASSWORD=N'ÍF£&ÀL|Ñ#J6&k^«?RÝÖÆ·î', DEFAULT_DATABASE=[bodb02], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER LOGIN [julien] DISABLE
GO
/****** Object:  Login [NT AUTHORITY\SYSTEM]    Script Date: 01/21/2010 03:36:42 ******/
CREATE LOGIN [NT AUTHORITY\SYSTEM] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO
/****** Object:  Login [Portal]    Script Date: 01/21/2010 03:36:42 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [Portal] WITH PASSWORD=N'RhLààÃ>;Æ¦÷Ôà$[poÛ¬j', DEFAULT_DATABASE=[bodb02], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
ALTER LOGIN [Portal] DISABLE
GO
/****** Object:  Login [RDSylvia]    Script Date: 01/21/2010 03:36:43 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [RDSylvia] WITH PASSWORD=N'Õj`znð½t×ÂdLùT¨b;å+MàÙ', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
EXEC sys.sp_addsrvrolemember @loginame = N'RDSylvia', @rolename = N'sysadmin'
GO
ALTER LOGIN [RDSylvia] DISABLE
GO
/****** Object:  Login [RDTim]    Script Date: 01/21/2010 03:36:43 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [RDTim] WITH PASSWORD=N'ßØÌ(¢ï[¨Ït*N»¹%å°l* ¬ÜH', DEFAULT_DATABASE=[bodb02], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER LOGIN [RDTim] DISABLE
GO
/****** Object:  Login [RDVivi]    Script Date: 01/21/2010 03:36:43 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [RDVivi] WITH PASSWORD=N'ªµ^ê:QªÕ$o3Æã9u¾m¯Cy?IÔ', DEFAULT_DATABASE=[bodb02], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
EXEC sys.sp_addsrvrolemember @loginame = N'RDVivi', @rolename = N'sysadmin'
GO
ALTER LOGIN [RDVivi] DISABLE
GO
/****** Object:  Login [Save_Files]    Script Date: 01/21/2010 03:36:43 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [Save_Files] WITH PASSWORD=N'ßöUÊYºçDhóhü)!Ï¿
KN¾;<ânQ', DEFAULT_DATABASE=[bodb02], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
ALTER LOGIN [Save_Files] DISABLE
GO

/****** Object:  Login [vnDBA]    Script Date: 01/21/2010 03:36:44 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [vnDBA] WITH PASSWORD=N'', DEFAULT_DATABASE=[bodb_Archive], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

GO
/****** Object:  Login [vnteam]    Script Date: 01/21/2010 03:36:44 ******/
/* For security reasons the login is created disabled and with a random password. */
CREATE LOGIN [vnteam] WITH PASSWORD=N'', DEFAULT_DATABASE=[bodb_Archive], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

--------------------------
USE [master]
GO
/****** Object:  Database [bodb_Archive]    Script Date: 01/21/2010 03:45:11 ******/
CREATE DATABASE [bodb_Archive] ON  PRIMARY 
( NAME = N'bodb_Archive_Data', FILENAME = N'G:\IBC_DB\bodb_Archive\bodb_Archive.MDF' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB ), 
 FILEGROUP [EVENT] 
( NAME = N'bodb_Archive_Event', FILENAME = N'G:\IBC_DB\bodb_Archive\bodb_Archive_Event-1.ndf' , SIZE = 14336KB , MAXSIZE = UNLIMITED, FILEGROWTH = 2048KB ), 
 LOG ON 
( NAME = N'bodb_Archive_Log', FILENAME = N'G:\IBC_DB\bodb_Archive\bodb_Archive_log.LDF' , SIZE = 1 MB , MAXSIZE = 51200000KB , FILEGROWTH = 10%)
GO
ALTER DATABASE [bodb_Archive] ADD FILEGROUP [DATA]
GO
ALTER DATABASE [bodb_Archive] ADD FILE ( NAME = N'DATA_01', FILENAME = N'G:\IBC_DB\bodb_Archive\bodb_Archive_DATA_01.ndf' , SIZE = 2048KB , FILEGROWTH = 32MB ) TO FILEGROUP [DATA]
GO
ALTER DATABASE [bodb_Archive] ADD FILE ( NAME = N'DATA_02', FILENAME = N'G:\IBC_DB\bodb_Archive\bodb_Archive_DATA_02.ndf' , SIZE = 2048KB , FILEGROWTH = 32MB ) TO FILEGROUP [DATA]
GO

EXEC dbo.sp_dbcmptlevel @dbname=N'bodb_Archive', @new_cmptlevel=90
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [bodb_Archive].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [bodb_Archive] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [bodb_Archive] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [bodb_Archive] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [bodb_Archive] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [bodb_Archive] SET ARITHABORT OFF 
GO
ALTER DATABASE [bodb_Archive] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [bodb_Archive] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [bodb_Archive] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [bodb_Archive] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [bodb_Archive] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [bodb_Archive] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [bodb_Archive] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [bodb_Archive] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [bodb_Archive] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [bodb_Archive] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [bodb_Archive] SET  DISABLE_BROKER 
GO
ALTER DATABASE [bodb_Archive] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [bodb_Archive] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [bodb_Archive] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [bodb_Archive] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [bodb_Archive] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [bodb_Archive] SET  READ_WRITE 
GO
ALTER DATABASE [bodb_Archive] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [bodb_Archive] SET  MULTI_USER 
GO
ALTER DATABASE [bodb_Archive] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [bodb_Archive] SET DB_CHAINING OFF 
GO
---------------
USE [bodb_Archive]
GO
/****** Object:  User [bodbAdminNet]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [bodbAdminNet] FOR LOGIN [bodbAdminNet] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [bodbDownlineNet]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [bodbDownlineNet] FOR LOGIN [bodbDownlineNet] WITH DEFAULT_SCHEMA=[bodbDownlineNet]
GO
/****** Object:  User [bodbDownlineNetView]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [bodbDownlineNetView] FOR LOGIN [bodbDownlineNetView] WITH DEFAULT_SCHEMA=[bodbDownlineNetView]
GO
/****** Object:  User [Dot_Member]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [Dot_Member] FOR LOGIN [Dot_Member] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [dwrs]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [dwrs] FOR LOGIN [dwrs] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [RDSylvia]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [RDSylvia] FOR LOGIN [RDSylvia] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [RDVivi]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [RDVivi] FOR LOGIN [RDVivi] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnDBA]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [vnDBA] FOR LOGIN [vnDBA] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [vnteam]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [vnteam] FOR LOGIN [vnteam] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [julien]    Script Date: 01/21/2010 03:36:37 ******/
CREATE USER [julien] FOR LOGIN [julien] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [finance]    Script Date: 01/21/2010 03:36:38 ******/
CREATE USER [finance] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [Vivi_Test]    Script Date: 01/21/2010 03:36:38 ******/
CREATE USER [Vivi_Test] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
----------
GRANT SELECT ON [dbo].[bettrans_BK] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[bettrans_BK] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[bettrans_BK] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[bettransm] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[bettransm] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[bettransm] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[bettransm] TO [bodbSuperNet]
GO
GRANT SELECT ON [dbo].[match_BK] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[match_BK] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[match_BK] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[match_BK] TO [bodbSuperNet]
GO
GRANT SELECT ON [dbo].[outright_bk] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[outright_bk] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[outright_bk] TO [bodbDownlineNetView]
GO
GRANT SELECT ON [dbo].[outright_bk] TO [Dot_Member]
GO
GRANT SELECT ON [dbo].[sum_winloss_old] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[sum_winloss_old] TO [bodbDownlineNetView]
GO
