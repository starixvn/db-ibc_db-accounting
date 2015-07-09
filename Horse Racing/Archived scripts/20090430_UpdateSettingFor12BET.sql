--MinBet = 1 for all currencies
 
--         MaxBet MaxPerMatch
--RM        1000    3000      836218	12BETSuperRM
--RMB       2000    6000        836226	12BETSuperRMB
--US$       300     1000       791080	12BETSuperUS$
--EURO      300     700        791081	12BETSuperEURO
--GBP       200     600       836212	12BETSuperGBP

------------------------------------------------------------------------------
--RM        1000    3000      836218	12BETSuperRM
update custsetting set	
    minbet=1,
    maxbet=1000,
    apositiontaking=0,mpositiontaking=0,spositiontaking=0,alivepositiontaking=0,mlivepositiontaking=0,slivepositiontaking=0,autopositiontaking=0,autolivepositiontaking=0,isautopositiontaking=0,isautolivepositiontaking=0,sdiscount = 0,playerdiscount = 0,discount =0,adiscount=0,groupa = 0,groupb = 0,groupc = 0,groupd = 0,groupe = 0,groupf = 0
 where sporttype = 151
	and custid IN
	(	select custid from custinfo with (nolock)
		where srecommend = 836218

	)
update custinfo set maxpermatch151 = 3000,
                    disablehorseracing = 0
where srecommend = 836218

------------------------------------------------------------------------------
--RMB       2000    6000        836226	12BETSuperRMB
update custsetting set	
    minbet=1,
    maxbet=2000,
    apositiontaking=0,mpositiontaking=0,spositiontaking=0,alivepositiontaking=0,mlivepositiontaking=0,slivepositiontaking=0,autopositiontaking=0,autolivepositiontaking=0,isautopositiontaking=0,isautolivepositiontaking=0,sdiscount = 0,playerdiscount = 0,discount =0,adiscount=0,groupa = 0,groupb = 0,groupc = 0,groupd = 0,groupe = 0,groupf = 0
 where sporttype = 151
	and custid IN
	(	select custid from custinfo with (nolock)
		where srecommend = 836226

	)
update custinfo set maxpermatch151 = 6000,
                    disablehorseracing = 0
where srecommend = 836226
------------------------------------------------------------------------------
--US$       300     1000       791080	12BETSuperUS$
update custsetting set	
    minbet=1,
    maxbet=300,
    apositiontaking=0,mpositiontaking=0,spositiontaking=0,alivepositiontaking=0,mlivepositiontaking=0,slivepositiontaking=0,autopositiontaking=0,autolivepositiontaking=0,isautopositiontaking=0,isautolivepositiontaking=0,sdiscount = 0,playerdiscount = 0,discount =0,adiscount=0,groupa = 0,groupb = 0,groupc = 0,groupd = 0,groupe = 0,groupf = 0
 where sporttype = 151
	and custid IN
	(	select custid from custinfo with (nolock)
		where srecommend = 791080

	)
update custinfo set maxpermatch151 = 1000,
                    disablehorseracing = 0
where srecommend = 791080

------------------------------------------------------------------------------
--EURO      300     700        791081	12BETSuperEURO
update custsetting set	
    minbet=1,
    maxbet=300,
    apositiontaking=0,mpositiontaking=0,spositiontaking=0,alivepositiontaking=0,mlivepositiontaking=0,slivepositiontaking=0,autopositiontaking=0,autolivepositiontaking=0,isautopositiontaking=0,isautolivepositiontaking=0,sdiscount = 0,playerdiscount = 0,discount =0,adiscount=0,groupa = 0,groupb = 0,groupc = 0,groupd = 0,groupe = 0,groupf = 0
 where sporttype = 151
	and custid IN
	(	select custid from custinfo with (nolock)
		where srecommend = 791081

	)
update custinfo set maxpermatch151 = 700,
                    disablehorseracing = 0
where srecommend = 791081

------------------------------------------------------------------------------
--GBP       200     600       836212	12BETSuperGBP
update custsetting set	
    minbet=1,
    maxbet=200,
    apositiontaking=0,mpositiontaking=0,spositiontaking=0,alivepositiontaking=0,mlivepositiontaking=0,slivepositiontaking=0,autopositiontaking=0,autolivepositiontaking=0,isautopositiontaking=0,isautolivepositiontaking=0,sdiscount = 0,playerdiscount = 0,discount =0,adiscount=0,groupa = 0,groupb = 0,groupc = 0,groupd = 0,groupe = 0,groupf = 0
 where sporttype = 151
	and custid IN
	(	select custid from custinfo with (nolock)
		where srecommend = 836212

	)
update custinfo set maxpermatch151 = 600,
                    disablehorseracing = 0
where srecommend = 836212