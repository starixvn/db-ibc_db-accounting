

ALTER PROCEDURE [dbo].[Acc_ExecRep_09_Lukas]
	@COUNT	INT = 0,
	@step	INT = 0,
	@mode	INT = 3
AS
BEGIN

-- 1 - update Enable/Disable status, max per match (custinfo)
-- 2 - Update AutoPT (custsuper)
-- 3 - Update PT setting (Custsetting3rd)
-- 4 - Update Min/Max PT (Custoverride3rd)
SET NOCOUNT ON 

	DECLARE @betSetting TABLE(Currency INT, CurrencyName NVARCHAR(50), MinBet MONEY, MaxBet MONEY, MaxPerMatch MONEY)
	DECLARE @dummy TABLE (custid INT )

	
		INSERT INTO @dummy 
				  SELECT	1229820
		UNION ALL SELECT	1229718
		UNION ALL SELECT	1588025
		UNION ALL SELECT	1229748
		UNION ALL SELECT	3101938
		UNION ALL SELECT	1229844
		UNION ALL SELECT	3326497
		UNION ALL SELECT	2075752
		UNION ALL SELECT	3326368
		UNION ALL SELECT	1150890
		UNION ALL SELECT	1150923
		UNION ALL SELECT	1151025
		UNION ALL SELECT	1229808
		UNION ALL SELECT	1229814
		UNION ALL SELECT	1229724
		UNION ALL SELECT	1229754
		UNION ALL SELECT	3167992
		UNION ALL SELECT	1229838
		UNION ALL SELECT	1229802
		UNION ALL SELECT	2623331
		UNION ALL SELECT	3326420
		UNION ALL SELECT	1229790
		UNION ALL SELECT	1229736
		UNION ALL SELECT	1229832
		UNION ALL SELECT	1229850
		UNION ALL SELECT	3326471
		UNION ALL SELECT	2015739
		UNION ALL SELECT	1229796
		UNION ALL SELECT	1150941
		UNION ALL SELECT	1151009
		UNION ALL SELECT	3326522
		UNION ALL SELECT	3326446
		UNION ALL SELECT	1150991
		UNION ALL SELECT	3326394
		UNION ALL SELECT	1229712
		UNION ALL SELECT	1564740
		UNION ALL SELECT	1150856
		UNION ALL SELECT	1229742
		UNION ALL SELECT	1588006
		UNION ALL SELECT	1229826
		UNION ALL SELECT	1229730

	
	IF @mode = 1  -- update Enable/Disable status, max per match (custinfo)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custinfo' AND TYPE = 'u')
			RETURN
		/**/
		INSERT INTO @betSetting(Currency, CurrencyName, MinBet, MaxBet, MaxPerMatch)
				  SELECT	2	,	'RM'	,	10	,	40000	,	80000
		UNION ALL SELECT	35	,	'$US'	,	5	,	15000	,	30000
		UNION ALL SELECT	9	,	'AUD'	,	5	,	15000	,	30000
		UNION ALL SELECT	46	,	'BND'	,	5	,	15000	,	30000
		UNION ALL SELECT	21	,	'CAD'	,	5	,	10000	,	20000
		UNION ALL SELECT	50	,	'CAN'	,	5	,	15000	,	30000
		UNION ALL SELECT	41	,	'CHF'	,	5	,	15000	,	30000
		UNION ALL SELECT	57	,	'CZK'	,	100	,	400000	,	800000
		UNION ALL SELECT	47	,	'DDD'	,	50	,	120000	,	240000
		UNION ALL SELECT	52	,	'DKK'	,	20	,	120000	,	240000
		UNION ALL SELECT	6	,	'EURO'	,	5	,	10000	,	20000
		UNION ALL SELECT	12	,	'GBP'	,	5	,	10000	,	20000
		UNION ALL SELECT	5	,	'HK$'	,	20	,	80000	,	160000
		UNION ALL SELECT	33	,	'IDD'	,	50	,	120000	,	240000
		UNION ALL SELECT	34	,	'IDR'	,	50	,	120000	,	240000
		UNION ALL SELECT	15	,	'IN'	,	50	,	120000	,	240000
		UNION ALL SELECT	22	,	'IND'	,	50	,	120000	,	240000
		UNION ALL SELECT	51	,	'INH'	,	50	,	10000	,	20000
		UNION ALL SELECT	40	,	'IRR'	,	10	,	80000	,	160000
		UNION ALL SELECT	32	,	'JPY'	,	400	,	1000000	,	2000000
		UNION ALL SELECT	49	,	'MXN'	,	50	,	100000	,	200000
		UNION ALL SELECT	54	,	'NOK'	,	20	,	80000	,	160000
		UNION ALL SELECT	30	,	'NT'	,	150	,	400000	,	800000
		UNION ALL SELECT	17	,	'NTD'	,	5	,	15000	,	30000
		UNION ALL SELECT	37	,	'P'		,	5	,	15000	,	30000
		UNION ALL SELECT	42	,	'PE'	,	100	,	400000	,	800000
		UNION ALL SELECT	56	,	'PLN'	,	10	,	40000	,	80000
		UNION ALL SELECT	44	,	'PT'	,	30	,	100000	,	200000
		UNION ALL SELECT	31	,	'Pts'	,	400	,	400000	,	800000
		UNION ALL SELECT	13	,	'RMB'	,	20	,	80000	,	160000
		UNION ALL SELECT	58	,	'RON'	,	10	,	40000	,	80000
		UNION ALL SELECT	55	,	'RUB'	,	100	,	400000	,	800000
		UNION ALL SELECT	1	,	'SD$'	,	5	,	15000	,	30000
		UNION ALL SELECT	53	,	'SEK'	,	20	,	80000	,	160000
		UNION ALL SELECT	4	,	'TB'	,	100	,	400000	,	800000
		UNION ALL SELECT	43	,	'THB'	,	100	,	400000	,	800000
		UNION ALL SELECT	3	,	'US$'	,	5	,	15000	,	30000
		UNION ALL SELECT	45	,	'Won'	,	4000,	16000000,	32000000
		UNION ALL SELECT	36	,	'Y$US'	,	5	,	15000	,	30000
		UNION ALL SELECT	16	,	'Yen'	,	5	,	15000	,	30000
		UNION ALL SELECT	48	,	'ZAR'	,	20	,	80000	,	160000

		UPDATE c WITH(ROWLOCK,UPDLOCK)
		SET Maxpermatch151		= b.MaxPerMatch,	
			DisableHorseRacing  = CASE WHEN c.Currency IN (1,2,3,4,5,6,13,15,16,17,20,22,33,34,35,36,40,43,47) THEN DisableHorseRacing
									   ELSE DisableOpenTote END
		FROM custinfo c INNER JOIN @betSetting b ON c.currency = b.Currency
		WHERE roleid < 5 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
				AND srecommend NOT IN (SELECT custid FROM @dummy)			  
	END
	ELSE IF @mode = 2 --- Update AutoPT (custsuper)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custsuper' AND TYPE = 'U')
			RETURN

		UPDATE sp WITH(ROWLOCK,UPDLOCK)
		SET AutoIBCPositionTaking_Tote = AutoIBCPositionTaking_Fixed			
		FROM custsuper sp INNER JOIN custinfo c WITH(NOLOCK) ON sp.custid = c.custid
		WHERE sp.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
			  AND sp.custid NOT IN (SELECT custid FROM @dummy)
	END
	ELSE IF @mode = 3 -- Update PT setting (Custsetting3rd)
	BEGIN
		IF (SELECT COUNT('') FROM sys.objects WHERE NAME IN ('custsetting3rd','custinfo') AND TYPE = 'u') <> 2
			RETURN
		INSERT INTO @betSetting(Currency, CurrencyName, MinBet, MaxBet, MaxPerMatch)
				  SELECT	2	,	'RM'	,	10	,	40000	,	80000
		UNION ALL SELECT	35	,	'$US'	,	5	,	15000	,	30000
		UNION ALL SELECT	9	,	'AUD'	,	5	,	15000	,	30000
		UNION ALL SELECT	46	,	'BND'	,	5	,	15000	,	30000
		UNION ALL SELECT	21	,	'CAD'	,	5	,	10000	,	20000
		UNION ALL SELECT	50	,	'CAN'	,	5	,	15000	,	30000
		UNION ALL SELECT	41	,	'CHF'	,	5	,	15000	,	30000
		UNION ALL SELECT	57	,	'CZK'	,	100	,	400000	,	800000
		UNION ALL SELECT	47	,	'DDD'	,	50	,	120000	,	240000
		UNION ALL SELECT	52	,	'DKK'	,	20	,	120000	,	240000
		UNION ALL SELECT	6	,	'EURO'	,	5	,	10000	,	20000
		UNION ALL SELECT	12	,	'GBP'	,	5	,	10000	,	20000
		UNION ALL SELECT	5	,	'HK$'	,	20	,	80000	,	160000
		UNION ALL SELECT	33	,	'IDD'	,	50	,	120000	,	240000
		UNION ALL SELECT	34	,	'IDR'	,	50	,	120000	,	240000
		UNION ALL SELECT	15	,	'IN'	,	50	,	120000	,	240000
		UNION ALL SELECT	22	,	'IND'	,	50	,	120000	,	240000
		UNION ALL SELECT	51	,	'INH'	,	50	,	10000	,	20000
		UNION ALL SELECT	40	,	'IRR'	,	10	,	80000	,	160000
		UNION ALL SELECT	32	,	'JPY'	,	400	,	1000000	,	2000000
		UNION ALL SELECT	49	,	'MXN'	,	50	,	100000	,	200000
		UNION ALL SELECT	54	,	'NOK'	,	20	,	80000	,	160000
		UNION ALL SELECT	30	,	'NT'	,	150	,	400000	,	800000
		UNION ALL SELECT	17	,	'NTD'	,	5	,	15000	,	30000
		UNION ALL SELECT	37	,	'P'		,	5	,	15000	,	30000
		UNION ALL SELECT	42	,	'PE'	,	100	,	400000	,	800000
		UNION ALL SELECT	56	,	'PLN'	,	10	,	40000	,	80000
		UNION ALL SELECT	44	,	'PT'	,	30	,	100000	,	200000
		UNION ALL SELECT	31	,	'Pts'	,	400	,	400000	,	800000
		UNION ALL SELECT	13	,	'RMB'	,	20	,	80000	,	160000
		UNION ALL SELECT	58	,	'RON'	,	10	,	40000	,	80000
		UNION ALL SELECT	55	,	'RUB'	,	100	,	400000	,	800000
		UNION ALL SELECT	1	,	'SD$'	,	5	,	15000	,	30000
		UNION ALL SELECT	53	,	'SEK'	,	20	,	80000	,	160000
		UNION ALL SELECT	4	,	'TB'	,	100	,	400000	,	800000
		UNION ALL SELECT	43	,	'THB'	,	100	,	400000	,	800000
		UNION ALL SELECT	3	,	'US$'	,	5	,	15000	,	30000
		UNION ALL SELECT	45	,	'Won'	,	4000,	16000000,	32000000
		UNION ALL SELECT	36	,	'Y$US'	,	5	,	15000	,	30000
		UNION ALL SELECT	16	,	'Yen'	,	5	,	15000	,	30000
		UNION ALL SELECT	48	,	'ZAR'	,	20	,	80000	,	160000 

		
		UPDATE sa WITH(ROWLOCK,UPDLOCK)
		SET sa.spositiontaking	= uk.spositiontaking,
			sa.mpositiontaking	= uk.mpositiontaking,
			sa.apositiontaking	= uk.apositiontaking,
			sa.sdiscount		= uk.sdiscount,
			sa.adiscount		= uk.adiscount,
			sa.discount			= uk.discount,
			sa.playerdiscount	= uk.playerdiscount,
			sa.minbet			= b.minbet,
			sa.maxbet			= b.maxbet
		FROM custinfo c WITH(NOLOCK) INNER JOIN custsetting3rd sa ON sa.custid = c.custid
			INNER JOIN custsetting3rd uk WITH(NOLOCK) ON sa.custid = uk.custid AND sa.sporttype = uk.sporttype 
														 AND sa.bettype = uk.bettype - 10
			INNER JOIN @betSetting b ON c.currency = b.currency
		WHERE c.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
			AND c.srecommend NOT IN (SELECT custid FROM @dummy)			
			AND sa.sporttype = 151
			AND sa.bettype BETWEEN 31 AND 32
			AND uk.bettype BETWEEN 41 AND 42			
		
	END
	ELSE IF @mode = 4 -- Update Min/Max PT (Custoverride3rd)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custoverride3rd' AND TYPE = 'u')
			RETURN
		UPDATE sa
		SET sa.minpositiontaking = uk.minpositiontaking,
			sa.maxpositiontaking = uk.maxpositiontaking
		FROM custinfo c WITH(NOLOCK) 
			INNER JOIN custoverride3rd sa WITH(ROWLOCK,UPDLOCK) ON c.custid = sa.custid
			INNER JOIN custoverride3rd uk WITH(NOLOCK) ON sa.custid = uk.custid AND sa.sporttype = uk.sporttype
														AND sa.bettype = uk.bettype - 10
		WHERE c.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
			AND srecommend NOT IN (SELECT custid FROM @dummy)			
			AND sa.sporttype = 151
			AND sa.bettype BETWEEN 31 AND 32
			AND uk.bettype BETWEEN 41 AND 42
	END

END

 


/*
DECLARE @COUNT INT, @MaxCustID INT, @Step INT

-- Remember to select maxCustID before executing

SELECT  @MaxCustID = xxx,
        @COUNT = 0,
        @Step = 20000

WHILE 1 + @Step*@COUNT < @MaxCustID
BEGIN
    EXEC dbo.Acc_ExecRep_09  @COUNT = @COUNT, @Step = @Step, @Mode = 2
     
    SELECT @COUNT = @COUNT + 1
 
    WAITFOR DELAY '000:00:01'
END

*/