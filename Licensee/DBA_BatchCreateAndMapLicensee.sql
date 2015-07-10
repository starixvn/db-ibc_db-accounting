ALTER PROCEDURE [dbo].[DBA_BatchCreateAndMapLicensee]   
as  
/*      
 Create by : 20130322@Scott      
 Task : Create New licensee(mapping dummy account) and turn on product3rd
 DB: bodb_licensee    
             
      
*/       

BEGIN  
  
SET NOCOUNT ON   
  
  
DECLARE  @LicenseeID int , @LicenseeName VARCHAR(50), @ResellerID  INT, @IsSpecial BIT,@ErrCode int,@ErrMsg nvarchar(1000)  
DECLARE @strmsg Nvarchar(1000),@SuperWildCard VARCHAR(100), @custid int, @currency int  
DECLARE @NumberGame bit,@LiveCasino bit,@Racing bit, @RNGCasino bit  
   
SET @ErrCode = 0  
   
DECLARE licensee_cursor CURSOR FOR   
SELECT licenseename,resellerid,isspecial,numbergame,livecasino,racing,RNGCasino  
FROM dba_licenseeNew  
WHERE [status]=0   
ORDER BY rid  
  
  
OPEN licensee_cursor  
  
FETCH NEXT FROM licensee_cursor INTO @LicenseeName, @ResellerID  , @IsSpecial , @NumberGame ,@LiveCasino ,@Racing ,@RNGCasino  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
   
   
   
 set @SuperWildCard = @LicenseeName+'Super%'  
  
--1.create licensee if not exists  
 IF NOT EXISTS (select 1 from licensees where licenseename = @LicenseeName )  
 BEGIN  
    
    
  set @strmsg = '1.0 Create Licensee '+@LicenseeName   
    
    
  EXEC [DBA_CreateNewLicensee]    
   @LicenseeName=@LicenseeName,  
   @ResellerID=@ResellerID,  
   @IsSpecial=@IsSpecial,  
   @ErrCode=@ErrCode output,   
   @ErrMsg=@ErrMsg output  
  IF ( @ErrCode=0 )  
   SET @strmsg=@strmsg +  ' successfull !!!'  
  ELSE  
   SET @strmsg=@strmsg + ' Error -- ' + @ErrMsg  
    
       
  PRINT  @strmsg  
    
  SET @strmsg = ''  
 END  
  
  
  
--3. Enable product3rd  
 SELECT @LicenseeID=LicenseeID   
 FROM licensees WHERE licenseename = @LicenseeName  
   
 IF @Racing = 1  
 BEGIN  
  EXEC DBA_LicenseeProduct3rd_TurnOn  @LicenseeID = @LicenseeID, @Productid = 1    
  PRINT '@@ Enable Racing'  
 END  
     
 IF @NumberGame = 1  
 BEGIN  
   EXEC DBA_LicenseeProduct3rd_TurnOn  @LicenseeID = @LicenseeID, @Productid = 2    
  PRINT '@@ Enable Number Game'  
 END    
   
 IF @LiveCasino = 1   
 BEGIN  
   EXEC DBA_LicenseeProduct3rd_TurnOn  @LicenseeID = @LicenseeID, @Productid = 4  
  PRINT '@@ Enable Live Casino'  
 END    
   
 IF @RNGCasino = 1   
 BEGIN  
   EXEC DBA_LicenseeProduct3rd_TurnOn  @LicenseeID = @LicenseeID, @Productid = 6  
  PRINT '@@ Enable RNG Casino'  
 END    
   
   
  
 PRINT '---------------------------------'  
 UPDATE DBA_LicenseeNew set [status]=1 where licenseename = @LicenseeName  
 FETCH NEXT FROM licensee_cursor INTO @LicenseeName, @ResellerID  , @IsSpecial , @NumberGame ,@LiveCasino ,@Racing ,@RNGCasino  
END   
CLOSE licensee_cursor  
DEALLOCATE licensee_cursor  
   
  
   
 end  
   