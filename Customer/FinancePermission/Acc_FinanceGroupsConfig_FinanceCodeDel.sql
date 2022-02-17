/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_FinanceGroupsConfig_FinanceCodeDel]
	@XmlData	NVARCHAR(MAX) 
	,@UserID	INT
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(2000) = '' OUTPUT
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config - Finance Code - Remove
	DB: DBCUST/CUSTDB

	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]
		
	Param's Explanation:
		 @XmlData
			<root>
				<r GroupId="2" UserName="XD1" IsView="0" RoleId="2"/>
			</root>	               
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Xml XML = CONVERT(XML, @XmlData)

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @CustId INT = NULL, @UserName VARCHAR(30), @IsView BIT, @GroupId INT

	SET @startRun = GETDATE();

	CREATE TABLE #Finance(ID INT IDENTITY(1, 1), GroupId SMALLINT, UserName VARCHAR(30), CustId INT, IsView BIT, RoleId TINYINT)
	INSERT INTO #Finance (GroupId , UserName, IsView, RoleId)
	SELECT 
		t.c.value('@GroupId', 'SMALLINT') AS GroupId
		,t.c.value('@UserName', 'VARCHAR(30)') AS UserName
		,t.c.value('@IsView', 'BIT') AS IsView
		,t.c.value('@RoleId', 'TINYINT') AS RoleId
	FROM @Xml.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@Xml = NULL))

	UPDATE f
		SET f.CustId = n.CustId
	FROM #Finance f
	CROSS APPLY (
		SELECT c.CustId FROM dbo.Customer c WITH(NOLOCK) WHERE c.UserName = f.UserName
	) AS n

	BEGIN TRY
		DELETE f WITH(ROWLOCK, UPDLOCK)
		FROM dbo.Acc_FinancePermission f
			INNER JOIN #Finance e ON e.UserName = f.FinanceCode AND e.GroupId = f.GroupId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 100, @ErrMsg = 'Delete unsuccessfully, please check again.' 
		RETURN
	END CATCH
		
	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	DECLARE @Id INT = 1

	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM #Finance f WHERE f.ID = @Id)
			BREAK

		SELECT @UserName = UserName, @IsView = IsView, @CustId = CustId, @GroupId = GroupId FROM #Finance WITH(NOLOCK) WHERE ID = @Id

		SELECT @LogSPData = '<Acc_FinanceGroupsConfig_FinanceCodeDel GroupId="'+ COALESCE(CAST(@GroupId AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'CustId="'+ COALESCE(CAST(@CustId AS VARCHAR(20)), SPACE(1)) + '" ' +
							   'Username="'+ COALESCE(CAST(@Username AS VARCHAR(30)), SPACE(1)) + '" ' +
							   'IsView="'+ COALESCE(CAST(ISNULL(@IsView, 0) AS VARCHAR(2)), SPACE(1)) + '" ' +				   
							   'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'ErrMsg="'+ COALESCE(CAST(@ErrMsg as VARCHAR(4000)),SPACE(1)) + '" />'
		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					 @UserID = @UserID, 
					 @CustID = @CustId,
					 @ActionID = 95060,
					 @TrackingValue = @LogSPData,
					 @duration = @duration
					 
		SET @Id = @Id + 1
	END

	DROP TABLE #Finance
END
GO
