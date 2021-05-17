/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_VendorGlobalSetting_Upd        
    @File NVARCHAR(MAX),        
    @LoginIP VARCHAR(20) = '',        
    @UserID INT,        
    @ErrCode INT = 0 OUTPUT,        
    @ErrMsg NVARCHAR(4000) = '' OUTPUT        
AS        
/*            
Created: 20210512@Evan          
Task :  NAP -  Manage VendorGlobal Setting and Product3rd          [Redmine: #153521]
DB:   DBCUST-CustDB          
Original:            
  Revisions: 
    - 20200413@Evan: Create new SP [Redmine: #153521]
Param's Explanation:          
 - @Fie:            
  <ROOT><File VendorID = "40" VendorName = "3rdCashWLShareRate1" NumberValue = "1" SportType = "200" BetType = "200" />        
</ROOT>        
*/          
BEGIN        
 SET NOCOUNT ON;        
 IF ISNULL(@File, '') = ''        
        RETURN;        
DECLARE @iDoc INT,      
        @ValueError NVARCHAR(MAX) = N'',      
        @ColumnName NVARCHAR(200);      
DECLARE @startRun DATETIME,      
        @endRun DATETIME,      
        @duration INT,      
        @LogSPData NVARCHAR(MAX),      
        @LogSPData_Old NVARCHAR(MAX),      
        @RowTotal INT = 0,      
        @CurrentRow INT = 0;       
CREATE TABLE #input        
(        
    ID INT IDENTITY (1,1),      
    VendorId INT,        
    VName VARCHAR(50),        
    NumberValue DECIMAL(19, 8),        
    sporttype SMALLINT,        
    bettype SMALLINT        
);          
CREATE TABLE #inputTmp        
(        
    VendorID NVARCHAR(MAX),        
    VendorName NVARCHAR(MAX),        
    NumberValue NVARCHAR(MAX),        
    SportType NVARCHAR(MAX),        
    BetType NVARCHAR(MAX)        
);        
BEGIN TRY        
    EXEC sp_xml_preparedocument @iDoc OUTPUT, @File;        
 INSERT INTO #inputTmp        
 (        
     VendorID,        
     VendorName,        
     NumberValue,        
     SportType,        
     BetType        
 )        
    SELECT VendorID,        
           VendorName,        
           NumberValue,        
           SportType,        
           BetType        
    FROM        
        OPENXML(@iDoc, '/ROOT/File', 1)        
        WITH        
        (        
            VendorID NVARCHAR(MAX),        
            VendorName NVARCHAR(MAX),        
            NumberValue NVARCHAR(MAX),        
            SportType NVARCHAR(MAX),        
            BetType NVARCHAR(MAX)        
        );        
    EXEC sp_xml_removedocument @iDoc;        
END TRY        
BEGIN CATCH        
    SELECT @ErrCode = ERROR_NUMBER(),        
           @ErrMsg = ERROR_MESSAGE();        
    RETURN;        
END CATCH;        
-- Check Simple Data         
UPDATE #inputTmp          
SET            
NumberValue  = CASE WHEN LEN(NumberValue)  = 0 THEN NULL ELSE NumberValue  END,         
SportType  = CASE WHEN LEN(SportType)  = 0 THEN NULL ELSE SportType  END,         
BetType  = CASE WHEN LEN(BetType)  = 0 THEN NULL ELSE BetType  END        
WHERE LEN(NumberValue) = 0        
   OR LEN(SportType) = 0        
   OR LEN(BetType) = 0;       
   SELECT TOP (1)    
       @ErrCode = 1007,    
       @ColumnName = 'NumberValue'    
FROM #inputTmp WITH (NOLOCK)    
WHERE  ISNUMERIC(NumberValue) <> 1;    
IF @ErrCode <> 0        
BEGIN        
  SELECT @ErrMsg = 'Invalid "' + @ColumnName + '"' + '.Please check them again.';        
  RETURN;        
