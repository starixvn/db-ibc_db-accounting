/*
select distinct e.currency, 'Exec ExecRep_07 ''' + e.currency + ''''
from custinfo c (nolock)
	inner join exchange e with (nolock) on c.currency = e.exchangeid
where custid in (select custid from dbo.f_Depsuper_1('12bet')
----------------------------
Exec ExecRep_07 'AFF'
Exec ExecRep_07 'AUD'
Exec ExecRep_07 'CHF'
Exec ExecRep_07 'EURO'
Exec ExecRep_07 'GBP'
Exec ExecRep_07 'RM'
Exec ExecRep_07 'RMB'
Exec ExecRep_07 'TB'
Exec ExecRep_07 'US$'
Exec ExecRep_07 'UUS'
*/

ALTER PROCEDURE [dbo].[ExecRep_07]	
	@Currency varchar(5)
AS
--

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END


if @Currency = 'AFF' --Update Affiliate accounts
BEGIN
	DECLARE @mCustID int
	SELECT @mCustID = CustID from CustInfo with(nolock) where username = '12BETAFF'

	-- UPDATE PT FOR EXISTED AFFILIATE
	UPDATE cs WITH(ROWLOCK,UPDLOCK) 
    SET cs.mpositiontaking = 0,
		cs.mlivepositiontaking = 0
    FROM custsetting cs
        INNER JOIN custinfo ci WITH(NOLOCK) ON ci.custid=cs.custid
    WHERE ci.mrecommend=@mCustID 
        AND ci.roleid=2
    
    UPDATE cs WITH(ROWLOCK,UPDLOCK)--Update PT for Horseracing
    SET apositiontaking = 0,
        mpositiontaking = 0,
        spositiontaking = 0
    FROM custsetting cs
        INNER JOIN custinfo ci WITH(NOLOCK) ON ci.custid=cs.custid
    WHERE ci.mrecommend=@mCustID 
        AND ci.roleid=2
        and Sporttype = 151
        and Bettype in (31,32,41,42)
        
    UPDATE cs WITH(ROWLOCK,UPDLOCK)--Update PT for Finance
    SET apositiontaking = 0,
        mpositiontaking = 0,
        spositiontaking = 0
    FROM custsetting cs
        INNER JOIN custinfo ci WITH(NOLOCK) ON ci.custid=cs.custid
    WHERE ci.mrecommend=@mCustID 
        AND ci.roleid=2
        and Sporttype = 201
        and Bettype in (2,3)
	RETURN
END  

if @Currency NOT in (select e.currency
						from custinfo c (nolock)
							inner join exchange e with (nolock) on c.currency = e.exchangeid
						where custid in (1015419,1015427,791081,836212,836218,836226,836203,791080,916498,179457))

-- UPDATE FOR CURRENCY AGENTs AND MEMBERs
DECLARE @mVALUE smallmoney
SELECT @mVALUE = 0.85
-----------------------------
DECLARE 
	@apositiontaking smallmoney,
	@mpositiontaking smallmoney,
	@spositiontaking smallmoney,
	@alivepositiontaking smallmoney,
	@mlivepositiontaking smallmoney,
	@slivepositiontaking smallmoney

CREATE TABLE #TempCustomers(CustID int primary key, Username varchar(50), RoleID int)
INSERT INTO #TempCustomers
	-- Agent [01]
	SELECT CustID, Username, RoleID
	FROM CustInfo c WITH(NOLOCK)
		INNER JOIN Exchange e WITH(NOLOCK) on c.Currency = e.ExchangeID
	WHERE RoleID = 2
		AND c.Username = '12BET' +e.Currency +'01'
		AND e.Currency = @Currency

INSERT INTO #TempCustomers
	-- Member (under agent [01])
	SELECT c.CustID, c.Username, c.RoleID
	FROM CustInfo c WITH(NOLOCK)
		INNER JOIN #TempCustomers t on c.Recommend = t.CustID
	WHERE c.RoleID = 1

	UNION ALL
	-- Master
	SELECT mRecommend, c.Username, 3
	FROM CustInfo c WITH(NOLOCK)
		INNER JOIN #TempCustomers t on c.CustID = t.CustID
	WHERE c.RoleID = 2

	UNION ALL
	-- Super
	SELECT sRecommend, c.Username, 4
	FROM CustInfo c WITH(NOLOCK)
		INNER JOIN #TempCustomers t on c.CustID = t.CustID
	WHERE c.RoleID = 2

