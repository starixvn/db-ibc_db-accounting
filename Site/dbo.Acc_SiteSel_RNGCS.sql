ALTER PROCEDURE [dbo].[Acc_SiteSel_RNGCS]
	 @CustID	INT				= 0
	,@SiteRNG	VARCHAR(10)		= ''	OUTPUT 
	,@ErrCode	INT				= 0		OUTPUT
	,@ErrMsg	NVARCHAR(100)	= ''	OUTPUT
AS

/*
Created by: Jamie
Date: 2013-02-05
Task : Get SiteName for RNG Casino API
  + Sitename= "ibcbet" if customer belongs to CREDIT site.
  + Sitename = deposit's sitename if customer belongs to DEPOSIT site.

DB: DBAGE/BODB02

Revisions:

*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE	 @Site		VARCHAR(10)
			,@RoleID	TINYINT 
			,@Recommend	INT
			
	SELECT	 @SiteRNG	= CASE	WHEN @RoleID = 1 THEN ''
								WHEN s.isLicensee = 0 THEN 'ibcbet' 
								ELSE s.[site] END 
			,@RoleID	= c.RoleID
			,@Recommend	= c.Recommend 
	FROM	Customer c WITH (NOLOCK)
			LEFT JOIN Site s WITH (NOLOCK) ON c.site = s.site 
	WHERE	custid = @CustID
	
	IF	@RoleID IS NULL OR @RoleID > 4
	BEGIN
		SELECT	 @ErrCode	= 100
				,@ErrMsg	= 'Invalid Customer!'
	END
	
	IF @RoleID = 1 
	BEGIN
		SELECT	@SiteRNG = CASE	WHEN s.isLicensee = 0 THEN 'ibcbet' 
								ELSE s.[site] END
		FROM	Customer ag WITH (NOLOCK)
				LEFT JOIN Site s WITH (NOLOCK) ON ag.site = s.site 
		WHERE	ag.custid = @Recommend
		
	END

END
GO
GRANT EXECUTE ON [dbo].[Acc_SiteSel_RNGCS] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_SiteSel_RNGCS] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SiteSel_RNGCS] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_SiteSel_RNGCS] TO [bodbDownlineNetView]

