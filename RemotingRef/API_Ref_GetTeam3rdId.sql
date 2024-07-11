/*<info serverAlias="DBBOF-bodb02" executers="asv_hit" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[API_Ref_GetTeam3rdById]
	@Team3rdId INT
AS

/*
	Created: Kos@20240711
	Task: Fanex.RemotingRef - Get Team3rd by ID
	DB: DBBOF.bodb02

	Revisions:
		- 20240711@Kos: Created [#Redmine: 207774]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		Team3rdId,
		TeamName,
		TeamNameSC,
		TeamNameTC,
		TeamNameJP,
		TeamNameTH,
		TeamNameIN,
		TeamNameVN,
		TeamNameKO,
		TeamNameHI,
		TeamNameMMR,
		VendorTeamId,
		VendorTeamName,
		SportType,
		CAST(Tstamp AS BIGINT) AS Tstamp
	FROM dbo.Team3rd WITH (NOLOCK)
	WHERE Team3rdId = @Team3rdId
END
GO
