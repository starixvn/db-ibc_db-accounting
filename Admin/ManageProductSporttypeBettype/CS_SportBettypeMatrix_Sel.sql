/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.CS_SportBettypeMatrix_Sel
    @ProductID      VARCHAR(200) = '', 
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

	CREATE TABLE #SportTypeGroup
	(
		ProductID			INT,
		SportTypeGroup		SMALLINT,
		DisplaySport		VARCHAR(100),
		DisplaySportName	VARCHAR(200)
	)

	CREATE TABLE #Tmp 
	(
	    ProductID			TINYINT,
		ProductName			VARCHAR(50),
	 	SportType			SMALLINT,
		SportName			NVARCHAR(100),
		Bettype				SMALLINT,
		BettypeName			NVARCHAR(256),
		IsLive				BIT,
		Enabled				BIT,
		IsTest				BIT,
		EventType			TINYINT,
		SubProduct			VARCHAR(500),
		RefTable			TINYINT,
		SportTypeGroup		SMALLINT,
		BetTypeGroup		SMALLINT,
		SportTypeGroupName  VARCHAR(200),
		BetTypeGroupName    VARCHAR(100),
		RowNum				INT
	)

	INSERT INTO #SportTypeGroup
	(
		ProductID,
		SportTypeGroup,
		DisplaySport,
		DisplaySportName
	)
	EXEC dbo.CS_SportType_Sel

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
				SportTypeGroup,
				BetTypeGroup,
				SportTypeGroupName,
				BetTypeGroupName,
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
				m.SportTypeGroup,
				m.BetTypeGroup,				
				sg.DisplaySportName,
				bg.typenamee,
			   ROW_NUMBER() OVER(ORDER BY m.ProductID, m.SportType, m.Bettype, m.IsLive) AS RowNum
	FROM dbo.CS_SportBettypeMatrix m WITH(NOLOCK)
		INNER JOIN dbo.Products p WITH(NOLOCK) ON m.ProductID = p.ProductID
		INNER JOIN dbo.Sports s WITH(NOLOCK) ON m.SportType = s.SportType 
		INNER JOIN dbo.bettype b WITH(NOLOCK) ON m.BetType = b.typeid
		INNER JOIN dbo.bettype bg WITH(NOLOCK) ON bg.typeid = m.BetTypeGroup
		INNER JOIN #SportTypeGroup sg WITH(NOLOCK) ON sg.SportTypeGroup = m.SportTypeGroup

	WHERE (',' + @ProductID + ',' LIKE '%,' + CONVERT(VARCHAR(4), m.ProductID) + ',%' OR @ProductID = '') 
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
			SportTypeGroup,
			BetTypeGroup,
			SportTypeGroupName,
			BetTypeGroupName,
			RowNum 
	FROM #Tmp
	WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNum BETWEEN @RowStart AND @RowEnd)

	DROP TABLE #Tmp
 
END

