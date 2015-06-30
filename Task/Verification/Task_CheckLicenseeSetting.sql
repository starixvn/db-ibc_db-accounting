ALTER PROCEDURE [dbo].[Task_CheckLicenseeSetting]

AS 
BEGIN 
	/*	Created by: Jamie
		Date: 20120204
		Task: Verify Commission & PT setting for All licensees 
				+ Commission: Aust: 3% | Others: 4%
				+ PT: 12BET: 50% on Agent | Others: 0%
			1. Commission on Agent Licensee: Aust:3% | Others: 4% 
			2. Agent Licensee PT: 12BET : 50% | Others: 0% 
			3. House PT: 12BET: 0% | Others: 50%  


	*/
	--1. Step 1:CHECKING COMMISSION FOR ALL LICENSEES

	SET NOCOUNT ON 

	DECLARE	@commList VARCHAR(7500),
			@ptList VARCHAR(7500),
			@ibcPTList VARCHAR(7500), --UK/Irish Horse Racing 
			@ibcPTList_Others VARCHAR(7500),
			@Message VARCHAR(8000)

	SELECT	@commList='',
			@ptList='',
			@ibcPTList='',
			@ibcPTList_Others='',
			@Message=''

--	SELECT	@commList = @commList + CAST( cs.CustID AS VARCHAR(20)) +','
--	FROM(	SELECT DISTINCT cs.custid --,ci.username, ci.roleid,cs.sporttype, cs.bettype, cs.spositiontaking, cs.mpositiontaking, cs.apositiontaking, cs.sdiscount, cs.adiscount, cs.discount
--			FROM CustSetting3rd cs WITH (NOLOCK)
--				INNER JOIN custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
--			WHERE ci.srecommend IN (
--				SELECT *
--				FROM f_DepSuper_1('ALL')
--
--			)
--			AND ci.mrecommend NOT IN (927780,857227)
--			AND ci.currency <> 20 --UUS currency
--			AND cs.sporttype BETWEEN 151 AND 153
--			AND cs.bettype BETWEEN 31 AND 52
--			AND(
--				( ci.roleid = 4 AND sdiscount <> CASE WHEN bettype IN (51,52)THEN 0.03 ELSE 0.04 END )
--				OR( ci.roleid = 3 AND adiscount <> CASE WHEN bettype IN (51,52)THEN 0.03 ELSE 0.04 END )
--				OR( ci.roleid = 2 AND discount <> CASE WHEN bettype IN (51,52)THEN 0.03 ELSE 0.04 END )
--				OR( ci.roleid = 1 AND (	sdiscount <> CASE WHEN bettype IN (51,52)THEN 0.03 ELSE 0.04 END
--										OR adiscount <> CASE WHEN bettype IN (51,52)THEN 0.03 ELSE 0.04 END
--										OR discount <> CASE WHEN bettype IN (51,52)THEN 0.03 ELSE 0.04 END
--									)
--				) 
--			)
--	) AS cs
--
--	IF @commList <>'' 
--		SELECT	@Message = 'Wrong Racing commission licensee(s): ' + @commList
--
--	SELECT @Message
--
--	--2. Step 2:CHECKING PT FOR 12BET
--
--	SELECT	@ptList = @ptList + CAST( cs.CustID AS VARCHAR(20)) +','
--	FROM(	SELECT DISTINCT cs.custid --,ci.username, ci.roleid,cs.sporttype, cs.bettype, cs.spositiontaking, cs.mpositiontaking, cs.apositiontaking, cs.sdiscount, cs.adiscount, cs.discount
--			FROM CustSetting3rd cs WITH (NOLOCK)
--				INNER JOIN custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
--			WHERE ci.srecommend IN (
--				SELECT *
--				FROM f_DepSuper_1('12bet')
--
--			)
--			AND ci.mrecommend NOT IN (927780,857227)
--			AND ci.currency <> 20 --UUS currency
--			AND cs.sporttype BETWEEN 151 AND 153
--			AND cs.bettype BETWEEN 31 AND 52
--			AND(
--			   ( ci.roleid = 4 AND (cs.spositiontaking <> 0.5 OR cs.mpositiontaking <> 0.5 OR cs.apositiontaking <>0.5 ))
--				OR( ci.roleid = 3 AND (cs.spositiontaking <> 0 OR cs.mpositiontaking <> 0.5 OR cs.apositiontaking <>0 ))
--				OR( ci.roleid = 2 AND (cs.spositiontaking <> 0 OR cs.mpositiontaking <> 0 OR cs.apositiontaking <>0.5 ))
--				OR( ci.roleid = 1 AND (cs.spositiontaking <> 0 OR cs.mpositiontaking <> 0 OR cs.apositiontaking <>0.5 ))
--			)
--	) as cs
--
--	IF @PTList <>'' 
--		SELECT	@Message =  @Message + ' Wrong Racing PT licensee(s): ' + @PTList
--
--	IF @Message <>'' RAISERROR(@Message,16,1)
--
--	SELECT @Message

	--3. Checking House PT on UK/Irish Horse : Collect all customers on bettrans : effect from 2012-05-14

