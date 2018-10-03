/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0"></info>*/ 
USE bodb_licensee
GO

ALTER  PROCEDURE [dbo].[Acc_Dep_SyncLicenseeSetting]
@name  nvarchar(30),
@ErrCode int = 0 OUTPUT , 
@ErrMsg nvarchar(1000) = '' OUTPUT 		
AS

/*  
 Created by: 20131028@Jim
 Task: AccSite - Licensee Setting Configuration (feature #6303)
 DB: DBCUST-bodb_Licensee
 Revisions:  
	- 20181003@Sophia: Migrate SP from DB052 to DBCUST [Redmine: #99855]
   
*/ 

DECLARE @Site varchar(10)
DECLARE @LicenseeName VARCHAR(10)
DECLARE @SuperWildCard VARCHAR(20)

SELECT @Site=site
FROM CUSTDB.dbo.customer WITH (NOLOCK)
WHERE username=@name

IF ISNULL(@Site,'')=''
BEGIN 
	SELECT @Site=Site
	FROM CUSTDB.dbo.customer WITH (NOLOCK)
	WHERE Site=@name
	IF @@ROWCOUNT = 0 
	SELECT @ErrCode = 2
			, @ErrMsg ='Wrong input data, please check again'
	RETURN;
	
END 
			
SELECT @LicenseeName=LicenseeName FROM dbo.Licensees WITH (NOLOCK) WHERE LicenseeName=@Site
IF  ISNULL(@LicenseeName,'')=''
	BEGIN 
		SELECT @SuperWildCard=@Site+'Super%'
		EXEC [dbo].DBA_Lrf_CreateNewLicensee
				@LicenseeName=@Site ,
				@SuperWildCard =@SuperWildCard,
				@ResellerID  =0,
				@IsSpecial  = 0,
				@IsAllowedNG =0,
				@IsAllowedRB  =0,
				@IsAllowedDW =0
	END
		
ELSE 
	BEGIN
		SELECT @SuperWildCard=@LicenseeName+'Super%' 
		EXEC [dbo].DBA_CreateLicenseeAgent 
				@LicenseeName=@LicenseeName
				,@SuperWildCard=@SuperWildCard
				,@IsSpecial=0
	END
SELECT @ErrCode = 0
		, @ErrMsg =  'Process is Successfull'	


GO
GRANT EXECUTE ON [dbo].[Acc_Dep_SyncLicenseeSetting] TO [bodbAdminNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Dep_SyncLicenseeSetting] TO [vnteam]      

