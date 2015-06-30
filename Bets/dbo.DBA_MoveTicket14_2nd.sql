USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[DBA_MoveTicket14_2nd]    Script Date: 01/11/2011 08:33:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_MoveTicket14_2nd]
	@TransID bigint,
	@NewMatchID int
AS
/*
	DB: DBTRANS.bodb02
	Creator : Thien
	Date : 2011-01-11
	Task : Copy one ticket on bettrans14 to another match
	Revisions:
	- 20110513@Henry: change bettype to new range
	
*/
if not exists(SELECT 1 FROM Bettrans14 with(nolock) WHERE TransID = @TransID)
BEGIN
	select 'Invalid TransID, please check!' ErrMsg
	RETURN
END

if exists(SELECT 1 FROM Bettrans14 with(nolock) WHERE TransID = @TransID and transdesc like '(2nd copied to%')
BEGIN
	select 'Already copied this ticket, please check!' ErrMsg
	RETURN
END

if not exists(SELECT 1 FROM Match with(nolock) WHERE MatchID = @NewMatchID)
BEGIN
	select 'Invalid NewMatchID, please check!' ErrMsg
	RETURN
END

DECLARE @MatchID int, @Bettype int, @NewOddsID int, @Winlostdate smalldatetime, @newTransID int

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
	[hdp1], [hdp2], [odds], [status], [statusID],

	[stake], [actual_stake], [winlost], 

	[livehomescore], [liveawayscore], [liveindicator], [betteam],
	[creator], [comstatus], [winlostdate], [betfrom], [betcheck], 
	[checktime], [oddsspread], [apositiontaking], [mpositiontaking], [spositiontaking],
	[tpositiontaking], [awinlost], [mwinlost], [swinlost], [playerdiscount], [discount], [adiscount], [sdiscount],
	[playercomm], [comm], [acomm], [scomm], [actualrate], [virtualrate], [matchid], [modds], 
	[recommend], [mrecommend], [srecommend], [betdaqid], [ruben], [statuswinlost], [bettype], [currency], 
	 [transdesc], [ip], [betid], [Username], [CurrencyName], [oddstype], [currency2])
select 
	[refno], [custid], getdate(), @NewOddsID,
	[hdp1], [hdp2], [odds],
	
	Status = CASE
				WHEN [actual_stake] - [winlost] > 0 THEN N'WON'
				WHEN [actual_stake] - [winlost] = 0 THEN N'DRAW'
				WHEN [actual_stake] - [winlost] < 0 THEN N'LOSE'
				END,
	StatusID = CASE
		WHEN [actual_stake] - [winlost] > 0 THEN 112 --WON
		WHEN [actual_stake] - [winlost] = 0 THEN 111 --DRAW
		WHEN [actual_stake] - [winlost] < 0 THEN 113 --LOSE
		END,
		
	[winlost], [winlost], [actual_stake],--swap the winlost and stake

	[livehomescore], [liveawayscore], [liveindicator], [betteam],
	[creator], [comstatus],

	'2011-01-11', --hard-code for winlostdate

	[betfrom], [betcheck], 
	[checktime], [oddsspread], [apositiontaking], [mpositiontaking], [spositiontaking],
	[tpositiontaking],
	-[awinlost], -[mwinlost], -[swinlost], --opposite agency winloss

	[playerdiscount], [discount], [adiscount], [sdiscount],

	-[playercomm], -[comm], -[acomm], -[scomm], -- negative commission
	
	[actualrate], [virtualrate], @NewMatchID, [modds], 
	[recommend], [mrecommend], [srecommend], [betdaqid], [ruben], [statuswinlost], [bettype], [currency], 
	 '(2nd copied from ' + CAST(@MatchID as varchar(20)) + ')' + transdesc, [ip], [betid], [Username], [CurrencyName], [oddstype],  [currency2]
from bettrans14 (nolock)
WHERE TransID = @TransID

select @NewTransid=scope_identity() 

UPDATE Bettrans14
Set transdesc =  REPLACE (transdesc,'(copied to','(2nd copied to')
WHERE TransID = @TransID

select @NewTransid TransID, @NewMatchID NewMatchID, @NewOddsID NewOddsID



GO
GRANT EXECUTE ON [dbo].[DBA_MoveTicket14_2nd] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_MoveTicket14_2nd] TO [vnteam]