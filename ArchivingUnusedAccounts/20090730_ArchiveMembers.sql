 /*
select count(*)
from custinfo with (nolock) where recommend in (	
	select custid from customer with (nolock) where roleid = 2 and lastlogged < '2008-07-30'
	and srecommend < 100 and closed = 1
	) and roleid = 1

select sag.username super, sag.lastlogged  SuperLast,  mag.username master, mag.lastlogged  MasterLast, ag.username agent, ag.lastlogged  AgentLast,
	count(mem.custid) NoOfMember
from customer ag with (nolock)
	inner join custinfo agci with (nolock) on agci.custid = ag.custid
	inner join customer mag with (nolock) on ag.mrecommend = mag.custid and mag.roleid = 3
	inner join customer sag with (nolock) on ag.srecommend = sag.custid and sag.roleid = 4
	inner join customer mem with (nolock) on ag.custid = mem.recommend and mem.roleid = 1
where  ag.roleid = 2
	and ag.lastlogged < '2008-07-30'
	and ag.srecommend > 100 and agci.closed = 1

group by sag.username , mag.username , ag.username, ag.lastlogged, sag.lastlogged, mag.lastlogged

order by sag.lastlogged desc,sag.username, mag.username, ag.username

select count(*)
from custinfo with (nolock) where recommend in (	
	select custid from customer with (nolock) where roleid = 2 and lastlogged < '2008-07-30'
	and srecommend < 100 and closed = 1
	) and roleid = 1
*/
/*

CREATE DATABASE [bodb_Customer] ON  PRIMARY 
( NAME = N'bodb_Customer', FILENAME = N'G:\IBC_DB\bodb_Customer\bodb_Customer.mdf' , SIZE = 2048KB , FILEGROWTH = 1024KB ), 
 FILEGROUP [Custsetting_table] 
( NAME = N'CustSetting_table', FILENAME = N'G:\IBC_DB\bodb_Customer\CustSetting_table.ndf' , SIZE = 4194304KB , FILEGROWTH = 65536KB ), 
 FILEGROUP [DATA] 
( NAME = N'bodb_Customer_DATA', FILENAME = N'G:\IBC_DB\bodb_Customer\bodb_Customer_DATA.ndf' , SIZE = 1048576KB , FILEGROWTH = 16384KB )
 LOG ON 
( NAME = N'bodb_Customer_log', FILENAME = N'G:\IBC_DB\bodb_Customer\bodb_Customer_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO
EXEC dbo.sp_dbcmptlevel @dbname=N'bodb_Customer', @new_cmptlevel=90
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [bodb_Customer].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [bodb_Customer] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [bodb_Customer] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [bodb_Customer] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [bodb_Customer] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [bodb_Customer] SET ARITHABORT OFF 
GO
ALTER DATABASE [bodb_Customer] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [bodb_Customer] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [bodb_Customer] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [bodb_Customer] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [bodb_Customer] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [bodb_Customer] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [bodb_Customer] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [bodb_Customer] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [bodb_Customer] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [bodb_Customer] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [bodb_Customer] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [bodb_Customer] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [bodb_Customer] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [bodb_Customer] SET  READ_WRITE 
GO
ALTER DATABASE [bodb_Customer] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [bodb_Customer] SET  MULTI_USER 
GO
ALTER DATABASE [bodb_Customer] SET PAGE_VERIFY CHECKSUM  
GO
USE [bodb_Customer]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [bodb_Customer] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO


*/