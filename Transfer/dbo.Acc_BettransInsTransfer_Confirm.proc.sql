ALTER PROCEDURE [dbo].[Acc_BettransInsTransfer_Confirm]
	@FromUsername varchar(50),
	@ToUsername varchar(50),
	@ExchangeRate float,
	@FromCurrency varchar(30) OUTPUT,
	@ToCurrency varchar(30) OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E'
AS
/*
Created: 
Task : Check constrans before transferring money
DB: DB053.bodb02
Revisions:
						
Parameters Explanation:
	
*/
SET NOCOUNT ON

Select @FromCurrency = e.currency 
FROM customer c with (nolock)
	inner join exchange e with (nolock) on c.currency = e.exchangeid
WHERE c.username = @FromUsername

Select @ToCurrency = e.currency 
FROM customer c with (nolock)
	inner join exchange e with (nolock) on c.currency = e.exchangeid
WHERE c.username = @ToUsername

if @FromCurrency = @ToCurrency and @ExchangeRate <> 1
BEGIN
	Select @ErrMsg = 'Same currency but different exchange rate? (Exchange rate: '+ cast(cast(@ExchangeRate as decimal(10,4)) as varchar(20)) +')',
		@ErrCode = 101
	return
END
else if @FromCurrency <> @ToCurrency and @ExchangeRate = 1
BEGIN
	Select @ErrMsg = 'Different currency but same exchange rate? (Exchange rate: '+ cast(cast(@ExchangeRate as decimal(10,4)) as varchar(20)) +')',
		@ErrCode = 102
	return
END
else if @FromCurrency <> @ToCurrency
BEGIN
	Select @ErrMsg = 'This is a cross currency exchange rate. Please confirm the exchange rate: (Exchange rate: '+ cast(cast(@ExchangeRate as decimal(10,4)) as varchar(20)) +')',
		@ErrCode = 103
	return
END
GO
GRANT EXECUTE ON [dbo].[Acc_BettransInsTransfer_Confirm] TO [bodbAdminNet]