USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectTransfer]    Script Date: 03/30/2013 23:51:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectTransfer]
AS

Declare @min_winlostdate smalldatetime,
		@max_winlostdate smalldatetime
		
SELECT	@max_winlostdate = MAX(winlostdate)
FROM bodb_archive.dbo.Task_ArchiveDate

SELECT @min_winlostdate = DateAdd(d,-6,@max_winlostdate)

--select @min_winlostdate,@max_winlostdate


SELECT [custid]
      ,[transdate]
      ,[Debit]
      ,[Credit]
      ,[TransDesc]
      ,[winlostdate]
      ,[recommend]
      ,[mrecommend]
      ,[srecommend]
      ,[currency]
      ,[refno]
      ,[creator]
      ,[transid]
      ,[bettype]
FROM [bodb_Archive].[dbo].[transfer_bk]
WHERE winlostdate between @min_winlostdate and @max_winlostdate

