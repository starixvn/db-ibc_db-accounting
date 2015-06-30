 USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_Event_DBSPARE]    Script Date: 03/30/2013 23:51:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_Event_DBSPARE]
	@winlostdate smalldatetime
AS
SET NOCOUNT ON


declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

	INSERT INTO DBSPARE.bodb_archive12.dbo.Dot_Admin_LiveLog
		SELECT * FROM Dot_Admin_LiveLog with (nolock)
		WHERE matchid in (select matchid from match_bk with (nolock) where eventdate = @winlostdate)
	
	INSERT INTO DBSPARE.bodb_archive12.dbo.Dot_Admin_Assignment_Operator_bk
		SELECT * FROM Dot_Admin_Assignment_Operator_bk with (nolock)
		WHERE matchid in (select matchid from match_bk with (nolock) where eventdate = @winlostdate)

	INSERT INTO DBSPARE.bodb_archive12.dbo.odds_bk
		SELECT * FROM odds_bk with (nolock)
		WHERE matchid in (select matchid from match_bk with (nolock) where eventdate = @winlostdate)

	INSERT INTO DBSPARE.bodb_archive12.dbo.match_bk
		SELECT * FROM match_bk with (nolock)
		WHERE eventdate = @winlostdate

	INSERT INTO DBSPARE.bodb_archive12.dbo.bingoBall_bk		
		SELECT * FROM bingoBall_bk with (nolock)
		WHERE MatchID in (SELECT MatchID from match_bk with (nolock) where eventdate = @winlostdate)

	INSERT INTO DBSPARE.bodb_archive12.dbo.SS_GameState_bk	
	SELECT * FROM SS_GameState_bk with (nolock)
		WHERE MatchID in (SELECT MatchID from match_bk with (nolock) where eventdate = @winlostdate)
	
	INSERT INTO DBSPARE.bodb_archive12.dbo.outright_bk
		SELECT * FROM outright_bk with (nolock)
		WHERE eventdate = @winlostdate

----------------------------------------------------------------
set @endRun = getdate()
set @duration  = datediff (minute,@startRun,@endRun)

print convert(varchar(50), @winlostdate, 111) +': ' + cast(@duration as varchar(12)) + 'min'


