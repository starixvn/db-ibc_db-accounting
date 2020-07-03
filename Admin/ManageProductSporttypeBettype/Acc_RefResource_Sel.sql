/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_RefResource_Sel
	@RefId          VARCHAR(20)  = '',
	@ResourceId     VARCHAR(20)  = '',
	@ResourceEN     NVARCHAR(50) = '',
	@PageSize		INT = 0,
	@PageIndex		INT = 0,
	@TotalRows		INT = 0 OUTPUT
AS

/*
Created: 20200703@Malcolm
Task :  NAP-Manage RefResource
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200703@Malcolm: NAP-Manage RefResource [Redmine: #131241]
		
*/

BEGIN
    SET NOCOUNT ON
	
	DECLARE @RowStart INT, @RowEnd INT

	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #Tmp 
	(    
		RefId			VARCHAR(20),		
		ResourceId		VARCHAR(20),		
		Resource_en		NVARCHAR(50),	
		Resource_ch		NVARCHAR(50),	
		Resource_cs		NVARCHAR(50),	
		Resource_jp		NVARCHAR(50),	
		Resource_it		NVARCHAR(50),	
		Resource_th		NVARCHAR(50),	
		Resource_ko		NVARCHAR(50),	
		Resource_es		NVARCHAR(50),	
		Sort1			INT,	
		Sort2			INT,	
		Resource_el		NVARCHAR(50),	
		Resource_vn		NVARCHAR(50),	
		Resource_pl		NVARCHAR(50),	
		Resource_id		NVARCHAR(50),	
		Resource_hi		NVARCHAR(50),	
		Resource_mm		NVARCHAR(50),	
		Resource_fr		NVARCHAR(50),	
		Resource_ru		NVARCHAR(64),	
		Resource_pt		NVARCHAR(50),	
		Resource_de		NVARCHAR(50),
		RowNum          INT
	)

	INSERT INTO #Tmp
	(
			   RefId,		
			   ResourceId,
			   Resource_en,
			   Resource_ch,
			   Resource_cs,
			   Resource_jp,
			   Resource_it,
			   Resource_th,
			   Resource_ko,
			   Resource_es,
			   Sort1,		
			   Sort2,		
			   Resource_el,
			   Resource_vn,
			   Resource_pl,
			   Resource_id,
			   Resource_hi,
			   Resource_mm,
			   Resource_fr,
			   Resource_ru,
			   Resource_pt,
			   Resource_de,
			   RowNum   	
	)
    SELECT     RefId,		
			   ResourceId,
			   Resource_en,
			   Resource_ch,
			   Resource_cs,
			   Resource_jp,
			   Resource_it,
			   Resource_th,
			   Resource_ko,
			   Resource_es,
			   Sort1,		
			   Sort2,		
			   Resource_el,
			   Resource_vn,
			   Resource_pl,
			   Resource_id,
			   Resource_hi,
			   Resource_mm,
			   Resource_fr,
			   Resource_ru,
			   Resource_pt,
			   Resource_de,
			   ROW_NUMBER() OVER(ORDER BY RefId, ResourceId) AS RowNum
	FROM dbo.RefResource WITH(NOLOCK)
	WHERE (RefId LIKE '%' + @RefId + '%' OR ISNULL(@RefId,'') = '') 
		  AND (ResourceId = @ResourceId OR ISNULL(@ResourceId,'') = '')
		  AND (Resource_en LIKE '%' + @ResourceEN + '%' OR ISNULL(@ResourceEN,'') = '')
		  AND (RefId <> 'N7_Bettype')

	ORDER BY RefId, ResourceId

	SELECT @TotalRows = COUNT(*) FROM #Tmp 
	
	SELECT  RefId,		
			ResourceId,
			Resource_en,
			Resource_ch,
			Resource_cs,
			Resource_jp,
			Resource_it,
			Resource_th,
			Resource_ko,
			Resource_es,
			Sort1,		
			Sort2,		
			Resource_el,
			Resource_vn,
			Resource_pl,
			Resource_id,
			Resource_hi,
			Resource_mm,
			Resource_fr,
			Resource_ru,
			Resource_pt,
			Resource_de,
			RowNum   	
	FROM #Tmp
	WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNum BETWEEN @RowStart AND @RowEnd)

	DROP TABLE #Tmp
 
END

