--------------------
--1. sum_winloss table
--1.1 sum_winloss table: remove index
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[sum_winloss]') AND name = N'PK_sum_winloss')
ALTER TABLE [dbo].[sum_winloss] DROP CONSTRAINT [PK_sum_winloss]
GO
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[sum_winloss]') AND name = N'CIX_sum_winloss')
DROP INDEX [CIX_sum_winloss] ON [dbo].[sum_winloss] WITH ( ONLINE = OFF )
GO

--1.2 sum_winloss table: remove constraint
ALTER TABLE [dbo].[sum_winloss] DROP CONSTRAINT [DF_sum_winloss_bettype]
GO
ALTER TABLE [dbo].[sum_winloss] DROP CONSTRAINT [DF_sum_winloss_sporttype]
GO

--1.3 sum_winloss table: alter datatype
ALTER TABLE sum_winloss
ALTER COLUMN bettype SMALLINT NOT NULL

GO
ALTER TABLE sum_winloss
ALTER COLUMN sporttype SMALLINT NOT NULL

GO
ALTER TABLE sum_winloss
ALTER COLUMN keyid BIGINT NOT NULL
GO

--1.4 sum_winloss table: add back constraints
ALTER TABLE [dbo].[sum_winloss] ADD  CONSTRAINT [DF_sum_winloss_bettype]  DEFAULT ((0)) FOR [bettype]
GO
ALTER TABLE [dbo].[sum_winloss] ADD  CONSTRAINT [DF_sum_winloss_sporttype]  DEFAULT ((0)) FOR [sporttype]
GO

--1.5 sum_winloss table: add back index
CREATE CLUSTERED INDEX [CIX_sum_winloss] ON [dbo].[sum_winloss] 
(
	[winlostdate] ASC,
	[srecommend] ASC,
	[mrecommend] ASC,
	[recommend] ASC,
	[roleid] ASC,
	[sporttype] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO

ALTER TABLE [dbo].[sum_winloss] ADD  CONSTRAINT [PK_sum_winloss] PRIMARY KEY NONCLUSTERED 
(
	[keyid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO
--------------------
