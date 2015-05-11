CREATE PROCEDURE [dbo].[DBA_UpdCSSyncCase2]

AS
--SYNC=0 in IBC DB, but EXIST and DISABLE in casino db
-- Correct data by updating SYNC=1 and DISABLE=1 in IBC DB

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

    UPDATE CustInfo WITH (UPDLOCK, ROWLOCK) SET SyncCasino=1, DisableCasino=1 WHERE 
	CustID in ( SELECT ibc.CustID FROM CustInfo ibc WITH (nolock)
				inner join DBCasino.CasinoAdmin.dbo.Customer cas WITH (nolock)
				on ibc.custid = cas.IBCCustID
				and ibc.enabled=1
				and ibc.currency<>20
				and ibc.SyncCasino=0
				and cas.EnableCasino=0)
   
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
    WAITFOR DELAY '00:00:1'        
 END


--Check if all the records are updated or not .
IF EXISTS ( SELECT 1 FROM CustInfo ibc WITH (nolock)
				inner join DBCasino.CasinoAdmin.dbo.Customer cas WITH (nolock)
				on ibc.custid = cas.IBCCustID
				and ibc.enabled=1
				and ibc.currency<>20
				and ibc.SyncCasino=0
				and cas.EnableCasino=0
)
BEGIN
    PRINT ('All the records are not updated , there is some problems , Contact Devs ')
END
BEGIN
    PRINT ('All the records are updated SUCCESSFULLY !!!!')
END

SET ROWCOUNT 0
