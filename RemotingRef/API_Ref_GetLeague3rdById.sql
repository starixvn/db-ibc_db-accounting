/*<info serverAlias="DBBOF-bodb02" executers="asv_hit" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[API_Ref_GetLeague3rdById]
	@League3rdId INT
AS

/*
	Created: Kos@20240711
	Task: Fanex.RemotingRef - Get League3rd by ID
	DB: DBBOF.bodb02

	Revisions:
		- 20240711@Kos: Created [#Redmine: 207774]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		League3rdId,
		LeagueName,
		LeagueNameSC,
		LeagueNameTC,
		LeagueNameJP,
		LeagueNameTH,
		LeagueNameIN,
		LeagueNameVN,
		LeagueNameKO,
		LeagueNameHI,
		LeagueNameMMR,
		LeagueCode,
		VendorLeagueId,
		VendorLeagueName,
		SportType,
		CAST(Tstamp AS BIGINT) AS Tstamp
	FROM dbo.League3rd WITH (NOLOCK)
	WHERE League3rdId = @League3rdId
END
GO
