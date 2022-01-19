/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceGroupsConfig_UsersIns]
	@XMLData	NVARCHAR(MAX)
	,@GroupId	SMALLINT
	,@UserID	INT
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(2000) = '' OUTPUT
	
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config - Add Users to Group
	DB: DBCUST/CUSTDB
	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]
		
	Param's Explanation:
		 @XmlData
			<root>
				<r CustId="" Username="Supertest1" RoleId="5"/>
			</root>	
		               
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Xml XML = CONVERT(XML, @XmlData)

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @CustId INT = NULL
			,@RoleId TINYINT, @UserName VARCHAR(50), @IsView BIT
	SET @startRun = GETDATE();

	CREATE TABLE #Finance(ID INT IDENTITY(1, 1), CustId INT, Username VARCHAR(50), RoleId INT)
	INSERT INTO #Finance (CustId, Username ,RoleId)
	SELECT 
		t.c.value('@CustId', 'INT') AS Username
		,t.c.value('@Username', 'VARCHAR(50)') AS Username
		,t.c.value('@RoleId', 'INT') AS RoleId
	FROM @Xml.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@Xml = NULL))

	BEGIN TRY
		DELETE f WITH(ROWLOCK, UPDLOCK)
		FROM dbo.Acc_FinancePermission f 
		WHERE EXISTS (SELECT 1 FROM #Finance c WHERE c.Username = f.FinanceCode AND f.GroupId <> @GroupId)

		INSERT INTO dbo.Acc_FinancePermission (GroupId, FinanceCode, RoleId, IsView)
		SELECT @GroupId, f.Username, f.RoleId, 0
		FROM #Finance f
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 100, @ErrMsg = ''
		RETURN
	END CATCH

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	DECLARE @Id INT = 1

	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM #Finance f WHERE f.ID = @Id)
			BREAK

		SELECT @UserName = UserName, @RoleId = RoleId, @CustId = CustId FROM #Finance WITH(NOLOCK) WHERE ID = @Id

		SELECT @LogSPData = '<R GroupId="'+ COALESCE(CAST(@GroupId AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'CustId="'+ COALESCE(CAST(@CustId AS VARCHAR(20)), SPACE(1)) + '" ' +
							   'Username="'+ COALESCE(CAST(@Username AS VARCHAR(50)), SPACE(1)) + '" ' +
							   'RoleId="'+ COALESCE(CAST(@RoleId AS VARCHAR(5)), SPACE(1)) + '" ' +			   
							   'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' +
							   'ErrMsg="'+ COALESCE(CAST(@ErrMsg as VARCHAR(4000)),SPACE(1)) + '" />'
		
		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					 @UserID = @UserID, 
					 @CustID = @CustId,
					 @ActionID = 95004,
					 @TrackingValue = @LogSPData,
					 @duration = @duration
		
		SET @Id = @Id + 1
	END

	DROP TABLE #Finance
END
GO
