CREATE PROCEDURE [dbo].DBA_TaskImportData
AS
BEGIN
--Import Main DB
---------------------------------
Exec DBA_Import_Odds_Info @isMain = 1, @Istest = 0
GO
Exec DBA_Import_Odds_Small @isMain = 1, @Istest = 0
GO
------------------------
Declare @StrCurrency varchar(200)
select @StrCurrency = '2, 3, 12, 20, 13, 37, 33'

--Bettrans
Exec DBA_Import_Bet	@StrCurrency = @StrCurrency, @isMain = 1, @Istest = 0

--Bettrans14
Exec DBA_Import_Bet14 @StrCurrency = @StrCurrency, @isMain = 1, @Istest = 0
GO


--Import Replication DB
---------------------------------
Exec DBA_Import_Odds_Info @isMain = 0, @Istest = 0
GO

Exec DBA_Import_Odds_Small @isMain = 0, @Istest = 0
GO
------------------------
Declare @StrCurrency varchar(200)
select @StrCurrency = '2, 3, 12, 20, 13, 37, 33'
--Bettrans
Exec DBA_Import_Bet	@StrCurrency = @StrCurrency, @isMain = 0, @Istest = 0

--Bettrans14
Exec DBA_Import_Bet14 @StrCurrency = @StrCurrency, @isMain = 0, @Istest = 0
---------------- 
END