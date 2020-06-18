/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_AutoFollowBetDelMultipleCustomer] 
	@strUsername	VARCHAR(MAX)
	,@UserId		INT
	,@IP			VARCHAR(50)
	,@ErrCode		VARCHAR(100)	= ''	OUTPUT
	,@ErrMsg		NVARCHAR(MAX)	= ''	OUTPUT
AS

/*
	Created: 20141230@Kathy
	DB: DBCUST-CustDB
	Task: Delete multiple customer
	
	Revisions:
		- 20150311@Kathy: Support multi-follower on one customer [Redmine:#32146]
		
	Param's Explanation:
		*@strUsername: list of username: 
		 EX: member01,follower01;member02,follower02
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @username		VARCHAR(30)
			,@follower		VARCHAR(30)
			,@rowid			INT
			,@SubErrMsg		VARCHAR(200)
			,@SubErrCode INT
			
	DECLARE @tblCust TABLE(username VARCHAR(30), follower VARCHAR(30))
	
	INSERT INTO @tblCust(username, follower)
	SELECT PARSENAME(t.val,2) as username
		,PARSENAME(t.val,1) as follower
	FROM (SELECT replace(s.val,',','.') val 
			FROM dbo.strSplit(@strUsername,';') s
		) t
	
	WHILE(1 = 1)
	BEGIN
		SELECT TOP 1 @username = username
					,@follower = follower
		FROM @tblCust		
		
		IF @@ROWCOUNT = 0
			BREAK
		
		BEGIN TRY
			SELECT @SubErrCode = 0
				,@SubErrMsg = ''
			
				EXEC dbo.Acc_AutoFollowBetDelCustomer
				@Username = @username
				,@follower	= @follower
				,@UserId = @UserId 	
				,@IP	= @IP	
				,@ErrCode = @SubErrCode OUTPUT
				,@ErrMsg   = @SubErrMsg OUTPUT
			
			SELECT @ErrCode = ISNULL(@ErrCode,'') + CONVERT(VARCHAR(3),ISNULL(@SubErrCode,0)) + ';'
					,@ErrMsg = ISNULL(@ErrMsg,'') + ISNULL(@SubErrMsg,'') + ';'
					
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = ISNULL(@ErrCode,'') + CONVERT(VARCHAR(3),ISNULL(@SubErrCode,0)) + ';'
					,@ErrMsg = ISNULL(@ErrMsg,'') +  ISNULL(@SubErrMsg,'')  + ';'
		END CATCH
				
		DELETE FROM @tblCust
		WHERE username = @username
		AND follower = @follower
		
	END
	
	SELECT @ErrCode = LEFT(@ErrCode,LEN(@ErrCode) - 1)
		,@ErrMsg = LEFT(@ErrMsg, LEN(@ErrMsg) - 1)
END
GO