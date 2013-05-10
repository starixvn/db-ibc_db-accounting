ALTER PROCEDURE [dbo].[DBA_Import_Bet_Bettrans]
	@Currency int,
	@IsMain bit,
	@Istest bit = 1
AS
if @@servername = 'DWDBG1S' and @IsMain = 0
	Return

if @@servername <> 'DWDBG1S' and @IsMain = 1
	Return
	
DECLARE @sql_cmd nvarchar(4000), @plist varchar(4000)
SELECT @plist = dbo.f_GetParamsList('bettrans','')
SELECT @sql_cmd = 'Insert into bettrans(' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.bettrans WHERE  currency = @Currency'


SET IDENTITY_INSERT bettrans ON
if @istest = 1
	print @sql_cmd
else
 	exec sp_executesql @sql_cmd,N'@Currency int',@Currency = @Currency
--Note: in DB05, the DB02VN linked server link to 10.20.20.214

SET IDENTITY_INSERT bettrans OFF
