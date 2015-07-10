set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[HR_Settle_200901]--by race
	@leagueid  int,--meeting	
	@raceNumber varchar(10),--race	
	@eventdate  datetime
AS

--======================================================
--Settlement for Horseracing
--Simulate only, the real settlement is from Phumelela
--======================================================

--results format: 
--Position:	 01   02   03   04  
--HorseNo:  '05','07','09','15',...
declare @race varchar(10)
select  @race = @raceNumber
declare 
	@orid int, @HorseCount int, @c int, @Results varchar(2000),
	@First int, @Second int, @Third int, @ThirdNo int, @dividendWin smallmoney, @dividendPlace smallmoney,
	@TurnOver money, @WinBetCount int, @dividend float ,@tax smallmoney, @phum smallmoney 
--SELECT @tax = 0.2  --- suppose 20% for goverment tax and comm 
--SELECT @phum = 1 - @tax 
select @eventdate = convert(varchar(10),@eventdate,120 )

if not exists(select 1 from league with (nolock) where leagueid= @leagueid and sporttype = 151) return
select @HorseCount = count(1) from outright with (nolock) where groupmatch = @race and leagueid= @leagueid and matchcode <> 'HRDummy'

if @Results <> ''
BEGIN
	if (@HorseCount <> (select count(1) from dbo.StrSplit(@Results, ','))) return --invalid results
END
else--simulate result if not indicate
BEGIN
	select @Results = ''
	select @Results = @Results + matchcode + ',' 
	from  outright 
	where groupmatch = @race and leagueid= @leagueid and matchcode <> 'HRDummy'
	ORDER BY matchcode
END

--delete dummy trans to avoid settle on dummy trans
delete bettrans where matchid IN(select orid from outright with (nolock) where leagueid= @leagueid and groupmatch = @race and matchcode = 'HRDummy')


select @c = 1
WHILE(@c <= @HorseCount)
BEGIN
	select @orid = orid from outright 
	where groupmatch = @race and leagueid= @leagueid and matchcode = dbo.Acc_SplitIndex(@Results, ',', @c)
	
	if @c < 4 --record orid of 1,2,3 position and horseNo of 3rd
	BEGIN
		select @First = case when @c=1 then @orid else @First end
		select @Second = case when @c=2 then @orid else @Second end
		select @Third = case when @c=3 then @orid else @Third end		
		select @ThirdNo = case when @c=3 then matchcode else @ThirdNo end from outright with (nolock) where orid = @orid
		
		update outright set placing = @c where orid = @orid  ---update position 
	END
	--update horse position
	update outright set oddsstatus = 'closed', status = 'OFFICIAL'  
	where orid = @orid

	select @c = @c + 1
END


---SETTLE 
	EXEC dbo.[HR_Calculate_viaLeague]     @leagueid, @raceNumber, @eventdate
	EXEC dbo.[HR_DummyTransfer_viaLeague] @leagueid, @raceNumber, @eventdate

	UPDATE dbo.Outright
	SET oddsstatus = 'completed'
	WHERE
		leagueid = @leagueid
		AND groupmatch = @raceNumber
		AND eventdate = @eventdate
		AND oddsstatus = 'closed'

	-- Code to Log Message put here
	Declare @LogData as nvarchar(300)
	SET @LogData = 'Calculate Result for Horse ID:' + cast (@leagueid as varchar(20))+ ' race:' + @raceNumber 
	EXEC dbo.logfile 151, @LogData