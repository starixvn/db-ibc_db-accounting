--Script to update PT of Super Level with the same PT settings for all sport types, bet types, live
/*List of Updated Supers
	KAR: 726562
	KBR: 726571
	KCR: 726579
	KDR: 1164457
	KER: 1238537
	KH:  194355
	KR:  194356

--SAMPLE:
--=================================================
	Super Preset = 70%
	Auto Super Preset = 70%
--=================================================
--PAY ATTENTION TO HORSE RACING AND FINANCIAL BETTING.
*/

DECLARE @srecommend INT
SELECT @srecommend = 726562 --super ID here

--update super's max PT (s4) for whole line(company set):
	UPDATE custsetting WITH (ROWLOCK, UPDLOCK) 
	SET	spositiontaking = 0.7,
		slivepositiontaking = CASE WHEN sporttype = 1 AND bettype IN(1,3,7,8) THEN 0.7 ELSE 0 END
	WHERE custid = @srecommend AND sporttype NOT IN (151,201)

	--Recalculate s1 when update s4
	--u = (i3 or i1)?(u3 or u1)
	--s1 = min(s4-m1-a1, u)
	UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
	SET spositiontaking = CASE WHEN scs.spositiontaking-custsetting.mpositiontaking-custsetting.apositiontaking >
								(CASE WHEN custsetting.isautopositiontaking=1 
										THEN custsetting.autopositiontaking 
										ELSE mcs.autopositiontaking END) 
							THEN (CASE WHEN custsetting.isautopositiontaking=1 
										THEN custsetting.autopositiontaking ELSE mcs.autopositiontaking END) 
							ELSE scs.spositiontaking-custsetting.mpositiontaking-custsetting.apositiontaking END 
	FROM
		custsetting
		INNER JOIN custinfo AS c WITH (NOLOCK) ON custsetting.custid = c.custid
		INNER JOIN custsetting AS mcs WITH (NOLOCK) ON mcs.custid = c.mrecommend AND mcs.sporttype=custsetting.sporttype AND mcs.bettype=custsetting.bettype
		INNER JOIN custsetting AS scs WITH (NOLOCK) ON scs.custid = @srecommend AND scs.sporttype=custsetting.sporttype AND scs.bettype=custsetting.bettype
	WHERE
		c.srecommend = @srecommend
		AND c.roleid = 1
		AND (custsetting.isautopositiontaking=1 OR mcs.isautopositiontaking=1)
		AND custsetting.sporttype NOT IN (151,201)

	UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
	SET slivepositiontaking = CASE WHEN scs.slivepositiontaking-custsetting.mlivepositiontaking-custsetting.alivepositiontaking >
								(CASE WHEN custsetting.isautolivepositiontaking=1 THEN custsetting.autolivepositiontaking ELSE mcs.autolivepositiontaking END) THEN (CASE WHEN custsetting.isautolivepositiontaking=1 THEN custsetting.autolivepositiontaking ELSE mcs.autolivepositiontaking END) ELSE scs.slivepositiontaking-custsetting.mlivepositiontaking-custsetting.alivepositiontaking END 
	FROM
		custsetting
		INNER JOIN custinfo AS c WITH (NOLOCK) ON custsetting.custid = c.custid
		INNER JOIN custsetting AS mcs WITH (NOLOCK) ON mcs.custid = c.mrecommend AND mcs.sporttype=custsetting.sporttype AND mcs.bettype=custsetting.bettype
		INNER JOIN custsetting AS scs WITH (NOLOCK) ON scs.custid = @srecommend AND scs.sporttype=custsetting.sporttype AND scs.bettype=custsetting.bettype
	WHERE
		c.srecommend = @srecommend
		AND c.roleid = 1
		AND (custsetting.isautolivepositiontaking=1 OR mcs.isautolivepositiontaking=1)
		AND custsetting.sporttype NOT IN (151,201)

