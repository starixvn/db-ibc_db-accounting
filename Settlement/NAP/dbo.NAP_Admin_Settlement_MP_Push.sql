USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
		- 20160714@Kathy: Add checking SystemSettings before doing Parlay Settlement on UAT
		- 20160801@Patrick: Auto Payout - User can cal MP before calculating FT FGLG [Redmine: #61767]
		- 20161125@Bobby: @#67822 - check single and parlay ticket for AUTO bet types

	Param's Explanation:		
		
*/
SET NOCOUNT ON

BEGIN
	DECLARE  @NotKeyScoreList VARCHAR(130)
			,@NotAllowCalculating VARCHAR(200)
			,@HaveWaitingTicket VARCHAR(200)
			,@procName nvarchar(50)	
			,@matchid int
		
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
	
	DECLARE @tblRunningAutoSettle TABLE (matchid INT)
	
	INSERT INTO @tblRunningAutoSettle
	SELECT matchid
	FROM	dbo.bettrans WITH(NOLOCK)
	WHERE	matchid IN (SELECT matchid FROM @match)
			AND statusID = 0
			AND bettype IN (SELECT bettype FROM dbo.f_Set_GetGroupBettypes() WHERE GroupId = 8)
	GROUP BY matchid
	
	;WITH cteBetStatusM
	AS(
		SELECT	matchid
				,CASE 
					WHEN BetType IN (160,164,169,180,216) THEN CAST(BetType AS VARCHAR(20)) + '__'
					ELSE CAST(BetType AS VARCHAR(20))
				END AS ResourceId
		FROM	dbo.bettransm WITH(NOLOCK)
		WHERE	matchid IN (SELECT matchid FROM @match)
				AND statusID = 0
				AND bettype IN (SELECT BetType FROM dbo.f_Set_GetGroupBettypes() WHERE GroupId = 8)
		GROUP BY matchid, bettype		
	)
	INSERT INTO @tblRunningAutoSettle (matchid)
	SELECT	c.matchid
	FROM	cteBetStatusM c
		LEFT JOIN DBPRO.BODB02.dbo.ResultDetail r WITH(NOLOCK)
			ON	c.matchid = r.matchid
				AND r.ResourceId LIKE c.ResourceId
	WHERE	r.ResultStatusId NOT IN (2,5)
		
	IF EXISTS (SELECT 1
				FROM @match
				WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL ) AND @action <> 'UNDO'
		OR EXISTS (SELECT TOP 1 1
					FROM @tblRunningAutoSettle
				)				
	BEGIN
		SELECT @NotKeyScoreList = COALESCE(@NotKeyScoreList + ',' + matchcode, matchcode)
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
			OR matchid IN (SELECT matchid FROM @tblRunningAutoSettle)

		-- exclude matches were not keyscore yet
		DELETE
		FROM @match
		WHERE fth IS NULL OR fta IS NULL OR hth IS NULL OR hta IS NULL
				OR matchid IN (SELECT matchid FROM @tblRunningAutoSettle)
	END

	--have running tickets of 14 & 127 on bettrans & bettransm for auto payout
	DECLARE @Tmp TABLE(MatchId INT, matchcode VARCHAR(100))
	IF EXISTS (SELECT TOP 1 1
				FROM dbo.bettrans WITH(NOLOCK)
				WHERE matchid IN (SELECT matchid FROM @match)
					AND bettype IN (14,127)
					AND statusID = 0
			)
	BEGIN
		-- exclude matches were not keyscore yet
		DELETE m
		OUTPUT DELETED.matchid, DELETED.matchcode INTO @Tmp(MatchId, matchcode)
		FROM @match m
		WHERE EXISTS (SELECT 1 FROM dbo.bettrans b WITH(NOLOCK)
						WHERE m.matchid = b.matchid
							AND bettype IN (14,127)
							AND statusID = 0)
	END

	IF EXISTS (SELECT TOP 1 1
					FROM dbo.bettransm WITH(NOLOCK)
					WHERE matchid IN (SELECT matchid FROM @match)
						AND bettype IN (14,127)
						AND statusID = 0
		)
	BEGIN
		DELETE m
		OUTPUT DELETED.matchid, DELETED.matchcode INTO @Tmp(MatchId, matchcode)
		FROM @match m
		WHERE EXISTS (SELECT 1 FROM dbo.bettransm b WITH(NOLOCK)
						WHERE m.matchid = b.matchid
							AND bettype IN (14,127)
							AND statusID = 0)
	END

	IF EXISTS (SELECT TOP 1 1 FROM @Tmp)
	BEGIN
		SELECT @NotKeyScoreList = COALESCE(@NotKeyScoreList + ',' + matchcode, matchcode)
		FROM @Tmp
	END
	--End: have running tickets of 14 & 127 on bettrans & bettransm for auto payout

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

	IF (ISNULL(@NotKeyScoreList,'') <> '' or ISNULL(@NotAllowCalculating,'') <> '' OR ISNULL(@HaveWaitingTicket,'') <> '')
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
				
				IF EXISTS (SELECT TOP 1 1 FROM dbo.SystemSettings WHERE VName = 'isCalculatingParlay' AND VValue = 1)
				BEGIN
					SELECT	@ErrCode = 1000000
						,@ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'
					RETURN	
				END
				ELSE
				BEGIN
					UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
							SET VValue = 1
					WHERE VName = 'isCalculatingParlay'
				END
				
				BEGIN TRY
					EXEC [NAP_Admin_Settlement_MP] @matchid = @matchid
						,@creator = @AdminId
						,@action  = @action
						,@IP      = @IP
						,@ErrCode = @subErrCode OUTPUT
						,@ErrMsg  = @subErrMsg   OUTPUT
				END TRY
				BEGIN CATCH					
					UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
							SET VValue = 0
					WHERE VName = 'isCalculatingParlay'
						
					SELECT @ErrMsg  = @subErrMsg + ISNULL(ERROR_MESSAGE(),'')
						  ,@ErrCode = @@error
					RETURN
				END CATCH
								
				UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
						SET VValue = 0
				WHERE VName = 'isCalculatingParlay'

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