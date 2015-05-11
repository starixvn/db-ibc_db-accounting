 ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
    @ids varchar(max),
    @currency INT,
    @site varchar (20),
    @whatAreYouDoing varchar(100) = ''
AS
SET NOCOUNT ON

if @whatAreYouDoing <> 'Offer_Bodog_Racing_setting' RETURN --:D

IF NOT exists (SELECT TOP 1 1 FROM dbo.sysobjects WHERE name = 'Custinfo') RETURN

declare @string varchar(max), @splitter char(1), @xml XML
select @splitter = ',' ,@string = @ids

SET @XML = N'<root><r>' + REPLACE(@string, @splitter, '</r><r>') + '</r></root>'
declare @res AS TABLE(custid INT)
INSERT INTO @res(custid)
SELECT r.value('.','VARCHAR(12)')
FROM @xml.nodes('//root/r') AS RECORDS(r)
---------------------------------------------

DECLARE @minbet MONEY, @maxbet MONEY, @maxpermatch MONEY 
DECLARE @Comm decimal (9,8), @AustComm decimal (9,8)

SELECT @Comm = 0.04, @AustComm = 0.03

SELECT  @minbet = CASE
                WHEN @currency = 1  and @site = 'Bodog' THEN 10  --SD$
				WHEN @currency = 2  and @site = 'Bodog' THEN 30  --RM/MYR
				WHEN @currency = 3  and @site = 'Bodog' THEN 10  --US$
				WHEN @currency = 4  and @site = 'Bodog' THEN 300  --TB/THB
				WHEN @currency = 6  and @site = 'Bodog' THEN 10  --EURO
				WHEN @currency = 9  and @site = 'Bodog' THEN 10 --AUD
				WHEN @currency = 12 and @site = 'Bodog' THEN 10  --GBP
				WHEN @currency = 13 and @site = 'Bodog' THEN 50  --RMB/CNY
				WHEN @currency = 20 and @site = 'Bodog' THEN 2  --UUS
				WHEN @currency = 30 and @site = 'Bodog' THEN 150  --NT/TWD
				WHEN @currency = 45 and @site = 'Bodog' THEN 7000  --Won/KRW
				WHEN @currency = 51 and @site = 'Bodog' THEN 150  --INH
				WHEN @currency = 63 and @site = 'Bodog' THEN 10 --NZD
				ELSE 0 END,

		@maxbet = CASE
				WHEN @currency = 1  and @site = 'Bodog' THEN 12476  --SD$
				WHEN @currency = 2  and @site = 'Bodog' THEN 30704  --RM/MYR
				WHEN @currency = 3  and @site = 'Bodog' THEN 10000  --US$
				WHEN @currency = 4  and @site = 'Bodog' THEN 294812  --TB/THB
				WHEN @currency = 6  and @site = 'Bodog' THEN 7689  --EURO
				WHEN @currency = 9  and @site = 'Bodog' THEN 9766 --AUD
				WHEN @currency = 12 and @site = 'Bodog' THEN 6698  --GBP
				WHEN @currency = 13 and @site = 'Bodog' THEN 62696 --RMB/CNY
				WHEN @currency = 20 and @site = 'Bodog' THEN 10000  --UUS
				WHEN @currency = 30 and @site = 'Bodog' THEN 296472  --NT/TWD
				WHEN @currency = 45 and @site = 'Bodog' THEN 10760788  --Won/KRW
				WHEN @currency = 51 and @site = 'Bodog' THEN 209118  --INH
				WHEN @currency = 63 and @site = 'Bodog' THEN 12156  --NZD
				ELSE 0 END,
               
        @maxpermatch = CASE
                WHEN @currency = 1  and @site = 'Bodog' THEN 12476  --SD$
				WHEN @currency = 2  and @site = 'Bodog' THEN 30704  --RM/MYR
				WHEN @currency = 3  and @site = 'Bodog' THEN 10000  --US$
				WHEN @currency = 4  and @site = 'Bodog' THEN 294812  --TB/THB
				WHEN @currency = 6  and @site = 'Bodog' THEN 7689  --EURO
				WHEN @currency = 9  and @site = 'Bodog' THEN 9766 --AUD
				WHEN @currency = 12 and @site = 'Bodog' THEN 6698  --GBP
				WHEN @currency = 13 and @site = 'Bodog' THEN 62696 --RMB/CNY
				WHEN @currency = 20 and @site = 'Bodog' THEN 10000  --UUS
				WHEN @currency = 30 and @site = 'Bodog' THEN 296472  --NT/TWD
				WHEN @currency = 45 and @site = 'Bodog' THEN 10760788  --Won/KRW
				WHEN @currency = 51 and @site = 'Bodog' THEN 209118  --INH
				WHEN @currency = 63 and @site = 'Bodog' THEN 12156  --NZD
				ELSE 0 END


