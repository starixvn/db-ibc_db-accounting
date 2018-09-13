/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_CustomerSelByUserName]
	@TypeID TINYINT,
	@Name NVARCHAR(50) = '',
	@System VARCHAR(50) = 'ACCOUNTING',
	@CustID INT = 0 OUTPUT,
	@UserID int = 0,
	@ShowInternalGroup bit = 1,
	@ErrCode INT = 0 OUTPUT, 
	@ErrMsg NVARCHAR (200) = '' OUTPUT
AS
/*
	Created by: 20120607@Sophia
	Task: Check valid and select ID from @Name, used for select view log of user control
	DB: DBCUST/NAP_UserControl
	
	Revisions:
		- 20120720@Johnson: Remove checking in accCustomer_1
		- 20120828@Elodie: IT admin's log are only be seen by IT department users.
		- 20180808@Helen: DB05.DBPOLICY migration  [Redmine:99462]
		
	Explain @Paramater:
		- @TypeID:
			0: used for Group
			1: used for Admin
		- @Name: for Group name and Admin name	
		- @ShowInternalGroup: 
			1: Show all departments with all users
			0: Show IT department with only IT department users (GroupID of IT department = 1)

		
*/ 
SET NOCOUNT ON 

--- Don't search by Name 
IF @Name = ''
BEGIN 
	IF @TypeID = 0 
	BEGIN 
		SELECT	@ErrCode = 500,
				@ErrMsg = N'Please input group name!'  
		RETURN
	END
	ELSE
	BEGIN 
		SELECT	@ErrCode = 501,
				@ErrMsg = N'Please input admin name!'  
		RETURN
	END 
END 

IF(@ShowInternalGroup = 0)
begin
	Declare @UserGroupID int
	select @UserGroupID = GroupID
	from accCustomer with (NOLOCK)	
	where custid = @UserID
end

--- Group
IF @TypeID = 0   
BEGIN 
	SELECT	@CustID = GroupID
	FROM	Acc_GroupInfo WITH (NOLOCK)  
	WHERE	GroupName = @Name AND 
			System = @System and
			GroupID <> CASE WHEN @UserGroupID = 1 or @ShowInternalGroup = 1 THEN 0 ELSE 1 end

	IF ISNULL(@CustID,0) = 0
		BEGIN
			SELECT	@ErrCode = 502,
					@ErrMsg = N'This group does not exist!'  
  			RETURN
		END
END
--- Admin
ELSE 
BEGIN 
	IF ISNULL((SELECT RoleID FROM CUSTDB.dbo.Custinfo WITH (NOLOCK) WHERE Username = @Name),0) < 5
		BEGIN 
			SELECT	@ErrCode = 503,
					@ErrMsg = N'This admin does not exist!'  
  			RETURN
		END	 
	ELSE	
	BEGIN 
		SELECT	@CustID = c.CustID 
		FROM	CUSTDB.dbo.Custinfo c WITH(NOLOCK)  	
				inner JOIN accCustomer ac with (NOLOCK) ON c.custid = ac.custid	
		WHERE	c.Username = @Name and
				ac.GroupID <> CASE WHEN @UserGroupID = 1 or @ShowInternalGroup = 1 THEN 0 ELSE 1 end

		IF ISNULL(@CustID,0) = 0
		BEGIN
			SELECT	@ErrCode = 504,
					@ErrMsg = N'This admin does not exist!'  
  			RETURN
		END
	END
END 

GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_CustomerSelByUserName] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Acc_Con_CustomerSelByUserName] TO [bodbAdminNet]
