/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC Acc_FinancePermissionDel
	 @UserId INT,
	 @GroupId SMALLINT,
	 @Username NVARCHAR(50),
	 @RoleId INT,
	 @Type SMALLINT = 0,
	 @IsView BIT = 0,
	 @LoginIP VARCHAR(20)='',
	 @ErrCode INT = 0 OUTPUT,
	 @ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
    Created by: 20200325@Malcolm
	Task: Remove Finance User/ Finance Code from FinancePermission table [Redmine : #128128]
	DB : DBCUST/CustDB

	Revisions:
		- 20200325@Malcolm: Remove Finance User/ Finance Code from FinancePermission table [Redmine : #128128]
	Param's Explanation:
		- @Type = 0 : Finance code
		        = 1 : Finance User	
*/
BEGIN
    BEGIN TRY
		DELETE t
		FROM dbo.Acc_FinancePermission t
		WHERE t.FinanceCode = @Username AND t.GroupId = @GroupId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE();
	END CATCH
	
END
