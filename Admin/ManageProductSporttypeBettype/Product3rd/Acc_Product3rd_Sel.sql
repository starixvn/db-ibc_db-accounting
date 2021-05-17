/*<info serverAlias="DBCUST-bodb_Licensee" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Acc_Product3rd_Sel
    @Productid INT = NULL,
    @ProductName VARCHAR(50) = '',
    @Description VARCHAR(100) = '',
    @ProductPrefix VARCHAR(10) = '',
    @OfferSingle BIT = NULL,
    @ApplyDCS BIT = NULL,
    @PageSize INT = 50,
    @PageIndex INT = 1,
    @TotalRows INT = 0 OUTPUT
AS
/*          
Created: 20210513@Evan        
Task :  NAP -  Manage Product3rd [Redmine: #153521]
DB:   DBCUST-bodb_Licensee           
Original:          
  Revisions: 
    - 20200413@Evan: Create new SP [Redmine: #153521]
*/
BEGIN
    SET NOCOUNT ON;
    SELECT Productid,
           ProductName,
           Description,
           ProductPrefix,
           OfferSingle,
           ApplyDCS,
           Enabled,
           EndOfSupportDate,
           ROW_NUMBER() OVER (ORDER BY Productid) AS RowNum
    INTO #Tmp
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
              ProductPrefix = @ProductPrefix
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
           RowNum
    FROM #Tmp 
    WHERE RowNum > (@PageIndex - 1) * @PageSize
          AND RowNum <= @PageIndex * @PageSize;
    DROP TABLE #Tmp;
END;