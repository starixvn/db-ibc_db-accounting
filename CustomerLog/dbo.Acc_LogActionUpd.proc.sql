ALTER PROCEDURE [dbo].[Acc_LogActionUpd]    
   @ActionID INT ,
   @ActionTypeID INT = 0,
   @SPName varchar(50),
   @ActionNameEN nvarchar(256),
   @ActionNameCH nvarchar(256),
   @ActionNameCS nvarchar(256),
   @ActionNameJP nvarchar(256),
   @ActionNameIT nvarchar(256),
   @ActionNameTH nvarchar(256),
   @ActionNameKO nvarchar(256),
   @IsInternal tinyint
AS 
/* Created:20100325@Henry
    Task: 
    DB: bodb_CustomerLog

	Description:
	- Update table LogAction
	
    Param's Explaination:    
	
*/
SET NOCOUNT ON 

UPDATE LogAction with (UPDLOCK,ROWLOCK)
SET 
	SPName = @SPName,
	ActionNameEN = @ActionNameEN,
	ActionNameCH = @ActionNameCH,
	ActionNameCS = @ActionNameCS,
	ActionNameJP = @ActionNameJP,
	ActionNameIT = @ActionNameIT,
	ActionNameTH = @ActionNameTH,
	ActionNameKO = @ActionNameKO,
	ActionTypeID = case @ActionTypeID when 0 then null else @ActionTypeID end,
	IsInternal = @IsInternal
WHERE ActionID = @ActionID

SELECT @@ROWCOUNT as [ROWCOUNT]

GO
GRANT EXECUTE ON [dbo].[Acc_LogActionUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_LogActionUpd] TO [vnteam]