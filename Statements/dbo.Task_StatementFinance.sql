ALTER PROCEDURE [dbo].[Task_StatementFinance]
AS
 /*
	Created by: 20120809@Don
	Task: Insert data for transfer_fi
	DB: DB06.bodb02 
	
	Revisions:
	    - 20130121@Don: Making a copy of table transfer_fi in DB054
		- 20130724@Jamie: Change Alias 
			+ DB053 --> DBSUM & DBSUM_STDBY for synchronizing data 
			+ bodb_Archive --> DBARC 	
	
 */
 
SET NOCOUNT ON 

CREATE TABLE #Refno_temp (refno BIGINT, winlostdate SMALLDATETIME)
CREATE CLUSTERED INDEX [CIX_Winlostdate] ON #Refno_temp
(
    [Winlostdate] ASC,
    [RefNo] ASC
)

DECLARE @BalanceUpDay SMALLDATETIME
SELECT TOP 1 @BalanceUpDay = winlostdate + 7
FROM dbo.Bettrans WITH(NOLOCK)
WHERE bettype = 20000 AND matchid = 0 AND custid = 3

INSERT INTO #Refno_temp
    SELECT refno, winlostdate FROM bettrans b WITH (NOLOCK)
        INNER join bodb02.dbo.custAgent c WITH (NOLOCK) ON b.recommend = c.custid
    WHERE c.isInternal = 1 AND bettype > 20000 AND matchid = 0 AND winlostdate < @BalanceUpDay
    UNION
    SELECT refno, winlostdate FROM bettrans b WITH (NOLOCK)
        INNER join bodb02.dbo.CustMaster c WITH (NOLOCK) ON b.custid = c.custid
    WHERE c.isInternal = 1 AND bettype > 20000 AND matchid = 0 AND winlostdate < @BalanceUpDay
    UNION
    SELECT refno, winlostdate FROM bettrans b WITH (NOLOCK)
        INNER join bodb02.dbo.CustSuper c WITH (NOLOCK) ON b.custid = c.custid
    WHERE c.isInternal = 1 AND bettype > 20000 AND matchid = 0 AND winlostdate < @BalanceUpDay


INSERT INTO DBSUM.bodb_Summary.dbo.transfer_fi
    (
        transid, 
        custid, 
        transdate, 
        bettype, 
        actual_stake, 
        winlost, 
        ActualRate, 
        TransDesc, 
        winlostdate, 
        recommend, 
        mrecommend, 
        srecommend, 
        currency, 
        refno,
        creator,
        CheckerID,
        CheckerName,
        checkTime,
        isReversal
    )
    SELECT 
        b.transid, 
        custid, 
        transdate, 
        bettype, 
        actual_stake, 
        winlost, 
        ActualRate, 
        TransDesc, 
        b.winlostdate, 
        recommend, 
        mrecommend, 
        srecommend, 
        currency, 
        b.refno,
        creator,
        betid, --CheckerID
        betcheck, --CheckerName
        checkTime,
        liveindicator isReversal
    FROM dbo.bettrans b WITH (NOLOCK, INDEX=CIX_matchid_bettype)
        INNER JOIN #Refno_temp r ON b.refno = r.refno AND b.winlostdate=r.winlostdate
    WHERE b.matchid = 0 AND b.bettype > 20000
    
INSERT INTO DBSUM_STDBY.bodb_Summary.dbo.transfer_fi
    (
        transid, 
        custid, 
        transdate, 
        bettype, 
        actual_stake, 
        winlost, 
        ActualRate, 
        TransDesc, 
        winlostdate, 
        recommend, 
        mrecommend, 
        srecommend, 
        currency, 
        refno,
        creator,
        CheckerID,
        CheckerName,
        checkTime,
        isReversal
    )
    SELECT 
        b.transid, 
        custid, 
        transdate, 
        bettype, 
        actual_stake, 
        winlost, 
        ActualRate, 
        TransDesc, 
        b.winlostdate, 
        recommend, 
        mrecommend, 
        srecommend, 
        currency, 
        b.refno,
        creator,
        betid, --CheckerID
        betcheck, --CheckerName
        checkTime,
        liveindicator isReversal
    FROM dbo.bettrans b WITH (NOLOCK, INDEX=CIX_matchid_bettype)
        INNER JOIN #Refno_temp r ON b.refno = r.refno AND b.winlostdate=r.winlostdate
    WHERE b.matchid = 0 AND b.bettype > 20000
    
DROP TABLE #Refno_temp

GO
GRANT VIEW DEFINITION ON [dbo].[Task_StatementFinance] TO [vnteam] AS [dbo]