USE CheckResultDB
GO 

ALTER PROCEDURE [dbo].DBA_Get_List_Agency_Licensee
(
	@srecommend VARCHAR(1000)=NULL
)
AS
/*
	Created: 20131015@Tom.Vo	
	Task :  Retrieve fee licensee's by product 
	DB: DB054.CheckResultDB
	Original:

	Revisions:
		
	Param's Explanation:
		
*/
BEGIN
SET NOCOUNT ON

IF ISNULL(@srecommend ,'')<>''
	BEGIN
		DECLARE @tblsrecommend TABLE (srecommend INT)
		
		INSERT INTO @tblsrecommend
		SELECT val FROM  [dbo].[strSplit] (@srecommend, ',')

		SELECT
				ag.custid,
				st.siteid
		FROM CheckCustDB.dbo.dep_custsuper d WITH (NOLOCK)
			INNER JOIN CheckCustDB.dbo.customer ag WITH (NOLOCK) ON d.custid = ag.srecommend
			INNER JOIN @tblsrecommend sp ON ag.srecommend = sp.srecommend
			INNER JOIN CheckCustDB.dbo.site st WITH (NOLOCK) ON st.site = ag.site
			--INNER join DBLIC.bodb_licensee.dbo.Licensees l with (nolock) on ag.site = l.LicenseeName
			INNER JOIN CheckCustDB.dbo.exchange e WITH (NOLOCK) ON ag.currency = e.exchangeid
			--LEFT JOIN DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK) ON ag.custid = lc.custid
		WHERE ag.roleid = 2
			AND ag.username NOT LIKE '%Aff%'
			AND ag.username NOT LIKE '%ACC' + e.currency + '%'
			AND ag.username NOT LIKE '%ACC' + e.Code + '%'
			AND ag.username NOT LIKE '%cas' + e.currency + '%'
			AND ag.username NOT LIKE '%Bank' + e.currency + '%'
			AND d.currency <> 20
	END
ELSE
	SELECT
			ag.custid,
			st.siteid
	FROM CheckCustDB.dbo.dep_custsuper d WITH (NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer ag WITH (NOLOCK) ON d.custid = ag.srecommend
		INNER JOIN CheckCustDB.dbo.site st WITH (NOLOCK) ON st.site = ag.site 
		--INNER join DBLIC.bodb_licensee.dbo.Licensees l with (nolock) on ag.site = l.LicenseeName
		INNER JOIN CheckCustDB.dbo.exchange e WITH (NOLOCK) ON ag.currency = e.exchangeid
		--LEFT JOIN DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK) ON ag.custid = lc.custid
	WHERE ag.roleid = 2		
		AND ag.username NOT LIKE '%Aff%'
		AND ag.username NOT LIKE '%ACC' + e.currency + '%'
		AND ag.username NOT LIKE '%ACC' + e.Code + '%'
		AND ag.username NOT LIKE '%cas' + e.currency + '%'
		AND ag.username NOT LIKE '%Bank' + e.currency + '%'
		AND d.currency <> 20

END



