/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_SportBettypeMatrix_Sel
	@SportType      SMALLINT = NULL,
	@BetType        SMALLINT = NULL,
	@ProductId      TINYINT  = NULL,
	@EventType      TINYINT  = NULL,
	@RefTable       TINYINT  = NULL,
	@PageSize		INT = 0,
	@PageIndex		INT = 0,
	@TotalRows		INT = 0 OUTPUT
AS

/*
Created: 20200416@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200416@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
		
*/

BEGIN
    SET NOCOUNT ON
	
	DECLARE @RowStart INT, @RowEnd INT

	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #Tmp (
	 	SportType		SMALLINT,
		BetType			SMALLINT,
		IsLive			BIT,
		ProductID		TINYINT,
		Enabled			BIT,
		IsTest			BIT,
		EventType		TINYINT,
		SubProduct		VARCHAR(500),
		RefTable		TINYINT,
		RowNum          INT
	)

	INSERT INTO #Tmp(
			   SportType,
			   BetType,
			   IsLive,
			   ProductID,
			   Enabled,
			   IsTest,
			   EventType,
			   SubProduct,
			   RefTable,
			   RowNum
	)
    SELECT     SportType,
			   BetType,
			   IsLive,
			   ProductID,
			   Enabled,
			   IsTest,
			   EventType,
			   SubProduct,
			   RefTable,			   
			   ROW_NUMBER() OVER(ORDER BY SportType, Bettype, IsLive) AS RowNum
	FROM dbo.SportBettypeMatrix WITH(NOLOCK)
	WHERE (SportType = @Sporttype OR ISNULL(@Sporttype,0) = 0) 
		  AND (BetType		= @BetType		OR ISNULL(@BetType,0)   = 0)
		  AND (ProductID	= @ProductId	OR ISNULL(@ProductId,0) = 0)
		  AND (EventType	= @EventType	OR ISNULL(@EventType,0) = 0)
		  AND (RefTable		= @RefTable		OR ISNULL(@RefTable,0)	= 0)


	ORDER BY SportType, BetType, IsLive

	SELECT @TotalRows = COUNT(*) FROM #Tmp 
	
	SELECT  SportType,
			BetType,
			IsLive,
			ProductID,
			Enabled,
			IsTest,
			EventType,
			SubProduct,
			RefTable,
			RowNum
	FROM #Tmp
	WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNum BETWEEN @RowStart AND @RowEnd)

	DROP TABLE #Tmp
 
END

