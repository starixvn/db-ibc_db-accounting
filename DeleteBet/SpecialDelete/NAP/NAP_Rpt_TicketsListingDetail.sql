ALTER PROCEDURE [dbo].[NAP_Rpt_TicketsListingDetail]
	@matchID INT,
	@LicenseeName VARCHAR(1000),
	@bettypes VARCHAR(1000), 
	@bettypesLive VARCHAR(1000) ,
	@LiveType SMALLINT = 2,	
	@livehomescore smallint = NULL,
    @liveawayscore smallint = NULL,
    @FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@Type SMALLINT = 0,
    @SAFilter tinyint = 0
WITH RECOMPILE
AS

/*	Created by: Elodie
	Date: 20130606
	Task: Show Tickets Listing Detail and Export to excel for NAP system
	DB: DBACC/bodb02
	Original: Acc_Rpt_TicketsListingDetail

	Revisions:	
							   
	Param's Explanation:
	- @Type: sports type
		0: Sportsbook
		1: Number Game
		2: Virtual sports
		3: Live casino
	- @LicenseeName:
		ALL, IBC, 12bet, ...	
	- @bettypes: String of bettype for Sportsbook, virtual sports and for Dead Ball - Number game, Live casino
	- @bettypesLive: String of bettype ONLY for Live - Number game 
	- @LiveType: Combo Type, used only for Sportsbook
		0: Dead ball
		1: Live ball
		2: All	
	- Because the interface is separated with sportbook and number game
		==>	SportsBook: Use @bettypes and @LiveType to indicate Live ball or Dead ball
			Number game: Use @bettypes and @bettypesLive to indicate Live ball or Dead ball
			Virtual sports: Use @bettypes to indicate Dead ball
    - @SAFilter: 
      + 0: All tickets
      + 1: Normal tickets only
      + 2: SA tickets only	
     
   Example: exec NAP_Rpt_TicketsListingDetail @matchID=4626986,@LicenseeName='IBC',@bettypes='1101,1102',@bettypesLive='',@LiveType=0,@livehomescore=default,@liveawayscore=default,@FromTransdate=default,@ToTransdate=default,@Type=2,@SAFilter=0
	
*/
SET NOCOUNT ON 

DECLARE @p_bettypes VARCHAR(1000) 
DECLARE @p_bettypesLive VARCHAR(1000) 

SET @p_bettypes = @bettypes 
SET @p_bettypesLive = @bettypesLive

---- If number game then don't care @livetype , so set @LiveType to zero
IF @Type = 1 or @Type = 2 or @Type = 3
	SELECT @LiveType = 0

----***** bettype <> 9 (because bettype = 9 then matchID = 9)****----
IF @p_bettypes <> '9' AND @bettypes <> '29' AND @bettypes <> '9,29'
BEGIN
	CREATE TABLE #SpecialDeleteBets 
	(
		username VARCHAR(30),
		bettype SMALLINT,
		transid BIGINT,
		homeid INT,
		awayid INT,
		hdp1 SMALLMONEY, 
		hdp2 SMALLMONEY,
		odds SMALLMONEY,
		status NVARCHAR(10),
		stake MONEY,
		transdate DATETIME, 
		betteam NVARCHAR(10),
		livehomescore SMALLINT, 
		liveawayscore SMALLINT,
		liveindicator BIT,
		ISNeutral BIT,
		OddsType INT, 
		CurrencyName NVARCHAR(100),
		winlost MONEY,
		betid BIGINT,
		IsMP BIT,
		SecAcceptFlag BIT,		
		refno BIGINT
	)
	
