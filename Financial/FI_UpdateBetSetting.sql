ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@username varchar(50)
AS

--Bet Setting for Financial(201)

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

Declare @custid int, @currency int, @roleid tinyint,
    @minbet money, @maxbet money, @maxpermatch money
    
select @custid = custid, @currency = currency, @roleid = roleid 
from custinfo with (nolock) where username = @username

if (@roleid not in (4,3,2,1)) 
    RETURN

CREATE TABLE #tempExchange (Currency int, CurName varchar(50),
                minbet money, maxbet money, maxpermatch money)
                
CREATE UNIQUE CLUSTERED INDEX IX_1 on #tempExchange (currency)


INSERT INTO #tempExchange([Currency], [CurName], [MinBet], [MaxBet], [MaxPerMatch])
SELECT 35, N'$US', 10, 300, 12000 UNION ALL
SELECT 9, N'AUD', 10, 400, 16000 UNION ALL
SELECT 46, N'BND', 10, 500, 20000 UNION ALL
SELECT 21, N'CAD', 10, 200, 8000 UNION ALL
SELECT 41, N'CHF', 10, 400, 16000 UNION ALL
SELECT 47, N'DDD', 10, 3800, 152000 UNION ALL
SELECT 6, N'EURO', 10, 300, 12000 UNION ALL
SELECT 12, N'GBP', 10, 200, 8000 UNION ALL
SELECT 5, N'HK$', 10, 2400, 96000 UNION ALL
SELECT 27, N'H', 10, 4400, 176000 UNION ALL
SELECT 33, N'IDD', 10, 4000, 160000 UNION ALL
SELECT 34, N'IDR', 10, 4000, 160000 UNION ALL
SELECT 15, N'IN', 10, 4000, 160000 UNION ALL
SELECT 22, N'IND', 10, 4000, 160000 UNION ALL
SELECT 40, N'IRR', 10, 300, 12000 UNION ALL
SELECT 32, N'JPY', 10, 27000, 1080000 UNION ALL
SELECT 30, N'NT', 10, 9500, 380000 UNION ALL
SELECT 17, N'NTD', 10, 300, 12000 UNION ALL
SELECT 37, N'P', 10, 300, 12000 UNION ALL
SELECT 42, N'PE', 10, 13700, 548000 UNION ALL
SELECT 44, N'PT', 10, 3800, 152000 UNION ALL
SELECT 31, N'Pts', 10, 27000, 1080000 UNION ALL
SELECT 2, N'RM', 10, 1000, 40000 UNION ALL
SELECT 26, N'M', 10, 500, 20000 UNION ALL
SELECT 13, N'RMB', 10, 2000, 80000 UNION ALL
SELECT 28, N'C', 10, 4500, 180000 UNION ALL
SELECT 1, N'SD$', 10, 500, 20000 UNION ALL
SELECT 29, N'S', 10, 900, 36000 UNION ALL
SELECT 4, N'TB', 10, 10000, 400000 UNION ALL
SELECT 25, N'TBS', 10, 22000, 880000 UNION ALL
SELECT 43, N'THB', 10, 10000, 400000 UNION ALL
SELECT 3, N'US$', 10, 300, 12000 UNION ALL
SELECT 45, N'Won', 10, 324000, 12960000 UNION ALL
SELECT 36, N'Y$US', 10, 300, 12000 UNION ALL
SELECT 16, N'Yen', 10, 300, 12000 UNION ALL
SELECT 20, N'UUS', 10, 499, 1500



select @minbet = minbet, @maxbet = maxbet, @maxpermatch = maxpermatch
from #tempExchange
where currency = @currency

if @currency not in (select currency from #tempExchange)
BEGIN
    PRINT 'ERROR ACCOUNT: ' + @username
    RETURN
END

DROP TABLE #tempExchange

if @roleid = 4
BEGIN
	update custinfo with(rowlock,updlock)
	set maxpermatch201 = @maxpermatch
	where srecommend = @custid
END
IF @roleid = 3 
BEGIN
	update custinfo with(rowlock,updlock)
	set maxpermatch201 = @maxpermatch
	where mrecommend = @custid
END

IF @roleid = 2
BEGIN
	update custinfo with(rowlock,updlock)
	set maxpermatch201 = @maxpermatch
	where recommend = @custid
END
IF @roleid = 1
BEGIN
	update custinfo with(rowlock,updlock)
	set maxpermatch201 = @maxpermatch
	where custid = @custid
END

IF NOT EXISTS  (SELECT COUNT(*) FROM dbo.sysobjects
                WHERE name in ('custsetting3rd','custoverride3rd')
                    and xtype = 'U'
                HAVING COUNT(*) = 2)
BEGIN
    RETURN
END

if @roleid = 4
BEGIN
    update custsetting3rd with(rowlock,updlock)
	set	
        minbet = @minbet,
        maxbet = @maxbet
     where sporttype = 201 
	    and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)
END

if @roleid = 3
BEGIN
    update custsetting3rd with(rowlock,updlock)
	set	
        minbet = @minbet,
        maxbet = @maxbet
     where sporttype = 201 
	    and custid IN (select custid from custinfo with (nolock) where mrecommend = @custid)
END

if @roleid = 2 
BEGIN	
    update custsetting3rd with(rowlock,updlock)
	set	
        minbet = @minbet,
        maxbet = @maxbet
     where sporttype = 201 
	    and custid IN (select custid from custinfo with (nolock) where recommend = @custid)
END

if @roleid = 1 
BEGIN	
    update custsetting3rd with(rowlock,updlock)
	set	
        minbet = @minbet,
        maxbet = @maxbet
     where sporttype = 201 
	    and custid = @custid
END

