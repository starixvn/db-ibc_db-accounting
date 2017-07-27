/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
 
ALTER PROCEDURE [dbo].[NAP_Admin_AddNewSite]
	@sitename	NVARCHAR(50),
	@isDeposit	BIT = 1,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20170704@Harper
	DB: DBCust.CustDB
	Description: Create new site by NAP [RedmineID: #77817]

	Revisions:
		- 20170704@Harper: Create new SP [RedmineID: #77817]
*/
BEGIN
	
	IF EXISTS (SELECT TOP 1 1 FROM dbo.Site WITH (NOLOCK) WHERE site = @Sitename)
	BEGIN
		SELECT @ErrMsg = 'Site name: ' + @Sitename + ' already exists !!!'
		     , @ErrCode = 101
		
		RETURN
	END
	ELSE
	BEGIN
		INSERT INTO dbo.Site(site, ServerID, isLicensee, isActive, isDeposit)
		VALUES (@sitename, 0, @isDeposit, 1, @isDeposit)
	
		IF @@ERROR <> 0
		BEGIN
			SELECT @ErrMsg = 'Insert Failed', @ErrCode = 102

			DELETE dbo.Site
			WHERE site = @sitename AND isDeposit = @isDeposit

			RETURN
		END
	END	
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_AddNewSite] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_AddNewSite] TO [vnteam]
GO
