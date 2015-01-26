ALTER PROCEDURE [dbo].[Acc_Rpt_DailyTurnover]
	@fromdate datetime,
	@isActual bit = 0,
	@errcode bit = 0 OUTPUT,
	@errmsg varchar(300) ='' OUTPUT
AS
/*
Created: Daniel@20120201
Task : Get agency, ibc turnover, bet count

DB: DBTRANS+DB06.bodb02
Original: Dot_Admin_turnover_detail

Revisions:
	- Daniel@20120605: fix bug include P2P tickets
	-20121031@Jim: add more bettype for Sportbook (new Tennis: 1301->1304)
	- 20150126@Jamie: Missing 3rd party's tickets - HotFix [#29477]
Param's Explanation:

*/

SET NOCOUNT ON
------ 20121109@Viet: do not allow this SP to run once cpu is high --------
declare @ispermit bit
EXEC dbo.Server_IsHeavyLoadPermitted @ispermit OUTPUT
IF @ispermit = 0 
BEGIN
	SELECT @errcode = 1, @errmsg = 'oops! Server is too busy, please try again later!'
	RETURN
END
------ 20121109@Viet: do not allow this SP to run once cpu is high --------

Declare @NormalCNT int, @RejectCNT int

DECLARE	@tmpBettypes TABLE(
	Bettype		INT
)

INSERT INTO @tmpBettypes(Bettype)
SELECT	Bettype 
FROM	SportBettypeMatrix WITH (NOLOCK)
WHERE	ProductID = 1
		AND EventType = 1 

-- Consider to include bettrans_BK into query or not.
IF @fromdate <= (select max(distinct eventdate) from match14 (nolock))
BEGIN
	SELECT @RejectCNT = count(1)
	FROM bettrans14 with(rowlock)
	WHERE winlostdate = @fromdate
		and matchid > 29 -- exclude transfer, mix parlay, system parlay
		--and (bettype < 9 OR bettype between 11 and 30 OR bettype between 121 and 999 OR bettype BETWEEN 1301 AND 1334)	
		and bettype IN (SELECT bettype FROM @tmpBettypes)
		and statusid in (101,102,103) -- void, reject, refund
		and currency <> 20

	select 
		@fromdate as eventdate,
		sum(abs(stake) *
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end			
		) as total,
		sum(abs(stake) * spositiontaking * 
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end
		) as super,
		sum(abs(stake) * mpositiontaking * 
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end
		) as master,
		sum(abs(stake) * apositiontaking * 
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end
		) as agent,
		sum(abs(stake) * (1-tpositiontaking) * 
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end
		) as after,	
		count(1)+@RejectCNT as TicketCNT,
		count(1) as NormalCNT,
		@RejectCNT as RejectCNT
	FROM bettrans14 with(rowlock)
	WHERE winlostdate = @fromdate
		and matchid > 29 -- exclude transfer, mix parlay, system parlay
		--and (bettype < 9 OR bettype between 11 and 30 OR bettype between 121 and 999 OR bettype BETWEEN 1301 AND 1334)	
		and bettype IN (SELECT bettype FROM @tmpBettypes)
		and statusid in (111,112,113) -- won, lose, draw	
		and currency <> 20

END
ELSE
BEGIN
	SELECT @RejectCNT = count(1)
	FROM bettrans with(rowlock)
	WHERE winlostdate = @fromdate
		and matchid > 29 -- exclude transfer, mix parlay, system parlay
		--and (bettype < 9 OR bettype between 11 and 30 OR bettype between 121 and 999 OR bettype BETWEEN 1301 AND 1334)	
		and bettype IN (SELECT bettype FROM @tmpBettypes)
		and statusid in (101,102,103) -- void, reject, refund
		and currency <> 20

	select 
		@fromdate as eventdate,
		sum(abs(stake) *
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end			
		) as total,
		sum(abs(stake) * spositiontaking * 
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end
		) as super,
		sum(abs(stake) * mpositiontaking * 
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end
		) as master,
		sum(abs(stake) * apositiontaking * 
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end
		) as agent,
		sum(abs(stake) * (1-tpositiontaking) * 
			case when @isActual = 1 then actualrate else virtualrate end *
			case when betteam in ('a','h') then case when abs(odds) > 1 then abs(odds) else 1 end else 1 end
		) as after,	
		count(1)+@RejectCNT as TicketCNT,
		count(1) as NormalCNT,
		@RejectCNT as RejectCNT
	FROM bettrans with(rowlock)
	WHERE winlostdate = @fromdate
		and matchid > 29 -- exclude transfer, mix parlay, system parlay
		--and (bettype < 9 OR bettype between 11 and 30 OR bettype between 121 and 999 OR bettype BETWEEN 1301 AND 1334)	
		and bettype IN (SELECT bettype FROM @tmpBettypes)
		and statusid in (111,112,113) -- won, lose, draw
		and currency <> 20

END

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyTurnover] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyTurnover] TO [Dot_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyTurnover] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyTurnover] TO [vnteam] AS [dbo]