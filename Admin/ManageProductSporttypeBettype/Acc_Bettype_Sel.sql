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

	CREATE TABLE #Tmp (
	    typeid          INT,
		typenamee       NVARCHAR(128),
		typenamec		NVARCHAR(128),
		typedesc		NVARCHAR(128),
		creator         INT,
		typenamec_uni	NVARCHAR(128),
		typenamej		NVARCHAR(128),
		typenamcn		NVARCHAR(128),
		typenamecn		NVARCHAR(128),
		typenameth		NVARCHAR(128),
		typenameit		NVARCHAR(128),
		typenameko		NVARCHAR(128),
		typenameES		NVARCHAR(128),
		typenameVN		NVARCHAR(128),
		typenameEL		NVARCHAR(128),
		typenamee_Eu	NVARCHAR(128),
		typenameRU		NVARCHAR(128),
		typenameID		NVARCHAR(128),
		typenamePT		NVARCHAR(128),
		typenameFR		NVARCHAR(128),
		ParentTypeid	INT,
		typenameMMR		NVARCHAR(128),
		typenameHI		NVARCHAR(128),
		DisplayedTypeID INT,
		RowNum INT)

	INSERT INTO #Tmp(
	        typeid,
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
			ParentTypeid,
			typenameMMR,
			typenameHI,
			DisplayedTypeID, 
			RowNum
	)
    SELECT	typeid,
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
			ParentTypeid,
			typenameMMR,
			typenameHI,
			DisplayedTypeID, 
			ROW_NUMBER() OVER(ORDER BY TypeID) AS RowNum   
	FROM bettype WITH(NOLOCK)
	WHERE (typeid = @TypeId OR ISNULL(@TypeId,0) = 0) 
	      AND (typenamee LIKE '%' + @TypeNamee + '%' OR ISNULL(@TypeNamee,'') = '')

	ORDER BY typeid

	SELECT @TotalRows = COUNT(*) FROM #Tmp

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
	WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNum BETWEEN @RowStart AND @RowEnd) 
	
	DROP TABLE #Tmp

END

