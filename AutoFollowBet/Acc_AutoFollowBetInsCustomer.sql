ALTER PROCEDURE [Acc_AutoFollowBetInsCustomer]	
	@Username varchar(30),
	@Rate smallmoney,
	@FollowLive		INT,
	@Handicap		BIT,
	@1stHandicap	BIT,
	@OverUnder		BIT,
	@1stOverUnder	BIT,
	@Follower		VARCHAR(30),

	@UserId			INT,
	@IP				VARCHAR(50),
	@ErrCode int = 0 Output,
	@ErrMsg nvarchar(200) = '' Output
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTXN.CustDB

Revision:
	- 20131212@Kathy: - Remove @status, add new @param
					  - Separate Auto follow bet account for Live or Non-Live or All [Redmine:#9144]
					  - Write log
	- 20140106@Kathy: Add param: @Follower [Redmine:#10329]
Param's Explanation:	
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun Datetime, @endRun datetime, @duration int 
	SELECT @startRun = getdate(), @duration = 0

	DECLARE @custid INT, @custFollow INT

	SELECT @custid = custid
	FROM Custinfo with(nolock)
	WHERE username = @Username
		AND roleid = 1

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username, please try again!', @ErrCode = 101			
		RETURN
	END

	IF EXISTS (SELECT TOP 1 1 FROM Cust_followBet WITH(NOLOCK) WHERE custid = @custid)
	BEGIN
		SELECT @ErrMsg = 'Username existed, please try again!', @ErrCode = 102		
		RETURN
	END
	
	SELECT @custFollow = c.custid
	from custInfo c WITH(NOLOCK)
	WHERE c.username = @Follower
	AND c.roleid = 1

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid follower, please try again!', @ErrCode = 103			
		RETURN
	END

	INSERT INTO Cust_followBet(custid, Rate, src, FollowLive, Follow1, Follow3, Follow7, Follow8, Follower)
	VALUES (@custid, @Rate,0, @FollowLive, @Handicap, @OverUnder, @1stHandicap, @1stOverUnder, @custFollow)

	-- write log
	Declare @LogSPData varchar(MAX)

	SELECT	@LogSPData =  '<Acc_AutoFollowBetInsCustomer Username="'+ coalesce(@Username,space(1)) + '" '+
						  'Rate="'+ coalesce(cast(@Rate as varchar(10)),space(1)) + '" '+
						  'FollowLive="'+ coalesce(cast(@FollowLive as varchar(1)),space(1)) + '" '+
						  'Handicap="'+ COALESCE(CAST(@Handicap AS VARCHAR(1)),SPACE(1))+'" '+
						  '1stHandicap="'+ coalesce(cast(@1stHandicap as varchar(1)),space(1)) + '" '+
						  'OverUnder="'+ coalesce(cast(@OverUnder as varchar(1)),space(1))+'" '+
						  '1stOverUnder="'+ coalesce(cast(@1stOverUnder as varchar(1)),space(1))+'" ' +
						  'Follower="'+ coalesce(cast(@Follower as varchar(30)),space(1))+'" ' +
						  'UserId="'+ coalesce(cast(@UserId as varchar(50)),space(1)) + '" '+
						  'IP="'+ coalesce(cast(@IP as varchar(50)),space(1)) + '" '+
						  'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" '+
						  'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)


	BEGIN TRY											  						  	 
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 639,
			@TrackingValue = @LogSPData	,
			@duration = @duration 
	END TRY
	BEGIN CATCH
		SELECT	@LogSPData =  '<Acc_AutoFollowBetInsCustomer Username="'+ coalesce(@Username,space(1)) + '" '+
						  'Rate="'+ coalesce(cast(@Rate as varchar(10)),space(1)) + '" '+
						  'FollowLive="'+ coalesce(cast(@FollowLive as varchar(1)),space(1)) + '" '+
						  'Handicap="'+ COALESCE(CAST(@Handicap AS VARCHAR(1)),SPACE(1))+'" '+
						  '1stHandicap="'+ coalesce(cast(@1stHandicap as varchar(1)),space(1)) + '" '+
						  'OverUnder="'+ coalesce(cast(@OverUnder as varchar(1)),space(1))+'" '+
						  '1stOverUnder="'+ coalesce(cast(@1stOverUnder as varchar(1)),space(1))+'" ' +
						  'Follower="'+ coalesce(cast(@Follower as varchar(30)),space(1))+'" ' +
						  'UserId="'+ coalesce(cast(@UserId as varchar(50)),space(1)) + '" '+
						  'IP="'+ coalesce(cast(@IP as varchar(50)),space(1)) + '" '+
						  'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" '+
						  'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'"  />'
		
		
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 639,
			@TrackingValue = @LogSPData	,
			@duration = @duration 
	END CATCH

END

GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetInsCustomer] TO [VNTeam]
GO