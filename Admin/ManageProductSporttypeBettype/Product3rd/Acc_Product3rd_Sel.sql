/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_Product3rd_Sel
    @Productid INT = NULL,
    @ProductName VARCHAR(50) = '',
    @Description VARCHAR(100) = '',
    @ProductPrefix VARCHAR(10) = '',
    @OfferSingle BIT = NULL,
    @ApplyDCS BIT = NULL,
    @OfferSite TINYINT = 0,
    @PageSize INT = 0,
    @PageIndex INT = 0,
    @TotalRows INT = 0 OUTPUT
AS
/*          
Created: 20210513@Evan        
Task :  NAP -  Manage Product3rd [Redmine: #153521]
DB:   DBCUST-bodb_Licensee           

Revisions: 
    - 20210513@Evan: Create new SP [Redmine: #153521]
*/
BEGIN
    SET NOCOUNT ON;
  
    DECLARE @RowStart INT , @RowEnd INT
    SELECT @PageIndex = @PageIndex - 1, @RowStart =  @PageIndex * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1;

  CREATE TABLE #Tmp
  (
    Productid INT,  
        ProductName VARCHAR(50),  
        Description VARCHAR(100),  
        ProductPrefix VARCHAR(10),  
        OfferSingle BIT,  
        ApplyDCS BIT,  
        Enabled BIT,  
        EndOfSupportDate DATE,  
        OfferSite TINYINT ,
    RowNum INT
  )
  INSERT INTO #Tmp (Productid,ProductName,Description,ProductPrefix,OfferSingle,ApplyDCS,Enabled,EndOfSupportDate,OfferSite,RowNum)
    SELECT Productid,
           ProductName,
           Description,
           ProductPrefix,
           OfferSingle,
           ApplyDCS,
           Enabled,
           EndOfSupportDate,
           OfferSite,
           ROW_NUMBER() OVER (ORDER BY Productid) AS RowNum
    FROM dbo.Product3rd WITH (NOLOCK)
    WHERE (
              Productid = @Productid
              OR @Productid IS NULL
          )
          AND
          (
              ProductName LIKE '%' + @ProductName + '%'
              OR ISNULL(@ProductName, '') = ''
          )
          AND
          (
              Description LIKE '%' + @Description + '%'
              OR ISNULL(@Description, '') = ''
          )
          AND
          (
              ProductPrefix LIKE '%' + @ProductPrefix + '%'
              OR ISNULL(@ProductPrefix, '') = ''
          )
          AND
          (
              OfferSingle = @OfferSingle
              OR @OfferSingle IS NULL
          )
          AND
          (
              ApplyDCS = @ApplyDCS
              OR @ApplyDCS IS NULL
          )
      AND
          (
              OfferSite = @OfferSite
              OR ISNULL(@OfferSite,0) = 0
          );

    SELECT @TotalRows = COUNT(*)
    FROM #Tmp ;

    SELECT Productid,
           ProductName,
           Description,
           ProductPrefix,
           OfferSingle,
           ApplyDCS,
           Enabled,
           EndOfSupportDate,
           OfferSite,
           RowNum
    FROM #Tmp 
    WHERE @PageIndex < 0 OR @PageSize <= 0 OR (RowNum BETWEEN @RowStart AND @RowEnd);
    
    DROP TABLE #Tmp;
END;
