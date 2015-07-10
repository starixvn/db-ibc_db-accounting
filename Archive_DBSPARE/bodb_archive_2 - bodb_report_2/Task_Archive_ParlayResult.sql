ALTER PROCEDURE [dbo].[Task_Archive_ParlayResult]
AS
/*
	- 20131108@Elodie: Splitting bodb02 into CustDB (Use DBARC instead of DB06)
					   
*/					   
	Declare @winlostdate smalldatetime
	
	SELECT @winlostdate = MAX(winlostdate)
	FROM dbo.Task_ArchiveDate

	INSERT INTO DBARC.[bodb_Archive].dbo.[betParlayResult] (
		rID, RefNo, Serial, transid, winlostdate, statusid, stake, Odds, mOdds,
		winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
		)
	SELECT
		rID, RefNo, Serial, transid, winlostdate, statusid, stake, Odds, mOdds,
		winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
	FROM
		dbo.betParlayResult
	WHERE
		winlostdate <= @winlostdate

	INSERT INTO DBARC.[bodb_Archive].dbo.[betParlayResult_Archive]
		(rID, RefNo, Serial, winlostdate, statusid, Odds, mOdds)
	SELECT
		rID, RefNo, Serial, winlostdate, statusid, Odds, mOdds
	FROM
		dbo.betParlayResult
	WHERE
		winlostdate <= @winlostdate


--	IF @@ERROR = 0
--		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @winlostdate, @parlay = 29
		--DELETE FROM dbo.betParlayResult
		--WHERE winlostdate <= @winlostdate


GO
GRANT VIEW DEFINITION ON [dbo].[Task_Archive_ParlayResult] TO [vnteam] AS [dbo]