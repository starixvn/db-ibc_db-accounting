--Super level
update custsetting set
	spositiontaking = 0.75,
	mpositiontaking = 0.75,
	apositiontaking = 0.75,
	slivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.75 else 0 end,
	mlivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.75 else 0 end,
	alivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.75 else 0 end	
where custid  in (791080,791081,836203,836212,836218,836226,916498,1015419,1015427)

--Master level
update custsetting set
	spositiontaking = 0,
	mpositiontaking = 0.75,	
	slivepositiontaking = 0,
	mlivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.75 else 0 end		
where custid  in (1015420,1015429,791087,836214,836222,836228,836207,791082)

--Agent Level
update custsetting set
	mpositiontaking = 0,
	apositiontaking = 0.75,
	mlivepositiontaking = 0,
	alivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.75 else 0 end	
where custid  in (1015422,1015430,791088,836215,836224,836230,836210,791083)

--Member Level

update custsetting set
	mpositiontaking = 0,
	apositiontaking = 0.75,
	mlivepositiontaking = 0,
	alivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.75 else 0 end	
where custid in (
	select custid from custinfo with (nolock)
	where recommend in (1015422,1015430,791088,836215,836224,836230,836210,791083)
		and roleid = 1)

--Affiliate
update custsetting set
	mpositiontaking = 0.75 - apositiontaking,	
	mlivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.75 - alivepositiontaking  else 0 end	
where custid in (
	select custid from custinfo with (nolock)
	where recommend in (1015423,1015433,860379,860383,860386,860387,860380,860376)
		and roleid = 1)
		
		-----------
		
--Affiliate
update custsetting set
	mpositiontaking = 0.75 - apositiontaking,	
	mlivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then 0.75 - alivepositiontaking  else 0 end	
where custid in (
	select custid from custinfo with (nolock)
	where mrecommend = 927780
		and roleid = 2)