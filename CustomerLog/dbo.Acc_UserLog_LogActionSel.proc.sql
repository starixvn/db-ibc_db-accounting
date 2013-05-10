ALTER PROCEDURE [dbo].[Acc_UserLog_LogActionSel]    
AS 
/* Created:20100304@Henry
    Task: 
    DB: bodb_CustomerLog
	Description: Get all data of table LogAction			
    Param's Explaination:    
    Revisions:
		- 20130227@Elodie: Get log action with Vietname language
	
*/
SET NOCOUNT ON
SELECT 
	ActionID,
	ActionTypeID,
	SPName,
	ActionNameEN,
	ActionNameCH,
	ActionNameCS,
	ActionNameJP,
	ActionNameIT,
	ActionNameTH,
	ActionNameKO,
	ActionNameVI,
	IsInternal,
	XsltContent
FROM LogAction WITH (NOLOCK)

GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_LogActionSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_LogActionSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_LogActionSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_LogActionSel] TO [vnteam] AS [dbo]