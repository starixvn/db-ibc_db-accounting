
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SaveBet_GetWinLost    Script Date: 9/10/2014 3:22:02 PM ******/
CREATE PROCEDURE [dbo].[NAP_SaveBet_GetWinLost]
	@matchid int
AS

/*
	Created by: Dom
	Date:2014-05-05
	Task: Winlost Report 
	DB: DB06.BODB02
	
	Revisions:
		
*/

IF EXISTS (SELECT matchid FROM bodb02.dbo.match with (nolock) WHERE matchid = @matchid)

SELECT
	bt.typenamee typename,
	b.bettype,
	CASE b.liveindicator WHEN 0 THEN '' ELSE 'Live' END Live,
	b.winlosta, b.agenta, b.comma,
	b.winlostv, b.agentv, b.commv,
	CASE WHEN b.bettype IN (1,3,7,8,20) THEN b.winlostv + b.agentv ELSE 0 END FC,
	b.BetCount, b.Reject, b.Void,
	IsNull(t.HomeA, 0) HomeA, IsNull(t.AwayA, 0) AwayA, IsNull(t.HomeA, 0) - IsNull(t.AwayA, 0) DiffA,
	IsNull(t.HomeV, 0) HomeV, IsNull(t.AwayV, 0) AwayV, IsNull(t.HomeV, 0) - IsNull(t.AwayV, 0) DiffV

FROM
(
	SELECT
		bettype, liveindicator,
		SUM( (winlost - actual_stake) * actualrate ) winlosta,
		SUM( (swinlost+mwinlost+awinlost) * actualrate ) agenta,
		SUM( (scomm) * actualrate ) comma,
		SUM( (winlost - actual_stake) * virtualrate ) winlostv,
		SUM( (swinlost+mwinlost+awinlost) * virtualrate ) agentv,
		SUM( (scomm) * virtualrate ) commv,
		COUNT(*) BetCount,
		SUM(CASE [status] WHEN 'reject' THEN 1 ELSE 0 END) Reject,
		SUM(CASE [status] WHEN 'void' THEN 1 ELSE 0 END) Void
	FROM
		bodb02.dbo.bettrans (nolock)
	WHERE
		matchid = @matchid
	GROUP BY
		bettype, liveindicator
) b
LEFT OUTER JOIN 
(
	SELECT
		bettype, liveindicator,
		sum(Case betteam  
		when 'a' then CASE when abs(odds) > 1 then abs(odds) * b.stake else b.stake END * b.actualrate * (1 - b.tpositiontaking)
		else 0
		end) AwayA,
		sum(Case betteam
		when 'a' then 0
		when 'h' then CASE when abs(odds) > 1 then abs(odds) * b.stake else b.stake END * b.actualrate * (1 - b.tpositiontaking)
		else b.stake * b.actualrate * (1 - b.tpositiontaking)
		end) HomeA,  

		sum(Case betteam  
		when 'a' then CASE when abs(odds) > 1 then abs(odds) * b.stake else b.stake END * b.virtualrate * (1 - b.tpositiontaking)
		else 0
		end) AwayV,
		sum(Case betteam
		when 'a' then 0
		when 'h' then CASE when abs(odds) > 1 then abs(odds) * b.stake else b.stake END * b.virtualrate * (1 - b.tpositiontaking)
		else b.stake * b.virtualrate * (1 - b.tpositiontaking)
		end) HomeV
	FROM
		bodb02.dbo.bettrans b (nolock)
	WHERE
		matchid = @matchid
		AND status NOT IN ('void','reject')
	GROUP BY
		bettype, liveindicator
) t ON b.bettype = t.bettype AND b.liveindicator = t.liveindicator
INNER JOIN bodb02.dbo.bettype bt (nolock) ON b.bettype = bt.typeid
ORDER BY b.liveindicator, b.bettype



ELSE




SELECT
	bt.typenamee  typename,
	b.bettype,
	CASE b.liveindicator WHEN 0 THEN '' ELSE 'Live' END Live,
	b.winlosta, b.agenta, b.comma,
	b.winlostv, b.agentv, b.commv,
	CASE WHEN b.bettype IN (1,3,7,8,20) THEN b.winlostv + b.agentv ELSE 0 END FC,
	b.BetCount, b.Reject, b.Void,
	IsNull(t.HomeA, 0) HomeA, IsNull(t.AwayA, 0) AwayA, IsNull(t.HomeA, 0) - IsNull(t.AwayA, 0) DiffA,
	IsNull(t.HomeV, 0) HomeV, IsNull(t.AwayV, 0) AwayV, IsNull(t.HomeV, 0) - IsNull(t.AwayV, 0) DiffV

FROM
(
	SELECT
		bettype, liveindicator,
		SUM( (winlost - actual_stake) * actualrate ) winlosta,
		SUM( (swinlost+mwinlost+awinlost) * actualrate ) agenta,
		SUM( (scomm) * actualrate ) comma,
		SUM( (winlost - actual_stake) * virtualrate ) winlostv,
		SUM( (swinlost+mwinlost+awinlost) * virtualrate ) agentv,
		SUM( (scomm) * virtualrate ) commv,
		COUNT(*) BetCount,
		SUM(CASE [status] WHEN 'reject' THEN 1 ELSE 0 END) Reject,
		SUM(CASE [status] WHEN 'void' THEN 1 ELSE 0 END) Void
	FROM
		bodb02.dbo.bettrans14 (nolock)
	WHERE
		matchid = @matchid
	GROUP BY
		bettype, liveindicator
) b
LEFT OUTER JOIN 
(
	SELECT
		bettype, liveindicator,
		sum(Case betteam  
		when 'a' then CASE when abs(odds) > 1 then abs(odds) * b.stake else b.stake END * b.actualrate * (1 - b.tpositiontaking)
		else 0
		end) AwayA,
		sum(Case betteam
		when 'a' then 0
		when 'h' then CASE when abs(odds) > 1 then abs(odds) * b.stake else b.stake END * b.actualrate * (1 - b.tpositiontaking)
		else b.stake * b.actualrate * (1 - b.tpositiontaking)
		end) HomeA,  

		sum(Case betteam  
		when 'a' then CASE when abs(odds) > 1 then abs(odds) * b.stake else b.stake END * b.virtualrate * (1 - b.tpositiontaking)
		else 0
		end) AwayV,
		sum(Case betteam
		when 'a' then 0
		when 'h' then CASE when abs(odds) > 1 then abs(odds) * b.stake else b.stake END * b.virtualrate * (1 - b.tpositiontaking)
		else b.stake * b.virtualrate * (1 - b.tpositiontaking)
		end) HomeV
	FROM
		bodb02.dbo.bettrans14 b (nolock)
	WHERE
		matchid = @matchid
		AND status NOT IN ('void','reject')
	GROUP BY
		bettype, liveindicator
) t ON b.bettype = t.bettype AND b.liveindicator = t.liveindicator
INNER JOIN bodb02.dbo.bettype bt (nolock) ON b.bettype = bt.typeid
ORDER BY b.liveindicator, b.bettype
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[NAP_SaveBet_GetWinLost] TO [bodbAdminNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SaveBet_GetWinLost] TO [vnteam]
GO 
