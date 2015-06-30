 USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_LiveLog_DBSPARE]    Script Date: 03/31/2013 01:00:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_LiveLog_DBSPARE]
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

	

----------------------------------------------------------------
set @endRun = getdate()
set @duration  = datediff (minute,@startRun,@endRun)

print convert(varchar(50), @winlostdate, 111) +': ' + cast(@duration as varchar(12)) + 'min'


