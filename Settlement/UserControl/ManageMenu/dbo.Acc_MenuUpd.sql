 ALTER PROCEDURE [dbo].[Acc_MenuUpd] 
    @MenuId            INT,
    @Menu           VARCHAR(50),
    @ParentId       INT,
    @FuncName   VARCHAR(50),
    @Url            VARCHAR(100),
    @Target         VARCHAR(50),
    @IsHide         BIT,
    @ORDER          INT,
    @LEVEL            INT,
    @ErrCode        INT OUTPUT,
    @ErrMsg            VARCHAR(200) OUTPUT
               
AS
/*
Created by: Robert
Task : update menu
DB: DB03.bodb02


Revisions:
Param's Explanation:
*/

SET NOCOUNT ON

BEGIN
    IF not exists (SELECT 1 FROM Acc_Menu (nolock) WHERE MenuId = @MenuId)
    BEGIN
        SELECT @ErrCode = 100, @ErrMsg = 'Invalid MenuId'
        RETURN
    END

    IF not exists(SELECT 1 FROM acc_functioninfo WHERE FuncName=@FuncName)
    BEGIN
        SELECT @ErrCode = 101, @ErrMsg = 'Invalid FuncName'
        RETURN
    END

    UPDATE Acc_Menu SET
        Menu = @Menu,
        ParentId = @ParentId,
        FuncName = @FuncName,
        Url = @Url,
        Target = @Target,
        IsHide = @IsHide,
        [ORDER] = @ORDER,
        [LEVEL] = @LEVEL
    WHERE MenuId = @MenuId
END

GO
GRANT EXECUTE ON [dbo].[Acc_MenuUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuUpd] TO [vnteam]
 

