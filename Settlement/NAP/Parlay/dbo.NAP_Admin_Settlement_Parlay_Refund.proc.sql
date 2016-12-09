ALTER PROCEDURE [dbo].[NAP_Admin_Settlement_Parlay_Refund] (
	@MatchId 			INT
	, @matchdate		SMALLDATETIME
	, @Mode 			VARCHAR(20)
	, @IsDetermined		BIT = 0
	, @ResultBetRadar	VARCHAR(MAX) = NULL
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

	/*IF (@ResultBetRadar IS NOT NULL) -- for betradar
	BEGIN
		DECLARE @xmlBetRadar 		XML
			, @ResourceIDsREFUND 	VARCHAR(MAX)
		
		SET @xmlBetRadar = CONVERT(XML, @ResultBetRadar)
		
		SELECT TOP(1)
			@ResourceIDsREFUND = ISNULL(T.C.value('./@ResourceIDsREFUND[1]', 'varchar(MAX)'), '')                
		FROM @xml.nodes('/root/r') as [T](C) --T: table, C: column
		OPTION ( OPTIMIZE FOR ( @xml = NULL ) )
		
		;WITH CTE_autoBettypes AS (
			SELECT f.BetType
			FROM dbo.f_Set_GetGroupBettypes() f
			WHERE f.groupId = 8
		)
		INSERT INTO #tempRefundTickets (transid, statusId)
		SELECT bm.transid, bm.bettype, bm.statusId
		FROM (
			SELECT bm.transid, bm.bettype, bm.statusId
			FROM dbo.bettransm bm WITH(NOLOCK)		
			WHERE matchid = @matchid
				AND statusID NOT IN (101, 102) 
				AND bettype IN (SELECT bettype FROM CTE_autoBettypes)
				AND 1 = CASE 
						WHEN @ResourceIDsREFUND IS NOT NULL 
                            AND Bettype IN (160,164,169,180) 
                            AND CHARINDEX(SUBSTRING(CAST(Betcheck AS VARCHAR(20)),2,5),@ResourceIDsREFUND)>0 THEN 1 
						WHEN @ResourceIDsREFUND IS NOT NULL 
                                AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDsREFUND)>0 THEN 1 
						ELSE 0 
					END --Betradar 2 Auto Bettype
		) AS bm 
		WHERE 
		
	END*/

	;WITH CTE_RefundBettypes 
	AS 
	(
		SELECT f.BetType
		FROM dbo.f_Set_GetGroupBettypes() f
		WHERE 1 = CASE 
					WHEN @Mode IN ('REFUND-FT') AND f.GroupId IN (2,4,6)  THEN 1 -- FT, FT corner, HTFT-FGLG
					WHEN @Mode IN ('REFUND') THEN 1 --ALL
					ELSE 0 
				END
	),
	CTE_DeterminedBettypes
	AS
	(
		SELECT f.BetType
		FROM dbo.f_Set_GetGroupBettypes() f
		WHERE 1 =  CASE WHEN @IsDetermined = 1 AND f.IsDetermined = @IsDetermined THEN 1 ELSE 0 END
				AND 1 = CASE 
							WHEN @Mode = 'REFUND-FT' AND f.GroupId IN (2,4,6)  THEN 1 -- FT, FT corner, HTFT-FGLG
							WHEN @Mode = 'REFUND' THEN 1
							ELSE 0
						END
				AND f.GroupId <> 8 -- auto betradar
	)
	INSERT INTO #tempRefundTickets (transid, statusId)
	SELECT transid
		, 103 AS statusId
	FROM
	(
		SELECT bm.transid, bm.bettype, bm.statusId
		FROM dbo.bettransm bm WITH(NOLOCK)		
		WHERE matchid = @matchid
			AND statusID NOT IN (101, 102)
			AND transid NOT IN (SELECT transid FROM #tempRefundTickets)
			AND bm.bettype IN (SELECT bettype FROM CTE_RefundBettypes)
	) AS b
	WHERE @IsDetermined 	= 0 --ALL bettypes
		OR (
			@IsDetermined 	= 1 
			AND (
				b.bettype NOT IN (SELECT bettype FROM CTE_DeterminedBettypes) -- not supported determined bettypes
				OR (
					b.bettype IN (SELECT bettype FROM CTE_DeterminedBettypes) 
					AND statusID NOT IN (112,113)
				) --determined bettypes without calculating SDT
			)
		)
	
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
			,@mode 			= @mode
			,@action 		= 'REFUND'
			,@strTransIds	= @strRefundTicket
			
		IF(@batchCount < @batchNo) BREAK
	END
	
	DROP TABLE #tempRefundTickets
	RETURN
END
GO

			