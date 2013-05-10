ALTER PROCEDURE [dbo].[Dot_Msg_GetTopPriMessage]
@targetid	int
AS
    /*
    Created: @TWTeam
    Task: 
    DB: DB07
    Original:
    Revisions:
        
    Param's Explanation:
    */
BEGIN
	-- Select Private Message
	SELECT TOP 1 m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
				 m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
				 m.Content_es, m.PostTime, m.CreateTime, m.LastUpdateTime,
				 m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsPublic,
				 m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, 
				 m.IsBatch, 
				 mt.BettransID, mt.TargetId, mt.TargetName as UserName
	FROM dbo.Msg m with (nolock)
	INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
	WHERE m.MsgType = 1
		AND m.PostTime > getdate()-1
		AND mt.TargetId = @targetid
	ORDER BY m.PostTime Desc
END


GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTopPriMessage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTopPriMessage] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetTopPriMessage] TO vnteam

