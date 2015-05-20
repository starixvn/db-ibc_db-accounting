USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[DBA_DelBettrans_bk]    Script Date: 12/12/2009 08:30:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_DelBettrans_bk]
    @winlostdate smalldatetime
AS

if @winlostdate >= '2008-07-01' --to prevent mistake
    RETURN
    
Declare @RowsEffected int
Declare @RowsCnt int

SELECT @RowsEffected = 0

SET NOCOUNT ON
WHILE 1=1
BEGIN
    DELETE TOP(10000) FROM bettrans_bk where
        winlostdate between @winlostdate and dateadd(mi, 1439, @winlostdate) -- plus '23:59:00'
    
	SELECT @RowsCnt = @@ROWCOUNT
	SELECT @RowsEffected = @RowsEffected + @RowsCnt   

	IF @RowsCnt < 10000
        BREAK

END

SET NOCOUNT OFF

print convert(varchar(20), @winlostdate,0) + '-' + convert(varchar(20), dateadd(mi, 1439, @winlostdate),0) + ' - '+ convert(varchar,@RowsEffected) 
-----------------
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2009-01-31 23:59:00')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2009-02-28 23:59:00')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2009-03-31 23:59:00')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2009-04-30 23:59:00')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2009-05-31 23:59:00')
GO
ALTER PARTITION FUNCTION pf_BET_monthly() MERGE RANGE ('2009-06-30 23:59:00')

----------
USE [bodb_Archive]
GO
ALTER DATABASE [bodb_Archive]  REMOVE FILE [BET_09M01]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [BET_09M01]
GO

ALTER DATABASE [bodb_Archive]  REMOVE FILE [BET_09M02]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [BET_09M02]
GO

ALTER DATABASE [bodb_Archive]  REMOVE FILE [BET_09M03]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [BET_09M03]
GO

ALTER DATABASE [bodb_Archive]  REMOVE FILE [BET_09M04]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [BET_09M04]
GO

ALTER DATABASE [bodb_Archive]  REMOVE FILE [BET_09M05]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [BET_09M05]
GO

ALTER DATABASE [bodb_Archive]  REMOVE FILE [BET_09M06]
GO
ALTER DATABASE [bodb_Archive] REMOVE FILEGROUP [BET_09M06]
GO

 
 
 
 
 
 

