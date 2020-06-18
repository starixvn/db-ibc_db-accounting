/*<info serverAlias="DBTXN-bodb02" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_FollowBet_Step2]
AS

/*
	Created:
	DB: DBTXN-bodb02

	Revisions:
		- 20120529@Sophia: . Update credit/debit balance
						   . Check @@Error to rollback
		- 20131108@Elodie: Splitting bodb02 into CustDB (call CustInfo, Exchange by link database)	
		- 20130107@Kathy: Get follower from Cust_FollowBet instead of hardcoded		
		- 20140919@Kathy: Allow to follow running ticket only [Redmine:#22392]	
		- 20150311@Kathy: Support multi-follower on one customer [Redmine:#32146]	
		- 20151230@Kathy: Not allow to follow ticket which still not accepted yet [Redmine:#49830]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @follow_transid		BIGINT,
			@follower			INT,
			@statusID			INT				
	
	DECLARE @TransIDs TABLE (transid BIGINT, follower INT, isFinished BIT)
	
	INSERT INTO @TransIDs (transid, follower, isFinished)
	SELECT	transid, follower, 0
	FROM	dbo.Task_FollowBet_Details WITH (NOLOCK)

	WHILE (1 = 1)
	BEGIN
		UPDATE TOP(1) @TransIDs
			SET isFinished = 1
				,@follow_transid = transid
				,@follower = follower
		WHERE	isFinished = 0
		
		IF @@ROWCOUNT = 0 BREAK -- no more tickets to handle
		
		SELECT	@statusID = b.statusID
		FROM	dbo.bettrans b WITH(NOLOCK)
		WHERE	b.transid = @follow_transid
				AND b.statusID <> 1 -- 1: Status is waiting
				AND 1 = CASE WHEN b.statusID = 0 AND b.SecAcceptFlag = 1 AND b.checktime > CURRENT_TIMESTAMP THEN 0 ELSE 1 END
				
		IF @@ROWCOUNT = 0 CONTINUE -- this ticket is still waiting, leave it alone :D, get back later.
		
		IF @statusID = 0  -- follow running ticket only
		BEGIN
			EXEC dbo.Task_FollowBet_Step2_PlaceBet 
				@follow_transid = @follow_transid
				,@follower		= @follower
		END
		ELSE
		BEGIN
			DELETE FROM dbo.Task_FollowBet_Details WITH(UPDLOCK, ROWLOCK)
			WHERE transid = @follow_transid	
			AND follower = @follower
		END
			
	END --end while
	
	WAITFOR DELAY '000:00:01' -- WAIT 1 second, then back to the 1st step (list ticket)
END