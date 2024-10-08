/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_FinanceGroupsConfig_GetValidCustid]
	@ValidCustIds NVARCHAR(MAX) = NULL OUTPUT  
	
AS
/*
	Created: 20240809@Lewis
	Task :  NAP - Admin - Finance Groups Config - get valid custid
	DB: DBPOL/NAP_UserControl

	Revisions:
		- 20240809@Lewis: Scale Out DBCust - Remove Linked Server [Redmine : #206895]

	Param's Explanation:
		               
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @ABS TABLE (custid int)

	INSERT INTO @ABS(custid)
	SELECT 5452637 --ABS014
	UNION SELECT 5452639 --ABS015
	UNION SELECT 5519908 --ABS016
	UNION SELECT 5519911 --ABS017
	UNION SELECT 5519914 --ABS018
	UNION SELECT 5519916 --ABS019
	UNION SELECT 5519917 --ABS020
	UNION SELECT 5519919 --ABS021
	UNION SELECT 5519921 --ABS022
	UNION SELECT 5519922 --ABS023
	UNION SELECT 5519924 --ABS024
	UNION SELECT 5519926 --ABS025
	UNION SELECT 5848823 --ABS026
	UNION SELECT 6081162 --ABSJackyTING.

	DECLARE @FuncId INT

	SELECT @FuncId = FuncId FROM dbo.acc_functioninfo WITH(NOLOCK) WHERE FuncDesc = 'View Finance Account'

	SELECT @ValidCustIds = STRING_AGG(CAST(a.custid AS VARCHAR(MAX)),',') 
	FROM dbo.acccustomer a WITH(NOLOCK) 
		INNER JOIN dbo.acc_memberpolicy m WITH(NOLOCK) ON m.CustID = a.custid
		INNER JOIN dbo.acc_grouppolicy g WITH(NOLOCK) ON g.GroupID = a.GroupID AND g.FuncID = m.FuncID
	WHERE a.custid NOT IN (SELECT Custid FROM @ABS)
		AND m.FuncID = @FuncId AND ((ISNULL(m.Policy, 0) | ISNULL(g.Policy, 0)) > 0) 



END
GO
