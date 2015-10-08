
ALTER FUNCTION [dbo].[f_SiteBySystem]
(
	@System varchar(50) = 'ACCOUNTING'
)
	RETURNS @tbSite table (siteid  int PRIMARY KEY)
AS

/*
Created: 
Task : Get sites by system
DB: DBAGE/bodb02; DBACC/bodb02

Revisions:
	- 20100819@Ethan: Get sites by System
	- 20101130@Johnson: Get INDO site
	- 20110908@Johnson: Get ACCYEN789 and ACCYEN889 system
	- 20111122@Johnson: Get ACCDDD system
	- 20120809@Elodie: Get ACCIRR system
	- 20130404@Jamie: Put ACCUUS for testing 
	- 20130718@Lukas: add ACCUT group
	- 20130909@Jamie: ADD group ACCYEN668 
	- 20140117@Lukas: add group ACCYEN888
	- 20150526@Kiwi: add ACCUT2 group
	- 20150812@Amy: add ACCTHAI2 group
	-20150817@Susan: add ACCIN group
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	
	Param's Explanation:
	- @System: input system name 'ACCTHAI', 'ACCOUNTING'
*/

BEGIN
	IF (@System = 'ACCOUNTING')
	BEGIN
		Insert Into @tbSite(siteid)
		Select siteid 
		From [Site] (nolock)
	END
	ELSE IF(@System IN ('ACCTHAI','ACCTHAI2','ACCTHAI56','ACCTHAI99'))
	BEGIN
		Insert Into @tbSite(siteid)
		SELECT 22 --755555,...
	END
	ELSE IF (@System IN ('ACCINDO','ACCIN') )
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 11 --INDO
	END
	ELSE IF (@System IN ('ACCYEN','ACCYEN789','ACCYEN889','ACCYEN668','ACCNTD','ACCIRR','ACCUSD','ACCUT','ACCYEN888','ACCUT2'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 3 --789y
	END
	ELSE IF (@System IN ('ACCUUS'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 1 --BEST-ODDS
		UNION ALL 
		SELECT 184 -- 766666
	END
	ELSE IF (@System = 'ACCDDD')
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 11 --INDO
	END	
	Return
END


GO
GRANT SELECT ON [dbo].[f_SiteBySystem] TO [bodbAdminNet] AS [dbo]
GO
GRANT SELECT ON [dbo].[f_SiteBySystem] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[f_SiteBySystem] TO [vnteam] AS [dbo]

