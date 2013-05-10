USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_ParlayResult]    Script Date: 03/30/2013 23:50:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_Archive_ParlayResult]
AS
	Declare @min_winlostdate smalldatetime,
		@max_winlostdate smalldatetime
			
	SELECT	@max_winlostdate = MAX(winlostdate)
	FROM bodb_archive.dbo.Task_ArchiveDate

	SELECT @min_winlostdate = DateAdd(d,-6,@max_winlostdate)

	INSERT INTO DBARCHIVE2.[bodb_Archive].dbo.[betParlayResult] (
		rID, RefNo, Serial, transid, winlostdate, statusid, stake, Odds, mOdds,
		winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
		)
	SELECT
		rID, RefNo, Serial, transid, winlostdate, statusid, stake, Odds, mOdds,
		winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
	FROM
		dbo.betParlayResult
	WHERE winlostdate between @min_winlostdate and @max_winlostdate



GO
GRANT VIEW DEFINITION ON [dbo].[Task_Archive_ParlayResult] TO [vnteam] AS [dbo]