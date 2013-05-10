ALTER PROCEDURE [dbo].[Acc_LogActionTypeUpd]    
   @ActionTypeID INT ,
   @ActionTypeNameEN nvarchar(50),
   @ActionTypeNameCH nvarchar(50),
   @ActionTypeNameCS nvarchar(50),
   @ActionTypeNameJP nvarchar(50),
   @ActionTypeNameIT nvarchar(50),
   @ActionTypeNameTH nvarchar(50),
   @ActionTypeNameKO nvarchar(50)

AS 
/* Created:20100325@Henry
    Task: 
    DB: bodb_CustomerLog

	Description:
	- Update table LogActionType
	
    Param's Explaination:    
	
*/
SET NOCOUNT ON 

UPDATE LogActionType with (UPDLOCK,ROWLOCK)
SET 
	ActionTypeNameEN = @ActionTypeNameEN,
	ActionTypeNameCH = @ActionTypeNameCH,
	ActionTypeNameCS = @ActionTypeNameCS,
	ActionTypeNameJP = @ActionTypeNameJP,
	ActionTypeNameIT = @ActionTypeNameIT,
	ActionTypeNameTH = @ActionTypeNameTH,
	ActionTypeNameKO = @ActionTypeNameKO

WHERE ActionTypeID = @ActionTypeID

SELECT @@ROWCOUNT as [ROWCOUNT]

GO
GRANT EXECUTE ON [dbo].[Acc_LogActionTypeUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_LogActionTypeUpd] TO [vnteam]