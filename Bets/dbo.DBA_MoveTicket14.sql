USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[DBA_MoveTicket14]    Script Date: 01/11/2011 08:33:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_MoveTicket14]
	@TransID bigint,
	@NewMatchID int
AS
/*
	DB: DBTRANS.bodb02
	Creator : Thien
	Date : 2011-01-11
	Task : Copy one ticket on bettrans14 to another match
	Revisions:
		- 20110520@Amy: Re-arrange bettype
	
*/
if not exists(SELECT 1 FROM Bettrans14 with(nolock) WHERE TransID = @TransID)
BEGIN
	select 'Invalid TransID, please check!' ErrMsg
	RETURN
END

if exists(SELECT 1 FROM Bettrans14 with(nolock) WHERE TransID = @TransID and transdesc like '(copied to%')
BEGIN
	select 'Already copied this ticket, please check!' ErrMsg
	RETURN
END

if not exists(SELECT 1 FROM Match with(nolock) WHERE MatchID = @NewMatchID)
BEGIN
	select 'Invalid NewMatchID, please check!' ErrMsg
	RETURN
END

DECLARE @MatchID int, @Bettype smallint, @NewOddsID int, @Winlostdate smalldatetime, @newTransID int

SELECT @MatchID = MatchID, @Bettype = Bettype
FROM Bettrans14 with(nolock)
WHERE TransID = @TransID

IF @MatchID = @NewMatchID
BEGIN
	select 'Invalid NewMatchID, please check!' ErrMsg
	RETURN
END

SELECT @NewOddsID = OddsID FROM Odds with(nolock) WHERE MatchID = @NewMatchID and Bettype=@Bettype

insert into bettrans 
	( [refno], [custid], [transdate], [oddsid],
	[hdp1], [hdp2], [odds], [stake], [status], [winlost],
	[livehomescore], [liveawayscore], [liveindicator], [betteam],
	[creator], [comstatus], [winlostdate], [betfrom], [betcheck], 
	[checktime], [oddsspread], [apositiontaking], [mpositiontaking], [spositiontaking],
	[tpositiontaking], [awinlost], [mwinlost], [swinlost], [playerdiscount], [discount], [adiscount], [sdiscount],
	[playercomm], [comm], [acomm], [scomm], [actualrate], [virtualrate], [matchid], [modds], 
	[recommend], [mrecommend], [srecommend], [betdaqid], [ruben], [statuswinlost], [bettype], [currency], 
	[actual_stake], [transdesc], [ip], [betid], [Username], [CurrencyName], [oddstype], [statusID], [currency2])
select 
	[refno], [custid], getdate(), @NewOddsID,
	[hdp1], [hdp2], [odds], [stake], [status], [winlost],
	[livehomescore], [liveawayscore], [liveindicator], [betteam],
	[creator], [comstatus], [winlostdate], [betfrom], [betcheck], 
	[checktime], [oddsspread], [apositiontaking], [mpositiontaking], [spositiontaking],
	[tpositiontaking], [awinlost], [mwinlost], [swinlost], [playerdiscount], [discount], [adiscount], [sdiscount],
	[playercomm], [comm], [acomm], [scomm], [actualrate], [virtualrate], @NewMatchID, [modds], 
	[recommend], [mrecommend], [srecommend], [betdaqid], [ruben], [statuswinlost], [bettype], [currency], 
	[actual_stake], '(copied from ' + CAST(@MatchID as varchar(20)) + ')' + transdesc, [ip], [betid], [Username], [CurrencyName], [oddstype], [statusID], [currency2]
from bettrans14 (nolock)
WHERE TransID = @TransID

select @NewTransid=scope_identity() 

UPDATE Bettrans14
Set transdesc =  '(copied to ' + CAST(@NewMatchID as varchar(20)) + ')' + transdesc
WHERE TransID = @TransID

select @NewTransid TransID, @NewMatchID NewMatchID, @NewOddsID NewOddsID

GO
GRANT EXECUTE ON [dbo].[DBA_MoveTicket14] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_MoveTicket14] TO [vnteam]