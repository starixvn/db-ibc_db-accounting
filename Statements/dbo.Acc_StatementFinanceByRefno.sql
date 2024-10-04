/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_StatementFinanceByRefno]
    @RefNo BIGINT,
    @FromDate DATETIME,
	@ToDate DATETIME,
	@Username VARCHAR(30) = null
AS
 /*
	Created by: 20120803@Don
	Task: Get Statement of Finance by RefNo
	DB: DB06.bodb02 
	
	Revisions:
		- 20130724@Jamie: Change Alias 
			+ DB053 --> DBSUM
			+ bodb_Archive --> DBARC
		- 20180731@Percy: Expand column transdesc [RedmineID: #92841]
		- 20181107@Louis: Credit Collection [Redmine: #98621]
		- 20190114@Sophia: Move table transfer_fi from DBSUM.bodb_summary to DBARC.bodb_archive [Redmine: #105415]
		- 20191113@Louis: Hot Fix Credit Collection BK [Redmine: #123812]
		- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
		- 20220830@Danny: Remove orphan ticket [Redmine: #175253]
        - 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
        - 20240826@Bobby: Reward Payement transfer [Redmine: #209633]

    Param's Explanation:
    
    Sample:
		exec [dbo].[Acc_StatementFinanceByRefno] @RefNo = 200169713535,@FromDate = '2012-07-23',@ToDate = '2012-07-23'
    
 */
