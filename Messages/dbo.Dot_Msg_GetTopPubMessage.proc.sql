USE [bodb_Message]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_GetTopPubMessage]
	@messageType int,
	@site1 varchar(10),
	@site2 varchar(10) = '',
	@site3 varchar(10) = '',
	@site4 varchar(10) = '',
	@site5 varchar(10) = '',
	@LatestMsgID int = 0,  -- Check new msg count that newer than this messageid
	@isTest bit
AS
BEGIN
    /*
    Created: @TWTeam
    Task: 
    DB: DB07
    Original:
    Revisions:

    Param's Explanation:
    */
	SET NOCOUNT ON;
	DECLARE @site6 CHAR(4)
	DECLARE @site7 CHAR(4)
	DECLARE @site8 CHAR(4)
	SET @site6=''
	SET @site7=''
	SET @site8=''
	IF @LatestMsgID=0 SET @LatestMsgID=52000

	IF @site1<>'' SET @site1=dbo.FixSiteID(@site1)
	IF @site2<>'' SET @site2=dbo.FixSiteID(@site2)
	IF @site3<>'' SET @site3=dbo.FixSiteID(@site3)
	IF @site4<>'' SET @site4=dbo.FixSiteID(@site4)
	IF @site5<>'' SET @site5=dbo.FixSiteID(@site5)

	IF @site1<>'' SET @site6=dbo.FixSiteID2(@site1)
	IF @site2<>'' SET @site7=dbo.FixSiteID2(@site2)
	IF @site3<>'' SET @site8=dbo.FixSiteID2(@site3)

	IF @isTest = 0
	BEGIN
		-- Select Public Message(not include test message)
		SELECT TOP 1 m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					 m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					 m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
					 m.Content_mx,
					 m.PostTime, m.CreateTime, m.LastUpdateTime,
					 m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
					 m.Creator, m.LastUpdator, 
					 m.CreatorName, m.LastUpdateName,
					 mt.TargetName as UserName, mt.BettransID, mt.TargetId
		FROM dbo.Msg m with (nolock)
		INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
		WHERE m.MsgType = @messageType
			AND mt.TargetID IN (@site1,@site2,@site3,@site4,@site5,@site6,@site7,@site8)
			AND m.MessageId > @LatestMsgID
			AND m.IsTest = 0
		ORDER BY m.PostTime Desc
	END
	ELSE
	BEGIN
		-- Select Public Message(include test message)
		SELECT TOP 1 m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					 m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					 m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
					 m.Content_mx,
					 m.PostTime, m.CreateTime, m.LastUpdateTime,
					 m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
					 m.Creator, m.LastUpdator, 
					 m.CreatorName, m.LastUpdateName,
					 mt.TargetName as UserName, mt.BettransID, mt.TargetId

		FROM dbo.Msg m with (nolock)
		INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
		WHERE m.MsgType = @messageType
			AND mt.TargetID IN (@site1,@site2,@site3,@site4,@site5,@site6,@site7,@site8)
			AND m.MessageId > @LatestMsgID
		ORDER BY m.PostTime Desc
	END
END


GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTopPubMessage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTopPubMessage] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetTopPubMessage] TO vnteam