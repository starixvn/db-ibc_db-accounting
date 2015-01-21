ALTER PROCEDURE [dbo].[Lrf_LicenseeBetSettingSel] 
	@CustID INT
	,@Product INT
AS
/*
	Created: Elodie
	Date: 20150121
	Task : Licensee Setting Configuration - Get bet setting information [#6304]
	DB: DBAGE/bodb02
	Original:

	Revisions:

	Param's Explanation:
		@Product:	1: Sportbook
					161: Number Game
					180: Virtual sport
					151: Horse Racing
					202: Keno
		
*/ 
BEGIN
	SET NOCOUNT ON
	DECLARE @downlines BIT
	SELECT @downlines = CASE WHEN EXISTS (SELECT TOP 1 1 FROM custinfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3) THEN 1 ELSE 0 END

	IF @Product = 1 --Sportbook
	BEGIN
		DECLARE @MinBetv1			MONEY,  
				@MinBetv2			MONEY,  
				@MinBetv3			MONEY,  
				@MinBetv5			MONEY,  
				@MinBetv8			MONEY,  
				@MinBetv10			MONEY,  
				@MinBetv11			MONEY,  
				@MinBetv99			MONEY,  
				@MinBetv99MP		MONEY,

				@MaxBetv1			MONEY,
				@MaxBetv2			MONEY,
				@MaxBetv3			MONEY,
				@MaxBetv5			MONEY,
				@MaxBetv8			MONEY,
				@MaxBetv10			MONEY,
				@MaxBetv11			MONEY,
				@MaxBetv99			MONEY,
				@MaxBetv99MP		MONEY,

				@MaxPerMatchv1		MONEY,
				@MaxPerMatchv2		MONEY,
				@MaxPerMatchv3		MONEY,
				@MaxPerMatchv5		MONEY,
				@MaxPerMatchv8		MONEY,
				@MaxPerMatchv10		MONEY,
				@MaxPerMatchv11		MONEY,		
				@MaxPerMatchv99		MONEY,
				@MaxPerMatchv99MP	MONEY
		
		SELECT @MinBetv1 = MinBet, @MaxBetv1 = MaxBet FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype =  1 and cs.sporttype=1
		SELECT @MinBetv2 = MinBet, @MaxBetv2 = MaxBet FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype = 1 and cs.sporttype=2
		SELECT @MinBetv3 = MinBet, @MaxBetv3 = MaxBet FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype = 1 and cs.sporttype=3
		SELECT @MinBetv5 = MinBet, @MaxBetv5 = MaxBet FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype = 1 and cs.sporttype=5
		SELECT @MinBetv8 = MinBet, @MaxBetv8 = MaxBet FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype = 1 and cs.sporttype=8
		SELECT @MinBetv10 = MinBet, @MaxBetv10 = MaxBet FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype = 1 and cs.sporttype=10
		SELECT @MinBetv11 = MinBet, @MaxBetv11 = MaxBet FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype = 1 and cs.sporttype=11
		SELECT @MinBetv99 = MinBet, @MaxBetv99 = MaxBet FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype = 1 and cs.sporttype=99
		SELECT @MinBetv99MP = MinBet, @MaxBetv99MP = MaxBet FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype = 9 and cs.sporttype=99

		SELECT  @MinBetv1			AS MinBetv1,
				@MinBetv2			AS MinBetv2,
				@MinBetv3			AS MinBetv3,
				@MinBetv5			AS MinBetv5,
				@MinBetv8			AS MinBetv8,
				@MinBetv10			AS MinBetv10,
				@MinBetv11			AS MinBetv11,	
				@MinBetv99			AS MinBetv99,
				@MinBetv99MP		AS MinBetv99MP,
		
				@MaxBetv1			AS MaxBetv1,
				@MaxBetv2			AS MaxBetv2,
				@MaxBetv3			AS MaxBetv3,
				@MaxBetv5			AS MaxBetv5,
				@MaxBetv8			AS MaxBetv8,
				@MaxBetv10			AS MaxBetv10,
				@MaxBetv11			AS MaxBetv11,	
				@MaxBetv99			AS MaxBetv99,
				@MaxBetv99MP		AS MaxBetv99MP,
		
				ci.MaxPerMatch		AS MaxPerMatchv1,			
				ci.MaxPerMatch2		AS MaxPerMatchv2,			
				ci.MaxPerMatch3		AS MaxPerMatchv3,			
				ci.MaxPerMatch5		AS MaxPerMatchv5,			
				ci.MaxPerMatch8		AS MaxPerMatchv8,			
				ci.MaxPerMatch10	AS MaxPerMatchv10,			
				ci.MaxPerMatch11	AS MaxPerMatchv11,			
				ci.MaxPerMatch99	AS MaxPerMatchv99,			
				ci.MaxPerMatch99MP	AS MaxPerMatchv99MP
		FROM CustInfo AS ci WITH (NOLOCK)
		WHERE ci.custid = @CustID

	END
	
	IF @Product = 161 --Number Game 
	BEGIN
		DECLARE @MinBetv161			MONEY,
				@MaxBetv161			MONEY,
				@MaxPerMatchv161	MONEY,	
				@MaxPerBallv161		MONEY

		SELECT @MinBetv161 = MinBet, @MaxBetv161 = MaxBet FROM Dep_CustSetting3rd AS cs WITH (NOLOCK)	WHERE cs.custid = @CustID and cs.bettype = 81 and cs.sporttype=161
		SELECT	@MinBetv161			AS MinBetv161,
				@MaxBetv161			AS MaxBetv161,
				ci.MaxPerMatch161	AS MaxPerMatchv161,		
				ci.MaxPerBall161	AS MaxPerBallv161
		FROM CustInfo AS ci WITH (NOLOCK)
		WHERE ci.custid = @CustID
	END

	IF @Product = 151 --Horse Racing
	BEGIN
		DECLARE @v151MinBet_31			MONEY,
				@v151MinBet_41			MONEY,
				@v151MinBet_51			MONEY,
				@v152MinBet_41			MONEY,
				@v152MinBet_51			MONEY,
				@v153MinBet_51			MONEY,

				@v151MaxBet_31			MONEY,
				@v151MaxBet_41			MONEY,
				@v151MaxBet_51			MONEY,
				@v152MaxBet_41			MONEY,
				@v152MaxBet_51			MONEY,
				@v153MaxBet_51			MONEY,

				@v151MaxPerMatch_31		MONEY,
				@v151MaxPerMatch_41		MONEY,
				@v151MaxPerMatch_51		MONEY,
				@v152MaxPerMatch_41		MONEY,
				@v152MaxPerMatch_51		MONEY,
				@v153MaxPerMatch_51		MONEY,

				@DisableDownlines151_31 BIT,
				@DisableDownlines151_41 BIT,
				@DisableDownlines151_51 BIT,
				@DisableDownlines152_41 BIT,
				@DisableDownlines152_51 BIT,
				@DisableDownlines153_51 BIT				
								 
		SELECT TOP 1 @DisableDownlines151_31 = ISNULL(DisableHorseRacing,0) FROM custinfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableHorseRacing = 1
		SELECT TOP 1 @DisableDownlines151_41 = ISNULL(DisableOpenTote,0) FROM custinfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND DisableOpenTote = 1
		SELECT TOP 1 @DisableDownlines151_51 = ISNULL(Disable151_AU,0) FROM custinfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND Disable151_AU = 1
		SELECT TOP 1 @DisableDownlines152_41 = ISNULL(Disable152_UK,0) FROM custinfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND Disable152_UK = 1
		SELECT TOP 1 @DisableDownlines152_51 = ISNULL(Disable152_AU,0) FROM custinfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND Disable152_AU = 1
		SELECT TOP 1 @DisableDownlines153_51 = ISNULL(Disable153_AU,0) FROM custinfo WITH(NOLOCK) WHERE srecommend = @custid AND roleid = 3 AND Disable153_AU = 1
		

		SELECT @v151MinBet_31 = MinBet, @v151MaxBet_31 = MaxBet FROM Dep_CustSetting3rd AS cs WITH (NOLOCK) WHERE cs.custid = @CustID AND cs.bettype = 31 AND cs.sporttype=151
		SELECT @v151MinBet_41 = MinBet, @v151MaxBet_41 = MaxBet FROM Dep_CustSetting3rd AS cs WITH (NOLOCK) WHERE cs.custid = @CustID AND cs.bettype = 41 AND cs.sporttype=151
		SELECT @v151MinBet_51 = MinBet, @v151MaxBet_51 = MaxBet FROM Dep_CustSetting3rd AS cs WITH (NOLOCK) WHERE cs.custid = @CustID AND cs.bettype = 51 AND cs.sporttype=151
		SELECT @v152MinBet_41 = MinBet, @v152MaxBet_41 = MaxBet FROM Dep_CustSetting3rd AS cs WITH (NOLOCK) WHERE cs.custid = @CustID AND cs.bettype = 41 AND cs.sporttype=152
		SELECT @v152MinBet_51 = MinBet, @v152MaxBet_51 = MaxBet FROM Dep_CustSetting3rd AS cs WITH (NOLOCK) WHERE cs.custid = @CustID AND cs.bettype = 51 AND cs.sporttype=152
		SELECT @v153MinBet_51 = MinBet, @v153MaxBet_51 = MaxBet FROM Dep_CustSetting3rd AS cs WITH (NOLOCK) WHERE cs.custid = @CustID AND cs.bettype = 51 AND cs.sporttype=153

		SELECT  @v151MinBet_31			AS v151MinBet_31,
				@v151MinBet_41			AS v151MinBet_41,
				@v151MinBet_51			AS v151MinBet_51,
				@v152MinBet_41			AS v152MinBet_41,
				@v152MinBet_51			AS v152MinBet_51,
				@v153MinBet_51			AS v153MinBet_51,

				@v151MaxBet_31			AS v151MaxBet_31,
				@v151MaxBet_41			AS v151MaxBet_41,
				@v151MaxBet_51			AS v151MaxBet_51,
				@v152MaxBet_41			AS v152MaxBet_41,
				@v152MaxBet_51			AS v152MaxBet_51,
				@v153MaxBet_51			AS v153MaxBet_51,

				ci.MaxPerMatch151		AS v151MaxPerMatch_31,		
				ci.MaxPerMatch151_OT	AS v151MaxPerMatch_41,		
				ci.MaxPerMatch151_AU	AS v151MaxPerMatch_51,		
				ci.MaxPerMatch152_UK	AS v152MaxPerMatch_41,		
				ci.MaxPerMatch152_AU	AS v152MaxPerMatch_51,		
				ci.MaxPerMatch153_AU	AS v153MaxPerMatch_51,		
		
				ci.DisableHorseRacing	AS Disable151_31,
				ci.DisableOpenTote		AS Disable151_41,
				ci.Disable151_AU		AS Disable151_51,
				ci.Disable152_UK		AS Disable152_41,
				ci.Disable152_AU		AS Disable152_51,
				ci.Disable153_AU		AS Disable153_51,
				
				CASE WHEN @downlines = 0 THEN ci.DisableHorseracing ELSE ISNULL(@DisableDownlines151_31,0) END AS DisableDownlines151_31,
				CASE WHEN @downlines = 0 THEN ci.DisableOpenTote ELSE ISNULL(@DisableDownlines151_41,0) END AS DisableDownlines151_41,
				CASE WHEN @downlines = 0 THEN ci.Disable151_AU ELSE ISNULL(@DisableDownlines151_51,0) END AS DisableDownlines151_51,
				CASE WHEN @downlines = 0 THEN ci.Disable152_UK ELSE ISNULL(@DisableDownlines152_41,0) END AS DisableDownlines152_41,
				CASE WHEN @downlines = 0 THEN ci.Disable152_AU ELSE ISNULL(@DisableDownlines152_51,0) END AS DisableDownlines152_51,
				CASE WHEN @downlines = 0 THEN ci.Disable153_AU ELSE ISNULL(@DisableDownlines153_51,0) END AS DisableDownlines153_51
		FROM CustInfo AS ci WITH (NOLOCK)
		WHERE ci.custid = @CustID
	END

	IF @Product = 180 --Virtual Sports
	BEGIN
		DECLARE @MinBetv180			MONEY,
				@MaxBetv180			MONEY,
				@MaxPerMatchv180	MONEY, 
		
				@MinBetv181			MONEY,
				@MaxBetv181			MONEY,
				@MaxPerMatchv181	MONEY,
		
				@MinBetv182			MONEY,
				@MaxBetv182			MONEY,
				@MaxPerMatchv182	MONEY,
		
				@MinBetv183			MONEY,
				@MaxBetv183			MONEY,
				@MaxPerMatchv183	MONEY,
		
				@MinBetv184			MONEY,
				@MaxBetv184			MONEY,
				@MaxPerMatchv184	MONEY,
		
				@MinBetv185			MONEY,
				@MaxBetv185			MONEY,
				@MaxPerMatchv185	MONEY,
		
				@MinBetv186			MONEY,
				@MaxBetv186			MONEY,
				@MaxPerMatchv186	MONEY
		
		DECLARE @DisableDownlinesVirtualSports	BIT
		
		SELECT TOP 1 @DisableDownlinesVirtualSports = ISNULL(DisableVirtualSports,0) 
		FROM custinfo WITH (NOLOCK) 
		WHERE srecommend = @custid and roleid = 3 and DisableVirtualSports = 1

		SELECT @MinBetv180 = cs3.minbet, @MaxBetv180 = cs3.maxbet FROM Dep_CustSetting3rd cs3 WITH(NOLOCK) where cs3.custid = @CustID AND cs3.sporttype = 180 AND cs3.bettype = 1201
		SELECT @MinBetv181 = cs3.minbet, @MaxBetv181 = cs3.maxbet FROM Dep_CustSetting3rd cs3 WITH(NOLOCK) where cs3.custid = @CustID AND cs3.sporttype = 181 AND cs3.bettype = 1231
		SELECT @MinBetv182 = cs3.minbet, @MaxBetv182 = cs3.maxbet FROM Dep_CustSetting3rd cs3 WITH(NOLOCK) where cs3.custid = @CustID AND cs3.sporttype = 182 AND cs3.bettype = 1231
		SELECT @MinBetv183 = cs3.minbet, @MaxBetv183 = cs3.maxbet FROM Dep_CustSetting3rd cs3 WITH(NOLOCK) where cs3.custid = @CustID AND cs3.sporttype = 183 AND cs3.bettype = 1231
		SELECT @MinBetv184 = cs3.minbet, @MaxBetv184 = cs3.maxbet FROM Dep_CustSetting3rd cs3 WITH(NOLOCK) where cs3.custid = @CustID AND cs3.sporttype = 184 AND cs3.bettype = 1231
		SELECT @MinBetv185 = cs3.minbet, @MaxBetv185 = cs3.maxbet FROM Dep_CustSetting3rd cs3 WITH(NOLOCK) where cs3.custid = @CustID AND cs3.sporttype = 185 AND cs3.bettype = 1231
		SELECT @MinBetv186 = cs3.minbet, @MaxBetv186 = cs3.maxbet FROM Dep_CustSetting3rd cs3 WITH(NOLOCK) where cs3.custid = @CustID AND cs3.sporttype = 186 AND cs3.bettype = 1220

		SELECT	@MinBetv180						AS MinBetv180,		
				@MinBetv181						AS MinBetv181,	
				@MinBetv182						AS MinBetv182,		
				@MinBetv183						AS MinBetv183,		
				@MinBetv184						AS MinBetv184,		
				@MinBetv185						AS MinBetv185,	
				@MinBetv186						AS MinBetv186,	

				@MaxBetv180						AS MaxBetv180,		
				@MaxBetv181						AS MaxBetv181,		
				@MaxBetv182						AS MaxBetv182,		
				@MaxBetv183						AS MaxBetv183,		
				@MaxBetv184						AS MaxBetv184,		
				@MaxBetv185						AS MaxBetv185,		
				@MaxBetv186						AS MaxBetv186,		

				ci.MaxPerMatch180				AS MaxPerMatchv180, 	
				ci.MaxPerMatch181				AS MaxPerMatchv181,
				ci.MaxPerMatch182				AS MaxPerMatchv182,
				ci.MaxPerMatch183				AS MaxPerMatchv183,
				ci.MaxPerMatch184				AS MaxPerMatchv184,	
				ci.MaxPerMatch185				AS MaxPerMatchv185,	
				ci.MaxPerMatch186				AS MaxPerMatchv186,

				ISNULL(DisableVirtualSports,0)	AS DisableVirtualSports,
				ISNULL(HideVirtualSports,0)		AS HideVirtualSports,
				CASE WHEN @downlines = 0 THEN DisableVirtualSports ELSE ISNULL(@DisableDownlinesVirtualSports,0) END AS DisableDownlinesVirtualSports		
		FROM CustInfo AS ci WITH (NOLOCK)
		WHERE ci.custid = @CustID
	END

	IF @Product = 202 --Keno
	BEGIN
		DECLARE @GameType TABLE (GameTypeID INT, IBCBetTypeID INT)
		INSERT INTO @GameType (GameTypeID, IBCBetTypeID)
		SELECT GameTypeID, IBCBetTypeID FROM GameType WITH (NOLOCK) WHERE IBCBetTypeID BETWEEN 1501 AND 1599 AND IsDisabled = 0

		DECLARE @DisableDownlinesKeno TABLE (GameTypeID INT, DisableDownlines BIT)
		INSERT INTO @DisableDownlinesKeno (GameTypeID, DisableDownlines)
		SELECT cg.GameTypeID, CASE WHEN SUM(CASE WHEN cg.IsDisabled = 1 THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END
		FROM dbo.CustGameType cg WITH (NOLOCK)
			INNER JOIN @GameType gt ON cg.GameTypeID = gt.GameTypeID
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON cg.CustID = ci.CustID
		WHERE ci.srecommend = @CustID AND ci.roleid = 3
		GROUP BY cg.GameTypeID	

		SELECT	gt.IBCBetTypeID, 
				cg.MinBet, 
				cg.MaxBet, 
				cg.MaxPerGameType, 
				cg.IsDisabled, 
				CASE WHEN @downlines = 0 then cg.IsDisabled ELSE ISNULL(d.DisableDownlines,1) END AS DisableDownlinesKeno
		FROM dbo.CustGameType cg WITH (NOLOCK)
			INNER JOIN @GameType gt ON cg.GameTypeID = gt.GameTypeID
			LEFT JOIN @DisableDownlinesKeno d ON cg.GameTypeID = d.GameTypeID
		WHERE cg.CustID = @CustID
		ORDER BY gt.IBCBetTypeID
		--DECLARE @KenoList NVARCHAR(MAX) = ''
		--SELECT	gt.IBCBetTypeID bettype,
		--		ISNULL(Minbet,0) AS Minbet,
		--		ISNULL(MaxBet,0) AS MaxBet,
		--		ISNULL(MaxPerGameType,0) AS MaxPerMatch,
		--		ISNULL(cgt.isDisabled,1) AS isDisabled
		--INTO #data
		--FROM dbo.CustGameType cgt WITH (NOLOCK) 
		--	INNER JOIN dbo.GameType gt with (nolock) ON cgt.GameTypeID = gt.GameTypeID
		--WHERE Custid=@CustID 

		--SELECT @KenoList = @KenoList +'<products>'

		--DECLARE @i INT =1501, @j INT = (SELECT max(bettype) FROM #data)

		--WHILE (@i<=@j)
		--BEGIN
		--	SELECT @KenoList = @KenoList+'<product BetType = "'+coalesce(cast(Bettype as varchar(50)),space(1))+ '" ' 
		--								+'MaxBet = "'+coalesce(cast(MaxBet as varchar(50)),space(1))+ '" ' 
		--								+'MinBet = "'+coalesce(cast(MinBet as varchar(50)),space(1))+ '" ' 
		--								+'MaxPerMatch = "'+ coalesce(cast(MaxPerMatch as varchar(50)),space(1)) + '" ' +
		--								+'isDisabled = "'+ coalesce(cast(isDisabled as varchar(50)),space(1)) + '" ' +
		--								+ '></product>'
		--	FROM #data
		--	WHERE Bettype=@i	

		--	SELECT @i=@i+1
		--END

		--SELECT @KenoList +'</products>' AS KenoList

		--DROP TABLE #data
	END 
END

GO 
GRANT VIEW DEFINITION ON [dbo].[Lrf_LicenseeBetSettingSel] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Lrf_LicenseeBetSettingSel] TO [bodbAdminNet]
GO 

