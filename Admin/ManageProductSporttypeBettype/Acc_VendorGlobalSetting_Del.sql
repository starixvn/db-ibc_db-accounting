/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_VendorGlobalSetting_Del    
    @File NVARCHAR(MAX),    
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
    IF ISNULL(@File, '') = ''    
        RETURN;    
    DECLARE @StartRun DATETIME,    
            @EndRun DATETIME,    
            @Duration INT,    
            @iDoc INT,    
            @logSpData NVARCHAR(MAX);    
    CREATE TABLE #input    
    (    
        VendorID NVARCHAR(MAX),    
        VendorName NVARCHAR(MAX)    
    );    
    SET @StartRun = GETDATE();    
    
    BEGIN TRY    
        EXEC sp_xml_preparedocument @iDoc OUTPUT, @File;    
        INSERT INTO #input    
        (    
            VendorID,    
            VendorName    
        )    
        SELECT VendorID,    
               VendorName    
        FROM    
            OPENXML(@iDoc, '/ROOT/File', 1)    
            WITH    
            (    
                VendorID NVARCHAR(MAX),    
                VendorName NVARCHAR(MAX)    
            );    
        EXEC sp_xml_removedocument @iDoc;    
        SELECT @logSpData =    
        (    
            SELECT vgs.VendorId,    
                   vgs.VName  
            FROM DBCUST.CustDB.dbo.VendorGlobalSetting vgs WITH (NOLOCK)    
                INNER JOIN #input a WITH (NOLOCK)    
                    ON a.VendorID = vgs.VendorId    
     AND a.VendorName = vgs.VName    
            FOR XML RAW('File')    
        );    
        SET @logSpData = N'<ROOT>' + @logSpData + N'</ROOT>';    
        DELETE vgs    
  FROM DBCUST.CustDB.dbo.VendorGlobalSetting vgs WITH (ROWLOCK)    
  INNER JOIN #input a WITH (NOLOCK)    
  ON a.VendorID = vgs.VendorId    
  AND a.VendorName = vgs.VName;    
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
    DROP TABLE #input;    
END;    