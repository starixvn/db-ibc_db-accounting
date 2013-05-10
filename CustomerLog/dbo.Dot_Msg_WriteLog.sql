ALTER PROCEDURE [dbo].[Dot_Msg_WriteLog]
           @Site tinyint,
           @OpratorID int,
           @MessageId int,
           @LogContent varchar(300),
           @ActionType char(1),
           @Method varchar(20)
/*
Created: @TWTeam
DB: bodb_message

Param's Explanation:
 @Site : 0:Admin Site ,1:Agent Site
 @OpratorID : UserID of Each Site
 @LogContent : Log Content 
 @ActionType : 'N':New ,'E':Edie ,'D':Delete
 @Method : Execute Method Or Function Name Or ASPX PageName
*/

AS
SET NOCOUNT ON
BEGIN
INSERT INTO dbo.MsgLog
   (Site
   ,OpratorID
   ,MessageId
   ,LogContent
   ,ActionType
   ,Method)
 VALUES
   (@Site,
   @OpratorID,
   @MessageId,
   @LogContent,
   @ActionType,
   @Method)
END

GO
GRANT EXECUTE ON [dbo].[Dot_Msg_WriteLog] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_WriteLog] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_WriteLog] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_WriteLog] TO [Dot_Admin]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_WriteLog] TO [vnteam]