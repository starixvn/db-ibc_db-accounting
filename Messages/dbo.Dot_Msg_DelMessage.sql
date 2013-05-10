ALTER PROCEDURE [dbo].[Dot_Msg_DelMessage]
	@MessageId int
AS
/*
	Created: @TWTeam
	Task: Delete message target and message content
	DB: DB07 

	Revisions: 
*/
BEGIN
	SET NOCOUNT ON
	DELETE dbo.MsgTarget WHERE MessageID = @MessageId;
	DELETE dbo.Msg WHERE MessageID = @MessageId;
END
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetMessage] TO [Dot_Admin]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetMessage] TO [vnteam]