/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_SelFIPermission]
	@UserID INT,
	@username VARCHAR(30),
	@CheckCustId TINYINT = 0
	
AS
/*
Created: 20200212@Tiara
Task :  Arrange detail permission for finance account 
DB: DBCUST/CUSTDB
Original:

	Revisions:
		- 20200211@Tiara: Arrange detail permission for finance account [Redmine: #128128]
		- 20200317@malcolm :  Arrange detail permission for finance account [Redmine: #128128]
*/

BEGIN
DECLARE @IsView BIT = 0,@srecomend INT, @mrecomend INT, @recomend INT, @player INT, 
		@GroupId SMALLINT = 0, @CustId INT, @Roleid SMALLINT
		
SELECT @GroupId = GroupId FROM dbo.f_GetFinanceUser() WHERE CustID = @UserID

IF @GroupId = 0 OR @GroupId = 1
   SELECT @IsView = @GroupId
		
IF @IsView IS  NULL
BEGIN
    EXEC @CustId = DBACC.bodb02.dbo.f_GetCustIDFromUsernameOrCustId @username, @CheckCustId

	SELECT @srecomend = srecommend, 
           @mrecomend = mrecommend, 
		   @recomend  = recommend, 
		   @player    = custid, 
		   @Roleid    = roleid
	FROM dbo.Customer WITH(NOLOCK)
	WHERE custid = @CustId

	SELECT TOP(1) @IsView = ISNULL(IsView,0)
	FROM dbo.Acc_FinancePermission f WITH(NOLOCK)
	WHERE CustId IN (@srecomend, @mrecomend, @recomend, @player) 
		  AND GroupId = @GroupId 
		  AND f.RoleId >= @Roleid
	ORDER BY RoleId ASC

	

END

SELECT @IsView AS IsView

END
