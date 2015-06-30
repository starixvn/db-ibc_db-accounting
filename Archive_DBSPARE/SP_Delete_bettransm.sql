ALTER PROCEDURE [dbo].[DBA_DelBettransm]
    @winlostdate smalldatetime
AS

if @winlostdate >= '2009-01-01' --to prevent mistake
    RETURN
    
Declare @RowsEffected int
Declare @RowsCnt int

SELECT @RowsEffected = 0

SET NOCOUNT ON
WHILE 1=1
BEGIN
    DELETE TOP(5000) FROM Bettransm where
        winlostdate between @winlostdate and dateadd(mi, 1439, @winlostdate) -- plus '23:59:00'
    
	SELECT @RowsCnt = @@ROWCOUNT
	SELECT @RowsEffected = @RowsEffected + @RowsCnt   

	IF @RowsCnt < 5000
        BREAK

END
SET NOCOUNT OFF
print convert(varchar(20), @winlostdate,0) + '-' + convert(varchar(20), dateadd(mi, 1439, @winlostdate),0) + ' - '+ convert(varchar,@RowsEffected) 
GO
