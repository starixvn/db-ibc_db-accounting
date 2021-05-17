/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_VendorGlobalSetting_Del    
    @VendorId INT,      
    @VName VARCHAR(50),    
    @LoginIP VARCHAR(20) = '',    
    @UserID INT,    
    @ErrCode INT = 0 OUTPUT,    
    @ErrMsg NVARCHAR(4000) = '' OUTPUT    
AS    
/*          
Created: 20210512@Evan        
Task :  NAP -  Manage VendorGlobal Setting and Product3rd        [Redmine: #153521]
DB:   DBCUST-CustDB
Original:          
*/    
BEGIN    
    SET NOCOUNT ON;    
    DECLARE @StartRun DATETIME,    
            @EndRun DATETIME,    
            @Duration INT,    
            @logSpData NVARCHAR(MAX);    
    SET @StartRun = GETDATE();  
    SELECT @LogSPData = '<R VendorId="'+ COALESCE(CAST(@VendorId AS VARCHAR(6)), SPACE(1)) + '" ' +
                            'VName="' + COALESCE(CAST(@VName  AS VARCHAR(6)), SPACE(1)) + '" ' +
                            'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
    BEGIN TRY    
        DELETE vgs    
        FROM DBCUST.CustDB.dbo.VendorGlobalSetting vgs WITH (ROWLOCK)    
        WHERE vgs.VendorId = @VendorId AND vgs.VName = @VName;
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