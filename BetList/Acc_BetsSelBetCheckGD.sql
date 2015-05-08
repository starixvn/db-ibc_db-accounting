USE BODB02
GO

ALTER PROCEDURE [dbo].[Acc_BetsSelBetCheckGD]
	@refno  bigint,
	@Language NVARCHAR(2) = 'E'
AS

/*
	Created by: [Tom]
	Date: 20150508
	Task: Get info of Gold Deluxe Bets 
	DB: DBAGE.BODB02
	Original:  
	
	Revisions: 		
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @BetListGD TABLE (
		TransID BIGINT
		,Bettype INT
		,oddsid INT
		,odds SMALLMONEY
		,betteam NVARCHAR(20)
		,statusid INT
		,TransDesc VARCHAR(300)
		,WinlostDate SMALLDATETIME	
		)

	IF EXISTS (
			SELECT TOP 1 1
			FROM dbo.bettransg WITH (NOLOCK)
			WHERE refno = @refno
			)
	BEGIN
		INSERT INTO @BetListGD(TransID,Bettype,oddsid,odds,betteam,statusid,TransDesc,WinlostDate)
		SELECT btg.TransID
			,btg.Bettype
			,btg.oddsid
			,btg.odds
			,btg.betteam
			,btg.statusid
			,btg.TransDesc
			,WinlostDate
		FROM dbo.bettransg btg WITH (NOLOCK)
		WHERE refno = @refno
	END
	ELSE IF EXISTS (
			SELECT TOP 1 1
			FROM dbo.bettransg14 WITH (NOLOCK)
			WHERE refno = @refno
			)
	BEGIN
		INSERT INTO @BetListGD(TransID,Bettype,oddsid,odds,betteam,statusid,TransDesc,WinlostDate)
		SELECT btg.TransID
			,btg.Bettype
			,btg.oddsid
			,btg.odds
			,btg.betteam
			,btg.statusid
			,btg.TransDesc
			,WinlostDate			 
		FROM dbo.bettransg14 btg WITH (NOLOCK)
		WHERE refno = @refno
	END
	ELSE IF EXISTS (
			SELECT TOP 1 1
			FROM DBARC.bodb_archive.dbo.bettransg WITH (NOLOCK)
			WHERE refno = @refno
			)
	BEGIN
		INSERT INTO @BetListGD(TransID,Bettype,oddsid,odds,betteam,statusid,TransDesc,WinlostDate)
		SELECT btg.TransID
			,btg.Bettype
			,btg.oddsid
			,btg.odds
			,btg.betteam
			,btg.statusid
			,btg.TransDesc
			,WinlostDate
		FROM DBARC.bodb_archive.dbo.bettransg btg WITH (NOLOCK)
		WHERE refno = @refno
	END

	SELECT TransID
		,Bettype
		,oddsid
		,odds
		,betteam
		,statusid
		,TransDesc
		,WinlostDate
	FROM @BetListGD
	ORDER BY TransID DESC


END

GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetCheckGD] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetCheckGD] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetsSelBetCheckGD] TO [vnteam]