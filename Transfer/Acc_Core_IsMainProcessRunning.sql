
ALTER PROCEDURE [dbo].[Acc_Core_IsMainProcessRunning]
	  @CustId INT
	, @UplineId INT
	, @IsDepositMember BIT
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg VARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20170914@Patrick
	Task: Check main process is processing data for his/her line or not
	DB: DBTXN.BODB02
	Revision:
*/
BEGIN
	SET NOCOUNT ON
	SELECT @ErrCode = 0 , @ErrMsg = ''
	
	--for ad-hoc case
	/*
	--//not allow for all lines
	SELECT @ErrCode = 113
		, @ErrMsg = 'Can''t make transfer at this time.'
	RETURN
	*/

	--//only check for Deposit site
	IF @IsDepositMember = 1
	BEGIN
		IF EXISTS (
			SELECT TOP 1 1 
			FROM dbo.f_Core_BlackSitesList()
		)
		BEGIN
			DECLARE @siteName VARCHAR(50)
			SELECT @siteName = ISNULL(site, '')
			FROM CustDB.dbo.Customer WITH(NOLOCK)
			WHERE custid = @UplineId --> recommend

			IF EXISTS (
				SELECT TOP 1 1
				FROM dbo.f_Core_BlackSitesList()
				WHERE siteName = @siteName
			)
			BEGIN
				SELECT @ErrCode = 114
					, @ErrMsg = 'Can''t make transfer at this time.'
				RETURN
			END
		END
	END
	
	IF EXISTS (
		SELECT TOP 1 1 
		FROM dbo.ProcessingCustList WITH(NOLOCK)
		WHERE CustId IN (@CustId, @UplineId)
	)
	BEGIN
		SELECT @ErrCode = 115
			, @ErrMsg = 'Can''t make transfer/withdrawal at this time. Because The [MB/BU] process is running for this line.'
		RETURN
	END

END
GO
GRANT EXECUTE ON [dbo].[Acc_Core_IsMainProcessRunning] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_Core_IsMainProcessRunning] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_Core_IsMainProcessRunning] TO [bodbExtAccNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_Core_IsMainProcessRunning] TO [Dot_Bonus] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_Core_IsMainProcessRunning] TO [Dot_Member] AS [dbo]
GO