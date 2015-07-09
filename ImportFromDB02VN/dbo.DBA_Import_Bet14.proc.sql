ALTER PROCEDURE [dbo].[DBA_Import_Bet14]
	@StrCurrency varchar(200) = '3,20',
	@IsMain bit,
	@Istest bit = 1
AS
if @@servername = 'DWDBG1S' and @IsMain = 0
	Return

if @@servername <> 'DWDBG1S' and @IsMain = 1
	Return

IF @IsTest = 1
	Print 'Delete bet14'
ELSE
	Exec DBA_Import_Bet14_Delete @IsMain = @IsMain

Exec DBA_Import_Odds14 @Istest = @Istest,@IsMain = @IsMain

------------------------------------------------------

DECLARE  @minDate smalldatetime, @maxDate smalldatetime
select @minDate = min(winlostdate), @maxDate = max(winlostdate)
from DB02VN.bodb02_tmp.dbo.bettrans14 with (nolock)

DECLARE @splitter varchar(3)

select @splitter = ','

if substring (@StrCurrency, len(@StrCurrency), 1) <> @splitter
	set @StrCurrency = @StrCurrency + @splitter

declare @start int, @currency varchar(100), @charindex int, @countDate smalldatetime
set @start=1
set @charindex= charindex( @splitter, @StrCurrency, @start)

while (@charindex <> 0)
begin
	set @currency= substring( @StrCurrency, @start, @charindex - @start)
	set @start= @charindex +1
	set @charindex= charindex( @splitter, @StrCurrency, @start)
	set @countDate = @mindate
	
	while (@countDate <= @maxDate)
	BEGIN
		
		Exec DBA_Import_Bet14_Bettrans14 @Istest = @Istest,@currency = @currency, @winlostdate = @countDate, @IsMain = @IsMain
		Exec DBA_Import_Bet14_Bettransm14 @Istest = @Istest,@currency = @currency, @winlostdate = @countDate, @IsMain = @IsMain
		--Exec DBA_Import_Bet14_sum_winloss @currency = @currency, @winlostdate = @countDate, @IsMain = @IsMain
		select @countDate = @countDate + 1
	END
end

Exec DBA_Import_Bet14_sum_winloss @Istest = @Istest,@IsMain = @IsMain

