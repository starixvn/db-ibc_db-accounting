ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
    @custid INT,   
    @currency INT,
    @site varchar (20),
    @whatAreYouDoing varchar(100) = ''
AS
SET NOCOUNT ON

if @whatAreYouDoing <> 'Offer_Tycoon_NG_setting' RETURN --:D

DECLARE @minbet MONEY, @maxbet MONEY, @maxpermatch MONEY, @maxperball MONEY, @ptVALUE SMALLMONEY
SELECT  @ptVALUE = 0.85
SELECT @minbet = CASE
                WHEN @currency = 13 and @site = 'Mayfair' THEN 10  --CNY
                WHEN @currency = 15 and @site = 'Macaubet' THEN 1  --IDR
                WHEN @currency = 3 and @site = 'bodog' THEN 1  --USD
                WHEN @currency = 12 and @site = 'bodog' THEN 1  --GBP
                WHEN @currency = 6 and @site = 'bodog' THEN 1  --EUR
                WHEN @currency = 13 and @site = 'bodog' THEN 1  --CNY
                WHEN @currency = 2 and @site = 'bodog' THEN 1  --MYR
                WHEN @currency = 4 and @site = 'bodog' THEN 1  --THB
                WHEN @currency = 1 and @site = 'bodog' THEN 1  --SGD
                WHEN @currency = 45 and @site = 'bodog' THEN 1100  --KRW
                
                --Alog
                WHEN @currency = 13 and @site = 'alog' THEN 1  --CNY
                WHEN @currency = 3 and @site = 'alog' THEN 10  --USD
                WHEN @currency = 12 and @site = 'alog' THEN 5  --GBP
                WHEN @currency = 2 and @site = 'alog' THEN 5  --MYR
                WHEN @currency = 1 and @site = 'alog' THEN 5  --SGD
                WHEN @currency = 4 and @site = 'alog' THEN 10  --THB
                WHEN @currency = 6 and @site = 'alog' THEN 5  --EUR
                WHEN @currency = 32 and @site = 'alog' THEN 100  --JPY
				WHEN @currency = 45 and @site = 'alog' THEN 1000  --KRW
				WHEN @currency = 61 and @site = 'alog' THEN 1  --INR
				WHEN @currency = 51 and @site = 'alog' THEN 10  --INH
				WHEN @currency = 15 and @site = 'alog' THEN 10  --IDR
				WHEN @currency = 55 and @site = 'alog' THEN 40  --RUB
				WHEN @currency = 56 and @site = 'alog' THEN 1  --RUB  
				-- TLC
				WHEN @currency = 13 and @site = 'TLC' THEN 2  --CNY
				-- Fun88
				WHEN @currency = 13 and @site = 'asiabet88' THEN 2  --CNY
				WHEN @currency = 4 and @site = 'asiabet88' THEN 10  --THB
				WHEN @currency = 51 and @site = 'asiabet88' THEN 5  --INH
				WHEN @currency = 15 and @site = 'asiabet88' THEN 3  --IDR
				WHEN @currency = 6 and @site = 'asiabet88' THEN 1  --EUR
				WHEN @currency = 3 and @site = 'asiabet88' THEN 1  --USD	
				--VCAsia
				WHEN @currency = 13 and @site = 'VCAsia' THEN 1  --CNY
				--SunGame	
				WHEN @currency = 13 and @site = 'SunGame' THEN 5  --CNY 
                WHEN @currency = 51 and @site = 'SunGame' THEN 10  --VN
                WHEN @currency = 4 and @site = 'SunGame' THEN 20  --TB		
                
                -- Tycoon    
                WHEN @currency = 13 and @site = 'Tycoon' THEN 10  --CNY
                WHEN @currency = 2 and @site = 'Tycoon' THEN 10  --MYR
                WHEN @currency = 15 and @site = 'Tycoon' THEN 10  --IDR
                WHEN @currency = 61 and @site = 'Tycoon' THEN 10  --INR
                WHEN @currency = 4 and @site = 'Tycoon' THEN 100  --THB
            ELSE 0 END,
        @maxbet = CASE
                WHEN @currency = 13 and @site = 'Mayfair' THEN 5000  --CNY
                WHEN @currency = 15 and @site = 'Macaubet' THEN 8800  --IDR
                WHEN @currency = 3 and @site = 'bodog' THEN 5000  --USD
                WHEN @currency = 12 and @site = 'bodog' THEN 3250  --GBP
                WHEN @currency = 6 and @site = 'bodog' THEN 3750  --EUR
                WHEN @currency = 13 and @site = 'bodog' THEN 30000  --CNY
                WHEN @currency = 2 and @site = 'bodog' THEN 15000  --MYR
                WHEN @currency = 4 and @site = 'bodog' THEN 6250  --THB
                WHEN @currency = 1 and @site = 'bodog' THEN 6250  --SGD
                WHEN @currency = 45 and @site = 'bodog' THEN 5500000  --KRW
                --Alog
                WHEN @currency = 13 and @site = 'alog' THEN 30000  --CNY
                WHEN @currency = 3 and @site = 'alog' THEN 5000  --USD
                WHEN @currency = 12 and @site = 'alog' THEN 5000  --GBP
                WHEN @currency = 2 and @site = 'alog' THEN 10000  --MYR
                WHEN @currency = 1 and @site = 'alog' THEN 5000 --SGD
                WHEN @currency = 4 and @site = 'alog' THEN 100000  --THB
                WHEN @currency = 6 and @site = 'alog' THEN 5000  --EUR
                WHEN @currency = 32 and @site = 'alog' THEN 500000  --JPY
				WHEN @currency = 45 and @site = 'alog' THEN 500000  --KRW
				WHEN @currency = 61 and @site = 'alog' THEN 250000  --INR
				WHEN @currency = 51 and @site = 'alog' THEN 100000  --INH
				WHEN @currency = 15 and @site = 'alog' THEN 50000  --IDR
				WHEN @currency = 55 and @site = 'alog' THEN 200000  --RUB
				WHEN @currency = 56 and @site = 'alog' THEN 15000  --RUB
				-- TLC
				WHEN @currency = 13 and @site = 'TLC' THEN 2000  --CNY
				-- Fun88
				WHEN @currency = 13 and @site = 'asiabet88' THEN 2000 --CNY
				WHEN @currency = 4 and @site = 'asiabet88' THEN 10000  --THB
				WHEN @currency = 51 and @site = 'asiabet88' THEN 5000  --INH
				WHEN @currency = 15 and @site = 'asiabet88' THEN 3000  --IDR
				WHEN @currency = 6 and @site = 'asiabet88' THEN 200  --EUR
				WHEN @currency = 3 and @site = 'asiabet88' THEN 500  --USD
				--VCAsia
				WHEN @currency = 13 and @site = 'VCAsia' THEN 3000  --CNY
				--Sungame
				WHEN @currency = 13 and @site = 'SunGame' THEN 2000  --CNY/RMB 
                WHEN @currency = 51 and @site = 'SunGame' THEN 7000  --VN
                WHEN @currency = 4 and @site = 'SunGame' THEN 10000  --TB
                
                -- Tycoon    
                WHEN @currency = 13 and @site = 'Tycoon' THEN 1000  --CNY
                WHEN @currency = 2 and @site = 'Tycoon' THEN 1000  --MYR
                WHEN @currency = 15 and @site = 'Tycoon' THEN 1000  --IDR
                WHEN @currency = 61 and @site = 'Tycoon' THEN 1000  --INR
                WHEN @currency = 4 and @site = 'Tycoon' THEN 10000  --THB
            ELSE 0 END,
		@maxperball = CASE
                WHEN @currency = 13 and @site = 'Mayfair' THEN 5000  --CNY
                WHEN @currency = 15 and @site = 'Macaubet' THEN 30000  --IDR
                WHEN @currency = 3 and @site = 'bodog' THEN 5000  --USD
                WHEN @currency = 12 and @site = 'bodog' THEN 3250  --GBP
                WHEN @currency = 6 and @site = 'bodog' THEN 3750  --EUR
                WHEN @currency = 13 and @site = 'bodog' THEN 30000  --CNY
                WHEN @currency = 2 and @site = 'bodog' THEN 15000  --MYR
                WHEN @currency = 4 and @site = 'bodog' THEN 6250  --THB
                WHEN @currency = 1 and @site = 'bodog' THEN 6250  --SGD
                WHEN @currency = 45 and @site = 'bodog' THEN 5500000  --KRW
                 --Alog
                WHEN @currency = 13 and @site = 'alog' THEN 200000  --CNY
                WHEN @currency = 3 and @site = 'alog' THEN 20000  --USD
                WHEN @currency = 12 and @site = 'alog' THEN 20000  --GBP
                WHEN @currency = 2 and @site = 'alog' THEN 50000  --MYR
                WHEN @currency = 1 and @site = 'alog' THEN 25000 --SGD
                WHEN @currency = 4 and @site = 'alog' THEN 2000000  --THB
                WHEN @currency = 6 and @site = 'alog' THEN 20000  --EUR
                WHEN @currency = 32 and @site = 'alog' THEN 1000000  --JPY
				WHEN @currency = 45 and @site = 'alog' THEN 10000000  --KRW
				WHEN @currency = 61 and @site = 'alog' THEN 500000  --INR
				WHEN @currency = 51 and @site = 'alog' THEN 20000  --INH
				WHEN @currency = 15 and @site = 'alog' THEN 50000  --IDR
				WHEN @currency = 55 and @site = 'alog' THEN 400000  --RUB
				WHEN @currency = 56 and @site = 'alog' THEN 30000  --RUB
				-- TLC
				WHEN @currency = 13 and @site = 'TLC' THEN 4000  --CNY
				-- Fun88
				WHEN @currency = 13 and @site = 'asiabet88' THEN 4000 --CNY
				WHEN @currency = 4 and @site = 'asiabet88' THEN 20000  --THB
				WHEN @currency = 51 and @site = 'asiabet88' THEN 10000  --INH
				WHEN @currency = 15 and @site = 'asiabet88' THEN 6000  --IDR
				WHEN @currency = 6 and @site = 'asiabet88' THEN 400  --EUR
				WHEN @currency = 3 and @site = 'asiabet88' THEN 1000  --USD
				--VCAsia
				WHEN @currency = 13 and @site = 'VCAsia' THEN 30000  --CNY
				--SunGame
				WHEN @currency = 13 and @site = 'SunGame' THEN 2000  --CNY/RMB 
                WHEN @currency = 51 and @site = 'SunGame' THEN 7000  --VN
                WHEN @currency = 4 and @site = 'SunGame' THEN 10000  --TB
                
                 -- Tycoon    
                WHEN @currency = 13 and @site = 'Tycoon' THEN 10000  --CNY
                WHEN @currency = 2 and @site = 'Tycoon' THEN 10000  --MYR
                WHEN @currency = 15 and @site = 'Tycoon' THEN 10000  --IDR
                WHEN @currency = 61 and @site = 'Tycoon' THEN 10000  --INR
                WHEN @currency = 4 and @site = 'Tycoon' THEN 100000  --THB
            ELSE 0 END,
         @maxpermatch = CASE
                WHEN @currency = 13 and @site = 'Mayfair' THEN 5000  --CNY
                WHEN @currency = 15 and @site = 'Macaubet' THEN 150000  --IDR
                WHEN @currency = 3 and @site = 'bodog' THEN 15000  --USD
                WHEN @currency = 12 and @site = 'bodog' THEN 10000  --GBP
                WHEN @currency = 6 and @site = 'bodog' THEN 10000  --EUR
                WHEN @currency = 13 and @site = 'bodog' THEN 100000  --CNY
                WHEN @currency = 2 and @site = 'bodog' THEN 45000  --MYR
                WHEN @currency = 4 and @site = 'bodog' THEN 19000  --THB
                WHEN @currency = 1 and @site = 'bodog' THEN 19000  --SGD
                WHEN @currency = 45 and @site = 'bodog' THEN 16500000  --KRW
                
                 --Alog
                WHEN @currency = 13 and @site = 'alog' THEN 200000  --CNY
                WHEN @currency = 3 and @site = 'alog' THEN 20000  --USD
                WHEN @currency = 12 and @site = 'alog' THEN 20000  --GBP
                WHEN @currency = 2 and @site = 'alog' THEN 50000  --MYR
                WHEN @currency = 1 and @site = 'alog' THEN 25000 --SGD
                WHEN @currency = 4 and @site = 'alog' THEN 2000000  --THB
                WHEN @currency = 6 and @site = 'alog' THEN 20000  --EUR
                WHEN @currency = 32 and @site = 'alog' THEN 2000000  --JPY
				WHEN @currency = 45 and @site = 'alog' THEN 20000000  --KRW
				WHEN @currency = 61 and @site = 'alog' THEN 1000000  --INR
				WHEN @currency = 51 and @site = 'alog' THEN 40000  --INH
				WHEN @currency = 15 and @site = 'alog' THEN 100000  --IDR
				WHEN @currency = 55 and @site = 'alog' THEN 800000  --RUB
				WHEN @currency = 56 and @site = 'alog' THEN 60000  --RUB
				-- TLC
				WHEN @currency = 13 and @site = 'TLC' THEN 50000  --CNY
				-- Fun88
				WHEN @currency = 13 and @site = 'asiabet88' THEN 50000 --CNY
				WHEN @currency = 4 and @site = 'asiabet88' THEN 250000  --THB
				WHEN @currency = 51 and @site = 'asiabet88' THEN 150000 --INH
				WHEN @currency = 15 and @site = 'asiabet88' THEN 75000  --IDR
				WHEN @currency = 6 and @site = 'asiabet88' THEN 5000  --EUR
				WHEN @currency = 3 and @site = 'asiabet88' THEN 15000  --USD
				--VCAsia
				WHEN @currency = 13 and @site = 'VCAsia' THEN 30000  --CNY
				--Sungame
				WHEN @currency = 13 and @site = 'SunGame' THEN 30000  --CNY/RMB 
                WHEN @currency = 51 and @site = 'SunGame' THEN 100000  --VN
                WHEN @currency = 4 and @site = 'SunGame' THEN 150000  --TB
                
                 -- Tycoon    
                WHEN @currency = 13 and @site = 'Tycoon' THEN 50000  --CNY
                WHEN @currency = 2 and @site = 'Tycoon' THEN 50000  --MYR
                WHEN @currency = 15 and @site = 'Tycoon' THEN 50000  --IDR
                WHEN @currency = 61 and @site = 'Tycoon' THEN 50000  --INR
                WHEN @currency = 4 and @site = 'Tycoon' THEN 500000  --THB
            ELSE 0 END

