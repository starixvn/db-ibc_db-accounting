ALTER PROCEDURE [dbo].[DBA_Import_Odds_Small]	
	@IsMain bit,
	@IsTest bit = 1
AS
if @@servername = 'DWDBG1S' and @IsMain = 0
	Return

if @@servername <> 'DWDBG1S' and @IsMain = 1
	Return

if @IsTest = 1
	print 'Delete data'
else
begin
	if @@servername = 'DWDBG1S' --Main DB
	BEGIN
		DELETE FROM EventStats
		DELETE FROM match
		DELETE FROM match_remark
		DELETE FROM odds
		DELETE FROM outright
	END
	ELSE
	BEGIN
		TRUNCATE TABLE EventStats
		TRUNCATE TABLE match
		TRUNCATE TABLE match_remark
		TRUNCATE TABLE odds
		TRUNCATE TABLE outright
	END
end

DECLARE @sql_cmd nvarchar(4000), @plist varchar(4000)
SELECT @plist = dbo.f_GetParamsList('EventStats','')
SELECT @sql_cmd = 'Insert into EventStats (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.EventStats '
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)


------------------------------------------------------

SELECT @plist = dbo.f_GetParamsList('match','')
SELECT @sql_cmd = 'Insert into match (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.match '

SET IDENTITY_INSERT match ON

if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
SET IDENTITY_INSERT match OFF

------------------------------------------------------


SELECT @plist = dbo.f_GetParamsList('match_remark','')
SELECT @sql_cmd = 'Insert into match_remark (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.match_remark '
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)


------------------------------------------------------

SELECT @plist = dbo.f_GetParamsList('odds','')
SELECT @sql_cmd = 'Insert into odds (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.odds '

SET IDENTITY_INSERT odds ON
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
SET IDENTITY_INSERT odds OFF
------------------------------------------------------


SELECT @plist = dbo.f_GetParamsList('outright','')
SELECT @sql_cmd = 'Insert into outright (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.outright'

SET IDENTITY_INSERT outright ON
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
SET IDENTITY_INSERT outright OFF

GO
