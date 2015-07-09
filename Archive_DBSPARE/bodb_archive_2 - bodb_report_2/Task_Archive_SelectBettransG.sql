USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBettransG]    Script Date: 03/30/2013 23:50:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_Archive_SelectBettransG]
	AS
SET NOCOUNT ON

Declare @min_winlostdate smalldatetime,
		@max_winlostdate smalldatetime
			
SELECT	@max_winlostdate = MAX(winlostdate)
FROM bodb_archive.dbo.Task_ArchiveDate

SELECT @min_winlostdate = DateAdd(d,-6,@max_winlostdate)


SELECT 
	[acomm],[actualrate],[adiscount],[apositiontaking],[awinlost],
	[betfrom],[betteam],[bettype],[checktime],[comm],[creator],[custid],
	[discount],[matchdate],[matchid],[mpositiontaking],[mwinlost],
	[odds],[oddsid],[playercomm],[playerdiscount],[refno],[ruben],
	[scomm],[sdiscount],[spositiontaking],[stake],[status],[statusID],[statuswinlost],[swinlost],
	[tpositiontaking],[transdate],[transid],[virtualrate],[winlost],[winlostdate]
FROM dbo.bettransG with (nolock)
WHERE winlostdate BETWEEN @min_winlostdate AND @max_winlostdate

