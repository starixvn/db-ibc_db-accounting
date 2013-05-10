 /************step1**************/
--update Min PT = max PT = 0.9
UPDATE co WITH(ROWLOCK,UPDLOCK)
SET co.minpositiontaking = cs.spositiontaking
FROM CustOverrideGame co 
INNER JOIN CustSettingGame cs WITH (nolock) ON co.CustID=cs.CustID AND cs.Sporttype=co.Sporttype 
and cs.Bettype=co.Bettype
WHERE CO.custid IN (595565,--XX
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

/************step1**************/



/************step2**************/
/*595565 ,--XX (count=199,462)
1539339 ,--EC (count=333,772)
1889065,--EG (count=55,886)
2063714,--EI (count=8,617)
2426467,--EL (count=1,266,353)   MORE THAN 1.2 MILLION ACCOUNTS
2877058,--EP (count=10,114)
3318714,--EU (count=10,133)
3397270,--XC (count=6,158)
3428663,--XD (count=16,523)
3466791,--XG (count=8,265)
3919562,--SSA (count=6,043)*/

EXEC [Acc_ExecRep_09] @srecommend = xxyy


-- Update Correct Min for downline by Excep-rep
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@srecommend int
AS
BEGIN

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

/************step2**************/

