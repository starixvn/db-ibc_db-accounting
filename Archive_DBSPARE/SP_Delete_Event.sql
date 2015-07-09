USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[DBA_DelEvent]    Script Date: 12/12/2009 08:15:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_DelEvent]
    @winlostdate smalldatetime
AS

if @winlostdate >= '2008-07-01' --to prevent mistake
    RETURN

if @winlostdate < '2006-10-01'
BEGIN
	DELETE FROM odds_BK WHERE odds_BK.matchid in (
                          select matchid from match_06Q3 AS m WITH (nolock) 
							where eventdate between @winlostdate and dateadd(mi, 1439, @winlostdate)
                            ) 
	DELETE FROM match_06Q3 where eventdate between @winlostdate and dateadd(mi, 1439, @winlostdate)
END
ELSE
BEGIN
	DELETE FROM odds_BK WHERE odds_BK.matchid in (
                          select matchid from match_bk AS m WITH (nolock) 
							where eventdate between @winlostdate and dateadd(mi, 1439, @winlostdate)
                            )
	DELETE FROM match_bk where eventdate between @winlostdate and dateadd(mi, 1439, @winlostdate)
END

DELETE FROM outright_bk where eventdate between @winlostdate and dateadd(mi, 1439, @winlostdate)

print convert(varchar(20), @winlostdate,0) 

