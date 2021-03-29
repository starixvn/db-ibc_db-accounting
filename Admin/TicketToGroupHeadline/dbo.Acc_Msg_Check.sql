/*<info serverAlias="DBMSG-bodb_Message" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_Msg_Check]
	@MessageId		INT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created by: 20210329@Malcolm
	Task: Check whether the messageId exists
	DB: DBMSG.bodb_Message
	Original:	
	
	Revisions:
		- 20210329@Malcolm : check whether the messageId exists [RedmineId : #147470]
	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	IF ISNULL(@MessageId, 0) = 0
	BEGIN
		SELECT @ErrCode = 110, @ErrMsg = 'Message ID is required!'
		RETURN
	END

	IF NOT EXISTS(SELECT 1 FROM dbo.Msg m WITH(NOLOCK) WHERE m.MessageId = @MessageId)
	BEGIN
		SELECT @ErrCode = 111, @ErrMsg = 'Message ID does not exist. Please check!'
		RETURN
	END
END
