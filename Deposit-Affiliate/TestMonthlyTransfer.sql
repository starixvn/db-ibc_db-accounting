use bodb02
------------------------------
Declare @Month int, 
		@Year int,
	    @AffMaster varchar(50)	
select @Month=6, @Year=2009,@AffMaster='12BETAFF'

declare @FirstDay datetime,
		@LastDay datetime	
Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
Select @LastDay = dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1, 0))


print cast(@LastDay as varchar(12))

---Delete all transfer from this month if exists
IF EXISTS (select 1
			from bettrans with (nolock)
			where 	
				bettype =105
				and datediff(month,@FirstDay,winlostdate)=0				
			) or exists (select 1
			from DB03.[12betaffiliate].dbo.Affiliate_Bettrans with (nolock)
			where 	
				bettype =105
				and datediff(month,@FirstDay,winlostdate)=0				
			)
	begin
       print 'test'
		/*declare @count int
        select @count=count(1)
        from DB03.bodb02.dbo.Affiliate_Bettrans with(nolock)
		where bettype=105 and datediff(month,@FirstDay,WinlostDate)=0*/


		delete DB03.[12betaffiliate].dbo.Affiliate_Bettrans with(rowlock,updlock)
		where bettype=105 and datediff(month,@LastDay,WinlostDate)=0

		/*update ref with(rowlock,updlock)
        set refno=refno-@@ROWCOUNT-1 
        where refid='aff' */
  
		delete bettrans 
		where bettype=105 and 
              -- transdesc like '%Affiliate Monthly transfer 105%'
              matchid=0
              and datediff(month,@FirstDay,WinlostDate)=0
  end
/*
declare @mrecommend INT 
select @mrecommend=927780
CREATE TABLE #AffCustInfo
(
	custid int primary key,
	username nvarchar(50),		
	recommend int,
	mrecommend int,
	srecommend int,	
	currency int,
	roleid tinyint,
	AffiliateID int
)

CREATE NONCLUSTERED INDEX IX_#AffCustInfo_AffiliateID ON #AffCustInfo(AffiliateID)

INSERT #AffCustInfo(custid,username,recommend,mrecommend,srecommend,currency,roleid,AffiliateID)
SELECT custid,username,recommend,mrecommend,srecommend,currency,roleid,AffiliateID
FROM custinfo with(nolock) 
where recommend in (select aff.custid
					from custinfo aff with (nolock)
					 inner join exchange e with (nolock) on aff.currency=e.exchangeid	 	
					where roleid=2 and 
					      aff.username = '12BET' + e.currency + '02'
					) and roleid=1

delete #AffCustInfo where AffiliateID=0

delete #AffCustInfo 
from
#AffCustInfo affcust
 inner join 
 custinfo aff on affcust.AffiliateID=aff.custid and aff.mrecommend=@mrecommend



select *
from #AffCustInfo 

select distinct AffiliateID from  #AffCustInfo

drop table #AffCustInfo

*/
exec [Task_Aff_MonthlyTransfer] @Month,@Year,@AffMaster

select * from DB03.[12betaffiliate].dbo.Affiliate_Bettrans
where bettype=105 and datediff(month,@FirstDay,WinlostDate)=0

select username,winlost,actual_stake,awinlost,bettype,transid,refno,currency,actualrate,winlostdate,recommend,mrecommend,srecommend 
from bettrans 
where 
--where refno=200076440631 and
 --and currency=13 and
transdesc like '%Affiliate Monthly transfer 105%'
and winlostdate=cast(@LastDay as varchar(12))--cast(@Year as varchar(4)) + '-' + cast(@Month as varchar(2)) + '-01'
order by refno,transid asc



select * from ref
