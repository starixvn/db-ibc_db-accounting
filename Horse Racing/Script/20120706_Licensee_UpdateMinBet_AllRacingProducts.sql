/*
	Created by:Jamie
	Date: 2012-06-07
	Task: Update MinBet for HR/Greyhound/Harness 

*/

--1. ALTER [Acc_ExecRep_09] 
 
	ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
		@ids varchar(max)
	AS

	SET NOCOUNT ON

	/*
		update Live casino PT setting 
		
	*/
	BEGIN
		IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('CustSetting3rd','custInfo') AND type = 'U') <> 2
			RETURN

		DECLARE @res AS TABLE (custid INT)
		DECLARE @splitter CHAR(1), @string VARCHAR(MAX)

		SELECT @splitter = ',', @string = @ids

		IF SUBSTRING (@string, LEN (@string), 1) <> @splitter
			  SET @string= @string+@splitter

		DECLARE @START INT, @word NVARCHAR(4000), @CHARINDEX INT, @i INT
		SET @i=1
		SET @START=1
		SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
		WHILE (@CHARINDEX <> 0)BEGIN
			SET @word= SUBSTRING( @string, @START, @CHARINDEX - @START)
			SET @START= @CHARINDEX +1
			SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
			INSERT INTO @res  VALUES(CAST(@word AS INT))
			SET @i=@i+1
		END

		DECLARE @tmpCurrency TABLE(
			Currency INT,
			MinBet	 MONEY,
			CurrencyName VARCHAR(10)
		)

		INSERT INTO @tmpCurrency(Currency, MinBet,CurrencyName)
				  SELECT 13 , 50 , 'RMB'
		UNION ALL SELECT 6 , 10 , 'EURO'
		UNION ALL SELECT 12 , 10 , 'GBP'
		UNION ALL SELECT 47 , 40 , 'DDD'
		UNION ALL SELECT 33 , 40 , 'IDD'
		UNION ALL SELECT 34 , 40 , 'IDR'
		UNION ALL SELECT 15 , 40 , 'IN'
		UNION ALL SELECT 22 , 40 , 'IND'
		UNION ALL SELECT 61 , 500 , 'INR'
		UNION ALL SELECT 32 , 700 , 'JPY'
		UNION ALL SELECT 37 , 700 , 'P'
		UNION ALL SELECT 31 , 700 , 'Pts'
		UNION ALL SELECT 64 , 7000 , 'KW'
		UNION ALL SELECT 44 , 7000 , 'PT'
		UNION ALL SELECT 45 , 7000 , 'Won'
		UNION ALL SELECT 2 , 30 , 'RM'
		UNION ALL SELECT 56 , 300 , 'PLN'
		UNION ALL SELECT 55 , 300 , 'RUB'
		UNION ALL SELECT 1 , 10 , 'SD$'
		UNION ALL SELECT 4 , 300 , 'TB'
		UNION ALL SELECT 43 , 300 , 'THB'
		UNION ALL SELECT 30 , 150 , 'NT'
		UNION ALL SELECT 35 , 10 , '$US'
		UNION ALL SELECT 40 , 10 , 'IRR'
		UNION ALL SELECT 17 , 10 , 'NTD'
		UNION ALL SELECT 3 , 10 , 'US$'
		UNION ALL SELECT 36 , 10 , 'Y$US'
		UNION ALL SELECT 16 , 10 , 'Yen'
		UNION ALL SELECT 51 , 150 , 'INH'

		UPDATE cs WITH (UPDLOCK,ROWLOCK)
		SET		minbet = t.minBet
		FROM	CustSetting3rd cs
				INNER JOIN custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
				INNER JOIN @tmpCurrency t ON ci.currency = t.currency 
		WHERE	cs.CustID IN (SELECT * FROM @res)	
				AND cs.sporttype BETWEEN 151 AND 153
				AND cs.bettype IN (31,32,41,42,51,52)
	END

	GO

----END- STEP 1 -  EXEC REP - [Acc_ExecRep_09]

