ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@custid int,
	@roleid int,
	@currency int
AS

if NOT exists (select top 1 1 from dbo.sysobjects where name = 'Custinfo') RETURN
if NOT exists (select top 1 1 from dbo.sysobjects where name = 'CustSetting3rd') RETURN

declare @minbet money, @maxbet money, @maxperball money, @maxpermatch money

select @minbet = case 
					when @currency = 13 then 11 -- CNY (RMB)
					when @currency = 6 then 1 -- EUR
					when @currency = 12 then 1 -- GBP
					when @currency = 5 then 13 -- HKD (HK$)
					when @currency = 44 then 1900 -- PT (KRW)
					when @currency = 2 then 5 -- MYR (RM)
					when @currency = 1 then 3 -- SGD
					when @currency in (4,43) then 60 -- THB (TB & THB)
					when @currency in (3,16,17,35,40) then 2-- USD (US$,Yen,NTD,$US,IRR)
					when @currency = 20 then 11
				else 0 end
		,@maxbet = case 
					when @currency = 13 then 1800 -- CNY (RMB)
					when @currency = 6 then 160 -- EUR
					when @currency = 12 then 160 -- GBP
					when @currency = 5 then 2100 -- HKD (HK$)
					when @currency = 44 then 294000 -- PT (KRW)
					when @currency = 2 then 800 -- MYR (RM)
					when @currency = 1 then 500 -- SGD
					when @currency in (4,43) then 6000 -- THB (TB & THB)
					when @currency in (3,16,17,35,40) then 320-- USD (US$,Yen,NTD,$US,IRR)
					when @currency = 20 then 1800
				else 0 end
		,@maxperball = case 
					when @currency = 13 then 6600 -- CNY (RMB)
					when @currency = 6 then 500 -- EUR
					when @currency = 12 then 500 -- GBP
					when @currency = 5 then 7800 -- HKD (HK$)
					when @currency = 44 then 1100000 -- PT (KRW)
					when @currency = 2 then 3000 -- MYR (RM)
					when @currency = 1 then 1800 -- SGD
					when @currency in (4,43) then 36000 -- THB (TB & THB)
					when @currency in (3,16,17,35,40) then 1000-- USD (US$,Yen,NTD,$US,IRR)
					when @currency = 20 then 6600
				else 0 end
		,@maxpermatch = case
					when @currency = 13 then 110000 -- CNY (RMB)
					when @currency = 6 then 10000 -- EUR
					when @currency = 12 then 10000 -- GBP
					when @currency = 5 then 130000 -- HKD (HK$)
					when @currency = 44 then 18000000 -- PT (KRW)
					when @currency = 2 then 50000 -- MYR (RM)
					when @currency = 1 then 30000 -- SGD
					when @currency in (4,43) then 600000 -- THB (TB & THB)
					when @currency in (3,16,17,35,40) then 15000-- USD (US$,Yen,NTD,$US,IRR)
					when @currency = 20 then 110000
				else 0 end
IF @minbet = 0 RETURN

IF @roleid > 2 -- IF Super/Master: only update himself
BEGIN
	UPDATE dbo.custinfo with(rowlock, updlock)
	SET DisableNumber = 0
		,maxperball161 = @maxperball
		,maxpermatch161 = @maxpermatch
	WHERE custid = @custid
	
	UPDATE dbo.CustSetting3rd with(rowlock, updlock)
	SET minbet = @minbet
		,maxbet = @maxbet
	WHERE custid = @custid
		and sporttype = 161
END
ELSE IF @roleid = 2 -- IF Agent: update himself and downlines
BEGIN
	UPDATE dbo.custinfo with(rowlock, updlock)
	SET DisableNumber = 0
		,maxperball161 = @maxperball
		,maxpermatch161 = @maxpermatch
	WHERE recommend = @custid
	
	UPDATE dbo.CustSetting3rd with(rowlock, updlock)
	SET minbet = @minbet
		,maxbet = @maxbet
	WHERE custid in (select custid from custinfo with(nolock) where recommend = @custid)
		and sporttype = 161
END


GO
GRANT EXECUTE ON [dbo].[Acc_ExecRep_09] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_09] TO [vnteam]


------------------------------------
-------------------------------------
-----------------------------------


CREATE TABLE #List (custid int primary key, roleid tinyint, cnt int, currency int)

INSERT INTO #List(custid, roleid, cnt, currency)
SELECT custid, roleid, 1, currency
FROM Custinfo with(nolock)
WHERE srecommend in (
	select custid
	from customer c with(nolock)
	where roleid=4 and custid > 100
		and custid not in (
			SELECT custid
			FROM customer WITH(NOLOCK)
			WHERE 
				roleid = 4
				AND
				(
					username LIKE '3rdSuper%'  
					OR username LIKE '12BETACCSuper%'
					OR username LIKE 'MS88ACCSuper%'
					OR username LIKE 'AB88ACCSuper%'
					OR username LIKE 'ALogACCSuper%'
					OR username LIKE 'DELAACCSuper%'
					OR username LIKE 'STEST%'  
					OR username like 'DELASuper%'
					OR username like 'TLCACCSuper%'
					OR username like 'MFACCSuper%'
					OR username like 'SCACCSuper%'

				)
		)
		and custid not in (select * from f_DepSuper_1('all'))
		and site not in ('indo', '755555', '611111','722222','733333')
		and username not in ('EA','EB','EC','EE','EF','EG','EH','EI','EJ','EK','EL','EM','EN','EP','EQ','ES','ET','EU','EV','EW','EX','EY','SG','SH','SQ','XA','XB','XC','XM','XX','XY','XZ','ER','SQQR')
)
	AND roleid > 1
	AND currency in (1,2,3,4,5,6,12,13,16,17,20,35,40,44)

UNION
select CustID, roleid, 1, currency
from custinfo with(nolock) 
where mrecommend in (
		select custid--, username, e.code currency
		from customer c with(nolock)
		where roleid=3 and srecommend in (1,2,3,4,5,6,12,13,16,17,20,35,40,44)
		and site not in ('indo', '755555', '611111','722222','733333')
	)
	and roleid > 1

update #list 
set cnt = (select count(custid) from custinfo with(nolock) where #list.custid = recommend)


----------------------------

select * from #List order by cnt desc


delete top (100)
from #list
output 'EXEC dbo.acc_execrep_09 '+ cast(deleted.custid as varchar(12))+', '+ cast(deleted.roleid as varchar(2))+', '+ cast(deleted.currency as varchar(2)), deleted.cnt
where custid in (select top 100 custid from #list order by cnt desc)

-- drop table #list