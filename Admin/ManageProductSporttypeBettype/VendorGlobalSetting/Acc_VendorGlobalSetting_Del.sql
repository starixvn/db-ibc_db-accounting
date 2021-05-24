/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
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
Task :  NAP -  Manage VendorGlobal Setting        [Redmine: #153521]
DB:   DBCUST-CustDB

Revisions: 
    - 20210512@Evan: Create new SP [Redmine: #153521]
*/
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartRun DATETIME,
            @EndRun DATETIME,
            @Duration INT,
            @logSpData NVARCHAR(MAX);
    SET @StartRun = GETDATE();
    SELECT @logSpData
        = N'<R VendorId="' + COALESCE(CAST(@VendorId AS VARCHAR(6)), SPACE(1)) + N'" ' + N'VName="'
          + COALESCE(CAST(@VName AS VARCHAR(6)), SPACE(1)) + N'" ' + N'LoginIP="'
          + COALESCE(CAST(@LoginIP AS VARCHAR(20)), SPACE(1)) + N'" />';
    BEGIN TRY
        DELETE vgs
        FROM dbo.VendorGlobalSetting vgs WITH (ROWLOCK)
        WHERE vgs.VendorId = @VendorId
              AND vgs.VName = @VName;
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = ERROR_NUMBER(),
               @ErrMsg = ERROR_MESSAGE();
        RETURN;
    END CATCH;

    SELECT @EndRun = GETDATE(),
           @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun);
           
    EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @UserID = @UserID,
                                            @ActionID = 95046,
                                            @TrackingValue = @logSpData,
                                            @Duration = @Duration;
END;