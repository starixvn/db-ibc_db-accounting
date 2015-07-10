ALTER PROCEDURE [dbo].[DBA_MoveTicket]
	@TransID bigint,
	@NewMatchID int
AS
/*
	DB: DBTRANS.bodb02
	Creator : Viet
	Date : 2009-06-04
	Task : Move one ticket to another match
	Revisions:
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20110513@Henry: change bettype to new range
	-- 20110518@Lukas: Update HomeTotal, AwayTotal to Odds table
*/
if not exists(SELECT 1 FROM Bettrans with(nolock) WHERE TransID = @TransID)
BEGIN
	select 'Invalid TransID, please check!' ErrMsg
	RETURN
END

if not exists(SELECT 1 FROM Match with(nolock) WHERE MatchID = @NewMatchID)
BEGIN
	select 'Invalid NewMatchID, please check!' ErrMsg
	RETURN
END

DECLARE @MatchID int, @Bettype int, @NewOddsID int, @Winlostdate smalldatetime

SELECT @MatchID = MatchID, @Bettype = Bettype
FROM Bettrans with(nolock)
WHERE TransID = @TransID

IF @MatchID = @NewMatchID
BEGIN
	select 'Invalid NewMatchID, please check!' ErrMsg
	RETURN
END

SELECT @NewOddsID = OddsID FROM Odds with(nolock) WHERE MatchID = @NewMatchID and Bettype=@Bettype

SELECT @NewMatchID = MatchID	
FROM Odds with(nolock)
WHERE OddsID = @NewOddsID

SELECT @Winlostdate = eventdate FROM Match with(nolock) WHERE MatchID = @MatchID

UPDATE Bettrans
Set MatchID = @NewMatchID, OddsID = @NewOddsID, winlostdate = @winlostdate,
	transdesc =  + '(move from ' + CAST(@MatchID as varchar(20)) + ')' + transdesc
WHERE TransID = @TransID

IF @Bettype IN (1,3,7,8)
BEGIN
	-- update totalbets
	DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)
	
	INSERT INTO @Total
	SELECT
		oddsid,
		SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
		SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
	FROM bettrans b WITH (nolock)
		INNER JOIN exchange e WITH (nolock) ON b.currency = e.exchangeid
	WHERE bettype = @bettype AND ruben = 0 AND oddsid <> 0 and matchid IN (@matchid, @NewMatchID)
	GROUP BY oddsid

	UPDATE odds WITH (rowlock, updlock)
	SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
	FROM @Total t WHERE odds.oddsid = t.oddsid
END

select @TransID TransID, @NewMatchID NewMatchID, @NewOddsID NewOddsID

GO
GRANT VIEW DEFINITION ON [dbo].[DBA_MoveTicket] TO [vnteam]