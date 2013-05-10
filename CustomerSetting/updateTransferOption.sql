Create table #tempCust (CustID int)
insert into #tempCust
Select custid from customer
where srecommend in (Select custid from customer
				where username in ('KAM','KAR','KBR','KCR','KH','KHH','KHK','KM','KMA','KMAM','KMM','KR','KRC','KRR','KS','KSD','KT'))
and roleid in (2,3)

select * from #tempCust

update customer set transferoption = dbo.F_Binary_Decimal('01001001')
	where custid in (select custid from #tempCust)