--update s4 = l4 and make sure that s1 + m1 + a1 <=l4
	EXEC dbo.Acc_CustoverrideUpd @custid = @srecommend,@minpositiontaking_1 = 0,@minpositiontaking_2 = 0,@minpositiontaking_3 = 0,@minpositiontaking_4 = 0,@minpositiontaking_5 = 0,@minpositiontaking_6 = 0,@minpositiontaking_7 = 0,@minpositiontaking_8 = 0,@minpositiontaking_9 = 0,@minpositiontaking_10 = 0,@minlivepositiontaking_1 = 0,@minlivepositiontaking_3 = 0,@minlivepositiontaking_7 = 0,@minlivepositiontaking_8 = 0,@minv2positiontaking_1 = 0,@minv2positiontaking_2 = 0,@minv2positiontaking_3 = 0,@minv2positiontaking_7 = 0,@minv2positiontaking_8 = 0,@minv2positiontaking_9 = 0,@minv2positiontaking_20 = 0,@minv3positiontaking_1 = 0,@minv3positiontaking_2 = 0,@minv3positiontaking_3 = 0,@minv3positiontaking_20 = 0,@minv5positiontaking_1 = 0,@minv5positiontaking_2 = 0,@minv5positiontaking_3 = 0,@minv5positiontaking_20 = 0,@minv8positiontaking_1 = 0,@minv8positiontaking_3 = 0,@minv8positiontaking_20 = 0,@minv10positiontaking_1 = 0,@minv10positiontaking_2 = 0,@minv10positiontaking_3 = 0,@minv10positiontaking_20 = 0,@minv11positiontaking_1 = 0,@minv11positiontaking_20 = 0,@minv99positiontaking_1 = 0,@minv99positiontaking_2 = 0,@minv99positiontaking_3 = 0,@minv99positiontaking_20 = 0,@maxpositiontaking_1 = 0.7,@maxpositiontaking_2 = 0.7,@maxpositiontaking_3 = 0.7,@maxpositiontaking_4 = 0.7,@maxpositiontaking_5 = 0.7,@maxpositiontaking_6 = 0.7,@maxpositiontaking_7 = 0.7,@maxpositiontaking_8 = 0.7,@maxpositiontaking_9 = 0.7,@maxpositiontaking_10 = 0.7,@maxlivepositiontaking_1 = 0.7,@maxlivepositiontaking_3 = 0.7,@maxlivepositiontaking_7 = 0.7,@maxlivepositiontaking_8 = 0.7,@maxv2positiontaking_1 = 0.7,@maxv2positiontaking_2 = 0.7,@maxv2positiontaking_3 = 0.7,@maxv2positiontaking_7 = 0.7,@maxv2positiontaking_8 = 0.7,@maxv2positiontaking_9 = 0.7,@maxv2positiontaking_20 = 0.7,@maxv3positiontaking_1 = 0.7,@maxv3positiontaking_2 = 0.7,@maxv3positiontaking_3 = 0.7,@maxv3positiontaking_20 = 0.7,@maxv5positiontaking_1 = 0.7,@maxv5positiontaking_2 = 0.7,@maxv5positiontaking_3 = 0.7,@maxv5positiontaking_20 = 0.7,@maxv8positiontaking_1 = 0.7,@maxv8positiontaking_3 = 0.7,@maxv8positiontaking_20 = 0.7,@maxv10positiontaking_1 = 0.7,@maxv10positiontaking_2 = 0.7,@maxv10positiontaking_3 = 0.7,@maxv10positiontaking_20 = 0.7,@maxv11positiontaking_1 = 0.7,@maxv11positiontaking_20 = 0.7,@maxv99positiontaking_1 = 0.7,@maxv99positiontaking_2 = 0.7,@maxv99positiontaking_3 = 0.7,@maxv99positiontaking_20 = 0.7,@CheckPermission = 0,@UpdateMinPos = 0,@UpdateMaxPos = 1,@UserID = 360418,@SubAccID = 0,@WriteLog = 0
