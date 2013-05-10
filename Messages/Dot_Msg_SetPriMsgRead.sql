ALTER PROCEDURE [dbo].[Dot_Msg_SetPriMsgRead]
	@UserId int,
	@UserName nvarchar(20)
AS
BEGIN
SET NOCOUNT ON
	Update dbo.MsgTarget
	SET IsRead = 1
	WHERE IsRead = 0
		AND TargetId = @UserId
		AND TargetName = @UserName
END

GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_SetPriMsgRead] TO [vnteam]