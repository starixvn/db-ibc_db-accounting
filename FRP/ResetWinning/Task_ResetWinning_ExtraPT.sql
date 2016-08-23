USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_ResetWinning_ExtraPT]
	@fromdate SMALLDATETIME,
	@todate   SMALLDATETIME,
	@mode     TINYINT = 0,
	@creator  INT = 5838421,
	@ip       VARCHAR(20) = '',
	@ErrCode  INT = 0 output,
    @ErrMsg   VARCHAR(100) = '' output
AS
/*
	Creator: Percy
	Date: 20160304
	Remark: Add new function for Reset Winning (Extra PT) [Redmine: #51721]
	DB: DBACC.bodb02

	Revisions:
		- 20160331@Sophia: change the way to use Function f_SportBettypeMatrix_Sel [Redmine: #54719]

	Param's explain:
		@mode:  0 _ view report
	            1 _ reset balance
	          
	    @ErrCode: 0 _ Success
	              1 _ Error
	              2 _ Already reset

	Noted: use inline func: bodb02.dbo.f_SportBettypeMatrix_Sel(@ProductID, @Sporttype, @Bettype, @IsLive, @SubProduct, @ProductPrefix, @IsTest)
			instead of sp Acc_SportBettypeMatrix_Sel
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @dummy TABLE (CustID INT, GroupID TINYINT, GroupName VARCHAR(50), Winlostdate SMALLDATETIME)
	CREATE TABLE #winning (ProductID TINYINT, Sporttype INT, SubProduct VARCHAR(500), Winlost MONEY, Winlostdate SMALLDATETIME, GroupId TINYINT)
	DECLARE @reset TABLE (CustID INT, Winlost MONEY, [Reset] MONEY, Variance MONEY, Winlostdate SMALLDATETIME, GroupID TINYINT, GroupName VARCHAR(50))
	DECLARE @LastReset TABLE (CustID INT, [Reset] MONEY, Winlostdate SMALLDATETIME, GroupID TINYINT)

	DECLARE @wldate SMALLDATETIME = @todate
	DECLARE @Date TABLE (WLDate SMALLDATETIME)

	WHILE @wldate >= @fromdate
	BEGIN
		INSERT INTO @Date (WLDate)
		SELECT @wldate

		SELECT @wldate = DATEADD(DAY, -1, @wldate)
	END
	
	----Get Sport Bettype Matrix------
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	SELECT ProductID, Bettype, SubProduct FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)

	DELETE @SportBettype WHERE ProductId NOT IN (SELECT DISTINCT ProductID FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))

	----- End get sport bettype 
	
	DECLARE @SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)
	
	IF  (@SQL like '%_xtest%')
	BEGIN
		INSERT INTO @dummy (CustID, GroupID, GroupName, Winlostdate)	
		SELECT  DISTINCT e.CustID, e.GroupID, e.GroupName, d.WLDate
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest e WITH (NOLOCK)
		CROSS JOIN @Date d
	END
	ELSE
	BEGIN
		INSERT INTO @dummy (CustID, GroupID, GroupName, Winlostdate)	
		SELECT  DISTINCT e.CustID, e.GroupID, e.GroupName, d.WLDate
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK)
		CROSS JOIN @Date d
	END


	/* winlost */
	
	-- General data --
	
	----Non sportsbook

	;WITH wl AS (
			SELECT b.srecommend , s.ProductID, 0 AS Sporttype, '' AS SubProduct,
				SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0))*ISNULL(actualrate, 0)) AS Winlost, b.winlostdate
			FROM bettrans b WITH(READPAST, INDEX = IX_Report)
			INNER JOIN  @SportBettype s
				ON s.BetType = b.bettype
			WHERE b.winlostdate BETWEEN @fromdate AND @todate
				AND s.ProductID <> 1 
				AND b.ruben = 1
				AND b.statusID NOT IN (101, 102, 103, 121)
				AND b.bettype < 19001
			GROUP BY b.winlostdate, b.srecommend, s.ProductID
			)
	INSERT INTO #winning (ProductID, Sporttype, SubProduct, Winlost, Winlostdate, GroupId)
	SELECT w.ProductID, w.Sporttype, w.SubProduct, SUM (w.Winlost * s.ExtraPT) AS Winlost, w.Winlostdate, s.GroupId
	FROM wl w
	INNER JOIN bodb_Acc.dbo.Acc_GroupExtraPTSetting s WITH (NOLOCK)
			ON w.srecommend = s.SuperId
			AND w.ProductId = s.ProductId
			AND w.SubProduct = s.SubProduct
			AND w.Sporttype = s.Sporttype 
			AND w.winlostdate BETWEEN s.FromDate AND s.ToDate	
	GROUP BY w.ProductID, w.Sporttype, w.SubProduct, w.Winlostdate, s.GroupId

	 
	-- SportBook  	
	;WITH wl AS (
			SELECT	b.srecommend, 1 AS ProductID, 
					CASE WHEN ISNULL(m.matchid, 0) <> 0 THEN m.Sporttype ELSE 0 END AS Sporttype, 
					CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm') THEN s.SubProduct ELSE '' END AS SubProduct,
					SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0)) * ISNULL(actualrate, 0)) AS Winlost, 
					b.winlostdate
			FROM bettrans b WITH(READPAST, INDEX = IX_Report)
			INNER JOIN  @SportBettype s
				ON s.BetType = b.bettype
			LEFT JOIN bodb02.dbo.match m WITH(NOLOCK)
				ON m.matchid = b.matchid AND m.eventdate = b.winlostdate AND m.sporttype = 44 -- MuayThai
			WHERE  b.winlostdate BETWEEN @fromdate AND @todate
				AND b.ruben = 1
				AND b.statusID NOT IN (101, 102, 103, 121)
				AND b.bettype < 19001
				AND s.productID = 1 
			GROUP BY b.winlostdate, b.srecommend,
					CASE WHEN ISNULL(m.matchid, 0) <> 0	THEN m.Sporttype ELSE 0 END, 
					CASE WHEN s.SubProduct IN ('MG-SuperLive', 'BT-Sold','BT-Bought','BT-Comm') THEN s.SubProduct ELSE '' END
			)
	INSERT INTO #winning (ProductID, Sporttype, SubProduct, Winlost, Winlostdate, GroupID)
	SELECT w.ProductID, w.Sporttype, w.SubProduct, SUM(w.Winlost * s.ExtraPT) AS Winlost, w.Winlostdate, s.GroupId
	FROM wl w
	INNER JOIN bodb_Acc.dbo.Acc_GroupExtraPTSetting s WITH (NOLOCK)
			ON w.srecommend = s.SuperId
			AND w.ProductId = s.ProductId
			AND w.SubProduct = s.SubProduct
			AND w.Sporttype = s.Sporttype 
			AND w.winlostdate BETWEEN s.FromDate AND s.ToDate	
	GROUP BY w.ProductID, w.Sporttype, w.SubProduct, w.Winlostdate, s.GroupId

	---Last reset

	INSERT INTO @LastReset (CustID, [Reset], Winlostdate, GroupID)
	SELECT b.custid, ROUND(SUM(ISNULL(b.winlost, 0) - ISNULL(b.actual_stake, 0)), 2) AS [Reset], b.winlostdate, d.GroupID
	FROM bettrans b WITH(READPAST)
	INNER JOIN (SELECT DISTINCT CustID, GroupID FROM @dummy) d
		ON b.custid = d.CustID
	WHERE b.bettype IN (21001, 21002)
		AND b.winlostdate BETWEEN @fromdate AND @todate
	GROUP BY b.custid, b.winlostdate, d.GroupID

	IF @mode = 0 -- view
	BEGIN
		
		;WITH WL AS ( 	
			SELECT  GroupID,
					SUM(Winlost) AS Winlost,
					Winlostdate
			FROM #winning 
			GROUP BY GroupID, Winlostdate
		)
		SELECT DM.GroupId, DM.GroupName, ROUND(ISNULL(W.Winlost,0), 2) AS Winlost, ROUND(ISNULL(W.[Reset],0), 2) AS [Reset], DM.Winlostdate
		FROM @dummy AS DM
		LEFT JOIN (
			SELECT  ISNULL(w.GroupId, rs.GroupID) AS GroupID,
					ROUND(SUM(ISNULL(w.Winlost, 0)), 2) AS Winlost,
					ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS [Reset],
					ISNULL(w.Winlostdate, rs.Winlostdate) AS Winlostdate
			FROM WL w
			FULL OUTER JOIN @LastReset rs
				ON w.GroupId = rs.GroupID AND w.Winlostdate = rs.Winlostdate
			GROUP BY ISNULL(w.GroupId, rs.GroupID), ISNULL(w.Winlostdate, rs.Winlostdate)
		) AS W
			ON DM.GroupID = W.GroupID AND DM.Winlostdate = W.Winlostdate
		ORDER BY DM.Winlostdate DESC, DM.GroupID ASC		

	END
	ELSE IF @mode = 1 -- reset
	BEGIN
		;WITH WL AS ( 	
			SELECT  GroupID,
					SUM(Winlost) AS Winlost,
					Winlostdate
			FROM #winning 
			GROUP BY GroupID, Winlostdate
		)
		INSERT INTO @reset (CustID, Winlost, [Reset], Variance, Winlostdate, GroupID, GroupName)
		SELECT DM.CustID, ROUND(ISNULL(W.Winlost,0), 2) AS Winlost, ROUND(ISNULL(W.[Reset],0), 2) AS [Reset], ROUND(ISNULL(W.Variance,0), 2) as Variance, DM.Winlostdate, DM.GroupID, DM.GroupName
		FROM @dummy DM
		LEFT JOIN (
			SELECT  ROUND(SUM(ISNULL(w.Winlost, 0)), 2) AS Winlost,
					ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS [Reset],
					ROUND(SUM(-ISNULL(w.Winlost, 0)), 2) - ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS Variance,
					ISNULL(w.Winlostdate, rs.winlostdate) AS Winlostdate,
					ISNULL(w.GroupId, rs.GroupID) AS GroupID
			FROM WL w
			FULL OUTER JOIN @LastReset rs
				ON w.GroupId = rs.GroupID AND w.Winlostdate = rs.Winlostdate
			GROUP BY ISNULL(w.GroupId, rs.GroupID), ISNULL(w.Winlostdate, rs.Winlostdate)
		) AS W
		ON DM.GroupID = W.GroupID AND DM.Winlostdate = W.Winlostdate

 
		DECLARE @variance     MONEY = 0,
                @winlostdate  SMALLDATETIME,
                @custid       INT,
                @resetCount   TINYINT = 0,
                @transDesc    VARCHAR(300)= '',
				@seq		  TINYINT = 1,
				@maxseq		  TINYINT
                
        SELECT @winlostdate = @fromdate

		SELECT
			@maxseq = MAX(GroupID),
			@resetCount = ISNULL(SUM(CASE WHEN Variance <> 0 THEN 1 ELSE 0 END), 0)
        FROM   @reset
        WHERE  WinlostDate = @WinlostDate

        IF (@resetCount = 0)
        BEGIN
            SELECT @ErrMsg = 'No codes need to reset winning!',
                   @ErrCode = 2
            RETURN
        END

        WHILE (@seq <= @maxseq)
        BEGIN
            SET @variance = 0

            SELECT @variance = Variance,
                   @custid = CustID
            FROM @reset
            WHERE GroupID = @seq
				AND WinlostDate = @WinlostDate
				 

            IF (@variance <> 0)
            BEGIN
                SELECT @transDesc = 'DWL-' + CAST(@fromdate as varchar(30))
                                           + CAST(@custid as varchar(50)) + ':'
                                           + CAST(@variance as varchar(100))

               EXEC DBTXN.bodb02.dbo.Task_ResetWinning_Non3rdParty_Add
                    @winlostdate = @winlostdate,
	                @custid = @custid,
	                @amount = @variance,
	                @transdesc = @transDesc,
	                @creator = @creator,
	                @ip = @ip,
					@isExtraPT = 1,
	                @ErrCode = @ErrCode OUTPUT,
                    @ErrMsg = @ErrMsg OUTPUT

                IF (@ErrCode <> 0) BREAK
                                    
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Transfer
					@UserID = @creator,
					@FromCustID = 0,
					@ToCustID = @custid,
					@IP = @ip,
					@Doing = @transDesc
            END

            SET @seq = @seq + 1

            SELECT @ErrMsg = 'The process has been successful!'
        END
      
        SELECT GroupID,
			   GroupName,
			   winlostdate,
               ISNULL(SUM(winlost), 0) AS winlost,
               ISNULL(SUM([reset]), 0) + ISNULL(SUM(Variance), 0) AS totalreset,
               ISNULL(SUM(Variance), 0) AS latestreset
        FROM @reset
		GROUP BY GroupID, GroupName, winlostdate
		ORDER BY winlostdate DESC, GroupID ASC
	END

	DROP TABLE #winning
END
GO

GRANT EXECUTE ON [dbo].[Task_ResetWinning_ExtraPT] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Task_ResetWinning_ExtraPT] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_ResetWinning_ExtraPT] TO [vnteam] AS [dbo]
GO