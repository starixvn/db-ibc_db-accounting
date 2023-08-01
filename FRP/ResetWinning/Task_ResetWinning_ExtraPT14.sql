/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_ResetWinning_ExtraPT14]
	@fromdate SMALLDATETIME,
	@todate   SMALLDATETIME,
	@mode     TINYINT = 0,
	@creator  INT = 5838421,
	@ip       VARCHAR(45) = '',
	@ErrCode  INT = 0 OUTPUT,
    @ErrMsg   VARCHAR(100) = '' OUTPUT,
	@SiteDBGroupID SMALLINT = 0,
	@resetData1		VARCHAR(8000) = '' OUTPUT,
	@resetData2		VARCHAR(8000) = '' OUTPUT,
	@resetData3		VARCHAR(8000) = '' OUTPUT,
	@resetData4		VARCHAR(8000) = '' OUTPUT,
	@resetData5		VARCHAR(8000) = '' OUTPUT
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
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
		- 20210512@Malcolm : Add VGaming (Amount due to Jackpot Pool) into Reset winning [RedmineId : #154643]
		- 20220106@Evan: Add SG Jackpot - [Redmine: #166685]	
		- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
		- 20220425@Evan: Remove Casino Jackpot Amount [Redmine: #171865]
		- 20230522@Lewis: Call sum Sps on other servers - [RedmineID: #188463]
		- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
		- 20221024@Sol: Database - Sync-up Standby Server data - [RedmineID: #167261]
		- 20220614@Danny: Database - scale out credit [RedmineID: #181595]
		
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
	
	--Get BU date
	DECLARE @balanceUpDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @balanceUpDay = BalanceUpDay FROM @tblMoveBetBalanceUp

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
		FROM dbo.Acc_DWLList_ExtraPT_xtest e WITH (NOLOCK)
		CROSS JOIN @Date d
		WHERE e.IsDisabled = 0
	END
	ELSE
	BEGIN
		INSERT INTO @dummy (CustID, GroupID, GroupName, Winlostdate)	
		SELECT DISTINCT e.CustID, e.GroupID, e.GroupName, d.WLDate
		FROM dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK)
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
					WHEN b.bettype IN (1698, 3898, 4297, 4599) THEN
						CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
					WHEN b.bettype IN (1699, 3899, 4298, 4600) THEN 0
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
	FROM dbo.Transfer b WITH (READPAST)
	INNER JOIN (SELECT DISTINCT CustID, GroupID FROM @dummy) d
		ON b.custid = d.CustID
	WHERE b.bettype IN (21001, 21002)
		AND b.winlostdate BETWEEN @fromdate AND @todate
		AND b.winlostdate >= @balanceUpDay
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
				@LogData  		NVARCHAR(200) = ''
                
        SELECT @winlostdate = @fromdate


		DECLARE @resetData VARCHAR(MAX) = ''
		--WLDate, amount, transdesc, creator, ip
		SELECT @resetData = CAST
		(
		(
			SELECT @winlostdate AS '@WLDate' ,
					r.CustID  AS '@CustID' ,
					r.Variance AS '@amount' ,
					'DWL-' + CAST(@fromdate as varchar(30))
							+ CAST(r.CustID as varchar(50)) + ':'
							+ CAST(r.Variance as varchar(100)) AS '@transdesc',
					@creator  AS '@creator' ,
					@ip		 AS '@ip'
			FROM @reset r
			INNER JOIN dbo.Customer c WITH(NOLOCK) ON r.CustID = c.custid
			INNER JOIN dbo.Site s WITH(NOLOCK) ON s.site = c.site
			WHERE r.WinlostDate = @WinlostDate AND s.SiteDBGroupID = @SiteDBGroupID AND r.Variance <> 0

			FOR XML PATH('z'), ROOT('ROOT')
		)  AS VARCHAR(MAX))

		SELECT @resetData1 = SUBSTRING(@resetData, 1, 8000) ;
		SELECT @resetData2 = SUBSTRING(@resetData, 8001, 8000) ;
		SELECT @resetData3 = SUBSTRING(@resetData, 16001, 8000) ;
		SELECT @resetData4 = SUBSTRING(@resetData, 24001, 8000) ;
		SELECT @resetData5 = SUBSTRING(@resetData, 32001, 8000) ;

	END

	DROP TABLE #winning
END
GO
