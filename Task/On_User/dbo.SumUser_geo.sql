  
ALTER PROCEDURE [dbo].[sumuser_geo]
AS

/*
	Task:  
	DB: DB03.ON_USER
	Original SP: 	
	Revisions:
		- 20110916@Sophia: add table On_User_Agent.  
	Param's Explanation: 
	
*/
SET NOCOUNT ON

Declare @m_total TABLE (MachineIP int, cnt money)  
 INSERT INTO @m_total (MachineIP, CNT)
 SELECT s.MachineIP, COUNT(DISTINCT o.custid) CNT  
 FROM dbo.ServerLists2 s (nolock)  
 LEFT OUTER JOIN dbo.on_user o (nolock)  
 ON s.MachineIP = o.MachineIP  
 GROUP BY s.MachineIP 

 INSERT INTO @m_total (MachineIP, CNT)
 SELECT s.MachineIP, COUNT(DISTINCT o.custid) CNT  
 FROM dbo.ServerLists2 s (nolock)  
 LEFT OUTER JOIN dbo.on_user_admin o (nolock)  
 ON s.MachineIP = o.MachineIP  
 GROUP BY s.MachineIP 

 INSERT INTO @m_total (MachineIP, CNT)
 SELECT s.MachineIP, COUNT(DISTINCT o.custid) CNT  
 FROM dbo.ServerLists2 s (nolock)  
 LEFT OUTER JOIN dbo.on_user_agent o (nolock)  
 ON s.MachineIP = o.MachineIP  
 GROUP BY s.MachineIP 
  
Declare @s_vs_m TABLE (MachineIP int, countryGroup tinyint, URL varchar(50), MaxUser money, cnt money)  
 INSERT INTO @s_vs_m  
 SELECT sl.MachineIP, sl.countryGroup, sl.URL, sl.MaxUser, m.cnt  
 FROM dbo.ServerLists2 sl with (nolock)  
 INNER JOIN @m_Total m ON sl.MachineIP = m.MachineIP  
 WHERE sl.Enabled = 1  
  
Declare @countryGroup tinyint, @MachineIP int, @URL varchar(50)  
Declare s_cursor CURSOR FOR select countryGroup FROM dbo.geoGroup with (nolock)

Declare @Mesg varchar(1000)
SET @Mesg = ''

OPEN s_cursor  
FETCH NEXT FROM s_cursor INTO @countryGroup  
WHILE (@@FETCH_STATUS = 0)  
BEGIN  
 SELECT TOP 1 @MachineIP = MachineIP, @URL = URL
 FROM @s_vs_m WHERE countryGroup = @countryGroup
 ORDER BY (cnt-MaxUser)/(MaxUser+1)  

 IF @@ROWCOUNT > 0  
 BEGIN  
  UPDATE dbo.LoadBalance WITH (rowlock, updlock)
  SET ServerID = @MachineIP, URL = @URL
  WHERE [Site] = CAST(@countryGroup as varchar(10))

  IF @@ROWCOUNT = 0
   INSERT INTO dbo.LoadBalance ([Site], ServerID,  URL)
   VALUES (@countryGroup, @MachineIP, @URL)

  SET @Mesg = @Mesg + CAST(@countryGroup as varchar(2)) + ':' + CAST(@MachineIP as varchar(6)) + ':' + @URL + CHAR(13)
 END  

 FETCH NEXT FROM s_cursor INTO @countryGroup  
END  
CLOSE s_cursor  
DEALLOCATE s_cursor  

PRINT @Mesg

--SELECT * FROM LoadBalance
GO
GRANT VIEW DEFINITION ON [dbo].[sumuser_geo] TO [vnteam] 