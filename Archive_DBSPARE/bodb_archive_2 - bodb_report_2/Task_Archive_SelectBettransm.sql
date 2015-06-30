USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBettransm]    Script Date: 03/30/2013 23:50:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_Archive_SelectBettransm]
	AS
SET NOCOUNT ON

Declare @min_winlostdate smalldatetime,
		@max_winlostdate smalldatetime
			
SELECT	@max_winlostdate = MAX(winlostdate)
FROM bodb_archive.dbo.Task_ArchiveDate

SELECT @min_winlostdate = DateAdd(d,-6,@max_winlostdate)

SELECT    transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, 
                      refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, awinlost, 
                      mwinlost, swinlost, playerdiscount, discount, adiscount, sdiscount, playercomm, comm, acomm, scomm, actualrate, matchid, matchdate, finalodds, 
                      isfinish, statuswinlost, ruben, statusID, bettype, recommdate
FROM         bettransm with (nolock)
WHERE winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
