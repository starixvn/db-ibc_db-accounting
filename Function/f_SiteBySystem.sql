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
	ELSE IF(@System = 'ACCTHAI')
	BEGIN
		Insert Into @tbSite(siteid)
		SELECT 22 --755555,...
	END
	ELSE IF (@System = 'ACCINDO')
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 11 --INDO
	END
	ELSE IF (@System IN ('ACCYEN','ACCYEN789','ACCYEN889','ACCNTD','ACCIRR','ACCUSD','ACCUT'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 3 --789y
	END
	ELSE IF (@System IN ('ACCUUS'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 1 --BEST-ODDS
	END
	ELSE IF (@System = 'ACCDDD')
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 11 --INDO
	END	
	Return
END


GO
GRANT VIEW DEFINITION ON [dbo].[f_SiteBySystem] TO [vnteam]
GO
GRANT SELECT ON [dbo].[f_SiteBySystem] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[f_SiteBySystem] TO [bodbExtAccNet] 