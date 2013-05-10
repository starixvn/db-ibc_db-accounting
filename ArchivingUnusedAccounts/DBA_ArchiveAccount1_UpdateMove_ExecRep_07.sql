ALTER PROCEDURE [dbo].[ExecRep_07]
	@AgentID int	
AS

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

update custinfo set enabled = 0, closed = 1 where recommend = @AgentID


if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

delete custsetting where custid
                IN (select custid
                    from custinfo with (nolock)
                    where roleid = 1 and recommend = @AgentID)
                    AND NOT (
        (sporttype = 1 and bettype = 1)
        or (sporttype = 1 and bettype = 4)
        or (sporttype = 1 and bettype = 5)
        or (sporttype = 151 and bettype = 31)
        or (sporttype = 151 and bettype = 41)
        or (sporttype = 201 and bettype = 3)
        )