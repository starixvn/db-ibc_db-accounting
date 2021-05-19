/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_VendorGlobalSetting_Sel
    @VendorId INT = NULL,
    @VName VARCHAR(50) = '',
    @NumberValue DECIMAL(19, 8) = NULL,
    @SportType VARCHAR(MAX) = NULL,
    @BetType VARCHAR(MAX) = NULL,
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
Param's Explanation:
  @SportType = N'1,2,3,4'
  @BetType = N'1,2,3,4'
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowStart INT , @RowEnd INT
    SELECT @PageIndex = @PageIndex - 1, @RowStart =  @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1;

    DECLARE @tmp_Sports TABLE
    (
        SportType SMALLINT,
        SportName NVARCHAR(50)
    );
    DECLARE @tmp_Bettype TABLE
    (
        typeid INT,
        typenamee NVARCHAR(128)
    );
    IF ISNULL(@SportType, '') = ''
    BEGIN
        INSERT INTO @tmp_Sports
        (
            SportType,
            SportName
        )
        VALUES
        (   0,  -- SportType - smallint  
            N'' -- SportName - nvarchar(50)  
            );
    END;
    ELSE
    BEGIN
        INSERT INTO @tmp_Sports
        (
            SportType,
            SportName
        )
        SELECT a.val,
               ISNULL(b.SportName, '')
        FROM dbo.strSplit(ISNULL(@SportType, ''), ',') a
            INNER JOIN DBPRO.bodb02.dbo.Sports b WITH (NOLOCK)
                ON a.val = b.SportType;
    END;
   
    IF ISNULL(@BetType, '') = ''
    BEGIN
        INSERT INTO @tmp_Bettype
        (
            typeid,
            typenamee
        )
        VALUES
        (   0,  -- typeid - int  
            N'' -- typenamee - nvarchar(50)  
            );
    END;
    ELSE
    BEGIN
        INSERT INTO @tmp_Bettype
        (
            typeid,
            typenamee
        )
        SELECT a.val,
               ISNULL(b.typenamee, '')
        FROM dbo.strSplit(ISNULL(@BetType, ''), ',') a
            INNER JOIN DBPRO.bodb02.dbo.bettype b WITH (NOLOCK)
                ON a.val = b.typeid;
    END;
  
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
        INNER JOIN @tmp_Bettype bt
            ON ISNULL(vgs.bettype, '') = bt.typeid
        INNER JOIN @tmp_Sports st
            ON ISNULL(vgs.sporttype, '') = st.SportType
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
    WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNum BETWEEN @RowStart AND @RowEnd);
    DROP TABLE #Tmp;
END;