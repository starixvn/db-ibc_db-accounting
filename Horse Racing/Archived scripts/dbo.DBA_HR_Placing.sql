ALTER PROCEDURE dbo.DBA_HR_Placing
@programid		varchar(20),
@raceNumber		int,
@eventdate		datetime,
@Results		varchar(1000)=''
AS 
BEGIN 

--select  @programid ='XGD'
--        ,@raceNumber='8'
--		,@eventdate ='2009-01-28 00:00:00'

	declare 
		@orid int, @HorseCount int, @c int, 
		@First int, @Second int, @Third int, @ThirdNo int, @dividendWin smallmoney, @dividendPlace smallmoney,
		@TurnOver money, @WinBetCount int, @dividend float ,@tax smallmoney, @phum smallmoney 

	select @eventdate = convert(varchar(10),@eventdate,120 )

	if not exists(select 1 from outright with (nolock) where programid = @programid and groupmatch = CAST(@raceNumber as varchar(20)) and eventdate = @eventdate ) return
	select @HorseCount = count(1) from outright with (nolock) where groupmatch = CAST(@raceNumber as varchar(20)) and programid= @programid and eventdate = @eventdate 
	select @HorseCount

	if @Results <> ''
	BEGIN
		if (@HorseCount < (select count(1) from dbo.StrSplit(@Results, ','))) return --invalid results
	END
	else--simulate result if not indicate
	BEGIN
		select @Results = ''
		select @Results = @Results + matchcode + ',' 
		from  outright 
		where groupmatch = CAST(@raceNumber as varchar(20)) and programid = @programid and eventdate = @eventdate 
		ORDER BY matchcode
	END

	select @c = 1
	WHILE(@c <= @HorseCount)
	BEGIN
		select @orid = orid from outright 
		where groupmatch = CAST(@raceNumber as varchar(20)) and programid = @programid and matchcode = dbo.Acc_SplitIndex(@Results, ',', @c)
		and eventdate = @eventdate and isnull(isSCR,0) <>1
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
	update	outright set odds = 0,  placeOdds = 0 
	where	groupmatch = CAST(@raceNumber as varchar(20)) and 
			programid = @programid and  
			eventdate = @eventdate and 
			isnull(placing,0) =0 
	update outright set odds = 0 ,oddsstatus ='closed'
	where	groupmatch = CAST(@raceNumber as varchar(20)) and 
			programid = @programid and  
			eventdate = @eventdate and 
			isnull(placing,0) <> 1 
END 