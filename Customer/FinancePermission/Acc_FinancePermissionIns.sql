/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC dbo.Acc_FinancePermissionIns
	 @UserId INT,
	 @GroupId SMALLINT,
	 @Username NVARCHAR(50),
	 @RoleId INT,
	 @IsView BIT = 0,
	 @Type SMALLINT = 0
AS
/*
    Created by: 20200325@Malcolm
	Task: Insert Finance User/ Finance Code into FinancePermission table [Redmine : #128128]
	DB : DBCUST/CustDB

	Revisions:
		- 20200325@Malcolm: Insert Finance User/ Finance Code into FinancePermission table [Redmine : #128128]
	Param's Explanation:
		- @Type   = 0 : Finance code
		          = 1 : Finance User	
	    - @IsView = 0 for Finance User
*/
BEGIN

	INSERT INTO dbo.Acc_FinancePermission(GroupId, FinanceCode, RoleId, IsView)
	VALUES (@GroupId, @Username, @RoleId, @IsView)	
	
END
