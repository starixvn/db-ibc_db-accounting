/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_SportBettypeMatrix_Sel
    @ProductID      VARCHAR(200) = 'All', 
	@SportType      TINYINT = NULL,
	@BetType        INT = NULL,
	@EventType      TINYINT  = NULL,
	@RefTable       TINYINT  = NULL,
	@SportName      NVARCHAR(50)  = '',
	@BettypeName    NVARCHAR(128) = '',
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

	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1, @ProductID = ISNULL(@ProductID,'')

	CREATE TABLE #Tmp (
	    ProductID		TINYINT,
		ProductName     VARCHAR(50),
	 	SportType		SMALLINT,
		SportName       NVARCHAR(100),
		Bettype			SMALLINT,
		BettypeName     NVARCHAR(256),
		IsLive			BIT,
		Enabled			BIT,
		IsTest			BIT,
		EventType		TINYINT,
		SubProduct		VARCHAR(500),
		RefTable		TINYINT,
		RowNum          INT
	)

	INSERT INTO #Tmp
	(
				ProductID,
				ProductName,
	 			SportType,
				SportName,
				Bettype,
				BettypeName,
				IsLive,
				Enabled,
				IsTest,
				EventType,
				SubProduct,
				RefTable,
				RowNum 
	)
    SELECT      m.ProductID,
				p.ProductName,
	 			m.SportType,
				s.SportName,
				m.Bettype,
				b.typenamee AS BettypeName,
				m.IsLive,
				m.Enabled,
				m.IsTest,
				m.EventType,
				m.SubProduct,
				m.RefTable,		   
			   ROW_NUMBER() OVER(ORDER BY m.ProductID, m.SportType, m.Bettype, m.IsLive) AS RowNum
	FROM dbo.SportBettypeMatrix m WITH(NOLOCK)
		INNER JOIN dbo.Products p WITH(NOLOCK) ON m.ProductID = p.ProductID
		INNER JOIN dbo.Sports s WITH(NOLOCK) ON m.SportType = s.SportType 
		INNER JOIN dbo.bettype b WITH(NOLOCK) ON m.BetType = b.typeid
	WHERE (',' + @ProductID + ',' LIKE '%,' + CONVERT(VARCHAR(4), m.ProductID) + ',%'	OR @ProductID = 'All') 
		  AND (m.SportType	= @Sporttype	OR @Sporttype IS NULL) 
		  AND (m.BetType	= @BetType		OR @BetType IS NULL)
		  AND (m.EventType	= @EventType	OR @EventType IS NULL)
		  AND (m.RefTable	= @RefTable		OR @RefTable IS NULL)
		  AND (s.SportName	= '' OR s.SportName LIKE '%' + @SportName + '%')
		  AND (b.typenamee	= '' OR b.typenamee LIKE '%' + @BettypeName + '%')
	ORDER BY m.ProductID, m.SportType, m.BetType, m.IsLive

	SELECT @TotalRows = COUNT(*) FROM #Tmp 
	
	SELECT  ProductID,
			ProductName,
	 		SportType,
			SportName,
			Bettype,
			BettypeName,
			IsLive,
			[Enabled],
			IsTest,
			EventType,
			SubProduct,
			RefTable,
			RowNum 
	FROM #Tmp
	WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNum BETWEEN @RowStart AND @RowEnd)

	DROP TABLE #Tmp
 
END

