

ALTER PROCEDURE Acc_SpecialDelete_CheckPermission
(
	@UserName	NVARCHAR(50),
	@UserPwd	NVARCHAR(50),
	@UserID		INT,
	@matchid	INT,
	@f_transid	BIGINT	= NULL,
	@t_transid	BIGINT	= NULL,
	@type		INT	    = 1,
	@ErrMsg		NVARCHAR(200)	= '' OUTPUT,
	@ErrCode	INT				= 0 OUTPUT 
)
AS
/*
	Created: 20120918@Lukas
	Task: checking authentication & authorization before doing delete tickets
	DB: DBTRANS.BODB02
	
	Revisions:
	
	Param explanation
		@type : 1 SpecialDelete
				2 SpecialDeleteNumberGame
				3 SpecialDeleteLivecasino
				4 SpecialDeleteEarlyKickOff
*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @funcname VARCHAR(50)
	SELECT @ErrCode = 0	
	
	SELECT @funcname = CASE @type	WHEN 1 THEN '[SpecialDelete]'
									WHEN 2 THEN '[SpecialDeleteNumberGame]'
									WHEN 3 THEN '[SpecialDeleteLivecasino]'
									WHEN 4 THEN '[SpecialDeleteEarlyKickOff]'
									ELSE ''
					   END
	--Check permission
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname=@funcname,@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end	
	
	-- remove Check settled Date

	DECLARE @LogData NVARCHAR(500)
	

	IF NOT EXISTS (SELECT 1
					FROM customer WITH (NOLOCK)
					WHERE   customer.userpwd = @UserPwd
						and custid = @UserID
						and roleid>=5)
	BEGIN
		IF @type = 4
			SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' because of early kick off'
		ELSE			
			SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid)
		EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END
END

GO

GRANT EXECUTE ON Acc_SpecialDelete_CheckPermission TO bodbAdminNet