----Direct Licensee
	IF @LicenseeName <> 'IBC' AND @LicenseeName <> 'ALL' 
	BEGIN				 
		INSERT INTO #SpecialDeleteBets
		SELECT	b.username,
				b.bettype,		
				b.transid,
				m.homeID,
				m.awayID,
				convert(float, b.hdp1) as hdp1, 
				convert(float, b.hdp2) as hdp2, 
				b.odds,
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					 ELSE b.status 
					 END  as status,
				b.stake,
				b.transdate,		
				b.betteam,
				b.livehomescore,
				b.liveawayscore,
				b.liveindicator, 
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				b.OddsType,
				b.CurrencyName,
				(winlost-actual_stake )as winlost,
				b.betid,
				0 as isMP,
				ISNULL(SecAcceptFlag,0) SecAcceptFlag,
				b.refno
		FROM		Bettrans b WITH (NOLOCK) 
		INNER JOIN  match m WITH (NOLOCK) on b.matchid = m.matchid 		
		WHERE		b.srecommend IN ( SELECT custid FROM dbo.f_DepSuper_1 (@LicenseeName) )
					AND b.statusID NOT IN (101,102, 121) ---('Void', 'Reject', 'Dummy')
					AND b.matchid = @matchid 
			 	   	AND
						(   
							(
								b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@p_bettypes,','))
								 AND CASE WHEN @LiveType <> 2 THEN liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
								 AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @LiveType = 1 THEN @livehomescore ELSE b.livehomescore END
								 AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @LiveType = 1 THEN @liveawayscore ELSE b.liveawayscore END
								 AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE b.transdate END 
												AND	   CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE b.transdate END  
							)
							 OR
							(
								b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@p_bettypesLive,','))
								AND b.liveindicator = 1
							)
						) 
                    AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		ORDER BY transID
 
	END

	---IBC 
	IF @LicenseeName = 'IBC'  
	BEGIN	
		INSERT INTO #SpecialDeleteBets
		SELECT	b.username,
				b.bettype,		
				b.transid,
				m.homeID,
				m.awayID,
				convert(float, b.hdp1) as hdp1, 
				convert(float, b.hdp2) as hdp2, 
				b.odds,
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					 ELSE b.status 
					 END as status,
				b.stake,
				b.transdate,		
				b.betteam,
				b.livehomescore,
				b.liveawayscore,
				b.liveindicator, 
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				b.OddsType,
				b.CurrencyName,
				(winlost-actual_stake )as winlost,
				b.betid,
				0 as isMP,
				ISNULL(SecAcceptFlag,0) SecAcceptFlag,
				b.refno
		FROM		Bettrans b WITH (NOLOCK) 
		INNER JOIN  match m WITH (NOLOCK) on b.matchid = m.matchid 	
		WHERE		B.recommend NOT IN (SELECT CustID FROM DBLIC.bodb_Licensee.dbo.LicenseeCust WITH (NOLOCK) ) 
					AND b.statusID NOT IN (101,102, 121) --- ('Void', 'Reject', 'Dummy')
					AND b.matchid = @matchid 
					AND
						(   
							(
								b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@p_bettypes,','))
								 AND CASE WHEN @LiveType <> 2 THEN liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
								 AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @LiveType = 1 THEN @livehomescore ELSE b.livehomescore END
								 AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @LiveType = 1 THEN @liveawayscore ELSE b.liveawayscore END
								 AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE b.transdate END 
												 AND	 CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE b.transdate END
							)
							 OR
							(
								b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@p_bettypesLive,','))
								AND b.liveindicator = 1
							)
						)
						AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		ORDER BY transID

	END

	---ALL
	IF @LicenseeName= 'ALL' 
	BEGIN 	
		INSERT INTO #SpecialDeleteBets
		SELECT	b.username,
				b.bettype,		
				b.transid,
				m.homeID,
				m.awayID,
				convert(float, b.hdp1) as hdp1, 
				convert(float, b.hdp2) as hdp2, 
				b.odds,
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					 ELSE b.status 
					 END  as status,
				b.stake,
				b.transdate,		
				b.betteam,
				b.livehomescore,
				b.liveawayscore,
				b.liveindicator, 
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				b.OddsType,
				b.CurrencyName,
				(winlost-actual_stake )as winlost,
				b.betid,
				0 as isMP,
				ISNULL(SecAcceptFlag,0) SecAcceptFlag,
				b.refno				
		FROM		Bettrans b WITH (NOLOCK)
		INNER JOIN  match m WITH (NOLOCK) on b.matchid = m.matchid 		
		WHERE		b.statusID NOT IN (101,102, 121)--('Void', 'Reject', 'Dummy') 
					AND b.matchid = @matchid 
					AND	(   
							(
								b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@p_bettypes,','))
								 AND CASE WHEN @LiveType <> 2 THEN liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
								 AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @LiveType = 1 THEN @livehomescore ELSE b.livehomescore END
								 AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @LiveType = 1 THEN @liveawayscore ELSE b.liveawayscore END
								 AND b.transdate	BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE b.transdate END 
													AND	    CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE b.transdate END 
							)
							 OR
							(
								b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@p_bettypesLive,','))
								AND b.liveindicator = 1
							)
						)
					AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		ORDER BY transID
	END
		
	SELECT * FROM #SpecialDeleteBets
	
	IF @Type = 3				
		SELECT bg.refno, bg.odds, bg.stake, bg.status, bg.bettype, bg.betteam
		FROM #SpecialDeleteBets b
			INNER JOIN bettransG bg WITH(NOLOCK) ON b.refno = bg.refno
			
