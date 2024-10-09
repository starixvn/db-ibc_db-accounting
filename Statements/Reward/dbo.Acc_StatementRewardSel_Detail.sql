/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_StatementRewardSel_Detail]
	@CustId			INT,
	@Winlostdate	SMALLDATETIME
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - CreditReward - Reward Statement
	DB: DBACC.bodb02

	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @CID INT -- to prevent bad parameter sniffing
	SELECT  @CID = @custid
	
	-- get move bet date
	DECLARE @balanceUpDay SMALLDATETIME;
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @balanceUpDay OUTPUT

	-- 1.1 Get TransferExtra	
	IF @Winlostdate >= @balanceUpDay
	BEGIN
		SELECT 
			b.TransDate, 
			bt.typenamee AS transtype, 
			b.transdesc + ' - Ex.Rate: ' + CAST(b.actualrate AS VARCHAR(10)) Remark, 
			(Credit-Debit) AS Amount,
			c.username AS Creator
		FROM dbo.TransferExtra b WITH (NOLOCK)	
			INNER JOIN dbo.Customer c WITH(NOLOCK) ON c.custid = b.Creator
			LEFT JOIN dbo.bettype bt WITH (NOLOCK) ON b.bettype = bt.typeid 
		WHERE b.custID = @CID		
			AND b.winlostdate = @Winlostdate
			AND b.bettype > 30000
		ORDER BY b.TransId
	END

	-- 1.2 Get TransferExtra_bk
	IF @Winlostdate < @balanceUpDay
	BEGIN

		SELECT 
			b.TransDate, 
			bt.typenamee AS transtype, 
			b.transdesc + ' - Ex.Rate: ' + CAST(b.actualrate AS VARCHAR(10)) Remark, 
			(Credit-Debit) AS Amount,
			c.username AS Creator
		FROM bodb_Archive.dbo.TransferExtra_bk b WITH (NOLOCK)	
			INNER JOIN dbo.Customer c WITH(NOLOCK) ON c.custid = b.Creator
			LEFT JOIN dbo.bettype bt WITH (NOLOCK) ON b.bettype = bt.typeid 
		WHERE b.custID = @CID		
			AND b.winlostdate = @Winlostdate
		ORDER BY b.TransId
	END
END
