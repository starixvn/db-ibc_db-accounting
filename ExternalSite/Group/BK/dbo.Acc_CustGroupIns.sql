 ALTER PROCEDURE [dbo].[Acc_CustGroupIns]
	@CustID		INT,
	@RoleID		TINYINT,
	@System		VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(1000)='' OUTPUT
AS
/*
	Created: Johnson
	Date: 2010-11-19
	Task: Add customer info into Acc_CustGroup for external Account site
	DB: DB052.BODB02
*/
BEGIN
	SET NOCOUNT ON 
	
	IF(	@RoleID <> 4 
		OR @System = 'ACCOUNTING'
		OR EXISTS (SELECT 1 FROM Acc_CustGroup WITH(NOLOCK) WHERE custid = @Custid)
	) RETURN 
	ELSE 
	BEGIN
		INSERT INTO Acc_CustGroup(CustID,RoleID,GroupName)
		VALUES(@CustID,@RoleID,@System)

		IF @@ERROR <> 0
		BEGIN
			SET @ErrCode = 200
			SET @ErrMsg = 'Add Customer into Group fail. Please try again!'
			RETURN
		END
	END 

END
GO
GRANT EXECUTE ON [dbo].[Acc_CustGroupIns] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustGroupIns] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustGroupIns] TO [vnteam]
GO 
