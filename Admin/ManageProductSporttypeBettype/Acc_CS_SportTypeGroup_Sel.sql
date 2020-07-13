/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CS_SportType_Sel]
	@ProductId TINYINT 
AS

/*
	Created: 20200713@Malcolm
	DB: DBPRO.bodb02
	Task: Get Sports List

	Revisions:
		- 20200713@Malcolm: Initialize SP [RedmineID: #131241]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SporttypeGroup TABLE (ProductID TINYINT,SportTypeGroup SMALLINT,DisplaySport NVARCHAR(MAX), DisplaySportName NVARCHAR(MAX))

	SELECT @ProductId = ISNULL(@ProductId,0)

	INSERT INTO @SporttypeGroup
	(
		ProductID,
		SportTypeGroup,
		DisplaySport,
		DisplaySportName
	)
	EXEC dbo.CS_SportType_Sel

	SELECT DISTINCT SportTypeGroup,DisplaySportName
	FROM @SporttypeGroup
	WHERE (ProductID = 1 AND @ProductId = 1) 
		OR (ProductID IS NULL AND @ProductId <> 1)

END
GO