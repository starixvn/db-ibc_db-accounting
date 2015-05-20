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
		AND e.Currency <> 'EURO'

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

-- UPDATE MASTER
-- a3 = 0, m3 = @mVALUE, s3 = 0
SELECT 
	@apositiontaking = 0,
	@mpositiontaking = @mVALUE,
	@spositiontaking = 0,
	@alivepositiontaking = 0,
	@mlivepositiontaking = @mVALUE,
	@slivepositiontaking = 0

UPDATE CustSetting 
SET apositiontaking = @apositiontaking,
	mpositiontaking = @mpositiontaking,
	spositiontaking = @spositiontaking,
	alivepositiontaking = @alivepositiontaking,
	mlivepositiontaking = @mlivepositiontaking,
	slivepositiontaking = @slivepositiontaking
WHERE CustID in (SELECT CustID FROM #TempCustomers WHERE RoleID = 3)

-- UPDATE Agent [01]
-- a2 = @mVALUE, m2 = s2 = 0
SELECT 
	@apositiontaking = @mVALUE,
	@mpositiontaking = 0,
	@spositiontaking = 0,
	@alivepositiontaking = @mVALUE,
	@mlivepositiontaking = 0,
	@slivepositiontaking = 0

UPDATE CustSetting 
SET apositiontaking = @apositiontaking,
	mpositiontaking = @mpositiontaking,
	spositiontaking = @spositiontaking,
	alivepositiontaking = @alivepositiontaking,
	mlivepositiontaking = @mlivepositiontaking,
	slivepositiontaking = @slivepositiontaking
WHERE CustID in (SELECT CustID FROM #TempCustomers WHERE RoleID = 2)

-- UPDATE Member (under agent [01])
-- a1 = @mVALUE, m1 = s1 = 0
-- (LIVE) a1 = m1 = s1 = 0
SELECT 
	@apositiontaking = @mVALUE,
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
WHERE CustID in (SELECT CustID FROM #TempCustomers WHERE RoleID = 1)

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
		AND e.Currency <> 'EURO'

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
SET mpositiontaking = @mVALUE - apositiontaking,
	spositiontaking = @spositiontaking,	
	mlivepositiontaking = @mVALUE - alivepositiontaking,
	slivepositiontaking = @slivepositiontaking
WHERE CustID in (SELECT CustID FROM #TempCustomers)

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
DROP TABLE #TempCustomers