/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_Admin_AddNewSite]
	@sitename	NVARCHAR(50),
	@sitelabel	VARCHAR(50)=NULL,
	@isDeposit	BIT = 1,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT,
	@SiteDBGroupID SMALLINT = 0
AS
/*
	Created: 20170704@Harper
	DB: DBCust.CustDB
	Description: Create new site by NAP [RedmineID: #77817]

	Revisions:
		- 20170704@Harper: Create new SP [RedmineID: #77817]
		- 20220413@Elodie: Remove code to delete site in case of error [RedmineID: #170752]
		- 20220722@Eden: LAP - Scale Out DBTrans  [redmine: #158293/#175297]
		- 20230112@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]
		- 20241230@July: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
*/
BEGIN
	IF LEN(@Sitename) > 10
	BEGIN
		SELECT @ErrMsg = 'The max length of the Site Name is 10 characters. Please enter again.'
		     , @ErrCode = 102
		
		RETURN
	END
	ELSE
	IF EXISTS (SELECT TOP 1 1 FROM dbo.Site WITH (NOLOCK) WHERE site = @Sitename)
	BEGIN
		SELECT @ErrMsg = 'Site name: ' + @Sitename + ' already exists !!!'
		     , @ErrCode = 101
		
		RETURN
	END
	ELSE
	BEGIN
		INSERT INTO dbo.Site(site, ServerID, isLicensee, isActive, isDeposit,SiteDBGroupID,SiteLabel, RepUpdateTime)
		VALUES (@sitename, 0, @isDeposit, 1, @isDeposit, @SiteDBGroupID, @sitelabel, dbo.f_GetDateTime2())
	
		IF @@ERROR <> 0
		BEGIN
			SELECT @ErrMsg = 'Insert Failed', @ErrCode = 102

			RETURN
		END
	END	
END
GO