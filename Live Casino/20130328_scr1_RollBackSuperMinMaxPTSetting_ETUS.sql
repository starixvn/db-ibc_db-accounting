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



--------------STEP #2 (update max pt=0.7 for 34 supers) ----------------

UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.7
WHERE custid IN (300958	,--SQ
595561	,--SC
1113450	,--SM
1317452	,--SG
1505137	,--EA
1505140	,--EB
1667537	,--EE
1698753	,--SH
1935648	,--EH
2426461	,--EK
2426472	,--EM
2571383	,--EN
2822583	,--EO
3002011	,--EQ
3043753	,--ET
3370732	,--EW
3379262	,--EX
3448871	,--XE
3448873	,--XF
3518530	,--XJ
3518536	,--XK
3518540	,--XL
3706024	,--XH
3759851	,--XS
3764956	,--XT
3967000	,--XXA
4113805	,--XXB
4113806	,--XXC
4190683	,--XXF
6197528	,--EAL
6909004	,--EBA
6910631	,--EB5
6910642	,--EB6
8104526	--EBL
)
--------------/STEP #2 (update max pt=0.7 for 34 supers) ----------------

--------------STEP #3 Correct PT according to Max super PT ----------------
/* 1 */ EXEC [Acc_ExecRep_09] @srecommend=300958
/* 2 */ EXEC [Acc_ExecRep_09] @srecommend=595561
/* 3 */ EXEC [Acc_ExecRep_09] @srecommend=1113450
/* 4 */ EXEC [Acc_ExecRep_09] @srecommend=1317452
/* 5 */ EXEC [Acc_ExecRep_09] @srecommend=1505137
/* 6 */ EXEC [Acc_ExecRep_09] @srecommend=1505140
/* 7 */ EXEC [Acc_ExecRep_09] @srecommend=1667537
/* 8 */ EXEC [Acc_ExecRep_09] @srecommend=1698753
/* 9 */ EXEC [Acc_ExecRep_09] @srecommend=1935648
/* 10 */ EXEC [Acc_ExecRep_09] @srecommend=2426461
/* 11 */ EXEC [Acc_ExecRep_09] @srecommend=2426472
/* 12 */ EXEC [Acc_ExecRep_09] @srecommend=2571383
/* 13 */ EXEC [Acc_ExecRep_09] @srecommend=2822583
/* 14 */ EXEC [Acc_ExecRep_09] @srecommend=3002011
/* 15 */ EXEC [Acc_ExecRep_09] @srecommend=3043753
/* 16 */ EXEC [Acc_ExecRep_09] @srecommend=3370732
/* 17 */ EXEC [Acc_ExecRep_09] @srecommend=3379262
/* 18 */ EXEC [Acc_ExecRep_09] @srecommend=3448871
/* 19 */ EXEC [Acc_ExecRep_09] @srecommend=3448873
/* 20 */ EXEC [Acc_ExecRep_09] @srecommend=3518530
/* 21 */ EXEC [Acc_ExecRep_09] @srecommend=3518536
/* 22 */ EXEC [Acc_ExecRep_09] @srecommend=3518540
/* 23 */ EXEC [Acc_ExecRep_09] @srecommend=3706024
/* 24 */ EXEC [Acc_ExecRep_09] @srecommend=3759851
/* 25 */ EXEC [Acc_ExecRep_09] @srecommend=3764956
/* 26 */ EXEC [Acc_ExecRep_09] @srecommend=3967000
/* 27 */ EXEC [Acc_ExecRep_09] @srecommend=4113805
/* 28 */ EXEC [Acc_ExecRep_09] @srecommend=4113806
/* 29 */ EXEC [Acc_ExecRep_09] @srecommend=4190683
/* 30 */ EXEC [Acc_ExecRep_09] @srecommend=6197528
/* 31 */ EXEC [Acc_ExecRep_09] @srecommend=6909004
/* 32 */ EXEC [Acc_ExecRep_09] @srecommend=6910631
/* 33 */ EXEC [Acc_ExecRep_09] @srecommend=6910642
/* 34 */ EXEC [Acc_ExecRep_09] @srecommend=8104526


-------------------select command -------------------
SELECT 
 '/* ' + CONVERT(VARCHAR(20),RowNo) + ' */ ' + sqltext
FROM (
SELECT ROW_NUMBER() OVER(ORDER BY c.custid ) AS RowNo,
'EXEC [Acc_ExecRep_09] @srecommend=' + cast(custid as varchar(12)) as sqltext
from custInfo c with (nolock)
WHERE c.custid IN (300958	,--SQ
595561	,--SC
1113450	,--SM
1317452	,--SG
1505137	,--EA
1505140	,--EB
1667537	,--EE
1698753	,--SH
1935648	,--EH
2426461	,--EK
2426472	,--EM
2571383	,--EN
2822583	,--EO
3002011	,--EQ
3043753	,--ET
3370732	,--EW
3379262	,--EX
3448871	,--XE
3448873	,--XF
3518530	,--XJ
3518536	,--XK
3518540	,--XL
3706024	,--XH
3759851	,--XS
3764956	,--XT
3967000	,--XXA
4113805	,--XXB
4113806	,--XXC
4190683	,--XXF
6197528	,--EAL
6909004	,--EBA
6910631	,--EB5
6910642	,--EB6
8104526	--EBL
))a

