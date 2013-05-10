ALTER PROCEDURE [dbo].[Task_Acc_ExchangeDaily_Check]
@InputDate datetime
AS
/*
Created: Henry
Task : Check the table ExchangeDaily for yesterday + the day before yesterday insertion
DB: DB052.bodb02
Revisions:
	-  20110322@Henry: add one more base currency: CNY
	- 20120427@Henry: check data from new table ExchangeDailyOanda instead of ExchangeDaily
*/		
SET NOCOUNT ON

declare @error varchar(1000)


if exists(
select 1 
from exchange (nolock)
where 
	isnull(Code,'') <> ''and 
	exchangeid not in (
	select exchangeid from ExchangeDailyOanda (nolock)
	where exchangedate = @InputDate
	)
)
--raise error if not exist
begin
	set @error = 'One or some of the ExchangeId of table Exchange could not get inserted to table ExchangeDailyOanda for job on date: ' + Cast(@InputDate  as varchar(50)) 
	RAISERROR(@error,16,1)
end
-- 2 check value
if exists(
select 1 from ExchangeDailyOanda (nolock)
	where 
		exchangedate = @InputDate and 
		(isnull(Code,'') = ''
		OR isnull(MYR,0) = 0
		OR isnull(USD,0) = 0
		OR isnull(EUR,0) = 0
		OR isnull(CNY,0) = 0
		)	
)
begin
	set @error = 'One or some values of table ExchangeDailyOanda could not get inserted properly for job on date: ' + Cast(@InputDate  as varchar(50))
	RAISERROR(@error,16,1)
end



	


GO
GRANT VIEW DEFINITION ON [dbo].[Task_Acc_ExchangeDaily_Check] TO [vnteam]