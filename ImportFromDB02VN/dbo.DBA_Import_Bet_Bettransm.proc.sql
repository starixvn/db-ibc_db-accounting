ALTER PROCEDURE [dbo].[DBA_Import_Bet_Bettransm]
	@IsMain bit,
	@Istest bit = 1
AS
if @@servername = 'DWDBG1S' and @IsMain = 0
	Return

if @@servername <> 'DWDBG1S' and @IsMain = 1
	Return

DECLARE @sql_cmd nvarchar(4000), @plist varchar(4000)
SELECT @plist = dbo.f_GetParamsList('bettransm','')
SELECT @sql_cmd = 'Insert into bettransm(' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.bettransm'

 
SET IDENTITY_INSERT bettransm ON
if @Istest = 1
	print @sql_cmd
else
	exec(@sql_cmd)
--Note: in DB05, the DB02VN linked server link to 10.20.20.214

SET IDENTITY_INSERT bettransm OFF


