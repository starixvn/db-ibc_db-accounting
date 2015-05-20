 -- Update PT according to email "Super LC PT Update for 789Y site - Miss Out !"
-- Super_list_under_headline_ETUS_(Latest_Update)_(27-Mar) - CheckList (1st Apr)


-------------------STEP #1 ---------------------

------- ExecRep to correct the Min Max PT according to Max Super PT -------
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@srecommend int
AS
BEGIN

--IF @@SERVERNAME in ('DB052', 'DB053', 'DB054') RETURN

IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('CustSettingGame','CustOverrideGame','custinfo') AND type = 'U') <> 3
		RETURN

declare @mpos smallmoney, @apos smallmoney, @spos smallmoney, @mapos1 smallmoney, @mapos2 smallmoney, @mapos smallmoney, @maxspos smallmoney, @maxmapos smallmoney

----------------------------------------------------------------------------
--s1=min(s1,s4-m3) if i=0 & syncLC = 1
UPDATE cs
SET cs.spositiontaking = scs.spositiontaking - mcs.mpositiontaking
FROM CustSettingGame cs 
INNER JOIN CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = ci.mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype
INNER JOIN CustSettingGame scs WITH(NOLOCK) ON scs.custid = @srecommend AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype
WHERE ci.srecommend = @srecommend AND roleid = 1 AND ci.SyncLiveCasino = 1
	AND cs.sporttype = 162 AND cs.bettype = 1101
	AND (mcs.isautopositiontaking = 0 OR cs.isautopositiontaking = 0) AND scs.spositiontaking - mcs.mpositiontaking < cs.spositiontaking
	

----------------------------------------------------------------------------
--check agent min
--a1=max(a1,n2)
--m1=min(m3-n2,m1)
UPDATE cs
SET cs.apositiontaking = aco.minpositiontaking,
	cs.mpositiontaking = CASE WHEN cs.mpositiontaking + aco.minpositiontaking > mcs.mpositiontaking THEN mcs.mpositiontaking - aco.minpositiontaking ELSE cs.mpositiontaking END
FROM CustSettingGame cs
	INNER JOIN CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
	INNER JOIN CustOverrideGame aco WITH(NOLOCK) ON aco.custid = ci.recommend AND aco.sporttype = cs.sporttype AND aco.bettype = cs.bettype
	INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = ci.mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype
WHERE ci.srecommend = @srecommend AND ci.roleid = 1 AND ci.SyncLiveCasino = 1
	AND cs.sporttype = 162 AND cs.bettype = 1101
	AND cs.apositiontaking < aco.minpositiontaking


--Recal AUTO MPT m1=min(m3-a1,u2)
-------------------------------------------------------------------------------------
UPDATE cs
SET cs.mpositiontaking = CASE WHEN mcs.mpositiontaking - cs.apositiontaking > CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END
				THEN CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END
				ELSE mcs.mpositiontaking - cs.apositiontaking END		
FROM CustSettingGame cs WITH(NOLOCK)
	INNER JOIN CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
	INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = ci.mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype
	INNER JOIN CustSettingGame acs WITH(NOLOCK) ON acs.custid = ci.recommend AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype
WHERE ci.srecommend = @srecommend AND ci.roleid = 1 AND ci.SyncLiveCasino = 1
	AND cs.sporttype = 162 AND cs.bettype = 1101
	AND (cs.isautompositiontaking = 1 OR acs.isautompositiontaking = 1)
	
	
--check master min
--m1=max(m1,n3-a1)
UPDATE cs
SET cs.mpositiontaking =CASE WHEN cs.mpositiontaking + cs.apositiontaking < mco.minpositiontaking THEN mco.minpositiontaking - cs.apositiontaking ELSE cs.mpositiontaking END
FROM CustSettingGame cs
	INNER JOIN CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid 
	INNER JOIN CustOverrideGame mco WITH(NOLOCK) ON mco.custid = ci.mrecommend AND mco.sporttype = cs.sporttype AND mco.bettype = cs.bettype
WHERE ci.srecommend = @srecommend AND ci.roleid = 1 AND ci.SyncLiveCasino = 1
	AND cs.sporttype = 162 AND cs.bettype = 1101 


