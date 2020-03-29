/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.BettypeSel
	@TypeId tinyint = NULL,
	@TypeNamee nvarchar(100) = NULL,
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

	DECLARE @RowStart INT , @RowEnd INT 

	SELECT @PageIndex = @PageIndex - 1, @RowStart =  @PageIndex * @PageSize, @RowEnd = @RowStart + @PageSize - 1
	
    IF @TypeId IS NULL
	BEGIN
	   ;WITH CTE AS (
			SELECT ROW_NUMBER() OVER(ORDER BY typenamee) RowNum, *
	     	FROM  bettype WITH(NOLOCK)
	     	WHERE typenamee LIKE '%' +@TypeNamee +'%'
	   )
	   SELECT  typeid ,typenamee,typenamec,typedesc,creator,typenamec_uni,typenamej,typenamcn,
               typenamecn,typenameth,typenameit,typenameko,typenameES,typenameVN,typenameEL,typenamee_Eu,
               typenameRU,typenameID,typenamePT,typenameFR,ParentTypeid,typenameMMR,typenameHI,DisplayedTypeID
	   FROM CTE
	   WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
	ELSE
	BEGIN
	    ;WITH CTE AS(
			SELECT ROW_NUMBER() OVER(ORDER BY typeid) RowNum, *			   
			FROM bettype WITH(NOLOCK)
			WHERE typeid = @TypeId 
		)
		SELECT typeid ,typenamee,typenamec,typedesc,creator,typenamec_uni,typenamej,typenamcn,
               typenamecn,typenameth,typenameit,typenameko,typenameES,typenameVN,typenameEL,typenamee_Eu,
               typenameRU,typenameID,typenamePT,typenameFR,ParentTypeid,typenameMMR,typenameHI,DisplayedTypeID
		FROM CTE
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
		
	END 
END

