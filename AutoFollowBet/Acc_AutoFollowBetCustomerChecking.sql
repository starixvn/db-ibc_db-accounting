/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetCustomerChecking] 
	@Username	NVARCHAR(50)
	,@ErrCode   INT				= 0 OUTPUT
    ,@ErrMsg    NVARCHAR(200)	= '' OUTPUT
AS

/*
	Created: 20141230@Kathy
	DB: DBCUST-CustDB
	Task: Checking username

	Revisions:
		- 20150311@Kathy: Support multi-follower on one customer [RedmineID: #32146]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @custid		INT
			,@roleid	INT
	
	SELECT @custid = custid
	      ,@roleid = CASE WHEN roleid = 1 THEN 0 ELSE 1 END
	FROM dbo.CustInfo WITH (NOLOCK)
	WHERE username = @Username
		AND roleid IN (1, 2) --member or agent

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username, please try again!'
			 , @ErrCode = 101

		RETURN
	END
END
GO