--	SELECT	@ibcPTList = @ibcPTList + CAST( b.CustID AS VARCHAR(20)) +','
--	FROM	bettrans b WITH (NOLOCK)
--			INNER JOIN outright o WITH (NOLOCK) ON b.matchid = o.orid
--			INNER JOIN RacingMeeting m WITH (NOLOCK) ON o.leagueid =m.MeetingID
--	WHERE	b.bettype BETWEEN 31 AND 33
--			AND M.partnerID IN (2,3,4)
--			AND isnull(oddsspread,0) <> 0.5 	
--			AND srecommend IN (SELECT custid FROM dbo.f_depsuper_1('ALL'))
--			AND srecommend NOT IN (SELECT custid FROM dbo.f_depsuper_1('12BET'))
--			AND b.winlostdate >='2012-05-14'



	SELECT	@ibcPTList = @ibcPTList + CAST( CustID AS VARCHAR(20)) +','
	FROM	CustSuper WITH (NOLOCK)
	WHERE	CustID IN (SELECT custid FROM dbo.f_depsuper_1('ALL'))
			AND CustID NOT IN (SELECT custid FROM dbo.f_depsuper_1('12BET'))
			AND CustID NOT IN (7604551) -- MFSuperEURO  --Finance Accounts for Transfer ONLY 
			AND CustID NOT IN (8065893,8066263,8067174) -- test currency 20 spontest02,PSuperTestUUS3,PSuperTestUUS4
			AND AutoIBCPositionTaking_Fixed <> 0.5 	
			--AND b.winlostdate >='2012-05-14'



	IF @ibcPTList <>'' 
		SELECT	@Message =  @Message + ' Wrong Racing House PT licensee(s) for UK/Irish Horse : ' + @ibcPTList
----
----	SELECT	@ibcPTList_Others = @ibcPTList_Others + CAST( b.CustID AS VARCHAR(20)) +','
----	FROM	bettrans b WITH (NOLOCK)
----			INNER JOIN outright o WITH (NOLOCK) ON b.matchid = o.orid
----			INNER JOIN RacingMeeting m WITH (NOLOCK) ON o.leagueid =m.MeetingID
----	WHERE	b.bettype BETWEEN 31 AND 33
----			AND M.partnerID NOT IN (2,3,4)
----			AND isnull(oddsspread,0) <> 0
----			AND srecommend IN (SELECT custid FROM dbo.f_depsuper_1('ALL'))
----			--AND srecommend NOT IN (SELECT custid FROM dbo.f_depsuper_1('12BET'))
----			AND b.winlostdate >='2012-05-14'


	SELECT	@ibcPTList_Others = @ibcPTList_Others + CAST( CustID AS VARCHAR(20)) +','
	FROM	CustSuper WITH (NOLOCK) 
	WHERE	CustID IN (SELECT custid FROM dbo.f_depsuper_1('ALL'))
			AND CustID NOT IN (8065893,8066263,8067174) -- test currency 20 spontest02,PSuperTestUUS3,PSuperTestUUS4

			--AND b.winlostdate >='2012-05-14'
			AND(	AutoIBCPositionTaking_Tote <> 0 
					OR AutoIBCPT151_AU <> 0
					OR AutoIBCPT152_UK <> 0 
					OR AutoIBCPT152_AU <> 0 
					--OR AutoIBCPT153_AU <> 0  --Double-check all Harness setting when this product is offered 
			)


	IF @ibcPTList_Others <>'' 
		SELECT	@Message =  @Message + ' Wrong Racing House PT licensee(s) for Others: ' + @ibcPTList_Others

	IF @Message <>'' RAISERROR(@Message,16,1)


	SELECT @Message

	SELECT @commList AS Comm, @PTList AS PT, @ibcPTList AS ibcPTList


END
GO
GRANT VIEW DEFINITION ON [dbo].[Task_CheckLicenseeSetting] TO [vnteam] AS [dbo]