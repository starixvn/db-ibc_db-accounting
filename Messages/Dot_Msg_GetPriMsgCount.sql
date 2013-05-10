ALTER PROCEDURE [dbo].[Dot_Msg_GetPriMsgCount]
	@UserId int,
	@UserName nvarchar(20)
AS
BEGIN
	SET NOCOUNT ON
	Select Count(*) As Count From dbo.MsgTarget with (nolock)
	Where IsRead =0 
	AND TargetId = @UserId
	AND TargetName = @UserName
END

GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetPriMsgCount] TO [vnteam]