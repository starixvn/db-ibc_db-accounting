/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_VendorGlobalSetting_Sel
    @VendorId INT = NULL,
    @VName VARCHAR(50) = '',
    @NumberValue DECIMAL(19, 8) = NULL,
    @SportType SMALLINT = NULL,
    @BetType SMALLINT = NULL,
    @PageSize INT = 50,
    @PageIndex INT = 1,
    @TotalRows INT = 0 OUTPUT
AS
/*            
Created: 20210511@Evan          
Task :  NAP -  Manage VendorGlobal Setting  [Redmine: #153521]  
DB:   DBCUST-CustDB         
Original:            
  Revisions:   
    - 20210511@Evan: Create new SP [Redmine: #153521]  
*/
BEGIN
    SET NOCOUNT ON;
    SELECT vgs.VendorId,
           vgs.VName,
           vgs.NumberValue,
           vgs.sporttype,
           st.SportName,
           vgs.bettype,
           bt.typenamee,
           ROW_NUMBER() OVER (ORDER BY VendorId, VName) AS RowNum
    INTO #Tmp
    FROM dbo.VendorGlobalSetting vgs WITH (NOLOCK)
        LEFT JOIN DBPRO.bodb02.dbo.bettype bt WITH (NOLOCK)
            ON bt.typeid = vgs.bettype
        LEFT JOIN DBPRO.bodb02.dbo.Sports st WITH (NOLOCK)
            ON st.SportType = vgs.sporttype
    WHERE (
              VendorId = @VendorId
              OR @VendorId IS NULL
          )
          AND
          (
              VName LIKE '%' + @VName + '%'
              OR ISNULL(@VName, '') = ''
          )
          AND
          (
              NumberValue = @NumberValue
              OR @NumberValue IS NULL
          )
          AND
          (
              vgs.sporttype = @SportType
              OR @SportType IS NULL
          )
          AND
          (
              vgs.bettype = @BetType
              OR @BetType IS NULL
          );
    SELECT @TotalRows = COUNT(*)
    FROM #Tmp;
    SELECT VendorId,
           VName,
           NumberValue,
           sporttype,
           SportName,
           bettype,
           typenamee,
           RowNum
    FROM #Tmp
    WHERE RowNum > (@PageIndex - 1) * @PageSize
          AND RowNum <= @PageIndex * @PageSize;
    DROP TABLE #Tmp;
END;
GO
