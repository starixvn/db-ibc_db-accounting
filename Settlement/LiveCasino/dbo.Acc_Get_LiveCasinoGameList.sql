ALTER PROCEDURE [dbo].[Acc_Get_LiveCasinoGameList]
	@FromDate datetime,
	@ToDate datetime,
	@LeagueID int = 0,
	@StatusID INT = 0
AS

/*
	Created by: 20120116@Lukas
	Task: get game hand by leagueid
	DB: DB02.BODB02

	Revisions:		
		- 20120910@Sophia: .Get homeid2 for bettype
						   .Change server name DB02 instead of DBTRANS
		- 20120911@Sophia: .Add new parameter @StatusID 
						   .Remove parameter @IsCompleted
		- 20121029@Lukas: add more status into filter - closed
		- 20121203@Elodie:  Sort game list by matchid
							Remove filter by both completed and refund status
	Param explanation:
		@LeagueID: 
			0: show info of all leagues 		
		@StatusID:
			0: All
			1: Running
			2: Completed
			3: Refund
			4: Completed + Refund (Call from Result page) -- Remove filter by both completed and refund status
			5: Closed
*/
BEGIN

	SET NOCOUNT ON

	SELECT 
		m.matchid
		,m.matchcode
		,m.eventdate
		,m.kickofftime
		,m.showtime AS GameEvent
		,m.finalhomescore
		,m.finalawayscore
		,CASE WHEN m.betstatus= 'Refund' THEN NULL ELSE m.betstatus END betstatus
		,CASE WHEN m.betstatus = 'Refund' THEN 'Refund' ELSE eventstatus END eventstatus
		,m.leagueid
		,CASE WHEN ISNULL(homeid2,0) = 0 THEN 1101 ELSE homeid2 END AS bettype
	FROM match m WITH(NOLOCK)
		INNER JOIN league l WITH(NOLOCK) ON l.leagueid = m.leagueid
	WHERE m.eventdate BETWEEN @FromDate AND @ToDate
		AND m.sporttype = 162 
		AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
		AND m.eventstatus = CASE @StatusID	WHEN 1 THEN 'running'
											WHEN 2 THEN 'completed' 
											--WHEN 4 THEN 'completed' -- Remove filter by both completed and refund status
											WHEN 5 THEN 'closed'
											ELSE m.eventstatus END
		AND ISNULL(m.betstatus,'') = CASE	WHEN @StatusID = 3 THEN 'Refund' ELSE ISNULL(m.betstatus,'') END
		AND CASE WHEN @StatusID = 2 THEN ISNULL(m.betstatus,'')ELSE '1' END <> CASE WHEN @StatusID = 2 THEN 'Refund' ELSE '2' END 
	order BY m.matchid
 
END

GO
GRANT VIEW DEFINITION ON [Acc_Get_LiveCasinoGameList] TO vnteam
GO
GRANT EXECUTE ON [Acc_Get_LiveCasinoGameList] TO bodbAdminNet
 