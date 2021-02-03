/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_ResetWinning_ExtraPT14]
	@fromdate SMALLDATETIME,
	@todate   SMALLDATETIME,
	@mode     TINYINT = 0,
	@creator  INT = 5838421,
	@ip       VARCHAR(20) = '',
	@ErrCode  INT = 0 OUTPUT,
    @ErrMsg   VARCHAR(100) = '' OUTPUT
AS
/*
	Creator: Sophia
	Date: 20191014	
	DB: DBACC.bodb02
	Task: Reset ExtraPT - range Bettrans14 - in recover 7 days [redmine: #115377]

	Revisions:
		- 20191014@Sophia: initial SP [redmine :#115377]
		- 20190826@Sophia: CN88 Headline balance - Exclude reset winning for CN88 group [Redmine: #117863]
		- 20200407@Percy: Using new column bettrans.epositiontaking instead of Acc_GroupExtraPTSetting.ExtraPT [RedmineID: #131696]
		- 2020714@Sophia: Add PP Jackpot[Redmine: #137270]
		- 20210203@Malcolm : Add Saba.club (Amount due to Jackpot Pool) into Reset winning [RedmineId : #149409]
		
	Param's explain:
		@mode:  0 _ view report
	            1 _ reset balance
	          
	    @ErrCode: 0 _ Success
	              1 _ Error
	              2 _ Already reset
 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @dummy TABLE (CustID INT, GroupID TINYINT, GroupName VARCHAR(50), Winlostdate SMALLDATETIME)
	CREATE TABLE #winning (GroupId TINYINT, Winlostdate SMALLDATETIME, Winlost MONEY)
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

	DELETE @SportBettype WHERE ProductId NOT IN (SELECT DISTINCT ProductID FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK))

	----- End get sport bettype 
	
	DECLARE @SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)
	
	IF  (@SQL like '%_xtest%')
	BEGIN
		INSERT INTO @dummy (CustID, GroupID, GroupName, Winlostdate)	
		SELECT DISTINCT e.CustID, e.GroupID, e.GroupName, d.WLDate
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT_xtest e WITH (NOLOCK)
		CROSS JOIN @Date d
		WHERE e.IsDisabled = 0
	END
	ELSE
	BEGIN
		INSERT INTO @dummy (CustID, GroupID, GroupName, Winlostdate)	
		SELECT DISTINCT e.CustID, e.GroupID, e.GroupName, d.WLDate
		FROM bodb_ACC.dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK)
		CROSS JOIN @Date d
		WHERE e.IsDisabled = 0
	END


	/* winlost */
	
	-- General data --
	;WITH wl AS
	(
		SELECT b.srecommend, b.winlostdate,
			SUM((
				CASE
					-- Jackpot
					WHEN b.bettype IN (1698, 2198, 2398, 2998, 4297) THEN
						CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
					WHEN b.bettype IN (1699, 2199, 2399, 2999, 4298) THEN 0
					ELSE
						CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake + b.scomm / (1 - b.tpositiontaking) END
					END) * b.actualrate * b.epositiontaking) AS Winlost
		FROM dbo.bettrans14 b WITH (READPAST)
			INNER JOIN @SportBettype s ON s.BetType = b.bettype
		WHERE b.winlostdate BETWEEN @fromdate AND @todate
			AND b.statusid NOT IN (101, 102, 103, 121)
		GROUP BY b.srecommend, b.winlostdate
	)
	INSERT INTO #winning (GroupId, Winlostdate, Winlost)
	SELECT s.GroupId, w.winlostdate, SUM(w.Winlost)
	FROM wl w
		CROSS APPLY (
			SELECT TOP 1 s.GroupId
			FROM dbo.Acc_GroupExtraPTSetting s WITH (NOLOCK)
			WHERE s.SuperId = w.srecommend
				AND w.winlostdate BETWEEN s.FromDate AND s.ToDate
				AND s.GroupID NOT IN (4, 5, 6) --- ACCTHAI2,ACCTHAI56,ACCTHAI99
		) s
	GROUP BY s.GroupId, w.winlostdate

	---Last reset
	INSERT INTO @LastReset (CustID, [Reset], Winlostdate, GroupID)
	SELECT b.custid, ROUND(SUM(ISNULL(b.winlost, 0) - ISNULL(b.actual_stake, 0)), 2) AS [Reset], b.winlostdate, d.GroupID
	FROM bettrans b WITH (READPAST)
	INNER JOIN (SELECT DISTINCT CustID, GroupID FROM @dummy) d
		ON b.custid = d.CustID
	WHERE b.bettype IN (21001, 21002)
		AND b.winlostdate BETWEEN @fromdate AND @todate
	GROUP BY b.custid, b.winlostdate, d.GroupID

	IF @mode = 0 -- view
	BEGIN
		SELECT dm.GroupId, dm.GroupName, ROUND(ISNULL(w.Winlost,0 ), 2) AS Winlost, ROUND(ISNULL(w.[Reset],0), 2) AS [Reset], dm.Winlostdate
		FROM @dummy dm
		LEFT JOIN (
			SELECT  ISNULL(w.GroupId, rs.GroupID) AS GroupID,
					ROUND(SUM(ISNULL(w.Winlost, 0)), 2) AS Winlost,
					ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS [Reset],
					ISNULL(w.Winlostdate, rs.Winlostdate) AS Winlostdate
			FROM #winning w
			FULL OUTER JOIN @LastReset rs
				ON w.GroupId = rs.GroupID AND w.Winlostdate = rs.Winlostdate
			GROUP BY ISNULL(w.GroupId, rs.GroupID), ISNULL(w.Winlostdate, rs.Winlostdate)
		) AS w
			ON dm.GroupID = w.GroupID AND dm.Winlostdate = w.Winlostdate
		ORDER BY dm.Winlostdate DESC, dm.GroupID ASC		
	END
	ELSE IF @mode = 1 -- reset
	BEGIN
		INSERT INTO @reset (CustID, Winlost, [Reset], Variance, Winlostdate, GroupID, GroupName)
		SELECT	dm.CustID,
				ROUND(ISNULL(W.Winlost, 0), 2) AS Winlost,
				ROUND(ISNULL(W.[Reset],0), 2) AS [Reset],
				ROUND(ISNULL(W.Variance, 0), 2) as Variance,
				dm.Winlostdate, dm.GroupID, dm.GroupName
		FROM @dummy dm
		LEFT JOIN (
			SELECT  ROUND(SUM(ISNULL(w.Winlost, 0)), 2) AS Winlost,
					ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS [Reset],
					ROUND(SUM(-ISNULL(w.Winlost, 0)), 2) - ROUND(SUM(ISNULL(rs.[Reset], 0)), 2) AS Variance,
					ISNULL(w.Winlostdate, rs.winlostdate) AS Winlostdate,
					ISNULL(w.GroupId, rs.GroupID) AS GroupID
			FROM #winning w
			FULL OUTER JOIN @LastReset rs
				ON w.GroupId = rs.GroupID AND w.Winlostdate = rs.Winlostdate
			GROUP BY ISNULL(w.GroupId, rs.GroupID), ISNULL(w.Winlostdate, rs.Winlostdate)
		) AS W
			ON dm.GroupID = w.GroupID AND dm.Winlostdate = w.Winlostdate

		DECLARE @variance		MONEY = 0,
                @winlostdate	SMALLDATETIME,
                @custid			INT,
                @resetCount		TINYINT = 0,
                @transDesc		NVARCHAR(1000)= '',
				@seq			TINYINT = 1,
				@maxseq			TINYINT,
				@LogData  		NVARCHAR(200) = ''	
                
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
				
				----Adjust statement
				EXEC bodb_report.dbo.[Acc_StatementUpdateTransfer]
					@custid = @custid
					,@Amount = @variance
					,@winlostdate = @winlostdate
					,@ErrCode = @ErrCode OUTPUT
					,@ErrMsg = @ErrMsg OUTPUT							

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