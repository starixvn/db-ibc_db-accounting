ALTER PROCEDURE [Acc_AutoFollowBetUpdRate]	
	@UserName		VARCHAR(50),
	@Rate			SMALLMONEY,
	@FollowLive		INT,
	@Handicap		BIT,
	@1stHandicap	BIT,
	@OverUnder		BIT,
	@1stOverUnder	BIT,
	@Follower		VARCHAR(30),

	@UserId			INT,
	@IP				VARCHAR(50),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTXN.CustDB
Revison:
	- 20131212@Kathy: - Remove @status, add new @param
					  - Separate Auto follow bet account for Live or Non-Live or All [Redmine:#9144] 
					  - Write log
	- 20140106@Kathy: Add param: @Follower [Redmine:#10329]

Param's Explanation:	

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @custid int, @custFollower int,
			@startRun Datetime, @endRun datetime, @duration int ,
			@oldRate smallmoney, @oldFollowLive int, @oldHandicap bit, @old1stHandicap bit,
			@oldOverUnder bit, @old1stOverUnder bit, @oldFollower varchar(30)

	SELECT @startRun = getdate(), @duration = 0

	SELECT @custid = custid
	FROM Custinfo with(nolock)
	WHERE username = @Username
	AND roleid = 1

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username, please try again!', @ErrCode = 101			
		RETURN
	END

	SELECT @custFollower = custid
	FROM Custinfo with(nolock)
	WHERE username = @Follower
	AND roleid = 1

	IF @@rowcount = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid follower, please try again!', @ErrCode = 102	
		RETURN
	END


	SELECT @oldRate = f.Rate, @oldFollowLive = f.FollowLive, @oldHandicap = f.Follow1,
			@old1stHandicap = f.Follow7, @oldOverUnder = f.Follow3, @old1stOverUnder = f.Follow8,
			@oldFollower = (SELECT c.username FROM custInfo c with(NOLOCK) WHERE c.custid = f.Follower AND c.roleid = 1)
	FROM Cust_FollowBet f WITH(NOLOCK)
	WHERE f.custid = @custid

	UPDATE Cust_followBet WITH(UPDLOCK, ROWLOCK)
	SET rate = @Rate,
		FollowLive = @FollowLive,
		Follow1 = @Handicap,
		Follow7 = @1stHandicap,
		Follow3 = @OverUnder,
		Follow8 = @1stOverUnder,
		Follower = @custFollower
	WHERE custid = @custid

	-- write log
	Declare @LogSPData varchar(MAX),@TrackingValueDB varchar(max)

	SELECT	@LogSPData =  '<Acc_AutoFollowBetUpdRate Username="'+ coalesce(@Username,space(1)) + '" '+
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

	SELECT	@TrackingValueDB =  '<Acc_AutoFollowBetUpdRate Username="'+ coalesce(@Username,space(1)) + '" '+
						  'Rate="'+ coalesce(cast(@oldRate as varchar(10)),space(1)) + '" '+
						  'FollowLive="'+ coalesce(cast(@oldFollowLive as varchar(1)),space(1)) + '" '+
						  'Handicap="'+ COALESCE(CAST(@oldHandicap AS VARCHAR(1)),SPACE(1))+'" '+
						  '1stHandicap="'+ coalesce(cast(@old1stHandicap as varchar(1)),space(1)) + '" '+
						  'OverUnder="'+ coalesce(cast(@oldOverUnder as varchar(1)),space(1))+'" '+
						  '1stOverUnder="'+ coalesce(cast(@old1stOverUnder as varchar(1)),space(1))+'" ' +
						  'Follower="'+ coalesce(cast(@oldFollower as varchar(30)),space(1))+'" ' +
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
			@ActionID = 640,
			@TrackingValue = @LogSPData	,
			@TrackingValue2 = @TrackingValueDB,
			@duration = @duration 
	END TRY
	BEGIN CATCH
		SELECT	@LogSPData =  '<Acc_AutoFollowBetUpdRate Username="'+ coalesce(@Username,space(1)) + '" '+
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
						  'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 640,
			@TrackingValue = @LogSPData	,
			@TrackingValue2 = @TrackingValueDB,
			@duration = @duration 
	END CATCH

END

GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetUpdRate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetUpdRate] TO [VNTeam]
GO