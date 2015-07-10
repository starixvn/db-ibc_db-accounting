USE CheckLicenseeDB
GO
SET NOCOUNT ON

TRUNCATE TABLE dbo.[Licensees]
--TRUNCATE TABLE dbo.LicenseeBAConfig
--TRUNCATE TABLE dbo.LicenseeBAHistory
--TRUNCATE TABLE dbo.LicenseeSpecialCust	
--TRUNCATE TABLE dbo.LicenseeGroupComm
--TRUNCATE TABLE dbo.LicenseeCustComm


DECLARE @InsertDate SmallDateTime

SELECT @InsertDate=CONVERT(Varchar(10),GETDATE(),101)

INSERT INTO [dbo].[Licensees]
           ([LicenseeID]
           ,[LicenseeName]
           ,[Description]
           ,[IsDeposit]
           ,[AffectedDate]
           ,[BrandName]
           ,[CompanyName]
           ,[IsAllowedMemberComm]
		   )
SELECT [LicenseeID]
        ,[LicenseeName]
        ,[Description]
        ,[IsDeposit]
        ,[AffectedDate]
        ,[BrandName]
        ,[CompanyName]
        ,[IsAllowedMemberComm]
FROM DBLIC.bodb_licensee.dbo.[Licensees] lb WITH(NOLOCK)

INSERT INTO [dbo].LicenseeBAConfig 
	([LicenseeID]
      ,[1x2Comm]
      ,[OtherComm]
      ,[EnableBA]
      ,[ModifyBy]
      ,[ModifyDate]
      ,[groupa]
      ,[groupb]
      ,[groupc]
      ,[groupd]
	  ,[InsertDate])

SELECT [LicenseeID]
      ,[1x2Comm]
      ,[OtherComm]
      ,[EnableBA]
      ,[ModifyBy]
      ,[ModifyDate]
      ,[groupa]
      ,[groupb]
      ,[groupc]
      ,[groupd]
	  ,@InsertDate
FROM DBLIC.bodb_licensee.dbo.LicenseeBAConfig lb WITH(NOLOCK)

INSERT INTO [dbo].[LicenseeBAHistory]
           ([ID]
           ,[LicenseeID]
           ,[CustID]
           ,[OnDate]
           ,[OffDate]
           ,[OnBy]
           ,[OffBy]
           ,[GroupComm]
           ,[1x2Comm]
           ,[OtherComm]
           ,[Status]
           ,[Ugroup]
		   ,[InsertDate])
SELECT [ID]
           ,[LicenseeID]
           ,[CustID]
           ,[OnDate]
           ,[OffDate]
           ,[OnBy]
           ,[OffBy]
           ,[GroupComm]
           ,[1x2Comm]
           ,[OtherComm]
           ,[Status]
           ,[Ugroup]
		   ,@InsertDate
FROM DBLIC.bodb_licensee.dbo.[LicenseeBAHistory] lb WITH(NOLOCK)
WHERE [Status] = 'running'

INSERT INTO [dbo].[LicenseeCustComm]
           ([LicenseeID]
           ,[CustID]
           ,[SBComm]
           ,[RacingComm]
           ,[NGComm]
           ,[GroupCommID]
           ,[LCComm]
           ,[RNGComm]
		   ,[InsertDate])
SELECT [LicenseeID]
        ,[CustID]
        ,[SBComm]
        ,[RacingComm]
        ,[NGComm]
        ,[GroupCommID]
        ,[LCComm]
        ,[RNGComm]
		,@InsertDate
FROM DBLIC.bodb_licensee.dbo.[LicenseeCustComm] lb WITH(NOLOCK) 

INSERT INTO [dbo].[LicenseeGroupComm]
           ([id]
           ,[Licenseeid]
           ,[GroupName]
           ,[IsActive]
           ,[SBComm]
           ,[RacingComm]
           ,[NGComm]
           ,[color]
           ,[IsDefault]
           ,[LCComm]
           ,[RNGComm]
		   ,[InsertDate])
SELECT [id]
        ,[Licenseeid]
        ,[GroupName]
        ,[IsActive]
        ,[SBComm]
        ,[RacingComm]
        ,[NGComm]
        ,[color]
        ,[IsDefault]
        ,[LCComm]
        ,[RNGComm]
		,@InsertDate
FROM DBLIC.bodb_licensee.dbo.[LicenseeGroupComm] lb WITH(NOLOCK)

INSERT INTO [dbo].[LicenseeSpecialCust]
           ([Licenseeid]
           ,[Custid]
           ,[ugroup]
           ,[ugroup_old]
           ,[modifyby]
           ,[modifydate]
		   ,[InsertDate])
SELECT [Licenseeid]
        ,[Custid]
        ,[ugroup]
        ,[ugroup_old]
        ,[modifyby]
        ,[modifydate]
		,@InsertDate
FROM DBLIC.bodb_licensee.dbo.[LicenseeSpecialCust] lb WITH(NOLOCK)