--2. Check affected customers 

	CREATE TABLE #tmpCurrency(
		Currency INT,
		MinBet	 MONEY,
		CurrencyName VARCHAR(10)
	)

	CREATE TABLE #tmpDummyMRecommend(
	CustID INT
	)


	CREATE TABLE #temp (custid int primary key, isfinished bit) -- Customers need to be updated 


	INSERT INTO #tmpCurrency(Currency, MinBet,CurrencyName)
			  SELECT 13 , 50 , 'RMB'
	UNION ALL SELECT 6 , 10 , 'EURO'
	UNION ALL SELECT 12 , 10 , 'GBP'
	UNION ALL SELECT 47 , 40 , 'DDD'
	UNION ALL SELECT 33 , 40 , 'IDD'
	UNION ALL SELECT 34 , 40 , 'IDR'
	UNION ALL SELECT 15 , 40 , 'IN'
	UNION ALL SELECT 22 , 40 , 'IND'
	UNION ALL SELECT 61 , 500 , 'INR'
	UNION ALL SELECT 32 , 700 , 'JPY'
	UNION ALL SELECT 37 , 700 , 'P'
	UNION ALL SELECT 31 , 700 , 'Pts'
	UNION ALL SELECT 64 , 7000 , 'KW'
	UNION ALL SELECT 44 , 7000 , 'PT'
	UNION ALL SELECT 45 , 7000 , 'Won'
	UNION ALL SELECT 2 , 30 , 'RM'
	UNION ALL SELECT 56 , 300 , 'PLN'
	UNION ALL SELECT 55 , 300 , 'RUB'
	UNION ALL SELECT 1 , 10 , 'SD$'
	UNION ALL SELECT 4 , 300 , 'TB'
	UNION ALL SELECT 43 , 300 , 'THB'
	UNION ALL SELECT 30 , 150 , 'NT'
	UNION ALL SELECT 35 , 10 , '$US'
	UNION ALL SELECT 40 , 10 , 'IRR'
	UNION ALL SELECT 17 , 10 , 'NTD'
	UNION ALL SELECT 3 , 10 , 'US$'
	UNION ALL SELECT 36 , 10 , 'Y$US'
	UNION ALL SELECT 16 , 10 , 'Yen'
	UNION ALL SELECT 51 , 150 , 'INH'



	--SELECT * FROM @tmpCurrency	

	INSERT INTO #tmpDummyMRecommend(CustID) --Dummy accounts moved to real SUPERS 
	SELECT ci.custID  --, ',--',ci.username 
	FROM Custinfo ci WITH (NOLOCK)
	INNER JOIN exchange e WITH (NOLOCK)  ON ci.currency = e.exchangeID
	WHERE (	ci.username LIKE '%Acc' +e.currency 
		OR ci.username LIKE '%Cas' +e.currency
		OR ci.username LIKE '%LocalBank'+e.currency
	  )
		AND ci.roleID = 3


	INSERT INTO #temp (custid, isfinished)
	SELECT DISTINCT ci.CustID,0   --, ci.currency, t.CurrencyName, cs.MinBet, t.MinBet
	FROM Custsetting3rd cs WITH (NOLOCK)
		INNER JOIN Custinfo ci WITH (NOLOCK) ON cs.custid = ci.custid 
		INNER JOIN #tmpCurrency t WITH (NOLOCK) ON ci.currency= t.currency 
	WHERE cs.CustID IN (
				SELECT CustID FROM custInfo WITH (NOLOCK) 
				WHERE srecommend IN (SELECT CustID FROM f_DepSuper_1('12bet')) -- SELECT * f_DepSuper_1('ALL') --Not in DELA  
					AND mrecommend NOT IN (SELECT CustID FROM #tmpDummyMRecommend WITH (NOLOCK))
			)
	AND cs.sporttype BETWEEN 151 AND 153
	AND cs.Bettype IN (31,32, 41,42,51,52) 
	AND ci.currency <> 20
	AND cs.minbet < t.minBet
	AND ci.custid <  @MaxCustID   --- SELECT MAX(CustID) FROM Custinfo WITH (NOLOCK) 

---- END STEP 2 

--3. RUN SCRIPT 

CREATE TABLE #tmpScript (ID INT IDENTITY(1,1), s varchar(MAX))

declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (5000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount

	INSERT INTO #tmpScript (s)
	
	SELECT ' EXEC [Acc_ExecRep_09] @ids =' +'''' + @ids +''' GO'
	
	--EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 5000 RETURN
	--WAITFOR DELAY '00:00:03'
end

----CHECKING 
--SELECT top 10 *
--FROM #tmpScript 
--WHERE S not LIKE '%GO'