BEGIN

    SET NOCOUNT ON

    DECLARE @StatementTable TABLE(
        TransID BIGINT,
        TransDate DATETIME,
        TransType NVARCHAR(100),
	    TransDesc NVARCHAR(1000),
	    TotalAmt MONEY,
	    TotalAmtRM MONEY,
	    IsOwner BIT 
    )

    DECLARE @_RefNo AS BIGINT
    SET @_RefNo = @RefNo

    DECLARE @_ToDate AS DATETIME
    SET @_ToDate = @ToDate
    SET @_ToDate = DATEADD(day,1,@_ToDate)

    DECLARE @_FromDate AS DATETIME
    SET @_FromDate = @FromDate

    DECLARE @_Username AS VARCHAR(30)
    SET @_Username = @Username

    DECLARE @CustID INT
    SELECT @CustID = custid FROM dbo.Customer (NOLOCK) WHERE username LIKE @_Username

    -- get BU date
    DECLARE @balanceUpDay SMALLDATETIME
    DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

    INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
    EXEC bodb02.dbo.Age_SelBalanceUpDay

    SELECT @balanceUpDay = BalanceUpDay FROM @tblMoveBetBalanceUp

    INSERT INTO @StatementTable(TransID, TransDate, TransType, TransDesc, TotalAmt, IsOwner, TotalAmtRM)
    SELECT 
        b.transid,
        b.transdate,
        CASE 
			WHEN ISNULL(ti.IsCollection,0) = 0 THEN bettype.typenamee
			ELSE 'Coll' END transtype,
        b.transdesc + ' - Ex.Rate: ' + CAST(b.actualrate AS VARCHAR(10)) transdesc,
        (b.winlost - b.actual_stake),
        CASE WHEN b.custid = @CustID THEN 1 ELSE 0 END IsOwner,
        (b.winlost - b.actual_stake) * b.actualrate
    FROM dbo.transfer b (NOLOCK) 
		LEFT JOIN dbo.TransferInfo ti WITH(NOLOCK) ON b.TransId = ti.TransId
        LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = b.bettype 
    WHERE b.bettype > 20000 
        AND b.refno = @_RefNo
		AND b.CustId <> 0
        AND b.winlostdate >= @balanceUpDay

    UNION ALL
    SELECT 
        b.transid,
        b.transdate,
        bettype.typenamee AS transtype,
        b.transdesc + ' - Ex.Rate: ' + CAST(b.actualrate AS VARCHAR(10)) transdesc,
        (b.Credit - b.Debit),
        CASE WHEN b.custid = @CustID THEN 1 ELSE 0 END IsOwner,
        (b.Credit - b.Debit) * b.actualrate
    FROM dbo.transferExtra b (NOLOCK) 
        LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = b.bettype 
    WHERE b.bettype > 30000 
        AND b.refno = @_RefNo
		AND b.CustId <> 0
        AND b.winlostdate >= @balanceUpDay

    IF NOT EXISTS( SELECT 1 FROM @StatementTable )
    BEGIN

        INSERT INTO @StatementTable(TransID, TransDate, TransType, TransDesc, TotalAmt, IsOwner, TotalAmtRM)
        SELECT 
            tf.transid,
            tf.transdate,
			CASE WHEN tcbk.TransID > 0 THEN 'Coll' ELSE bettype.typenamee END transtype,
            tf.transdesc + ' - Ex.Rate: ' + isnull(CAST(tf.actualrate AS VARCHAR(10)),'') transdesc,
            (tf.winlost - tf.actual_stake),
            CASE WHEN tf.custid = @CustID THEN 1 ELSE 0 END IsOwner,
            (tf.winlost - tf.actual_stake) * tf.actualrate
        FROM bodb_archive.dbo.transfer_fi tf WITH(NOLOCK)
            LEFT JOIN bodb_archive.dbo.Transfer_Coll_BK tcbk WITH(NOLOCK) ON tcbk.TransID = tf.TransID
            LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = tf.bettype 
        WHERE 
            tf.winlostdate >= @_FromDate AND tf.winlostdate < @_ToDate
            AND tf.refno = @RefNo 

        DECLARE @TotalAmtRM MONEY
        SELECT @TotalAmtRM = ISNULL(SUM(TotalAmtRM),0) FROM @StatementTable
    
        IF @TotalAmtRM <> 0
            INSERT INTO @StatementTable(TransID, TransDate, TransType, TransDesc, TotalAmt, IsOwner)
            SELECT 
                tf.transid,
                tf.transdate,
				CASE WHEN tcbk.TransID > 0 THEN 'Coll' ELSE bettype.typenamee END transtype,
                tf.transdesc,
                (tf.credit - tf.debit) totalamt,
                CASE WHEN tf.custid = @CustID THEN 1 ELSE 0 END IsOwner
            FROM bodb_Archive.dbo.transfer_bk tf (NOLOCK)
                LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = tf.bettype 
                LEFT JOIN bodb_archive.dbo.Transfer_Coll_BK tcbk WITH(NOLOCK) ON tcbk.TransID = tf.TransID
                LEFT JOIN @StatementTable st ON st.TransID = tf.transid
            WHERE 
                tf.winlostdate >= @_FromDate AND tf.winlostdate < @_ToDate
                AND tf.refno = @RefNo 
                AND st.TransID IS NULL

            UNION ALL --transferExtra_bk
            SELECT 
                tf.transid,
                tf.transdate,
				bettype.typenamee AS transtype,
                --tf.transdesc,
                tf.transdesc + ' - Ex.Rate: ' + isnull(CAST(tf.actualrate AS VARCHAR(10)),'') transdesc,
                (tf.credit - tf.debit) totalamt,
                CASE WHEN tf.custid = @CustID THEN 1 ELSE 0 END IsOwner
            FROM bodb_Archive.dbo.transferExtra_bk tf (NOLOCK)
                LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = tf.bettype 
            WHERE 
                tf.winlostdate >= @_FromDate AND tf.winlostdate < @_ToDate
                AND tf.refno = @RefNo

    END


    -- Result
    SELECT 
        tmp.TransID [TransID],
        tmp.TransDate [TransDate],
        tmp.TransType [TransType],
        tmp.TransDesc [TransDescription],
        tmp.TotalAmt [TotalAmount],
        tmp.IsOwner [IsOwner]
    FROM @StatementTable tmp
    ORDER BY tmp.TransID
END
GO