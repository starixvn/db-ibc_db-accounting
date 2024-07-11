/*<info serverAlias="DBBOF-bodb02" executers="asv_hit" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[API_Ref_GetLeague3rd]
	@MinTstamp BIGINT = 0
AS

/*
	Created: Kos@20240711
	Task: Fanex.RemotingRef - Get League3rd
	DB: DBBOF.bodb02
	Param's Explanation:
		- @MinTstamp: min timestamp (0: Get All)

	Revisions:
		- 20240711@Kos: Created [#Redmine: 207774]
*/

BEGIN
	SET NOCOUNT ON

	IF @MinTstamp = 0
	BEGIN
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
	END
	ELSE
	BEGIN
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
		WHERE Tstamp > CONVERT(TIMESTAMP, @MinTstamp)
	END
END
GO
