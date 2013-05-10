ALTER PROCEDURE [dbo].[DBA_Import_Bet14_Bettrans14]
	@Currency int,
	@winlostdate smalldatetime,
	@IsMain bit,
	@Istest bit = 1
AS
if @@servername = 'DWDBG1S' and @IsMain = 0
	Return

if @@servername <> 'DWDBG1S' and @IsMain = 1
	Return

DECLARE @sql_cmd nvarchar(4000), @plist varchar(4000)
SELECT @plist = dbo.f_GetParamsList('bettrans14','')
SELECT @sql_cmd = 'Insert into bettrans14 (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.bettrans14 WHERE  currency = @Currency and winlostdate = @winlostdate and matchid > 0 '

 
if @istest = 1
	print @sql_cmd
else 
	exec sp_executesql @sql_cmd,N'@Currency int, @Winlostdate smalldatetime',@Currency = @Currency,@winlostdate = @winlostdate 
--Note: in DB05, the DB02VN linked server link to 10.20.20.214

