USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Set_MatchSelDetail] @matchid INT
	,@excludeRefundFGLG BIT = 0
AS
/*
	Created by: 20120913
	Task: Update score 
	DB: DBTXN/BODB02 
	Original: [Acc_Set_MatchSelScore], Acc_Set_MatchSelForBill
	
	Revisions:			
		- 20140304@Kathy: Execute settlement for abandoned/postponed matches- Clean Sheet, Both/One/Neither team to score, To Win To Nil 
		- 20140423@Kathy: Remove check weekend peak-hour
		- 20140506@Kathy: Add IsExistHTFGLG, IsExistHTLG column. Offer new bettype 126, 127 (1H total goal, 1H FGLG) [Redmine:#14449]
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]
		- 20140623@Kathy: Apply BetRadar - Add new bettype 151 (1st Half Double Chance) [Redmine:#17142]
		- 20140710@Kathy: Apply BetRadar - bettype 135 (PenaltyShootout) - check PS status [Redmine:#17142]
		- 20140725@Kathy: Settle determined tickets for Correct Score(4,30)[Redmine:#19310]
		- 20140811@Kathy: Support new 11 bettypes [Redmine:#19667]
		- 20140905@Kathy: exclude virtual racing bettype 1231,1232,1233
		- 20140909@Kathy: Exclude virtual racing (bettype 1237, 1238), outright (bettype 10, 31, 32, 33),
						 sportting solution (from 1301 -> 1334), keno (1501 -> 1599)
		- 20141008@Jamie: Sportting Solution settlement [Redmine: #23034]
		- 20141204@Jamie: Sportting Solution settlement - GameSession to indicate the type of league [Redmine:#27027]
		- 20150401@Jamie: Auto Settlement Betradar phase 2 [Redmine: #27212]
		- 20150406@Jamie: Manual Settlement Betradar phase 2 [Redmine: #27212]
		- 20150602@Jamie: DisplayCat = 8 ExtraTime 
		- 20150611@Jamie: Remove the contrainst  DisplayCat = 8 ExtraTime 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IsExistFGLG BIT
		,@IsExistLG BIT
		,@IsHTOnly BIT
		,@IsLive BIT
		,@IsSettleAbandonedMatchIBC BIT
		,@sporttype TINYINT
		,@IsExistHTFGLG BIT
		,@IsExistHTLG BIT
		,@FTStatus NVARCHAR(20)
		,@HTStatus NVARCHAR(20)
		,@FGLGStatus NVARCHAR(20)
		,@HTFGLGStatus NVARCHAR(20)
		--,@PSStatus NVARCHAR(20)
		,@FGLG_FTParlayRunning BIT
		,@FGLG_HTParlayRunning BIT
		,@PSParlayRunning BIT
		,@IsExistPS BIT
		,@LeagueID	INT
		-- Tennis Settlement 
		,@TennisStatusSet1	NVARCHAR(20)
		,@TennisStatusSet2	NVARCHAR(20)
		,@TennisStatusSet3	NVARCHAR(20)
		,@TennisStatusSet4	NVARCHAR(20)
		,@TennisStatusSet5	NVARCHAR(20)
		,@TennisStatusMatch NVARCHAR(20)	-- Match Scope 

		-- Betradar Results
		,@isExistTotalCorner	BIT
		,@isExistHTFCorner		BIT
		,@isExistHTLCorner		BIT
		,@isExistFTFCorner		BIT	
		,@isExistFTLCorner		BIT
		,@isExistResultandFirstTeamScore	BIT

	SELECT @IsExistLG = 0
		,@IsExistFGLG = 0
		,@IsHTOnly = 0
		,@IsLive = 0
		,@IsSettleAbandonedMatchIBC = 0
		,@IsExistHTLG = 0
		,@IsExistHTFGLG = 0
		,@IsExistPS  = 0
		,@isExistTotalCorner	= 0
		,@isExistHTFCorner		= 0
		,@isExistHTLCorner		= 0
		,@isExistFTFCorner		= 0	
		,@isExistFTLCorner		= 0
		,@isExistResultandFirstTeamScore = 0 

	SELECT	 @sporttype = sporttype
			,@LeagueID	= leagueid
	FROM	match WITH (NOLOCK)
	WHERE	matchid = @matchid

	IF @excludeRefundFGLG = 0 -- Calculate page
	BEGIN
		-- IsExistLG
		IF EXISTS (
				SELECT TOP 1 1
				FROM bettrans WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 14 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102)
				)
			SELECT @IsExistLG = 1
		ELSE IF EXISTS (
				SELECT TOP 1 1
				FROM bettransm WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 14 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102)
				)
			SELECT @IsExistLG = 1

		-- IsExistHTLG
		IF EXISTS (
				SELECT TOP 1 1
				FROM bettrans WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 127 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102)
				)
			SELECT @IsExistHTLG = 1
		ELSE IF EXISTS (
				SELECT TOP 1 1
				FROM bettransm WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 127 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102)
				)
			SELECT @IsExistHTLG = 1

		-- IsExistFGLG
		IF (@IsExistLG = 0)
		BEGIN
			IF EXISTS (
					SELECT TOP 1 1
					FROM bettrans WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101, 102)
					)
				SELECT @IsExistFGLG = 1
			ELSE IF EXISTS (
					SELECT TOP 1 1
					FROM bettransm WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101, 102)
					)
				SELECT @IsExistFGLG = 1
		END
		ELSE
			SELECT @IsExistFGLG = 1

		-- IsExistHTFGLG
		IF (@IsExistHTLG = 0)
		BEGIN
			IF EXISTS (
					SELECT TOP 1 1
					FROM bettrans WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101, 102)
					)
				SELECT @IsExistHTFGLG = 1
			ELSE IF EXISTS (
					SELECT TOP 1 1
					FROM bettransm WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101, 102)
					)
				SELECT @IsExistHTFGLG = 1
		END
		ELSE
			SELECT @IsExistHTFGLG = 1

		---- IsExistPS
		--IF EXISTS (	
		--	SELECT TOP 1 1
		--	FROM bettrans WITH(NOLOCK)
		--	WHERE matchid = @matchid AND bettype = 135 AND statusID NOT IN (101, 102)
		--)
		--	SELECT @IsExistPS = 1
		--ELSE IF EXISTS
		--	(
		--	SELECT TOP 1 1
		--	FROM bettransm WITH(NOLOCK)
		--	WHERE matchid = @matchid AND bettype = 135 AND statusID NOT IN (101, 102)
		--	)
		--	SELECT @IsExistPS = 1


		-- @isExistResultandFirstTeamScore
		IF EXISTS (	
			SELECT TOP 1 1
			FROM bettrans WITH(NOLOCK)
			WHERE matchid = @matchid AND bettype = 172 AND statusID NOT IN (101, 102)
		)
			SELECT @isExistResultandFirstTeamScore = 1
		ELSE IF EXISTS
			(
			SELECT TOP 1 1
			FROM bettransm WITH(NOLOCK)
			WHERE matchid = @matchid AND bettype = 172 AND statusID NOT IN (101, 102)
			)
			SELECT @isExistResultandFirstTeamScore = 1

		/**START: Check existing Corner bettypes or not **/
		IF EXISTS(
			SELECT TOP 1 1 
			FROM	Bettrans WITH (NOLOCK)
			WHERE	MatchID = @matchid
					AND bettype BETWEEN 194 AND 205 
					AND statusID NOT IN (101, 102)
			)
			OR EXISTS(
				SELECT TOP 1 1 
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype BETWEEN 194 AND 205 
						AND statusID NOT IN (101, 102)
			)
		BEGIN
			SELECT	@isExistTotalCorner = 1 	
		END			

		IF EXISTS(	
			SELECT	TOP 1 1
			FROM	Bettrans WITH (NOLOCK) 
			WHERE	MatchID = @matchid
					AND bettype BETWEEN 206 AND 209
					AND statusID NOT IN (101, 102)
		) 
		OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype BETWEEN 206 AND 209
						AND statusID NOT IN (101, 102)
		)
		BEGIN
			IF EXISTS(
				SELECT	TOP 1 1
				FROM	Bettrans WITH (NOLOCK) 
				WHERE	MatchID = @matchid
						AND bettype = 206
						AND statusID NOT IN (101, 102)
			) 
			OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype = 206
						AND statusID NOT IN (101, 102)
			)
			BEGIN
				SELECT	@isExistFTFCorner = 1 
			END

			IF EXISTS(
				SELECT	TOP 1 1
				FROM	Bettrans WITH (NOLOCK) 
				WHERE	MatchID = @matchid
						AND bettype = 208
						AND statusID NOT IN (101, 102)
			) 
			OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype = 208
						AND statusID NOT IN (101, 102)
			)
			BEGIN
				SELECT	@isExistFTLCorner = 1 
			END

			IF EXISTS(
				SELECT	TOP 1 1
				FROM	Bettrans WITH (NOLOCK) 
				WHERE	MatchID = @matchid
						AND bettype = 207
						AND statusID NOT IN (101, 102)
			) 
			OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype = 207
						AND statusID NOT IN (101, 102)
			)
			BEGIN
				SELECT	@isExistHTFCorner = 1 
			END

			IF EXISTS(
				SELECT	TOP 1 1
				FROM	Bettrans WITH (NOLOCK) 
				WHERE	MatchID = @matchid
						AND bettype = 209
						AND statusID NOT IN (101, 102)
			) 
			OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype = 209
						AND statusID NOT IN (101, 102)
			)
			BEGIN
				SELECT	@isExistHTLCorner = 1 
			END
		END

		/**END: Check existing Corner bettypes or not **/


		-- check match status
		DECLARE @status TABLE (
			[Group] TINYINT
			,BetCount INT
			,InRunning INT
			)

		INSERT INTO @status
		SELECT CASE -- 0:FT , 1:HT , 2:FGLG , 3: HTFGLG , 4: PS
				WHEN bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209) THEN 1
				WHEN bettype = 14 THEN 2
				WHEN bettype = 127 THEN 3
				WHEN bettype = 135 THEN 4
				WHEN bettype IN (154,155,156,1311,1312,1316,1317,1318,1324)	--- Tennis Set x 
					THEN CASE	WHEN CAST(betid AS VARCHAR(20)) LIKE '801%' THEN 11		-- Tennis Set 1 
								WHEN CAST(betid AS VARCHAR(20)) LIKE '802%' THEN 12		-- Tennis Set 2
								WHEN CAST(betid AS VARCHAR(20)) LIKE '803%' THEN 13		-- Tennis Set 3
								WHEN CAST(betid AS VARCHAR(20)) LIKE '804%' THEN 14		-- Tennis Set 4
								WHEN CAST(betid AS VARCHAR(20)) LIKE '805%' THEN 15		-- Tennis Set 5
								ELSE 0 END 
				ELSE 0
				END
			,SUM(CASE 
					WHEN [statusID] IN (101, 102) THEN 0
					ELSE 1
					END)
			,SUM(CASE 
					WHEN [statusID] = 0 THEN 1
					ELSE 0
					END)
		FROM bettrans WITH (NOLOCK)
		WHERE	matchid = @matchid 
				AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238)
				AND bettype NOT IN (135,160,164,168,169,173,174,175,176,180,192,193,210,211,212,213,214,215,216,217)
				AND bettype NOT BETWEEN 1501 and 1599 -- Keno
		GROUP BY CASE 
				WHEN bettype IN (7, 8, 12, 15, 21, 30, 125, 126, 129, 136, 138, 143, 151,165,167,179,181,182,188,191,200,201,202,203,204,205,207,209) THEN 1
				WHEN bettype = 14 THEN 2
				WHEN bettype = 127 THEN 3
				WHEN bettype = 135 THEN 4
				WHEN bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) 
					THEN CASE	WHEN CAST(betid AS VARCHAR(20)) LIKE '801%' THEN 11		-- Tennis Set 1 
								WHEN CAST(betid AS VARCHAR(20)) LIKE '802%' THEN 12		-- Tennis Set 2
								WHEN CAST(betid AS VARCHAR(20)) LIKE '803%' THEN 13		-- Tennis Set 3
								WHEN CAST(betid AS VARCHAR(20)) LIKE '804%' THEN 14		-- Tennis Set 4
								WHEN CAST(betid AS VARCHAR(20)) LIKE '805%' THEN 15		-- Tennis Set 5
								ELSE 0 END 
				ELSE 0
				END

		IF NOT EXISTS (
				SELECT *
				FROM @status
				WHERE [Group] = 0
				)
			INSERT INTO @status
			VALUES (
				0
				,0
				,0
				)

		IF NOT EXISTS (
				SELECT *
				FROM @status
				WHERE [Group] = 1
				)
			INSERT INTO @status
			VALUES (
				1
				,0
				,0
				)

		IF NOT EXISTS (
				SELECT *
				FROM @status
				WHERE [Group] = 2
				)
			INSERT INTO @status
			VALUES (
				2
				,0
				,0
				)

		IF NOT EXISTS (
				SELECT *
				FROM @status
				WHERE [Group] = 3
				)
			INSERT INTO @status
			VALUES (
				3
				,0
				,0
				)

		IF NOT EXISTS (
				SELECT *
				FROM @status
				WHERE [Group] = 4
				)
			INSERT INTO @status
			VALUES (
				4
				,0
				,0
				)
		IF NOT EXISTS ( SELECT * FROM @status WHERE [Group] = 11)
			INSERT INTO @status VALUES (11,0,0)

		IF NOT EXISTS ( SELECT * FROM @status WHERE [Group] = 12)
			INSERT INTO @status VALUES (12,0,0)

		IF NOT EXISTS ( SELECT * FROM @status WHERE [Group] = 13)
			INSERT INTO @status VALUES (13,0,0)

		IF NOT EXISTS ( SELECT * FROM @status WHERE [Group] = 14)
			INSERT INTO @status VALUES (14,0,0)

		IF NOT EXISTS ( SELECT * FROM @status WHERE [Group] = 15)
			INSERT INTO @status VALUES (15,0,0)

		SELECT TOP 1 @FGLG_FTParlayRunning = CASE WHEN statusID = 0 THEN 1 ELSE 0 END
		FROM bettransm WITH(NOLOCK)
		WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101,102)

		SELECT TOP 1 @FGLG_HTParlayRunning = CASE WHEN statusID = 0 THEN 1 ELSE 0 END
		FROM bettransm WITH(NOLOCK)
		WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101,102)

		SELECT TOP 1 @PSParlayRunning = CASE WHEN statusID = 0 THEN 1 ELSE 0 END
		FROM bettransm with(NOLOCK)
		WHERE matchid = @matchid AND bettype = 135 AND statusID NOT IN (101, 102)

		SELECT @FTStatus = CASE 
				WHEN betcount = 0 THEN N'No Ticket'
				WHEN inRunning = 0 THEN N'Calculated'
				ELSE N'Running'
				END
		FROM @status
		WHERE [Group] = 0

		SELECT @HTStatus = CASE 
				WHEN betcount = 0 THEN N'No Ticket'
				WHEN inRunning = 0 THEN N'Calculated'
				ELSE N'Running'
				END
		FROM @status
		WHERE [Group] = 1
		
		SELECT @FGLGStatus = CASE 
				WHEN betcount = 0 THEN CASE WHEN @FGLG_FTParlayRunning IS NULL THEN N'No Ticket'
											WHEN @FGLG_FTParlayRunning = 1 then N'Parlay Running'
											WHEN @FGLG_FTParlayRunning = 0 THEN N'Parlay Calculated'
										END
				WHEN inRunning = 0 THEN N'Calculated'
				ELSE N'Running'
				END
		FROM @status
		WHERE [Group] = 2

		SELECT @HTFGLGStatus = CASE 
				WHEN betcount = 0 THEN CASE WHEN  @FGLG_HTParlayRunning IS NULL THEN  N'No Ticket'
											WHEN @FGLG_HTParlayRunning = 1 then N'Parlay Running'	
											WHEN @FGLG_HTParlayRunning = 0 then N'Parlay Calculated'
										END
				WHEN inRunning = 0 THEN N'Calculated'
				ELSE N'Running'
				END
		FROM @status
		WHERE [Group] = 3

		--SELECT @PSStatus = CASE 
		--		WHEN betcount = 0 THEN CASE WHEN @PSParlayRunning IS NULL THEN  N'No Ticket'
		--									WHEN @PSParlayRunning = 1 then N'Parlay Running'	
		--									WHEN @PSParlayRunning = 0 then N'Parlay Calculated'
		--								END
		--		WHEN inRunning = 0 THEN N'Calculated'
		--		ELSE N'Running'
		--		END
		--FROM @status
		--WHERE [Group] = 4

		--- Tennis Ticket Status 

		SELECT	@TennisStatusSet1 = CASE	WHEN betcount = 0 THEN N'No Ticket'
											WHEN inRunning = 0 THEN N'Calculated'
											ELSE N'Running'
											END
		FROM	@Status 
		WHERE	[Group] = 11 

		SELECT	@TennisStatusSet2 = CASE	WHEN betcount = 0 THEN N'No Ticket'
											WHEN inRunning = 0 THEN N'Calculated'
											ELSE N'Running'
											END
		FROM	@Status 
		WHERE	[Group] = 12

		SELECT	@TennisStatusSet3 = CASE	WHEN betcount = 0 THEN N'No Ticket'
											WHEN inRunning = 0 THEN N'Calculated'
											ELSE N'Running'
											END
		FROM	@Status 
		WHERE	[Group] = 13

		SELECT	@TennisStatusSet4 = CASE	WHEN betcount = 0 THEN N'No Ticket'
											WHEN inRunning = 0 THEN N'Calculated'
											ELSE N'Running'
											END
		FROM	@Status 
		WHERE	[Group] = 14

		SELECT	@TennisStatusSet5 = CASE	WHEN betcount = 0 THEN N'No Ticket'
											WHEN inRunning = 0 THEN N'Calculated'
											ELSE N'Running'
											END
		FROM	@Status 
		WHERE	[Group] = 15

		SELECT	@TennisStatusMatch = CASE	WHEN betcount = 0 THEN N'No Ticket'
											WHEN inRunning = 0 THEN N'Calculated'
											ELSE N'Running'
											END
		FROM	@Status 
		WHERE	[Group] = 0
				AND @Sporttype = 5 
	

		
	END
	ELSE -- Refund page
	BEGIN
		-- IsExistLG
		IF EXISTS (
				SELECT TOP 1 1
				FROM bettrans WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 14 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102, 103)
				)
			SELECT @IsExistLG = 1
		ELSE IF EXISTS (
				SELECT TOP 1 1
				FROM bettransm WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 14 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102, 103)
				)
			SELECT @IsExistLG = 1

		-- IsExistHTLG
		IF EXISTS (
				SELECT TOP 1 1
				FROM bettrans WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 127 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102, 103)
				)
			SELECT @IsExistHTLG = 1
		ELSE IF EXISTS (
				SELECT TOP 1 1
				FROM bettransm WITH (NOLOCK)
				WHERE matchid = @matchid AND bettype = 127 AND right(BETTEAM, 1) = '2' AND statusID NOT IN (101, 102, 103)
				)
			SELECT @IsExistHTLG = 1

		-- IsExistFGLG
		IF (@IsExistLG = 0)
		BEGIN
			IF EXISTS (
					SELECT TOP 1 1
					FROM bettrans WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101, 102, 103)
					)
				SELECT @IsExistFGLG = 1
			ELSE IF EXISTS (
					SELECT TOP 1 1
					FROM bettransm WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101, 102, 103)
					)
				SELECT @IsExistFGLG = 1
		END
		ELSE
			SELECT @IsExistFGLG = 1

		-- IsExistHTFGLG
		IF (@IsExistHTLG = 0)
		BEGIN
			IF EXISTS (
					SELECT TOP 1 1
					FROM bettrans WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101, 102, 103)
					)
				SELECT @IsExistHTFGLG = 1
			ELSE IF EXISTS (
					SELECT TOP 1 1
					FROM bettransm WITH (NOLOCK)
					WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101, 102, 103)
					)
				SELECT @IsExistHTFGLG = 1
		END
		ELSE
			SELECT @IsExistHTFGLG = 1


		-- @isExistResultandFirstTeamScore
		IF EXISTS (	
			SELECT TOP 1 1
			FROM bettrans WITH(NOLOCK)
			WHERE matchid = @matchid AND bettype = 172 AND statusID NOT IN (101, 102, 103)
		)
			SELECT @isExistResultandFirstTeamScore = 1
		ELSE IF EXISTS
			(
			SELECT TOP 1 1
			FROM bettransm WITH(NOLOCK)
			WHERE matchid = @matchid AND bettype = 172 AND statusID NOT IN (101, 102, 103)
			)
			SELECT @isExistResultandFirstTeamScore = 1

		/**START: Check existing Corner bettypes or not **/
		IF EXISTS(
			SELECT TOP 1 1 
			FROM	Bettrans WITH (NOLOCK)
			WHERE	MatchID = @matchid
					AND bettype BETWEEN 194 AND 205 
					AND statusID NOT IN (101, 102,103)
			)
			OR EXISTS(
				SELECT TOP 1 1 
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype BETWEEN 194 AND 205 
						AND statusID NOT IN (101, 102,103)
			)
		BEGIN
			SELECT	@isExistTotalCorner = 1 	
		END			

		IF EXISTS(	
			SELECT	TOP 1 1
			FROM	Bettrans WITH (NOLOCK) 
			WHERE	MatchID = @matchid
					AND bettype BETWEEN 206 AND 209
					AND statusID NOT IN (101, 102,103)
		) 
		OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype BETWEEN 206 AND 209
						AND statusID NOT IN (101, 102,103)
		)
		BEGIN
			IF EXISTS(
				SELECT	TOP 1 1
				FROM	Bettrans WITH (NOLOCK) 
				WHERE	MatchID = @matchid
						AND bettype = 206
						AND statusID NOT IN (101, 102,103)
			) 
			OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype = 206
						AND statusID NOT IN (101, 102,103)
			)
			BEGIN
				SELECT	@isExistFTFCorner = 1 
			END

			IF EXISTS(
				SELECT	TOP 1 1
				FROM	Bettrans WITH (NOLOCK) 
				WHERE	MatchID = @matchid
						AND bettype = 208
						AND statusID NOT IN (101, 102,103)
			) 
			OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype = 208
						AND statusID NOT IN (101, 102,103)
			)
			BEGIN
				SELECT	@isExistFTLCorner = 1 
			END

			IF EXISTS(
				SELECT	TOP 1 1
				FROM	Bettrans WITH (NOLOCK) 
				WHERE	MatchID = @matchid
						AND bettype = 207
						AND statusID NOT IN (101, 102,103)
			) 
			OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype = 207
						AND statusID NOT IN (101, 102,103)
			)
			BEGIN
				SELECT	@isExistHTFCorner = 1 
			END

			IF EXISTS(
				SELECT	TOP 1 1
				FROM	Bettrans WITH (NOLOCK) 
				WHERE	MatchID = @matchid
						AND bettype = 209
						AND statusID NOT IN (101, 102,103)
			) 
			OR EXISTS(
				SELECT	TOP 1 1
				FROM	Bettransm WITH (NOLOCK)
				WHERE	MatchID = @matchid
						AND bettype = 209
						AND statusID NOT IN (101, 102,103)
			)
			BEGIN
				SELECT	@isExistHTLCorner = 1 
			END
		END

		/**END: Check existing Corner bettypes or not **/
	END

	IF (
			EXISTS (
				--HT Soccer
				SELECT	TOP 1 1
				FROM	DBPRO.BODB02.dbo.match m WITH (NOLOCK)
						INNER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
				WHERE	m.matchid = @matchid 
						AND sporttype = 1 
						AND datediff(minute, kickofftime, CURRENT_TIMESTAMP) < 100 
						AND (datediff(minute, kickofftime, CURRENT_TIMESTAMP) > 45 OR isnull(ConfirmHT, 0) > 0) 
						AND isnull(ConfirmFT, 0) = 0
				)
			)
	BEGIN
		SELECT @IsHTOnly = 1
		
	END

	IF (
			EXISTS (
				SELECT 1
				FROM bettrans WITH (NOLOCK)
				WHERE 
						( bettype IN (4, 6, 13, 26, 27, 30, 126)  
							OR bettype BETWEEN 128 AND 134
							OR bettype BETWEEN 140 AND 150 
							OR bettype = 152
							OR bettype IN (159,161,162,163,170,172,179,181,182,187,188,195,196,199,200,201,202,206,207) 
						)
						AND matchid = @matchid AND statusID NOT IN (101, 102, 103) 
						AND ruben = 0 
						AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770, 15523642) AND recommend <> 1688156)
				) AND @sporttype = 1
			)
	BEGIN
		SELECT @IsSettleAbandonedMatchIBC = 1
	END

	IF EXISTS (
			SELECT TOP 1 1
			FROM bettrans(NOLOCK)
			WHERE matchid = @matchid AND liveindicator = 1
			)
		SELECT @IsLive = 1

	SELECT match.sporttype
		,match.betstatus
		,hthomescore AS HalfTimeHomeScore
		,htawayscore AS HalfTimeAwayScore
		,datediff(minute, kickofftime, CURRENT_TIMESTAMP) playtime
		,match.leagueid
		,match.matchid
		,match.homeid
		,match.awayid
		,match.matchcode
		,match.kickofftime
		,match.finalhomescore
		,match.finalawayscore
		,match.eventstatus
		,isnull(mr.refund, 0) IsRefund
		,isnull(mr.calrefund, 0) IsCalRefund
		,isnull(mr.calculate, 0) IsCalculated
		,isnull(mr.multiple, 0) IsMultiCaled
		,isnull(match.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
		,mr.ishtcal AS IsHalfTimeCal
		,ISNULL(mr.SettlementStatus135,0) SettlementStatus135
		,match.GoalRecord
		,mr.ConfirmHT
		,mr.ConfirmFT
		,@HTStatus HTStatus
		,@FTStatus FTStatus
		,@FGLGStatus fglgstatus
		,@HTFGLGStatus HTFGLGStatus
		--,@PSStatus PSStatus
		,@IsExistFGLG AS IsExistFGLG
		,@IsExistLG AS IsExistLG
		,@IsExistHTFGLG AS IsExistHTFGLG
		,@IsExistHTLG AS IsExistHTLG
		,@IsExistPS as IsExistPS
		,@IsHTOnly AS IsHTOnly
		,@IsLive AS IsLive
		,@IsSettleAbandonedMatchIBC IsSettleAbandonedMatchIBC
		,@TennisStatusSet1	AS TennisStatusSet1
		,@TennisStatusSet2	AS TennisStatusSet2
		,@TennisStatusSet3	AS TennisStatusSet3
		,@TennisStatusSet4	AS TennisStatusSet4
		,@TennisStatusSet5	AS TennisStatusSet5
		,@TennisStatusMatch	AS TennisStatusMatch
		,@isExistTotalCorner	AS isExistTotalCorner
		,@isExistHTFCorner		AS isExistHTFCorner
		,@isExistHTLCorner		AS isExistHTLCorner
		,@isExistFTFCorner		AS isExistFTFCorner	
		,@isExistFTLCorner		AS isExistFTLCorner
		,@isExistResultandFirstTeamScore AS isExistResultandFirstTeamScore
 	FROM DBPRO.BODB02.dbo.match WITH (NOLOCK)
		LEFT OUTER JOIN DBPRO.BODB02.dbo.match_remark mr WITH (NOLOCK) ON match.matchid = mr.matchid
	WHERE match.matchid = @matchid

	-- GET TENNIS RESULT 
	SELECT	MatchId
			, ResourceId
			, HomeValue
			, AwayValue
			, ResultStatusID
			, SettlementStatusID
	FROM	DBPRO.BODB02.dbo.[ResultDetail] WITH (NOLOCK) 
	WHERE	MatchID = @MatchID 
			AND (@Sporttype = 5 
					OR(	@Sporttype = 1 
						AND ResourceID IN ('04','05','206','207','208','209') -- Corners Bettype
					)
			)


END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchSelDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchSelDetail] TO [vnteam] AS [dbo]

