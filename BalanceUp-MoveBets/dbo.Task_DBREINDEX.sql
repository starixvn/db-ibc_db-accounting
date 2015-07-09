USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_DBREINDEX]    Script Date: 12/01/2009 23:18:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DBREINDEX]
AS
/*		
	DB: All servers.bodb02 (DB02, DB03, DB053, DB052, DB054, DB06, DB07)
	
*/
	DBCC DBREINDEX (match, '', 80)
	DBCC DBREINDEX (odds, '', 80)
	DBCC DBREINDEX (customer, '', 80)
	DBCC DBREINDEX (bettrans, '', 50)
	DBCC DBREINDEX (team, '', 80)
	DBCC DBREINDEX (league, '', 80)
	IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[custaccount]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
		DBCC DBREINDEX (custaccount, '', 50)
	IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[zzzbettrans]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
		DBCC DBREINDEX (zzzbettrans, '', 50)