--update s3, m3, u3
	declare @mrecommend int
	DECLARE @master TABLE (mrecommend int)
	insert into @master
	select mrecommend from custinfo (nolock) where srecommend = @srecommend and roleid = 3

	declare @cnt int
	startloop:

		SELECT TOP 1 @mrecommend = mrecommend FROM @master
		SELECT @cnt = @@ROWCOUNT	
		IF @cnt = 0 GOTO EndLoop

		EXEC dbo.Acc_CustomerUpdMaster_PositionTaking @custid = @mrecommend,@spositiontaking_1 = 0,@spositiontaking_2 = 0,@spositiontaking_3 = 0,@spositiontaking_4 = 0,@spositiontaking_5 = 0,@spositiontaking_6 = 0,@spositiontaking_7 = 0,@spositiontaking_8 = 0,@spositiontaking_9 = 0,@spositiontaking_10 = 0,@slivepositiontaking_1 = 0,@slivepositiontaking_3 = 0,@slivepositiontaking_7 = 0,@slivepositiontaking_8 = 0,@v2spositiontaking_1 = 0,@v2spositiontaking_2 = 0,@v2spositiontaking_3 = 0,@v2spositiontaking_7 = 0,@v2spositiontaking_8 = 0,@v2spositiontaking_9 = 0,@v2spositiontaking_20 = 0,@v3spositiontaking_1 = 0,@v3spositiontaking_2 = 0,@v3spositiontaking_3 = 0,@v3spositiontaking_20 = 0,@v5spositiontaking_1 = 0,@v5spositiontaking_2 = 0,@v5spositiontaking_3 = 0,@v5spositiontaking_20 = 0,@v8spositiontaking_1 = 0,@v8spositiontaking_3 = 0,@v8spositiontaking_20 = 0,@v10spositiontaking_1 = 0,@v10spositiontaking_2 = 0,@v10spositiontaking_3 = 0,@v10spositiontaking_20 = 0,@v11spositiontaking_1 = 0,@v11spositiontaking_20 = 0,@v99spositiontaking_1 = 0,@v99spositiontaking_2 = 0,@v99spositiontaking_3 = 0,@v99spositiontaking_20 = 0,@auto_spositiontaking_1 = 0.7,@auto_spositiontaking_2 = 0.7,@auto_spositiontaking_3 = 0.7,@auto_spositiontaking_4 = 0.7,@auto_spositiontaking_5 = 0.7,@auto_spositiontaking_6 = 0.7,@auto_spositiontaking_7 = 0.7,@auto_spositiontaking_8 = 0.7,@auto_spositiontaking_9 = 0.7,@auto_spositiontaking_10 = 0.7,@auto_slivepositiontaking_1 = 0.7,@auto_slivepositiontaking_3 = 0.7,@auto_slivepositiontaking_7 = 0.7,@auto_slivepositiontaking_8 = 0.7,@auto_v2spositiontaking_1 = 0.7,@auto_v2spositiontaking_2 = 0.7,@auto_v2spositiontaking_3 = 0.7,@auto_v2spositiontaking_7 = 0.7,@auto_v2spositiontaking_8 = 0.7,@auto_v2spositiontaking_9 = 0.7,@auto_v2spositiontaking_20 = 0.7,@auto_v3spositiontaking_1 = 0.7,@auto_v3spositiontaking_2 = 0.7,@auto_v3spositiontaking_3 = 0.7,@auto_v3spositiontaking_20 = 0.7,@auto_v5spositiontaking_1 = 0.7,@auto_v5spositiontaking_2 = 0.7,@auto_v5spositiontaking_3 = 0.7,@auto_v5spositiontaking_20 = 0.7,@auto_v8spositiontaking_1 = 0.7,@auto_v8spositiontaking_3 = 0.7,@auto_v8spositiontaking_20 = 0.7,@auto_v10spositiontaking_1 = 0.7,@auto_v10spositiontaking_2 = 0.7,@auto_v10spositiontaking_3 = 0.7,@auto_v10spositiontaking_20 = 0.7,@auto_v11spositiontaking_1 = 0.7,@auto_v11spositiontaking_20 = 0.7,@auto_v99spositiontaking_1 = 0.7,@auto_v99spositiontaking_2 = 0.7,@auto_v99spositiontaking_3 = 0.7,@auto_v99spositiontaking_20 = 0.7,@isauto_spositiontaking_1 = 1,@isauto_spositiontaking_2 = 1,@isauto_spositiontaking_3 = 1,@isauto_spositiontaking_4 = 1,@isauto_spositiontaking_5 = 1,@isauto_spositiontaking_6 = 1,@isauto_spositiontaking_7 = 1,@isauto_spositiontaking_8 = 1,@isauto_spositiontaking_9 = 1,@isauto_spositiontaking_10 = 1,@isauto_slivepositiontaking_1 = 1,@isauto_slivepositiontaking_3 = 1,@isauto_slivepositiontaking_7 = 1,@isauto_slivepositiontaking_8 = 1,@isauto_v2spositiontaking_1 = 1,@isauto_v2spositiontaking_2 = 1,@isauto_v2spositiontaking_3 = 1,@isauto_v2spositiontaking_7 = 1,@isauto_v2spositiontaking_8 = 1,@isauto_v2spositiontaking_9 = 1,@isauto_v2spositiontaking_20 = 1,@isauto_v3spositiontaking_1 = 1,@isauto_v3spositiontaking_2 = 1,@isauto_v3spositiontaking_3 = 1,@isauto_v3spositiontaking_20 = 1,@isauto_v5spositiontaking_1 = 1,@isauto_v5spositiontaking_2 = 1,@isauto_v5spositiontaking_3 = 1,@isauto_v5spositiontaking_20 = 1,@isauto_v8spositiontaking_1 = 1,@isauto_v8spositiontaking_3 = 1,@isauto_v8spositiontaking_20 = 1,@isauto_v10spositiontaking_1 = 1,@isauto_v10spositiontaking_2 = 1,@isauto_v10spositiontaking_3 = 1,@isauto_v10spositiontaking_20 = 1,@isauto_v11spositiontaking_1 = 1,@isauto_v11spositiontaking_20 = 1,@isauto_v99spositiontaking_1 = 1,@isauto_v99spositiontaking_2 = 1,@isauto_v99spositiontaking_3 = 1,@isauto_v99spositiontaking_20 = 1,@mpositiontaking_1 = 0.7,@mpositiontaking_2 = 0.7,@mpositiontaking_3 = 0.7,@mpositiontaking_4 = 0.7,@mpositiontaking_5 = 0.7,@mpositiontaking_6 = 0.7,@mpositiontaking_7 = 0.7,@mpositiontaking_8 = 0.7,@mpositiontaking_9 = 0.7,@mpositiontaking_10 = 0.7,@mlivepositiontaking_1 = 0.7,@mlivepositiontaking_3 = 0.7,@mlivepositiontaking_7 = 0.7,@mlivepositiontaking_8 = 0.7,@v2mpositiontaking_1 = 0.7,@v2mpositiontaking_2 = 0.7,@v2mpositiontaking_3 = 0.7,@v2mpositiontaking_7 = 0.7,@v2mpositiontaking_8 = 0.7,@v2mpositiontaking_9 = 0.7,@v2mpositiontaking_20 = 0.7,@v3mpositiontaking_1 = 0.7,@v3mpositiontaking_2 = 0.7,@v3mpositiontaking_3 = 0.7,@v3mpositiontaking_20 = 0.7,@v5mpositiontaking_1 = 0.7,@v5mpositiontaking_2 = 0.7,@v5mpositiontaking_3 = 0.7,@v5mpositiontaking_20 = 0.7,@v8mpositiontaking_1 = 0.7,@v8mpositiontaking_3 = 0.7,@v8mpositiontaking_20 = 0.7,@v10mpositiontaking_1 = 0.7,@v10mpositiontaking_2 = 0.7,@v10mpositiontaking_3 = 0.7,@v10mpositiontaking_20 = 0.7,@v11mpositiontaking_1 = 0.7,@v11mpositiontaking_20 = 0.7,@v99mpositiontaking_1 = 0.7,@v99mpositiontaking_2 = 0.7,@v99mpositiontaking_3 = 0.7,@v99mpositiontaking_20 = 0.7,@UserID = 360418,@IP = '202.78.208.8'
		
		DELETE FROM @master WHERE mrecommend = @mrecommend

		GOTO StartLoop
		waitfor delay '000:00:01'
	EndLoop:
	
