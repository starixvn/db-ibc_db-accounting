-- Rule M3 < M2 + A2 (IM2 = 0) 
-- correct M688K2211 
/*
UPDATE custsetting3rd WITH (UPDLOCK,ROWLOCK)
SET apositiontaking=0, -- 0.7
mpositiontaking=0.7 --0.00
where custid=972594
and bettype = 1201 and sporttype= 180   
*/


-- M3 < N3  
-- correct m3=n3, s3= (is3=1)? 0 : s4-m3
/*
update cs WITH (UPDLOCK,ROWLOCK)
set mpositiontaking = co.minpositiontaking, 
	spositiontaking= case when cs.isautopositiontaking=1 THEN 0 else scs.spositiontaking - cs.mpositiontaking end 
from custinfo  ci (nolock)
	JOIN dbo.CustSetting3rd cs ON cs.custid=ci.custid
    JOIN dbo.custOverride3rd co WITH (NOLOCK) ON co.custid=ci.custid and co.sporttype=cs.sporttype and co.bettype=cs.bettype
    JOIN dbo.CustSetting3rd scs WITH (NOLOCK) ON scs.custid=ci.srecommend and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
where ci.custid in (
				423074,
				614993,
				1607963,
				640117,
				1587333,
				1587335,
				1587339,
				1587346,
				1587352,
				2377991,
				1596664,
				1862782,
				690112,
				597212)
	and cs.bettype = 1201 and cs.sporttype= 180   
	--and cs.bettype = 81 and cs.sporttype= 161   
*/

-- S4 < S3 + M3 (IS3 = 0)
-- correct s3=s4-m3
/*
update cs WITH (UPDLOCK,ROWLOCK)	
SET spositiontaking = scs.spositiontaking - cs.mpositiontaking
from custinfo  ci (nolock)
	JOIN dbo.CustSetting3rd cs ON cs.custid=ci.custid
    JOIN dbo.custOverride3rd co WITH (NOLOCK) ON co.custid=ci.custid and co.sporttype=cs.sporttype and co.bettype=cs.bettype
    JOIN dbo.CustSetting3rd scs WITH (NOLOCK) ON scs.custid=ci.srecommend and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
where ci.custid in (
					119927	,
					150089	,
					92131	,
					117405	,
					215901	,
					15003	
				)
	and cs.bettype = 1201 and cs.sporttype= 180  
*/	

/*
-- A2 < N2
--correct a2=n2, m2= (im=1)?0:m3-n2,  um=(im=1)?m3:0
update cs WITH (UPDLOCK,ROWLOCK)
set apositiontaking = co.minpositiontaking, 
	mpositiontaking= case when cs.isautopositiontaking=1 THEN 0 else mcs.mpositiontaking - co.minpositiontaking end,
	autompositiontaking= case when cs.isautopositiontaking=1 THEN mcs.mpositiontaking else 0 end 
from custinfo  ci (nolock)
	JOIN dbo.CustSetting3rd cs ON cs.custid=ci.custid
    JOIN dbo.custOverride3rd co WITH (NOLOCK) ON co.custid=ci.custid and co.sporttype=cs.sporttype and co.bettype=cs.bettype
    JOIN dbo.CustSetting3rd mcs WITH (NOLOCK) ON mcs.custid=ci.mrecommend and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
where ci.custid in (
			615356, 616822,	618106,	618112,	645424,	621074,	622327,	2418800,3321811,329415,
			2500418, 2500511, 2501950, 2502007, 607844, 681702, 683340, 683383, 684336,
			357993,	359778,	692862,	1593913,1831582,1588155,1588368,341011,	341013,
			341014,	689151,	691038,	691039,	2101461,2511522,3005991,317969, 597214, 597239,
			597248,	597249,	597363,	597365,	597366,	597370,	597372, 647019,670393, 675220,
			935779,	2387083,2256497,657886,	1862810,2379097
		)
	and cs.bettype = 1201 and cs.sporttype= 180   
*/

/*
-- S1 < 0 || M1 < 0 || A1 < 0
-- S1 + M1 + A1 > 0.9   
-- all of them have m2<0
-- correct: set m1=m2
-- run SP tp correct PT constraints

update cs WITH (UPDLOCK,ROWLOCK)	
SET mpositiontaking = acs.mpositiontaking
from custinfo  ci (nolock)
	JOIN dbo.CustSetting3rd cs ON cs.custid=ci.custid    
    JOIN dbo.CustSetting3rd acs WITH (NOLOCK) ON acs.custid=ci.recommend and acs.sporttype=cs.sporttype and acs.bettype=cs.bettype
where ci.custid in (
					4249266	,
					7422846	,
					7459822	,
					7312195	,
					7313401	,
					7313705	,
					7387506	,
					7408870	,
					2522974	,
					7490773	,
					7774430	
				)
	and cs.bettype = 1201 and cs.sporttype= 180  
	
EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 4249266, 
				@recommend = 2510149, @mrecommend = 2269970, @srecommend = 882346

EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 2522974, 
				@recommend = 2510149, @mrecommend = 2269970, @srecommend = 882346				
				
EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 7422846, 
				@recommend = 6105582, @mrecommend = 2773017, @srecommend = 1517030

EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 7459822, 
				@recommend = 7291625, @mrecommend = 4405084, @srecommend = 3934718		

EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 7312195, 
				@recommend = 7291625, @mrecommend = 4405084, @srecommend = 3934718				

EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 7313401, 
				@recommend = 7291625, @mrecommend = 4405084, @srecommend = 3934718
				
EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 7313705, 
				@recommend = 7291625, @mrecommend = 4405084, @srecommend = 3934718				

EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 7387506, 
				@recommend = 7291625, @mrecommend = 4405084, @srecommend = 3934718								

EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 7408870, 
				@recommend = 7291625, @mrecommend = 4405084, @srecommend = 3934718												

EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 7490773, 
				@recommend = 7291625, @mrecommend = 4405084, @srecommend = 3934718		

EXEC dbo.Acc_CustomerUpdMemberVS_MinMaxPositiontaking 
				@sporttype = 180, @bettype = 1201, @custid = 7774430, 
				@recommend = 7291625, @mrecommend = 4405084, @srecommend = 3934718		
*/
