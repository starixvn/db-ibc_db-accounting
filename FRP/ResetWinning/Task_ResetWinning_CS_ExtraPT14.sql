/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

CREATE PROCEDURE [dbo].[Task_ResetWinning_CS_ExtraPT14]
	@WinlostDate SMALLDATETIME, 
	@Mode     TINYINT = 0,
	@ErrCode  INT = 0 OUTPUT,
    @ErrMsg   VARCHAR(100) = '' OUTPUT
AS
/*
	Creator: 20190826@Sophia 
	Remark: Daily Auto add transfer ticket for CN88 Headline balance - bettrans14 range (like reset winning Extra PT for CN88) 
	DB: DBTXN-bodb02

	Revisions:
		- 20190826@Sophia: initial SP [Redmine: #117863]	 

	Param's explain:
		@mode:  0 _ view report
	            1 _ reset balance
	          
	    @ErrCode: 0 _ Success
	              1 _ Error
	            

	 
*/
BEGIN
	SET NOCOUNT ON
 
	CREATE TABLE #Headline(SuperID INT, UplineID INT, Winlostdate SMALLDATETIME)		 
	CREATE TABLE #Transfer (Custid INT, Reset MONEY, RealReset MONEY, Winlostdate SMALLDATETIME )	
	CREATE TABLE #Reset (seq INT IDENTITY (1,1), Winlostdate SMALLDATETIME, CustId INT, ExtraPTWinlost MONEY, RealExtraPTWinlost MONEY, Reset MONEY, RealReset MONEY, Variance MONEY, RealVariance MONEY)

	
	----Begin: Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)

	DELETE @SportBettype WHERE ProductId NOT IN (SELECT DISTINCT ProductID FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))

	-----End: Get Sport Bettype Matrix------
		 
	
	----Begin: Get Headline List ----
	
	INSERT INTO #Headline (SuperId, UplineId) 
	SELECT c.CustID AS SuperId, c.UplineId
	FROM DBCUST.CUSTDB.dbo.CustSuper c WITH (NOLOCK) 
	WHERE UplineID IS NOT NULL	 
 	
	----End: Get Headline List ----
	
	
	--- Begin: Last reset	
	
	INSERT INTO #Transfer (Custid, Reset, RealReset, Winlostdate)
	SELECT	b.custid, 			
			ROUND((b.winlost - b.actual_stake)* actualrate, 2) AS Reset, 
			ROUND((b.winlost - b.actual_stake), 2) AS RealReset, 
			b.winlostdate 
	FROM dbo.bettrans b WITH(NOLOCK) 	
	WHERE b.bettype = 21007
		AND b.winlostdate = @Winlostdate
		AND EXISTS (SELECT 1 FROM #Headline h WHERE h.Headline = b.CustID) 
	
	--- End: Last reset


	
	-----Begin : Get Winlost on ticket ----------------
	 
	--------------------------------------------Extra PT ---------------------------------------------------
	CREATE TABLE #wl 
	(	winlostdate 	SMALLDATETIME, 
		srecommend 		INT, 		
		Sporttype  		SMALLINT, 
		ProductId		INT, 
		ProductName		VARCHAR(250), 
		SubProduct		VARCHAR(250), 
		CommForExtraPT	MONEY,
		WinlostForExtraPT MONEY,
		RealCommForExtraPT	MONEY,
		RealWinlostForExtraPT MONEY
	)
	
	CREATE TABLE #WLByProduct
	(
	    winlostdate			SMALLDATETIME, 
		ProductId			INT,
		ProductName			VARCHAR(250),
		SubProduct			VARCHAR(250),
		UplineId			INT,		
		ExtraPTWinlost		MONEY,		
		RealExtraPTWinlost	MONEY
	) 
	 
	INSERT INTO #wl (winlostdate, srecommend, Sporttype, ProductId, ProductName, SubProduct, 
					CommForExtraPT, WinlostForExtraPT, RealCommForExtraPT, RealWinlostForExtraPT)
	SELECT  b.winlostdate,
			b.srecommend,					
			CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END AS Sporttype,
			s.ProductId,
			CASE WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live'			
				WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'
				WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
				WHEN b.bettype = 10 THEN 'Outright'
				WHEN b.bettype IN (9,29) THEN'Parlay' 
				WHEN b.liveindicator = 1 AND s.ProductID = 1 THEN 'SPL' 
				WHEN b.liveindicator = 0 AND s.ProductID = 1 THEN 'SPNL'  	
				ELSE ''
				END	AS ProductName,
			CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END AS SubProduct,
			---Base currency			
			0 AS CommForExtraPT,
				
			SUM((
				CASE
					-- Jackpot
					WHEN b.bettype IN (2198, 2398, 2998) THEN
						CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
					WHEN b.bettype IN (2199, 2399, 2999) THEN 0
					ELSE
						CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
					END) * b.actualrate
				) AS WinlostForExtraPT,				
			---Real currency				
			0 AS RealCommForExtraPT,
			SUM(
				CASE
					-- Jackpot
					WHEN b.bettype IN (2198, 2398, 2998) THEN
						CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
					WHEN b.bettype IN (2199, 2399, 2999) THEN 0
					ELSE
						CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
					END
				) AS RealWinlostForExtraPT				
				
		FROM dbo.bettrans14 b WITH (NOLOCK)			
		INNER JOIN @SportBettype s ON s.BetType = b.bettype
		LEFT JOIN dbo.Match m WITH (NOLOCK) ON m.MatchId = b.MatchId  AND m.Sporttype = 44		
		WHERE   b.Winlostdate = @Winlostdate
			AND b.ruben = 1
			AND b.statusid NOT IN (101, 102, 103, 121)		
			AND b.Currency <> 20 
			AND EXISTS (SELECT 1 FROM dbo.CS_CustSuper cs WITH (NOLOCK) WHERE cs.CusTID = b.srecommend) 
		GROUP BY b.Winlostdate,				
				b.srecommend,	
				b.Currency,
				CASE WHEN ISNULL(m.Sporttype, 0) <> 0 THEN m.Sporttype ELSE 0 END,
				s.ProductId,
				CASE WHEN s.SubProduct = 'MG-SuperLive' THEN 'Metric Gaming - Super Live' 
					WHEN s.SubProduct = 'Bet Builder' THEN 'Bet Builder'
					WHEN ISNULL(m.Sporttype, 0) = 44 THEN 'Muay Thai'
					WHEN b.bettype = 10 THEN 'Outright'
					WHEN b.bettype IN (9,29) THEN'Parlay' 
					WHEN b.liveindicator = 1 AND s.ProductID = 1 THEN 'SPL' 
					WHEN b.liveindicator = 0 AND s.ProductID = 1 THEN 'SPNL'  	
					ELSE ''
					END	,
				CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm','BT-Winloss','Bet Builder') THEN s.SubProduct ELSE '' END
				 

	INSERT INTO #WLByProduct (Winlostdate, ProductId, ProductName, UplineID, ExtraPTWinlost, RealExtraPTWinlost) 
	SELECT Winlostdate, ProductId, ProductName, UplineID, SUM(ExtraPTWinlost), SUM(RealExtraPTWinlost)
	FROM (		
			--- extraPT
			SELECT  w.Winlostdate, w.ProductId, w.ProductName, 				
					cs.UplineID,
				   SUM(w.WinlostForExtraPT * ISNULL(s.ExtraPT,0)) as ExtraPTWinlost,				
				   SUM(w.RealWinlostForExtraPT * ISNULL(s.ExtraPT,0)) as RealExtraPTWinlost  
			FROM	#wl w
			INNER JOIN dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate	
			INNER JOIN dbo.CustSuper cs WITH (NOLOCK) 
					ON cs.CustId = w.srecommend AND cs.UplineID IS NOT NULL
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName, cs.UplineID
			
		 
			--- extraComm	
			UNION ALL 
			SELECT	w.Winlostdate, w.ProductId, w.ProductName, 
					cs.UplineID,
					SUM(w.CommForExtraPT * ISNULL(s.ExtraCommRate,0)) as ExtraPTWinlost,
					SUM(w.RealCommForExtraPT * ISNULL(s.ExtraCommRate,0)) as RealExtraPTWinlost   --- ExtraComm if any
			FROM	#wl w
			INNER JOIN dbo.Acc_GroupExtraCommRateSetting s WITH (NOLOCK)
					ON w.srecommend = s.SuperId
					AND w.ProductId = s.ProductId
					AND w.SubProduct = s.SubProduct
					AND w.Sporttype = s.Sporttype 
					AND w.Winlostdate BETWEEN s.FromDate AND s.ToDate
			INNER JOIN dbo.CustSuper cs WITH (NOLOCK) 
					ON cs.CustId = w.srecommend AND cs.UplineID IS NOT NULL
			GROUP BY w.Winlostdate, w.ProductId, w.ProductName,
					 cs.UplineID		
	
		) w
	GROUP BY w.Winlostdate, w.ProductId, w.ProductName, cs.UplineID	
	
	
	----view report
    IF (@mode = 0)
    BEGIN 
	    ----- calculate reset 
		SELECT  h.Winlostdate, h.UplineID,
				ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) AS ExtraPTWinlost,
				ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2) AS RealExtraPTWinlost,
				ROUND(SUM(ISNULL(rs.Reset, 0)), 2) AS Reset,
				ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) AS RealReset
		FROM #Headline h		
			LEFT JOIN (
						SELECT Winlostdate, UplineID, SUM(ExtraPTWinlost) AS ExtraPTWinlost, SUM(RealExtraPTWinlost) AS RealExtraPTWinlost
						FROM  #WLByProduct 
						GROUP BY Winlostdate, UplineID
						) e 
				ON h.UplineID = e.UplineID
			LEFT JOIN #Transfer rs 
				ON h.UplineID = rs.Custid
		GROUP BY h.Winlostdate, h.UplineID  
		HAVING (ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2) - ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) ) <> 0
	END	
	ELSE
    BEGIN 
	    ----- calculate reset 
		INSERT INTO #Reset (Winlostdate, CustId, ExtraPTWinlost, RealExtraPTWinlost, Reset, RealReset, Variance, RealVariance)
		SELECT  @Winlostdate, h.UplineID,
				ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) AS ExtraPTWinlost,
				ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2) AS RealExtraPTWinlost,
				ROUND(SUM(ISNULL(rs.Reset, 0)), 2) AS Reset,
				ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) AS RealReset,
				ROUND(SUM(ISNULL(e.ExtraPTWinlost, 0)), 2) - ROUND(SUM(ISNULL(rs.Reset, 0)), 2)  AS Variance,
				ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2) - ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) AS RealVariance
		FROM #Headline h		
			LEFT JOIN (
						SELECT Winlostdate, UplineID, SUM(ExtraPTWinlost) AS ExtraPTWinlost, SUM(RealExtraPTWinlost) AS RealExtraPTWinlost
						FROM  #WLByProduct 
						GROUP BY Winlostdate, UplineID
						) e 
				ON h.UplineID = e.UplineID
			LEFT JOIN #Transfer rs 
				ON h.UplineID = rs.Custid
		GROUP BY h.Winlostdate, h.UplineID  
		HAVING (ROUND(SUM(ISNULL(e.RealExtraPTWinlost, 0)), 2) - ROUND(SUM(ISNULL(rs.RealReset, 0)), 2) ) <> 0
		
		
		---------------------
 
		DECLARE 
				@seq		  TINYINT = 1,
				@maxseq		  TINYINT = 0,				
				@RealExtraPTWinlost MONEY = 0, 
                @custid       INT,               
                @transDesc    NVARCHAR(1000)= 'ExtraPT',		
				@Creator  INT = 5838421,
				@IP       VARCHAR(20) = '',
				@LogData  NVARCHAR(200) = ''				

		SELECT @maxseq = MAX(r.seq)
        FROM   #reset r
		
		IF (@maxseq = 0)
        BEGIN
            SELECT @ErrMsg = 'No products need to reset winning!',
                   @ErrCode = 2
            RETURN
        END
			
		
        WHILE (@seq <= @maxseq)
        BEGIN
        
            SELECT @CustId = CustId,
				   @RealExtraPTWinlost = RealExtraPTWinlost
            FROM #Reset
            WHERE seq = @seq 		
			
			IF NOT EXISTS (SELECT 1 FROM dbo.Bettrans WITH (NOLOCK) WHERE CustID = @CustID AND WinlostDate = @WinlostDate AND Bettype = 21007)
			BEGIN 
				EXEC DBTXN.bodb02.dbo.Task_ResetWinning_Non3rdParty_Add
					@winlostdate = @winlostdate,
					@custid = @custid,
					@amount = @RealExtraPTWinlost,
					@transdesc = @TransDesc,
					@creator = @creator,
					@ip = @ip,
					@isExtraPT = 2,    --- reset extraPT for CN88 (headline balance)
					@ErrCode = @ErrCode OUTPUT,
					@ErrMsg = @ErrMsg OUTPUT
			END
			ELSE 			
			BEGIN 
				UPDATE dbo.Bettrans WITH (ROWLOCK) 
				SET Winlost = CASE WHEN @RealExtraPTWinlost >= 0 THEN @RealExtraPTWinlost ELSE 0 END,
				    Actual_Stake = CASE WHEN @RealExtraPTWinlost <= 0 THEN ABS(@RealExtraPTWinlost) ELSE 0 END
				WHERE CustID = @CustID
					AND WinlostDate = @WinlostDate
					AND Bettype = 21007	
			END				

			IF (@ErrCode <> 0) BREAK
											
			--- write log 
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Transfer
					@UserID = @creator,
					@FromCustID = 0,
					@ToCustID = @custid,
					@ip = @ip,
					@Doing = @transDesc
			END TRY	
			BEGIN CATCH						
				SELECT @LogData = @LogData + ' ErrMsg=' + error_message()
				EXEC DBTXN.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
					@UserID = @creator, 
					@FromCustID = 0, 
					@ToCustID = @CustID, 
					@IP = @IP, 
					@Doing = @LogData						
			END CATCH
         

            SET @seq = @seq + 1

            SELECT @ErrMsg = 'The process has been successful!'
			
        END
  
    END
	
	
	DROP TABLE #Headline
	DROP TABLE #Reset
	DROP TABLE #Transfer
	DROP TABLE #wl
	DROP TABLE #WLByProduct
	
END
GO