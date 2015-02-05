USE [bodb_licensee]
GO
 
ALTER PROCEDURE [dbo].[DBA_Lrf_EnablePlayerComm]
(	
	@LicenseeName  VARCHAR(500)
)
AS
/*
Created: 20140502@Jim
Task : re-structure create new licensee flow
DB: DBLIC.bodb_licensee
Original :
	
Revisions:
	
Param's Explanation:

	
*/
BEGIN
	DECLARE  @tblLicensee   AS TABLE ([id] [int] IDENTITY(1,1) ,LicenseeID INT)
	DECLARE  @tblFunctionComm  AS TABLE ( FunctionID INT ) 
	DECLARE  @tblLicenseeUser  AS TABLE ([id] INT IDENTITY(1,1), UserId INT)
	DECLARE  @LicenseeID INT
			 ,@i		 INT
			 ,@maxID	 INT
			 ,@j		 INT
			 ,@maxUserId INT
			 ,@UserId	INT
			 
	INSERT INTO @tblLicensee (LicenseeID)
	SELECT l.LicenseeID
	FROM dbo.Licensees l WITH (NOLOCK)
	WHERE l.licenseename IN (
							SELECT  val AS LicenseeName
							FROM bodb02.dbo.strSplit(@LicenseeName,',')
						) 
	UPDATE dbo.Licensees WITH(ROWLOCK,UPDLOCK)
	SET IsAllowedMemberComm = 1
	FROM dbo.Licensees l
		INNER JOIN @tblLicensee t ON t.licenseeID = l.licenseeID
	
	INSERT INTO @tblFunctionComm (FunctionId )
	SELECT FunctionId 
	FROM dbo.Functions WITH (NOLOCK)
	WHERE ParentId = 4 

	SELECT @i = 1,@maxID = MAX(ID) FROM  @tblLicensee
	WHILE  (@i<@maxID + 1)
		BEGIN 
			
			SELECT  @LicenseeID = LicenseeID 
			FROM @tblLicensee
			WHERE ID = @i	
			
			IF NOT EXISTS (SELECT 1 FROM dbo.LicenseeCustComm (NOLOCK) WHERE LicenseeID = @LicenseeID)
			BEGIN
				--- initial data
				INSERT INTO  LicenseeCustComm (LicenseeID
												,CustID
												,SBComm
												,RacingComm
												,NGComm
												,GroupCommID
												,LCComm
												,RNGComm)
				SELECT t.LicenseeID
					  ,lci.CustID
					  ,0 as SBComm
					  ,0 as RacingComm
					  ,0 as NGComm
					  ,0 as GroupCommID
					  ,0 as LCComm
					  ,0 as RNGComm
				FROM @tblLicensee t
					INNER JOIN dbo.LicenseeCust  lc WITH (NOLOCK) ON t.LicenseeID  = lc.LicenseeID
					INNER JOIN dbo.LicenseeCustinfo lci WITH (NOLOCK) ON lc.CustID = lci.recommend
				WHERE t.ID = @i
					AND lci.CustID NOT IN (SELECT CustId FROM LicenseeCustComm WITH (NOLOCK) )
					
				--- grant comm function permission 
				INSERT INTO  dbo.LicenseeFunctions (LicenseeId
													,FunctionId
													)
				SELECT @licenseeid
						,functionid
				FROM @tblFunctioncomm
				WHERE functionid NOT IN (SELECT functionid 
											 FROM dbo.LicenseeFunctions WITH (NOLOCK) 
											 WHERE licenseeid = @licenseeid 
										 )
				
				INSERT INTO  @tbllicenseeuser (userid)
				SELECT DISTINCT lu.userid
				FROM dbo.LicenseeUser lu WITH (NOLOCK)
					INNER JOIN  dbo.users u WITH (NOLOCK) ON lu.userid=u.userid
				WHERE lu.isactive = 1
					 AND lu.licenseeid = @licenseeid
					
				SELECT @j =1 
						,@maxUserId = MAX(Id)
				FROM @tbllicenseeuser
				WHILE (@j<= @maxUserId)
				BEGIN
					SELECT 	@UserId = UserId
					FROM  @tbllicenseeuser
					WHERE ID = @j
					
					INSERT INTO [dbo].[LicenseeUserFunctions] (userid
															   ,functionid
															   ,licenseeid
															  )
					SELECT  DISTINCT @userid userid
						   ,lf.functionid
						   ,@licenseeid licenseeid
					FROM dbo.LicenseeFunctions lf WITH (NOLOCK)
						INNER JOIN @tblFunctioncomm f ON lf.functionid = f.functionid
					WHERE lf.functionid NOT IN (SELECT functionid 
												FROM dbo.LicenseeUserFunctions WITH (NOLOCK)
												WHERE licenseeid = @licenseeid
													  AND userid = @userid
												)	
						AND licenseeid=@licenseeid							 
					
					SET @j = @j +1
				END
				SET @i = @i+1
			END	
		END	
 
END