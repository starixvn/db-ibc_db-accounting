ALTER PROCEDURE [dbo].[Task_BalanceUp_TriggerControl]
	@step tinyint,
	@on	bit
AS
	IF @step = 1 AND @on = 1 ENABLE  TRIGGER step1_change_winlostdate ON dbo.balanceTable_tmp
	IF @step = 1 AND @on = 0 DISABLE TRIGGER step1_change_winlostdate ON dbo.balanceTable_tmp

	IF @step = 2 AND @on = 1 ENABLE  TRIGGER step2_balance_insert ON dbo.balanceTable_tmp
	IF @step = 2 AND @on = 0 DISABLE TRIGGER step2_balance_insert ON dbo.balanceTable_tmp


WAITFOR DELAY '000:00:04.000'

GO
GRANT VIEW DEFINITION ON [dbo].[Task_BalanceUp_TriggerControl] TO [vnteam] AS [dbo]