END 
ELSE
BEGIN 
	SELECT	username ,
			bettype ,				
			transid ,
			0 as homeID ,
			0 as awayID ,
			hdp1 , 
			hdp2 , 
			odds ,	
			status,
			stake ,
			transdate ,		
			betteam ,
			livehomescore ,
			liveawayscore ,
			liveindicator , 
			0 as IsNeutral ,
			OddsType ,
			CurrencyName ,
			winlost ,
			betid,	
			0 as isMP,
			0,
			refno
	FROM bettrans WITH (NOLOCK)
	WHERE 0 = 1
END 

----******* If list of bettype include 9 *******
IF charindex('9', @p_bettypes , 1) <> 0  
BEGIN 
	---Licensee
	IF @LicenseeName <> 'IBC' AND @LicenseeName <> 'ALL' 
	BEGIN		
		SELECT
				b.username,
				b.bettype,		
				b.betteam as selection,
				bm.bettype as bettypem,
				b.transid,
				m.homeID,
				m.awayID,
				convert(float, bm.hdp1) as hdp1, 
				convert(float, bm.hdp2) as hdp2, 
				b.odds,  
				bm.odds as oddsm, 
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					 ELSE b.status 
					 END  as status,
				bm.stake,
				b.transdate,		
				bm.betteam,
				bm.livehomescore,
				bm.liveawayscore,
				bm.liveindicator, 
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				0 as OddsType,
				b.CurrencyName,
				(b.winlost-b.actual_stake )as winlost,
				1 as isMP,
				0 SecAcceptFlag								 
		FROM	bettransm bm WITH (NOLOCK)	
		INNER JOIN  Bettrans b WITH (NOLOCK) ON b.refno = bm.refno 
		INNER JOIN dbo.strSplit(@bettypes,',') t ON b.bettype = t.val
		INNER JOIN  match m WITH (NOLOCK) ON m.matchid = bm.MatchID	
		WHERE		b.srecommend IN ( SELECT custid FROM dbo.f_DepSuper_1 (@LicenseeName)) 
					AND b.statusID NOT IN (101,102) --- ('Void', 'Reject' )
					AND b.bettype IN(9,29) AND b.matchID IN (9,29)
					AND bm.matchid = @matchid 
					AND CASE WHEN @LiveType <> 2 THEN bm.liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
					AND bm.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @LiveType = 1 THEN @livehomescore ELSE bm.livehomescore END
					AND bm.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @LiveType = 1 THEN @liveawayscore ELSE bm.liveawayscore END
					AND bm.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE bm.transdate END 
									 AND	  CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE bm.transdate END
					AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					AND (b.betid = 0 OR b.betid IS NULL)

	END
	ELSE 
	
	---IBC
	IF @LicenseeName= 'IBC'  
	BEGIN		
		SELECT	b.username,
				b.bettype,	
				b.betteam as selection,	
				bm.bettype as bettypem,
				b.transid,
				m.homeID,
				m.awayID,
				convert(float, bm.hdp1) as hdp1, 
				convert(float, bm.hdp2) as hdp2, 
				b.odds,  
				bm.odds as oddsm, 
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					 ELSE b.status 
					 END  as status,
				bm.stake,
				b.transdate,		
				bm.betteam,
				bm.livehomescore,
				bm.liveawayscore,
				bm.liveindicator, 
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				0 as OddsType,
				b.CurrencyName,
				(b.winlost-b.actual_stake )as winlost,
				1 as isMP,
				0 SecAcceptFlag								
		FROM	Bettrans b WITH (NOLOCK) 
		INNER JOIN  bettransm bm WITH (NOLOCK) ON b.refno = bm.refno 
		INNER JOIN dbo.strSplit(@bettypes,',') t ON b.bettype = t.val
		INNER JOIN  match m WITH (NOLOCK) ON m.matchid = bm.matchID
		WHERE		b.recommend NOT IN (SELECT CustID FROM DBLIC.bodb_Licensee.dbo.LicenseeCust WITH (NOLOCK) ) 
					AND b.statusID NOT IN (101,102) --('Void', 'Reject')
					AND b.bettype IN (9,29) AND b.matchID IN (9,29)
					AND bm.matchid = @matchid 	 
					AND CASE WHEN @LiveType <> 2 THEN bm.liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
					AND bm.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @LiveType = 1 THEN @livehomescore ELSE bm.livehomescore END
					AND bm.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @LiveType = 1 THEN @liveawayscore ELSE bm.liveawayscore END
					AND bm.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE bm.transdate END 
									 AND	 CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE bm.transdate END
					AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					AND (b.betid = 0 OR b.betid IS NULL)
	END 

	---ALL
	IF @LicenseeName= 'ALL'  
	BEGIN		
		SELECT	b.username,
				b.bettype,		
				b.betteam as selection,
				bm.bettype as bettypem,
				b.transid,
				m.homeID,
				m.awayID,
				convert(float, bm.hdp1) as hdp1, 
				convert(float, bm.hdp2) as hdp2, 
				b.odds,  
				bm.odds as oddsm, 
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
					 ELSE b.status 
					 END  as status,
				bm.stake,
				b.transdate,		
				bm.betteam,
				bm.livehomescore,
				bm.liveawayscore,
				bm.liveindicator, 
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				0 as OddsType,
				b.CurrencyName,
				(b.winlost-b.actual_stake )as winlost,
				1 as isMP,
				0 SecAcceptFlag								
		FROM	Bettrans b WITH (NOLOCK)	
		INNER JOIN  bettransm bm WITH (NOLOCK) ON b.refno = bm.refno 
		INNER JOIN dbo.strSplit(@bettypes,',') t ON b.bettype = t.val
		INNER JOIN  match m WITH (NOLOCK) ON m.matchid = bm.matchID
		WHERE		b.statusID NOT IN (101,102)--('Void', 'Reject')
					AND b.bettype IN (9,29) AND b.matchID IN (9,29) 
					AND bm.matchID = @matchID
					AND CASE WHEN @LiveType <> 2 THEN bm.liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
					AND bm.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @LiveType = 1 THEN @livehomescore ELSE bm.livehomescore END
					AND bm.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @LiveType = 1 THEN @liveawayscore ELSE bm.liveawayscore END
					AND bm.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE bm.transdate END 
									 AND	 CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE bm.transdate END
					AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
					AND (b.betid = 0 OR b.betid IS NULL)
	END 		
END 
ELSE 
BEGIN
		SELECT	username ,
				bettype ,	
				'' as selection	,
				0 as bettypem ,
				transid ,
				0 as homeID ,
				0 as awayID ,
				hdp1 , 
				hdp2 , 
				odds ,
				0 as oddsm ,
				status,
				stake ,
				transdate ,		
				betteam ,
				livehomescore ,
				liveawayscore ,
				liveindicator , 
				0 as IsNeutral ,
				OddsType ,
				CurrencyName ,
				winlost ,	
				0 as isMP,
				0				
		FROM bettrans WITH (NOLOCK) 
		WHERE 0 = 1
END

GO
GRANT EXECUTE ON [dbo].[NAP_Rpt_TicketsListingDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Rpt_TicketsListingDetail] TO [vnteam]

 