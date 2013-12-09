ALTER PROCEDURE [dbo].[Acc_Set_PrivateMessageForRefund]
	@matchid int,	
	@action varchar(10), -- Refund / Refund-FT	
	@Content_en	nvarchar(4000) = NULL,
	@Content_ch	nvarchar(4000) = NULL,
	@Content_cs	nvarchar(4000) = NULL,
	@IP varchar(50) = NULL,
	@AdminID int
AS
/*
	Created by:[Viet]
	Date:[14 Jan 2011]
	Task: Set private message for refund number game
	DB: DBTXN/BODB02
	
	Revisions:
		- 20130121@Elodie: Change link server DB07 to DBMSG
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo by link database)
*/

SET NOCOUNT ON

/*
IF @action not in ('Refund', 'Refund-FT') RETURN
IF NOT EXISTS (SELECT 1 1 FROM match with(nolock) WHERE matchid = @matchid and sporttype = 161) RETURN
*/

CREATE TABLE #TempData(transid bigint, custid int, recommend int, mrecommend int, srecommend int)
INSERT INTO #TempData(transid, custid, recommend, mrecommend, srecommend)
SELECT transid, custid, recommend, mrecommend, srecommend
FROM Bettrans with(nolock)
WHERE matchid = @matchid
	and bettype between 81 and 87
	and statusID = 103

DECLARE @TempMember as table(custid int, username varchar(30), roleid tinyint)

INSERT INTO @TempMember(custid, roleid)
select DISTINCT custid, 1 FROM #TempData
UNION
SELECT DISTINCT recommend, 2 FROM #TempData
UNION
SELECT DISTINCT mrecommend, 3 FROM #TempData
UNION
SELECT DISTINCT srecommend, 4 FROM #TempData

UPDATE t
SET username = c.username
FROM @TempMember t
	inner join CustDB.dbo.Custinfo c with(nolock) on t.custid = c.custid

DECLARE @custID int, @MessageId int, @username varchar(30), @roleid tinyint, @transidList varchar(2000)

EXEC DBMSG.bodb_message.dbo.Dot_Msg_SetMessage2 
	@MessageId = @MessageId OUTPUT,
	@Content_en = @Content_en,
	@Content_ch = @Content_ch,
	@Content_cs = @Content_cs,
	@Content_jp = @Content_en,
	@Content_it = @Content_en,
	@Content_th = @Content_en,
	@Content_ko = @Content_en,
	@Content_es = @Content_en,
	@Content_vn = @Content_en,
	@Content_id = @Content_en,
	@MsgType = 1,
	@IsSticky = 0,
	@Creator = @AdminID,
	@CreatorName = '',
	@IsTest = 0,
	@MatchId = @MatchId,
	@IsBatch = 1

declare player_cursor cursor for
SELECT custid, username, roleid FROM @TempMember

OPEN player_cursor
FETCH NEXT FROM player_cursor into @custID, @username, @roleid

WHILE @@FETCH_STATUS = 0
BEGIN	
	SET @transidList = ''

	IF @roleID = 1
		SELECT @transidList = @transidList + CASE @transidList WHEN '' THEN '' ELSE ',' END + cast(transid as varchar(12))
		FROM #TempData 
		WHERE CustID = @custID
	ELSE IF @roleID = 2
		SELECT @transidList = @transidList + CASE @transidList WHEN '' THEN '' ELSE ',' END + cast(transid as varchar(12))
		FROM #TempData 
		WHERE Recommend = @custID
	ELSE IF @roleID = 3
		SELECT @transidList = @transidList + CASE @transidList WHEN '' THEN '' ELSE ',' END + cast(transid as varchar(12))
		FROM #TempData 
		WHERE MRecommend = @custID
	ELSE IF @roleID = 4
		SELECT @transidList = @transidList + CASE @transidList WHEN '' THEN '' ELSE ',' END + cast(transid as varchar(12))
		FROM #TempData 
		WHERE SRecommend = @custID

	EXEC DBMSG.bodb_message.dbo.Dot_Msg_SetUsrMessage
		@MessageId = @MessageId,
		@TargetId = @custID,
		@TargetName = @username,
		@isRead = 0,
		@BetTransId = @transidList

	FETCH NEXT FROM player_cursor into @custID, @username, @roleid
END
GO
GRANT EXECUTE ON [dbo].[Acc_Set_PrivateMessageForRefund] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_PrivateMessageForRefund] TO [vnteam] AS [dbo]