IF (@maxbet * @minbet * @maxpermatch = 0) RETURN
	
UPDATE Custinfo WITH (ROWLOCK, UPDLOCK)
SET maxpermatch151 = @maxpermatch,
	maxpermatch151_OT = @maxpermatch,
	maxPerMatch151_AU = @maxpermatch,
	maxPerMatch152_UK = @maxpermatch,
	maxPerMatch152_AU = @maxpermatch,
	maxPerMatch153_AU = @maxpermatch,
	DisableHorseRacing = 0,
	DisableOpenTote = 0,
	Disable151_AU = 0,
	Disable152_AU = 0,
	Disable152_UK = 0,
	Disable153_AU = 0
WHERE custid IN (SELECT * FROM @res)
AND ( maxpermatch151 <> @maxpermatch
	 OR maxpermatch151_OT <> @maxpermatch
	 OR maxPerMatch151_AU <> @maxpermatch
	 OR maxPerMatch152_AU <> @maxpermatch
	 OR maxPerMatch152_UK <> @maxpermatch
	 OR maxPerMatch153_AU <> @maxpermatch
	)

IF NOT exists (SELECT TOP 1 1 FROM dbo.sysobjects WHERE name = 'Dep_CustSetting3rd') RETURN

UPDATE cs3 WITH(ROWLOCK,UPDLOCK)	
SET sdiscount = CASE WHEN roleid IN (1,4) THEN CASE WHEN bettype IN (41,42,31,32) THEN @Comm
													WHEN bettype IN (51,52) THEN @AustComm
													ELSE 0
											   END
				     ELSE 0 
				END,
	adiscount = CASE WHEN roleid IN (1,3) THEN CASE WHEN bettype IN (41,42,31,32) THEN @Comm
													WHEN bettype IN (51,52) THEN @AustComm
													ELSE 0
											   END
				    ELSE 0 
				END,
	discount  = CASE WHEN roleid IN (1,2) THEN CASE WHEN bettype IN (41,42,31,32) THEN @Comm
													WHEN bettype IN (51,52) THEN @AustComm
													ELSE 0
											   END
					ELSE 0 
				END,
	playerdiscount = 0,
	
	maxbet = @maxbet,
	minbet = @minbet,
	
	apositiontaking = 0,
	mpositiontaking = 0,
	spositiontaking = 0	
	FROM Custinfo c WITH(NOLOCK)
		INNER JOIN Dep_CustSetting3rd cs3 ON c.custid = cs3.custid
	WHERE sporttype IN (151,152,153)
		AND bettype IN (31,32,41,42,51,52)
		AND cs3.custid IN (select custid from @res)

GO
----------------------------
----------------------------

CREATE TABLE #list (custid INT PRIMARY KEY, isfinished bit)

declare @site varchar(20), @currency int

/*
srecommend currency username
custid	currency	username
4689517	1	BODOGSuperSD$
4714272	2	BODOGSuperRM
4686903 3   BODOGSuperUS$ 
4689166 4	BODOGSuperTB 
4715142	6	BODOGSuperEURO
7651889	9	BODOGSuperAUD
4715061	12	BODOGSuperGBP
4688739 13  BODOGSuperRMB 
4603197	20	BODOGSuperUUS
4689995	30	BODOGSuperNT
4715507	45	BODOGSuperWON
8198572	51	BODOGSuperINH
7652025	63	BODOGSuperNZD

*/   
   


select @site='Bodog', @currency=12

INSERT INTO #list (custid, isfinished)
SELECT custid, 0
FROM customer WITH(NOLOCK)
WHERE roleid in (1,2,3,4)
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

	EXEC [Acc_ExecRep_09] @ids = @ids, @currency = @currency, @site = @site, @whatAreYouDoing = 'Offer_Bodog_Racing_setting'
	
	if @rowcnt < 1000 RETURN

	WAITFOR DELAY '00:00:01'
end	

DROP TABLE #list