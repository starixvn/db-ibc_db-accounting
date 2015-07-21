USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBettransG]    Script Date: 07/19/2015 22:20:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectBettransG]
AS
SET NOCOUNT ON

/*
Created by:
Date:
Task: Insert data from bettransG14 to bettransG at bodb_Archive
DB:  
Revisions:
    - 20150720@Sophia: Add column TransDesc
    
 */

Declare @min_winlostdate smalldatetime,
		@max_winlostdate smalldatetime
SELECT
	@min_winlostdate = MIN(winlostdate),
	@max_winlostdate = MAX(winlostdate)
FROM dbo.Task_ArchiveDate

-- to DB06.bodb_Archive.dbo.bettransG
SELECT 
	[acomm],[actualrate],[adiscount],[apositiontaking],[awinlost],
	[betfrom],[BetID3rd],[betteam],[bettype],[checktime],[comm],[creator],[custid],
	[discount],[matchdate],[matchid],[mpositiontaking],[mwinlost],
	[odds],[oddsid],[playercomm],[playerdiscount],[refno],[ruben],
	[scomm],[sdiscount],[spositiontaking],[stake],[status],[statusID],[statuswinlost],[swinlost],
	[tpositiontaking],[transdate],[transid],[virtualrate],[winlost],[winlostdate],[TransDesc]
FROM dbo.bettransG14
WHERE winlostdate
--BETWEEN @min_winlostdate AND @max_winlostdate
<= @max_winlostdate
GO
