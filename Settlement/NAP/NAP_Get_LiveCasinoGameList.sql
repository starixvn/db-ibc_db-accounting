ALTER PROCEDURE [dbo].[NAP_Get_LiveCasinoGameList]
	@FromDate datetime,
	@ToDate datetime,
	@LeagueID int = 0,
	@matchcode nvarchar(50) = '',
	@statusid tinyint = 0,
	@isReLoad bit = 0
AS

/*
	Created by: 20120907@Dan
	Task: get game hand by leagueid	
	DB: DB02.BODB02
	Original: Acc_Get_LiveCasinoGameList

	Revisions:		
		
	Param explanation:
		@LeagueID: = 0: show info of all leagues 		
		@matchcode: match code
		@statusid: 0: all, 1: running; 2: closed; 3: completed; 4: refund; 
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @eventstatus NVARCHAR(50), @isRefund BIT, @matchid INT
	
	SELECT @matchcode = ISNULL(@matchcode,''), @LeagueID = ISNULL(@LeagueID,0)
	-- if entering matcode, ignore other params (excep FromDate, ToDate, sport type)
	IF (@matchcode <> '')
	BEGIN
		SELECT @eventstatus= '', @isRefund=0, 
			@LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues
					
		BEGIN TRY	
			SET @matchid = CASE WHEN ISNUMERIC(@matchcode) = 1 THEN CAST(@matchcode AS INT) ELSE NULL END
		END TRY
		BEGIN CATCH
			SET @matchid=NULL
		END CATCH				
	END
	ELSE
	BEGIN
		SELECT @eventstatus = CASE @statusid WHEN 1 THEN 'running'
											WHEN 2 THEN 'closed'
											WHEN 3 THEN 'completed'
											ELSE ''
								END,
			@isRefund = CASE @statusid WHEN 4 THEN 1 
									WHEN 0 THEN NULL --all
									ELSE 0	END			
	END


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
		/*
		, CASE WHEN CHARINDEX('Baccarat',l.leaguename,0) > 0 THEN 1101 
				WHEN CHARINDEX('Roulette',l.leaguename,0) > 0 THEN 1102 
				WHEN CHARINDEX('Sicbo',l.leaguename,0) > 0 THEN 1103
			ELSE 0 END AS bettype
		*/
	FROM match m WITH(NOLOCK)
		--INNER JOIN league l WITH(NOLOCK) ON l.leagueid = m.leagueid
	WHERE m.eventdate BETWEEN @FromDate AND @ToDate
		AND m.sporttype = 162 
		AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END		
		AND (@eventstatus='' or eventstatus = @eventstatus) 		
		AND (@matchcode = '' or (m.matchid = @matchid OR m.matchcode = @matchcode)) 		
		AND (@isRefund is null or 
				(@isRefund =1 and betstatus like 'Refund%') or
				(@isRefund =0 and ISNULL(betstatus,'') not like 'Refund%') 
			)	  
END




GO
GRANT VIEW DEFINITION ON [NAP_Get_LiveCasinoGameList] TO vnteam
GO
GRANT EXECUTE ON [NAP_Get_LiveCasinoGameList] TO bodbAdminNet
 