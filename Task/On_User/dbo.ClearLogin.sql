ALTER PROCEDURE [dbo].[ClearLogin]
AS
/*
	Task:  
	DB: DB03.ON_USER
	Original SP: 	
	Revisions:
		- 20110916@Sophia: Delete table On_User_Agent. Edit Delete WITH (ROWLOCK, UPDLOCK)
	Param's Explanation: 
	
*/

SET NOCOUNT ON
declare @tblCust as table (custid int) -- for nickname statistics  
declare @on_id as table (rn int PRIMARY KEY IDENTITY (1,1), on_userid int)
  
INSERT INTO @on_id (on_userid)
select on_userid
from on_user with (nolock)
where  
(reload_time < dateadd(second,-200,CURRENT_TIMESTAMP) AND (ServerID < 101001) AND (ServerID NOT IN (93, 94, 95)))  
OR  
(reload_time < dateadd(minute,-5,CURRENT_TIMESTAMP) AND (ServerID >= 101001) AND (ServerID NOT IN (101101, 101102, 200101, 201101, 202101, 202102, 206101))) 
OR
(reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP) AND (ServerID IN (101101, 101102, 200101, 201101, 202101, 202102, 206101, 93, 94, 95)))

Declare @rn int, @rn2 int, @xrn int
SELECT @rn = 1, @rn2 = 200, @xrn = MAX(rn)
FROM @on_id

WHILE @rn < @xrn
BEGIN
 DELETE on_user 
 OUTPUT deleted.custid INTO @tblCust -- for nickname statistics  
 FROM on_user WITH (ROWLOCK, UPDLOCK)
  INNER JOIN @on_id x ON on_user.on_userid = x.on_userid
 WHERE
  rn BETWEEN @rn AND @rn2

 SELECT @rn = @rn + 200, @rn2 = @rn2 + 200
END

-- for use NickName login user  
DELETE FROM tmp_Username2 WITH (ROWLOCK, UPDLOCK) WHERE custid in (SELECT custid FROM @tblCust)  

--delete from on_user where reload_time < dateadd(second,-200,CURRENT_TIMESTAMP) AND (ServerID < 101001)
--delete from on_user where reload_time < dateadd(minute,-5,CURRENT_TIMESTAMP) AND (ServerID >= 101001)


DELETE oa
FROM on_user_admin oa WITH (ROWLOCK, UPDLOCK)
WHERE reload_time < dateadd(second,-200,CURRENT_TIMESTAMP)

DELETE ag
FROM on_user_agent ag WITH (ROWLOCK, UPDLOCK)
WHERE 
(reload_time < dateadd(second,-200,CURRENT_TIMESTAMP) AND ServerID NOT IN (93, 94, 95, 96, 97, 98))
OR 
(reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP) AND ServerID IN (93, 94, 95, 96, 97, 98))

SET NOCOUNT OFF
GO
GRANT VIEW DEFINITION ON [dbo].[ClearLogin] TO [vnteam] 