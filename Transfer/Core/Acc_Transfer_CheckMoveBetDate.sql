/*<info serverAlias="DBTXN-bodb02,DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_Transfer_CheckMoveBetDate] 
	@MoveBetDate DATE,
	@IsDiff BIT = 0 OUTPUT,
	@NewMoveBetDate DATE = NULL OUTPUT
AS
/*
	Created: 20210512@Sol
	Task: Check move bet date if there is any change or not
	DB: DBTXN.bodb02/DBAGE.bodb02
	Revisions:	
		- 20210512@Sol: Check move bet date - [Redmine: #149927]

	Param explaination:
		@IsDiff: 0 - the same value
				 1 - different value

*/
BEGIN 
	
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay DATE, MoveBetsDay DATE)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	IF EXISTS (SELECT 1 FROM @tblMoveBetBalanceUp t WHERE t.MoveBetsDay <> @MoveBetDate)
	BEGIN
		SELECT @IsDiff = 1, @NewMoveBetDate = t.MoveBetsDay
		FROM @tblMoveBetBalanceUp t
	END
	ELSE
		SET @IsDiff = 0

END 
GO
 
  


   