-------------------/select command -------------------
--------------/STEP #3 Correct PT according to Max super PT ----------------

--------------STEP #4 Rollback Max=Min PT = 0.7 for 38 supers --------------
create table #SuperIds (custid INT)
INSERT INTO #SuperIds
SELECT c.custid
FROM custinfo c WITH(NOLOCK)
WHERE custid IN (1731862,--EF
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
					8594806,--ET9
					595565,--XX
					1539339,--EC
					1889065,--EG
					2063714,--EI
					2426467,--EL
					2877058,--EP
					3318714,--EU
					3397270,--XC
					3428663,--XD
					3466791,--XG
					3919562--SSA	
				)				

------------Update Min Max PT = 0.7 for 38 supers
UPDATE custsettinggame WITH (rowlock,updlock)
SET spositiontaking = 0.7
WHERE custid in (SELECT custid FROM #SuperIds)

UPDATE custoverridegame WITH (rowlock,updlock)
SET minpositiontaking = 0.7
WHERE custid in (SELECT custid FROM #SuperIds)	

drop table #SuperIds
--------------/STEP #4 Rollback Max=Min PT = 0.7 for 38 supers --------------

--------------STEP #5 Correct PT according to Min/Max super PT --------------
/* 1 */ EXEC [Acc_ExecRep_09] @srecommend=595565
/* 2 */ EXEC [Acc_ExecRep_09] @srecommend=1539339
/* 3 */ EXEC [Acc_ExecRep_09] @srecommend=1731862
/* 4 */ EXEC [Acc_ExecRep_09] @srecommend=1889065
/* 5 */ EXEC [Acc_ExecRep_09] @srecommend=1935623
/* 6 */ EXEC [Acc_ExecRep_09] @srecommend=1935638
/* 7 */ EXEC [Acc_ExecRep_09] @srecommend=2063714
/* 8 */ EXEC [Acc_ExecRep_09] @srecommend=2063723
/* 9 */ EXEC [Acc_ExecRep_09] @srecommend=2426467
/* 10 */ EXEC [Acc_ExecRep_09] @srecommend=2877058
/* 11 */ EXEC [Acc_ExecRep_09] @srecommend=3002015
/* 12 */ EXEC [Acc_ExecRep_09] @srecommend=3043749
/* 13 */ EXEC [Acc_ExecRep_09] @srecommend=3318714
/* 14 */ EXEC [Acc_ExecRep_09] @srecommend=3318716
/* 15 */ EXEC [Acc_ExecRep_09] @srecommend=3379272
/* 16 */ EXEC [Acc_ExecRep_09] @srecommend=3397263
/* 17 */ EXEC [Acc_ExecRep_09] @srecommend=3397267
/* 18 */ EXEC [Acc_ExecRep_09] @srecommend=3397270
/* 19 */ EXEC [Acc_ExecRep_09] @srecommend=3428663
/* 20 */ EXEC [Acc_ExecRep_09] @srecommend=3466791
/* 21 */ EXEC [Acc_ExecRep_09] @srecommend=3581460
/* 22 */ EXEC [Acc_ExecRep_09] @srecommend=3588788
/* 23 */ EXEC [Acc_ExecRep_09] @srecommend=3667252
/* 24 */ EXEC [Acc_ExecRep_09] @srecommend=3672278
/* 25 */ EXEC [Acc_ExecRep_09] @srecommend=3707684
/* 26 */ EXEC [Acc_ExecRep_09] @srecommend=3707692
/* 27 */ EXEC [Acc_ExecRep_09] @srecommend=3919562
/* 28 */ EXEC [Acc_ExecRep_09] @srecommend=3919574
/* 29 */ EXEC [Acc_ExecRep_09] @srecommend=4058361
/* 30 */ EXEC [Acc_ExecRep_09] @srecommend=4058379
/* 31 */ EXEC [Acc_ExecRep_09] @srecommend=4079058
/* 32 */ EXEC [Acc_ExecRep_09] @srecommend=4157382
/* 33 */ EXEC [Acc_ExecRep_09] @srecommend=4157389
/* 34 */ EXEC [Acc_ExecRep_09] @srecommend=4195794
/* 35 */ EXEC [Acc_ExecRep_09] @srecommend=4195796
/* 36 */ EXEC [Acc_ExecRep_09] @srecommend=4629022
/* 37 */ EXEC [Acc_ExecRep_09] @srecommend=5362731
/* 38 */ EXEC [Acc_ExecRep_09] @srecommend=8594806

-------------------select command -------------------
SELECT 
 '/* ' + CONVERT(VARCHAR(20),RowNo) + ' */ ' + sqltext
FROM (
SELECT ROW_NUMBER() OVER(ORDER BY c.custid ) AS RowNo,
'EXEC [Acc_ExecRep_09] @srecommend=' + cast(custid as varchar(12)) as sqltext
from custInfo c with (nolock)
WHERE c.custid IN (SELECT custid FROM #SuperIds))a
-------------------/select command -------------------
--------------/STEP #5 Correct PT according to Min/Max super PT --------------