-- UPDATE SUPER
-- a4 = m4 = s4 = @mVALUE
SELECT 
	@apositiontaking = @mVALUE,
	@mpositiontaking = @mVALUE,
	@spositiontaking = @mVALUE,
	@alivepositiontaking = @mVALUE,
	@mlivepositiontaking = @mVALUE,
	@slivepositiontaking = @mVALUE

UPDATE CustSetting 
SET apositiontaking = @apositiontaking,
	mpositiontaking = @mpositiontaking,
	spositiontaking = @spositiontaking,
	alivepositiontaking = @alivepositiontaking,
	mlivepositiontaking = @mlivepositiontaking,
	slivepositiontaking = @slivepositiontaking
WHERE CustID in (SELECT CustID FROM #TempCustomers WHERE RoleID = 4)

-- UPDATE MASTER: a3 = 0, m3 = @mVALUE, s3 = 0
-- UPDATE Agent [01]: a2 = @mVALUE, m2 = s2 = 0 
-- UPDATE Member (under agent [01]): a1 = m1 = s1 = 0
SELECT 
	@apositiontaking = 0,
	@mpositiontaking = 0,
	@spositiontaking = 0,
	@alivepositiontaking = 0,
	@mlivepositiontaking = 0,
	@slivepositiontaking = 0

UPDATE CustSetting 
SET apositiontaking = @apositiontaking,
	mpositiontaking = @mpositiontaking,
	spositiontaking = @spositiontaking,
	alivepositiontaking = @alivepositiontaking,
	mlivepositiontaking = @mlivepositiontaking,
	slivepositiontaking = @slivepositiontaking
WHERE CustID in (SELECT CustID FROM #TempCustomers WHERE RoleID in (1,2,3))
	and sporttype not in (151,201)

-- UPDATE FOR HORSE RACING (ALL LEVEL)
UPDATE CustSetting
SET apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,
	alivepositiontaking = 0,
	mlivepositiontaking = 0,
	slivepositiontaking = 0
WHERE CustID in (SELECT CustID FROM #TempCustomers)
	and Sporttype = 151
	and Bettype in (31,32,41,42)
	
-- UPDATE FOR FINANCIAL (ALL LEVEL)
UPDATE CustSetting
SET apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,
	alivepositiontaking = 0,
	mlivepositiontaking = 0,
	slivepositiontaking = 0
WHERE CustID in (SELECT CustID FROM #TempCustomers)
	and Sporttype = 201
	and Bettype in (2,3)	
------------
TRUNCATE TABLE #TempCustomers
------------
INSERT INTO #TempCustomers
	-- Agent [02]
	SELECT CustID, Username, RoleID
	FROM CustInfo c WITH(NOLOCK)
		INNER JOIN Exchange e WITH(NOLOCK) on c.Currency = e.ExchangeID
	WHERE RoleID = 2
		AND c.Username = '12BET' +e.Currency +'02'
		AND e.Currency = @Currency

INSERT INTO #TempCustomers
	-- Member (under agent [02])
	SELECT c.CustID, c.Username, c.RoleID
	FROM CustInfo c WITH(NOLOCK)
		INNER JOIN #TempCustomers t on c.Recommend = t.CustID
	WHERE c.RoleID = 1

-- UPDATE Agent [02] and Members
-- m2 = @mVALUE-a1, s1 = 0
-- m1 = @mVALUE-a1, s1 = 0
SELECT 	
	@spositiontaking = 0,
	@slivepositiontaking = 0

UPDATE CustSetting 
SET mpositiontaking = 0,
	spositiontaking = @spositiontaking,	
	mlivepositiontaking = 0,
	slivepositiontaking = @slivepositiontaking
WHERE CustID in (SELECT CustID FROM #TempCustomers)
	and sporttype not in (151,201)

-- UPDATE FOR HORSE RACING (ALL LEVEL)
UPDATE CustSetting
SET apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,
	alivepositiontaking = 0,
	mlivepositiontaking = 0,
	slivepositiontaking = 0
WHERE CustID in (SELECT CustID FROM #TempCustomers)
	and Sporttype = 151
	and Bettype in (31,32)
	
-- UPDATE FOR FINANCIAL (ALL LEVEL)
UPDATE CustSetting
SET apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0,
	alivepositiontaking = 0,
	mlivepositiontaking = 0,
	slivepositiontaking = 0
WHERE CustID in (SELECT CustID FROM #TempCustomers)
	and Sporttype = 201
	and Bettype in (2,3)		
DROP TABLE #TempCustomers


GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_07] TO [ITTim]
GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_07] TO [ITVivi]