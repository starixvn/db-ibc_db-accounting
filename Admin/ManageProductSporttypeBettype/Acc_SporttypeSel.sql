/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_SporttypeSel
	@Sporttype tinyint = NULL,
	@SportName nvarchar(100) = NULL,
	@PageSize		INT = 20,
	@PageIndex		INT = 1
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

    IF @Sporttype IS NULL
	BEGIN
	    ;WITH CTE AS (
			SELECT *,ROW_NUMBER() OVER(ORDER BY SportName) RowNum
			FROM Sports WITH(NOLOCK)
			WHERE SportName LIKE '%' +@SportName +'%'
		)
		SELECT SportType ,SportName ,SportNameCh ,SportNameCs ,SportNameJp ,SportNameIt ,
		       SportNameTh ,ParlayMaxPayout ,SportNameKo ,SportNameES ,SportNameVN ,SportNameEL ,
			   SportNameRU ,SportNameID ,SportNamePT ,SportNameFR ,SportNameMMR ,SportNamePL ,SportNameHI
		FROM CTE
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
		
	END
	ELSE
	BEGIN
	    ;WITH CTE AS(
			SELECT *,ROW_NUMBER() OVER(ORDER BY SportType) RowNum
			FROM Sports WITH(NOLOCK)
			WHERE SportType = @Sporttype
		)
		SELECT SportType ,SportName ,SportNameCh ,SportNameCs ,SportNameJp ,SportNameIt ,
		       SportNameTh ,ParlayMaxPayout ,SportNameKo ,SportNameES ,SportNameVN ,SportNameEL ,
			   SportNameRU ,SportNameID  ,SportNamePT ,SportNameFR ,SportNameMMR ,SportNamePL ,SportNameHI
		FROM CTE 
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
		
	END 
END

