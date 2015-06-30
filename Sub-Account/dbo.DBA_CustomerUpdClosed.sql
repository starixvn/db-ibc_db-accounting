ALTER PROCEDURE [dbo].[DBA_CustomerUpdClosed]
@CustID		INT = 0,
@SubAccID	INT = 0,
@UserID		INT = 5838421 --dbaAdmin  
AS
/*
	Created by: Jamie
	Task: DBA  - Close the account failed login 200 times 
	DB: DBTRANS.BODB02 
	
	Revisions: 
	
	Execution Sample: 
		EXEC dbo.DBA_CustomerUpdClosed @CustID = xxx, @SubAccID = xxx 
	
*/
SET NOCOUNT ON 

DECLARE @LogSPData VARCHAR(2000)

IF @CustID <> 0 
BEGIN
	UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
	SET closed = 1 
	WHERE	custid = @CustID 
	
	
	SELECT	@LogSPData = '<DBA_CustomerUpdClosed CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" ' +
						'Closed="1" ' +
						'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
						+ ' />'
					
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 1140,
		@TrackingValue = @LogSPData	,
		@duration = NULL
END 


IF @SubAccID <> 0 
BEGIN
	SELECT	@CustID = custid
	FROM    CustSub WITH (NOLOCK)
	WHERE	SubaccID = @SubAccID

	UPDATE	CustSub WITH (UPDLOCK, ROWLOCK)
	SET		Closed = 1
	WHERE	SubaccID = @SubAccID
		

	SELECT	@LogSPData = '<DBA_CustomerUpdClosed SubaccID="'+ coalesce(cast(@SubAccID as varchar(50)),space(1)) + '" ' +
						'Closed="1" ' +
						'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
						'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
						+' />'
					
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 1141,
		@TrackingValue = @LogSPData	,
		@duration = NULL
END 




