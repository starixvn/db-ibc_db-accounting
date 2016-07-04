USE bodb_Message
go

/****** Object:  Stored Procedure dbo.Acc_Msg_Remove    Script Date: 6/24/2011 4:48:50 PM ******/
ALTER PROCEDURE [dbo].[NAP_RecoverBet_MessageDel]
   @transids 	VARCHAR(MAX),
    @UserID 	INT = 0 
AS
/*
Created: 20160609@Bobby.Nguyen	
DB: DBMSG.bodb_Message
Revisions:   
	- 20160609@Bobby.Nguyen: #59171 - Implement remove message function when recovering multiple tickets
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tempTransId (transid VARCHAR(20))
	CREATE TABLE #tempMsgTarget (MsgTargetId INT, MessageId INT)
	CREATE TABLE #updatedMsgTarget (MsgTargetId INT, BettransId VARCHAR(MAX))

	INSERT INTO #tempTransId(transid)
	SELECT DISTINCT val
	FROM dbo.strSplit(@transids, ',')
	WHERE LEN(val) > 0 AND val <> '0'
	
	--Gather MsgTargetId need to update
	INSERT INTO #tempMsgTarget (MsgTargetId, MessageId)
	SELECT DISTINCT MsgTargetId, MessageId
	FROM #tempTransId temp
		CROSS APPLY (
			SELECT MsgTargetId, msg.MessageId
			FROM dbo.MsgTarget msg WITH(NOLOCK)
			WHERE msg.isDeleted = 0
				AND CHARINDEX(temp.transid, msg.BettransId) > 0
	) AS t

	IF(@@ROWCOUNT = 0) RETURN

	;WITH CTE_UpdateMsgTarget AS (
		SELECT temp.MsgTargetId
			,msg.transid
		FROM #tempMsgTarget temp
			CROSS APPLY (
				SELECT tx.transid
				FROM dbo.MsgTarget msg WITH(NOLOCK)
					CROSS APPLY (
						SELECT val AS transid
						FROM dbo.strSplit(msg.BetTransId, ',') AS v
							LEFT JOIN #tempTransId f 
							ON v.val = f.transid
						WHERE val <> '0' AND f.transid IS NULL
							
					) tx 
				WHERE msg.MsgTargetId = temp.MsgTargetId
			) AS msg
	)
	--SELECT * FROM CTE_UpdateMsgTarget
	INSERT INTO #updatedMsgTarget (MsgTargetId, BetTransId)
	SELECT MsgTargetId
		,BetTransId = STUFF((
			SELECT ',' + transid FROM CTE_UpdateMsgTarget
			WHERE MsgTargetId = temp.MsgTargetId
			FOR XML PATH(''), TYPE).value('.[1]', 'VARCHAR(MAX)'), 1, 2, '')
	FROM #tempMsgTarget temp
	GROUP BY MsgTargetId
	
	--update back to msgTarget
	UPDATE mt WITH(ROWLOCK,UPDLOCK)
		SET isDeleted = CASE WHEN up.BetTransId IS NULL THEN 1 ELSE 0 END
			,BetTransId = up.BetTransId
	FROM dbo.msgTarget mt
		INNER JOIN #updatedMsgTarget up 
		ON mt.MsgTargetId = up.MsgTargetId			

	--update back to main message
	UPDATE msg WITH(ROWLOCK,UPDLOCK) 
	SET isDeleted = 1
	FROM dbo.Msg msg
	WHERE MessageId IN (
		SELECT MessageId 
		FROM dbo.MsgTarget ck WITH(NOLOCK) 
		WHERE MessageId IN (SELECT DISTINCT MessageId FROM #tempMsgTarget )
		GROUP BY MessageId
		HAVING SUM(CASE WHEN isDeleted = 0 THEN 1 ELSE 0 END) = 0
			
	)
	AND msg.isDeleted = 0
	
	-- Write Log 
	INSERT INTO [bodb_Message].[dbo].[MsgLog]
			   ([Site]
			   ,[OpratorID]
			   ,[MessageId]
			   ,[LogContent]
			   ,[ActionType]
			   ,[Method]
			   ,[LogDate])	
	SELECT	DISTINCT	
				2, -- Accounting Site
				@UserID,
				MessageId,
				'Personal Message',
				'D',
				'NAP_RecoverBet_MessageDel',
				GETDATE()	
	FROM #tempMsgTarget
		
	DROP TABLE #tempTransId
	DROP TABLE #tempMsgTarget
	DROP TABLE #updatedMsgTarget
	
	RETURN
END
GO
GRANT EXECUTE ON [dbo].[NAP_RecoverBet_MessageDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_RecoverBet_MessageDel] TO [vnteam]
GO