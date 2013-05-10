set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER  PROCEDURE [dbo].[DBA_Lrf_ChangeLicenseeName]
@OldLicenseeName VARCHAR(100),
@NewLicenseeName VARCHAR(100),
@ErrCode		INT = 0 OUTPUT,
@ErrMsg			NVARCHAR(4000) = '' OUTPUT

AS
/*
	Create by : 20130307@Jim
	Task : Athena - Change licensee/ site name preparing for official launch
	DB: DBTXN.bodb02
	Param's Explanation: 
			*@OldLicenseeName :string, Licensee whose need to rename
			*NewLicenseeName: string,new licensee name 
		
*/		

CREATE TABLE #tblCust (CustID INT, username VARCHAR(100),username2 VARCHAR(100),roleid INT)

-- step 0: change sitename 
	IF NOT EXISTS (SELECT 1 FROM dbo.site WITH (NOLOCK) WHERE site=@NewLicenseeName)
	BEGIN
		UPDATE dbo.Site WITH (rowlock,updlock)
		SET Site=@NewLicenseeName
		WHERE Site=@OldLicenseeName
	END 
	ELSE 
		BEGIN 
			SELECT @ErrCode = 103, @ErrMsg = 'The New Site name have been already exist,please check again!'
			RETURN
		END	
	IF NOT EXISTS (SELECT 1 FROM DBDW.bodb_Account.dbo.tbl_site WITH (NOLOCK) WHERE site=@NewLicenseeName
				   UNION ALL
				   SELECT 1 FROM DBDW2.bodb_Account.dbo.tbl_site WITH (NOLOCK) WHERE site=@NewLicenseeName		
					)	
		BEGIN
			
			UPDATE DBDW.bodb_Account.dbo.tbl_site WITH (rowlock,updlock)
			SET Site=@NewLicenseeName
			WHERE Site=@OldLicenseeName
			
			UPDATE DBDW2.bodb_Account.dbo.tbl_site WITH (rowlock,updlock)
			SET Site=@NewLicenseeName
			WHERE Site=@OldLicenseeName
			
		END 
	ELSE 
		BEGIN 
			SELECT @ErrCode = 103, @ErrMsg = 'The New Site name have been already exist,please check again!'
			RETURN
		END 
-- step 1: change licenseename
	IF NOT EXISTS (SELECT 1 FROM DBLIC.bodb_licensee.dbo.Licensees  WITH (NOLOCK) WHERE LicenseeName=@NewLicenseeName)
	BEGIN
		UPDATE DBLIC.bodb_licensee.dbo.Licensees WITH (rowlock,updlock)
		SET LicenseeName=@NewLicenseeName
		WHERE LicenseeName=@OldLicenseeName
	END 
	ELSE 
		BEGIN 
			SELECT @ErrCode = 102, @ErrMsg = 'The New Licensee name have been already exist,please check again!'
			RETURN
		END	

-- step 2: change username,username2 from bettrans,bettrans14,Custinfo,Customer,LicenseeCustinfo ,Dep_CustSuper
	
	INSERT INTO #tblCust
	SELECT 	custid
			,replace(username,@OldLicenseeName,@NewLicenseeName) username
			,replace(username2,@OldLicenseeName,@NewLicenseeName) username2
			,roleid 
	FROM dbo.Customer WITH (NOLOCK)
	WHERE  srecommend in (SELECT custid FROM dbo.Dep_CustSuper WITH (NOLOCK) WHERE site=@OldLicenseeName)
	--- bettrans
	UPDATE dbo.bettrans WITH (rowlock,updlock)
	SET username=s.username
	FROM dbo.bettrans d
	INNER JOIN #tblCust  s
	ON s.custid=d.custid 
	--- bettrans14
	UPDATE dbo.bettrans14 WITH (rowlock,updlock)
	SET username=s.username
	FROM dbo.bettrans14 d
	INNER JOIN #tblCust  s
	ON s.custid=d.custid 
	---- Custinfo -----
	UPDATE dbo.custinfo WITH (rowlock,updlock)
	SET username=s.username
	FROM dbo.custinfo d
	INNER JOIN #tblCust  s
	ON s.custid=d.custid 
	---- Customer ------
	UPDATE dbo.customer WITH (rowlock,updlock)
	SET username=s.username,
		username2=s.username2
	FROM dbo.customer d
	INNER JOIN #tblCust s
	ON s.custid=d.custid 
	
	UPDATE dbo.customer WITH (rowlock,updlock)
	SET site=@newLicenseeName
	FROM dbo.customer d
	INNER JOIN #tblCust s
	ON s.custid=d.custid AND d.roleid<>1 
	---- Dep_CustSuper
	UPDATE dbo.Dep_CustSuper WITH (rowlock,updlock)
	SET site=@newLicenseeName
	WHERE site=@OldLicenseeName
	
	UPDATE dbo.Dep_CustSuper WITH (rowlock,updlock)
	SET username=s.username
	FROM dbo.Dep_CustSuper d
	INNER JOIN #tblCust s
	ON s.custid=d.custid
	
	
	-----LicenseeCustinfo
	UPDATE DBLIC.bodb_Licensee.dbo.LicenseeCustInfo WITH (rowlock,updlock)
	SET username=s.username,
		username2=s.username2
	FROM DBLIC.bodb_Licensee.dbo.LicenseeCustInfo d
	INNER JOIN #tblCust s
	ON s.custid=d.custid
	

	
	--------------------------------------------------------------------------------------------------------------------------------------------
	DROP TABLE #tblCust
	--------------------------------------------------------------------------------------------------------------------------------------------


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_Lrf_ChangeLicenseeName] TO [vnteam] 
