/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_DWLList_ExtraPT_Sel
	@CustID			INT = NULL,
	@UserName		VARCHAR(30) = NULL,
	@GroupID		INT = NULL,
	@GroupName		VARCHAR(50) = NULL,
	@IsDisabled		BIT = NULL,
	@IsTest			BIT
AS

/*
Created: 20200916@Danny
Task :  NAP Manage Reset Winning
DB: DBACC/bodb_ACC
Original:

	Revisions:
		- 20200328@Danny: NAP Manage Reset Winning [Redmine: #131241][Task: #141775]
*/

BEGIN
    SET NOCOUNT ON
	
	CREATE TABLE #Tmp (
	 	CustID			INT,
		Username		VARCHAR(30),
		GroupID			INT,
		GroupName		VARCHAR(50),
		IsDisabled		BIT
	)

	IF @IsTest = 0 
	BEGIN
		INSERT INTO #Tmp(
				   CustID,
				   Username,
				   GroupID,
				   GroupName,
				   IsDisabled
		)
		SELECT     acc.CustID,
				   cus.Username,
				   acc.GroupID,
				   acc.GroupName,
				   acc.IsDisabled
		FROM Acc_DWLList_ExtraPT acc WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Customer cus WITH(NOLOCK) on acc.CustID = cus.CustID
		WHERE (acc.CustID = @CustID OR @CustID IS NULL) 
				AND (acc.CustID = @CustID OR @CustID IS NULL)
				AND (acc.GroupID = @GroupID OR @GroupID IS NULL)	
				AND (cus.Username LIKE '%' + @Username +'%' OR ISNULL(@Username,'') = '')
				AND (acc.GroupName LIKE '%' + @GroupName +'%' OR ISNULL(@GroupName,'') = '')
				AND (acc.IsDisabled = @IsDisabled OR @IsDisabled IS NULL)	
		ORDER BY  acc.CustID
	END

	IF @IsTest = 1 
	BEGIN
		INSERT INTO #Tmp(
				   CustID,
				   Username,
				   GroupID,
				   GroupName,
				   IsDisabled
		)
		SELECT     acc.CustID,
				   cus.Username,
				   acc.GroupID,
				   acc.GroupName,
				   acc.IsDisabled
		FROM Acc_DWLList_ExtraPT_xtest acc WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Customer cus WITH(NOLOCK) on acc.CustID = cus.CustID
		WHERE (acc.CustID = @CustID OR @CustID IS NULL) 
				AND (acc.CustID = @CustID OR @CustID IS NULL)
				AND (acc.GroupID = @GroupID OR @GroupID IS NULL)	
				AND (cus.Username LIKE '%' + @Username +'%' OR ISNULL(@Username,'') = '')
				AND (acc.GroupName LIKE '%' + @GroupName +'%' OR ISNULL(@GroupName,'') = '')
				AND (acc.IsDisabled = @IsDisabled OR @IsDisabled IS NULL)	
		ORDER BY  acc.CustID
	END

	SELECT  CustID,
			Username,
			GroupID,
			GroupName,
			IsDisabled
	FROM #Tmp

	DROP TABLE #Tmp
 
END