 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROCEDURE [dbo].[Acc_CustomerDelConsolidatedGroup]
	@CustIDList varchar(500),
	@groupID int,
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@IP varchar(15) = ''
AS
/*	
	Created: Sophia
	Date: 2011-07-12
	Task : Remove Customer from Consolidated Group  
	DB: DBAGE/bodb_AGE
	Original:  
	Revisions:		
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY
*/

SET NOCOUNT ON

DECLARE @startRun datetime
DECLARE @endRun datetime
DECLARE @duration int
SET @startRun = getdate()

--Check permission for account  
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ConsolidatedGroup]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
IF @ErrCode <> 0
	RETURN
 

UPDATE Age_CustGroup WITH (ROWLOCK, UPDLOCK)
SET GroupID = 0,
	Creator = @UserID,
	CreatedDate = getdate()
WHERE CustID IN ( SELECT val
				  FROM dbo.strSplit (@CustIDList, ','))
	AND isHeader <> 1

 
--Write log
DECLARE @LogData nvarchar(1000)

SELECT @LogData = 'GroupID="' + convert (VARCHAR(20), @groupID) + '" ' +
	   'IP="' + coalesce (cast (@IP AS VARCHAR(15)), space (1)) + '" ' +
	   'ErrCode="' + coalesce (cast (@ErrCode AS VARCHAR(10)), space (1)) + '" ' +
	   'ErrMsg="' + @ErrMsg + '" />'

--Write log

SET @endRun = getdate()
SET @duration  = datediff (millisecond,@startRun,@endRun)

INSERT INTO DBLOG.bodb_CustomerLog.dbo.UserLog_RunSP ( UserID
													 , CustID
													 , ActionID
													 , TrackingValue
													 , duration)
SELECT @UserID
	 , CustID
	 , 625
	 , '<Acc_CustomerDelConsolidatedGroup CustID="' + CustID + '" ' + @LogData
	 , @duration
FROM (
	  SELECT val CustID
	  FROM dbo.strSplit (@CustIDList, ',')
	 ) tbCust



GO
GRANT EXECUTE ON [dbo].[Acc_CustomerDelConsolidatedGroup] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerDelConsolidatedGroup] TO [vnteam]