ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Parlay_Refund] (
	@MatchId 			INT
	, @matchdate		SMALLDATETIME
	, @Mode				VARCHAR(20)
	, @IsRefundHT		BIT
	, @TicketCount		INT = 0 OUTPUT
	, @ErrCode 			INT = 0 OUTPUT
	, @ErrMsg 			NVARCHAR(200) = '' OUTPUT
)
AS
/*	Creator: 20161206@Bobby
	Task: #61352 - Apply settle determined for parlay bet types
	DB: DBTXN/BODB02
	ORIGINAL: 

	Revisions:		
		

	Param's Explanation:		
		- @Mode: ['REFUND', 'REFUND-HT','REFUND-FT']
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tempRefundBatch TABLE (transid BIGINT, refno BIGINT, statusId TINYINT)
	CREATE TABLE #refundBettypes (bettype SMALLINT)

	SELECT @ticketCount		= 0
	
	INSERT INTO #refundBettypes (bettype)
	SELECT f.BetType
	FROM dbo.f_Set_GetGroupBettypes() f
	WHERE 1 = CASE 
				WHEN @Mode = 'REFUND' THEN 1
				WHEN @Mode = 'REFUND-HT' THEN
					CASE 
						WHEN f.Is3x30 = 1 THEN 1
						ELSE 0
					END
				WHEN @Mode = 'REFUND-FT' THEN 
					CASE 
						WHEN GroupId IN (2,4,6) THEN 1
						ELSE 0
					END
				ELSE 0 
			END
		AND f.IsAuto = 0 --Exclude BetRadar, FM
	
	DECLARE @minTransId		BIGINT
		,@maxTransId		BIGINT
		,@fromTransId		BIGINT
		,@batchNo			INT
		,@batchCount		INT
		,@strTicket			VARCHAR(MAX)


	SELECT  @minTransId 	= MIN(transid)
		, @maxTransId 		= MAX(transid)
		, @ticketCount		= COUNT(1)
	FROM dbo.bettransm bm WITH(NOLOCK)
		INNER JOIN #refundBettypes t 
		ON bm.bettype		= t.bettype
	
	WHERE bm.matchId		= @matchId
		AND bm.statusID		NOT IN (101, 102)	

	SELECT @batchNo			= 10000
		, @batchCount		= 0
		, @fromTransId		= @minTransId
		
	
	--DO REFUND parlay tickets
	WHILE (1 = 1)
	BEGIN
		
		DELETE @tempRefundBatch
		
		INSERT INTO @tempRefundBatch (transid, refno, statusId)
		SELECT TOP(@batchNo)
			bm.transid
			,bm.refno
			,103 AS statusId
		FROM dbo.bettransm bm WITH(ROWLOCK)		
		WHERE matchid 		= @matchid
			AND bm.statusID NOT IN (101,102)
			AND bm.transid 	BETWEEN @fromTransId AND @maxTransId
			
		ORDER BY bm.transid
		
		SELECT @batchCount 		= @@ROWCOUNT
			, @strTicket		= CAST((SELECT b.transid AS t
											,b.refno AS r
											,b.statusId AS s
										FROM @tempRefundBatch b
										FOR XML AUTO) AS VARCHAR(MAX)
								)
		
		select @matchid
			,@matchdate
			,@mode AS mode
			,'REFUND' AS [action] 		
			,@strTicket AS strTransIds
		
		IF(@strTicket IS NOT NULL)
		BEGIN
		EXEC dbo.NAP_Admin_Calculate_MP_broker 
			@matchid 		= @matchid
			,@matchdate		= @matchdate
			,@mode 			= 'REFUND'
			,@action 		= 'REFUND'
			,@strTransIds	= @strTicket
		END
		
		SELECT @fromTransId = MAX(transid) + 1
		FROM @tempRefundBatch
		
		IF(@batchCount < @batchNo OR @fromTransId = @maxTransId) BREAK
			
	END
	
	DROP TABLE #refundBettypes
	RETURN
END
GO

			