 ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@mincustid INT,
	@maxcustid INT
AS

BEGIN	
	SET NOCOUNT ON	
	IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CustSetting3rd')
	BEGIN
		DELETE CustSetting3rd WITH(ROWLOCK,UPDLOCK)
		WHERE custid >= @mincustid and custid <= @maxcustid
			and ((bettype = 1220 AND sporttype = 186) OR (bettype = 1231 AND sporttype = 181))								
	END
	
	IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CustOverride3rd')
	BEGIN
		DELETE CustOverride3rd WITH(ROWLOCK,UPDLOCK)
		WHERE custid >= @mincustid and custid <= @maxcustid
			and ((bettype = 1220 AND sporttype = 186) OR (bettype = 1231 AND sporttype = 181))		
	END	
	
	--IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'Dep_CustSetting3rd')
	--BEGIN
	--	DELETE Dep_CustSetting3rd WITH(ROWLOCK,UPDLOCK)
	--	WHERE custid >= @mincustid and custid <= @maxcustid
	--		and ((bettype = 1220 AND sporttype = 186) OR (bettype = 1231 AND sporttype = 181))
	--END	
	
END
GO
/*
DECLARE @mincustid INT,@maxcustid INT
SELECT @mincustid= 0
select @maxcustid = max(custid) from custinfo with(nolocK)
EXEC dbo.Acc_ExecRep_09 @mincustid = @mincustid, @maxcustid=@maxcustid
*/
