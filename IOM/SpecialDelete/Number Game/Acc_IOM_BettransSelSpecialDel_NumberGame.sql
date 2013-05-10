ALTER PROCEDURE [dbo].[Acc_IOM_BettransSelSpecialDel_NumberGame]
	@MatchID	INT,
	@FromRefNo	BIGINT,
	@ToRefNo	BIGINT,
	@Live		VARCHAR(100) = '',	-- bettype for live-ball
	@Dead		VARCHAR(100) = '',  -- bettype for dead-ball
	@UserName	VARCHAR(50)	 = ''
AS
/*
Created by: Elodie
Date: 20120704
Original: Acc_BettransSelSpecialDel_NumberGame
Task: Select bets transaction need to delete (Number Game)
DB: DB053.BODB02

Revision:

Explanation's Param:

*/
BEGIN
	SET NOCOUNT ON
	SELECT			
		b.transid,
		b.custid,
		b.username,
		b.odds,   
		b.OddsType,  
		b.transdate,
		b.bettype,
		betteam,
		hdp1,
		hdp2,
		livehomescore,
		liveawayscore,
		cr.username AS creator,	
		stake AS StakePositiontaking,
		b.currency, 
		1 AS IsDeposit,
		ag.site,
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
		     END as status,
		b.mrecommend,
		b.recommend,
		b.liveindicator
	FROM 
		bettrans b WITH (NOLOCK)
		INNER JOIN customer ag WITH (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
	WHERE
		matchid=@matchid 
		AND b.transid BETWEEN @FromRefNo AND @ToRefNo
		AND statusID NOT IN (101,102,121)   ---- Void, Reject, 121: dummy ticket
		AND
		(   
			(
				b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead,'^'))
				AND 
				b.liveindicator = 0 
			)
			 OR
			(
				b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Live,'^'))
				AND 
				b.liveindicator = 1 
			)
		) 	
	ORDER BY transid	
END

GO
GRANT EXECUTE ON [dbo].[Acc_IOM_BettransSelSpecialDel_NumberGame] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_IOM_BettransSelSpecialDel_NumberGame] TO [VNTeam]