/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_Bettype_Sel
	@TypeId		INT = NULL,
	@TypeNamee	NVARCHAR(100) = NULL,
	@PageSize	INT = 0,
	@PageIndex	INT = 0,
	@TotalRows	INT = 0 OUTPUT

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

	DECLARE @RowStart INT , @RowEnd INT

	SELECT @PageIndex = @PageIndex - 1, @RowStart =  @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1
	
    SELECT *, ROW_NUMBER() OVER(ORDER BY TypeID) AS RowNum
    INTO #Tmp
	FROM bettype WITH(NOLOCK)
	WHERE (typeid = @TypeId OR ISNULL(@TypeId,'') = '') 
	      AND (typenamee LIKE '%' + @TypeNamee + '%' OR ISNULL(@TypeNamee,'') = '')

	ORDER BY typeid

	SELECT @TotalRows = COUNT(*) FROM #Tmp

	IF @PageIndex < 0 OR @PageSize <= 0
		SELECT  typeid, 
		        ParentTypeid,
				DisplayedTypeID,
				typenamee,
				typenamec,
				typedesc,
				creator,
				typenamec_uni,
				typenamej,
				typenamcn,
				typenamecn,
				typenameth,
				typenameit,
				typenameko,
				typenameES,
				typenameVN,
				typenameEL,
				typenamee_Eu,
				typenameRU,
				typenameID,
				typenamePT,
				typenameFR,				
				typenameMMR,
				typenameHI,
				RowNum
		FROM #Tmp 
	ELSE 
	BEGIN
	    SELECT  typeid, 
		        ParentTypeid,
				DisplayedTypeID,
				typenamee,
				typenamec,
				typedesc,
				creator,
				typenamec_uni,
				typenamej,
				typenamcn,
				typenamecn,
				typenameth,
				typenameit,
				typenameko,
				typenameES,
				typenameVN,
				typenameEL,
				typenamee_Eu,
				typenameRU,
				typenameID,
				typenamePT,
				typenameFR,				
				typenameMMR,
				typenameHI,
				RowNum
		 FROM #Tmp
		 WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END 

	DROP TABLE #Tmp

END

