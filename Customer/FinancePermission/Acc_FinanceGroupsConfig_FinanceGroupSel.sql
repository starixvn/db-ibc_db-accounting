/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_FinanceGroupsConfig_FinanceGroupSel]
	@GroupIds	    VARCHAR(400) = ''
	,@UsernameList	VARCHAR(MAX) = ''
	,@FinanceType	INT
	,@Level			TINYINT = NULL
	,@IsView		BIT = NULL
	,@PageSize 		INT = 50
	,@PageIndex 	INT = 1
	,@NRows 		INT = 0 OUTPUT
	
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config
	DB: DBCUST/CUSTDB

	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]

	Param's Explanation:
		@FinanceType = 1 : Finance User
					 = 2 : Finance Code	               
*/

BEGIN
	SET NOCOUNT ON

	SELECT @UsernameList = ISNULL(@UsernameList, ''), @GroupIds = ISNULL(@GroupIds, '')

	DECLARE @RowStart INT, @RowEnd INT, @SuperName VARCHAR(30), @MasterName VARCHAR(30), @AgentName VARCHAR(30), @UserName VARCHAR(30)

	SELECT @RowStart = (@PageIndex - 1) * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1

	DECLARE @GroupList TABLE (GroupId INT)

	INSERT INTO @GroupList (GroupId)
	SELECT f.val AS GroupId
	FROM dbo.f_StringSplit(@GroupIds, ',') f
	OPTION (MAXRECURSION 0)

	IF @FinanceType = 1
	BEGIN
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

		DECLARE @DepartmentGroupId INT

		SELECT @DepartmentGroupId = GroupID FROM NAP_UserControl.dbo.acc_groupinfo WITH(NOLOCK) WHERE GroupName  = 'Finance' AND System = 'ACCOUNTING'

		DECLARE @FinanceUser TABLE (CustId INT, UserName VARCHAR(30) DEFAULT(''), GroupId INT)

	    IF @UsernameList = ''
		BEGIN
			INSERT INTO @FinanceUser (CustId, UserName)
			SELECT a.custid, c.Username
			FROM NAP_UserControl.dbo.acccustomer a WITH(NOLOCK)
				INNER JOIN dbo.Customer c WITH(NOLOCK) ON c.custid = a.custid 
			WHERE (a.GroupID = @DepartmentGroupId OR c.username LIKE 'Starix%') AND a.custid NOT IN (SELECT custid FROM @ABS)
		END
		ELSE
		BEGIN
			INSERT INTO @FinanceUser (UserName)
			SELECT f.val AS UserName
			FROM dbo.f_StringSplit(@UsernameList, ',') f
			OPTION (MAXRECURSION 0)

			UPDATE u
				SET u.CustId = n.custid
			FROM @FinanceUser u
			CROSS APPLY (
				SELECT CustId FROM dbo.Customer c WHERE c.username = U.UserName 
			) AS n

			DELETE u
			FROM @FinanceUser u	
			WHERE NOT EXISTS (
				SELECT 1 
				FROM NAP_UserControl.dbo.acccustomer a WITH(NOLOCK) 
				WHERE (a.GroupID = @DepartmentGroupId OR u.UserName LIKE 'Starix%') AND a.custid NOT IN (SELECT custid FROM @ABS) 
				AND a.custid = u.CustId
			)

		END
		
		UPDATE f
			SET f.GroupId = a.GroupId
		FROM @FinanceUser f
			INNER JOIN dbo.Acc_FinancePermission a WITH(NOLOCK) ON a.FinanceCode = f.UserName 

		SELECT @NRows = COUNT(1) FROM @FinanceUser

		SELECT n.CustId, n.UserName, n.GroupId
		FROM 
		(	
			SELECT CustId, UserName, GroupId, ROW_NUMBER() OVER(ORDER BY UserName ASC) AS rn
			FROM @FinanceUser
			WHERE (GroupId IN (SELECT GroupId FROM @GroupList) OR @GroupIds = '')
		) AS n
		WHERE n.rn BETWEEN @RowStart AND @RowEnd
	END
	ELSE
	BEGIN
		DECLARE @FinanceCode TABLE 
		(
			SuperName		VARCHAR(30) DEFAULT('')
			,MasterName		VARCHAR(30) DEFAULT('')
			,AgentName		VARCHAR(30) DEFAULT('')
			,Username		VARCHAR(30) DEFAULT('')
			,Srecommend		INT DEFAULT (0)
			,Mrecommend		INT DEFAULT (0)
			,Recommend		INT DEFAULT (0)
			,CustId			INT DEFAULT (0)
			,FinanceCode	VARCHAR(30)
			,IsView			BIT
			,GroupId		SMALLINT
			,RoleId         TINYINT
		)

		IF @UsernameList = ''
		BEGIN	
			INSERT INTO @FinanceCode (SuperName, MasterName, AgentName, Username, IsView, GroupId, RoleId, FinanceCode)
			SELECT 
				CASE WHEN RoleId = 4 THEN FinanceCode ELSE '' END AS SuperName
				,CASE WHEN RoleId = 3 THEN FinanceCode ELSE '' END AS MasterName
				,CASE WHEN RoleId = 2 THEN FinanceCode ELSE '' END AS AgentName
				,CASE WHEN RoleId = 1 THEN FinanceCode ELSE '' END AS Username
				,IsView
				,GroupId
				,RoleId
				,FinanceCode
			FROM dbo.Acc_FinancePermission WITH(NOLOCK)
			WHERE RoleId <= 4 AND GroupId NOT IN (0, 1) 
				AND (@Level IS NULL OR RoleId = @Level) 
				AND (@IsView IS NULL OR IsView = @IsView) 
				AND (GroupId IN (SELECT GroupId FROM @GroupList) OR @GroupIds = '')

			UPDATE f
				SET f.CustId = n.Custid, f.Recommend = n.Recommend, f.Mrecommend = n.Mrecommend, f.Srecommend = n.Srecommend
			FROM @FinanceCode f
			CROSS APPLY (
				SELECT c.Custid, c.Recommend, c.Mrecommend, c.Srecommend
				FROM dbo.Customer c WITH(NOLOCK)
				WHERE c.username IN (f.FinanceCode)
			) AS n

			UPDATE u
				SET u.SuperName = s.username
					,u.MasterName = m.username
					,u.AgentName = r.username
					,u.UserName = p.username
			FROM @FinanceCode u
			OUTER APPLY (SELECT c.CustId, c.UserName FROM dbo.Customer c WITH(NOLOCK) WHERE c.custid = U.CustId) AS p
			OUTER APPLY (SELECT c.CustId, c.UserName FROM dbo.Customer c WITH(NOLOCK) WHERE c.custid = U.Recommend) AS r
			OUTER APPLY (SELECT c.CustId, c.UserName FROM dbo.Customer c WITH(NOLOCK) WHERE c.custid = U.Mrecommend) AS m
			OUTER APPLY (SELECT c.CustId, c.UserName FROM dbo.Customer c WITH(NOLOCK) WHERE c.custid = U.Srecommend) AS s
			
		END	
		ELSE IF @UsernameList <> ''
		BEGIN
			INSERT INTO @FinanceCode (UserName)
			SELECT f.val AS UserName
			FROM dbo.f_StringSplit(@UsernameList, ',') f
			OPTION (MAXRECURSION 0)

			UPDATE u
				SET u.Recommend = n.Recommend, u.Mrecommend = n.Mrecommend, u.Srecommend = n.Srecommend, u.CustId = n.custid
			FROM @FinanceCode u
			CROSS APPLY (
				SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
				FROM dbo.Customer c WITH(NOLOCK)
				WHERE c.username = u.UserName
			) n

			UPDATE u
				SET u.SuperName = s.username
					,u.MasterName = m.username
					,u.AgentName = r.username
					,u.UserName = p.username
			FROM @FinanceCode u
			OUTER APPLY (SELECT c.CustId, c.UserName FROM dbo.Customer c WITH(NOLOCK) WHERE c.custid = U.CustId) AS p
			OUTER APPLY (SELECT c.CustId, c.UserName FROM dbo.Customer c WITH(NOLOCK) WHERE c.custid = U.Recommend) AS r
			OUTER APPLY (SELECT c.CustId, c.UserName FROM dbo.Customer c WITH(NOLOCK) WHERE c.custid = U.Mrecommend) AS m
			OUTER APPLY (SELECT c.CustId, c.UserName FROM dbo.Customer c WITH(NOLOCK) WHERE c.custid = U.Srecommend) AS s

			INSERT INTO @FinanceCode 
			(
				UserName	
				,AgentName   
				,MasterName  
				,SuperName   
				,IsView			
				,FinanceCode 
				,RoleId      
				,GroupId		
			)
			SELECT DISTINCT
				 CASE WHEN n.RoleId >= 2 THEN '' ELSE u.UserName   END
				,CASE WHEN n.RoleId >= 3 THEN '' ELSE u.AgentName  END   
				,CASE WHEN n.RoleId >= 4 THEN '' ELSE u.MasterName END
				,u.SuperName   
				,n.IsView			
				,n.FinanceCode 
				,n.RoleId      
				,n.GroupId
			FROM @FinanceCode u
			CROSS APPLY (
				SELECT TOP(1) a.GroupId, a.RoleId, a.IsView, a.FinanceCode
				FROM dbo.Acc_FinancePermission a WITH(NOLOCK)
				WHERE a.FinanceCode IN (u.UserName, u.AgentName, u.MasterName, u.SuperName) AND a.GroupId NOT IN (0, 1) AND (GroupId IN (SELECT GroupId FROM @GroupList) OR @GroupIds = '')
				ORDER BY a.RoleId ASC
			) AS n

			DELETE @FinanceCode WHERE GroupId IS NULL

			IF @Level IS NOT NULL 
			BEGIN
				DELETE u FROM @FinanceCode u WHERE u.RoleId <> @Level
			END

			IF @IsView IS NOT NULL
			BEGIN
				DELETE u FROM @FinanceCode u WHERE u.IsView <> @IsView
			END
		END
		
		SELECT @NRows = COUNT(1) FROM @FinanceCode

		SELECT SuperName, MasterName, AgentName, Username, FinanceCode, IsView, GroupId, RoleId
		FROM
		(
			SELECT SuperName, MasterName, AgentName, Username, FinanceCode, IsView, GroupId, RoleId
				   ,ROW_NUMBER() OVER(ORDER BY GroupId ASC, SuperName ASC, MasterName ASC, AgentName ASC, Username ASC, IsView DESC) AS rn   
		FROM @FinanceCode
		) AS n
		WHERE n.rn BETWEEN @RowStart AND @RowEnd
	END
END
GO
