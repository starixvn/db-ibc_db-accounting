/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_Sporttype_Sel
	@Sporttype tinyint = NULL,
	@SportName nvarchar(50) = NULL,
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

    SELECT *, ROW_NUMBER() OVER(ORDER BY SportType) AS RowNum
	INTO #Tmp
	FROM Sports WITH(NOLOCK)
	WHERE (SportType = @Sporttype OR ISNULL(@Sporttype,'') = '') 
		  AND (SportName LIKE '%' + @SportName +'%' OR ISNULL(@SportName,'') = '')
	ORDER BY SportType

	IF @PageIndex <= 0 OR @PageSize <= 0
	BEGIN
		SELECT *
		FROM #Tmp
	END 
	ELSE
	BEGIN
		SELECT *
		FROM #Tmp
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END

	DROP TABLE #Tmp
 
END

