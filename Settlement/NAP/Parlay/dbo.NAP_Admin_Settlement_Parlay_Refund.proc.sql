USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Settlement_Parlay_Refund]    Script Date: 1/6/2017 5:16:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

	DECLARE @tempRefundBatch TABLE (refno BIGINT, betcount INT)
	CREATE TABLE #refundBettypes (bettype SMALLINT PRIMARY KEY)
	
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
						WHEN @IsRefundHT = 1 THEN 1
						WHEN @IsRefundHT = 0 AND f.GroupId IN (2,4,6) THEN 1
						ELSE 0
					END
				WHEN @Mode = 'ABANDONED-2H' THEN 
					CASE 
						WHEN (@IsRefundHT = 1 AND (f.GroupId IN (1,3,5,7) OR f.Is3x30 = 1)) THEN 1
						ELSE 0
					END
				ELSE 0 
			END
		AND f.IsAuto = 0 --Exclude BetRadar, FM
	
	DECLARE @fromTransId	INT
		,@batchNo			INT
		,@batchCount		INT
		,@strTicket			VARCHAR(MAX)

	SELECT @batchNo			= 2000
		, @batchCount		= 0
		, @fromTransId		= 0
		, @ticketCount		= 0
	
	DECLARE @tempRefno TABLE (refno BIGINT)
	
	INSERT INTO @tempRefno (refno)
	SELECT bm.refno
	FROM dbo.bettransm bm WITH(NOLOCK)
		INNER JOIN #refundBettypes t ON bm.bettype = t.bettype

	WHERE bm.matchid 	= @matchid
		AND bm.statusID NOT IN (101,102)

	--GROUP BY bm.refno

	--DO REFUND parlay tickets
	WHILE (1 = 1)
	BEGIN
		
		DELETE @tempRefundBatch
		
		DELETE TOP(@batchNo) t
		OUTPUT deleted.refno INTO @tempRefundBatch(refno)
		FROM @tempRefno t	
		
		SELECT @batchCount	= @@ROWCOUNT
			,@ticketCount	+= @batchCount

		SELECT @strTicket = CAST(
		(
			SELECT *
			FROM (
				SELECT TOP(@batchNo)
					b.transid AS t
					,b.refno AS r
					,0 AS m
				FROM @tempRefundBatch ref
					INNER JOIN dbo.bettransm b WITH(NOLOCK) ON b.refno = ref.refno
				WHERE b.matchid 	= @matchid
			) AS b FOR XML AUTO
		) AS VARCHAR(MAX))
		
		IF(@strTicket IS NOT NULL)
		BEGIN
		EXEC dbo.NAP_Admin_Calculate_MP_broker 
			@matchid 		= @matchid
			,@matchdate		= @matchdate
			,@mode 			= 'REFUND'
			,@action 		= 'REFUND'
			,@strTransIds	= @strTicket
		END
		
		--BREAK;

		IF(@batchCount = 0 OR @strTicket IS NULL) BREAK
			
	END
	
	DROP TABLE #refundBettypes
	RETURN
END
