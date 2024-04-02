/*<info serverAlias="DBTXN-bodb02,DBAGE-bodb02,DBEXT-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView,wsv_nap,wsv_alp,wsv_xnap,wsv_alpv" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ReCheck_MBUDate] 
	@MBDate SMALLDATETIME,
	@BUDate SMALLDATETIME,
	@IsDiff SMALLINT = 0 OUTPUT,
	@NewMBDate SMALLDATETIME = NULL OUTPUT,
	@NewBUDate SMALLDATETIME = NULL OUTPUT
AS
/*
	Created: 20230406@Evan
	Task: Check move bet, balance up date if there is any change or not
	DB: DBTXN.bodb02/DBAGE.bodb02
	Revisions:	
		- 20230406@Evan: initial SPs [Redmine: #173554]
		- 20240312@Bobby: EC enhancement [Redmine: #202276]
		
	Param explaination:
		@IsDiff: 0 - the same value
				 1 - different value

*/
BEGIN 
	SET NOCOUNT ON;

	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @NewMBDate OUTPUT
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @NewBUDate OUTPUT

	IF @NewBUDate IS NULL
	BEGIN
		SET @IsDiff = -1
		RETURN
	END

	IF (@MBDate < @NewMBDate OR @BUDate < @NewBUDate) AND @NewMBDate IS NOT NULL
	BEGIN
		SET @IsDiff = 1
	END
	ELSE
		SET @IsDiff = 0

END 
