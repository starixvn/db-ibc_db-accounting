/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="" isNested="" selecters=""></info>*/
ALTER PROCEDURE [dbo].[Acc_LicenseeTransfer_InitCode]
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(200) = '' OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT @ErrCode = 0
		, @ErrMsg	= '';
		
	BEGIN TRY

		;WITH cte_allsetting
		AS (
			SELECT s.licenseename
				,s.username
				,s.currencycode
				,s.statusId
				,cs.from_custid
				,cs.from_currency
				,l.LicenseeID
				,c.custid AS to_custid
				,c.currency AS to_currency
			FROM dbo.Acc_f_LicenseeTransfer_GetCode() s
			LEFT JOIN CustDB.dbo.custInfo c WITH(NOLOCK) ON s.username = c.username
			LEFT JOIN bodb_Licensee.dbo.Licensees l WITH(NOLOCK) ON s.licenseename = l.licenseename
			OUTER APPLY (
				SELECT cs.custid AS from_custid
					,cs.currency AS from_currency
				FROM CustDB.dbo.Dep_CustSuper cs WITH(NOLOCK)
				INNER JOIN CustDB.dbo.exchange ex WITH(NOLOCK) ON cs.currency = ex.exchangeid
				WHERE cs.site = s.licenseename
					AND cs.currency <> 20
				) AS cs
			)
			,cte_finalsetting
		AS (
			SELECT DISTINCT licenseename
				,to_custid AS CustId
				,StatusId
			FROM cte_allsetting
			WHERE LicenseeID > 0
				AND from_custid > 0
				AND to_custid > 0
			)
		--select * from cte_finalsetting
		MERGE dbo.LicenseeTransferCode AS tar
		USING cte_finalsetting AS src
			ON (
					tar.licenseename = src.licenseename
					AND tar.CustID = tar.CustID
					)
		WHEN NOT MATCHED BY target
			THEN
				INSERT (
					LicenseeName
					,CustID
					,StatusId
					)
				VALUES (
					src.LicenseeName
					,src.CustID
					,src.StatusId
					)
		WHEN MATCHED
			THEN
				UPDATE
				SET CustID = src.CustID
					,StatusId = src.StatusId;
	END TRY
	BEGIN CATCH
		SELECT @ErrCode		= 100
			, @ErrMsg		= ERROR_MESSAGE()
		RETURN
	END CATCH
END
