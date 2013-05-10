
ALTER PROCEDURE [dbo].[Acc_RecommLog_UpdTickets_xtest]
(
	@matchid INT,
	@recommID VARCHAR(MAX),
	@action VARCHAR(20) = 'void', --- 'recover'
	@userID INT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT
)
AS
/*
	Created: 20120911@Lukas
	Task: void/recover tickets in Recomm_Log
	DB: DB02.bodb02
	
	Revisions:
	
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)
	DECLARE @is1378 BIT
	
	SET @is1378 = 0
	
	IF @action = 'void'
	BEGIN
		UPDATE Recomm_Log WITH(ROWLOCK,UPDLOCK)
		SET @is1378 = CASE WHEN bettype IN (1,3,7,8) THEN 1 ELSE @is1378 END,
			status	= 'void',
			statusID= 102
		WHERE matchid = @matchid
			AND recommid IN (SELECT val FROM [dbo].[strSplit](@recommID,','))			
	END
	IF @action = 'recover'
	BEGIN
		UPDATE Recomm_Log WITH(ROWLOCK,UPDLOCK)
		SET @is1378 = CASE WHEN bettype IN (1,3,7,8) THEN 1 ELSE @is1378 END,
			status	= 'running',
			statusID= 0
		WHERE matchid = @matchid
			AND recommid IN (SELECT val FROM [dbo].[strSplit](@recommID,','))	
	END
	
	-- update totalbets
	IF @is1378 = 1
	BEGIN
		INSERT INTO @Total
		SELECT
			oddsid,
			SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
			SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
		FROM Recomm_Log b WITH (nolock)
			INNER JOIN exchange e WITH (nolock) ON b.currency = e.exchangeid
		WHERE bettype in (1,3,7,8) AND statusid IN (0,1) AND oddsid <> 0 and matchid = @matchid
		GROUP BY oddsid

		UPDATE odds WITH(ROWLOCK,UPDLOCK)
		SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
		FROM @Total t WHERE odds.oddsid = t.oddsid AND odds.matchid = @matchid
	END
END

GO
GRANT EXECUTE ON [Acc_RecommLog_UpdTickets] TO bodbAdminNet