----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--recal autopos
UPDATE cs
SET cs.spositiontaking = CASE WHEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking > CASE WHEN cs.isautopositiontaking = 1 THEN cs.autopositiontaking ELSE mcs.autopositiontaking END THEN
							CASE WHEN cs.isautopositiontaking = 1 THEN cs.autopositiontaking ELSE mcs.autopositiontaking END 
							ELSE scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking END
FROM CustSettingGame cs
	INNER JOIN CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid 
	INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = ci.mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
	INNER JOIN CustSettingGame scs WITH(NOLOCK) ON scs.custid = @srecommend AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype 
WHERE ci.srecommend = @srecommend AND ci.roleid = 1 AND ci.SyncLiveCasino = 1
	AND cs.sporttype = 162 AND cs.bettype = 1101 
	AND (cs.isautopositiontaking = 1 OR mcs.isautopositiontaking = 1)
	
----------------------------------------------------------------------------

--check super min
--s1=max(n4-m1-a1,s1)
UPDATE cs
SET 
	spositiontaking = sco.minpositiontaking-cs.mpositiontaking-cs.apositiontaking
FROM 
	CustSettingGame cs
	INNER JOIN CustInfo as ci with (NOLOCK) on cs.custid = ci.custid
	INNER JOIN CustOverrideGame as sco with (NOLOCK) on sco.custid = @srecommend  and sco.sporttype=cs.sporttype and sco.bettype=cs.bettype
WHERE ci.srecommend = @srecommend AND ci.roleid = 1 AND ci.SyncLiveCasino = 1
	AND cs.sporttype = 162 AND cs.bettype = 1101 
	AND cs.apositiontaking+cs.mpositiontaking+cs.spositiontaking<sco.minpositiontaking


--update s1,m1,a1 in case s1+m1+a1>s4
--s1=max(0,s4-m1-a1)
--@mapos1=iif(s1_new+m1+a1>s4,s4-s1_new,m1+a1)
--@maxmapos=min(m3,l3)
--@mapos2=min(@mapos1,@maxmapos)
--@mapos=max(@mapos2,n3)
--m1=max(0,@mapos-a1)
--a1=iif(m1_new+a1>@mapos,@mapos-m1_new,a1)
UPDATE cs
SET	@spos = CASE WHEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking <0 THEN 0 ELSE scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking END,
	cs.spositiontaking = @spos,
	@mapos1 = CASE WHEN @spos + cs.mpositiontaking + cs.apositiontaking > scs.spositiontaking THEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking ELSE cs.mpositiontaking + cs.apositiontaking END,
	@mapos2 = CASE WHEN @mapos1 > mcs.mpositiontaking THEN mcs.mpositiontaking ELSE @mapos1 END,
	@mapos  = CASE WHEN @mapos2 < mco.minpositiontaking THEN mco.minpositiontaking ELSE @mapos2 END,
	@mpos   = CASE WHEN @mapos - cs.apositiontaking < 0 THEN 0 ELSE @mapos - cs.apositiontaking END,
	cs.mpositiontaking = @mpos ,
	@apos   = CASE WHEN @mpos + cs.apositiontaking > @mapos THEN @mapos - @mpos ELSE cs.apositiontaking END,
	cs.apositiontaking = CASE WHEN @apos < aco.minpositiontaking THEN aco.minpositiontaking ELSE @apos END
FROM CustSettingGame cs
	INNER JOIN CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid 
	INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = ci.mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
	INNER JOIN CustOverrideGame mco WITH(NOLOCK) ON mco.custid = ci.mrecommend AND mco.sporttype = cs.sporttype AND mco.bettype = cs.bettype
	INNER JOIN CustOverrideGame aco WITH(NOLOCK) ON aco.custid = ci.recommend AND aco.sporttype = cs.sporttype AND aco.bettype = cs.bettype 
	INNER JOIN CustSettingGame scs WITH(NOLOCK) ON scs.custid = @srecommend AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype 
WHERE ci.srecommend = @srecommend AND ci.roleid = 1 AND ci.SyncLiveCasino = 1
	AND cs.sporttype = 162 AND cs.bettype = 1101
	AND cs.apositiontaking + cs.mpositiontaking + cs.spositiontaking > scs.spositiontaking

END
------- /ExecRep to correct the PT according to Max Super PT -------
-------------------/STEP #1 ---------------------

