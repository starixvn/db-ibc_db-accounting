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
/****** Object:  Index [PK_sum_winloss]    Script Date: 02/09/2011 22:49:31 ******/
ALTER TABLE [dbo].[sum_winloss] ADD  CONSTRAINT [PK_sum_winloss] PRIMARY KEY NONCLUSTERED 
(
	[keyid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO

--------------------
--2. custsetting table
--2.1 custsetting table: remove index
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[custSetting]') AND name = N'PK_custsetting')
ALTER TABLE [dbo].[custSetting] DROP CONSTRAINT [PK_custsetting]
GO

--2.2 custsetting table: remove constraint

--2.3 custsetting table: alter datatype
ALTER TABLE custsetting
ALTER COLUMN bettype SMALLINT NOT NULL

GO
ALTER TABLE custsetting
ALTER COLUMN sporttype SMALLINT NOT NULL
GO

--2.4 custsetting table: add back constraints

--2.5 custsetting table: add back index
ALTER TABLE [dbo].[custSetting] ADD  CONSTRAINT [PK_custsetting] PRIMARY KEY CLUSTERED 
(
	[custid] ASC,
	[bettype] ASC,
	[sporttype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [CustSetting_table]
GO
-----------------

--3. custoverride table
--3.1 custoverride table: remove index
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[custOverride]') AND name = N'PK_custoverride')
ALTER TABLE [dbo].[custOverride] DROP CONSTRAINT [PK_custoverride]
GO

--3.2 custoverride table: remove constraint

--3.3 custoverride table: alter datatype
ALTER TABLE custoverride
ALTER COLUMN bettype SMALLINT NOT NULL

GO
ALTER TABLE custoverride
ALTER COLUMN sporttype SMALLINT NOT NULL
GO

--3.4 custoverride table: add back constraints

--3.5 custoverride table: add back index
ALTER TABLE [dbo].[custOverride] ADD  CONSTRAINT [PK_custoverride] PRIMARY KEY CLUSTERED 
(
	[custid] ASC,
	[bettype] ASC,
	[sporttype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CustOverride_table]
GO

--------------------
--4. custsetting3rd table
--4.1 custsetting3rd table: remove index
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[CustSetting3rd]') AND name = N'PK_CustSetting3rd')
ALTER TABLE [dbo].[CustSetting3rd] DROP CONSTRAINT [PK_CustSetting3rd]
GO

--4.2 custsetting3rd table: remove constraint

--4.3 custsetting3rd table: alter datatype
ALTER TABLE custsetting3rd
ALTER COLUMN bettype SMALLINT NOT NULL

GO
ALTER TABLE custsetting3rd
ALTER COLUMN sporttype SMALLINT NOT NULL
GO

--4.4 custsetting3rd table: add back constraints

--4.5 custsetting3rd table: add back index
ALTER TABLE [dbo].[CustSetting3rd] ADD  CONSTRAINT [PK_CustSetting3rd] PRIMARY KEY CLUSTERED 
(
	[custid] ASC,
	[bettype] ASC,
	[sporttype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [CustSetting3rd_table]
GO
-----------------

--5. custoverride3rd table
--5.1 custoverride3rd table: remove index
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[custoverride3rd]') AND name = N'PK_custoverride3rd')
ALTER TABLE [dbo].[custoverride3rd] DROP CONSTRAINT [PK_custoverride3rd]
GO

--5.2 custoverride3rd table: remove constraint

--5.3 custoverride3rd table: alter datatype
ALTER TABLE custoverride3rd
ALTER COLUMN bettype SMALLINT NOT NULL

GO
ALTER TABLE custoverride3rd
ALTER COLUMN sporttype SMALLINT NOT NULL
GO

--5.4 custoverride3rd table: add back constraints

--5.5 custoverride3rd table: add back index
ALTER TABLE [dbo].[custOverride3rd] ADD  CONSTRAINT [PK_custoverride3rd] PRIMARY KEY CLUSTERED 
(
	[custid] ASC,
	[bettype] ASC,
	[sporttype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [CustOverride3rd_table]
GO
