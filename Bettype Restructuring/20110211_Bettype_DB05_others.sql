--------------------
--1. bettrans table
--1.1 bettrans table: remove indexes

/****** Object:  Index [bettrans16]    Script Date: 02/09/2011 23:42:31 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'bettrans16')
DROP INDEX [bettrans16] ON [dbo].[bettrans] WITH ( ONLINE = OFF )
GO
/****** Object:  Index [CIX_matchid_bettype]    Script Date: 02/09/2011 23:42:31 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'CIX_matchid_bettype')
DROP INDEX [CIX_matchid_bettype] ON [dbo].[bettrans] WITH ( ONLINE = OFF )
GO
/****** Object:  Index [IX_custid_matchid_bettype]    Script Date: 02/09/2011 23:42:31 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'IX_custid_matchid_bettype')
DROP INDEX [IX_custid_matchid_bettype] ON [dbo].[bettrans] WITH ( ONLINE = OFF )
GO
/****** Object:  Index [IX_recommend]    Script Date: 02/09/2011 23:42:31 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'IX_recommend')
DROP INDEX [IX_recommend] ON [dbo].[bettrans] WITH ( ONLINE = OFF )
GO
/****** Object:  Index [IX_srecommend]    Script Date: 02/09/2011 23:42:31 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'IX_srecommend')
DROP INDEX [IX_srecommend] ON [dbo].[bettrans] WITH ( ONLINE = OFF )
GO
/****** Object:  Index [IXU_transid]    Script Date: 02/09/2011 23:42:31 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'IXU_transid')
DROP INDEX [IXU_transid] ON [dbo].[bettrans] WITH ( ONLINE = OFF )
GO
--1.2 bettrans table: alter datatype
ALTER TABLE [dbo].[bettrans] ALTER COLUMN [bettype] smallint
GO
--1.3 bettrans table: create back indexes
USE [bodb02]
GO
/****** Object:  Index [bettrans16]    Script Date: 02/09/2011 23:42:22 ******/
CREATE NONCLUSTERED INDEX [bettrans16] ON [dbo].[bettrans] 
(
	[mrecommend] ASC,
	[recommend] ASC,
	[winlostdate] ASC,
	[bettype] ASC,
	[ruben] ASC,
	[status] ASC
)
INCLUDE ( [odds],
[stake],
[winlost],
[awinlost],
[mwinlost],
[playercomm],
[acomm],
[comm]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 50) ON [Bettrans_index1]
GO
/****** Object:  Index [CIX_matchid_bettype]    Script Date: 02/09/2011 23:42:22 ******/
CREATE CLUSTERED INDEX [CIX_matchid_bettype] ON [dbo].[bettrans] 
(
	[matchid] ASC,
	[custid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Bettrans_table]
GO
/****** Object:  Index [IX_custid_matchid_bettype]    Script Date: 02/09/2011 23:42:22 ******/
CREATE NONCLUSTERED INDEX [IX_custid_matchid_bettype] ON [dbo].[bettrans] 
(
	[custid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [Bettrans_index2]
GO
/****** Object:  Index [IX_recommend]    Script Date: 02/09/2011 23:42:22 ******/
CREATE NONCLUSTERED INDEX [IX_recommend] ON [dbo].[bettrans] 
(
	[recommend] ASC
)
INCLUDE ( [bettype],
[winlostdate]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Bettrans_index2]
GO
/****** Object:  Index [IX_srecommend]    Script Date: 02/09/2011 23:42:22 ******/
CREATE NONCLUSTERED INDEX [IX_srecommend] ON [dbo].[bettrans] 
(
	[srecommend] ASC,
	[winlostdate] ASC,
	[bettype] ASC,
	[statusID] ASC
)
INCLUDE ( [comm],
[recommend],
[mrecommend],
[ruben],
[actual_stake],
[scomm],
[spositiontaking],
[swinlost],
[custid],
[stake],
[acomm],
[tpositiontaking],
[liveawayscore],
[playercomm],
[mwinlost],
[awinlost],
[winlost]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Bettrans_index1]
GO
/****** Object:  Index [IXU_transid]    Script Date: 02/09/2011 23:42:22 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IXU_transid] ON [dbo].[bettrans] 
(
	[transid] ASC
)
INCLUDE ( [winlostdate],
[matchid],
[bettype],
[currency],
[ruben],
[liveawayscore],
[liveindicator],
[betteam],
[tpositiontaking],
[livehomescore],
[stake],
[status],
[odds],
[custid],
[oddsid],
[hdp1],
[hdp2]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Bettrans_index2]
GO

-------------------------
--------------------
--2. bettrans14 table
--2.1 bettrans14 table: remove indexes
/****** Object:  Index [bettrans1423]    Script Date: 02/09/2011 23:46:04 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans14]') AND name = N'bettrans1423')
DROP INDEX [bettrans1423] ON [dbo].[bettrans14] WITH ( ONLINE = OFF )
GO
/****** Object:  Index [IX_bettrans14]    Script Date: 02/09/2011 23:46:04 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans14]') AND name = N'IX_bettrans14')
DROP INDEX [IX_bettrans14] ON [dbo].[bettrans14] WITH ( ONLINE = OFF )
GO

--2.2 bettrans14 table: alter datatype
ALTER TABLE [dbo].[bettrans14] ALTER COLUMN [bettype] smallint
GO
--2.3 bettrans14 table: create back indexes
USE [bodb02]
GO
/****** Object:  Index [bettrans1423]    Script Date: 02/09/2011 23:45:57 ******/
CREATE NONCLUSTERED INDEX [bettrans1423] ON [dbo].[bettrans14] 
(
	[custid] ASC,
	[matchid] ASC,
	[ruben] ASC,
	[bettype] ASC,
	[winlost] ASC,
	[awinlost] ASC,
	[mwinlost] ASC,
	[actual_stake] ASC,
	[currency] ASC,
	[scomm] ASC,
	[swinlost] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Bettrans14_index]
GO
/****** Object:  Index [IX_bettrans14]    Script Date: 02/09/2011 23:45:57 ******/
CREATE CLUSTERED INDEX [IX_bettrans14] ON [dbo].[bettrans14] 
(
	[winlostdate] ASC,
	[custid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Bettrans14_table]
GO

--------------------
--3. bettransm table
--3.1 bettransm table: alter datatype
ALTER TABLE [dbo].[bettransm] ALTER COLUMN [bettype] smallint
GO

--4. bettransm14 table
--4.1 bettransm14 table: alter datatype
ALTER TABLE [dbo].[bettransm14] ALTER COLUMN [bettype] smallint
GO

--------------------
--5. Dot_ParlayMatchSetting table
--5.1 Dot_ParlayMatchSetting table: remove indexes
ALTER TABLE [dbo].[Dot_ParlayMatchSetting] DROP CONSTRAINT [PK_Dot_ParlayMatchSetting]
GO
--5.2 Dot_ParlayMatchSetting table: alter datatype
ALTER TABLE [dbo].[Dot_ParlayMatchSetting] ALTER COLUMN [bettype] smallint NOT NULL
GO
--5.3 Dot_ParlayMatchSetting table: create back indexes
USE [bodb02]
GO
/****** Object:  Index [PK_Dot_ParlayMatchSetting]    Script Date: 02/09/2011 23:59:49 ******/
ALTER TABLE [dbo].[Dot_ParlayMatchSetting] ADD  CONSTRAINT [PK_Dot_ParlayMatchSetting] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO
--------------------
--------------------
--6. odds table
--6.1 odds table: remove indexes
USE [bodb02]
GO
/****** Object:  Index [_MS_Sys_47_48_3]    Script Date: 02/10/2011 00:07:53 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[odds]') AND name = N'_MS_Sys_47_48_3')
DROP INDEX [_MS_Sys_47_48_3] ON [dbo].[odds] WITH ( ONLINE = OFF )
GO
/****** Object:  Index [IX_matchid]    Script Date: 02/10/2011 00:07:53 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[odds]') AND name = N'IX_matchid')
DROP INDEX [IX_matchid] ON [dbo].[odds] WITH ( ONLINE = OFF )
GO
/****** Object:  Index [UIX_GetAnOdds]    Script Date: 02/10/2011 00:07:53 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[odds]') AND name = N'UIX_GetAnOdds')
DROP INDEX [UIX_GetAnOdds] ON [dbo].[odds] WITH ( ONLINE = OFF )
GO

--6.2 odds table: alter datatype
ALTER TABLE [dbo].[odds] ALTER COLUMN [bettype] smallint
GO

--6.3 odds table: create back indexes
USE [bodb02]
GO
/****** Object:  Index [_MS_Sys_47_48_3]    Script Date: 02/10/2011 00:07:46 ******/
CREATE NONCLUSTERED INDEX [_MS_Sys_47_48_3] ON [dbo].[odds] 
(
	[liveindicator] ASC,
	[bettype] ASC,
	[oddsstatus] ASC
)
INCLUDE ( [oddsid],
[matchid],
[hdp1],
[hdp2],
[odds1a],
[odds2a],
[odds1hkc],
[odds2hkc],
[maxbet],
[sporttype]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO
/****** Object:  Index [IX_matchid]    Script Date: 02/10/2011 00:07:46 ******/
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[odds] 
(
	[matchid] ASC
)
INCLUDE ( [oddsid],
[bettype],
[odds2a],
[odds1a],
[hdp2],
[hdp1],
[oddsstatus],
[switch],
[diffbalance],
[changetime],
[newoffersetup],
[livehomescore],
[csstatus],
[maxbet],
[site3],
[hometotal],
[awaytotal],
[liveindicator],
[liveawayscore]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO
/****** Object:  Index [UIX_GetAnOdds]    Script Date: 02/10/2011 00:07:46 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UIX_GetAnOdds] ON [dbo].[odds] 
(
	[oddsid] ASC
)
INCLUDE ( [matchid],
[bettype],
[hdp1],
[hdp2],
[odds1a],
[odds2a],
[livehomescore],
[oddsstatus],
[odds1hkf],
[odds2hkf],
[oddsspreada],
[oddsspreadb],
[oddsspreadd],
[oddsspreade],
[oddsspreadf],
[oddsspreadc],
[liveawayscore],
[liveindicator],
[maxbet],
[sporttype]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
GO
--------------------
--7. odds14 table
--7.1 odds14 table: remove indexes
USE [bodb02]
GO
/****** Object:  Index [IX_odds14]    Script Date: 02/10/2011 00:15:23 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[odds14]') AND name = N'IX_odds14')
DROP INDEX [IX_odds14] ON [dbo].[odds14] WITH ( ONLINE = OFF )
GO

--7.2 odds14 table: alter datatype
ALTER TABLE [dbo].[odds14] ALTER COLUMN [bettype] smallint
GO

--7.3 odds14 table: create back indexes
USE [bodb02]
GO
/****** Object:  Index [IX_odds14]    Script Date: 02/10/2011 00:15:55 ******/
CREATE CLUSTERED INDEX [IX_odds14] ON [dbo].[odds14] 
(
	[oddsid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Event14_table]
GO
--------------------
--8. zzzbettrans table
--8.1 zzzbettrans table: remove indexes
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[zzzbettrans]') AND name = N'IX_zzzbettrans')
DROP INDEX [IX_zzzbettrans] ON [dbo].[zzzbettrans] WITH ( ONLINE = OFF )
GO

--8.2 zzzbettrans table: alter datatype
ALTER TABLE [dbo].[zzzbettrans] ALTER COLUMN [bettype] smallint
GO

--8.3 zzzbettrans table: create back indexes
CREATE CLUSTERED INDEX [IX_zzzbettrans] ON [dbo].[zzzbettrans] 
(
	[custid] ASC,
	[matchid] ASC,
	[bettype] ASC,
	[status] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Others_table]
GO
