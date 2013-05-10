ALTER PROCEDURE [dbo].[Acc_Set_HR_ResultSCRSel]
	@Eventdate	DATETIME,
	@LeagueID	INT,
	@RaceNo		VARCHAR(5)
AS
/*	Created:Jamie
	Date:2009-12-01
	Task: Scratch HR Information using for Settlement/Agent Site
	DB: DBAGE/BODB02 

	Revisions:
		- 20130121@Elodie: Change link server DB06 to DBARC

*/
BEGIN
	SET NOCOUNT ON 
	IF EXISTS(SELECT 1 FROM Outright WITH (NOLOCK) WHERE leagueid = @leagueid AND eventdate=@eventdate)
	BEGIN
		SELECT	 matchcode
				,teamid 	
				,CONVERT(VARCHAR,SCRTime,108) SCRTime
				,risk Deduction
		FROM	Outright WITH (NOLOCK)
		WHERE	leagueid = @leagueid 
				AND groupmatch = @raceNo 
				AND eventdate = @eventdate 
				AND IsSCR = 1	
				AND FOddsStatus = 'completed'
		ORDER BY CAST (matchcode AS TINYINT) 
	END
	ELSE IF EXISTS(SELECT 1 FROM Outright14 WITH (NOLOCK) WHERE leagueid = @leagueid AND eventdate=@eventdate)
	BEGIN
		SELECT	 matchcode
				,teamid 	
				,CONVERT(VARCHAR,SCRTime,108) SCRTime
				,risk Deduction
		FROM	Outright14 WITH (NOLOCK)
		WHERE	leagueid = @leagueid 
				AND groupmatch = @raceNo 
				AND eventdate = @eventdate 
				AND IsSCR = 1	
				AND FOddsStatus = 'completed'
		ORDER BY CAST (matchcode AS TINYINT) 
	END
	ELSE
	BEGIN
		SELECT	 matchcode
				,teamid 	
				,CONVERT(VARCHAR,SCRTime,108) SCRTime
				,risk Deduction
		FROM	DBARC.bodb_archive.dbo.Outright_bk WITH (NOLOCK)
		WHERE	leagueid = @leagueid 
				AND groupmatch = @raceNo 
				AND eventdate = @eventdate 
				AND IsSCR = 1	
				AND FOddsStatus = 'completed'
		ORDER BY CAST (matchcode AS TINYINT) 
	END
END 

GO
GRANT EXECUTE ON [dbo].[Acc_Set_HR_ResultSCRSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Set_HR_ResultSCRSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Set_HR_ResultSCRSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_HR_ResultSCRSel] TO [vnteam]