 USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBettrans]    Script Date: 03/30/2013 23:50:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectBettrans]
AS
SET NOCOUNT ON

Declare @winlostdate smalldatetime
SELECT TOP 1 @winlostdate = winlostdate
FROM dbo.Task_ArchiveDate
WHERE isDone = 0
ORDER BY 1 ASC

SELECT b.custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, 
                      scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, playerdiscount, discount, adiscount, sdiscount, livehomescore, 
                      liveawayscore, liveindicator, betteam, b.creator, refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, b.recommend, 
                      b.mrecommend, b.srecommend, ruben, betid, statuswinlost, modds, betdaqid, tstamp, b.currency, ip, transdesc, virtualrate, oddstype, statusID, currency2, 
                      transid, bettype, balance, transid2, SecAcceptFlag, recommdate, comstatus, c.site
FROM         bettrans_bk b WITH (nolock)
	inner join bodb02.dbo.customer c with (nolock) on b.recommend = c.custid
WHERE winlostdate = @winlostdate


UPDATE dbo.Task_ArchiveDate SET isDone = 1
WHERE winlostdate = @winlostdate