IF NOT exists (SELECT TOP 1 1 FROM dbo.sysobjects WHERE name = 'Custinfo') RETURN
 
UPDATE Custinfo WITH(rowlock, updlock)
SET maxperball161 = @maxperball,
	maxpermatch161 = @maxpermatch,
	disablenumber = 0
WHERE srecommend = @custid
    --and (maxperball161 <> @maxperball or maxpermatch161 <> @maxpermatch)
	and roleid in (2,3,4)
	

IF NOT exists (SELECT TOP 1 1 FROM dbo.sysobjects WHERE name = 'Dep_CustSetting3rd') RETURN
--UPDATE AT SUPER LEVEL
UPDATE Dep_CustSetting3rd WITH (ROWLOCK, UPDLOCK)
SET minbet = @minbet, 
	maxbet = @maxbet,
	apositiontaking = @ptVALUE,
    mpositiontaking = @ptVALUE,
    spositiontaking = @ptVALUE    
WHERE CustID = @custid
      AND sporttype = 161
      AND bettype BETWEEN 81 AND 90

--UPDATE AT MASTER LEVEL
UPDATE Dep_CustSetting3rd WITH (ROWLOCK, UPDLOCK)
SET minbet = @minbet, 
	maxbet = @maxbet,
	apositiontaking = 0,
	mpositiontaking = @ptVALUE,
    spositiontaking = 0 
