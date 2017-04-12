USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_SpecialDelete_VoidByCurrency_SelectAllLicensee]    Script Date: 04/25/2016 09:31:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_SpecialDelete_VoidByCurrency_SelectAllLicensee]
AS
/*
	Created: Kent
	Date: 20170412
	DB: DBACC/bodb02

	Revisions: 		
		- 20170412@Kent: Get all licensee [Redmine:#75009]		
*/
BEGIN
	SET NOCOUNT ON	
	
	CREATE TABLE #LicenseeGroupInfo
	(
		Id INT PRIMARY KEY,
		GroupName VARCHAR(100)
	)
	
	INSERT INTO #LicenseeGroupInfo(Id, GroupName) -- fix here 
	VALUES (-1, 'Others')
	     , (0, 'Others')	
	
	;WITH LicenseeList AS
	(     
		SELECT siteid as Id, site as Name
		FROM site WITH(NOLOCK)
		WHERE isLicensee = 1 AND isActive =1 
		  AND siteID NOT IN (29,35)	
		UNION ALL
		SELECT -1 AS Id, 'MBC Group' As Name -- fix here 
		UNION ALL
		SELECT 0 AS Id, '789y' As Name -- fix here 
	)
	SELECT l.Id, l.Name, ISNULL(g.GroupName, 'Asian') AS GroupName
	FROM LicenseeList l
		 LEFT JOIN #LicenseeGroupInfo g
				 ON l.Id = g.Id	  		      
	
	SET NOCOUNT OFF
END
GO

GRANT EXECUTE ON [dbo].[NAP_SpecialDelete_VoidByCurrency_SelectAllLicensee]  TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialDelete_VoidByCurrency_SelectAllLicensee]  TO [vnteam] AS [dbo]
GO