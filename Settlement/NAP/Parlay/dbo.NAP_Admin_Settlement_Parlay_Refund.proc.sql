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

	DECLARE @tempRefundBatch TABLE (transid BIGINT, statusId TINYINT)
	CREATE TABLE #tempRefundTickets (transid BIGINT PRIMARY KEY, statusId TINYINT)

	;WITH CTE_RefundBettypes 
	AS 
	(
		SELECT f.BetType
		FROM dbo.f_Set_GetGroupBettypes() f
		WHERE f.GroupId <> 8 -- auto betradar
			AND 1 = CASE 
					WHEN @Mode = 'REFUND' THEN 1
					WHEN @Mode = 'REFUND-HT' THEN
						CASE 
							WHEN GroupId IN (1,3,5) THEN 1
							WHEN GroupId = 2 AND f.Is3x30 = 1 AND @IsRefundHT = 1 THEN 1
							ELSE 0
						END
					WHEN @Mode = 'REFUND-FT' THEN 
						CASE 
							WHEN GroupId IN (2,4,6) THEN 1
							ELSE 0
						END
					ELSE 0 
				END
			
	)
	INSERT INTO #tempRefundTickets (transid, statusId)
	SELECT transid
		, 103 AS statusId
	FROM
	(
		SELECT bm.transid
		FROM dbo.bettransm bm WITH(ROWLOCK)		
		WHERE matchid = @matchid
			AND statusID NOT IN (101, 102)
			AND bm.bettype IN (SELECT bettype FROM CTE_RefundBettypes)
	) AS b
	
	DECLARE @batchNo		INT
		,@batchCount		INT
		,@strRefundTicket	VARCHAR(MAX)
	
	SELECT @batchNo			= 1000
		, @batchCount		= 0
		, @ticketCount		= 0
		
	--DO settle SDT parlay tickets
	WHILE (1 = 1)
	BEGIN
		
		DELETE @tempRefundBatch
		
		DELETE TOP(@batchNo) t
		OUTPUT DELETED.transid, DELETED.statusId INTO @tempRefundBatch(transid, statusId)
		FROM #tempRefundTickets t
		
		SELECT @batchCount 		= @@ROWCOUNT
			, @ticketCount 		+= @batchCount
			, @strRefundTicket	= CAST((SELECT b.transid AS t
											,b.statusId AS s
										FROM @tempRefundBatch b
										FOR XML AUTO) AS VARCHAR(MAX)
								)
		
		/*select @matchid
			,@matchdate
			,@mode AS mode
			,'REFUND' AS [action] 		
			,@strRefundTicket AS strTransIds*/
		
		EXEC dbo.NAP_Admin_Calculate_MP_broker 
			@matchid 		= @matchid
			,@matchdate		= @matchdate
			,@mode 			= 'REFUND'
			,@action 		= 'REFUND'
			,@strTransIds	= @strRefundTicket
			
		IF(@batchCount < @batchNo) BREAK
	END
	
	DROP TABLE #tempRefundTickets
	RETURN
END
GO

			