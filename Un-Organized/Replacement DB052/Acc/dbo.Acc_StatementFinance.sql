USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_StatementFinance]    Script Date: 12/13/2012 03:48:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- [dbo].[Acc_StatementFinance] @RefNo = -1,@Username = 'DWLSPNL',@FilterBy = 1,@FromDate = '2012-07-21',@ToDate = '2012-08-04',@BalanceUpDay = '',@IncludeAccBal = 1

ALTER PROCEDURE [dbo].[Acc_StatementFinance]
    @RefNo BIGINT = 0,
	@Username VARCHAR(30) = null,
	@FilterBy TINYINT = null,
	@FromDate DATETIME = null,
	@ToDate DATETIME = null,
	@BalanceUpDay DATETIME = null,
	@IncludeAccBal BIT = 0
AS
 /*
	Created by: 20120730@Don
	Task: Get Statement of Finance report
	DB: DB06.bodb02 
	
	Revisions:
		- 20121213@Dan: Change linked server from DB052-->DBEXT

    Param's Explanation:
        - @FilterBy: 1:winlostdate - 2:transdate
        - @IncludeAccBal: 1:include - 0:exclude
 */

SET NOCOUNT ON

CREATE TABLE #StatementTable(
    TransID BIGINT,
	TransDate DATETIME,
	WinlostDate SMALLDATETIME,
	RefNo BIGINT,
	TotalAmt MONEY,
	TransType NVARCHAR(100),
	TransDesc NVARCHAR(350),
	Creator INT,
	CheckerID INT NULL,
	CheckerName VARCHAR(50) NULL,
	CheckTime DATETIME NULL,
	IsAllowVerify BIT DEFAULT 0,
	IsReversal BIT DEFAULT 0,
	IsExpand BIT DEFAULT 0
)

DECLARE @_RefNo AS BIGINT
SET @_RefNo = @RefNo

DECLARE @_Username AS VARCHAR(30)
SET @_Username = @Username

DECLARE @_ToDate AS DATETIME
SET @_ToDate = @ToDate
SET @_ToDate = DATEADD(day,1,@_ToDate)

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
		    bettype.typenamee transtype,
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
	    FROM DBEXT.bodb02.dbo.bettrans b WITH(NOLOCK) 
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
		            bettype.typenamee transtype,
		            tf.transdesc + ' - Ex.Rate: ' + CAST(tf.actualrate AS VARCHAR(10)) transdesc, 
		            tf.creator,
		            NULL checkerID,
		            '' checkerName,
		            NULL checkTime,
		            0 isAllowVerify,
		            ISNULL(isReversal,0) isReversal
	            FROM DB053.bodb_Summary.dbo.transfer_fi tf WITH(NOLOCK)
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
		    bettype.typenamee transtype,
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
		SELECT @_ToDate = DATEADD(day, 1, @_BalanceUpDay)
	
	SELECT TOP 1 @_FromDate = ISNULL(accdate,@FromDate_Bk)
	FROM bodb_Report.dbo.Statement (NOLOCK)
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
	    FROM bodb_Report.dbo.Statement (NOLOCK) 
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
		    bettype.typenamee transtype,
		    tf.transdesc + ' - Ex.Rate: ' + CAST(tf.actualrate AS VARCHAR(10)) transdesc, 
		    tf.creator,
		    NULL checkerID,
		    '' checkerName,
		    NULL checkTime,
		    0 isAllowVerify,
		    ISNULL(isReversal,0) isReversal
	    FROM DB053.bodb_Summary.dbo.transfer_fi tf WITH(NOLOCK)
	        LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = tf.bettype 
	    WHERE 
            tf.custid = @CustID
	        AND 
                ( (@FilterBy = 1 AND tf.winlostdate >= @_FromDate AND tf.winlostdate < @_ToDate)
                OR (@FilterBy = 2 AND tf.transdate >= @_FromDate AND tf.transdate < @_ToDate)
                )

    IF @CustID > 0
    BEGIN
        ;WITH CTE_Statement AS (
            SELECT s.refno
            FROM #StatementTable s
                LEFT JOIN DB053.bodb_Summary.dbo.transfer_fi tf WITH(NOLOCK) ON s.refno = tf.refno
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

IF (@_IncludeAccBal = 1) AND (@CustID > 0)
BEGIN
	DECLARE @NoOfRows INT, @AccBal MONEY
	
	IF @FromDate_Bk <> @_BalanceUpDay
	BEGIN
		
		SELECT @NoOfRows = COUNT(*), @AccBal = ISNULL(SUM(totalamt),0)
		FROM #StatementTable
		WHERE 
            ( (@FilterBy = 1 AND winlostdate < @FromDate_Bk)
            OR (@FilterBy = 2 AND transdate < @FromDate_Bk)
            )

		IF EXISTS( 
		        SELECT 1 
		        FROM #StatementTable 
		        WHERE (@AccBal <> 0 OR (@NoOfRows > 0 AND @AccBal = 0))
		            AND
		                ( (@FilterBy = 1 AND winlostdate >= @FromDate_Bk)
                        OR (@FilterBy = 2 AND transdate >= @FromDate_Bk)
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
        
        -- In case, there are no transactions about 'OPENING BALANCE' or 'ACCUMULATED BALANCE', insert 'ACCUMULATED BALANCE' row with 'TotalAmt' zero
        IF EXISTS( 
		        SELECT *
		        FROM #StatementTable 
        )
            IF NOT EXISTS( 
		            SELECT 1 
		            FROM #StatementTable 
		            WHERE TransType = 'Bal'
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
			        SELECT 0, '', '', 0, 0, 'Bal', 'ACCUMULATED BALANCE', NULL, 0, '', NULL, 0, 1

	END
END

-- Result
IF @_RefNo > 0
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

IF @CustID > 0
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

DROP TABLE #StatementTable




