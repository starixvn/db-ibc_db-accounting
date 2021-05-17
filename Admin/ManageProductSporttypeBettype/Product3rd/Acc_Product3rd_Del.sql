/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/  
CREATE PROCEDURE dbo.Acc_Product3rd_Del      
    @ProductId INT,      
    @LoginIP VARCHAR(20) = '',      
    @UserID INT,      
    @ErrCode INT = 0 OUTPUT,      
    @ErrMsg NVARCHAR(4000) = '' OUTPUT      
AS      
/*            
Created: 20210514@Evan          
Task :  NAP -  Manage VendorGlobal Setting and Product3rd        [Redmine: #153521]  
DB:   DBCUST-CustDB  
Original:     
  - 20200413@Evan: Create new SP [Redmine: #153521]
*/      
BEGIN      
    SET NOCOUNT ON;      
    DECLARE @StartRun DATETIME,      
            @EndRun DATETIME,      
            @Duration INT,      
            @logSpData NVARCHAR(MAX);      
    SET @StartRun = GETDATE();    
  SELECT @LogSPData = '<R ProductId="'+ COALESCE(CAST(@ProductId AS VARCHAR(6)), SPACE(1)) + '" ' +  
              'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'  
    BEGIN TRY      
      DELETE p3      
      FROM DBCUST.bodb_Licensee.dbo.Product3rd p3 WITH (ROWLOCK)      
      WHERE p3.Productid = @ProductId;  
    END TRY      
    BEGIN CATCH      
        SELECT @ErrCode = ERROR_NUMBER(),      
               @ErrMsg = ERROR_MESSAGE();      
        RETURN;      
    END CATCH;      
    SELECT @EndRun = GETDATE(),      
           @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun);      
    --EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @UserID = @UserID,      
    --                                        @ActionID = 6062,      
    --                                        @TrackingValue = @logSpData,      
    --                                        @Duration = @Duration;      
END; 