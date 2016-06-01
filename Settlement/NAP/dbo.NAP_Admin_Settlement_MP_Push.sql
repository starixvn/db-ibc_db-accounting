ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_MP_Push] (
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
		- 20141117@Jamie: Change ErrCode [Redmine:#23034]		
		- 20150401@Kathy: Add checking ticket status before performing settlement [Redmine:#33493]		
		- 20150922@Johnson: check result status from ResultDetail [Redmine: #43806]
		- 20151002@Kathy: add more UAT version for testing (UAT1,UAT2,UAT3,UAT4)
		- 20160429@Kathy: Enhance performance [Redmine:#52426]
		- 20160524@Kathy: Exclude ComboParlay 
	Param's Explanation:		
		
*/
SET NOCOUNT ON

BEGIN
	DECLARE  @NotKeyScoreList VARCHAR(130)
			,@NotAllowCalculating VARCHAR(200)
			,@HaveWaitingTicket VARCHAR(200)
			,@procName nvarchar(50)	
			,@matchid int
			,@comboMatchIds VARCHAR(4000) 
	
	SET @comboMatchIds = @matchids
		
	DECLARE @subErrCode		INT
			,@subErrMsg		NVARCHAR(200)
	
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
			,@subErrCode = 0
			,@subErrMsg = ''
			
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
		OR EXISTS (SELECT 1
					FROM DBPRO.BODB02.dbo.ResultDetail WITH(NOLOCK)
					WHERE matchid IN (SELECT matchid FROM @match)
						AND ResourceId NOT IN ('00','01','08')
						AND ResultStatusId NOT IN (2,5)
				)				
	BEGIN
		SELECT @NotKeyScoreList = COALESCE(@NotKeyScoreList + ',' + matchcode, matchcode)
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
			OR matchid IN (
				SELECT matchid
				FROM DBPRO.BODB02.dbo.ResultDetail WITH(NOLOCK)
				WHERE matchid IN (SELECT matchid FROM @match)
					AND ResourceId NOT IN ('00','01','08')
					AND ResultStatusId NOT IN (2,5))

		-- exclude matches were not keyscore yet
		DELETE
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
			OR matchid IN (
				SELECT matchid
				FROM DBPRO.BODB02.dbo.ResultDetail WITH(NOLOCK)
				WHERE matchid IN (SELECT matchid FROM @match)
					AND ResourceId NOT IN ('00','01','08')
					AND ResultStatusId NOT IN (2,5))
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
	
	-- check waiting ticket
	EXEC NAP_Admin_Settlement_Checking
		@MatchIds = @MatchIds	OUTPUT
		,@Action = @Action
		,@Mode = 'CAL-MP'	
	
	SELECT @HaveWaitingTicket = COALESCE(@HaveWaitingTicket + ',' + m.matchcode, m.matchcode)
	FROM dbo.match m WITH(NOLOCK)
	WHERE m.matchid IN (SELECT val FROM dbo.strSplit(@MatchIds, ','))
	
	DELETE FROM @match
	WHERE matchid IN (SELECT val FROM dbo.strSplit(@MatchIds, ','))
	
	-- check Combo Parlay tickets
	DECLARE @HaveComboParlayTicket VARCHAR(200) = ''
	
	EXEC NAP_Admin_ComboParlay_Checking
		@MatchIds	= @comboMatchIds OUTPUT
	
	SELECT @HaveComboParlayTicket = COALESCE(@HaveComboParlayTicket + ',' + m.matchcode, m.matchcode)
	FROM dbo.match m WITH(NOLOCK)
	WHERE m.matchid IN (SELECT val FROM dbo.strSplit(@comboMatchIds, ','))
	
	DELETE FROM @match
	WHERE matchid IN (SELECT val FROM dbo.strSplit(@comboMatchIds, ','))
	
	IF (ISNULL(@NotKeyScoreList,'') <> '' or ISNULL(@NotAllowCalculating,'') <> '' OR ISNULL(@HaveWaitingTicket,'') <> '' OR ISNULL(@HaveComboParlayTicket,'') <> '')
	BEGIN
		SELECT   @ErrCode = 1001011
				,@ErrMsg = 'All matches are being calculated, except following matches ' 
							+ CASE WHEN ISNULL(@NotKeyScoreList, '') <> '' 
									THEN  '(not keyed in score yet): ' + @NotKeyScoreList 
									ELSE ''
								END
							+ CASE when ISNULL(@NotAllowCalculating,'') <> ''
									THEN  '(being calculated by another user): ' + @NotAllowCalculating
									ELSE ''
								END 
							+ CASE WHEN ISNULL(@HaveWaitingTicket, '') <> ''
									THEN '(existing some PENDING tickets): ' + @HaveWaitingTicket
									ELSE ''
								END
							+ CASE WHEN ISNULL(@HaveComboParlayTicket, '') <> ''
									THEN '(existing NEW Combo Parlay tickets): ' + @HaveComboParlayTicket
									ELSE ''
								END
	END
	
	IF EXISTS (
				SELECT TOP 1 1
				FROM @match
				)
	BEGIN
		IF @procName LIKE '%_xtest' or @procName LIKE '%_xpre' OR @procName LIKE '%_UAT_' -- UAT1 -->UAT9
		BEGIN

			WHILE(1 = 1)
			BEGIN
				SELECT TOP 1 @matchid = matchid
				FROM @match

				IF @@ROWCOUNT = 0
					BREAK
					 
				BEGIN TRY
										EXEC [NAP_Admin_Settlement_MP] @matchid = @matchid
						,@creator = @AdminId
						,@action  = @action
						,@IP      = @IP
						,@ErrCode = @subErrCode OUTPUT
						,@ErrMsg  = @subErrMsg   OUTPUT
				END TRY

				BEGIN CATCH
					SELECT @ErrMsg  = @subErrMsg + ISNULL(ERROR_MESSAGE(),'')
						  ,@ErrCode = @@error
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
GRANT EXECUTE ON [dbo].[NAP_Admin_Settlement_MP_Push] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Settlement_MP_Push] TO [vnteam] AS [dbo]