WHERE sporttype = 161
      AND bettype BETWEEN 81 AND 90
      AND custid IN (SELECT custid FROM custinfo(nolock) WHERE srecommend = @custid AND roleid = 3)  
      
--UPDATE AT AGENT LEVEL
UPDATE Dep_CustSetting3rd WITH (ROWLOCK, UPDLOCK)
SET minbet = @minbet, 
	maxbet = @maxbet,
	apositiontaking = @ptVALUE,
	mpositiontaking = 0,
    spositiontaking = 0
WHERE sporttype = 161
      AND bettype BETWEEN 81 AND 90
      AND custid IN (SELECT custid FROM custinfo(nolock) WHERE srecommend = @custid AND roleid = 2)  

GO
----------------------------
----------------------------

CREATE TABLE #list (custid INT PRIMARY KEY, currency INT, isdone BIT, username VARCHAR(50), [site] varchar(20))

INSERT INTO #list (custid, currency, isdone, username, [site])
/*SELECT custid, currency, 0, username,[site]
FROM dep_custsuper WITH(NOLOCK)
WHERE (site = 'Mayfair' and currency = 13)
	   OR (site = 'Macaubet' and currency = 15)
	   OR  (site = 'bodog' and currency IN (12,6,13,2,4,1,45))
	   OR  (site = 'alog' and currency IN (13,3,12,2,1,4,6,32,45,61,51,15,55,56))
	   OR  (site = 'TLC' and currency = 13)
	   OR  (site = 'asiabet88' and currency IN (13,4,51,15,6,3))
	   OR  (site = 'VCAsia' and currency = 13)
	   OR  (site = 'SunGame' and currency IN (4,13,51)) */

SELECT custid, currency, 0, username,[site]
FROM dep_custsuper WITH(NOLOCK)
WHERE (site = 'Tycoon' and currency IN (2,4,13,15,61))

DECLARE @custid INT, @currency INT, @username VARCHAR(50), @site VARCHAR (20)

WHILE (1=1)
BEGIN
    UPDATE TOP (1) #list
    SET @custid = custid,
        @currency = currency,
        @username = username,        
        @site = [site],
        isdone = 1
    WHERE isdone = 0
   
    IF @@ROWCOUNT = 0 BREAK
 
    EXEC dbo.Acc_ExecRep_09 
		@custid = @custid,
		@currency = @currency,
		@site = @site,
		@whatAreYouDoing = 'Offer_Tycoon_NG_setting' 
		
    PRINT @username
END

DROP TABLE #list
