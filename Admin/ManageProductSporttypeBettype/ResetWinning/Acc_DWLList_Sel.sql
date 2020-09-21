/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_DWLList_Sel
	@CustID			INT = NULL,
	@UserName		VARCHAR(30) = NULL,
	@ProductID		TINYINT = NULL,
	@Product		VARCHAR(50) = NULL,
	@IsDeleted		BIT = NULL,
	@IsTest			BIT = 0
AS

/*
Created: 20200916@Danny
Task :  NAP Manage Reset Winning
DB: DBACC/bodb_ACC
Original:

	Revisions:
		- 20200918@Danny: NAP Manage Reset Winning [Redmine: #131241][Task: #141775]
*/

BEGIN
    SET NOCOUNT ON
	
	CREATE TABLE #Tmp (
	 	CustID			INT,
		Username		VARCHAR(30),
		Seq				TINYINT,
		ProductID		TINYINT,
		Product			VARCHAR(50),
		IsDeleted		BIT
	)

	IF @IsTest = 0 
	BEGIN
		INSERT INTO #Tmp(
				   CustID,
				   Username,
				   Seq,
				   ProductID,
				   Product,
				   IsDeleted
		)
		SELECT     acc.CustID,
				   cus.Username,
				   acc.Seq,
				   acc.ProductID,
				   acc.Product,
				   acc.IsDeleted
		FROM Acc_DWLList acc WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Customer cus WITH(NOLOCK) on acc.CustID = cus.CustID
		WHERE (acc.CustID = @CustID OR @CustID IS NULL) 
				AND (acc.ProductID = @ProductID OR @ProductID IS NULL)	
				AND (cus.Username LIKE '%' + @Username +'%' OR ISNULL(@Username,'') = '')
				AND (acc.Product LIKE '%' + @Product +'%' OR ISNULL(@Product,'') = '')
				AND (acc.IsDeleted = @IsDeleted OR @IsDeleted IS NULL)	
		ORDER BY  acc.CustID
	END

	IF @IsTest = 1 
	BEGIN
		INSERT INTO #Tmp(
				   CustID,
				   Username,
				   Seq,
				   ProductID,
				   Product,
				   IsDeleted
		)
		SELECT     acc.CustID,
				   cus.Username,
				   acc.Seq,
				   acc.ProductID,
				   acc.Product,
				   acc.IsDeleted
		FROM Acc_DWLList_xtest acc WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Customer cus WITH(NOLOCK) on acc.CustID = cus.CustID
		WHERE (acc.CustID = @CustID OR @CustID IS NULL) 
				AND (acc.ProductID = @ProductID OR @ProductID IS NULL)	
				AND (cus.Username LIKE '%' + @Username +'%' OR ISNULL(@Username,'') = '')
				AND (acc.Product LIKE '%' + @Product +'%' OR ISNULL(@Product,'') = '')
				AND (acc.IsDeleted = @IsDeleted OR @IsDeleted IS NULL)	
		ORDER BY  acc.CustID
	END

	SELECT  CustID,
		    Username,
			Seq,
			ProductID,
			Product,
			IsDeleted
	FROM #Tmp

	DROP TABLE #Tmp
 
END