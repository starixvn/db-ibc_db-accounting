-- =============================================
-- Script Template
-- =============================================
--so, this clear transfer, must made at 4 digit value
--u mean put any special word in "transdesc" for "Delete Account" transfer transaction.


select c.username, c.custid, c.currency, c.roleid, c.srecommend, c.mrecommend, c.recommend, c.closed,
	count(transid) as bettrans
into Cust_Delete_Account
from custinfo c (nolock)
	left join bettrans b (nolock) on c.custid = b.custid
where c.username in (
'IS','JTM','JTR','S11AR','S11HH','S12RM','S18RUP','S1NT','S22R','S52ARM','S56RMB','S85RMB','S86ATB','S86BTB','S86M','S86TB','S93RMB','SATH','SB1R','SB5R','SBKR','SBKRMB','SDSD','shhkk','SHRM','SSTM','MHU','KH01','M13HK','M188HK','M39HK','M62AHK','M62BHK','M62CHK','M62DHK','M62HK','M69AHK','M69BHK','M69CHK','M69DHK','M69HK','M73AHK','M73BHK','M73HK','M818H','M86HK','M9AH','M9FH','M9H','M9HK','M9MH','M9OH','MD1H','MGHK','MMAHK','MP1HK','MSKHK','MST1HK','MSTHK','MSWHK','MVHK','MWHK','MYAHK','S28HK','M1NT','BEE','MENT','119','BEETEST','fong','KM04','M21RM','M22RM','M32ARM','M32RM','M37ARM','M37BRM','M37CRM','M37DRM','M37RM','M46ARM','M50ARM','M50RM','M55ARM','M55BRM','M55CRM','M55DRM','M55ERM','M6JM','M73ARM','M73BRM','M73CRM','M73DRM','M73ERM','M73RM','M88ARM','M88BRM','M88CRM','M88DRM','M88ERM','M90RM','MALRM','MASRM','MB1RM','MB2RM','MCARM','MGARM','MGBRM','MGCRM','MGDRM','MGSM','MHORM','MKARM','MLCRM','MLRM','MOARM','MRCRM','MTFRM','MYARM','SP01','SP02','SP03','SP04','SP05','SP901','SP902','KR102','KR107','KR108','KR11','KR113','KR114','KR115','KR116','KR121','KR125','KR128','KR132','KR134','KR135','KR137','KR142','KR148','KR156','KR157','KR158','KR159','KR160','KR18','KR22','KR27','KR30','KR37','KR40','KR43','KR47','KR48','KR54','KR58','KR61','KR79','KR89','KR96','M13ARMB','M13RMB','M18RMB','M1R','M22RMB','M23RMB','M29RMB','M30ARMB','M30RMB','M311RMB','M3BRMB','M3ZRMB','M46ARMB','M46BRMB','M46CRMB','M46RMB','M47ARMB','M47BRMB','M56HRMB','M56IRMB','M56JRMB','M56KRMB','M56R','M58ARMB','M63ARMB','M63BRMB','M63CRMB','M63DRMB','M63RMB','M65RMB','M67RMB','M77ARMB','M77BRMB','M818RMB','M85R','M88ARMB','M88BRMB','M88CRMB','M88DRMB','M88R','M9O1C','M9P1C','M9QC','M9RMB','M9X1C','MFRMB','mharmb','MHBRMB','MHCRMB','MHDRMB','MHERMB','MHFRMB','MHGRMB','MHHRMB','MHIRMB','MHJRMB','MHKRMB','MHLR','MHLRMB','MHRMB','MJ1RMB','MKARMB','MKERMB','MKKRMB','MKLRMB','MLCARMB','MLCRMB','MLSRMB','MPTRMB','MRMB2','MSW1RMB','MYARMB','PARMB','PPRMB','S33R22','S33R23','S33R25','S33R27','S33R29','S33R30','M5US','M7US','M90US','mahk','MBSA','MMYUS','005AHK','005HK','0082HK','033HK','1148HK','1188HK','1212HK','13KHK','1999AHK','1999BHK','1999HK','2525HK','267HK','3030HK','3321HK','3322HK','333AHK','3366HK','337BHK','3389HK','3399HK','3939BHK','3S100','5277HK','6018HK','6363HK','665AHK','668HK','760BHK','780COM','8288HK','852HK','8633HK','8666HK','ALHK','BOBOHK','BYHK','CASHHK','GS88','KLHK','LJHK','LMHK','OHK','SB1','sb181','SB2','SWHK','WAHK','0085RM','1139RM','1169RM','1188RM','188COM','2055ARM','2055BRM','2055RM','216COM','222ARM','2577RM','2600RM','3389RM','3466RM','359IRM','4566RM','5503ARM','5503RM','60INDOBET','8666IRM','8803ARM','8803BRM','8803CRM','8803DRM','8803ERM','8803RM','8818RM','888RM','9600RM','98WIN','ALRM','AMRM','APRM','ATRM','AYARM','AYFRM','aywrm','AYYRM','BNRM','CRM','FRM','GRM','KKKRM','LCRM','LRM','MRM01','PQRM','RCRM','S195.COM','SORM','SPRM','SS085','SS288','star88','STIRM','SWARM','SWBRM','SWCRM','SWRM','TRM','WARM','WBRM','WCRM','WDRM','YABRM','YACRM','YADRM','YAFRM','YAGRM','YAHRM','YAIRM','YLRM','0082RMB','1195ARMB','1195BRMB','1195CRMB','1195DRMB','1195RMB','195IRMB','1999RMB','290RMB','291RMB','3188RMB','3321ARMB','3321BRMB','3321CRMB','3321DRMB','3321RMB','3399RMB','3688RMB','6599RMB','659IRMB','8288RMB','828ARMB','92irmb','9933RMB','aaa660','banhk','CITY909','FW618','KARMB','kdb168','KLRMB','KRMB','LMRMB','OTSMC','SB3SMC','WKRMB','YARMB','1115SD','1117sd','1137SD','1146SD','2000SD','2005SD','270ASD','5288ASD','5501SD','5503SD','5531SD','6668SD','69SD','888SD','ATSD','CSD','DLSD','ERSD','FRANSD','FSD','HOSD','isb3','LCSD','sansd','SFSD','SSD','TOSD','YYYUS','YKIUS','WBB','VVVUS','VTUS','VT2US','TTTUS','PPPUS','OKUS','NNNUS','MANUS','LOVEUS','KENTUS','HHHUS','GGGUS','EKUS','CHOUS','CAMUS','BOUS','BBBUS','AKUS','700US','302US'
)
group by c.username, c.custid, c.currency, c.roleid, c.srecommend, c.mrecommend, c.recommend, c.closed
order by c.custid 

