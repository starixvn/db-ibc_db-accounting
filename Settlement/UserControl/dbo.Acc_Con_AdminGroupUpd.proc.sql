
ALTER PROCEDURE [dbo].[Acc_Con_AdminGroupUpd]
	@CustID int,
	@UserID int,
	@GroupID int,
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@System varchar(50)='ACCOUNTING'
AS
If @System = 'ACCOUNTING'
	BEGIN
		IF EXISTS(SELECT 1 FROM Acc_groupinfo_1 with(nolock) where groupid=@groupid)
			BEGIN 
				IF EXISTS(SELECT 1 FROM AccCustomer_1 ac with(nolock) WHERE custid=@custid and groupid <> @groupID) 
				BEGIN
					BEGIN TRANSACTION
						UPDATE accCustomer_1 with (ROWLOCK, UPDLOCK) SET groupid=@groupid WHERE custid = @custid					
					COMMIT TRANSACTION
				END
			END
			ELSE
			BEGIN
				SELECT @ErrMsg =  case @Language
									when 'E' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
									when 'CS' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
									when 'J' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
									else N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
								end, @ErrCode = 103
				return 
			END
		
	END
ELSE IF @System ='AFFILIATE'
	Begin
	IF EXISTS(SELECT 1 FROM Acc_groupinfo_1 with(nolock) where groupid=@groupid)
		BEGIN 
			IF EXISTS(SELECT 1 FROM affiliate_user ac with(nolock) WHERE custid=@custid and groupid <> @groupID) 
			BEGIN
				BEGIN TRANSACTION
					UPDATE affiliate_user with (ROWLOCK, UPDLOCK) SET groupid=@groupid WHERE custid = @custid			
				COMMIT TRANSACTION
			END
		END
		ELSE
		BEGIN
			SELECT @ErrMsg =  case @Language
								when 'E' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
								when 'CS' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
								when 'J' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
								else N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
							end, @ErrCode = 103
			return 
		END


	End
		



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminGroupUpd] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].Acc_Con_AdminGroupUpd TO [bodbAdminNet]