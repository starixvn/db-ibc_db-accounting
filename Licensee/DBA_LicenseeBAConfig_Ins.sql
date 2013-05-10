ALTER PROCEDURE [dbo].[DBA_LicenseeBAConfig_Ins]
(
	@LicenseeID		INT,
	@groupa		DECIMAL(9,8) = 0,
	@groupb		DECIMAL(9,8) = 0,
	@groupc		DECIMAL(9,8) = 0,
	@groupd		DECIMAL(9,8) = 0,
	@1x2Comm	DECIMAL(9,8) = 0,
	@OtherComm	DECIMAL(9,8) = 0,
	@ugroup		VARCHAR(3)  = 'a',
	@EnableBA	BIT = 0,
	@UserID			INT,
	@IP				VARCHAR(50)='',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
)
AS
/*
Created: Henry
Date: 20110614
Task : Insert Licensee Commission Template for applying BA 
DB: DB052.bodb_Licensee
Original:

Revisions:
	-20111213@Jim: remove ugroup column in LicenseeBAConfig table 
	
Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON
	
	--Check exist in Licensees
	IF not exists (SELECT 1 FROM Licensees with (nolock) WHERE LicenseeID = @LicenseeID)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Licensee, please check again!'
		RETURN
	END
	
	--Check exist in LicenseeBAConfig
	IF exists (SELECT 1 FROM LicenseeBAConfig with (nolock) WHERE LicenseeID = @LicenseeID)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This licensee has been inserted before!'
		RETURN
	END
	
	Insert into LicenseeBAConfig (LicenseeID, groupa, groupb, groupc, groupd, [1x2Comm], [OtherComm], EnableBA , ModifyBy, ModifyDate)
	values (@LicenseeID, @groupa, @groupb, @groupc, @groupd,  @1x2Comm, @OtherComm, @EnableBA , @UserID, getdate())
	
	--write log
	Insert into UserLog_LicenseeBAConfig (LicenseeID, groupa, groupb, groupc, groupd,  [1x2Comm], [OtherComm], EnableBA , IP, ActionID, ModifyBy, ModifyDate)
	values (@LicenseeID, @groupa, @groupb, @groupc, @groupd,  @1x2Comm, @OtherComm, @EnableBA , @IP, 217, @UserID, getdate())
	
END

GO
GRANT VIEW DEFINITION ON [dbo].[DBA_LicenseeBAConfig_Ins] TO [vnteam]