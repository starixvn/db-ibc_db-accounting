USE [ON_USER]
GO
/****** Object:  StoredProcedure [dbo].[SumUser]    Script Date: 09/14/2011 05:38:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SumUser]
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

DELETE FROM on_user_sum WITH (ROWLOCK)

Declare @sum TABLE (ServerID int, CNT int)
INSERT INTO @sum
SELECT IsNull(s.ServerID,o.ServerID) S_ID, COUNT(DISTINCT o.custid) CNT
FROM ServerLists s (nolock)
FULL OUTER JOIN on_user o with (nolock)
ON s.ServerID = o.ServerID
GROUP BY IsNull(s.ServerID,o.ServerID)

INSERT INTO @sum
SELECT IsNull(s.ServerID,o.ServerID) S_ID, COUNT(DISTINCT o.custid) CNT
FROM ServerLists s (nolock)
FULL OUTER JOIN on_user_admin o with (nolock)
ON s.ServerID = o.ServerID
GROUP BY IsNull(s.ServerID,o.ServerID)

INSERT INTO @sum
SELECT IsNull(s.ServerID,o.ServerID) S_ID, COUNT(DISTINCT o.custid) CNT
FROM ServerLists s (nolock)
FULL OUTER JOIN on_user_agent o with (nolock)
ON s.ServerID = o.ServerID
GROUP BY IsNull(s.ServerID,o.ServerID)

INSERT INTO on_user_sum
SELECT ServerID, SUM(CNT)
FROM @sum
GROUP BY ServerID
--------

 Declare @m_total TABLE (MachineID int, cnt money)
 INSERT INTO @m_Total
 SELECT sl.MachineID, SUM(ous.TotalOnline) cnt
  FROM on_user_sum ous with (nolock)
  INNER JOIN ServerLists sl with (nolock) ON ous.ServerID = sl.ServerID
  GROUP BY sl.MachineID

 Declare @s_vs_m TABLE (ServerID int, Site nvarchar(50), URL nvarchar(50), MaxUser money, cnt money)
 INSERT INTO @s_vs_m
 SELECT sl.ServerID, sl.Site, sl.URL, sl.MaxUser, m.cnt
  FROM ServerLists sl with (nolock)
  INNER JOIN @m_Total m ON sl.MachineID = m.MachineID
  WHERE sl.Enabled = 1

 Declare @Site nvarchar(50), @ServerID int, @URL nvarchar(50)
 Declare s_cursor CURSOR FOR select distinct site FROM ServerLists with (nolock) WHERE Enabled = 1
 OPEN s_cursor
 FETCH NEXT FROM s_cursor INTO @Site
 WHILE (@@FETCH_STATUS = 0)
 BEGIN
  SELECT TOP 1 @ServerID = ServerID, @URL = URL FROM @s_vs_m WHERE Site = @Site ORDER BY (cnt-MaxUser)/(MaxUser+1)
  IF @@ROWCOUNT > 0
  BEGIN
   UPDATE dbo.LoadBalance WITH (rowlock, updlock) SET ServerID = @ServerID, URL = @URL WHERE Site = @Site
   IF @@ROWCOUNT = 0 INSERT INTO dbo.LoadBalance (Site, ServerID,  URL) VALUES (@Site, @ServerID, @URL)
  END

  FETCH NEXT FROM s_cursor INTO @Site
 END
 CLOSE s_cursor
 DEALLOCATE s_cursor

GO
GRANT VIEW DEFINITION ON [dbo].[SumUser] TO [vnteam]