--EXEC dbo.Acc_CustomerUpdSuper_PositionTaking @custid = 726562,@spositiontaking_1 = 0.7,@spositiontaking_2 = 0.7,@spositiontaking_3 = 0.7,@spositiontaking_4 = 0.7,@spositiontaking_5 = 0.7,@spositiontaking_6 = 0.7,@spositiontaking_7 = 0.7,@spositiontaking_8 = 0.7,@spositiontaking_9 = 0.7,@spositiontaking_10 = 0.7,@slivepositiontaking_1 = 0.7,@slivepositiontaking_3 = 0.7,@slivepositiontaking_7 = 0.7,@slivepositiontaking_8 = 0.7,@v2spositiontaking_1 = 0.7,@v2spositiontaking_2 = 0.7,@v2spositiontaking_3 = 0.7,@v2spositiontaking_7 = 0.7,@v2spositiontaking_8 = 0.7,@v2spositiontaking_9 = 0.7,@v2spositiontaking_20 = 0.7,@v3spositiontaking_1 = 0.7,@v3spositiontaking_2 = 0.7,@v3spositiontaking_3 = 0.7,@v3spositiontaking_20 = 0.7,@v5spositiontaking_1 = 0.7,@v5spositiontaking_2 = 0.7,@v5spositiontaking_3 = 0.7,@v5spositiontaking_20 = 0.7,@v8spositiontaking_1 = 0.7,@v8spositiontaking_3 = 0.7,@v8spositiontaking_20 = 0.7,@v10spositiontaking_1 = 0.7,@v10spositiontaking_2 = 0.7,@v10spositiontaking_3 = 0.7,@v10spositiontaking_20 = 0.7,@v11spositiontaking_1 = 0.7,@v11spositiontaking_20 = 0.7,@v99spositiontaking_1 = 0.7,@v99spositiontaking_2 = 0.7,@v99spositiontaking_3 = 0.7,@v99spositiontaking_20 = 0.7,@mpositiontaking_1 = 0.7,@mpositiontaking_2 = 0.7,@mpositiontaking_3 = 0.7,@mpositiontaking_4 = 0.7,@mpositiontaking_5 = 0.7,@mpositiontaking_6 = 0.7,@mpositiontaking_7 = 0.7,@mpositiontaking_8 = 0.7,@mpositiontaking_9 = 0.7,@mpositiontaking_10 = 0.7,@mlivepositiontaking_1 = 0.7,@mlivepositiontaking_3 = 0.7,@mlivepositiontaking_7 = 0.7,@mlivepositiontaking_8 = 0.7,@v2mpositiontaking_1 = 0.7,@v2mpositiontaking_2 = 0.7,@v2mpositiontaking_3 = 0.7,@v2mpositiontaking_7 = 0.7,@v2mpositiontaking_8 = 0.7,@v2mpositiontaking_9 = 0.7,@v2mpositiontaking_20 = 0.7,@v3mpositiontaking_1 = 0.7,@v3mpositiontaking_2 = 0.7,@v3mpositiontaking_3 = 0.7,@v3mpositiontaking_20 = 0.7,@v5mpositiontaking_1 = 0.7,@v5mpositiontaking_2 = 0.7,@v5mpositiontaking_3 = 0.7,@v5mpositiontaking_20 = 0.7,@v8mpositiontaking_1 = 0.7,@v8mpositiontaking_3 = 0.7,@v8mpositiontaking_20 = 0.7,@v10mpositiontaking_1 = 0.7,@v10mpositiontaking_2 = 0.7,@v10mpositiontaking_3 = 0.7,@v10mpositiontaking_20 = 0.7,@v11mpositiontaking_1 = 0.7,@v11mpositiontaking_2 = 0.7,@v11mpositiontaking_20 = 0.7,@v99mpositiontaking_1 = 0.7,@v99mpositiontaking_2 = 0.7,@v99mpositiontaking_3 = 0.7,@v99mpositiontaking_20 = 0.7,@apositiontaking_1 = 0.7,@apositiontaking_2 = 0.7,@apositiontaking_3 = 0.7,@apositiontaking_4 = 0.7,@apositiontaking_5 = 0.7,@apositiontaking_6 = 0.7,@apositiontaking_7 = 0.7,@apositiontaking_8 = 0.7,@apositiontaking_9 = 0.7,@apositiontaking_10 = 0.7,@alivepositiontaking_1 = 0.7,@alivepositiontaking_3 = 0.7,@alivepositiontaking_7 = 0.7,@alivepositiontaking_8 = 0.7,@v2apositiontaking_1 = 0.7,@v2apositiontaking_2 = 0.7,@v2apositiontaking_3 = 0.7,@v2apositiontaking_7 = 0.7,@v2apositiontaking_8 = 0.7,@v2apositiontaking_9 = 0.7,@v2apositiontaking_20 = 0.7,@v3apositiontaking_1 = 0.7,@v3apositiontaking_2 = 0.7,@v3apositiontaking_3 = 0.7,@v3apositiontaking_20 = 0.7,@v5apositiontaking_1 = 0.7,@v5apositiontaking_2 = 0.7,@v5apositiontaking_3 = 0.7,@v5apositiontaking_20 = 0.7,@v8apositiontaking_1 = 0.7,@v8apositiontaking_3 = 0.7,@v8apositiontaking_20 = 0.7,@v10apositiontaking_1 = 0.7,@v10apositiontaking_2 = 0.7,@v10apositiontaking_3 = 0.7,@v10apositiontaking_20 = 0.7,@v11apositiontaking_1 = 0.7,@v11apositiontaking_20 = 0.7,@v99apositiontaking_1 = 0.7,@v99apositiontaking_2 = 0.7,@v99apositiontaking_3 = 0.7,@v99apositiontaking_20 = 0.7,@UserID = 360418,@IP = '202.78.208.8'
