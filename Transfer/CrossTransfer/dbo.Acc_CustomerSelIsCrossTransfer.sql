ALTER PROCEDURE [dbo].[Acc_CustomerSelIsCrossTransfer]
    @FromCustId INT,
    @ToUser        VARCHAR(50),
    @IsCrossTransfer BIT OUTPUT,
    @errcode    INT = 0 OUTPUT,
    @errmsg        VARCHAR(200) = '' OUTPUT
   
AS
SET NOCOUNT ON
/*
Created:
Task : Check is Cross transfer (from Betting Acc to Finance Acc or contrary)
DB: DB502.bodb02
Original:

Revisions:
    -
Param's Explanation:
   
*/
BEGIN

	SELECT @IsCrossTransfer = 0

    IF not exists(SELECT 1 FROM custinfo(nolock) WHERE custid = @FromCustId and RoleId<=4)
    BEGIN
        SELECT @errcode = 100, @errmsg = 'Invalid Account'
        RETURN
    END
    IF not exists(SELECT 1 FROM custinfo(nolock) WHERE username = @ToUser and RoleId<=4)
    BEGIN
        SELECT @errcode = 100, @errmsg = 'Invalid Account'
        RETURN
    END

    DECLARE
        @ToCustId INT, @ToRoleId INT, @ToIsInternal BIT,
        @FromRoleId INT, @FromIsInternal BIT
    SELECT @ToCustId = custid, @ToRoleId = roleid FROM custinfo (nolock) WHERE username = @ToUser
    SELECT @FromRoleid = roleid FROM custinfo (nolock) WHERE custid = @FromCustId

    IF @FromRoleId = 4
         SELECT @FromIsInternal = IsInternal FROM CustSuper (nolock) WHERE custid = @FromCustId
    ELSE IF @FromRoleId = 3
        SELECT @FromIsInternal = IsInternal FROM CustMaster (nolock) WHERE custid = @FromCustId
    ELSE IF @FromRoleId = 2
        SELECT @FromIsInternal = IsInternal FROM CustAgent (nolock) WHERE custid = @FromCustId
    ELSE IF @FromRoleId = 1
        SELECT @FromIsInternal = IsInternal FROM CustAgent (nolock) WHERE custid =
            (
                SELECT recommend FROM custinfo (nolock) WHERE custid=@FromCustId
            )

    IF @ToRoleId = 4
         SELECT @ToIsInternal = IsInternal FROM CustSuper (nolock) WHERE custid = @ToCustId
    ELSE IF @ToRoleId = 3
        SELECT @ToIsInternal = IsInternal FROM CustMaster (nolock) WHERE custid = @ToCustId
    ELSE IF @ToRoleId = 2
        SELECT @ToIsInternal = IsInternal FROM CustAgent (nolock) WHERE custid = @ToCustId
    ELSE IF @ToRoleId = 1
        SELECT @ToIsInternal = IsInternal FROM CustAgent (nolock) WHERE custid =
            (
                SELECT recommend FROM custinfo (nolock) WHERE custid=@ToCustId
            )       
	
    IF( (@ToIsInternal = 0 and @FromIsInternal = 1) or (@ToIsInternal = 1 and @FromIsInternal = 0))
        SELECT @IsCrossTransfer = 1
    ELSE
        SELECT @IsCrossTransfer = 0

   
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsCrossTransfer] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelIsCrossTransfer] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelIsCrossTransfer] TO [vnteam]