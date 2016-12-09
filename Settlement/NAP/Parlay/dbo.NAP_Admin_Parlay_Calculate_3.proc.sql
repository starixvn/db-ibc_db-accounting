ALTER PROCEDURE [dbo].[NAP_Admin_Parlay_Calculate_3]
	@matchid 		INT
	,@matchdate		SMALLDATETIME
    ,@action		VARCHAR(10)
	,@strTransIds 	VARCHAR(MAX) = NULL
AS
/*    
	Creator: 20161205@Bobby
    Task: #61352 - Apply settle determined for parlay bet types
    DB: DBTXN.bodb02
	Original:

    Revisions:        
    Param's Explanation:
        
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @xmlParlayTicket 	XML
		
	CREATE TABLE #parlayTicket (transid BIGINT PRIMARY KEY, statusId TINYINT)		
	CREATE TABLE #parlayOutput (transid BIGINT PRIMARY KEY, refno BIGINT, statusID TINYINT, statuswinlost TINYINT)		
	
	SET @xmlParlayTicket = CONVERT(XML, @strTransIds)
	
	INSERT INTO #parlayTicket (transid, statusId)
	SELECT T.C.value('./@t', 'BIGINT') 		AS transid
			,T.C.value('./@s', 'TINYINT') 	AS statusId
	FROM @xmlParlayTicket.nodes('/b') AS T(C)
	OPTION (OPTIMIZE FOR (@xmlParlayTicket = NULL ))
	
	IF(@@ROWCOUNT = 0) RETURN
	
	--CALCULATE PROCESS
	IF (@action IN ('ABANDONED', 'REFUND'))
	BEGIN
		--UPDATE bettransm
		UPDATE bm
		SET winlostdate 	= @matchdate
			,[status] 		= CASE 
				WHEN t.statusID = 113 THEN N'LOSE'
				WHEN t.statusID = 112 THEN N'WON'
				WHEN t.statusID = 103 THEN N'Refund'
				ELSE bm.[status]
			END
			,statuswinlost = CASE 
				WHEN t.statusID = 113 THEN 4 -- LOSE
				WHEN t.statusID = 112 THEN 2 -- WON
				WHEN t.statusID = 103 THEN 0 -- REFUND
				ELSE bm.statuswinlost
				END
			,ruben 		= 1
			,statusID 	= t.statusID
		OUTPUT INSERTED.transid
				,INSERTED.refno
				,INSERTED.statusID
				,INSERTED.statuswinlost
		INTO #parlayOutput(transid, refno, statusID, statuswinlost)
		FROM dbo.bettransm bm WITH(ROWLOCK, UPDLOCK)
			INNER JOIN #parlayTicket t
			ON bm.transid = t.transid
		
		--UPDATE BetParlayDetail
		UPDATE pd 
		SET winlostdate 	= @matchdate
			,statusid 		= r.statusId
			,statuswinlost 	= r.statuswinlost
		FROM dbo.BetParlayDetail pd WITH(ROWLOCK, UPDLOCK)
			INNER JOIN #parlayOutput r
			ON pd.transid 	= r.transid
			AND pd.RefNo 	= r.refno
	END
	
	--UNDO Process
	IF(@action = 'UNDO')
	BEGIN
		--UNDO bettransm
		UPDATE bm
		SET winlostdate 	= @matchdate
			,[status] 		= 'running'
			,statuswinlost 	= 0
			,ruben 			= 0
			,statusID 		= 0
		OUTPUT INSERTED.transid, INSERTED.refno 
		INTO #parlayOutput(transid, refno)
		FROM dbo.bettransm bm WITH(ROWLOCK, UPDLOCK)
			INNER JOIN #parlayTicket t
			ON bm.transid = t.transid
		
		--UNDO BetParlayDetail
		UPDATE pd
		SET winlostdate 	= @matchdate
			,statuswinlost 	= 0
			,statusID 		= 0
		FROM dbo.BetParlayDetail pd WITH(ROWLOCK, UPDLOCK)
			INNER JOIN #parlayOutput r
				ON pd.transid 	= r.transid
				AND pd.RefNo 	= r.refno
	END
	
	DROP TABLE #parlayTicket;
	DROP TABLE #parlayOutput
	RETURN;
	
END
