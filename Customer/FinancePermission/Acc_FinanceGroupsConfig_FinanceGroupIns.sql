/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceGroupsConfig_FinanceGroupIns]
	@XmlData	NVARCHAR(MAX)
	,@UserID	INT
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(2000) = '' OUTPUT
	,@GroupId	INT OUTPUT
	,@NUsers    INT OUT
	,@NCodes    INT OUT
	
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config - Add new Finance Group
	DB: DBCUST/CUSTDB

	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]

	Param's Explanation:
		 @XmlData
			<root>
				<r CustId="1" UserName="Supertest1" RoleId="1" IsView="0"/>
			</root>
	               
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @CustId INT = NULL
			,@RoleId TINYINT, @UserName VARCHAR(30), @IsView BIT
	SET @startRun = GETDATE();

	DECLARE @Xml XML = CONVERT(XML, @XmlData)

	CREATE TABLE #Finance (ID INT IDENTITY(1, 1), CustId INT, UserName VARCHAR(30), RoleId INT, IsView BIT)
	INSERT INTO #Finance (CustId, UserName ,RoleId ,IsView)
	SELECT 
		t.c.value('@CustId', 'INT') AS FinanceCode
		,t.c.value('@UserName', 'VARCHAR(30)') AS FinanceCode
		,t.c.value('@RoleId', 'INT') AS RoleId
		,t.c.value('@IsView', 'BIT') AS IsView
	FROM @Xml.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@Xml = NULL))

	SELECT @NUsers = COUNT(CASE WHEN RoleId >= 5 THEN 1 ELSE NULL END)
		  ,@NCodes =  COUNT(CASE WHEN RoleId <= 4 THEN 1 ELSE NULL END)
	FROM #Finance 

	SELECT @GroupId = MAX(GroupId) + 1
	FROM dbo.Acc_FinancePermission WITH(NOLOCK)

	BEGIN TRY
		DELETE f WITH(ROWLOCK, UPDLOCK)
		FROM dbo.Acc_FinancePermission f
		WHERE EXISTS (SELECT 1 FROM #Finance e WHERE e.UserName = f.FinanceCode AND e.RoleId >= 5)

		INSERT INTO dbo.Acc_FinancePermission (GroupId, FinanceCode, RoleId, IsView)
		SELECT @GroupId, f.UserName, f.RoleId, f.IsView
		FROM #Finance f
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 100, @ErrMsg = 'Cannot create new Finance Group.'
		RETURN
	END CATCH
	
	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	DECLARE @Id INT = 1

	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM #Finance f WHERE f.ID = @Id)
			BREAK

		SELECT @UserName = UserName, @RoleId = RoleId, @IsView = IsView, @CustId = CustId FROM #Finance WITH(NOLOCK) WHERE ID = @Id

		SELECT @LogSPData = '<Acc_FinanceGroupsConfig_FinanceGroupIns GroupId="'+ COALESCE(CAST(@GroupId AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'CustId="'+ COALESCE(CAST(@CustId AS VARCHAR(20)), SPACE(1)) + '" ' +
							   'Username="'+ COALESCE(CAST(@Username AS VARCHAR(30)), SPACE(1)) + '" ' +
							   'RoleId="'+ COALESCE(CAST(@RoleId AS VARCHAR(5)), SPACE(1)) + '" ' +
							   'IsView="'+ COALESCE(CAST(ISNULL(@IsView, 0) AS VARCHAR(2)), SPACE(1)) + '" ' +				   
							   'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'ErrMsg="'+ COALESCE(CAST(@ErrMsg as VARCHAR(4000)),SPACE(1)) + '" />'
		
		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					 @UserID = @UserID, 
					 @CustID = @CustId,
					 @ActionID = 95061,
					 @TrackingValue = @LogSPData,
					 @duration = @duration
					 
		SET @Id = @Id + 1
	END

	DROP TABLE #Finance
END
GO
