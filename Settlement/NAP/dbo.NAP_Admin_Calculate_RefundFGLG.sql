/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_RefundFGLG]    Script Date: 08/27/2014 14:03:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_RefundFGLG] @matchid INT
	,@action varchar(10) = 'REFUND'
	,@LGOnly BIT
	,@matchdate DATETIME
AS
/*	Created by: Kathy
	Date: 20140213
	Task: Refund FGLG 
	DB: DBTXN.BODB02

	Revisions: 
		- 20140426@Kathy: Add 1H FGLG (127) [Redmine:#14449]
		- 20140610@Kathy: Using clustered index(CIX_recommend_matchid_bettype) in DB052, DB053, DB054		
		- 20160905@Bobby: Remove LAS stattement
				
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @bettype int

	select @bettype = CASE WHEN @action = 'REFUND-HT' then 127
						   when @action = 'REFUND-FT' then 14
						   ELSE 0
					  end 
	
	IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054','DB231')
	BEGIN
		DECLARE @affectedagents INT
	
		CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)

		INSERT INTO #tmpRecommend(recommend)
		SELECT DISTINCT recommend
		FROM dbo.bettrans (NOLOCK) 
		WHERE matchid = @matchid 
		AND ((@bettype = 0 AND bettype IN (14,127)) 
					OR (bettype = @bettype))

		DECLARE @currecommend TABLE(recommend INT PRIMARY KEY)

		WHILE 1=1
		BEGIN
			DELETE
			FROM @currecommend

			DELETE TOP(100)
			FROM #tmpRecommend OUTPUT DELETED.recommend INTO @currecommend

			SET @affectedagents = @@rowcount

			UPDATE b WITH (ROWLOCK, UPDLOCK)
			SET STATUS = 'Refund'
				,statusID = 103
				,winlost = actual_stake
				,awinlost = 0
				,mwinlost = 0
				,swinlost = 0
				,playercomm = 0
				,comm = 0
				,acomm = 0
				,scomm = 0
				,ruben = 1
			FROM dbo.bettrans b with(ROWLOCK, UPDLOCK) 
			INNER JOIN @currecommend ag ON b.recommend = ag.recommend
			WHERE matchid = @matchid
			AND statusID NOT IN (103, 101, 102) 
			AND ((@bettype = 0 AND bettype IN (14,127)) 
					OR (bettype = @bettype))
			AND right(betteam, 1) = CASE WHEN @LGOnly = 1 THEN '2' ELSE right(betteam, 1) END

			IF @affectedagents <> 100
				BREAK
		END

		DROP TABLE #tmpRecommend
	END
	ELSE
	BEGIN
		WHILE 1 = 1
		BEGIN
			UPDATE TOP (10000) dbo.bettrans WITH (ROWLOCK, UPDLOCK)
			SET STATUS = 'Refund'
				,statusID = 103
				,winlost = actual_stake
				,awinlost = 0
				,mwinlost = 0
				,swinlost = 0
				,playercomm = 0
				,comm = 0
				,acomm = 0
				,scomm = 0
				,ruben = 1
			WHERE matchid = @matchid
				--AND [status] not in ('Void', 'Reject')
				AND statusID NOT IN (103, 101, 102) 
				AND ((@bettype = 0 AND bettype IN (14,127)) 
						OR (bettype = @bettype))
				--AND ruben = 1 
				AND right(betteam, 1) = CASE 
					WHEN @LGOnly = 1 THEN '2'
					ELSE right(betteam, 1)
					END

			IF @@ROWCOUNT < 10000
				BREAK
		END
	END

	-------------Start: Refund FGLG for bettransm-------------
	--WHILE 1=1
	BEGIN
		--UPDATE TOP (10000) dbo.bettransm with (ROWLOCK, UPDLOCK)
		UPDATE dbo.bettransm WITH (ROWLOCK, UPDLOCK)
		SET winlostdate = @matchdate
			,[status] = 'Refund'
			,statusID = 103
			,statuswinlost = 0
			,ruben = 1
		WHERE ((@bettype = 0 and bettype in (14, 127)) OR (bettype = @bettype))
		AND matchid = @matchid 
		AND statusID NOT IN (103, 101, 102) AND right(betteam, 1) = CASE 
				WHEN @LGOnly = 1 THEN '2'
				ELSE right(betteam, 1)
				END

		--	IF @@ROWCOUNT < 10000 BREAK
		UPDATE dbo.betParlayDetail WITH (ROWLOCK, UPDLOCK)
		SET winlostdate = @matchdate
			,statusID = 103
			,statuswinlost = 0
		WHERE ((@bettype = 0 and bettype IN (14, 127)) OR (bettype = @bettype)) 
		AND matchid = @matchid AND statusID NOT IN (103, 101, 102) AND right(betteam, 1) = CASE 
				WHEN @LGOnly = 1 THEN '2'
				ELSE right(betteam, 1)
				END
	END
		-------------End: Refund FGLG for bettransm-------------
END


GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Calculate_RefundFGLG] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_RefundFGLG] TO [vnteam] AS [dbo]