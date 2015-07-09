 --select min(winlostdate) from [betParlayResult_Archive] : 2011-11-24 00:00:00
--select min(winlostdate) from [betParlayResult] : 2012-02-09 00:00:00
---------------

/****** Object:  Table [dbo].[betParlayResult_Archive]    Script Date: 03/28/2013 23:36:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[betParlayResult_Archive](
	[rID] [bigint] NOT NULL,
	[RefNo] [bigint] NULL,
	[Serial] [int] NULL,
	[winlostdate] [smalldatetime] NULL,
	[statusid] [tinyint] NULL,
	[Odds] [money] NULL,
	[mOdds] [money] NULL,
 CONSTRAINT [PK_betParlayResult_Archive] PRIMARY KEY CLUSTERED 
(
	[rID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


/****** Object:  Index [CIX_refno]    Script Date: 03/28/2013 23:36:15 ******/
CREATE NONCLUSTERED INDEX [CIX_refno] ON [dbo].[betParlayResult_Archive] 
(
	[RefNo] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
-------------


---

--IMPORT DATA
SELECT [rID]
      ,[RefNo]
      ,[Serial]
      ,[winlostdate]
      ,[statusid]
      ,[Odds]
      ,[mOdds]
  FROM [bodb_Archive].[dbo].[betParlayResult_Archive] with (nolock)
 WHERE winlostdate between '2011-01-01' and '2011/12/31 23:59:00'
 -------
 