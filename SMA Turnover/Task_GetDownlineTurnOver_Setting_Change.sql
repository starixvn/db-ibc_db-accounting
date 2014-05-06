ALTER PROCEDURE [dbo].[Task_GetDownlineTurnOver_Setting_Change]
	@GetOption char(1) = '' -- C/D : Change/Delete
AS
/*
	Revisions:
		- 20140408@Elodie: Support all super, direct master and direct agent
*/
--SELECT custid, matchid, maxturnover, totalturnover from dbo.DownlineTurnOver_Setting
--GO

	SET NOCOUNT ON
	
	--SELECT custid, matchid, maxturnover, totalturnover
	--FROM @temp
	DELETE FROM DownlineTurnOver_Setting_tmp

	IF @GetOption = 'D'
		DELETE D
		OUTPUT deleted.SMAID, deleted.matchid INTO DownlineTurnOver_Setting_tmp (SMAID, matchid)
		FROM dbo.DownlineTurnOver_Setting_Delete D
	ELSE IF @GetOption = 'C'
	BEGIN
		Declare @GetValue sql_variant, @Last_tstamp binary(8), @Max_tstamp binary(8)
		
		EXEC sp_GetGlobalVariable 'TurnOver_Last_tstamp', @GetValue OUTPUT, 1
		SET @Last_tstamp = CONVERT(binary(8), @GetValue)
		
		INSERT INTO DownlineTurnOver_Setting_tmp (SMAID, matchid, maxturnover, totalturnover, tstamp)
		SELECT SMAID, matchid, maxturnover, totalturnover, tstamp
		FROM dbo.DownlineTurnOver_Setting with (nolock)
		WHERE tstamp > @Last_tstamp
		
		
		SELECT @Max_tstamp = MAX(tstamp) FROM DownlineTurnOver_Setting_tmp
		IF @Max_tstamp IS NOT NULL
			EXEC sp_SetGlobalVariable 'TurnOver_Last_tstamp', @Max_tstamp
	END
	
	SET NOCOUNT OFF