/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_VendorGlobalSetting_Sel        
    @VendorId INT = NULL,        
    @VName VARCHAR(50) = NULL,        
    @NumberValue DECIMAL(19, 8) = NULL,        
    @sporttype VARCHAR(MAX) = '',        
    @bettype VARCHAR(MAX) = '',        
    @PageSize INT = 50,        
    @PageIndex INT = 1,        
    @TotalRows INT = 0 OUTPUT        
AS        
/*          
Created: 20210511@Evan        
Task :  NAP -  Manage VendorGlobal Setting and Product3rd     [Redmine: #153521]
DB:   DBCUST-CustDB       
Original:          
*/        
BEGIN        
    SET NOCOUNT ON;        
    SELECT a.val AS SportType,        
           ISNULL(b.SportName, '') AS SportName        
    INTO #sporttype        
    FROM dbo.strSplit(@sporttype, ',') a        
    LEFT JOIN DBAGE.bodb02.dbo.Sports b WITH (NOLOCK) ON a.val = b.SportType;        
    SELECT a.val AS typeid,        
           ISNULL(b.typenamee, '') AS typenamee        
    INTO #bettype        
    FROM dbo.strSplit(@bettype, ',') a        
        LEFT JOIN DBAGE.bodb02.dbo.bettype b WITH (NOLOCK)        
            ON a.val = b.typeid;        
    SELECT vgs.VendorId,        
           vgs.VName,        
           vgs.NumberValue,        
           vgs.sporttype,        
           st.SportName,        
           vgs.bettype,        
           bt.typenamee,        
           ROW_NUMBER() OVER (ORDER BY VendorId, VName) AS RowNum        
    INTO #Tmp        
    FROM DBCUST.CustDB.dbo.VendorGlobalSetting vgs WITH (NOLOCK)        
        INNER JOIN #bettype bt WITH (NOLOCK)        
            ON ISNULL(vgs.bettype, '') = bt.typeid        
        INNER JOIN #sporttype st WITH (NOLOCK)        
            ON ISNULL(vgs.sporttype, '') = st.SportType        
    WHERE (        
              VendorId = @VendorId        
              OR ISNULL(@VendorId, 0) = 0        
          )        
          AND        
          (        
              VName LIKE '%' + @VName + '%'        
              OR ISNULL(@VName, '') = ''        
          )        
          AND        
          (        
              NumberValue = @NumberValue        
              OR ISNULL(@NumberValue, -1) = -1        
          );        
    SELECT @TotalRows = COUNT(*)        
    FROM #Tmp WITH (NOLOCK);        
    SELECT VendorId,        
           VName,        
           NumberValue,        
           sporttype,        
           SportName,        
           bettype,        
           typenamee,        
           RowNum        
    FROM #Tmp WITH (NOLOCK)        
    WHERE RowNum > @PageIndex - 1 * @PageSize        
          AND RowNum <= @PageIndex * @PageSize;        
    DROP TABLE #Tmp;        
    DROP TABLE #sporttype;        
    DROP TABLE #bettype;        
END;        