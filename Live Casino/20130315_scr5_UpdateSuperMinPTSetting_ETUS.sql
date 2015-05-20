/*create table #SuperIDs_2 (custid int)
create table #SuperIDs (custid int)
insert into #SuperIDs
select custid from custinfo with (nolock) where username in ('ea','ea5','eal','eb','eb5','eb6','eba','ebl','ec','ee','ef','eg','eh','ei','ej','eja','ek','el','em','en','eo','ep','eq','er','es','et','et9','eu','ev','ew','ex','ey','sc','sg','sh','sm','sq','ssa','ssb','ssc','sse','xa','xb','xc','xd','xe','xf','xg','xh','xj','xk','xl','xm','xn','xo','xp','xq','xr','xs','xt','xx','xxa','xxb','xxc','xxd','xxe','xxf','xxg','xxh','xxt','xy','xz')

select cast(c.custid as varchar(30)) +',--' + username from custinfo c with (nolock)
inner join custsettinggame cg with (nolock) on c.custid=cg.custid
inner join custoverridegame co with (nolock) on cg.custid=co.custid
where cg.custid in (select custid from #SuperIDs)
and (cg.spositiontaking <> 0 and co.minpositiontaking<>0)*/

/***38 supers have about 1,955,623 downlines **/

/*update Min PT for 27 supers having not much downline*/


/* 1 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =1731862, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 2 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =1935623, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 3 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =1935638, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 4 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =2063723, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 5 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3002015, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 6 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3043749, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 7 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3318716, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 8 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3379272, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 9 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3397263, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 10 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3397267, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 11 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3581460, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 12 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3588788, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 13 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3667252, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 14 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3672278, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 15 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3707684, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 16 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3707692, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 17 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =3919574, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 18 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =4058361, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 19 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =4058379, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 20 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =4079058, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 21 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =4157382, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 22 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =4157389, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 23 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =4195794, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 24 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =4195796, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 25 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =4629022, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 26 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =5362731, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 
/* 27 */ DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) EXEC Acc_CustomerUpdSuperLiveCS_All @custid =8594806, @v162spositiontaking_1101 = 0.70, @v162spositiontaking_1101_min = 0.70, @v162discount_1101 = 0.00700000, @v162UpdatePositiontaking_1101 = 0, @v162UpdateMinPositiontaking_1101 = 1, @v162UpdateCommission_1101 = 0, @IP=N'127.0.0.1', @UserID = 5838421 /* dbaadmin */, @Language=N'E', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode,@ErrMsg  dddGO 



-------------------------select the command ------------------------
SELECT 
 '/* ' + CONVERT(VARCHAR(20),RowNo) + ' */ ' + sqltext
FROM (
SELECT 
	ROW_NUMBER() OVER(ORDER BY g.custid ) AS RowNo,
	'DECLARE @ErrCode VARCHAR(300), @ErrMsg NVARCHAR(4000) '
	+ 'EXEC Acc_CustomerUpdSuperLiveCS_All'
	+ ' @custid =' + CONVERT(VARCHAR(20),g.custid)
	+ ', @v162spositiontaking_1101 = ' + CONVERT(VARCHAR(20),g.spositiontaking)
	+ ', @v162spositiontaking_1101_min = ' + CONVERT(VARCHAR(20),g.spositiontaking)
	+ ', @v162discount_1101 = ' + CONVERT(VARCHAR(20),g.sdiscount)
	+ ', @v162UpdatePositiontaking_1101 = 0'
	+ ', @v162UpdateMinPositiontaking_1101 = 1'
	+ ', @v162UpdateCommission_1101 = 0'
	+ ', @IP=N''127.0.0.1'''
	+ ', @UserID = 5838421 /* dbaadmin */'
	+ ', @Language=N''E'''	
	+ ', @ErrCode = @ErrCode OUTPUT'
	+ ', @ErrMsg = @ErrMsg OUTPUT'
	+ ' SELECT @ErrCode,@ErrMsg '
	+ ' dddGO ' as sqltext
FROM CustSettingGame g WITH(NOLOCK)
	INNER JOIN CustOverrideGame og WITH(NOLOCK) ON g.custid = og.custid
WHERE g.spositiontaking <> og.minpositiontaking
AND	g.custid IN (	1731862,--EF
					1935623,--XY
					1935638,--XZ
					2063723,--EJ
					3002015,--ER
					3043749,--ES
					3318716,--EV
					3379272,--EY
					3397263,--XA
					3397267,--XB
					3581460,--XM
					3588788,--XN
					3667252,--XO
					3672278,--XP
					3707684,--XQ
					3707692,--XR
					3919574,--SSB
					4058361,--SSC
					4058379,--SSE
					4079058,--EJA
					4157382,--XXD
					4157389,--XXE
					4195794,--XXG
					4195796,--XXH
					4629022,--xxt
					5362731,--EA5
					8594806--ET9
				)
) a