ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
    @ids varchar(max),
    @currency INT,
    @site varchar (20),
    @whatAreYouDoing varchar(100) = ''
AS
SET NOCOUNT ON

if @whatAreYouDoing <> 'Offer_Tycoon_NG_setting' RETURN --:D

IF NOT exists (SELECT TOP 1 1 FROM dbo.sysobjects WHERE name = 'Custinfo') RETURN

declare @string varchar(max), @splitter char(1), @xml XML
select @splitter = ',' ,@string = @ids

SET @XML = N'<root><r>' + REPLACE(@string, @splitter, '</r><r>') + '</r></root>'
declare @res AS TABLE(custid INT)
INSERT INTO @res(custid)
SELECT r.value('.','VARCHAR(12)')
FROM @xml.nodes('//root/r') AS RECORDS(r)
---------------------------------------------

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


UPDATE Custinfo WITH(rowlock, updlock)
SET maxperball161 = @maxperball,
	maxpermatch161 = @maxpermatch,
	disablenumber = 0
WHERE custid in (select custid from @res)
	

IF NOT exists (SELECT TOP 1 1 FROM dbo.sysobjects WHERE name = 'Dep_CustSetting3rd') RETURN
UPDATE Dep_CustSetting3rd WITH(rowlock, updlock)
SET minbet = @minbet, 
	maxbet = @maxbet,
	apositiontaking = @ptVALUE
WHERE custid in (select custid from @res)
    and sporttype = 161

GO
----------------------------
----------------------------

CREATE TABLE #list (custid INT PRIMARY KEY, isfinished bit)

declare @site varchar(20), @currency int
--select @site / @currency
-- Tycoon 2	
-- Tycoon 4	
-- Tycoon 13
-- Tycoon 15
-- Tycoon 61


select @site='Tycoon', @currency=2

INSERT INTO #list (custid, isfinished)
SELECT custid, 0
FROM customer WITH(NOLOCK)
WHERE roleid = 1
	and srecommend in (
		select custid 
		from dep_custsuper with(nolock)
		where currency = @currency
			and site=@site			
	)

declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (1000) #list
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #list
	where isfinished = 0
	
	select @rowcnt = @@rowcount	

	EXEC [Acc_ExecRep_09] @ids = @ids, @currency = @currency, @site = @site, @whatAreYouDoing = 'Offer_Tycoon_NG_setting' 
	
	if @rowcnt < 1000 RETURN

	WAITFOR DELAY '00:00:01'
end	

DROP TABLE #list
