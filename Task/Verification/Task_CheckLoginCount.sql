ALTER PROCEDURE [dbo].[Task_CheckLoginCount]

AS
/*
	Created by: Jamie
	Date: 2011-09-23
	Task: Checking Login Count 
	DB: DB052.BODB02

	Revisions:

*/
BEGIN
	SET NOCOUNT ON 
	DECLARE	@SubAccIDs VARCHAR(7500),
			@CustIDs VARCHAR(7500),
			@Message VARCHAR(8000),
			@ErrorCode TINYINT

	SELECT	@SubAccIDs='',
			@CustIDs='',
			@Message='',
			@ErrorCode = 0 

	IF EXISTS (SELECT TOP 1 1 FROM CustSub WITH (NOLOCK) WHERE LoginCount > 200 AND Closed = 0 )
	BEGIN
		SELECT	@SubAccIDs = @SubAccIDs + CAST(SubAccID AS VARCHAR(20)) +','
		FROM	CustSub WITH (NOLOCK)
		WHERE	LoginCount > 200 AND Closed = 0 
		
		SELECT	@ErrorCode = 100
		SELECT	@Message = 'Sub-Account(s) failed to log in more than 200 times: '+ @SubAccIDs + ' Please have a check!'
	END

	IF EXISTS (SELECT TOP 1 1 FROM Customer WITH (NOLOCK) WHERE LoginCount > 200)
	BEGIN
		SELECT	@CustIDs = @CustIDs + CAST(CustID AS VARCHAR(20)) +','
		FROM	Customer WITH (NOLOCK)
		WHERE	LoginCount > 200 -- Ignore Closed on Custinfo 
		SELECT	@ErrorCode = 101	
		SELECT	@Message = @Message+ 'Customer(s) failed to log in more than 200 times: '+ @CustIDs + ' Please have a check!'
	END
	
	IF @ErrorCode > 0  RAISERROR(@Message,16,1)
END




GO
GRANT VIEW DEFINITION ON [dbo].[Task_CheckLoginCount] TO [vnteam]