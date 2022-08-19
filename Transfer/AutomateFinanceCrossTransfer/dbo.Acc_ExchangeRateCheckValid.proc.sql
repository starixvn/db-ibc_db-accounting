/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeRateCheckValid] 
	@FromExchangeID	int,
	@ToExchangeID	int,
	@ExchangeRate	float,
	@UserID			int = 0,
	@FromCust		int = 0,
	@ToCust			int = 0,
	@Amount			money = 0,
	@transDate		datetime,
	@refNo			bigint = 0,
	@ErrCode		int = 0 OUTPUT,
	@ErrMsg			nvarchar(200) = '' OUTPUT
AS
/*
	Created: N/A
	Task : 
	DB: DBTXN/bodb02

	Revisions:
		- 20180808@Helen: DB05.DBPOLICY migration -  Move to DBTRANS [Redmine:99462]		
		- 20220818@Danny: change code to handle duplicate data problem [Redmine: #175253]
*/
BEGIN
	SET NOCOUNT ON
	BEGIN TRY

		DECLARE @rowcount tinyint 
		DECLARE	@xMin smallmoney, @xMax smallmoney
		DECLARE @MinExchangeRate money, @MaxExchangeRate money
		DECLARE @FromActualRate float, @ToActualRate float, @ActualRate float

		SELECT @FromActualRate = actualrate FROM CustDB.dbo.exchange with (nolock) where exchangeid = @FromExchangeID
		SELECT @ToActualRate = actualrate FROM CustDB.dbo.exchange with (nolock) where exchangeid = @ToExchangeID
		   
		/*--	@Actualrate = x/y  (A->B)  --*/
		SET	@ActualRate = @FromActualRate/@ToActualRate  

		SELECT	@xMin = MinActualRate,
				@xMax = MaxActualRate
		FROM Acc_ExchangeRate with(nolock) 
		WHERE FromExchangeID = @FromExchangeID and ToExchangeID = @ToExchangeID

		SET	@rowcount = @@rowcount 
		IF @rowcount = 0 
		BEGIN 
			SELECT	@xMin = MinActualRate,
					@xMax = MaxActualRate
			FROM Acc_ExchangeRate with(nolock) 
			WHERE FromExchangeID = @ToExchangeID and ToExchangeID = @FromExchangeID	
			IF @@rowcount = 0 RETURN
		END 

		/*	x1 = x/y*(1-xmin)
			x2 = x/y*(1+xmax)
		*/
		SET @MinExchangeRate = @Actualrate *(1 - @xMin)
		SET @MaxExchangeRate = @Actualrate *(1 + @xMax)

		IF ((@ExchangeRate < @MinExchangeRate) OR  (@ExchangeRate > @MaxExchangeRate))
		AND NOT EXISTS (SELECT 1 FROM Acc_ExchangeRate_InvalidTransfer WITH(NOLOCK) WHERE refno = @refNo AND  FromCust = @FromCust AND  ToCust = @ToCust AND  Amount = @Amount)
		BEGIN
			--Write Log
			INSERT INTO Acc_ExchangeRate_InvalidTransfer(TransDate,UserID,FromCust,ToCust,FromExchangeID,ToExchangeID,
														 Rate,MinExRate,MaxExRate,ExRate,Amount,refNo,isDeleted)
			VALUES (@transDate,@UserID, @FromCust, @ToCust, @FromExchangeID, @ToExchangeID,
					@Actualrate, @MinExchangeRate, @MaxExchangeRate,@ExchangeRate, @Amount, @refNo,0)
		END	
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = 'Exchange Rate Check Valid Faied.', @ErrCode = 103		
	
	END CATCH
END 
GO
