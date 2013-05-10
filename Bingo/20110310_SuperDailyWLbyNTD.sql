 DECLARE @SuperList TABLE (srecommend INT)
 
 INSERT INTO @SuperList
 SELECT custid FROM custinfo (nolock) WHERE currency=17 and roleid=4
AND username NOT LIKE '3rd%'
AND username NOT LIKE '%TEST%'

--select * from @SuperList
 
 SELECT Username ,
SUM(turnover) turnover,
SUM(grosscomm) grosscomm,
SUM(winlost) memberWinlost,
SUM(playercomm) membercomm,
isnull(SUM(winlost), 0) + isnull(SUM(playercomm), 0) membertotal,
SUM(awinlost) agentwinlost, -- AgWinlost
isnull(SUM(comm-playercomm),0) agentcomm, --AgComm
isnull(SUM(awinlost+comm-playercomm), 0) agenttotal, --AgTotal   
SUM(mwinlost) masterwinlost,
SUM(acomm)-SUM(comm) mastercomm,
isnull(SUM(mwinlost), 0) + isnull(SUM(acomm), 0)-SUM(comm) mastertotal,
SUM(swinlost) superwinlost,
isnull(SUM(scomm),0) -isnull(SUM(acomm),0) supercomm,
isnull(SUM(swinlost), 0) + isnull(SUM(scomm), 0)-SUM(acomm) supertotal,
-(isnull(SUM(swinlost), 0) + isnull(SUM(awinlost), 0) + isnull(SUM(mwinlost), 0) + isnull(SUM(scomm), 0) + isnull(SUM(winlost), 0)) Company                   
 FROM dbo.sum_winloss WITH (nolock)
 WHERE srecommend in (SELECT * FROM @SuperList)
    and winlostdate between '2011-02-28' and '2011-03-06'
    and sporttype in (161,252)
    and roleid=4
 GROUP BY Username


 

