--Script to update PT of whole chain with the same PT settings for all sport types, bet types, live

--SAMPLE:
--=================================================
--Agent = 0 
--Master = 60% 
--Super = 10% + auto 
--=================================================

declare @custid int
select @custid = @custid --Master ID here

--update PT on members:
update custsetting set 
	spositiontaking = 0.05,
	mpositiontaking = 0.65,
	apositiontaking = 0,

	slivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.05 else 0 end,
	mlivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.65 else 0 end,
	alivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0 else 0 end
where custid IN(select custid from customer with (nolock) where roleid = 1 and mrecommend = @custid)
	  and sporttype not in (151,201)





--update master preset PT (super set):
update custsetting set
	spositiontaking = 0.05,--super preset
	mpositiontaking = 0.65,--master preset
	slivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.05 else 0 end,
	mlivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.65 else 0 end,

	isautopositiontaking = 0,--super auto
	autopositiontaking = 0,

	isautolivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0 else 0 end,
	autolivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0 else 0 end
where custid = @custid and sporttype not in (151,201)


--update agent preset PT (master set):
update custsetting set 
	mpositiontaking = 0.65,--master preset
	apositiontaking = 0,--agent
	mlivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.65 else 0 end,
	alivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0 else 0 end
where custid IN(select custid from customer with (nolock) where roleid = 2 and mrecommend = @custid)
	  and sporttype not in (151,201) 





