SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_BA_SpecialCustDel]
	(
		@LicenseeID INT ,
		@CustID INT ,
		@modifyby INT,
		@IP VARCHAR(15)='',
		@ErrCode	INT = 0 OUTPUT,		
		@ErrMsg		varchar(1000)='' OUTPUT 
	)
AS
/*
Created: Jim
Date: 5-03-2012
Task : Replace hardcode member spread by web application
DB: DBLIC/bodb_Licensee
Original:

Revisions:
	- 20130123@Daniel: Change link server alias
	
Param's Explanation:
	
*/
BEGIN
	
	SET NOCOUNT ON 
	DECLARE @ugroup VARCHAR(3),@ugroup_old  VARCHAR(3)
	DECLARE @IsBA BIT  
	DECLARE @Currency INT 

	SELECT @ugroup=ugroup,@ugroup_old=ugroup_old FROM LicenseeSpecialCust  WITH (NOLOCK) WHERE CustID=@CustID AND LicenseeID=@LicenseeID
	
	
	IF NOT EXISTS (SELECT 1 FROM LicenseeSpecialCust lsc WITH (NOLOCK) WHERE Licenseeid=@LicenseeID AND Custid=@CustID)	
	BEGIN
		SELECT @ErrMsg='Customer was deleted',@ErrCode=1
		RETURN
	END
	ELSE 
	BEGIN
		DELETE FROM LicenseeSpecialCust 
		WHERE Licenseeid=@LicenseeID AND Custid=@CustID 
		-- If is BA
		IF EXISTS (SELECT 1 FROM LicenseeBAHistory lb WITH (NOLOCK) WHERE lb.LicenseeID=@LicenseeID AND lb.CustID=@CustID AND lb.Status='Running')
		BEGIN
			SET @IsBA=1
			--- Update Comm
			-- Update ugroup to LicenseeBAHistory table 
			UPDATE LicenseeBAHistory  WITH (ROWLOCK,UPDLOCK)
			SET ugroup=@ugroup_old
			WHERE LicenseeID=@LicenseeID AND CustID=@CustID  AND Status='Running'
			--- update comm
			EXEC DBTXN.bodb02.dbo.Lrf_CustomerUpdMemberBAComm
			@LicenseeID=@LicenseeID,
			@custid=@CustID,
			@ModifyBy=@Modifyby,
			@IsBA=@isBA,
			@IP=@IP,
			@IsAdmin=1,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT
			DECLARE @groupold VARCHAR(3)
			SELECT @groupold=ugroup FROM DBTXN.bodb02.dbo.customer WITH (NOLOCK) WHERE CustID=@CustID
			--- write log BA Customer
			INSERT INTO UserLog_LicenseeSpecialCust(LicenseeID,CustID,ugroup,ugroup_old,modifyby,modifydate,IP,ActionType)
			VALUES (@LicenseeID,@CustID,@groupold,@ugroup,@modifyby,getdate(),@IP,'Delete')
		END	 
		ELSE -- Normal member
		BEGIN
			-- Update ugroup to Customer table 0
				EXEC DBTXN.bodb02.dbo.Acc_BA_SpecialCustUpdUgroup
				@custid = @CustID,
				@ugroup = @ugroup_old,
				@userid = @modifyby,
				@IP = @IP,
				@ErrCode = @ErrCode OUTPUT,
				@ErrMsg = @ErrMsg OUTPUT
	
			-- write log  Normal Customer 
			INSERT INTO UserLog_LicenseeSpecialCust(LicenseeID,CustID,ugroup,ugroup_old,modifyby,modifydate,IP,ActionType)
			VALUES (@LicenseeID,@CustID,@ugroup_old,@ugroup,@modifyby,getdate(),@IP,'Delete')		
		END
		IF (@@ERROR <> 0 )
		BEGIN
			SELECT 	@ErrMsg = 'Delete failed. Please try again.', @ErrCode = 1	
			RETURN
		END
	END 
END


GO
GRANT EXECUTE ON [dbo].[Acc_BA_SpecialCustDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BA_SpecialCustDel] TO [vnteam] 








