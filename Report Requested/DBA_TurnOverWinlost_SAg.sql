
ALTER PROCEDURE DBA_TurnOverWinlost_SAg
	@Fromdate smalldatetime,
	@Todate smalldatetime,
	@SuperList varchar(200)=''
AS
DECLARE @BalanceUpDay smalldatetime
DECLARE @SAgWinLoss TABLE(CustID int, TurnOver money, Company money,winlostdate smalldatetime)
declare @superid table(srecommend int)

Select @BalanceUpDay = min(winlostdate) from bettrans (nolock)  
insert into @superid 
select custid from custinfo (nolock) 
where username in (select val from dbo.strsplit(@superlist,','))

IF @Todate >= @BalanceUpDay 
BEGIN	
	INSERT INTO @SAgWinLoss
		select
			s.srecommend as custid,			
			sum(stake) as turnover,	
			-(isnull(sum(swinlost), 0) + isnull(sum(awinlost), 0) + isnull(sum(mwinlost), 0) + isnull(sum(scomm), 0) + isnull(sum(winlost-actual_stake), 0)) as Company,			
			convert(smalldatetime,convert(varchar(4),year(winlostdate))+'-'+convert(varchar(2),month(winlostdate))+'-01') as winlostdate
		from 
			dbo.bettrans b with (nolock) inner join @superid s on b.srecommend = s.srecommend			
		where
			winlostdate between @FromDate and @ToDate and
			status not in ('running','waiting','VOID', 'REJECT')  and
			ruben=1 and 
			bettype < 91
		group by 
			s.srecommend,convert(smalldatetime,convert(varchar(4),year(winlostdate))+'-'+convert(varchar(2),month(winlostdate))+'-01')
	if @BalanceUpDay < @FromDate --if this case occurs then there is no data from sum_winloss_old
		select @BalanceUpDay=@FromDate
		
	INSERT INTO @SAgWinLoss
		select			
			s.srecommend as custid,			
			sum(turnover) as turnover,	
			-(isnull(sum(swinlost), 0) + isnull(sum(awinlost), 0) + isnull(sum(mwinlost), 0) + isnull(sum(scomm), 0) + isnull(sum(winlost), 0)) as company	,		
			convert(smalldatetime,convert(varchar(4),year(winlostdate))+'-'+convert(varchar(2),month(winlostdate))+'-01') as winlostdate
		from 
			dbo.sum_winloss b with (nolock) inner join @superid s on s.srecommend = b.srecommend
		where
			winlostdate between @BalanceUpDay and @todate and roleid = 3
		group by 
			s.srecommend,convert(smalldatetime,convert(varchar(4),year(winlostdate))+'-'+convert(varchar(2),month(winlostdate))+'-01')

END
IF @FromDate < @BalanceUpDay 
BEGIN
	if @ToDate >= DATEADD(dd, -1, @BalanceUpDay)
		select @ToDate = DATEADD(dd, -1, @BalanceUpDay)
		
	INSERT INTO @SAgWinLoss
		select				
			s.srecommend as custid, 		
			sum(turnover) as turnover,			
			-(isnull(sum(swinlost), 0) + isnull(sum(awinlost), 0) + isnull(sum(mwinlost), 0) + isnull(sum(scomm), 0) + isnull(sum(winlost), 0)) company,			
			convert(smalldatetime,convert(varchar(4),year(winlostdate))+'-'+convert(varchar(2),month(winlostdate))+'-01') as winlostdate
		from 
			bodb_archive.dbo.Sum_WinLoss_Old b WITH(NOLOCK) inner join @superid s on s.srecommend = b.srecommend
		where
			Winlostdate between @FromDate and @ToDate and roleid = 3
		group by 
			s.srecommend,convert(smalldatetime,convert(varchar(4),year(winlostdate))+'-'+convert(varchar(2),month(winlostdate))+'-01')
END

SELECT
	w.CustID, 
	c.UserName, 
	sum(TurnOver) as TurnOver,	
	sum(Company) as Company,
	winlostdate
FROM @SAgWinLoss w INNER JOIN Customer c WITH(NOLOCK) ON w.CustID = c.CustID 
Group by w.CustID, c.UserName,winlostdate
order by c.Username


GO

GRANT EXECUTE ON [dbo].DBA_TurnOverWinlost_SAg TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].DBA_TurnOverWinlost_SAg TO [bodbAdminNet]
 