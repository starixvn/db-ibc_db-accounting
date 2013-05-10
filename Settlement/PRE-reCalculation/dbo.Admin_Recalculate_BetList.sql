


ALTER PROCEDURE [dbo].[Admin_Recalculate_BetList]
(
	@matchid	INT,
	@principal	VARCHAR(100),
	@bettype	SMALLINT = 0
)
AS
/*
	Created by: 20111116@Lukas
	Task: Get affected tickets after re-calculate
	DB: DB052.BODB_REVIEW
	
	Revision:
		
*/
BEGIN
	
	
	IF @principal = 'IBC'
	BEGIN
		SELECT m.Sporttype, 
				b.username, 
				b.TransID,
				isnull(b.BetID,0) betid,
				b.Bettype,
				b.hdp1, 
				b.hdp2, 
				b.modds,
				dbo.f_ShowOddsByBettype(b.bettype,b.oddstype) as OddsType,
				dbo.f_GetOddsByBettype(b.odds,b.bettype,b.oddstype) as odds, 
				b.Stake, 
				b.actual_stake,
				dbo.f_GetChoice(b.betteam, b.bettype,'E') as betteam,
				b.status as Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-b.actual_stake) as winlost,
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
				
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP as IP,
				m.LeagueID,
				m.MatchID,		
				m.MatchCode,
				'' as Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				b.custid 
		FROM bettrans b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettrans bt WITH(NOLOCK) ON b.transid = bt.transid
			INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid		
		WHERE b.matchid = @matchid
			AND bt.statusID NOT IN (101,102,103)
			AND b.bettype = CASE WHEN @bettype = 0 THEN b.bettype ELSE @bettype END	
			AND b.currency <> 20
			AND b.srecommend NOT IN (SELECT custid FROM bodb02.dbo.f_depsuper_1('ALL'))
			AND CHECKSUM(b.statusid, b.winlost, b.playercomm) <> CHECKSUM(bt.statusid, bt.winlost, bt.playercomm)
	END
	ELSE
	BEGIN
		SELECT m.Sporttype, 
				b.username, 
				b.TransID,
				isnull(b.BetID,0) betid,
				b.Bettype,
				b.hdp1, 
				b.hdp2, 
				b.modds,
				dbo.f_ShowOddsByBettype(b.bettype,b.oddstype) as OddsType,
				dbo.f_GetOddsByBettype(b.odds,b.bettype,b.oddstype) as odds, 
				b.Stake, 
				b.actual_stake,
				dbo.f_GetChoice(b.betteam, b.bettype,'E') as betteam,
				b.status as Status,				
				b.refno,
				b.Transdate,	
				b.winlostdate,			
				(b.winlost-b.actual_stake) as winlost,
				b.awinlost,
				b.mwinlost,
				b.swinlost,
				
				b.PlayerComm,
				(b.comm - b.playercomm) as comm,
				(b.acomm - b.comm) as acomm ,
				(b.scomm - b.acomm) as scomm,
				
				b.APositiontaking,
				b.MPositiontaking,
				b.SPositiontaking,
				b.discount as Adiscount,
				b.adiscount as Mdiscount,
				b.sdiscount as Sdiscount,
				b.Liveindicator,
				b.Livehomescore,
				b.Liveawayscore,
				b.IP as IP,
				m.LeagueID,
				m.MatchID,		
				m.MatchCode,
				'' as Race,	
				m.HomeID,
				m.AwayID, 		
				m.Betstatus,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				b.custid 
		FROM bettrans b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettrans bt WITH(NOLOCK) ON b.transid = bt.transid
			INNER JOIN bodb02.dbo.f_depsuper_1(@Principal) s ON bt.srecommend = s.custid
			INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
		WHERE b.matchid = @matchid
			AND bt.statusID NOT IN (101,102,103)
			AND b.bettype = CASE WHEN @bettype = 0 THEN b.bettype ELSE @bettype END	
			AND b.currency <> 20
			AND CHECKSUM(b.statusid, b.winlost, b.playercomm) <> CHECKSUM(bt.statusid, bt.winlost, bt.playercomm)
	END

	
	
END


