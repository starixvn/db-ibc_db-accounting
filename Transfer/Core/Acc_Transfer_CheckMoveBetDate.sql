/*<info serverAlias="DBTXN-bodb02,DBAGE-bodb02,DBEXT-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_Transfer_CheckMoveBetDate] 
	@MoveBetDate SMALLDATETIME,
	@IsDiff BIT = 0 OUTPUT,
	@NewMoveBetDate SMALLDATETIME = NULL OUTPUT
AS
/*
	Created: 20210512@Sol
	Task: Check move bet date if there is any change or not
	DB: DBTXN.bodb02/DBAGE.bodb02
	Revisions:	
		- 20210512@Sol: Check move bet date - [Redmine: #149927]
		- 20210812@Sol: Enhance sps of setting related to new MB core - [Redmine: #160074]

	Param explaination:
		@IsDiff: 0 - the same value
				 1 - different value

*/
BEGIN 
	
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @NewMoveBetDate = MoveBetsDay FROM @tblMoveBetBalanceUp
	
	IF @NewMoveBetDate IS NOT NULL AND @MoveBetDate < @NewMoveBetDate
	BEGIN
		SET @IsDiff = 1
	END
	ELSE
		SET @IsDiff = 0

END 
GO
 
  


   