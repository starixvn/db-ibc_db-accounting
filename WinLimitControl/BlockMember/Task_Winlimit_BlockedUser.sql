ALTER PROCEDURE [dbo].[Task_Winlimit_BlockedUser]
AS
/*   
	Create: 20160623@Helen
	Task : Task scan winlimit amount & blocked member when they are reached max winlimit setting  - [Redmine:57722]
	DB: DBCUST/CustDB
	Revisions:
		- 20161011@Helen: NAP Risk & Control - Phase 3 [Redmine: 61220]

	Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON

	
	CREATE TABLE #DataTmp (CustId INT, ExchangeID TINYINT,SiteID INT, ProductId TINYINT, Bettype SMALLINT, TotalWinAmount MONEY, WinlostDate SMALLDATETIME, IsPrivateSetting BIT)
	CREATE TABLE #HistoryData (ID INT IDENTITY, CustId INT 
							, ProductId TINYINT 
							, BettypeID SMALLINT 
							, MaxWinLimit MONEY 
							, TotalWinAmt MONEY 
							, WinAmt MONEY 
							, LevelID TINYINT  
							, ActionID TINYINT 
							, ModifiedDate DATETIME  
							, IsNotified BIT  
							, ModifiedBy INT 
							, CreatedBy  INT 
							, WinlostDate DATETIME
							, MaxWinLimitSetting XML
							, TotalWinAmt_RM MONEY  )

	DECLARE @WinlostDate SMALLDATETIME, @ReachedDate DATETIME
	SELECT @WinlostDate = CAST(GETDATE() AS DATE)

	INSERT INTO #DataTmp(CustId, WinlostDate, Bettype, TotalWinAmount,IsPrivateSetting)
	SELECT CustId, WinlostDate, BetType, SUM(Winlost),0
	FROM (
		SELECT CustId, WinlostDate, BetType, Winlost
		FROM DBTXN.bodb02.dbo.Winlimit_CreditGame c WITH(NOLOCK)
		WHERE WinlostDate = @WinlostDate

		UNION ALL
		
		SELECT CustId, WinlostDate, BetType, - Winlost
		FROM DBTXN.bodb02.dbo.Winlimit_DebitGame c WITH(NOLOCK)
		WHERE WinlostDate = @WinlostDate
			
	)t
	GROUP BY CustId, WinlostDate, BetType


	UPDATE t 
	SET ExchangeID = cc.currency
		, ProductId = GGS.ProductId
		, SiteID = s.siteid
		, IsPrivateSetting = CASE WHEN CGS.CustID IS NOT NULL THEN 1 ELSE 0 END 
	FROM #DataTmp t
		INNER JOIN WinLimit_GameGroupSetting GGS WITH (NOLOCK) ON T.Bettype = GGS.BetTypeID
		INNER JOIN custInfo CI (NOLOCK) ON t.CustId = ci.custid
		INNER JOIN Customer cc WITH(NOLOCK) ON cc.custid = ci.recommend
		INNER JOIN [site] s WITH (NOLOCK) ON s.site = cc.site
		LEFT JOIN WinLimit_CustGameSetting CGS WITH (NOLOCK) ON CGS.CustID = T.CustId AND CGS.GroupID =  GGS.GroupID
		
	
	CREATE TABLE #CustReachCWLList (ID INT IDENTITY PRIMARY KEY, CustId INT, ProductId TINYINT, BettypeID SMALLINT,WinlostDate SMALLDATETIME,LevelID TINYINT, MaxWinLimit MONEY
		, TotalWinAmount MONEY
		, ExchangeID INT
		, SiteID INT
		, IsPrivateSetting BIT
		, MaxWinLimitSetting XML
		, TotalWinAmt_RM MONEY)

	--need to check cust setting fisrt after check global setting
	--for WinLimit_CustSetting
	DECLARE @Fromdate DATE= GETDATE(), @Todate DATE= GETDATE()  
	
	INSERT INTO #CustReachCWLList(CustId, ProductId, BettypeID,WinlostDate,ExchangeID,SiteID, LevelID, MaxwinLimit, TotalWinAmount,IsPrivateSetting,MaxWinLimitSetting)--,TotalWinAmt_RM)
	SELECT t.CustId, t.ProductId, t.Bettype,t.WinlostDate,t.ExchangeID,t.SiteID, MAX(s.LevelID) AS LevelID , MAX(s.MaxWinLimit) AS MaxWinLimit, MAX(t.TotalWinAmount) AS TotalWinAmount,1
			, CAST(tmp.MaxWinLimitSetting AS XML)
	FROM #DataTmp t
		INNER JOIN WinLimit_CustGameSetting s WITH(NOLOCK) ON t.CustId = s.CustId AND t.ProductId = s.ProductId 
		INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = S.GroupID AND GS.BetTypeID = T.Bettype
		CROSS APPLY (SELECT '<MaxWinLimitSetting' + x.str + '/>' 
					FROM (SELECT ' Level' + CAST(LevelID AS VARCHAR) + '="' + CAST(MaxWinLimit_RM AS VARCHAR) + '"'
						  FROM WinLimit_CustGameSetting S1 WITH (NOLOCK)
						  WHERE S1.CustID = T.CustId AND S1.ProductID = GS.ProductId AND S1.GroupID = GS.GroupID
						  FOR XML PATH('')
						) x(str)
		) AS tmp (MaxWinLimitSetting)
	WHERE t.TotalWinAmount >= s.MaxWinLimit
		AND s.MaxWinLimit > 0
		AND T.IsPrivateSetting = 1
		
	GROUP BY t.CustId, t.ProductId, t.Bettype,t.WinlostDate,t.ExchangeID,t.SiteID,tmp.MaxWinLimitSetting
	
	
	--for WinLimit_GlobalSetting
	INSERT INTO #CustReachCWLList(CustId, ProductId, BettypeID,WinlostDate,ExchangeID,SiteID,LevelID, MaxwinLimit, TotalWinAmount,IsPrivateSetting,MaxWinLimitSetting)
	SELECT t.CustId, t.ProductId, t.Bettype,t.WinlostDate,t.ExchangeID,t.SiteID,MAX(s.LevelID), MAX(s.MaxWinLimit), MAX(t.TotalWinAmount),0
		  ,CAST(tmp.MaxWinLimitSetting AS XML)
	FROM #DataTmp t
		INNER JOIN dbo.WinLimit_ProductSettingDetail s WITH(NOLOCK) ON t.ExchangeID = s.ExchangeID AND t.ProductId = s.ProductID AND T.SiteID = S.SiteID
		INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = S.GroupID AND GS.BetTypeID = T.Bettype AND t.Bettype = GS.BettypeID
		CROSS APPLY (SELECT '<MaxWinLimitSetting' + x.str + '/>'  
					FROM (SELECT ' Level' + CAST(LevelID AS VARCHAR) + '="' + CAST(MaxWinLimit_RM AS VARCHAR) + '"'
						  FROM WinLimit_ProductSettingDetail S1 WITH (NOLOCK)
						  WHERE S1.ProductID = GS.ProductId AND S1.GroupID = GS.GroupID AND S1.ExchangeID = T.ExchangeID AND S.SiteID = S1.SiteID
						  FOR XML PATH('')
						) x(str)
		) AS tmp (MaxWinLimitSetting)
		
	WHERE t.TotalWinAmount >= s.MaxWinLimit
		AND s.MaxWinLimit > 0
		AND T.IsPrivateSetting = 0
	GROUP BY t.CustId, t.ProductId, t.Bettype,t.WinlostDate,t.ExchangeID,t.SiteID,tmp.MaxWinLimitSetting
	
	
	
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM #CustReachCWLList)
	BEGIN
		RETURN
	END
	
	
	SELECT @ReachedDate = GETDATE()
	
	-- Update due to change status of currency setting
	UPDATE g
	SET 
		  ModifiedDate = @ReachedDate
		, IsNotified = 0
		, MaxwinLimit = t.MaxWinLimit
		, MaxWinLimitSetting = T.MaxWinLimitSetting
		
	OUTPUT inserted.CustId, inserted.ProductId,inserted.BettypeID, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.WinAmt, inserted.LevelID  
			, inserted.ModifiedDate, inserted.IsNotified,inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate,inserted.MaxWinLimitSetting ,inserted.TotalWinAmt_RM
	INTO #HistoryData(CustId
					, ProductId 
					, BettypeID 
					, MaxWinLimit 
					, TotalWinAmt 
					, WinAmt 
					, LevelID 
					, ModifiedDate 
					, IsNotified 
					, ModifiedBy 
					, CreatedBy 
					, WinlostDate
					, MaxWinLimitSetting
					
					, TotalWinAmt_RM ) 
	FROM dbo.WinLimit_CustGameMonitoring g WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #CustReachCWLList t ON t.CustId = g.CustID AND g.WinlostDate = t.WinlostDate AND t.BettypeID = g.BettypeID AND g.ProductID = t.ProductId AND g.LevelID = t.LevelID
		INNER JOIN Winlimit_ProductSettingDetail psd WITH (NOLOCK) ON g.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID and g.LevelID = psd.LevelID AND psd.SiteID = t.SiteID
		INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID AND t.BettypeID = GS.BettypeID AND g.BettypeID = gs.BettypeID 
		INNER JOIN WinLimit_CustGameStatus CGS WITH (NOLOCK) ON CGS.CustID = G.CustID AND CGS.ProductID = G.ProductID AND CGS.BettypeID = G.BettypeID 
		
	WHERE (psd.IsBlockedPlaceBet = 1 AND cgs.IsBlockedPlaceBet = 0 AND CGS.ActionID NOT IN (2,4)) OR (psd.IsBlockedTransfer = 1 AND cgs.IsBlockedTransfer = 0 AND CGS.ActionID NOT IN (2,4))
		
	-- UPDATE	
	
	UPDATE g
	
	SET MaxwinLimit = t.MaxWinLimit
		, TotalWinAmt = g.TotalWinAmt -  CASE WHEN CGS.ActionID IN (2,4) THEN 0 ELSE g.WinAmt END + t.TotalWinAmount
		, WinAmt = t.TotalWinAmount
		, ModifiedDate = @ReachedDate
		, IsNotified = 0
		, LevelID = T.LevelID
		, MaxWinLimitSetting = t.MaxWinLimitSetting
		, TotalWinAmt_RM = CASE 
								WHEN T.ExchangeID = 20 THEN (g.TotalWinAmt -  CASE WHEN CGS.ActionID IN (2,4) THEN 0 ELSE g.WinAmt END + t.TotalWinAmount) 
								ELSE  ROUND (FEX.MYR * (g.TotalWinAmt -  CASE WHEN CGS.ActionID IN (2,4) THEN 0 ELSE g.WinAmt END + t.TotalWinAmount),2)
							END
		
	OUTPUT inserted.CustId, inserted.ProductId,inserted.BettypeID, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.WinAmt, inserted.LevelID  
			, inserted.ModifiedDate, inserted.IsNotified,inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate, inserted.MaxWinLimitSetting,inserted.TotalWinAmt_RM  
	INTO #HistoryData(CustId
					, ProductId 
					, BettypeID 
					, MaxWinLimit 
					, TotalWinAmt 
					, WinAmt 
					, LevelID 
					, ModifiedDate 
					, IsNotified 
					, ModifiedBy 
					, CreatedBy 
					, WinlostDate
					, MaxWinLimitSetting
					,TotalWinAmt_RM) 
		
	FROM dbo.WinLimit_CustGameMonitoring g WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #CustReachCWLList t ON t.CustId = g.CustID AND g.WinlostDate = t.WinlostDate AND t.BettypeID = g.BettypeID AND g.ProductID = t.ProductId
		INNER JOIN WinLimit_CustGameStatus CGS WITH (NOLOCK) ON CGS.CustID = G.CustID AND CGS.ProductID = G.ProductID AND CGS.BettypeID = G.BettypeID 
		LEFT JOIN Lrf_f_GetExchangeDaily(@Fromdate, @Todate) fEx  ON fEx.ExchangeId = T.ExchangeID
	WHERE G.LevelID < T.LevelID
		-- Reach level again after unblocked
		OR ( CGS.ActionID IN (2,4))
	
	-- INSERT NEW
	INSERT INTO dbo.WinLimit_CustGameMonitoring(CustId, ProductID, BettypeID,LevelID, MaxWinLimit, WinAmt, TotalWinAmt
		, IsNotified, CreatedBy,ModifiedDate ,WinlostDate,MaxWinLimitSetting,TotalWinAmt_RM)
	
	OUTPUT inserted.CustId, inserted.ProductId,inserted.BettypeID, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.WinAmt, inserted.LevelID  
				, inserted.ModifiedDate, inserted.IsNotified,inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate,inserted.MaxWinLimitSetting,inserted.TotalWinAmt_RM  
	INTO #HistoryData(CustId
					, ProductId 
					, BettypeID 
					, MaxWinLimit 
					, TotalWinAmt 
					, WinAmt 
					, LevelID 
					, ModifiedDate 
					, IsNotified 
					, ModifiedBy 
					, CreatedBy 
					, WinlostDate
					, MaxWinLimitSetting
					, TotalWinAmt_RM ) 
							
	SELECT t.CustId, t.ProductId, t.BettypeID,t.LevelID, t.MaxwinLimit, t.TotalWinAmount, t.TotalWinAmount, 0, NULL,@ReachedDate ,@WinlostDate,t.MaxWinLimitSetting
			, CASE WHEN T.ExchangeID = 20 THEN t.TotalWinAmount ELSE ROUND(FEX.MYR * t.TotalWinAmount,2) END AS TotalWinAmt_RM
	FROM #CustReachCWLList t
		LEFT JOIN dbo.WinLimit_CustGameMonitoring g WITH(NOLOCK) ON t.CustId = g.CustID AND t.WinlostDate = g.WinlostDate AND t.BettypeID = g.BettypeID 
		LEFT JOIN Lrf_f_GetExchangeDaily(@Fromdate, @Todate) fEx  ON fEx.ExchangeId = T.ExchangeID
	WHERE g.CustID IS NULL
	
	DECLARE @StrData VARCHAR(MAX), @XmlData XML, @RowCount INT, @ReTry INT
	
	DECLARE @StartRow INT = 1, @MaxRow INT,@Threshold INT = 500, @StopRow INT
			
	SET @MaxRow = (SELECT MAX(ID) FROM #HistoryData)
	
	IF @Threshold >= @MaxRow
		SET @Threshold = @MaxRow
	
	SET @StopRow = @Threshold
	
	IF EXISTS (SELECT 1 FROM #HistoryData)
	BEGIN
		-- Update lates status
		UPDATE CS
			SET IsBlockedPlaceBet = CASE WHEN CS.IsBlockedPlaceBet = 1 THEN 1 ELSE PSD.IsBlockedPlaceBet END
				, IsBlockedTransfer = CASE WHEN CS.IsBlockedTransfer = 1 THEN 1 ELSE PSD.IsBlockedTransfer END
				,  ActionID =  CASE WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsBlockedTransfer = 1 THEN 5
								   WHEN PSD.IsBlockedPlaceBet = 1 THEN 1
								   WHEN PSD.IsBlockedTransfer = 1 THEN 3
							   ELSE 0 END
				, ModifiedDate = @ReachedDate
		FROM #CustReachCWLList T
			INNER JOIN #HistoryData H ON T.CustId = H.CustId AND T.BettypeID = H.BettypeID AND T.ProductId = H.ProductId AND H.WinlostDate = T.WinlostDate
			INNER JOIN WinLimit_ProductSettingDetail psd WITH (NOLOCK) ON T.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID AND T.SiteID = PSD.SiteID AND T.LevelID = psd.LevelID
			INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID AND t.BettypeID = GS.BettypeID 
			INNER JOIN WinLimit_CustGameStatus CS (NOLOCK) ON T.CustId = CS.CustId AND T.ProductId = CS.ProductID AND T.BettypeID = CS.BettypeID
		
		-- Insert Status	
		INSERT INTO WinLimit_CustGameStatus (CustID,ProductID,BettypeID,IsBlockedPlaceBet,IsBlockedTransfer,ActionID,ModifiedDate)
		SELECT T.CustId,T.ProductId,T.BettypeID
				, PSD.IsBlockedPlaceBet
				, PSD.IsBlockedTransfer
				, CASE WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsBlockedTransfer = 1 THEN 5
								   WHEN PSD.IsBlockedPlaceBet = 1 THEN 1
								   WHEN PSD.IsBlockedTransfer = 1 THEN 3
							   ELSE 0 END AS ActionID
				,@ReachedDate AS ModifiedDate
		FROM #CustReachCWLList T
			INNER JOIN #HistoryData H ON T.CustId = H.CustId AND T.BettypeID = H.BettypeID AND T.ProductId = H.ProductId AND H.WinlostDate = T.WinlostDate
			INNER JOIN WinLimit_ProductSettingDetail psd WITH (NOLOCK) ON T.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID	 AND T.SiteID = PSD.SiteID AND T.LevelID = psd.LevelID
			INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID AND t.BettypeID = GS.BettypeID  
			LEFT JOIN WinLimit_CustGameStatus CS WITH (NOLOCK) ON T.CustId = CS.CustId AND T.ProductId = CS.ProductID AND T.BettypeID = CS.BettypeID
		WHERE CS.CustId IS NULL
					 
		WHILE 1 = 1 --exec by batch
		BEGIN
			--clear data
			
			SET @XmlData = ''
			SET @StrData = ''

			SET @XmlData = (
					SELECT C.CustId AS 'a1'
						, C.ProductId AS 'a2'
						, C.BettypeID AS 'a3'
						, C.MaxWinLimit AS 'a4'
						, GM.TotalWinAmt AS 'a5'
						, GM.WinAmt  AS 'a6'
						, GM.LevelID  AS 'a7'
						, CASE WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsBlockedTransfer = 1 THEN 5
							   WHEN PSD.IsBlockedPlaceBet = 1 THEN 1
							   WHEN PSD.IsBlockedTransfer = 1 THEN 3
							   ELSE 0 END AS 'a8'
						, GM.ModifiedDate  AS 'a9'
						, GM.IsNotified  AS 'a10'
						, GM.ModifiedBy  AS 'a11'
						, GM.CreatedBy  AS 'a12'
						, GM.WinlostDate  AS 'a13'
						, gm.MaxWinLimitSetting AS 'a14'
						, gm.TotalWinAmt_RM AS 'a15'
					FROM #HistoryData GM
						INNER JOIN #CustReachCWLList C WITH (NOLOCK) ON C.CustId = GM.CustID AND C.BettypeID = GM.BettypeID AND C.WinlostDate = GM.WinlostDate AND C.ProductId = GM.ProductID 
						INNER JOIN WinLimit_ProductSettingDetail PSD WITH (NOLOCK) ON GM.ProductID = PSD.ProductID AND C.ExchangeID = PSD.ExchangeID AND PSD.SiteID = C.SiteID AND PSD.LevelID = c.LevelID 
						INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID AND GS.BetTypeID = C.BettypeID 
						
					WHERE GM.ID >= @StartRow AND GM.ID <= @StopRow
					
					FOR XML PATH('r'), ROOT ('root'), TYPE
				)
			
			SET @StrData = CONVERT(NVARCHAR(MAX), @XmlData)
		
			
			IF @StrData IS NULL
				BREAK

			EXEC dbo.Task_Winlimit_InsertHistoryData @XmlData = @StrData
			
			IF @StopRow = @MaxRow BREAK
						
			SET @StartRow = @StopRow + 1
			
			SET @StopRow = 1 + @StopRow + @Threshold
			
			IF @StopRow >= @MaxRow
				SET @StopRow = @MaxRow
		
		END
	END	
	DROP TABLE #HistoryData
	DROP TABLE #DataTmp
	DROP TABLE #CustReachCWLList
	
END

