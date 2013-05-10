ALTER PROCEDURE [dbo].[DBA_Import_Bet]
	@StrCurrency varchar(200) = '20',
	@IsMain bit,
	@Istest bit = 1
AS

if @IsTest = 1 
	Print 'Delete bets'
else
	Exec DBA_Import_Bet_Delete @IsMain = @IsMain

------------------------------------------------------
DECLARE @splitter varchar(3)

select @splitter = ','

if substring (@StrCurrency, len(@StrCurrency), 1) <> @splitter
	set @StrCurrency = @StrCurrency + @splitter

declare @start int, @currency varchar(100), @charindex int
set @start=1
set @charindex= charindex( @splitter, @StrCurrency, @start)

while (@charindex <> 0)
begin
	set @currency= substring( @StrCurrency, @start, @charindex - @start)
	set @start= @charindex +1
	set @charindex= charindex( @splitter, @StrCurrency, @start)
	Exec DBA_Import_Bet_Bettrans @Istest = @Istest,@currency = @currency, @IsMain = @IsMain
	Exec DBA_Import_Bet_zzzbettrans @Istest = @Istest,@currency = @currency, @IsMain = @IsMain
	
end

Exec DBA_Import_Bet_Bettransm @Istest = @Istest,@IsMain = @IsMain

	
	

------------------------------------------------------
