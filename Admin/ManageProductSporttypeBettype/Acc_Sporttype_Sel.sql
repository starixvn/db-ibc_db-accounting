/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_Sporttype_Sel
	@Sporttype      SMALLINT = NULL,
	@SportName      NVARCHAR(50) = NULL,
	@PageSize		INT = 0,
	@PageIndex		INT = 0,
	@TotalRows		INT = 0 OUTPUT
AS

/*
Created: 20200328@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200328@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
		
*/

BEGIN
    SET NOCOUNT ON
	
	DECLARE @RowStart INT, @RowEnd INT

	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #Tmp (
	 	SportType		SMALLINT,
		SportName		NVARCHAR(50),
		SportNameCh		NVARCHAR(50),
		SportNameCs		NVARCHAR(50),
		SportNameJp		NVARCHAR(50),
		SportNameIt		NVARCHAR(50),
		SportNameTh		NVARCHAR(50),
		ParlayMaxPayout INT,
		SportNameKo		NVARCHAR(50),
		SportNameES		NVARCHAR(50),
		SportNameVN		NVARCHAR(50),
		SportNameEL		NVARCHAR(50),
		SportNameRU		NVARCHAR(50),
		SportNameID		NVARCHAR(50),
		SportNamePT		NVARCHAR(50),
		SportNameFR		NVARCHAR(50),
		SportNameMMR	NVARCHAR(50),
		SportNamePL		NVARCHAR(50),
		SportNameHI		NVARCHAR(50),
		RowNum          INT
	)

	INSERT INTO #Tmp(
			   SportType,
		       ParlayMaxPayout,
			   SportName,
			   SportNameCh,
			   SportNameCs,
			   SportNameJp,
			   SportNameIt,
			   SportNameTh,		   
			   SportNameKo,
			   SportNameES,
			   SportNameVN,
			   SportNameEL,
			   SportNameRU,
			   SportNameID,
			   SportNamePT,
			   SportNameFR,
			   SportNameMMR,
			   SportNamePL,
			   SportNameHI,
			   RowNum
	)
    SELECT     SportType,
		       ParlayMaxPayout,
			   SportName,
			   SportNameCh,
			   SportNameCs,
			   SportNameJp,
			   SportNameIt,
			   SportNameTh,		   
			   SportNameKo,
			   SportNameES,
			   SportNameVN,
			   SportNameEL,
			   SportNameRU,
			   SportNameID,
			   SportNamePT,
			   SportNameFR,
			   SportNameMMR,
			   SportNamePL,
			   SportNameHI,
			   ROW_NUMBER() OVER(ORDER BY SportType) AS RowNum
	FROM Sports WITH(NOLOCK)
	WHERE (SportType = @Sporttype OR @Sporttype IS NULL) 
		  AND (SportName LIKE '%' + @SportName +'%' OR ISNULL(@SportName,'') = '')

	ORDER BY SportType

	SELECT @TotalRows = COUNT(*) FROM #Tmp 
	
	SELECT  SportType,
		    ParlayMaxPayout,
		    SportName,
		    SportNameCh,
		    SportNameCs,
			SportNameJp,
			SportNameIt,
			SportNameTh,		   
			SportNameKo,
			SportNameES,
			SportNameVN,
			SportNameEL,
			SportNameRU,
			SportNameID,
			SportNamePT,
			SportNameFR,
			SportNameMMR,
			SportNamePL,
			SportNameHI,
			RowNum
	FROM #Tmp
	WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNum BETWEEN @RowStart AND @RowEnd)

	DROP TABLE #Tmp
 
END

