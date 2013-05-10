 
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

/****** Object:  Stored Procedure dbo.Acc_Msg_Remove    Script Date: 6/24/2011 4:48:50 PM ******/


ALTER PROCEDURE [dbo].[Acc_Msg_Remove]
    @transid varchar(50),
    @UserID INT =0 
AS
/*
Created: Robert
DB: DB07.bodb_Message
Revisions:   
	- 20110624@Lukas: fix bug: remove messageID when msgtargetID still exists (orphan msgTargetID)
	- 20120112@Lukas: Exclude messages with isDeleted = 1
	- 20120208@Jamie: Add log into MsgLog table 
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @msgTarget TABLE (	msgTargetID INT
								,msgID INT
								,BettransId VARCHAR(MAX)
								,IsDeleted BIT 
								)

	DECLARE @ListTransID VARCHAR(4000)

	INSERT INTO @msgTarget(msgTargetID,msgID,BettransId,IsDeleted) 
			SELECT	MsgTargetId
					,MessageID
					,BettransId
					,CASE WHEN CHARINDEX(',',BettransId) = 0 THEN 1 ELSE 0 END IsDeleted
			FROM MsgTarget WITH(NOLOCK)
			WHERE CHARINDEX(@transid, BettransId) > 0
				AND isDeleted = 0

	--- Delete records that there is only one transid in [dbo].[msgTarget].[BettransID] column		
	UPDATE mt WITH(ROWLOCK,UPDLOCK)
	SET isDeleted = 1
	FROM msgTarget mt
	WHERE msgTargetId IN (SELECT msgTargetId FROM @msgTarget WHERE IsDeleted = 1)

	--- Exclude deleted transid in [dbo].[msgTarget].[BettransID] column 
	UPDATE @msgTarget
	SET BettransId = REPLACE(REPLACE(BettransId,', ' + @transid, ''), @transid + ', ','')
	WHERE IsDeleted = 0

	--- Update to msgTarget table
	UPDATE ms WITH(ROWLOCK,UPDLOCK)
	SET BettransId = t.BettransId
	FROM msgTarget ms 
		INNER JOIN @msgTarget t ON ms.msgTargetId = t.msgTargetId
	WHERE ms.isDeleted = 0
	
	IF NOT EXISTS ( SELECT 1 FROM msgTarget WHERE MessageID = (SELECT TOP 1 msgID FROM @msgTarget))
	BEGIN
		UPDATE  Msg WITH(ROWLOCK,UPDLOCK) 
		SET isDeleted = 1
		WHERE MessageId IN ( SELECT TOP 1 msgID FROM @msgTarget)
			AND isDeleted = 0
	END
	
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
				msgID,
				'Personal Message',
				'D',
				'Acc_Msg_Remove',
				GETDATE()	
	FROM	@msgTarget
		
		
END
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_Remove] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Msg_Remove] TO [vnteam]