-------------------STEP #2 ---------------------
---------update max super PT for 51 supers
UPDATE custsettinggame WITH (rowlock,updlock)
SET spositiontaking = 0.7
WHERE custid in (	3379272	, --EY
					1935623	, --XY
					1935638	, --XZ
					3466791	, --XG
					3919562	, --SSA
					3919574	, --SSB
					1889065	, --EG
					2426467	, --EL
					2877058	, --EP
					3043749	, --ES
					4195794	, --XXG
					4195796	, --XXH
					6456973	, --EEA
					8594806	, --ET9
					3581460	, --XM
					4157382	, --XXD
					4157389	, --XXE
					3588788	, --XN
					1539339	, --EC
					3707684	, --XQ
					3707692	, --XR
					4079058	, --EJA
					6910609	, --EB1
					6910614	, --EB2
					6910618	, --EB3
					2063714	, --EI
					2063723	, --EJ
					3428663	, --XD
					6909008	, --EBB
					6909014	, --EBC
					6909021	, --EBD
					6909027	, --EBE
					6909067	, --EBF
					6909106	, --EBG
					6909137	, --EBH
					6909152	, --EBI
					6909165	, --EBJ
					1731862	, --EF
					3002015	, --ER
					3672278	, --XP
					4058361	, --SSC
					4058379	, --SSE
					3667252	, --XO
					595565	, --XX
					3318714	, --EU
					3318716	, --EV
					4629022	, --xxt
					5362731	, --EA5
					3397263	, --XA
					3397267	, --XB
					3397270	 --XC
)
-------------------/STEP #2 ---------------------

-------------------STEP #3 ---------------------
---------update min super PT for 38 supers
UPDATE custoverridegame WITH (rowlock,updlock)
SET minpositiontaking = 0.7
WHERE custid in (	4058361	, --SSC
					4058379	, --SSE
					1935623	, --XY
					1935638	, --XZ
					3581460	, --XM
					3588788	, --XN
					1539339	, --EC
					3318714	, --EU
					5362731	, --EA5
					3397263	, --XA
					3397267	, --XB
					3397270	, --XC
					595565	, --XX
					3002015	, --ER
					3043749	, --ES
					1889065	, --EG
					3667252	, --XO
					3672278	, --XP
					3318716	, --EV
					1731862	, --EF
					3919562	, --SSA
					3919574	, --SSB
					2426467	, --EL
					2063723	, --EJ
					3707692	, --XR
					4157382	, --XXD
					4157389	, --XXE
					4195794	, --XXG
					4195796	, --XXH
					3428663	, --XD
					3707684	, --XQ
					4629022	, --xxt
					2063714	, --EI
					2877058	, --EP
					4079058	, --EJA
					8594806 , --ET9
					3379272	,-- EY
					3466791	-- XG
				)	
				
-------------------/STEP #3 ---------------------

-------------------STEP #4 ---------------------
--------------Correct PT according to Min/Max super PT for 51 supers--------------

------------Select Command--------------------------
SELECT 
 '/* ' + CONVERT(VARCHAR(20),RowNo) + ' */ ' + sqltext
FROM (
SELECT ROW_NUMBER() OVER(ORDER BY c.custid ) AS RowNo,
'EXEC [Acc_ExecRep_09] @srecommend=' + cast(custid as varchar(12)) + ' dddGO' as sqltext
from customer c with (nolock) where username in ('ea5','ec','ef','eg','ei','ej','eja','el','ep','er','es','et9','eu','ev','ssa','ssb','ssc','sse','xa','xb','xc','xd','xm','xn','xo','xp','xq','xr','xx','xxd','xxe','xxg','xxh','xxt','xy','xz','EEA','EBB','EBC','EBD','EBE','EBF','EBG','EBH','EBI','EBJ','EB1','EB2','EB3','ey','xg'))a


