/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_CustomerTotalAmountSel]
	@custid			INT,
	@TotalAmt		MONEY = 0 OUTPUT
AS

/*
	Created by Percy
	Date: 2017-10-18
	Task: Get total amount by custid
	DB: DBTXN.bodb02

	Revisions:
		- 20171018@Percy: Calculate total amount by custid [RedmineID: #84692]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (bettype INT, RefTable TINYINT)

	INSERT INTO #SportBettype (bettype, RefTable)
	SELECT bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)
	WHERE RefTable <> 0 -- get bettype from translog, bettransRnG, bettransLC

	DECLARE
		@totalAmt_bettransRNG	MONEY = 0,
		@totalAmt_bettransLC	MONEY = 0,
		@totalAmt_translog		MONEY = 0,
		@yesterday				SMALLDATETIME
	
	SELECT @yesterday = DATEADD(DAY, -1, CONVERT(DATE, GETDATE()))
	
	-- translog
    SELECT	@totalAmt_translog = SUM(-actual_stake)
    FROM	dbo.translog WITH (NOLOCK)
    WHERE	custid = @CustId
			AND statusID IN (0, 1)
			
	-- bettransRNG
	SELECT	@totalAmt_bettransRNG = SUM(winlost-actual_stake+playercomm)
	FROM	dbo.bettransRnG WITH (NOLOCK)
	WHERE	custid = @custID 
			AND (
				statusID IN (0, 1)
				OR winlostdate >= @yesterday
			)
			
	-- bettransLC
	SELECT	@totalAmt_bettransLC = SUM(winlost-actual_stake+playercomm)
	FROM	dbo.bettransLC WITH (NOLOCK)
	WHERE	custid = @custID 
			AND (
				statusID IN (0, 1)
				OR winlostdate >= @yesterday
			)
  
	-- bettrans
	SELECT  @TotalAmt = SUM(winlost-actual_stake+playercomm)
    FROM	dbo.bettrans WITH (NOLOCK)
    WHERE	custid = @CustID
			AND (
				-- exclude running tickets on translog, bettransRnG, bettransLC
				(ruben = 0 AND NOT EXISTS (SELECT bettype FROM #SportBettype))
				-- exclude settle tickets on bettransRnG, bettransLC where winlostdate >= yesterday
				OR (ruben = 1 AND (winlostdate < @yesterday OR NOT EXISTS (SELECT bettype FROM #SportBettype WHERE RefTable IN (1, 2))))
			)
    
	SELECT @TotalAmt = ISNULL(@TotalAmt, 0) + ISNULL(@totalAmt_translog, 0) + ISNULL(@totalAmt_bettransRNG, 0) + ISNULL(@totalAmt_bettransLC, 0) 
END
GO