 
ALTER PROCEDURE Acc_LoginAdminCheckTimeConstraint
(
	@custid		int,	
	@isAccess	BIT = 1 OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
)
AS
/*
	Created: 20130327@Lukas
	Task: constraint login time for some particular admins
	DB: DBTXN/bodb02
	
	Revision: 
		- 20130328@Lukas: set constrain time in between 9AM and 9PM (GMT+8)
*/
BEGIN
	SET NOCOUNT ON 
	
	IF @custid IN (	32648	, ---ALYN
					2937	, ---CRYSTAL
					347009	, ---CRYSTAL1
					630505	, ---doreen1
					1089853	, ---Foong
					610439	, ---june3
					2340	, ---pin
					8811	  ---YEAN
				)
				AND DATEPART(HOUR,GETDATE()) BETWEEN 9 AND 20
	BEGIN		
		SELECT	@isAccess = 0,
				@ErrMsg = 'You are not authorized to access at this time. Please contact your supervisor.',
				@ErrCode = 100
		RETURN
	END
END

GO

GRANT VIEW DEFINITION ON Acc_LoginAdminCheckTimeConstraint TO vnteam

