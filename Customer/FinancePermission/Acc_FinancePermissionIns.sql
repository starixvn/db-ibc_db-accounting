/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC dbo.Acc_FinancePermissionIns
	 @UserId INT,
	 @GroupId SMALLINT,
	 @Username NVARCHAR(50),
	 @RoleId INT,
	 @IsView BIT = 0,
	 @Type SMALLINT = 0,
	 @LoginIP VARCHAR(20)='',
	 @ErrCode INT = 0 OUTPUT,
	 @ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
    Created by: 20200325@Malcolm
	Task: Insert Finance User/ Finance Code into FinancePermission table [Redmine : #128128]
	DB : DBCUST/CustDB

	Revisions:
		- 20200325@Malcolm: Insert Finance User/ Finance Code into FinancePermission table [Redmine : #128128]
	Param's Explanation:
		- @Type = 0 : Finance code
		        = 1 : Finance User	
*/
BEGIN
    BEGIN TRY
		INSERT INTO dbo.Acc_FinancePermission(GroupId, FinanceCode, RoleId, IsView)
	    VALUES (@GroupId, @Username, @RoleId, @IsView)
	END TRY
	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE();
	END CATCH
	
END
