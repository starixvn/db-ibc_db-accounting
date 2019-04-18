/*<info serverAlias="DBAGE-BODB02" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_SiteSel] 
 @System varchar(50) = 'ACCOUNTING',
 @Userid INT=NULL,
 @IncludeCN88 BIT=0
AS
/*
DB: DBAGE/BODB02

Revisions:
	- 20100819@Ethan: get Sites by System
	- 20110310@Henry: get active credit sites and licensee sites
	- 20160617@Winnie: #48948 Hide_special_sites_from_unautorized_users
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20190320@Phillip: #105338 - Build Customer Setting with Singbet Style
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @SearchQuery varchar(1024)
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpUserid VARCHAR(50)

	IF(@System = 'ACCOUNTING')
	BEGIN
		IF @Userid IS NULL
		BEGIN
			SELECT [siteid], [site],  isLicensee
			FROM [Site] with (NOLOCK)
			WHERE isActive = 1 
			ORDER BY isLicensee, [site]
		END
		ELSE
		BEGIN
			SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))
			SELECT @SearchQuery = 'SELECT * 
			FROM OPENQUERY(DBPOL, 
			''SELECT siteid , site,SpecialGroup FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser( ''''' + @tmpUserid + ''''')'')'

			INSERT INTO  @tmp (siteid , site,SpecialGroup)
			EXECUTE(@SearchQuery)

			SELECT a.siteid, a.site,  isLicensee
			FROM [Site] a with (NOLOCK)
			WHERE isActive = 1 
				AND siteid NOT IN (SELECT siteid FROM @tmp )
				AND (@IncludeCN88 <> 0 OR a.site <> 'CN88')
			ORDER BY isLicensee, [site]
		END
	END
	ELSE
	BEGIN
		SELECT [siteid], [site], isLicensee
		FROM [Site] with (NOLOCK)
		WHERE 
			siteid in (SELECT siteid FROM dbo.f_SiteBySystem(@System))
			and isActive = 1		
		ORDER BY isLicensee, [site]
	END
END