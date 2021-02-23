DBA_GETPT 'S56HFF01331'

select ci.username, cs.* from custsetting cs with (nolock) 
	inner join custinfo ci with (nolock) on cs.custid = ci.custid
where spositiontaking + mpositiontaking + apositiontaking > 1
and bettype = 1 and sporttype = 1
and ci.roleid = 1
---------------
insert into _invalid_bets
select c.custid,
	c.username as memberName,	
	a.custid as recommend,
	a.username as agentName,
	m.custid as mrecommend,	
	m.username as masterName,
	s.custid as srecommend,		
	s.username as superName,
	b.apositiontaking, b.mpositiontaking, b.spositiontaking, cs.spositiontaking maxSpositiontaking,
transid, transdate, stake, status,winlostdate,1
from bettrans b with (nolock)
	inner join custsetting cs with (nolock) on b.srecommend = cs.custid and cs.sporttype = 1 and cs.bettype = 1	
	inner join custinfo c (nolock) on c.custid = b.custid
	inner join custinfo a with (nolock) on b.recommend = a.custid
	inner join custinfo m with (nolock) on b.mrecommend = m.custid
	inner join custinfo s with (nolock) on b.srecommend = s.custid
where 
	b.spositiontaking + b.mpositiontaking + b.apositiontaking >  cs.spositiontaking
	--and winlostdate between '2008-11-19' and '2008-11-30' 

-----------
select b.*
from bettrans14 b with (nolock)	
	inner join custsetting cs with (nolock) on b.srecommend = cs.custid and cs.sporttype = 1 and cs.bettype = 1
where  b.spositiontaking + b.mpositiontaking + b.apositiontaking > cs.spositiontaking
----------
select c.custid,
	c.username as memberName,	
	a.custid as recommend,
	a.username as agentName,
	m.custid as mrecommend,	
	m.username as masterName,
	s.custid as srecommend,		
	s.username as superName,
	cs.apositiontaking, cs.mpositiontaking, cs.spositiontaking, scs.spositiontaking maxSpositiontaking, cs.bettype, cs.sporttype
from custinfo c with (nolock)
	inner join custsetting cs with (nolock) on c.custid = cs.custid
	inner join custsetting scs with (nolock) on c.srecommend = scs.custid 
	inner join custinfo a with (nolock) on c.recommend = a.custid
	inner join custinfo m with (nolock) on c.mrecommend = m.custid
	inner join custinfo s with (nolock) on c.srecommend = s.custid  
where 
	cs.sporttype = scs.sporttype and cs.bettype = scs.bettype and
	cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking >  scs.spositiontaking
	and cs.sporttype < 100
and c.mrecommend in (68287, 198321, 283621, 343715, 406094, 406245, 412540, 450679, 461783, 461794, 461798, 463432, 567619, 567621, 753665, 771946, 781262, 812541, 829702, 835786, 836228, 836471, 838197, 838779, 839284, 839288, 839289, 846678, 866082, 867728, 878778, 889117, 889864, 900917, 900936, 918101, 920883, 935244, 939072, 945164, 945628, 951849, 971270, 971272, 976111, 976112, 976114, 976115, 976116, 976117, 976118, 984291, 984774, 988180, 989485, 991583, 994101, 994103, 994104, 996276, 999276, 999816, 1001047, 1002631, 1005674, 1007216, 1009643, 1009724, 1010367, 1012060, 1012343, 1012455, 1013167, 1013174, 1013177, 1013181, 1014406, 1020495, 1020696, 1027142, 1028954, 1031561, 1035154, 1037845, 1037857, 1041055, 1044773, 1047399, 1047877, 1050224, 1054028, 1056433, 1069659, 1080535, 1084007, 1087679, 1094037, 1107361, 1111964, 1117817, 1118041, 1118166, 1124510, 1126497, 1127130, 1133997, 1138157, 1140919, 1143254, 1143459, 1146951, 1151551, 1153238, 1153937, 1153967, 1153979, 1153981, 1158283, 1160482, 1163364, 1169926, 1172316, 1174325, 1175923, 1175981, 1175986, 1175991, 1175995, 1176491, 1176695, 1177727, 1178293, 1178343, 1178643, 1179136, 1179164, 1179194, 1180345, 1180443, 1181050, 1181052, 1181564, 1181921, 1181940, 1182389, 1182495, 1182615, 1183085, 1183237, 1183254, 1183892, 1184277, 1185861, 1185941, 1185944, 1185948, 1186191, 1186194, 1186498, 1187172, 1187592, 1188714, 1190109, 1191396, 1193713, 1193919, 1195538, 1196394, 1197281, 1197383, 1198223, 1199957, 1201072, 1201187, 1201286, 1201598, 1202208, 1202219, 1203538, 1203831, 1203926, 1204243, 1204647, 1204805, 1205034, 1205410, 1206517, 1207380, 1207452, 1208089, 1208188, 1209215, 1209459, 1209831, 1209906, 1210692, 1210745, 1210777, 1210952, 1211624, 1212718, 1212805, 1212867, 1213429, 1213617, 1214085, 1214088, 1214402, 1214717, 1214812, 1215765, 1215775, 1217399, 1217756, 1218725, 1218727, 1219011, 1219034, 1220238, 1220937, 1221065, 1221117, 1221149, 1221550, 1222494, 1222739)

