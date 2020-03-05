/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_StatementFinance]
    @RefNo BIGINT = 0,
	@Username VARCHAR(30) = null,
	@UserId INT = NULL,
	@FilterBy TINYINT = null,
	@FromDate DATETIME = null,
	@ToDate DATETIME = null,
	@BalanceUpDay DATETIME = null,
	@IncludeAccBal BIT = 0
AS
 /*
	Created by: 20120730@Don
	Task: Get Statement of Finance report
	DB: DBACC/bodb02 
	
	Revisions:
		- 20130724@Jamie: Change Alias 
			+ DB052 --> DBEXT 
			+ DB053/bodb_Summary --> DBSUM
			+ bodb_Report --> DBRPT/bodb_Report
		- 20160602@Percy: Hotfix - Opening balance is shown wrongly [Redmine: #58410]
		- 20160824@Lukas: add param @UserId for checking permission before query data
		- 20180731@Percy: Expand column transdesc [RedmineID: #92841]
		- 20181107@Louis: Credit Collection [Redmine: #98621]
		- 20190114@Sophia: Move table transfer_fi from DBSUM.bodb_summary to DBARC.bodb_archive [Redmine: #105415]
		- 20190502@Percy: Fix issue duplicate data when BU process (copy data) [RedmineID: #112525]
		- 20191113@Louis: Hot Fix Credit Collection BK [Redmine: #123812]
		- 20200305@Elodie: Hardcode list finance permission [Redmine: #129890]

    Param's Explanation:
        - @FilterBy: 1:winlostdate - 2:transdate
        - @IncludeAccBal: 1:include - 0:exclude
        
    Sample:
				EXEC [dbo].[Acc_StatementFinance] @RefNo = -1,@Username = 'DWLSPNL',@FilterBy = 1,@FromDate = '2012-07-21',@ToDate = '2012-08-04',@BalanceUpDay = '',@IncludeAccBal = 1

 */
BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #StatementTable(
		TransID BIGINT,
		TransDate DATETIME,
		WinlostDate SMALLDATETIME,
		RefNo BIGINT,
		TotalAmt MONEY,
		TransType NVARCHAR(100),
		TransDesc NVARCHAR(1000),
		Creator INT,
		CheckerID INT NULL,
		CheckerName VARCHAR(50) NULL,
		CheckTime DATETIME NULL,
		IsAllowVerify BIT DEFAULT 0,
		IsReversal BIT DEFAULT 0,
		IsExpand BIT DEFAULT 0
	)

	DECLARE @CustomerId INT, @srecommend INT
	SELECT @CustomerId = custid, @srecommend = srecommend FROM dbo.Customer WITH (NOLOCK) WHERE username = @Username

	SET @UserId = ISNULL(@UserId,0)
	--- check permission for some admins
	IF (EXISTS (SELECT 1 FROM dbo.custinfo WITH(NOLOCK) WHERE username = @Username AND custid IN (7214059,7213826,7213962))
			AND @UserId NOT IN (4240930,4241056,14883115,26020,32648,2114533,2809,2937,347009,3720967,2218288,630505,1089853,276397,5014141,610439,2450,15312122,268028,8,22113608,53157,1274,13345,12576511,2462))
		OR (@UserId IN (2049420,	--CMTDXU
						772240,		--CNSDBENG
						41916921,	--N88.calvinckm
						15185422	--WENG
						)
				AND (@CustomerId NOT IN (41534504,41534596,41534543,41534488,41534580,41534539,41534479,41534574,41534535,41048221)
						OR @srecommend NOT IN (39744331,39744349,39744361,39744373,39744386,39744399,39744411,39744423,39744435,39744447,39744460,41799106,41799118,41799200,41799212)
					)
			)
	BEGIN
		SELECT TransID,
				TransDate,
				WinlostDate,
				RefNo,
				TotalAmt,
				TransType,
				TransDesc as [TransDescription],
				Creator,
				CheckerID,
				CheckerName,
				CheckTime,
				IsAllowVerify,
				IsReversal,
				IsExpand
		FROM #StatementTable

		DROP TABLE #StatementTable
		RETURN
	END


	DECLARE @_RefNo AS BIGINT
	SET @_RefNo = @RefNo

	DECLARE @_Username AS VARCHAR(30)
	SET @_Username = @Username

	DECLARE @_ToDate AS DATETIME
	SET @_ToDate = @ToDate
	SET @_ToDate = DATEADD(day,1,@_ToDate) -- where statement winlostdate/transdate < @_ToDate

	DECLARE @_FromDate AS DATETIME
	SET @_FromDate = @FromDate

	DECLARE @_BalanceUpDay AS DATETIME
	SET @_BalanceUpDay = @BalanceUpDay

	DECLARE @FromDate_Bk DATETIME
	SET @FromDate_Bk = @_FromDate

	DECLARE @_IncludeAccBal AS BIT
	SET @_IncludeAccBal = @IncludeAccBal

	DECLARE @CustID INT
	SELECT @CustID = custid FROM dbo.Customer (NOLOCK) WHERE username LIKE @_Username
	SET @CustID = ISNULL(@CustID,0)


	IF @_RefNo > 0
	BEGIN
    
		INSERT INTO #StatementTable(
				TransID,
				TransDate,
				WinlostDate,
				RefNo,
				TotalAmt,
				TransType,
				TransDesc,
				Creator,
				CheckerID,
				CheckerName,
				CheckTime,
				IsAllowVerify,
				IsReversal)
			SELECT 
				b.transid,
				b.transdate,
				b.winlostdate,
				b.refno,
				(b.winlost - b.actual_stake) totalamt,
				CASE WHEN b.oddsId = 0 THEN bettype.typenamee ELSE 'Coll' END transtype,
				b.transdesc + ' - Ex.Rate: ' + CAST(b.actualrate AS VARCHAR(10)) transdesc, 
				b.creator,
				CASE 
					WHEN b.bettype IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL 
					ELSE b.betid 
				END checkerID, --BalanceUP AND Transfer to Casino/Bingo/P2P
				CASE 
					WHEN b.bettype IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' 
					ELSE b.betcheck 
				END checkerName,
				CASE 
					WHEN b.bettype IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL 
					ELSE b.checkTime 
				END checkTime,
				CASE 
					WHEN b.bettype IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 
					ELSE 1 
				END isAllowVerify,
				CASE b.bettype WHEN 20000 THEN 1 ELSE b.liveindicator END isReversal
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = b.bettype 
			WHERE 
				b.matchid = 0
				AND b.refno = @_RefNo
				AND b.bettype >= 20000 
            
            
			IF NOT EXISTS( SELECT 1 FROM #StatementTable )
			BEGIN
        
				INSERT INTO #StatementTable(
						TransID,
						TransDate,
						WinlostDate,
						RefNo,
						TotalAmt,
						TransType,
						TransDesc,
						Creator,
						CheckerID,
						CheckerName,
						CheckTime,
						IsAllowVerify,
						IsReversal)
					SELECT 
						tf.transid,
						tf.transdate,
						tf.winlostdate,
						tf.refno,
						(tf.winlost - tf.actual_stake) totalamt,
						CASE WHEN EXISTS (SELECT 1 FROM bodb_archive.dbo.Transfer_Coll_BK tcbk WITH(NOLOCK) WHERE tcbk.TransID = tf.TransID) THEN 'Coll' ELSE bettype.typenamee END transtype,
						tf.transdesc + ' - Ex.Rate: ' + isnull(CAST(tf.actualrate AS VARCHAR(10)),'') transdesc, 
						tf.creator,
						NULL checkerID,
						'' checkerName,
						NULL checkTime,
						0 isAllowVerify,
						ISNULL(isReversal,0) isReversal
					FROM bodb_archive.dbo.transfer_fi tf WITH(NOLOCK)
						LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = tf.bettype 
					WHERE tf.refno = @_RefNo

			END
    
	END -- End of @_RefNo > 0

	IF (DATEADD(day,-1,@_ToDate) >= @_BalanceUpDay) AND (@CustID > 0)
	BEGIN

		IF (@_FromDate > @_BalanceUpDay)
			SELECT @_FromDate = @_BalanceUpDay
	
		INSERT INTO #StatementTable(
				TransID,
				TransDate,
				WinlostDate,
				RefNo,
				TotalAmt,
				TransType,
				TransDesc,
				Creator,
				CheckerID,
				CheckerName,
				CheckTime,
				IsAllowVerify,
				IsReversal)
			SELECT 
				b.transid,
				b.transdate,
				b.winlostdate,
				b.refno,
				(b.winlost - b.actual_stake) totalamt,
				CASE WHEN b.oddsId = 0 THEN bettype.typenamee ELSE 'Coll' END transtype,
				b.transdesc + ' - Ex.Rate: ' + CAST(b.actualrate AS VARCHAR(10)) transdesc, 
				b.creator,
				CASE 
					WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL 
					ELSE b.betid 
				END checkerID, --BalanceUP AND Transfer to Casino/Bingo/P2P
				CASE 
					WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN '0' 
					ELSE b.betcheck 
				END checkerName,
				CASE 
					WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN NULL 
					ELSE b.checkTime 
				END checkTime,
				CASE 
					WHEN bettype.typeid IN (20000,23001,23002,23101,23102,23201,23202) THEN 0 
					ELSE 1 
				END isAllowVerify,
				CASE b.bettype WHEN 20000 THEN 1 ELSE b.liveindicator END isReversal
			FROM dbo.bettrans b (NOLOCK) 
				LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = b.bettype 
			WHERE 
				b.matchid = 0
				AND b.custid = @CustID
				AND b.bettype >= 20000 
				AND 
					( (@FilterBy = 1 AND b.winlostdate >= @_FromDate AND b.winlostdate < @_ToDate)
					OR (@FilterBy = 2 AND b.transdate >= @_FromDate AND b.transdate < @_ToDate)
					)

		;WITH CTE_Statement AS (
			SELECT s.refno
			FROM #StatementTable s
				LEFT JOIN dbo.bettrans b (NOLOCK) ON s.refno = b.refno
			WHERE b.matchid = 0 AND b.bettype>20000
			GROUP BY s.refno
			HAVING COUNT(*) > 1
		)
		UPDATE s
		SET s.IsExpand = 1
		FROM #StatementTable s
			INNER JOIN CTE_Statement cte ON s.refno = cte.refno
		WHERE s.TransType NOT IN ('Dep','Wit')

	END		   

	DECLARE @HasOpeningBalanceInBettrans INT
	SELECT @HasOpeningBalanceInBettrans = COUNT(*)
	FROM #StatementTable
	WHERE TransType LIKE 'Bal'

	IF ( (@_FromDate < @_BalanceUpDay) OR (@HasOpeningBalanceInBettrans = 0) ) AND (@CustID > 0)
	BEGIN

		IF DATEADD(day,-1,@_ToDate) >= DATEADD(day,-1,@_BalanceUpDay)
			SELECT @_ToDate = @_BalanceUpDay -- where statement winlostdate/transdate < @_ToDate
	
		SELECT TOP 1 @_FromDate = ISNULL(accdate,@FromDate_Bk)
		FROM bodb_Report.dbo.Statement WITH (NOLOCK)
		WHERE 
			custid = @CustID 
			AND accdate <= @FromDate_Bk
			AND transtype LIKE 'Bal' AND transdesc LIKE 'OPENING BALANCE'
		ORDER BY accdate DESC
 
		INSERT INTO #StatementTable(
				TransID,
				TransDate,
				WinlostDate,
				RefNo,
				TotalAmt,
				TransType,
				TransDesc,
				Creator,
				CheckerID,
				CheckerName,
				CheckTime,
				IsAllowVerify,
				IsReversal)
			SELECT 
				0 transid,
				accdate transdate,
				accdate winlostdate,
				0 refno,
				totalamt,
				transtype,
				transdesc, 
				0 creator,
				NULL checkerID,
				'' checkerName,
				NULL checkTime,
				0 isAllowVerify,
				1 isReversal
			FROM bodb_Report.dbo.Statement WITH (NOLOCK) 
			WHERE 
				custid = @CustID 
				AND accdate >= @_FromDate AND accdate < @_ToDate
				AND transtype LIKE 'Bal' AND transdesc LIKE 'OPENING BALANCE'

		INSERT INTO #StatementTable(
				TransID,
				TransDate,
				WinlostDate,
				RefNo,
				TotalAmt,
				TransType,
				TransDesc,
				Creator,
				CheckerID,
				CheckerName,
				CheckTime,
				IsAllowVerify,
				IsReversal)
			SELECT 
				tf.transid,
				tf.transdate,
				tf.winlostdate,
				tf.refno,
				(tf.winlost - tf.actual_stake) totalamt,
				CASE WHEN EXISTS (SELECT 1 FROM bodb_archive.dbo.Transfer_Coll_BK tcbk WITH(NOLOCK) WHERE tcbk.TransID = tf.TransID) THEN 'Coll' ELSE bettype.typenamee END transtype,
				tf.transdesc + ' - Ex.Rate: ' + isnull(CAST(tf.actualrate AS VARCHAR(10)),'') transdesc, 
				tf.creator,
				NULL checkerID,
				'' checkerName,
				NULL checkTime,
				0 isAllowVerify,
				ISNULL(isReversal,0) isReversal
			FROM bodb_archive.dbo.transfer_fi tf WITH(NOLOCK)
				LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = tf.bettype 
			WHERE 
				tf.custid = @CustID
				AND 
					( (@FilterBy = 1 AND tf.winlostdate >= CASE @_FromDate WHEN @FromDate_Bk THEN '19000101' ELSE @_FromDate END AND tf.winlostdate < @_ToDate)
					OR (@FilterBy = 2 AND tf.transdate >= CASE @_FromDate WHEN @FromDate_Bk THEN '19000101' ELSE @_FromDate END AND tf.transdate < @_ToDate)
					)

		IF @CustID > 0
		BEGIN
			;WITH CTE_Statement AS (
				SELECT s.refno
				FROM #StatementTable s
					LEFT JOIN bodb_archive.dbo.transfer_fi tf WITH(NOLOCK) ON s.refno = tf.refno
				WHERE tf.winlostdate >= s.winlostdate
				GROUP BY s.refno
				HAVING COUNT(*) > 1
			)
			UPDATE s
			SET s.IsExpand = 1
			FROM #StatementTable s
				INNER JOIN CTE_Statement cte ON s.refno = cte.refno
			WHERE s.TransType NOT IN ('Dep','Wit')
		END

	END

	DECLARE @AccBal MONEY = 0

	IF (@_IncludeAccBal = 1) AND (@CustID > 0)
	BEGIN
		IF @FromDate_Bk <> @_BalanceUpDay
		BEGIN
			SELECT @AccBal = ISNULL(SUM(totalamt),0)
			FROM #StatementTable
			WHERE 
				( (@FilterBy = 1 AND winlostdate < @FromDate_Bk)
				OR (@FilterBy = 2 AND transdate < @FromDate_Bk)
				)
		END
	END

	-- Result
	IF @CustID > 0
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 1 FROM #StatementTable
						WHERE TransType = 'Bal'
							AND
							(
								(@FilterBy = 1 AND winlostdate = @FromDate_Bk)
								OR (@FilterBy = 2 AND transdate = @FromDate_Bk)
							)
						)
		INSERT INTO #StatementTable(
			TransID,
			TransDate,
			WinlostDate,
			RefNo,
			TotalAmt,
			TransType,
			TransDesc,
			Creator,
			CheckerID,
			CheckerName,
			CheckTime,
			IsAllowVerify,
			IsReversal)
		SELECT 0, '', '', 0, @AccBal, 'Bal', 'ACCUMULATED BALANCE', NULL, 0, '', NULL, 0, 1

		SELECT 
			tmp.TransID,
			tmp.TransDate [TransDate],
			tmp.WinlostDate [WinlostDate],
			tmp.RefNo [RefNo],
			ISNULL(tmp.TotalAmt,0) [TotalAmount],
			tmp.TransType [TransType],
			tmp.TransDesc [TransDescription],
			ISNULL(c.Username,'') [Creator],
			tmp.CheckerID [CheckerID],
			tmp.CheckerName [CheckerName],
			tmp.CheckTime [CheckTime],
			tmp.IsAllowVerify [IsAllowVerify],
			tmp.IsReversal [IsReversal],
			tmp.IsExpand [IsExpand]
		FROM #StatementTable tmp
			LEFT JOIN dbo.Customer c (NOLOCK) ON tmp.creator = c.custid
		WHERE 
			tmp.winlostdate >= @FromDate_Bk 
			OR transdesc = 'ACCUMULATED BALANCE'
		ORDER BY 
			tmp.winlostdate,
			CASE WHEN tmp.transdesc LIKE 'OPENING BALANCE%' THEN 1 ELSE 2 END,
			tmp.TransID
	END

	IF @_RefNo > 0
	BEGIN
		SELECT 
			tmp.TransID,
			tmp.TransDate [TransDate],
			tmp.WinlostDate [WinlostDate],
			tmp.RefNo [RefNo],
			ISNULL(tmp.TotalAmt,0) [TotalAmount],
			tmp.TransType [TransType],
			tmp.TransDesc [TransDescription],
			ISNULL(c.Username,'') [Creator],
			tmp.CheckerID [CheckerID],
			tmp.CheckerName [CheckerName],
			tmp.CheckTime [CheckTime],
			tmp.IsAllowVerify [IsAllowVerify],
			tmp.IsReversal [IsReversal],
			tmp.IsExpand [IsExpand]
		FROM #StatementTable tmp
			LEFT JOIN dbo.Customer c (NOLOCK) ON tmp.creator = c.custid
		ORDER BY 
			tmp.winlostdate,
			tmp.TransID
	END
	DROP TABLE #StatementTable
END 

GO