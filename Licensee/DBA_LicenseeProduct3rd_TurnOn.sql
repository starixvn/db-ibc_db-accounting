 CREATE PROCEDURE DBA_LicenseeProduct3rd_TurnOn      
@LicenseeID int ,      
@Productid int,      
@isComm bit = 1,      
@isWinloss bit = 0      
      
AS      
      
/*      
 Create by : 20130312@Scott      
 Task : Turn on product3rd for particular Licensee.      
 DB:       
       
 Param's Explanation:       
   *@LicenseeID :       
   *@Productid :        
*/       
      
BEGIN       
SET NOCOUNT ON      
    
  --### DECLARE VARIABLE ###--      
  DECLARE @Table_Functions AS table ( Functionid int )      
  DECLARE @LicenseeName varchar(100), @ProductName varchar(100)      
  --### SET VALUE FOR VARIABLE ###--      
  SELECT @LicenseeName = isnull(a.LicenseeName,'')      
  FROM Licensees a  with(nolock)      
  WHERE a.LicenseeID=@LicenseeID      
      
  SELECT @ProductName = isnull(a.ProductName,'')      
  FROM Product3rd a with(nolock)       
  WHERE a.Productid=@Productid      
      
      
      
  --### VALIDATE DATA AND CHECK CONDITIONAL ###--      
  if @LicenseeName=''      
  begin      
    print 'This licensee doesn''t exists!'      
    return;      
  end        
  if @ProductName=''      
  begin      
    print 'This Product doesn''t exists!'      
    return;      
  end        
          
      
       
  IF  @Productid = 1 --Racing      
  begin      
   insert into @Table_Functions values (22)      
    insert into @Table_Functions values (34)      
    insert into @Table_Functions values (35)      
  end      
      
  If  @Productid = 2       
    insert into @Table_Functions values (23)      
      
      
  --### LICENSEEPRODUCT3RD      
  IF EXISTS(SELECT 1 FROM LicenseeProduct3rd WHERE ProductID=@productID and LicenseeID=@LicenseeID)      
  BEGIN      
   print 'This licensee has been add '+@ProductName + CHAR(13)      
    print 'SELECT * FROM LicenseeProduct3rd WHERE ProductID='+convert(varchar(50),@productID)+' and LicenseeID='+convert(varchar(50),@LicenseeID)      
    return;      
          
  END      
  ELSE       
    INSERT INTO LicenseeProduct3rd (LicenseeID,ProductID,Comm,Winloss)      
   SELECT @LicenseeID as LicenseeID,@productID as ProductID,@isComm as Comm, @isWinloss as Winloss      
      
  if exists (select  count(1) from @Table_Functions)      
  begin       
    --### LICENSEEFUNCTIONS      
    DELETE FROM LicenseeFunctions WITH (ROWLOCK,UPDLOCK)       
    WHERE LicenseeID = @LicenseeID AND FunctionId in (SELECT functionid FROM @Table_Functions)      
      
    INSERT INTO LicenseeFunctions (licenseeID,FunctionId)       
    SELECT @LicenseeID,functionid FROM @Table_Functions      
      
    --### LICENSEEUSERFUNCTIONS      
    DELETE FROM LicenseeUserFunctions WITH (ROWLOCK,UPDLOCK)      
    WHERE LicenseeId = @LicenseeID AND FunctionId in (SELECT functionid FROM @Table_Functions)      
           
    INSERT INTO LicenseeUserFunctions(UserId,FunctionId,LicenseeId)      
    SELECT UserId, b.functionid, @LicenseeID      
    FROM LicenseeUserFunctions a WITH (NOLOCK),  @Table_Functions b      
    WHERE LicenseeId  = @LicenseeID AND a.FunctionId = 1 --total bets      
  end      
      
END 