-----------------
insert into _invalid_bets
select
	c.username as memberName,		
	a.username as agentName,	
	m.username as masterName,		
	s.username as superName, 1, cs.spositiontaking as maxsupt, 
	b.transid, b.transdate, b.stake, b.status, b.winlostdate, b.custid, b.oddsid, b.hdp1, b.hdp2, b.odds, b.winlost, b.awinlost, b.
                      mwinlost, b.playercomm, b.comm, b.acomm, b.apositiontaking, b.mpositiontaking, b.tpositiontaking,b.playerdiscount, b.discount, b.adiscount, b.livehomescore, b.
                      liveawayscore, b.liveindicator, b.betteam, b.creator, b.refno, b.comstatus, b.betfrom, b.betcheck, b.checktime, b.oddsspread, b.actualrate, b.matchid, b.recommend, b.
                      mrecommend, b.ruben, b.betid, b.statuswinlost, b.modds, b.bettype, b.betdaqid, b.actual_stake, b.currency, b.ip, b.transdesc, b.sdiscount, b.scomm, b.spositiontaking, b.
                      swinlost, b.srecommend, b.virtualrate


from bettrans b with (nolock)
	inner join custsetting cs with (nolock) on b.srecommend = cs.custid and cs.sporttype = 1 and cs.bettype = 1	
	inner join custinfo c (nolock) on c.custid = b.custid
	inner join custinfo a with (nolock) on b.recommend = a.custid
	inner join custinfo m with (nolock) on b.mrecommend = m.custid
	inner join custinfo s with (nolock) on b.srecommend = s.custid
where 
	b.spositiontaking + b.mpositiontaking + b.apositiontaking >  cs.spositiontaking
	--and winlostdate between '2008-11-19' and '2008-11-30' 

-----------
UPDATE dbo._invalid_bets with (ROWLOCK, UPDLOCK) SET A_SPositiontaking = maxsupt - mpositiontaking - apositiontaking

-----------

UPDATE dbo._invalid_bets with (ROWLOCK, UPDLOCK) SET
	A_sWinLost = CASE
		WHEN modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -A_spositiontaking
		WHEN modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -A_spositiontaking * 0.5
		WHEN modds =  0    	THEN 0
		WHEN modds = -0.25 	THEN actual_stake * A_spositiontaking * 0.5
		WHEN modds < -0.25 	THEN actual_stake * A_spositiontaking
		END,

	
	A_sComm = CASE
		WHEN modds >  0.25 	THEN sdiscount * stake * (1-(A_spositiontaking+mpositiontaking+apositiontaking))
		WHEN modds =  0.25 	THEN sdiscount * stake * (1-(A_spositiontaking+mpositiontaking+apositiontaking)) * 0.5
		WHEN modds =  0    	THEN 0
		WHEN modds = -0.25 	THEN sdiscount * stake * (1-(A_spositiontaking+mpositiontaking+apositiontaking)) * 0.5
		WHEN modds < -0.25 	THEN sdiscount * stake * (1-(A_spositiontaking+mpositiontaking+apositiontaking))
		END
	
	WHERE [status] NOT IN (N'VOID', N'REJECT')
