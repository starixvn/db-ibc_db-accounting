ALTER PROCEDURE [dbo].[Acc_AutoFollowBetSelCustomer]	
	@Username		VARCHAR(50),
	@Source			INT = 2,
	@BAStatus		INT = 2,
	@FollowLive		VARCHAR(10) = '0,1,2',
	@Handicap		INT = 2,
	@1stHandicap	INT = 2,
	@OverUnder		INT = 2,
	@1stOverUnder	INT = 2
AS
/*
Created: Viet @ 4-Jul-2012
DB: DBTXN/bodb02
Revisions:  
	- 20130201@Daniel: Change link server alias
	- 20131212@Kathy: - Remove @status, add new @param
					  - Separate Auto follow bet account for Live or Non-Live or All [Redmine:#9144]
		
	Param's Explanation:  
	  + @Source:		0 - Manual		 1 - Auto;			2 - All;
	  +	@BAStatus:		0 - BA Disabled; 1 - BA Enabled 	2 - All;		
	  + @FollowLive:	0 - Non live;	 1 - Live;			2 - Both		
	  + @Handicap:		0 - Not follow   1 - Follow;		2 - All
	  + @1stHandicap:	0 - Not follow;	 1 - Follow;		2 - All
	  + @OverUnder:		0 - Not follow;	 1 - Follow;		2 - All
	  + @1stOverUnder:	0 - Not follow;	 1 - Follow;		2 - All


*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tblBACust TABLE (CustId INT PRIMARY KEY)
	INSERT INTO @tblBACust (CustId)
	SELECT l.custid
	FROM DBLIC.bodb_licensee.dbo.LicenseeBAHistory l WITH(NOLOCK) 
	WHERE l.status = 'running'

	SELECT c.username, 
			f.src, 
			f.Rate, 
			f.FollowLive, 
			f.Follow1, 
			f.Follow3, 
			f.Follow7, 
			f.Follow8,
			CASE WHEN f.custid IN (SELECT [@tblBACust].CustId FROM @tblBACust) THEN 1 ELSE 0 END as IsBA
	FROM Cust_FollowBet f WITH(NOLOCK)
	INNER JOIN Customer c WITH(NOLOCK)
		ON c.custid = f.custid
	WHERE (ISNULL(@Username,'') = '' OR c.username = @Username)
	AND (@Source = 2 OR f.src = @Source)
	AND (f.FollowLive IN (SELECT s.val FROM dbo.strSplit(@FollowLive, ',') s))
	AND (@Handicap = 2 OR f.Follow1 = @Handicap)
	AND (@1stHandicap = 2 OR f.Follow7 = @1stHandicap)
	AND (@OverUnder = 2 OR f.Follow3 = @OverUnder)
	AND (@1stOverUnder = 2 OR f.Follow8 = @1stOverUnder)
	AND (
		  (@BAStatus = 0
			AND @BAStatus = CASE WHEN f.custid NOT IN (SELECT CustId FROM @tblBACust) 
									THEN 0
								 ELSE 1
							END) 
		  OR ( @BAStatus = 1
			AND @BAStatus = CASE WHEN f.custid IN (SELECT CustId FROM @tblBACust) 
									THEN 1
								 ELSE 0
							END) 
		  OR @BAStatus = 2
		)
	ORDER BY c.username
	   
END

GO
GRANT EXECUTE ON [dbo].[Acc_AutoFollowBetSelCustomer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AutoFollowBetSelCustomer] TO [VNTeam]
GO