CREATE PROCEDURE [dbo].[DBA_UpdateDisableOutright]

AS
-- Agents are DISABLED Outright but Members are ENABLE Outright
-- Correct data by updating DisableOutright=1 for Members

DECLARE @counter INT
DECLARE @RowsEffected INT
DECLARE @RowsCnt INT
DECLARE @Err INT

SELECT @COUNTER = 1
SELECT @RowsEffected = 0

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

WHILE ( @COUNTER > 0)
BEGIN
    SET ROWCOUNT 1000   

    UPDATE CustInfo WITH (UPDLOCK, ROWLOCK) SET DisableOutright=1 WHERE 
	CustID in (SELECT  mem.Custid   
				FROM custinfo mem (nolock)
					INNER join custinfo a (nolock) ON mem.recommend = a.custid   
				WHERE mem.roleid = 1
					and mem.disableOutright = 0 and a.disableOutright = 1)
   
    SELECT @RowsCnt = @@ROWCOUNT ,@Err = @@ERROR
    IF @Err <> 0
    BEGIN
        PRINT 'Problem Updating the records'
    END

    IF @RowsCnt = 0
        SELECT @COUNTER = 0
    ELSE
        SELECT @RowsEffected = @RowsEffected + @RowsCnt

    PRINT 'The total number of rows effected :'+CONVERT(VARCHAR,@RowsEffected)
    --WAITFOR DELAY '00:00:1'        
 END


--Check if all the records are updated or not .
IF EXISTS ( SELECT 1
			FROM custinfo mem (nolock)
				INNER join custinfo a (nolock) ON mem.recommend = a.custid   
			WHERE mem.roleid = 1
				and mem.disableOutright = 0 and a.disableOutright = 1
)
BEGIN
    PRINT ('All the records are not updated , there is some problems , Contact Devs ')
END
BEGIN
    PRINT ('All the records are updated SUCCESSFULLY !!!!')
END

SET ROWCOUNT 0