--------------------------------------
SELECT
	custid,username, e.actualrate, e.currency,
	IsNull(bal,0) AS Balance,
	IsNull(bal,0)*e.actualrate AS BaseBalance
FROM 
	Cust_Delete_Account AS c with (nolock)
	LEFT OUTER JOIN (
			SELECT 
				srecommend,
				IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
				+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
				+ IsNull(sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end),0)
				+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end),0) AS bal 
			FROM bettrans with (nolock) 
			GROUP BY bettrans.srecommend
			) as  bal ON c.custid = bal.srecommend
INNER JOIN exchange as e with (nolock) ON c.currency = e.exchangeid
WHERE c.roleid = 4

---------------------------
select top 10 'EXEC dbo.DBA_ArchiveAccount_ClearBalance @AccName = '''+username+''', @UserID = 360418'  from cust_delete_account order by roleid desc, bettrans desc
--------------------------
select c.username, count(*)
from cust_delete_account c (nolock)
	inner join bettrans b (nolock) on c.custid = b.custid
where c.NotDelete = 0
group by c.username
order by count(*) desc

Update cust_Delete_account set NotDelete = 1 where custid = 10726

Delete from bettrans where recommend = 10726 and creator = 360418

DBA_GETPT '195IRMB'

select * from bettrans(nolock) where recommend = 10726 and creator <> 360418 and bettype > 100