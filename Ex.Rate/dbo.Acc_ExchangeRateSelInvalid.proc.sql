ALTER PROCEDURE [dbo].[Acc_ExchangeRateSelInvalid]
	@fromDate	datetime = null output,
	@toDate		datetime = null	
AS
/*
	Created by: 2008@[]
	Task: Show invalid exchange rate 
	DB: DB03.BODB02
	
	Revisions:
		- 20100105@Jamie: Get currency from Cache 
	
*/
	SET NOCOUNT ON
	if @fromDate is null or @toDate is null		
			SELECT @toDate=convert(datetime,convert(varchar(10),getdate(),120)),@fromDate = dateadd(day,-1,@toDate)			
	else
		begin
			SELECT @fromDate=convert(datetime,convert(varchar(10),@fromDate,120))--Reset into 00:00:00
			SELECT @toDate=convert(datetime,convert(varchar(10),@toDate,120))--Reset into 00:00:00
			SELECT @toDate = dateadd(day,1,@toDate) 
		end
	SELECT	a.transdate, 
			c.username as creator, 
			f.username as fromCust, 
			t.username as tocust, 
			a.fromexchangeid,
			a.toexchangeid,
			a.minExRate,
			a.maxExRate, 
			a.exRate as inputExRate,
			a.Amount
	FROM	Acc_ExchangeRate_InvalidTransfer a WITH (NOLOCK)
			INNER JOIN Custinfo c WITH (NOLOCK) ON a.userid = c.custid 
			INNER JOIN Custinfo f WITH (NOLOCK) ON a.fromcust = f.custid 
			INNER JOIN Custinfo t WITH (NOLOCK) ON a.tocust = t.custid 
	WHERE	transdate >= @fromDate and transdate < @toDate and isDeleted = 0
	ORDER BY a.transdate

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateSelInvalid] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateSelInvalid] TO [VNTeam]
GO