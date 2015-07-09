ALTER PROCEDURE [dbo].[DBA_Import_Odds_Info]
	@IsMain bit,
	@IsTest bit = 1
AS
if @@servername = 'DWDBG1S' and @IsMain = 0
	Return

if @@servername <> 'DWDBG1S' and @IsMain = 1
	Return

if @IsTest = 1
	Print 'Delete data'
else
begin
	if @@servername = 'DWDBG1S' --Main DB
	BEGIN
		DELETE FROM bettype
		DELETE FROM Dot_Admin_LeagueDisplayMode
		DELETE FROM Dot_Match_Favor
		DELETE FROM exchange
		DELETE FROM league
		DELETE FROM LeaguePattern
		DELETE FROM match_streaming
		DELETE FROM Site
		DELETE FROM Sports
		DELETE FROM team
		DELETE FROM TeamPattern
	END
	ELSE
	BEGIN
		TRUNCATE TABLE bettype
		TRUNCATE TABLE Dot_Admin_LeagueDisplayMode
		TRUNCATE TABLE Dot_Match_Favor
		TRUNCATE TABLE exchange
		TRUNCATE TABLE league
		TRUNCATE TABLE LeaguePattern
		TRUNCATE TABLE match_streaming
		TRUNCATE TABLE Site
		TRUNCATE TABLE Sports
		TRUNCATE TABLE team
		TRUNCATE TABLE TeamPattern
	END
end
------------------------------------------------------

DECLARE @sql_cmd nvarchar(4000), @plist varchar(4000)
SELECT @plist = dbo.f_GetParamsList('bettype','')
SELECT @sql_cmd = 'Insert into bettype (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.bettype '
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
 


-----------------------------------------------------

SELECT @plist = dbo.f_GetParamsList('Dot_Admin_LeagueDisplayMode','')
SELECT @sql_cmd = 'Insert into Dot_Admin_LeagueDisplayMode (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.Dot_Admin_LeagueDisplayMode'

SET IDENTITY_INSERT Dot_Admin_LeagueDisplayMode ON

if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
	
SET IDENTITY_INSERT Dot_Admin_LeagueDisplayMode OFF


------------------------------------------------------

SELECT @plist = dbo.f_GetParamsList('Dot_Match_Favor','')
SELECT @sql_cmd = 'Insert into Dot_Match_Favor (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.Dot_Match_Favor'

if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)

------------------------------------------------------

SELECT @plist = dbo.f_GetParamsList('exchange','')
SELECT @sql_cmd = 'Insert into exchange (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.exchange'

SET IDENTITY_INSERT exchange ON

if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)

SET IDENTITY_INSERT exchange OFF
------------------------------------------------------

SELECT @plist = dbo.f_GetParamsList('league','')
SELECT @sql_cmd = 'Insert into league (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.league'

SET IDENTITY_INSERT league ON
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)

SET IDENTITY_INSERT league OFF
------------------------------------------------------

SELECT @plist = dbo.f_GetParamsList('LeaguePattern','')
SELECT @sql_cmd = 'Insert into LeaguePattern (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.LeaguePattern'

SET IDENTITY_INSERT LeaguePattern ON
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
SET IDENTITY_INSERT LeaguePattern OFF

SELECT @plist = dbo.f_GetParamsList('match_streaming','')
SELECT @sql_cmd = 'Insert into match_streaming (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.match_streaming'
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)


SELECT @plist = dbo.f_GetParamsList('Site','')
SELECT @sql_cmd = 'Insert into Site (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.Site'
SET IDENTITY_INSERT Site ON
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
SET IDENTITY_INSERT Site OFF
------------------------------------------------------

SELECT @plist = dbo.f_GetParamsList('Sports','')
SELECT @sql_cmd = 'Insert into Sports (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.Sports'
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)

SELECT @plist = dbo.f_GetParamsList('team','')
SELECT @sql_cmd = 'Insert into team (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.team'

SET IDENTITY_INSERT team ON
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
SET IDENTITY_INSERT team OFF
------------------------------------------------------


SELECT @plist = dbo.f_GetParamsList('TeamPattern','')
SELECT @sql_cmd = 'Insert into TeamPattern (' + @plist  + ')' + 
	' Select ' + @plist + 
	' FROM db02vn.bodb02_tmp.dbo.TeamPattern'

SET IDENTITY_INSERT TeamPattern ON
if @istest = 1
	print @sql_cmd
else 
	exec(@sql_cmd)
SET IDENTITY_INSERT TeamPattern OFF
------------------------------------------------------
