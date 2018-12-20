/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

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

    Param's Explanation:
    
    Sample:
		exec [dbo].[Acc_StatementFinanceByRefno] @RefNo = 200169713535,@FromDate = '2012-07-23',@ToDate = '2012-07-23'
    
 */

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

INSERT INTO @StatementTable(TransID, TransDate, TransType, TransDesc, TotalAmt, IsOwner, TotalAmtRM)
    SELECT 
        b.transid,
        b.transdate,
        CASE WHEN b.oddsId = 0 THEN bettype.typenamee ELSE 'Coll' END transtype,
        b.transdesc + ' - Ex.Rate: ' + CAST(b.actualrate AS VARCHAR(10)) transdesc,
        (b.winlost - b.actual_stake),
        CASE WHEN b.custid = @CustID THEN 1 ELSE 0 END IsOwner,
        (b.winlost - b.actual_stake) * b.actualrate
    FROM dbo.bettrans b (NOLOCK) 
        LEFT JOIN dbo.bettype (NOLOCK) ON bettype.typeid = b.bettype 
    WHERE 
        b.matchid = 0
        AND b.bettype > 20000 
        AND b.refno = @_RefNo

IF NOT EXISTS( SELECT 1 FROM @StatementTable )
BEGIN

    INSERT INTO @StatementTable(TransID, TransDate, TransType, TransDesc, TotalAmt, IsOwner, TotalAmtRM)
        SELECT 
            tf.transid,
            tf.transdate,
            bettype.typenamee transtype,
            tf.transdesc + ' - Ex.Rate: ' + isnull(CAST(tf.actualrate AS VARCHAR(10)),'') transdesc,
            (tf.winlost - tf.actual_stake),
            CASE WHEN tf.custid = @CustID THEN 1 ELSE 0 END IsOwner,
            (tf.winlost - tf.actual_stake) * tf.actualrate
        FROM DBSUM.bodb_Summary.dbo.transfer_fi tf WITH(NOLOCK)
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
                bettype.typenamee transtype,
                tf.transdesc,
                (tf.credit - tf.debit) totalamt,
                CASE WHEN tf.custid = @CustID THEN 1 ELSE 0 END IsOwner
            FROM DBARC.bodb_Archive.dbo.transfer_bk tf (NOLOCK)
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

GO