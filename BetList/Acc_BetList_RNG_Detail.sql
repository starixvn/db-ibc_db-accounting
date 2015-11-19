USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Lrf_BetList_RNG_Detail]    Script Date: 10/12/2015 11:00:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_BetList_RNG_Detail]
	@RefNo		BIGINT,
	@CustId		INT,
	@TransType	TINYINT	= 0
AS

/*
	Created: Kos@20151012
	Task : Get ticket detail from table betransRnG (Microgaming RNG Game)
	DB: DBAGE.bodb02
	Original:
	Revisions:
		- 20151030@Kos: Change ProductId/SportType of Microgaming RNG Casino
	Parameters:
		- @TransType
			+ 0 : All (DRAW/WON/LOSE/Reject/Void/Refund/Running/Waiting)
			+ 1 : DRAW/WON/LOSE/Refund
			+ 2 : Reject/Void
			+ 3 : Running/Waiting
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tmpStatus TABLE (statusId TINYINT)

	IF @TransType = 0
	BEGIN
		INSERT INTO @tmpStatus
		SELECT 111 UNION ALL 
		SELECT 112 UNION ALL 
		SELECT 113 UNION ALL
		SELECT 101 UNION ALL 
		SELECT 102 UNION ALL 
		SELECT 103 UNION ALL 
		SELECT 0 UNION ALL 
		SELECT 1
	END
	ELSE IF @TransType = 1
	BEGIN
		INSERT INTO @tmpStatus
		SELECT 111 UNION ALL 
		SELECT 112 UNION ALL 
		SELECT 113 UNION ALL 
		SELECT 103
	END
	ELSE IF @TransType = 2
	BEGIN
		INSERT INTO @tmpStatus
		SELECT 101 UNION ALL 
		SELECT 102
	END 
	ELSE IF @TransType = 3
	BEGIN
		INSERT INTO @tmpStatus(statusId)
		SELECT 0 UNION ALL 
		SELECT 1
	END

	IF EXISTS ( SELECT 1 FROM dbo.bettrans WITH (NOLOCK) WHERE transid = @RefNo )
	BEGIN
		SELECT
			brng.transid,
			brng.productID AS SportType,
			brng.gameID AS BetType,
			brng.transdate,
			brng.winlostdate,
			brng.status,
			brng.statusID,
			brng.odds,
			brng.stake,
			brng.actual_stake,
			(brng.winlost - brng.actual_stake) AS WinLost,
			brng.playercomm AS commission,
			brng.spositiontaking,
			brng.mpositiontaking,
			brng.apositiontaking,
			brng.swinlost,
			brng.mwinlost,
			brng.awinlost,
			brng.sdiscount,
			brng.adiscount,
			brng.discount,
			(brng.scomm - brng.acomm) AS scomm,
			(brng.acomm - brng.comm) AS acomm,
			(brng.comm - brng.playercomm) AS comm,
			brng.ip,
			brng.transdesc,
			CASE
				WHEN brng.productID = 205 THEN brng.TranId3rd		-- Microgaming RNG Casino
				ELSE ''
			END AS BetCheck
		FROM dbo.bettransRnG AS brng WITH (NOLOCK)
		WHERE brng.custid = @CustId 
			AND brng.RefNo = @RefNo
			AND brng.statusID IN (SELECT statusId FROM @tmpStatus)
	END
	ELSE IF EXISTS ( SELECT 1 FROM dbo.bettrans14 WITH (NOLOCK) WHERE transid = @RefNo )
	BEGIN
		SELECT
			brng.transid,
			brng.productID AS SportType,
			brng.gameID AS BetType,
			brng.transdate,
			brng.winlostdate,
			brng.status,
			brng.statusID,
			brng.odds,
			brng.stake,
			brng.actual_stake,
			(brng.winlost - brng.actual_stake) AS WinLost,
			brng.playercomm AS commission,
			brng.spositiontaking,
			brng.mpositiontaking,
			brng.apositiontaking,
			brng.swinlost,
			brng.mwinlost,
			brng.awinlost,
			brng.sdiscount,
			brng.adiscount,
			brng.discount,
			(brng.scomm - brng.acomm) AS scomm,
			(brng.acomm - brng.comm) AS acomm,
			(brng.comm - brng.playercomm) AS comm,
			brng.ip,
			brng.transdesc,
			CASE
				WHEN brng.productID = 205 THEN brng.TranId3rd		-- Microgaming RNG Casino
				ELSE ''
			END AS BetCheck
		FROM dbo.bettransRnG14 AS brng WITH (NOLOCK)
		WHERE brng.custid = @CustId AND brng.RefNo = @RefNo
	END
	ELSE IF EXISTS ( SELECT 1 FROM DBARC.bodb_Archive.dbo.bettrans_bk WITH (NOLOCK) WHERE transid = @RefNo )
	BEGIN
		SELECT
			brng.transid,
			brng.productID AS SportType,
			brng.gameID AS BetType,
			brng.transdate,
			brng.winlostdate,
			brng.status,
			brng.statusID,
			brng.odds,
			brng.stake,
			brng.actual_stake,
			(brng.winlost - brng.actual_stake) AS WinLost,
			brng.playercomm AS commission,
			brng.spositiontaking,
			brng.mpositiontaking,
			brng.apositiontaking,
			brng.swinlost,
			brng.mwinlost,
			brng.awinlost,
			brng.sdiscount,
			brng.adiscount,
			brng.discount,
			(brng.scomm - brng.acomm) AS scomm,
			(brng.acomm - brng.comm) AS acomm,
			(brng.comm - brng.playercomm) AS comm,
			brng.ip,
			brng.transdesc,
			CASE
				WHEN brng.productID = 205 THEN brng.TranId3rd		-- Microgaming RNG Casino
				ELSE ''
			END AS BetCheck
		FROM DBARC.bodb_Archive.dbo.bettransRnG_bk AS brng WITH (NOLOCK)
		WHERE brng.custid = @CustId AND brng.RefNo = @RefNo
	END
END


GRANT	VIEW DEFINITION	ON	Acc_BetList_RNG_Detail	TO	vnteam
GRANT	EXECUTE	ON	Acc_BetList_RNG_Detail	TO	bodbExtAccNet
GRANT	EXECUTE	ON	Acc_BetList_RNG_Detail	TO	bodbDownlineNetView
GRANT	EXECUTE	ON	Acc_BetList_RNG_Detail	TO	bodbDownlineNet
GRANT	EXECUTE	ON	Acc_BetList_RNG_Detail	TO	bodbAdminNet