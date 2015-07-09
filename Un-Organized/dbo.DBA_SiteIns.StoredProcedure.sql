CREATE PROCEDURE [dbo].[DBA_SiteIns]
	@site nvarchar(50),
	@type nvarchar(50) = null,
	@spreada float = null,
	@spreadb float = null,
	@spreadc float = null,
	@spreadd float = null,
	@spreade float = null,
	@spreadf float = null,
	@ServerID int = 0,
	@isLicensee bit = 0,
	@isActive bit = 0
AS
/*
Created: 
Task : Insert new site
DB: DB02.bodb02
*/	
SET NOCOUNT ON

Insert into [Site] ([site], type,spreada,spreadb,spreadc,spreadd,spreade,spreadf,ServerID,isLicensee,isActive)
values (
	@site,
	@type,
	@spreada,
	@spreadb,
	@spreadc,
	@spreadd,
	@spreade,
	@spreadf,
	@ServerID,
	@isLicensee,
	@isActive
)

GO
GRANT VIEW DEFINITION ON [dbo].[DBA_SiteIns] TO [vnteam]