END;        
BEGIN TRY        
 INSERT INTO #input        
 (        
  VendorId,        
  VName,        
  NumberValue,        
  sporttype,        
  bettype        
 )        
 SELECT VendorID,        
   VendorName,        
   NumberValue,        
   SportType,        
   BetType        
 FROM #inputTmp WITH(NOLOCK) ;        
END TRY        
BEGIN CATCH        
 SELECT @ErrCode = ERROR_NUMBER(),        
   @ErrMsg = ERROR_MESSAGE();        
 RETURN;        
END CATCH;        
    
SELECT @RowTotal = COUNT(*) FROM #input;        
WHILE @CurrentRow <> @RowTotal        
BEGIN        
         
    SELECT @CurrentRow = @CurrentRow + 1,        
            @startRun = GETDATE();        
 SELECT @logSpData_Old = N'<R VendorID="'+ COALESCE(CAST(vgs.VendorId AS VARCHAR(10)), SPACE(1)) + '" ' +    
                      'VendorName="' + COALESCE(CAST(vgs.VName  AS VARCHAR(10)), SPACE(1)) + '" ' +    
                      'NumberValue="' + COALESCE(CAST(vgs.NumberValue   AS VARCHAR(50)), SPACE(1)) + '" ' +    
                      'SportType="' + COALESCE(CAST(vgs.SportType   AS VARCHAR(10)), SPACE(1)) + '" ' +    
       'BetType="' + COALESCE(CAST(vgs.SportType  AS VARCHAR(10)), SPACE(1)) + '" ' +    
       'IP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'    
  FROM DBCUST.CustDB.dbo.VendorGlobalSetting vgs WITH(NOLOCK)    
   INNER JOIN #input i ON i.VendorId = vgs.VendorId AND i.VName = vgs.VName      
  WHERE i.ID = @CurrentRow        
    BEGIN TRY        
   UPDATE vgs    
   SET vgs.NumberValue=i.NumberValue,    
    vgs.bettype=i.bettype,    
    vgs.sporttype=i.sporttype    
   FROM  DBCUST.CustDB.dbo.VendorGlobalSetting vgs WITH(ROWLOCK)    
   INNER JOIN #input i ON i.VendorId = vgs.VendorId AND i.VName = vgs.VName      
  WHERE i.ID = @CurrentRow       
    END TRY        
    BEGIN CATCH        
        SELECT @ErrCode = ERROR_NUMBER(),        
                @ErrMsg = ERROR_MESSAGE();        
        RETURN;        
    END CATCH;        
 SELECT @LogSPData = N'<R VendorID="'+ COALESCE(CAST(vgs.VendorId AS VARCHAR(10)), SPACE(1)) + '" ' +    
                      'VendorName="' + COALESCE(CAST(vgs.VName  AS VARCHAR(10)), SPACE(1)) + '" ' +    
                      'NumberValue="' + COALESCE(CAST(vgs.NumberValue   AS VARCHAR(50)), SPACE(1)) + '" ' +    
                      'SportType="' + COALESCE(CAST(vgs.SportType   AS VARCHAR(10)), SPACE(1)) + '" ' +    
       'BetType="' + COALESCE(CAST(vgs.SportType  AS VARCHAR(10)), SPACE(1)) + '" ' +    
       'IP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'   
  FROM DBCUST.CustDB.dbo.VendorGlobalSetting vgs WITH(NOLOCK)    
   INNER JOIN #input i ON i.VendorId = vgs.VendorId AND i.VName = vgs.VName      
  WHERE i.ID = @CurrentRow      
        
    SET @endRun = GETDATE();        
    SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun);        
               
--EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper     
--    @UserID = @UserID,    
--    @ActionID = 6061,    
--    @TrackingValue = @LogSPData,    
--    @TrackingValue2 = @logSpData_Old,    
--    @duration = @Duration    
    END;       
 DROP TABLE #input, #inputTmp;        
END     