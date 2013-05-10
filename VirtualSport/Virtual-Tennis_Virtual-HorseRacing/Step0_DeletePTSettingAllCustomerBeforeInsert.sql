 ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@mincustid INT,
	@maxcustid INT
AS

BEGIN	
	SET NOCOUNT ON	
	IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CustSetting3rd')
	BEGIN
		WHILE 1 = 1 
		BEGIN
			DELETE TOP(10000) CustSetting3rd WITH(ROWLOCK,UPDLOCK)
			WHERE custid >= @mincustid and custid <= @maxcustid
				and ((bettype = 1220 AND sporttype = 186) OR (bettype = 1231 AND sporttype = 181))
				
			IF @@ROWCOUNT <> 10000
				BREAK
		END
	END
	
	IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CustOverride3rd')
	BEGIN
		WHILE 1 = 1 
		BEGIN
			DELETE TOP(10000) CustOverride3rd WITH(ROWLOCK,UPDLOCK)
			WHERE custid >= @mincustid and custid <= @maxcustid
				and ((bettype = 1220 AND sporttype = 186) OR (bettype = 1231 AND sporttype = 181))		
			
			IF @@ROWCOUNT <> 10000
				BREAK
		END
	END	
	
	IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'Dep_CustSetting3rd')
	BEGIN
		WHILE 1 = 1 
		BEGIN
			DELETE TOP(10000) Dep_CustSetting3rd WITH(ROWLOCK,UPDLOCK)
			WHERE custid >= @mincustid and custid <= @maxcustid
				and ((bettype = 1220 AND sporttype = 186) OR (bettype = 1231 AND sporttype = 181))
			
			IF @@ROWCOUNT <> 10000
				BREAK
		END
	END	
	
END
GO
/*
-- select max(custid) from custinfo with(nolocK)
DECLARE @mincustid INT,@maxcustid INT
SELECT @mincustid= 0,
	@maxcustid= xxxxx --8414563

EXEC dbo.Acc_ExecRep_09 @mincustid = @mincustid, @maxcustid=@maxcustid
*/
