ALTER PROCEDURE [dbo].[ExecRep_07]
	@srecommend int,
	@maxbet money,
	@maxpermatch money
AS


if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
    RETURN
END

update custinfo set
    maxpermatch=@maxpermatch,
    maxpermatch2=@maxpermatch,
    maxpermatch3=@maxpermatch,
    maxpermatch5=@maxpermatch,
    maxpermatch8=@maxpermatch,
    maxpermatch10=@maxpermatch,
    maxpermatch11=@maxpermatch,
    maxpermatch99=@maxpermatch where srecommend = @srecommend and roleid = 1


if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
    RETURN
END
update custsetting
    SET maxbet=@maxbet
WHERE custid in (select custid from custinfo ci with (nolock) where ci.srecommend = @srecommend and roleid = 1)
AND sporttype <> 151


GO