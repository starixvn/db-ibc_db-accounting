/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_VendorGlobalSetting_Sel
    @VendorId INT = NULL,
    @VName VARCHAR(50) = '',
    @NumberValue DECIMAL(19, 8) = NULL,
    @SportType VARCHAR(MAX) = NULL,
    @BetType VARCHAR(MAX) = NULL,
    @PageSize INT = 0,
    @PageIndex INT = 0,
    @TotalRows INT = 0 OUTPUT
AS

/*            
Created: 20210511@Evan          
Task :  NAP -  Manage VendorGlobal Setting  [Redmine: #153521]  
DB:   DBCUST-CustDB         

Revisions:   
    - 20210511@Evan: Create new SP [Redmine: #153521]  
Param's Explanation:
  @SportType = N'1,2,3,4'
  @BetType = N'1,2,3,4'
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowStart INT,
            @RowEnd INT;
    SELECT @PageIndex = @PageIndex - 1,
           @RowStart = @PageIndex * @PageSize + 1,
           @RowEnd = @RowStart + @PageSize - 1;

  CREATE TABLE #Tmp
    (
        VendorId  INT,
        VName VARCHAR(50),
        NumberValue DECIMAL(19, 8),
        sporttype SMALLINT,
        SportName NVARCHAR(50),
        bettype   INT,
        typenamee NVARCHAR(128),
        RowNum          INT
    );
    CREATE TABLE #tmp_Sports
    (
        SportType SMALLINT,
        SportName NVARCHAR(50)
    );
    CREATE TABLE #tmp_Bettype
    (
        typeid INT,
        typenamee NVARCHAR(128)
    );

  INSERT INTO #tmp_Sports (SportType,SportName)
  SELECT  val, ''
  FROM dbo.f_StringSplit(ISNULL(@SportType, ''), ',') OPTION (MAXRECURSION 0) ;

  INSERT INTO #tmp_Bettype (typeid,typenamee)
  SELECT  val, ''
    FROM dbo.f_StringSplit(ISNULL(@BetType, ''), ',') OPTION (MAXRECURSION 0) ;
  
  UPDATE a 
  SET a.SportName = b.SportName
  FROM #tmp_Sports a INNER JOIN DBPRO.bodb02.dbo.Sports b WITH (NOLOCK)  ON  a.SportType = b.SportType ;

  UPDATE a 
  SET a.typenamee = b.typenamee
  FROM #tmp_Bettype a INNER JOIN DBPRO.bodb02.dbo.bettype b WITH (NOLOCK)  ON  a.typeid = b.typeid;

  INSERT INTO #Tmp (VendorId,VName,NumberValue,sporttype,SportName,bettype,typenamee,RowNum)
  SELECT vgs.VendorId,
      vgs.VName, 
      vgs.NumberValue,
      vgs.sporttype,
      st.SportName,
      vgs.bettype,
      bt.typenamee,
      ROW_NUMBER() OVER (ORDER BY VendorId, VName)
  FROM dbo.VendorGlobalSetting vgs WITH (NOLOCK)
      INNER JOIN #tmp_Bettype bt
        ON ISNULL(vgs.bettype, 0) = bt.typeid
      INNER JOIN #tmp_Sports st
        ON ISNULL(vgs.sporttype, 0) = st.SportType
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
    WHERE @PageIndex < 0
          OR @PageSize <= 0
          OR (RowNum
          BETWEEN @RowStart AND @RowEnd
             );
          
    DROP TABLE #Tmp ;
    DROP TABLE #tmp_Sports;
    DROP TABLE #tmp_Bettype;
END;
