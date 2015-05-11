ALTER PROCEDURE [dbo].[DBA_Import_Odds14]
	@IsMain bit,
	@Istest bit = 1
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
		DELETE FROM match14
		DELETE FROM odds14
		DELETE FROM outright14	
	END
	ELSE
	BEGIN
		TRUNCATE TABLE match14
		TRUNCATE TABLE odds14
		TRUNCATE TABLE outright14
	END
end
------------------------------------------------------
DECLARE @sql_cmd nvarchar(4000), @plist varchar(4000)
SELECT @plist = dbo.f_GetParamsList('match14','')
SELECT @sql_cmd = 'Insert into match14 (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.match14 '
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)


------------------------------------------------------
SELECT @plist = dbo.f_GetParamsList('odds14','')
SELECT @sql_cmd = 'Insert into odds14 (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.odds14 '
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)

------------------------------------------------------
SELECT @plist = dbo.f_GetParamsList('outright14','')
SELECT @sql_cmd = 'Insert into outright14 (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.outright14 '
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)

