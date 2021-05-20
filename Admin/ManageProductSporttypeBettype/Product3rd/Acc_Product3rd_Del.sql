/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_Product3rd_Del
    @ProductId INT,
    @LoginIP VARCHAR(20) = '',
    @UserID INT,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*            
Created: 20210514@Evan          
Task :  NAP -  Manage Product3rd        [Redmine: #153521]  
DB:   DBCUST-bodb_Licensee  

Revisions: 
    - 20210514@Evan: Create new SP [Redmine: #153521]
*/
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartRun DATETIME,
            @EndRun DATETIME,
            @Duration INT,
            @logSpData NVARCHAR(MAX);
    SET @StartRun = GETDATE();
    SELECT @logSpData
        = '<R ProductId="' + COALESCE(CAST(@ProductId AS VARCHAR(6)), SPACE(1)) + '" ' + 'LoginIP="'
          + COALESCE(CAST(@LoginIP AS VARCHAR(20)), SPACE(1)) + '" />';

    BEGIN TRY
        DELETE p3
        FROM dbo.Product3rd p3 WITH (ROWLOCK)
        WHERE p3.Productid = @ProductId;
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = ERROR_NUMBER(),
               @ErrMsg = ERROR_MESSAGE();
        RETURN;
    END CATCH;
    SELECT @EndRun = GETDATE(),
           @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun);

    EXEC DBCUST.CustDB.dbo.Acc_WriteLog_UserLog_RunSP_Wrapper @UserID = @UserID,
                                            @ActionID = 95049,
                                            @TrackingValue = @logSpData,
                                            @Duration = @Duration;
END;