--------------Correct PT according to Min/Max super PT for 51 supers--------------
/* 1 */ EXEC [Acc_ExecRep_09] @srecommend=595565 dddGO
/* 2 */ EXEC [Acc_ExecRep_09] @srecommend=1539339 dddGO
/* 3 */ EXEC [Acc_ExecRep_09] @srecommend=1731862 dddGO
/* 4 */ EXEC [Acc_ExecRep_09] @srecommend=1889065 dddGO
/* 5 */ EXEC [Acc_ExecRep_09] @srecommend=1935623 dddGO
/* 6 */ EXEC [Acc_ExecRep_09] @srecommend=1935638 dddGO
/* 7 */ EXEC [Acc_ExecRep_09] @srecommend=2063714 dddGO
/* 8 */ EXEC [Acc_ExecRep_09] @srecommend=2063723 dddGO
/* 9 */ EXEC [Acc_ExecRep_09] @srecommend=2426467 dddGO
/* 10 */ EXEC [Acc_ExecRep_09] @srecommend=2877058 dddGO
/* 11 */ EXEC [Acc_ExecRep_09] @srecommend=3002015 dddGO
/* 12 */ EXEC [Acc_ExecRep_09] @srecommend=3043749 dddGO
/* 13 */ EXEC [Acc_ExecRep_09] @srecommend=3318714 dddGO
/* 14 */ EXEC [Acc_ExecRep_09] @srecommend=3318716 dddGO
/* 15 */ EXEC [Acc_ExecRep_09] @srecommend=3379272 dddGO
/* 16 */ EXEC [Acc_ExecRep_09] @srecommend=3397263 dddGO
/* 17 */ EXEC [Acc_ExecRep_09] @srecommend=3397267 dddGO
/* 18 */ EXEC [Acc_ExecRep_09] @srecommend=3397270 dddGO
/* 19 */ EXEC [Acc_ExecRep_09] @srecommend=3428663 dddGO
/* 20 */ EXEC [Acc_ExecRep_09] @srecommend=3466791 dddGO
/* 21 */ EXEC [Acc_ExecRep_09] @srecommend=3581460 dddGO
/* 22 */ EXEC [Acc_ExecRep_09] @srecommend=3588788 dddGO
/* 23 */ EXEC [Acc_ExecRep_09] @srecommend=3667252 dddGO
/* 24 */ EXEC [Acc_ExecRep_09] @srecommend=3672278 dddGO
/* 25 */ EXEC [Acc_ExecRep_09] @srecommend=3707684 dddGO
/* 26 */ EXEC [Acc_ExecRep_09] @srecommend=3707692 dddGO
/* 27 */ EXEC [Acc_ExecRep_09] @srecommend=3919562 dddGO
/* 28 */ EXEC [Acc_ExecRep_09] @srecommend=3919574 dddGO
/* 29 */ EXEC [Acc_ExecRep_09] @srecommend=4058361 dddGO
/* 30 */ EXEC [Acc_ExecRep_09] @srecommend=4058379 dddGO
/* 31 */ EXEC [Acc_ExecRep_09] @srecommend=4079058 dddGO
/* 32 */ EXEC [Acc_ExecRep_09] @srecommend=4157382 dddGO
/* 33 */ EXEC [Acc_ExecRep_09] @srecommend=4157389 dddGO
/* 34 */ EXEC [Acc_ExecRep_09] @srecommend=4195794 dddGO
/* 35 */ EXEC [Acc_ExecRep_09] @srecommend=4195796 dddGO
/* 36 */ EXEC [Acc_ExecRep_09] @srecommend=4629022 dddGO
/* 37 */ EXEC [Acc_ExecRep_09] @srecommend=5362731 dddGO
/* 38 */ EXEC [Acc_ExecRep_09] @srecommend=6456973 dddGO
/* 39 */ EXEC [Acc_ExecRep_09] @srecommend=6909008 dddGO
/* 40 */ EXEC [Acc_ExecRep_09] @srecommend=6909014 dddGO
/* 41 */ EXEC [Acc_ExecRep_09] @srecommend=6909021 dddGO
/* 42 */ EXEC [Acc_ExecRep_09] @srecommend=6909027 dddGO
/* 43 */ EXEC [Acc_ExecRep_09] @srecommend=6909067 dddGO
/* 44 */ EXEC [Acc_ExecRep_09] @srecommend=6909106 dddGO
/* 45 */ EXEC [Acc_ExecRep_09] @srecommend=6909137 dddGO
/* 46 */ EXEC [Acc_ExecRep_09] @srecommend=6909152 dddGO
/* 47 */ EXEC [Acc_ExecRep_09] @srecommend=6909165 dddGO
/* 48 */ EXEC [Acc_ExecRep_09] @srecommend=6910609 dddGO
/* 49 */ EXEC [Acc_ExecRep_09] @srecommend=6910614 dddGO
/* 50 */ EXEC [Acc_ExecRep_09] @srecommend=6910618 dddGO
/* 51 */ EXEC [Acc_ExecRep_09] @srecommend=8594806 dddGO
-------------------/STEP #4 ---------------------
