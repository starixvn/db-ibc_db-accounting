ALTER PROCEDURE [dbo].[ExecRep_07]
	@AgentID int	
AS

if exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	delete custsetting where custid
                IN (select custid
                    from custinfo with (nolock)
                    where roleid = 1 and recommend = @AgentID) 
END

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

--delete all related member's infomation:
delete custinfo where roleid = 1 and recommend = @AgentID
                    
delete customer where roleid = 1 and recommend = @AgentID
