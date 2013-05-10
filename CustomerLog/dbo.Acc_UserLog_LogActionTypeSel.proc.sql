ALTER PROCEDURE [dbo].[Acc_UserLog_LogActionTypeSel]    
AS 
/* 
	Created:20100304@Henry
    Task: Get all data of table LogActionType
    DB: bodb_CustomerLog

	Description:
		- 20121212@Elodie: Get more field ActionTypeNameVI
		
    Param's Explaination:    
	
*/
SET NOCOUNT ON
SELECT 
	ActionTypeID,
	ActionTypeNameEN,
	ActionTypeNameCH,
	ActionTypeNameCS,
	ActionTypeNameJP,
	ActionTypeNameIT,
	ActionTypeNameTH,
	ActionTypeNameKO,
	ActionTypeNameVI
FROM LogActionType WITH (NOLOCK)

GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_LogActionTypeSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_LogActionTypeSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_LogActionTypeSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_LogActionTypeSel] TO [vnteam]