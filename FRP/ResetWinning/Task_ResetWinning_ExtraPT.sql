ALTER PROCEDURE [dbo].[Task_ResetWinning_ExtraPT]
	@fromdate DATETIME,
	@todate   DATETIME,
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

	Param's explain:
		@mode:  0 _ view report
	            1 _ reset balance
	            
	    @ErrCode: 0 _ Success
	              1 _ Error
	              2 _ Already reset

	Noted: use inline func: bodb02.dbo.f_SportBettypeMatrix_Sel(@ProductID, @Sporttype, @Bettype, @SubProduct, @ProductPrefix)
			instead of sp Acc_SportBettypeMatrix_Sel
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)
	DECLARE @dummy TABLE (CustID INT, GroupID TINYINT, GroupName VARCHAR(50))
	DECLARE @winning TABLE (SuperID INT, ProductID TINYINT, Sporttype INT, SubProduct VARCHAR(500), Winlost MONEY, Winlostdate DATETIME)
	DECLARE @reset TABLE (CustID INT, Winlost MONEY, [Reset] MONEY, Variance MONEY, Winlostdate DATETIME, GroupID TINYINT, GroupName VARCHAR(50))

	IF  (@SQL like '%_xtest%')
	BEGIN
		INSERT INTO @dummy (CustID, GroupID, GroupName)	
		SELECT  DISTINCT CustID, GroupID, GroupName
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest WITH (NOLOCK)
	END
	ELSE
	BEGIN
		INSERT INTO @dummy (CustID, GroupID, GroupName)	
		SELECT  DISTINCT CustID, GroupID, GroupName
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT WITH (NOLOCK)
	END

	/* winlost */
	
	-- General data --
	-- Other products (exclude SportBook)
	INSERT INTO @winning (SuperID, ProductID, Sporttype, SubProduct, Winlost, Winlostdate)
	SELECT b.srecommend, s.ProductID, 0 AS Sporttype, '' AS SubProduct,
		SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
	    ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0))*ISNULL(actualrate, 0)) AS Winlost, b.winlostdate
	FROM bettrans b WITH(NOLOCK)
	INNER JOIN bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '') s
		ON s.BetType = b.bettype
	WHERE srecommend IN (SELECT DISTINCT SuperID FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))
		AND b.winlostdate BETWEEN @fromdate AND @todate
		AND s.ProductID IN (SELECT DISTINCT ProductID FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))
		AND s.ProductID <> 1 -- SportBook
		AND b.ruben = 1
		AND b.statusID NOT IN (101, 102, 103, 121)
		--AND b.bettype < 19000
	GROUP BY b.winlostdate, b.srecommend, s.ProductID

	-- SportBook (exclude MG-SuperLive, Bettrade)
	INSERT INTO @winning (SuperID, ProductID, Sporttype, SubProduct, Winlost, Winlostdate)
	SELECT b.srecommend, 1 AS ProductID, ISNULL(m.sporttype, 0) /* MuayThai = 44, other = 0*/ AS Sporttype, '' AS SubProduct,
		SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
			ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0))*ISNULL(actualrate, 0)) AS Winlost, b.winlostdate
	FROM bettrans b WITH(NOLOCK)
	INNER JOIN bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, '', '') s
		ON s.BetType = b.bettype
	LEFT JOIN bodb02.dbo.match m WITH(NOLOCK)
		ON m.matchid = b.matchid AND m.eventdate = b.winlostdate AND m.sporttype = 44 -- MuayThai
	WHERE srecommend IN (SELECT DISTINCT SuperID FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))
		AND b.winlostdate BETWEEN @fromdate AND @todate
		AND b.ruben = 1
		AND b.statusID NOT IN (101, 102, 103, 121)
		--AND b.bettype < 19000
		AND b.bettype NOT IN (
			-- MG-SupperLive
			SELECT Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, 'MG-SuperLive', '')
			-- Bettrade
			UNION
			SELECT Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, 'BT-Comm', '')
			UNION
			SELECT Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, 'BT-Sold', '')
			UNION
			SELECT Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, 'BT-Bought', '')
		)
	GROUP BY b.winlostdate, b.srecommend, ISNULL(m.sporttype, 0)

	-- MG-SupperLive, Bettrade
	INSERT INTO @winning (SuperID, ProductID, Sporttype, SubProduct, Winlost, Winlostdate)
	SELECT b.srecommend, 1 AS ProductID, 0 AS Sporttype, s.SubProduct,
		SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
		ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0))*ISNULL(actualrate, 0)) as Winlost, b.winlostdate
	FROM bettrans b WITH(NOLOCK)
	INNER JOIN (
		-- MG-SupperLive
		SELECT SubProduct, Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, 'MG-SuperLive', '')
		-- Bettrade
		UNION
		SELECT SubProduct, Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, 'BT-Comm', '')
		UNION
		SELECT SubProduct, Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, 'BT-Sold', '')
		UNION
		SELECT SubProduct, Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, 'BT-Bought', '')
	) AS s
		ON s.BetType = b.bettype
	WHERE srecommend IN (SELECT DISTINCT SuperID FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))
		AND b.winlostdate BETWEEN @fromdate AND @todate
		AND b.ruben = 1
		AND b.statusID NOT IN (101, 102, 103, 121)
		--AND b.bettype < 19000
	GROUP BY b.winlostdate, b.srecommend, s.SubProduct


	/* reset */

	IF @mode = 0 -- view
	BEGIN
		INSERT INTO @reset (CustID, Winlost, Winlostdate, GroupID)
		SELECT b.custid, SUM(ISNULL(b.winlost, 0) - ISNULL(b.actual_stake, 0)) AS Winlost, b.winlostdate, d.GroupID
		FROM bettrans b WITH(NOLOCK)
		INNER JOIN @dummy d
			ON b.custid = d.CustID
		WHERE b.bettype IN (21001, 21002)
			AND b.winlostdate BETWEEN @fromdate AND @todate
		GROUP BY b.custid, b.winlostdate, d.GroupID

		;WITH DWL AS (
			SELECT G.GroupId, ISNULL(SUM(W.Winlost*G.ExtraPT), 0) AS Winlost, W.Winlostdate
			FROM @winning W
			INNER JOIN bodb_ACC.dbo.Acc_GroupExtraPTSetting G WITH(NOLOCK)
					 ON W.SuperID = G.SuperId
					AND W.ProductID = G.ProductId
					AND W.Sporttype = G.Sporttype
					AND W.SubProduct = G.SubProduct
					AND (W.Winlostdate >= G.FromDate AND W.Winlostdate <= G.ToDate)
			GROUP BY G.GroupId, W.Winlostdate
		)
		SELECT DM.GroupId, DM.GroupName, D.Winlost, ISNULL(rs.Winlost, 0) AS [Reset], D.Winlostdate
		FROM @dummy AS DM
		LEFT JOIN DWL AS D
			ON DM.GroupID = D.GroupId
		LEFT JOIN @reset AS rs
			ON D.GroupId = rs.GroupID AND D.Winlostdate = rs.Winlostdate
		ORDER BY D.Winlostdate DESC, D.GroupID ASC
	END
	ELSE IF @mode = 1 -- reset
	BEGIN
		;WITH DWL AS (
			SELECT G.GroupId, G.GroupName, ISNULL(SUM(W.Winlost*G.ExtraPT), 0) AS Winlost, W.Winlostdate
			FROM @winning W
			INNER JOIN bodb_ACC.dbo.Acc_GroupExtraPTSetting G WITH(NOLOCK)
					 ON W.SuperID = G.SuperId
					AND W.ProductID = G.ProductId
					AND W.Sporttype = G.Sporttype
					AND W.SubProduct = G.SubProduct
					AND (W.Winlostdate >= G.FromDate AND W.Winlostdate <= G.ToDate)
			GROUP BY G.GroupId, G.GroupName, W.Winlostdate
		)
		INSERT INTO @reset (CustID, Winlost, [Reset], Variance, Winlostdate, GroupID, GroupName)
		SELECT R.CustID, ISNULL(D.Winlost, 0), ISNULL(R.Winlost, 0), - ISNULL(D.Winlost, 0) - ISNULL(R.Winlost, 0), D.Winlostdate, D.GroupId, D.GroupName
		FROM DWL AS D
		LEFT JOIN (
			SELECT b.custid, SUM(ISNULL(b.winlost, 0) - ISNULL(b.actual_stake, 0)) AS Winlost, b.winlostdate, d.GroupID, d.GroupName
			FROM bettrans b WITH(NOLOCK)
			INNER JOIN @dummy d
				ON b.custid = d.CustID
			WHERE b.bettype IN (21001, 21002)
				AND b.winlostdate BETWEEN @fromdate AND @todate
			GROUP BY b.custid, b.winlostdate, d.GroupID, d.GroupName
		) AS R
			ON D.GroupId = R.GroupID AND D.Winlostdate = R.Winlostdate

		DECLARE @variance     MONEY = 0,
                @winlostdate  DATETIME,
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
            SELECT @ErrMsg = 'No products need to reset winning!',
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

                EXEC DBTRANS.bodb02.dbo.Task_ResetWinning_Non3rdParty_Add
                    @winlostdate = @winlostdate,
	                @custid = @custid,
	                @amount = @variance,
	                @transdesc = @transDesc,
	                @creator = @creator,
	                @ip = @ip,
	                @ErrCode = @ErrCode OUTPUT,
                    @ErrMsg = @ErrMsg OUTPUT

                IF (@ErrCode <> 0) BREAK
                    
                IF (@seq = @maxseq)
                BEGIN
	                EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Transfer
	                    @UserID = @creator,
	                    @FromCustID = 0,
	                    @ToCustID = @custid,
	                    @IP = @ip,
	                    @Doing = @transDesc
                END
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
END

GO

GRANT EXECUTE ON [dbo].[Task_ResetWinning_ExtraPT] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Task_ResetWinning_ExtraPT] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_ResetWinning_ExtraPT] TO [vnteam] AS [dbo]
GO