ALTER PROCEDURE [dbo].[DBA_Import_Bet14_sum_winloss]
	--@Currency int,
	--@winlostdate smalldatetime,
	@IsMain bit,
	@IsTest bit = 1
AS
if @@servername = 'DWDBG1S' and @IsMain = 0
	Return

if @@servername <> 'DWDBG1S' and @IsMain = 1
	Return
	
DECLARE @sql_cmd nvarchar(4000), @plist varchar(4000)
SELECT @plist = dbo.f_GetParamsList('sum_winloss','')
SELECT @sql_cmd = 'Insert into sum_winloss (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.sum_winloss '

 
SET IDENTITY_INSERT sum_winloss ON
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
--Note: in DB05, the DB02VN linked server link to 10.20.20.214
SET IDENTITY_INSERT sum_winloss OFF

