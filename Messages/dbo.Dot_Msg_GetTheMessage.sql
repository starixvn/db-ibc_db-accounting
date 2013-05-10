USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetTheMessage]    Script Date: 10/13/2009 00:36:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_GetTheMessage]
	@MessageID int = 0
AS
BEGIN
	SET NOCOUNT ON
	SELECT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
		   m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
		   m.Content_es, m.PostTime, m.IsSticky, m.IsTest, m.MatchId, 
		   m.Creator, m.CreateTime, mt.TargetId, mt.BettransID,
		   0 as BatchId,'' as BContent_en,'' as BContent_cs,'' as BContent_ch, --will remove when dll update
		   '' as BContent_jp,'' as BContent_th,'' as BContent_it,'' as BContent_ko, '' as BContent_es, --will remove when dll update
		   m.CreatorName, mt.TargetName as UserName
	FROM dbo.Msg m with (nolock)
	INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
	WHERE m.MessageId = @MessageID
END
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTheMessage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTheMessage] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetTheMessage] TO [vnteam]