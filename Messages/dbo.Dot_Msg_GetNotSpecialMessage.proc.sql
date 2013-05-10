SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_GetNotSpecialMessage]
	@targetid int = 0,
	@targetid2 varchar(100) = '0',
	@special int = 2,
	@record int = 1,
	@sdate datetime = NULL,
	@edate datetime = NULL,
	@IsTest bit = 0,
	@MatchId int = 0
AS
BEGIN
    /*
    Created: @TWTeam
    Task: 
    DB: DB07
    Original:
    Revisions:
        20090923@Don : adapt for new design (Drop table BatchMsg)
        20091016@twTeam: put the default value for batchid and batch content while waiting updated DLL 
        
    Param's Explanation:
    
    */
    SET NOCOUNT ON;
    
	SELECT *
	FROM (
		SELECT DISTINCT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
						m.Content_jp, m.Content_th, m.Content_it, m.content_ko,
						m.Content_es, m.PostTime, m.CreateTime, m.LastUpdateTime,
						m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
						m.Creator, m.LastUpdator, mt.TargetId,
						 0 as BatchId, '' as BContent_en, '' as BContent_cs, '' as BContent_ch, --will remove when dll update
						'' as BContent_jp, '' as BContent_th, '' as BContent_it, '' as BContent_ko, '' as BContent_es, --will remove when dll update
						m.CreatorName, m.LastUpdateName, mt.TargetName as UserName, mt.BettransID,
					    DENSE_RANK() OVER(ORDER BY m.PostTime desc) as rownum
		FROM dbo.Msg m with (nolock)
		    INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
		WHERE m.IsSticky = 0
			AND (mt.TargetID = @targetid OR mt.TargetId IN (SELECT val FROM dbo.strSplit(@targetid2,',')))
			AND CASE				 
				  WHEN (@sdate IS NOT NULL AND @edate IS NOT NULL 
						AND m.PostTime BETWEEN @sdate AND @edate) THEN 1		 
				  WHEN (@sdate IS NULL AND @edate IS NULL) THEN 1
				  WHEN (@sdate IS NOT NULL AND @edate IS NULL AND m.PostTime >= @sdate) THEN 1
				  WHEN (@sdate IS NULL AND @edate IS NOT NULL AND m.PostTime <= @edate) THEN 1
				ELSE 0 END = 1
			AND CASE @IsTest 
					WHEN 1 THEN 1
					WHEN m.IsTest THEN 1
				END = 1
			AND case @MatchID
					when 0 then 1
					when m.MatchID then 1
				end = 1
	) new_table
	WHERE CASE
			WHEN (@record <> 0 AND new_table.rownum <= @record) THEN 1
			WHEN (@record = 0) THEN 1
		ELSE 0 END = 1

END
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetNotSpecialMessage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetNotSpecialMessage] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetNotSpecialMessage] TO vnteam
