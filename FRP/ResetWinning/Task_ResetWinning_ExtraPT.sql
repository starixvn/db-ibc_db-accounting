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

	Revisions:

	Param's explain:
		@mode:  0 _ view report
	            1 _ reset balance
	            
	    @ErrCode: 0 _ Success
	              1 _ Error
	              2 _ Already reset
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)
	DECLARE @dummy TABLE (CustID INT)
	DECLARE @winning TABLE (SuperID INT, ProductID TINYINT, Sporttype INT, SubProduct VARCHAR(500), Winloss MONEY, Winlostdate DATETIME)
	DECLARE @reset TABLE (SuperID INT, Winloss MONEY, [Reset] MONEY, Variance MONEY, Winlostdate DATETIME, GroupID TINYINT, GroupName VARCHAR(50))
	IF  (@SQL like '%_xtest%' OR @SQL like '%_xpre%')
	BEGIN
		INSERT INTO @dummy (CustID)
		SELECT DISTINCT CustID FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest WITH(NOLOCK)
	END
	ELSE
	BEGIN
		INSERT INTO @dummy (CustID)
		SELECT DISTINCT CustID FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK)
	END

	/* winloss */

	-- General data (all)
	INSERT INTO @winning (SuperID, ProductID, Sporttype, SubProduct, Winloss, Winlostdate)
	SELECT b.srecommend, s.ProductID, 0, '',
		SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
	    ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0))*ISNULL(actualrate, 0)) as winloss, b.winlostdate
	FROM bettrans b WITH(NOLOCK)
	INNER JOIN bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '') s
		ON s.BetType = b.bettype
	WHERE srecommend IN (SELECT DISTINCT SuperID FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))
		AND b.winlostdate BETWEEN @fromdate AND @todate
		AND s.ProductID IN (SELECT DISTINCT ProductID FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))
		AND b.ruben = 1
		AND statusID NOT IN (101, 102, 103, 121)
		AND b.bettype < 19000
	GROUP BY b.winlostdate, b.srecommend, s.ProductID

	-- Exclude MG-SupperLive
	INSERT INTO @winning (SuperID, ProductID, Sporttype, SubProduct, Winloss, Winlostdate)
	SELECT b.srecommend, 1 AS ProductID, 0 AS Sporttype, 'MG-SuperLive' AS SubProduct,
		SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
		ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0))*ISNULL(actualrate, 0)) as winloss, b.winlostdate
	FROM bettrans b WITH(NOLOCK)
	INNER JOIN bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, 'MG-SuperLive', '') s
		ON s.BetType = b.bettype
	WHERE srecommend IN (SELECT DISTINCT SuperID FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))
		AND b.winlostdate BETWEEN @fromdate AND @todate
		AND b.ruben = 1
		AND statusID NOT IN (101, 102, 103, 121)
		AND b.bettype < 19000
	GROUP BY b.winlostdate, b.srecommend, s.ProductID

	/* reset */

	IF @mode = 0 -- view
	BEGIN
		INSERT INTO @reset (SuperID, Winloss, Winlostdate)
		SELECT custid,
			SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
			ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0))*ISNULL(actualrate, 0)) as winloss, winlostdate
		FROM bettrans WITH(NOLOCK)
		WHERE custid IN (SELECT CustID FROM @dummy)
			AND bettype IN (21001, 21002)
			AND winlostdate BETWEEN @fromdate AND @todate
		GROUP BY custid, winlostdate

		SELECT B.SuperID, B.Winloss, rs.Winloss AS [reset], B.Winlostdate, G.GroupId, G.GroupName
		FROM (
			SELECT SuperID, ProductID, Sporttype, SubProduct, SUM(Winloss) AS Winloss, Winlostdate
			FROM (
				SELECT SuperID, ProductID, 0 AS Sporttype, '' AS SubProduct,
					CASE WHEN SubProduct = 'MG-SuperLive' THEN -Winloss ELSE Winloss END AS Winloss,
					Winlostdate
				FROM @winning
			) AS A
			GROUP BY SuperID, ProductID, Sporttype, SubProduct, Winlostdate
		) AS B
		INNER JOIN (
			SELECT * FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE Sporttype = 0 AND SubProduct = ''
		) AS G
			ON B.SuperID = g.SuperId AND B.ProductID = G.ProductId AND B.Sporttype = G.Sporttype AND B.SubProduct = G.SubProduct
		LEFT JOIN @reset rs
			ON B.SuperID = rs.SuperID AND B.Winlostdate = rs.Winlostdate
		ORDER BY G.GroupID
	END
	ELSE IF @mode = 1 -- reset
	BEGIN
		INSERT INTO @reset (SuperID, Winloss, [Reset], Variance, Winlostdate, GroupID, GroupName)
		SELECT B.SuperID, B.Winloss, rs.Winloss, B.Winloss - rs.winloss, B.Winlostdate, G.GroupID, G.GroupName
		FROM (
			SELECT SuperID, ProductID, Sporttype, SubProduct, SUM(Winloss) AS Winloss, Winlostdate
			FROM (
				SELECT SuperID, ProductID, 0 AS Sporttype, '' AS SubProduct,
					CASE WHEN SubProduct = 'MG-SuperLive' THEN -Winloss ELSE Winloss END AS Winloss,
					Winlostdate
				FROM @winning
			) AS A
			GROUP BY SuperID, ProductID, Sporttype, SubProduct, Winlostdate
		) AS B
		INNER JOIN (
			SELECT * FROM bodb_ACC.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE Sporttype = 0 AND SubProduct = ''
		) AS G
			ON B.SuperID = g.SuperId AND B.ProductID = G.ProductId AND B.Sporttype = G.Sporttype AND B.SubProduct = G.SubProduct
		INNER JOIN (
			SELECT custid,
				SUM((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
				ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0))*ISNULL(actualrate, 0)) as winloss, winlostdate
			FROM bettrans WITH(NOLOCK)
			WHERE custid IN (SELECT CustID FROM @dummy)
				AND bettype IN (21001, 21002)
			GROUP BY custid, winlostdate
		) AS RS
			ON B.SuperID = rs.custid AND B.Winlostdate = rs.Winlostdate


		DECLARE @variance     money = 0,
                @winlostdate  datetime,
                @custid       int,
                @resetCount   tinyint = 0,
                @transDesc    varchar(300)= '',
				@seq		  tinyint = 1,
				@maxseq		  tinyint
                
        SELECT @WinlostDate = @FromDate

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
                   @custid = SuperID
            FROM @reset
            WHERE GroupID = @seq
				AND WinlostDate = @WinlostDate

            IF (@variance <> 0)
            BEGIN
                SELECT @transDesc = 'DWL-' + CAST(@fromdate as varchar(30))
                                           + CAST(@custid as varchar(50)) + ':'
                                           + CAST(@variance as varchar(100))

                EXEC DBTRANS.bodb02.dbo.Task_ResetWinning_ExtraPT_Add
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
      
        SELECT winlostdate,
               winloss,
               [reset] + Variance AS totalreset,
               Variance,
			   GroupID,
			   GroupName
        FROM @reset
		ORDER BY GroupID
	END
END

GO

GRANT EXECUTE ON [dbo].[Task_ResetWinning_ExtraPT] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Task_ResetWinning_ExtraPT] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_ResetWinning_ExtraPT] TO [vnteam] AS [dbo]
GO