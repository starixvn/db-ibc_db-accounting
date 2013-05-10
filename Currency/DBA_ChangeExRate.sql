ALTER PROCEDURE [dbo].[ExecRep_07]	
	@CurrencyName varchar(5)
AS

if NOT exists (select * from dbo.sysobjects where name = 'Exchange')
BEGIN
	RETURN
END

if NOT exists (select * from dbo.sysobjects where name = 'Bettrans')
BEGIN
	RETURN
END

Declare @ExchangeID int, @newRate float, @old_ratio float


select @ExchangeID = ExchangeID, @newRate = actualrate
from Exchange with (nolock) where currency = @CurrencyName

	
Update Bettrans
	SET
        @old_ratio = virtualrate/actualrate,
        actualrate = @newrate,
        virtualrate = case when @old_ratio = 1 then @newrate else @old_ratio * @newrate end
where 
    currency = @ExchangeID
	and actualrate is NOT NULL
	and winlostdate >= convert(varchar(10),getdate(),112)
	
	/*
--command must repeat running

UPDATE dbo.bettrans SET actualrate = e.actualrate, virtualrate = e.actualrate * c.virtualmultiplier

--select distinct b.custid

--select c.username, b.*

FROM dbo.bettrans b with (nolock), dbo.custinfo c with (nolock), dbo.exchange e with (nolock)

WHERE b.custid = c.custid AND b.currency = e.exchangeid AND b.actualrate <> e.actualrate

AND b.winlostdate >= 'UPDATE_DATE' AND b.bettype < 99

AND b.actualrate <> b.virtualrate

 

UPDATE dbo.bettrans SET actualrate = e.actualrate, virtualrate = e.actualrate

FROM dbo.bettrans b with (nolock), dbo.custinfo c with (nolock), dbo.exchange e with (nolock)

WHERE b.custid = c.custid AND b.currency = e.exchangeid AND b.actualrate <> e.actualrate

AND b.winlostdate >= 'UPDATE_DATE' AND b.bettype < 99

AND b.actualrate = b.virtualrate

*/
	 
	