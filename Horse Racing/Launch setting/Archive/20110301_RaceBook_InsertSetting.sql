
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@COUNT	INT = 0,
	@step	INT = 0,
	@mode	INT = 3
AS
BEGIN

-- 1 - update Enable/Disable status, max per match (custinfo)
-- 2 - Update AutoPT (custsuper)
-- 3 - Update PT setting (Custsetting3rd)
-- 4 - Update Min/Max PT (Custoverride3rd)


	DECLARE @betSetting TABLE(Currency INT, MinBet MONEY, MaxBet MONEY, MaxPerMatch MONEY)

	
	IF @mode = 1  -- update Enable/Disable status, max per match (custinfo)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custinfo' AND TYPE = 'u')
			RETURN
		/**/
		INSERT INTO @betSetting 
				  SELECT 2,		10.00,	40000.00,	80000.00 --	'RM'
		UNION ALL SELECT 35,	5.00,	15000.00,	30000.00 --	'$US'
		UNION ALL SELECT 9,		5.00,	15000.00,	30000.00 --	'AUD'
		UNION ALL SELECT 46,	5.00,	15000.00,	30000.00 --	'BND'
		UNION ALL SELECT 21,	5.00,	5000.00,	10000.00 --	'CAD'
		UNION ALL SELECT 50,	5.00,	40000.00,	80000.00 --	'CAN'
		UNION ALL SELECT 41,	10.00,	10000.00,	20000.00 --	'CHF'
		UNION ALL SELECT 57,	100.00, 40000.00,	80000.00 --	'CZK'
		UNION ALL SELECT 47,	50.00,	120000.00,	240000.00 --	'DDD'
		UNION ALL SELECT 52,	20.00,	80000.00,	160000.00 --	'DKK'
		UNION ALL SELECT 6,		5.00,	10000.00,	20000.00 --	'EURO'
		UNION ALL SELECT 12,	5.00,	10000.00,	20000.00 --	'GBP'
		UNION ALL SELECT 5,		30.00,	80000.00,	160000.00 --	'HK$'
		UNION ALL SELECT 33,	50.00,	120000.00,	240000.00 --	'IDD'
		UNION ALL SELECT 34,	50.00,	120000.00,	240000.00 --	'IDR'
		UNION ALL SELECT 15,	50.00,	120000.00,	240000.00 --	'IN'
		UNION ALL SELECT 22,	50.00,	120000.00,	240000.00 --	'IND'
		UNION ALL SELECT 40,	5.00,	10000.00,	20000.00 --	'IRR'
		UNION ALL SELECT 32,	500.00, 1000000.00, 2000000.00 -- 'JPY'
		UNION ALL SELECT 49,	50.00,	120000.00,	240000.00 --	'MXN'
		UNION ALL SELECT 54,	20.00,	80000.00,	160000.00 --	'NOK'
		UNION ALL SELECT 30,	100.00,	400000.00,	800000.00 --	'NT'
		UNION ALL SELECT 17,	5.00,	10000.00,	20000.00 --	'NTD'
		UNION ALL SELECT 37,	5.00,	10000.00,	20000.00 --	'P'
		UNION ALL SELECT 42,	300.00, 400000.00,	800000.00 --	'PE'
		UNION ALL SELECT 56,	10.00,	40000.00,	80000.00 --	'PLN'
		UNION ALL SELECT 44,	100.00, 120000.00,	240000.00 --	'PT'
		UNION ALL SELECT 31,	600.00, 4000000.00, 8000000.00 -- 'Pts'
		UNION ALL SELECT 13,	30.00,	80000.00,	160000.00 --	'RMB'
		UNION ALL SELECT 58,	10.00,	40000.00,	80000.00 --	'RON'
		UNION ALL SELECT 55,	100.00, 400000.00,	800000.00 --	'RUB'
		UNION ALL SELECT 1,		5.00,	20000.00,	40000.00 --	'SD$'
		UNION ALL SELECT 53,	20.00,	80000.00,	160000.00 --	'SEK'
		UNION ALL SELECT 4,		300.00, 400000.00,	800000.00 --	'TB'
		UNION ALL SELECT 43,	300.00, 400000.00,	800000.00 --	'THB'
		UNION ALL SELECT 3,		5.00,	15000.00,	30000.00 --	'US$'
		UNION ALL SELECT 51,	100.00, 40000.00,	80000.00 --	'VND'
		UNION ALL SELECT 45,	7000.00,16000000.00,32000000.00 --'Won'
		UNION ALL SELECT 36,	5.00,	15000.00,	30000.00 --	'Y$US'
		UNION ALL SELECT 16,	5.00,	15000.00,	30000.00 --	'Yen'
		UNION ALL SELECT 48,	30.00,	80000.00,	160000.00 --	'ZAR'
		UNION ALL SELECT 20,	5.00,	15000.00,	30000.00   -- 'UUS'
		UNION ALL SELECT 27,	0.00,	0.00,		0.00   -- 'H'
		UNION ALL SELECT 28,	0.00,	0.00,		0.00   -- 'C'

		UPDATE c WITH(ROWLOCK,UPDLOCK)
		SET MaxPerMatch151_AU = b.MaxPerMatch,
			MaxPerMatch152_UK = MaxPerMatch151_OT,
			MaxPerMatch152_AU = b.MaxPerMatch,
			MaxPerMatch153_AU = b.MaxPerMatch,
			Disable151_AU = DisableOpenTote,
			Disable152_UK = DisableOpenTote,
			Disable152_AU = DisableOpenTote,
			Disable153_AU = DisableOpenTote
		FROM custinfo c INNER JOIN @betSetting b ON c.currency = b.Currency
		WHERE roleid < 5 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
	END
	ELSE IF @mode = 2 --- Update AutoPT (custsuper)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custsuper' AND TYPE = 'u')
			RETURN

		UPDATE sp WITH(ROWLOCK,UPDLOCK)
		SET AutoIBCPT151_AU = AutoIBCPositionTaking_Fixed,
			AutoIBCPT152_UK = AutoIBCPositionTaking_Fixed,
			AutoIBCPT152_AU = AutoIBCPositionTaking_Fixed,
			AutoIBCPT153_AU = AutoIBCPositionTaking_Fixed
		FROM custsuper sp
		WHERE custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)

	END
	ELSE IF @mode = 3 -- Update PT setting (Custsetting3rd)
	BEGIN
		IF (SELECT COUNT('') FROM sys.objects WHERE NAME IN ('custsetting3rd','custinfo') AND TYPE = 'u') <> 2
			RETURN
		INSERT INTO @betSetting 
				  SELECT 2,		10.00,	40000.00,	80000.00 --	'RM'
		UNION ALL SELECT 35,	5.00,	15000.00,	30000.00 --	'$US'
		UNION ALL SELECT 9,		5.00,	15000.00,	30000.00 --	'AUD'
		UNION ALL SELECT 46,	5.00,	15000.00,	30000.00 --	'BND'
		UNION ALL SELECT 21,	5.00,	5000.00,	10000.00 --	'CAD'
		UNION ALL SELECT 50,	5.00,	40000.00,	80000.00 --	'CAN'
		UNION ALL SELECT 41,	10.00,	10000.00,	20000.00 --	'CHF'
		UNION ALL SELECT 57,	100.00, 40000.00,	80000.00 --	'CZK'
		UNION ALL SELECT 47,	50.00,	120000.00,	240000.00 --	'DDD'
		UNION ALL SELECT 52,	20.00,	80000.00,	160000.00 --	'DKK'
		UNION ALL SELECT 6,		5.00,	10000.00,	20000.00 --	'EURO'
		UNION ALL SELECT 12,	5.00,	10000.00,	20000.00 --	'GBP'
		UNION ALL SELECT 5,		30.00,	80000.00,	160000.00 --	'HK$'
		UNION ALL SELECT 33,	50.00,	120000.00,	240000.00 --	'IDD'
		UNION ALL SELECT 34,	50.00,	120000.00,	240000.00 --	'IDR'
		UNION ALL SELECT 15,	50.00,	120000.00,	240000.00 --	'IN'
		UNION ALL SELECT 22,	50.00,	120000.00,	240000.00 --	'IND'
		UNION ALL SELECT 40,	5.00,	10000.00,	20000.00 --	'IRR'
		UNION ALL SELECT 32,	500.00, 1000000.00, 2000000.00 -- 'JPY'
		UNION ALL SELECT 49,	50.00,	120000.00,	240000.00 --	'MXN'
		UNION ALL SELECT 54,	20.00,	80000.00,	160000.00 --	'NOK'
		UNION ALL SELECT 30,	100.00,	400000.00,	800000.00 --	'NT'
		UNION ALL SELECT 17,	5.00,	10000.00,	20000.00 --	'NTD'
		UNION ALL SELECT 37,	5.00,	10000.00,	20000.00 --	'P'
		UNION ALL SELECT 42,	300.00, 400000.00,	800000.00 --	'PE'
		UNION ALL SELECT 56,	10.00,	40000.00,	80000.00 --	'PLN'
		UNION ALL SELECT 44,	100.00, 120000.00,	240000.00 --	'PT'
		UNION ALL SELECT 31,	600.00, 4000000.00, 8000000.00 -- 'Pts'
		UNION ALL SELECT 13,	30.00,	80000.00,	160000.00 --	'RMB'
		UNION ALL SELECT 58,	10.00,	40000.00,	80000.00 --	'RON'
		UNION ALL SELECT 55,	100.00, 400000.00,	800000.00 --	'RUB'
		UNION ALL SELECT 1,		5.00,	20000.00,	40000.00 --	'SD$'
		UNION ALL SELECT 53,	20.00,	80000.00,	160000.00 --	'SEK'
		UNION ALL SELECT 4,		300.00, 400000.00,	800000.00 --	'TB'
		UNION ALL SELECT 43,	300.00, 400000.00,	800000.00 --	'THB'
		UNION ALL SELECT 3,		5.00,	15000.00,	30000.00 --	'US$'
		UNION ALL SELECT 51,	100.00, 40000.00,	80000.00 --	'VND'
		UNION ALL SELECT 45,	7000.00,16000000.00,32000000.00 --'Won'
		UNION ALL SELECT 36,	5.00,	15000.00,	30000.00 --	'Y$US'
		UNION ALL SELECT 16,	5.00,	15000.00,	30000.00 --	'Yen'
		UNION ALL SELECT 48,	30.00,	80000.00,	160000.00 --	'ZAR'
		UNION ALL SELECT 20,	5.00,	15000.00,	30000.00   -- 'UUS'
		UNION ALL SELECT 27,	0.00,	0.00,		0.00   -- 'H'
		UNION ALL SELECT 28,	0.00,	0.00,		0.00   -- 'C'
		-- 151-51
		INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
				SELECT cs3.custid, 51, 151, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, ISNULL(b.MinBet,0), ISNULL(b.MaxBet,0), autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
				FROM custsetting3rd  cs3 WITH(NOLOCK) INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
										LEFT JOIN @betSetting b ON b.Currency = c.currency
				WHERE cs3.sporttype = 151 AND cs3.bettype = 41 AND cs3.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)

		-- 151-52
		INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
				SELECT cs3.custid, 52, 151, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, ISNULL(b.MinBet,0), ISNULL(b.MaxBet,0), autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
				FROM custsetting3rd  cs3 WITH(NOLOCK) INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
										LEFT JOIN @betSetting b ON b.Currency = c.currency
				WHERE cs3.sporttype = 151 AND cs3.bettype = 42 AND cs3.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)

		---- Greyhound
		-- 152-41
		INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
				SELECT cs3.custid, 41, 152, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, MinBet, MaxBet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
				FROM custsetting3rd  cs3 WITH(NOLOCK) INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid								
				WHERE cs3.sporttype = 151 AND cs3.bettype = 41 AND cs3.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)

		-- 152-42
		INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
				SELECT cs3.custid, 42, 152, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, MinBet, MaxBet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
				FROM custsetting3rd  cs3 WITH(NOLOCK) INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid								
				WHERE cs3.sporttype = 151 AND cs3.bettype = 42 AND cs3.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)


		-- 152-51
		INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
				SELECT cs3.custid, 51, 152, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, ISNULL(b.MinBet,0), ISNULL(b.MaxBet,0), autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
				FROM custsetting3rd  cs3 WITH(NOLOCK) INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
										LEFT JOIN @betSetting b ON b.Currency = c.currency
				WHERE cs3.sporttype = 151 AND cs3.bettype = 41 AND cs3.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)

		-- 152-52
		INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
				SELECT cs3.custid, 52, 152, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, ISNULL(b.MinBet,0), ISNULL(b.MaxBet,0), autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
				FROM custsetting3rd  cs3 WITH(NOLOCK) INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
										LEFT JOIN @betSetting b ON b.Currency = c.currency
				WHERE cs3.sporttype = 151 AND cs3.bettype = 42 AND cs3.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)


		-- 153-51
		INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
				SELECT cs3.custid, 51, 153, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, ISNULL(b.MinBet,0), ISNULL(b.MaxBet,0), autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
				FROM custsetting3rd  cs3 WITH(NOLOCK) INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
										LEFT JOIN @betSetting b ON b.Currency = c.currency
				WHERE cs3.sporttype = 151 AND cs3.bettype = 41 AND cs3.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)

		-- 153-52
		INSERT INTO custsetting3rd(custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, minbet, maxbet, autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking)
				SELECT cs3.custid, 52, 153, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount, ISNULL(b.MinBet,0), ISNULL(b.MaxBet,0), autopositiontaking, isautopositiontaking, autompositiontaking, isautompositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, autolivepositiontaking, isautolivepositiontaking, autolivempositiontaking, isautolivempositiontaking
				FROM custsetting3rd  cs3 WITH(NOLOCK) INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
										LEFT JOIN @betSetting b ON b.Currency = c.currency
				WHERE cs3.sporttype = 151 AND cs3.bettype = 42 AND cs3.custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)

	END
	ELSE IF @mode = 4 -- Update Min/Max PT (Custoverride3rd)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custoverride3rd' AND TYPE = 'u')
			RETURN
		-- 151-51
		INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
						SELECT custid, 51, 151, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
						FROM custoverride3rd co3 WITH(NOLOCK)
						WHERE co3.bettype = 41 AND co3.sporttype = 151 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
		-- 151-52
		INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
						SELECT custid, 52, 151, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
						FROM custoverride3rd co3  WITH(NOLOCK)
						WHERE co3.bettype = 42 AND co3.sporttype = 151 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
	-- Greyhound
		-- 152-41
		INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
						SELECT custid, 41, 152, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
						FROM custoverride3rd co3  WITH(NOLOCK)
						WHERE co3.bettype = 41 AND co3.sporttype = 151 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
		-- 152-42
		INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
						SELECT custid, 42, 152, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
						FROM custoverride3rd co3  WITH(NOLOCK)
						WHERE co3.bettype = 42 AND co3.sporttype = 151 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)

		-- 152-51
		INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
						SELECT custid, 51, 152, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
						FROM custoverride3rd co3  WITH(NOLOCK)
						WHERE co3.bettype = 41 AND co3.sporttype = 151 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
		-- 152-52
		INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
						SELECT custid, 52, 152, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
						FROM custoverride3rd co3  WITH(NOLOCK)
						WHERE co3.bettype = 42 AND co3.sporttype = 151 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)

	-- Harness
		-- 153-51
		INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
						SELECT custid, 51, 153, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
						FROM custoverride3rd co3  WITH(NOLOCK)
						WHERE co3.bettype = 41 AND co3.sporttype = 151 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
		-- 153-52
		INSERT INTO custoverride3rd(custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
						SELECT custid, 52, 153, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
						FROM custoverride3rd co3  WITH(NOLOCK)
						WHERE co3.bettype = 42 AND co3.sporttype = 151 AND custid BETWEEN 1 + @step*@COUNT AND @step*(@COUNT + 1)
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
