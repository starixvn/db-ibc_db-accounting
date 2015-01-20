ALTER PROCEDURE [dbo].[Acc_CustSetting3rd_13]
	@srecommend INT	
	,@Sporttype INT
	,@Bettype INT
	,@Discount DECIMAL(9,8)
AS
/*
	Created: Elodie
	Date: 20150108
	Task : Licensee Setting Configuration - Update Commission [#6304]
	DB: DBTXN/CustDB
	Original:

	Revisions:

	Param's Explanation:
		
*/ 
BEGIN

	SET NOCOUNT ON
	
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('Dep_Custsetting3rd','custinfo') AND type = 'U') <> 2
		RETURN
	
	--Create temp table containing all accounts belong to super, exclude fincance account
	CREATE TABLE #tblCust (custid INT, roleid INT)
	
	INSERT INTO #tblCust (custid,roleid)
	SELECT custid,roleid
	FROM custinfo WITH(NOLOCK)	
	WHERE srecommend = @srecommend
			AND mrecommend NOT IN (SELECT custid FROM custinfo WITH(NOLOCK)
									WHERE srecommend = @srecommend AND username LIKE '%Acc%' AND roleid=3)

	--Update Commission for HR
	UPDATE cs WITH(UPDLOCK,ROWLOCK)
	SET sdiscount = CASE WHEN roleid IN (1,4) THEN CASE WHEN sporttype = @Sporttype AND ((@Bettype = 31 AND bettype IN (31,32)) OR (@Bettype = 41 AND bettype IN (41,42)) OR (@Bettype = 51 AND bettype IN (51,52))) THEN @Discount END
					ELSE 0 END,
		adiscount = CASE WHEN roleid IN (1,3) THEN CASE WHEN sporttype = @Sporttype AND ((@Bettype = 31 AND bettype IN (31,32)) OR (@Bettype = 41 AND bettype IN (41,42)) OR (@Bettype = 51 AND bettype IN (51,52))) THEN @Discount END
					ELSE 0 END,
		discount  = CASE WHEN roleid IN (1,2) THEN CASE WHEN sporttype = @Sporttype AND ((@Bettype = 31 AND bettype IN (31,32)) OR (@Bettype = 41 AND bettype IN (41,42)) OR (@Bettype = 51 AND bettype IN (51,52))) THEN @Discount END
					ELSE 0 END,
		playerdiscount = 0		 
		FROM Dep_CustSetting cs 
			INNER JOIN #tblCust c ON c.custid = cs.custid
	
	DROP TABLE #tblCust
END





