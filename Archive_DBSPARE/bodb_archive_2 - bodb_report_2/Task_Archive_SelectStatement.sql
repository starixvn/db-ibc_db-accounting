USE [bodb_Report]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectStatement]    Script Date: 03/30/2013 23:47:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectStatement]
AS
/*
	--Source: DB06.bodb_Report
*/
Declare @min_winlostdate datetime,
		@max_winlostdate datetime
		
SELECT	@max_winlostdate = MAX(winlostdate)
FROM bodb_archive.dbo.Task_ArchiveDate

SELECT @min_winlostdate = DateAdd(d,-6,@max_winlostdate)

select @max_winlostdate = DateAdd(d,1,DATEADD(ms, -3, @max_winlostdate))

--select @min_winlostdate,@max_winlostdate


SELECT custid,
	[accdate]
      ,[totalamt]
      ,[transtype]
      ,[transdesc]
FROM [Statement] with (nolock)
WHERE accDate between @min_winlostdate and @max_winlostdate

