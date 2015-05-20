ALTER PROCEDURE [dbo].[ExecRep_07]
	@username varchar(50)
AS

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

Declare @custid int,@roleid tinyint

select @custid = custid, @roleid = roleid from custinfo with (nolock) where username = @username

if (@roleid not in (4)) 
    RETURN

update custinfo
set disableHorseracing = 0
where srecommend = @custid