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
		- 20220614@Danny: Use String_split built-in function [RemineID: #171831]

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
	SELECT f.value AS GroupId
	FROM STRING_SPLIT(@GroupIds, ',') f

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

		DECLARE @FinanceUser TABLE (CustId INT, UserName VARCHAR(30) DEFAULT(''), GroupId INT)

	    IF @UsernameList = ''
		BEGIN
			INSERT INTO @FinanceUser (UserName, GroupId)
			SELECT FinanceCode, GroupId
			FROM dbo.Acc_FinancePermission WITH(NOLOCK)
			WHERE RoleId > 4
		END
		ELSE
		BEGIN
			INSERT INTO @FinanceUser (UserName)
			SELECT DISTINCT f.value AS UserName
			FROM STRING_SPLIT(@UsernameList, ',') f

			UPDATE f
				SET f.GroupId = a.GroupId
			FROM @FinanceUser f
				INNER JOIN dbo.Acc_FinancePermission a WITH(NOLOCK) ON a.FinanceCode = f.UserName 
			WHERE a.RoleId > 4

			DELETE u FROM @FinanceUser u WHERE u.GroupId IS NULL		
		END
		
		UPDATE u
		 SET u.CustId = n.custid
		FROM @FinanceUser u
		CROSS APPLY (
			SELECT CustId FROM dbo.Customer c WITH(NOLOCK) WHERE c.username = U.UserName 
		) AS n

		SELECT @NRows = COUNT(1) FROM @FinanceUser WHERE (GroupId IN (SELECT GroupId FROM @GroupList) OR @GroupIds = '')

		SELECT n.CustId, n.UserName, n.GroupId
		FROM 
		(	
			SELECT CustId, UserName, GroupId, ROW_NUMBER() OVER(ORDER BY GroupId ASC, UserName ASC) AS rn
			FROM @FinanceUser
			WHERE (GroupId IN (SELECT GroupId FROM @GroupList) OR @GroupIds = '')
		) AS n
		WHERE n.rn BETWEEN @RowStart AND @RowEnd
		ORDER BY n.rn ASC
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
				SET u.SuperName 	= ISNULL(n.SuperName, '')
					,u.MasterName 	= ISNULL(n.MasterName, '')
					,u.AgentName 	= ISNULL(n.AgentName, '')
					,u.UserName 	= ISNULL(n.username, '')
			FROM @FinanceCode u
			CROSS APPLY (
				SELECT 
					MAX(CASE WHEN c.roleid = 1 THEN c.username ELSE '' END) AS UserName
					,MAX(CASE WHEN c.roleid = 2 THEN c.username ELSE '' END) AS AgentName
					,MAX(CASE WHEN c.roleid = 3 THEN c.username ELSE '' END) AS MasterName
					,MAX(CASE WHEN c.roleid = 4 THEN c.username ELSE '' END) AS SuperName
				FROM dbo.Customer c WITH(NOLOCK)
				WHERE c.custid IN (u.CustId, u.Recommend, u.Mrecommend, u.Srecommend)
			) AS n
			
		END	
		ELSE IF @UsernameList <> ''
		BEGIN
			INSERT INTO @FinanceCode (UserName)
			SELECT f.value AS UserName
			FROM STRING_SPLIT(@UsernameList, ',') f

			UPDATE u
				SET u.Recommend = n.Recommend, u.Mrecommend = n.Mrecommend, u.Srecommend = n.Srecommend, u.CustId = n.custid, u.RoleId = n.roleid
			FROM @FinanceCode u
			CROSS APPLY (
				SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, c.roleid
				FROM dbo.Customer c WITH(NOLOCK)
				WHERE c.username = u.UserName
			) n

			DELETE @FinanceCode WHERE CustId IS NULL

			-- Get Downlines
			IF EXISTS (SELECT 1 FROM @FinanceCode WHERE RoleId = 4)
			BEGIN
				INSERT INTO @FinanceCode (Username, CustId, Recommend, Mrecommend, Srecommend)
				SELECT n.username, n.custid, n.recommend, n.mrecommend, n.srecommend
				FROM @FinanceCode f
				CROSS APPLY (
					SELECT c.username, c.custid, c.recommend, c.mrecommend, c.srecommend
					FROM dbo.Acc_FinancePermission a WITH(NOLOCK)
						INNER JOIN dbo.Customer c WITH(NOLOCK) ON c.username = a.FinanceCode
					WHERE c.roleid < 4 AND c.srecommend = f.CustId 
				) AS n
				WHERE f.RoleId = 4
			END

			IF EXISTS (SELECT 1 FROM @FinanceCode WHERE RoleId = 3)
			BEGIN
				INSERT INTO @FinanceCode (Username, CustId, Recommend, Mrecommend, Srecommend)
				SELECT n.username, n.custid, n.recommend, n.mrecommend, n.srecommend
				FROM @FinanceCode f
				CROSS APPLY (
					SELECT c.username, c.custid, c.recommend, c.mrecommend, c.srecommend
					FROM dbo.Acc_FinancePermission a WITH(NOLOCK)
						INNER JOIN dbo.Customer c WITH(NOLOCK) ON c.username = a.FinanceCode
					WHERE c.roleid < 4 AND c.mrecommend = f.CustId 
				) AS n
				WHERE f.RoleId = 3 AND RoleId IS NOT NULL
			END

			IF EXISTS (SELECT 1 FROM @FinanceCode WHERE RoleId = 2)
			BEGIN
				INSERT INTO @FinanceCode (Username, CustId, Recommend, Mrecommend, Srecommend)
				SELECT n.username, n.custid, n.recommend, n.mrecommend, n.srecommend
				FROM @FinanceCode f
				CROSS APPLY (
					SELECT c.username, c.custid, c.recommend, c.mrecommend, c.srecommend
					FROM dbo.Acc_FinancePermission a WITH(NOLOCK)
						INNER JOIN dbo.Customer c WITH(NOLOCK) ON c.username = a.FinanceCode
					WHERE c.roleid < 2 AND c.recommend = f.CustId 
				) AS n
				WHERE f.RoleId = 2 AND f.RoleId IS NOT NULL
			END

			UPDATE u
				SET u.SuperName 	= ISNULL(n.SuperName, '')
					,u.MasterName 	= ISNULL(n.MasterName, '')
					,u.AgentName 	= ISNULL(n.AgentName, '')
					,u.UserName 	= ISNULL(n.username, '')
			FROM @FinanceCode u
			CROSS APPLY (
				SELECT 
					MAX(CASE WHEN c.roleid = 1 THEN c.username ELSE '' END) AS UserName
					,MAX(CASE WHEN c.roleid = 2 THEN c.username ELSE '' END) AS AgentName
					,MAX(CASE WHEN c.roleid = 3 THEN c.username ELSE '' END) AS MasterName
					,MAX(CASE WHEN c.roleid = 4 THEN c.username ELSE '' END) AS SuperName
				FROM dbo.Customer c WITH(NOLOCK)
				WHERE c.custid IN (u.CustId, u.Recommend, u.Mrecommend, u.Srecommend)
			) AS n

			INSERT INTO @FinanceCode 
			(
				GroupId
				,FinanceCode
				,RoleId
				,IsView
				,Username
				,AgentName
				,MasterName
				,SuperName	
			)
			SELECT DISTINCT
				n.GroupId
				,k.FinanceCode
				,k.RoleId
				,k.IsView
				,CASE WHEN k.RoleId >= 2 THEN '' ELSE u.Username END
				,CASE WHEN k.RoleId >= 3 THEN '' ELSE u.AgentName END
				,CASE WHEN k.RoleId >= 4 THEN '' ELSE u.MasterName END
				,SuperName	
			FROM @FinanceCode u
			CROSS APPLY (
				SELECT a.GroupId
				FROM dbo.Acc_FinancePermission a WITH(NOLOCK)
				WHERE a.FinanceCode IN (u.UserName, u.AgentName, u.MasterName, u.SuperName) AND a.GroupId NOT IN (0, 1) AND (a.GroupId IN (SELECT GroupId FROM @GroupList) OR @GroupIds = '')
			) AS n
			CROSS APPLY (
				SELECT TOP(1) a.FinanceCode, a.RoleId, a.IsView
				FROM dbo.Acc_FinancePermission a WITH(NOLOCK)
				WHERE a.FinanceCode IN (u.UserName, u.AgentName, u.MasterName, u.SuperName) AND n.GroupId = a.GroupId
				ORDER BY a.RoleId ASC
			) AS k

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
		ORDER BY n.rn ASC
	END
END
GO
