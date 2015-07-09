ALTER PROCEDURE [dbo].[DBA_MNLBackupSPs] AS
/*
	DB: All DBs
	Creator : Viet
	Date : 6 Feb 2010
	Task : Generate script for all SPs belong to accounting, agent and affiliate site.
	History:
		
*/
SET NOCOUNT ON

DECLARE @exec_str varchar(200)
DECLARE @SP_name varchar(50), @SPID int
DECLARE @ScriptType int
Declare @ServerName varchar(30),
		@DBName varchar(30),
		@ScriptFile varchar(355)

IF @ScriptFile is NULL
  BEGIN
	-- Select Script File automatically
	-- form of file name: MNLBackup_SP_Script_[day].[month].[year]_[hour][minute][second].sql
	Set @ScriptFile =	'\\10.1.1.100\G$\VietTmp\MNLBackup_'+@@servername+ '_' + db_name() +'_SP_Script_'
						+ Replace(CONVERT(varchar(11),CURRENT_TIMESTAMP,106),' ','.') + '_'
						+ Replace(CONVERT(varchar(30),CURRENT_TIMESTAMP,108), ':','')
						+ '.sql'	
  END
ELSE
  BEGIN
	declare @result int
	exec master..xp_fileexist @ScriptFile, @result output
	
	IF (@result = 1)  --if file exists then exit sp
	begin
		print @ScriptFile + ' is exist. No operation is performed'
		return
		
	end   
  END  
  
Select @ServerName = @@servername, @DBName = db_name()

DECLARE @oServer int
DECLARE @method varchar(300)
DECLARE @TSQL varchar(4000)

EXEC sp_OACreate 'SQLDMO.SQLServer', @oServer OUT
EXEC sp_OASetProperty @oServer, 'loginsecure', 'true'
EXEC sp_OAMethod @oServer, 'Connect', NULL, @ServerName

CREATE TABLE #TEMP_SPsName (SPID int primary key, SPName varchar(100))
INSERT INTO #TEMP_SPsName
SELECT sp.object_id, sp.name
FROM sys.procedures sp WITH(NOLOCK)
WHERE sp.is_ms_shipped = 0
and ( -- all Acc, Age, Aff SPs
		sp.name like 'Acc_%'
		OR sp.name like 'Age_%'
		OR sp.name like 'Aff_%'
		OR sp.name like 'Is_%'
		OR sp.name like 'WriteLog_%'
	)
and ( -- except settlement SPs
		sp.name not like 'Acc_ExecRep_%'
	)

SELECT TOP 1 @SPID = SPID, @SP_name = SPName FROM #TEMP_SPsName	
WHILE (@SPID IS NOT NULL)
BEGIN		
	SET @ScriptType = 256 | 2 | 6 

	SET @method = 'Databases("'+@DBName+'").' +
				  'StoredProcedures("'+LTrim(RTrim(@SP_name))+'").Script' +
				  '(' + CAST (@ScriptType AS CHAR) +
				  ',"'+@ScriptFile +'", 4)'
	print @method
	EXEC sp_OAMethod @oServer, @method, @TSQL OUT
	
	DELETE FROM #TEMP_SPsName WHERE SPID = @SPID
	SELECT @SPID = null
	SELECT TOP 1 @SPID = SPID, @SP_name = SPName FROM #TEMP_SPsName	
END

EXEC sp_OADestroy @oServer



GO
GRANT VIEW DEFINITION ON [dbo].[DBA_MNLBackupSPs] TO [vnteam]