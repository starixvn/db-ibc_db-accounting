Alter PROCEDURE [dbo].[HRAPI_TurnoverInsAg]
	@Agentid int,
	--@Date smalldatetime,
	@Currency smallint,	
	@BetCount int,	
	@BetAmount money,	
	@BalanceAmount money,
	@FinalReturnAmount Money,
	@Desc varchar(200),
	@IsDone bit
AS
--DB06.bodb02
declare @Date smalldatetime
select @Date = convert(varchar(10), current_timestamp, 120)

if exists(select 1 from HRTurnover with (nolock) where Agentid = @Agentid and [Date] = @Date)
begin
	update HRTurnover with (updlock,rowlock) 
	set Currency = @Currency,		
		BetAmount = @BetAmount,	
		BetCount = @BetCount,
		BalanceAmount = @BalanceAmount,
		FinalReturnAmount = @FinalReturnAmount,
		[Desc] = @Desc,
		IsDone = @IsDone
	where Agentid = @Agentid and [Date] = @Date
	return
end

insert into HRTurnover([AgentId]
      ,[Date]
      ,[Currency]      
      ,[BetCount]
      ,[BetAmount]
      ,[BalanceAmount]
      ,[FinalReturnAmount]
      ,[Desc]
      ,[IsDone])
values(@Agentid,
	@Date,
	@Currency,
	@BetCount,
	@BetAmount,	
	@BalanceAmount,
	@FinalReturnAmount,
	@Desc,
	@IsDone)

Go
GRANT EXECUTE ON [dbo].[HRAPI_TurnoverInsAg] TO [bodbAdminNet]
