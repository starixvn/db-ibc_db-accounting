USE CheckResultDB
GO 

ALTER FUNCTION [dbo].f_GetPT_Dep_ByProduct
(
	@sporttype INT=0,
	@Site Nvarchar(100)=NULL
)
RETURNS  @tblSport_PT TABLE(
	Sportid INT,
	PT SmallMoney,
	Site Nvarchar(100),
	SiteID INT
	)
AS
/*
	Created: 20131015@Tom.Vo	
	Task :  Retrieve fee licensee's by product 
	DB: DB054.CheckResultDB
	Original:

	Revisions:
		-2014.04.22@Tom.Vo: Change source table : DBLIC.Licensee -> CheckLicenseeDB
		-2014.06.11@Tom.Vo: Add PT setting will be 90% new Lisencee Tonybet 
<<<<<<< HEAD
		-2014.06.26@Tom.Vo: Edit Keno PT setting 90% for all Licencees (Redmine#17380)
=======
		-2014.06.26@Tom.Vo: Edit Keno PT setting will be 90% for ALL Lisencee (Redmine#17380)
>>>>>>> 682c990bacc7204d27b77f72455780749402b597
	Param's Explanation:
		@sporttype: Product Id
			-1 : All
			0  : SB
			151: Racing
			161: NumberGame
			162: Live Casino
			180: Virtual Sport
			202: Keno
			251: RnG Casino		
*/
BEGIN

--DECLARE @Site Nvarchar(100)=NULL

DECLARE @tblSite TABLE (Site Varchar(100),SiteID INT)

INSERT INTO @tblSite(SiteID,Site)
Select SiteID , [Site]  From CheckCustDB.dbo.[Site] s WITH (nolock) 
	INNER JOIN CheckLicenseeDB.[dbo].[Licensees] l WITH (nolock) 
		ON LicenseeName = [Site] 
WHERE ( @Site IS NULL OR Site =  @Site )

IF @sporttype IN (-1,0) OR @sporttype <=99 OR @sporttype = 154--Sportbooks
		BEGIN
			INSERT INTO @tblSport_PT (Sportid,PT,Site,SiteID)
			select sp.sporttype, 
			CASE WHEN Site  = 'Tonybet' THEN 0.9 ELSE 0.85 END PT,
			tblSite.Site Site,
			tblSite.SiteID
			from bodb02.dbo.sports sp with (nolock)
				,@tblSite tblSite 
			where (sporttype <= 99 OR sporttype = 154)
				AND  (sporttype = @sporttype OR @sporttype IN (-1,0) )
		END

DECLARE @sporttype_old INT=@sporttype
IF @sporttype IN (-1,151) 	--Racing
		BEGIN
			SET @sporttype_old=151
			WHILE (@sporttype_old<154)
			BEGIN
				INSERT INTO @tblSport_PT (Sportid,PT,Site,SiteID)
				SELECT @sporttype_old, 0.0 ,Site,tblSite.SiteID	
				FROM @tblSite tblSite 
	
				SET @sporttype_old=@sporttype_old+1
			END
		END

IF @sporttype IN (-1,161) 	--NumberGame
		BEGIN			
			INSERT INTO @tblSport_PT (Sportid,PT,Site,SiteID)
			SELECT 161,
				CASE WHEN Site  = 'Haifa' THEN 0.925 ELSE 0.85 END PT,
				Site SITE,tblSite.SiteID
			FROM @tblSite tblSite 
		END

IF @sporttype IN (-1,162)  	--Live Casino
		BEGIN
			INSERT INTO @tblSport_PT (Sportid,PT,Site,SiteID)
			SELECT 162, 0.93 ,Site,tblSite.SiteID
			FROM @tblSite tblSite 
		END

IF @sporttype IN (-1,180)  	--Virtual Sport
		BEGIN
			SET @sporttype_old=180
			WHILE (@sporttype_old<186)
			BEGIN
				INSERT INTO @tblSport_PT (Sportid,PT,Site,SiteID)
				SELECT @sporttype_old, 0.85 ,Site,tblSite.SiteID	
				FROM @tblSite tblSite 
	
				SET @sporttype_old=@sporttype_old+1
			END
		END

IF @sporttype IN (-1,202) 	--Keno
		BEGIN
			INSERT INTO @tblSport_PT (Sportid,PT,Site,SiteID)
<<<<<<< HEAD
			SELECT 202, 0.9 PT,
=======
			SELECT 202, 
				0.9 AS PT,
>>>>>>> 682c990bacc7204d27b77f72455780749402b597
				Site,tblSite.SiteID					
			FROM @tblSite tblSite 
		END

IF @sporttype IN (-1,251) 	--RNG Casino
		BEGIN
			INSERT INTO @tblSport_PT (Sportid,PT,Site,SiteID)
			SELECT 251, 0.93,Site,tblSite.SiteID					
			FROM @tblSite tblSite 
		END

RETURN
END