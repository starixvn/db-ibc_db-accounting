
ALTER PROCEDURE [dbo].[Admin_Settlement_BetDaq_Move]
	@MatchID		INT,
	@NewMatchID		INT,
	@Creator		INT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(100)='' OUTPUT,  
	@NewMatchcode	NVARCHAR(20) ='' OUTPUT,
	@IP varchar(15) = ''
AS
/*
	Created: Jamie
	Date: 2009-09-12
	Task: Move BetDaq to new match 
	DB: DBTRANS.BODB02 

	Revisions: 
			- @20091025:  agent MTEST0101: 1688156 (requested by Erica)
			- 20091225@Daniel: writelog to table Userlog_settle
			- 20100305@Daniel: Add back writelog to table Userlog
			- 20100602@Shifu: Allow to choose destination match when Moving BetDaq tickets
			- 20100720@Henry: Change SP Logfile to WriteLog_UserLog
			- 20101001@Henry: Using f_GetBetDaqCustomer to query betdaq customer
			- 20101013@Henry: add custid 1077687 (BFOS as betdaq member)
			- 20110620@Jamie: Refer to Match/Odds on DB02 instead of DBTRANS
			- 20120930@Lukas: Put servername to control SP execution
	Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem

	

	Param's Explanation: 
		@MatchID: current match 

*/
BEGIN
	SET NOCOUNT ON
	DECLARE	@awayID			INT,
			@homeID			INT,
			@leagueID		INT,
			@eventdate		DATETIME,			
			@newEventdate	DATETIME,
			@matchcode	VARCHAR(20)

	DECLARE @finalhomescore INT, @finalawayscore INT,
			@hthomescore INT, @htawayscore INT,
			@betstatus nvarchar(50), @goalrecord varchar(50), @Remark varchar(50)

	DECLARE @finalhomescore1 INT, @finalawayscore1 INT,
			@hthomescore1 INT, @htawayscore1 INT,
			@betstatus1 nvarchar(50), @goalrecord1 varchar(50), @Remark1 varchar(50)

	DECLARE @tmpOdds TABLE (
		bettype		INT,
		oddsid		INT
	)
	
	SELECT	@awayID		= awayID,
			@homeID		= homeID,
			@leagueID	= leagueID,
			@eventdate	= eventdate,
			@finalhomescore = finalhomescore,
			@finalawayscore = finalawayscore,
			@hthomescore = hthomescore, 
			@htawayscore = htawayscore,
			@goalrecord = goalrecord,
			@betstatus = betstatus,
			@matchcode = matchcode
	FROM	DB02.BODB02.dbo.Match WITH (NOLOCK)
	WHERE	matchid = @MatchID 

	SELECT	@NewMatchcode	= matchcode, 
			@newEventdate	= eventdate,
			@finalhomescore1 = finalhomescore,
			@finalawayscore1 = finalawayscore,
			@hthomescore1 = hthomescore, 
			@htawayscore1 = htawayscore,
			@goalrecord1 = goalrecord,
			@betstatus1 = betstatus   
	FROM	DB02.BODB02.dbo.match WITH (NOLOCK) 
	WHERE	matchid = @NewMatchID
	
	INSERT INTO @tmpOdds ( bettype, oddsid)
	SELECT	bettype, max(oddsid)
	FROM	DB02.BODB02.dbo.odds WITH (NOLOCK)
	WHERE	matchid = @NewMatchID 
			AND liveindicator = 0 
	GROUP BY bettype 

	UPDATE	bettrans WITH (ROWLOCK,UPDLOCK)
	SET		matchid		= @NewMatchID, 
			oddsid		= o.oddsid, 
			winlostdate = @newEventdate  
	FROM	bettrans b
			INNER JOIN @tmpOdds o ON b.bettype = o.bettype 
	WHERE	b.matchid = @MatchID 
			AND (b.custid IN (50057, 879241, 103873, 78761,1077687) or b.recommend = 1688156)
			/*
			AND (
				b.custid IN (Select CustID from  [f_GetBetDaqCustomer] (1)) 
				or b.recommend IN (Select CustID from  [f_GetBetDaqCustomer] (2))
				)
			*/	
			AND b.ruben = 0
	IF @@ERROR <>0
	BEGIN
		SELECT	@ErrCode = 103,
				@ErrMsg  =  'Moving match is not successful!'
		RETURN
	END

	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		DECLARE	@LogData VARCHAR(200)
		SELECT	@LogData = 'BetDaq Movement from OldMatch:' + CAST(@matchid AS VARCHAR(15))+ ', NewMatch:' + CAST(@newMatchid AS VARCHAR(15))
		EXEC dbo.WriteLog_UserLog @userid = @Creator, @Doing = @LogData  
		
		
		--Write Log Settle
		SELECT @Remark = 'To match ' + convert(varchar(10),@NewMatchid) +', MatchCode:' + @newMatchcode,  
			   @Remark1 = 'From match ' + convert(varchar(10),@Matchid) + ', MatchCode:' + @matchcode 
		
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
			@UserID = @creator,
			@Matchid = @MatchID,
			@ActionID = 113,
			@finalhomescore = @finalhomescore,
			@finalawayscore = @finalawayscore,  
			@hthomescore = @hthomescore,
			@htawayscore = @htawayscore,
			@GoalRecord = @goalrecord,
			@betstatus = @betstatus,
			@Remark = @Remark,
			@IP = @IP

		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
			@UserID = @creator,
			@Matchid = @NewMatchID,
			@ActionID = 114,
			@finalhomescore = @finalhomescore1,
			@finalawayscore = @finalawayscore1,  
			@hthomescore = @hthomescore1,
			@htawayscore = @htawayscore1,
			@GoalRecord = @goalrecord1,
			@betstatus = @betstatus1,
			@Remark = @Remark1,
			@IP = @IP
	END
END
GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_BetDaq_Move] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_BetDaq_Move] TO [vnteam]  