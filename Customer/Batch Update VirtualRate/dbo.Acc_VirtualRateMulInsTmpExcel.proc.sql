ALTER PROC [dbo].[Acc_VirtualRateMulInsTmpExcel]	
	@UserID INT,
	@arrUsernames NVARCHAR(4000),
	@arrVirtualRates NVARCHAR(4000),	
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 
	Task : Insert new multi virtual rates into Acc_CustVirtualRate
	DB: DBACC/BODB_ACC
	Original: 
	Revisions:	
		- 20090812@Simon: Insert new multi virtual rates into Acc_CustVirtualRate
		- 20090919@Jamie: Check data before inserting 
		- 20091116@Daniel: Change to check permission on dedicated function [UploadVR]
		- 20130224@Lukas: move SP to new database bodb_ACC
						& change linked-server from db03 to DBPOLICY
		- 20131203@Elodie: Expand size of string						
*/
BEGIN
SET NOCOUNT ON
			
	--Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UploadVR]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	DECLARE @tblCust TABLE (
		UserName	NVARCHAR(50),
		VirtualRate	NVARCHAR(10)
	)

	DECLARE @tblFail TABLE (
		UserName	NVARCHAR(50),
		VirtualRate	NVARCHAR(10),
		Reason		NVARCHAR(100)
	)

	INSERT INTO @tblCust(username, virtualrate)
	SELECT	a.val, 
			b.val 
	FROM	dbo.strSplit(@arrUsernames, CHAR(8)) a
			INNER JOIN dbo.strSplit(@arrVirtualRates, CHAR(8)) b ON a.RANK=b.RANK
	WHERE  ISNULL(a.val,'') != ''

	INSERT INTO @tblFail(username, virtualrate, reason)
	SELECT	username, virtualrate, 
			CASE WHEN ISNUMERIC(VirtualRate)=0 THEN 'Invalid virtual rate.'
				 WHEN (ISNUMERIC(VirtualRate)=1  AND (CAST(VirtualRate AS SMALLMONEY)<-0.8 OR CAST(VirtualRate AS SMALLMONEY)>0.6 OR CAST(VirtualRate AS SMALLMONEY)*100%5!=0) ) THEN 'Virtual rate must be in a range from -80% to +60% and be multiples of 5%.'
				 WHEN ISNULL(username,'') ='' THEN 'Username cannot be blanked.' ELSE '' END AS Reason 	
	FROM	@tblCust 
	WHERE	ISNUMERIC(VirtualRate)=0 
			OR (ISNUMERIC(VirtualRate)=1  AND (CAST(VirtualRate AS SMALLMONEY)<-0.8 OR CAST(VirtualRate AS SMALLMONEY)>0.6 OR CAST(VirtualRate AS SMALLMONEY)*100%5!=0) )
			OR ISNULL(username,'') ='' 
	
	INSERT INTO dbo.Acc_CustVirtualRate(userid, username, virtualrate)
	SELECT	@UserID, 
			username,
			CAST(virtualrate AS SMALLMONEY)
	FROM	@tblCust 
	WHERE	username NOT IN ( SELECT username FROM @tblFail)
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrMsg = 'Insert process is unsuccessful.',
				@ErrCode = 103
		RETURN			
	END
	
	SELECT * FROM @tblFail 
END

GO
GRANT EXECUTE ON [dbo].[Acc_VirtualRateMulInsTmpExcel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_VirtualRateMulInsTmpExcel] TO [vnteam] AS [dbo]