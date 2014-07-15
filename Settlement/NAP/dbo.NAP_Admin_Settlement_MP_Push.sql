ALTER PROCEDURE [NAP_Admin_Settlement_MP_Push] (
	@MatchIds VARCHAR(4000)
	,@AdminId INT
	,@Action VARCHAR(20) = 'CAL'
	,@IP VARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
	)
AS
/*	Creator: 20140213@Kathy
	Task: Main SP for Mix parly settlement
	DB: DBTXN/BODB02
	ORIGINAL: Admin_Settlement_MP

	Revisions:		
		- 20140506@Kathy: Don't allow to calculate exists matches in queue
		- 20140512@Kathy: allow to execute undo action without score [Redmine:#14449]
						   
	Param's Explanation:		
		
*/
SET NOCOUNT ON

BEGIN
	DECLARE  @NotKeyScoreList VARCHAR(130)
			,@NotAllowCalculating VARCHAR(200)
			,@procName nvarchar(50)	
			,@matchid int

	DECLARE @match TABLE ( matchid INT
						  ,matchcode NVARCHAR(50)
						  ,fth SMALLINT
						  ,fta SMALLINT
						  ,hth SMALLINT
						  ,hta SMALLINT
						 )
	
	SELECT	 @ErrCode = 0
			,@ErrMsg = ''
			,@procName = OBJECT_NAME(@@procid)

	INSERT INTO @match ( matchid, matchcode, fth, fta, hth, hta)
	SELECT DISTINCT matchid
			,matchcode
			,finalhomescore
			,finalawayscore
			,hthomescore
			,htawayscore
	FROM DBPRO.BODB02.dbo.Match WITH (NOLOCK)
	WHERE matchid IN ( SELECT val
					   FROM dbo.strSplit(@matchids, ',') ) 

	IF EXISTS (SELECT 1
				FROM @match
				WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL ) AND @action <> 'UNDO'
	BEGIN
		SELECT @NotKeyScoreList = COALESCE(@NotKeyScoreList + ',' + matchcode, matchcode)
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL

		-- exclude matches were not keyscore yet
		DELETE
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
	END

	IF EXISTS (SELECT 1
				FROM @match
				WHERE matchid IN (SELECT matchid from Single_Calculate_Queue with(NOLOCK) where IsCalculating IN (0,1))
				OR matchid IN (SELECT matchid from Parlay_Calculate_Queue with(NOLOCK) where IsCalculating IN (0,1)) )
	BEGIN
		SELECT @NotAllowCalculating = COALESCE(@NotAllowCalculating + ',' + matchcode, matchcode)
		FROM @match 
		WHERE matchid IN (SELECT matchid from Single_Calculate_Queue with(NOLOCK) where IsCalculating IN (0,1) )
		OR matchid IN (SELECT matchid FROM Parlay_Calculate_Queue with(NOLOCK) WHERE IsCalculating IN (0,1) ) 

		-- exclude matches were not allow to calculate
		DELETE
		FROM @match
		WHERE matchid IN (SELECT matchid from Single_Calculate_Queue with(NOLOCK) where IsCalculating IN (0,1) )
		OR matchid IN (SELECT matchid FROM Parlay_Calculate_Queue with(NOLOCK) WHERE IsCalculating IN (0,1) ) 
	END

	IF EXISTS (
				SELECT TOP 1 1
				FROM @match
				)
	BEGIN
		IF (ISNULL(@NotKeyScoreList,'') <> '' or ISNULL(@NotAllowCalculating,'') <> '')
		BEGIN
			SELECT   @ErrCode = 100
					,@ErrMsg = 'All matches are being calculated, except following matches ' 
								+ CASE WHEN ISNULL(@NotKeyScoreList, '') <> '' 
										THEN  '(not keyed in score yet): ' + @NotKeyScoreList 
										ELSE ''
								  END
								+ CASE when ISNULL(@NotAllowCalculating,'') <> ''
										THEN  '(being calculated by another user): ' + @NotAllowCalculating
										ELSE ''
								  END 
		END

		IF @procName LIKE '%_xtest' or @procName LIKE '%_xpre'
		BEGIN
			WHILE(1 = 1)
			BEGIN
				SELECT TOP 1 @matchid = matchid
				FROM @match

				IF @@ROWCOUNT = 0
					BREAK
					 
				BEGIN TRY
					EXEC [NAP_Admin_Settlement_Parlay] @matchids = @matchid
						,@creator = @AdminId
						,@action  = @action
						,@IP      = @IP
						,@ErrCode = @ErrCode OUTPUT
						,@ErrMsg  = @ErrMsg   OUTPUT
				END TRY

				BEGIN CATCH
					SELECT @ErrMsg  = @ErrMsg + ISNULL(ERROR_MESSAGE(),'')
						  ,@ErrCode = @ErrCode
					RETURN
				END CATCH

				DELETE 
				FROM @match
				WHERE matchid = @matchid
			END
			
		END
		ELSE
		BEGIN		
			INSERT INTO dbo.Parlay_Calculate_Queue (matchid, isCalculating, creator, ip, starttime, action)
			SELECT matchid, 0, @AdminId, @IP, CURRENT_TIMESTAMP, @action
			FROM @match
		END
	END
END

GO

GRANT EXECUTE ON [NAP_Admin_Settlement_MP_Push] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_MP_Push] TO [vnteam] AS [dbo]
GO


