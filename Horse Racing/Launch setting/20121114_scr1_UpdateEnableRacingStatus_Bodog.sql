
-- update enable racing status for bodog customers


UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
SET DisableHorseRacing = 0,
	DisableOpenTote = 0,
	Disable151_AU = 0,
	Disable152_AU = 0,
	Disable152_UK = 0,
	Disable153_AU = 0
WHERE custid IN (7652050	,	--- BODOGNZD01
				7652044	,	--- BODOGNZD
				7652025	,	--- BODOGSuperNZD
				8198574	,	--- BODOGINH01
				8198573	,	--- BODOGINH
				8198572	,	--- BODOGSuperINH
				8221757	,	--- BODOGAUD01001
				8221761	,	--- BODOGAUD01002
				7651900	,	--- BODOGAUD01
				7651893	,	--- BODOGAUD
				7651889	,	--- BODOGSuperAUD
				8867248	,	--- BODOGAUD01005
				8338449	,	--- BODOGAUD01004
				8221810	,	--- BODOGAUD01003
			)
		
		
/*
SELECT custid, ',','--- ' + username
FROM custinfo c WITH(NOLOCK)
WHERE (	DisableHorseRacing = 1
		OR DisableOpenTote = 1
		OR Disable151_AU = 1
		OR Disable152_AU = 1
		OR Disable152_UK = 1
		OR Disable153_AU = 1
		)
	AND c.srecommend IN (SELECT custid FROM f_depsuper_1('bodog'))
	and mrecommend not in (
		select custid
		from custinfo with(nolock)
		where srecommend in (select custid from f_depsuper_1('bodog'))
		and roleid = 3 and username like '%ACC%'
	)
*/