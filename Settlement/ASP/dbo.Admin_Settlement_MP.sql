ALTER PROCEDURE [dbo].[Admin_Settlement_MP] 
(
	@matchids	VARCHAR(4000),
	@creator	INT,
	@action		VARCHAR(10) = 'CAL',
	@IP			VARCHAR(15) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
)
AS
/*	Creator: 20130627@Lukas
	Task: Main SP for Mix parly settlement
	DB: DBTXN/BODB02
	ORIGINAL: 

	Revisions:		
						   
	Param's Explanation:		
		
*/
SET NOCOUNT ON
BEGIN	

	DECLARE @NotKeyScoreList VARCHAR(130)
	DECLARE @match TABLE (		
		matchid INT,
		matchcode nvarchar(50),
		fth SMALLINT, 
		fta SMALLINT, 
		hth SMALLINT, 
		hta SMALLINT
	)
	
	INSERT INTO @match(matchid, matchcode, fth, fta, hth, hta)
	SELECT distinct matchid, matchcode, finalhomescore, finalawayscore, hthomescore, htawayscore
	FROM DBPRO.BODB02.dbo.Match with(rowlock)
	WHERE matchid IN (SELECT val FROM dbo.strSplit(@matchids,','))	
		AND matchid NOT IN (select matchid from Parlay_WaitingList WITH(NOLOCK))
		
	IF EXISTS (SELECT 1 FROM @match	WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL)
	BEGIN			
		SELECT @NotKeyScoreList  = COALESCE(@NotKeyScoreList + ',' + matchcode,matchcode)
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL

		-- exclude matches were not keyscore yet
		DELETE FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
	END
	
	INSERT INTO dbo.Parlay_WaitingList (matchid, isCalculating, creator, ip, starttime, action)
	SELECT matchid, 0, @creator, @IP, CURRENT_TIMESTAMP, @action
	FROM @match		
		
	IF @NotKeyScoreList IS NOT NULL AND @NotKeyScoreList <> ''
	BEGIN
		SELECT	@ErrCode = 1,
				@ErrMsg = 'All matches are being calculated, except following matches (not keyed in score yet): ' + 
				CASE WHEN LEN(@NotKeyScoreList) = 130 THEN @NotKeyScoreList + '...'
					 ELSE @NotKeyScoreList
				END
	END
	
END

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_MP] TO [bodbAdminNet]
