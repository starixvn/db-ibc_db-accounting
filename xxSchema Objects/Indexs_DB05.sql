--======================================================
--===================Customer===========================
--======================================================

USE [bodb02]
GO
/****** Object:  Index [IX_agent]    Script Date: 06/08/2009 22:10:15 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = N'IX_agent')
DROP INDEX [IX_agent] ON [dbo].[Customer] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_agent]    Script Date: 06/08/2009 22:10:25 ******/
CREATE NONCLUSTERED INDEX [IX_agent] ON [dbo].[Customer] 
(
	[recommend] ASC
)
INCLUDE ( [roleid]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Customer_index]

USE [bodb02]
GO
/****** Object:  Index [IX_custid]    Script Date: 06/08/2009 22:10:41 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = N'IX_custid')
DROP INDEX [IX_custid] ON [dbo].[Customer] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_custid]    Script Date: 06/08/2009 22:10:51 ******/
CREATE UNIQUE CLUSTERED INDEX [IX_custid] ON [dbo].[Customer] 
(
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Customer_table]

USE [bodb02]
GO
/****** Object:  Index [IX_master]    Script Date: 06/08/2009 22:11:06 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = N'IX_master')
DROP INDEX [IX_master] ON [dbo].[Customer] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_master]    Script Date: 06/08/2009 22:11:12 ******/
CREATE NONCLUSTERED INDEX [IX_master] ON [dbo].[Customer] 
(
	[mrecommend] ASC,
	[roleid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Customer_index]

USE [bodb02]
GO
/****** Object:  Index [ix_sma]    Script Date: 06/08/2009 22:11:19 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Customer]') AND name = N'ix_sma')
DROP INDEX [ix_sma] ON [dbo].[Customer] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [ix_sma]    Script Date: 06/08/2009 22:11:25 ******/
CREATE NONCLUSTERED INDEX [ix_sma] ON [dbo].[Customer] 
(
	[srecommend] ASC,
	[roleid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Customer_index]


--======================================================
--===================custInfo===========================
--======================================================

USE [bodb02]
GO
/****** Object:  Index [_MS_Sys_6]    Script Date: 06/08/2009 22:12:33 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[custInfo]') AND name = N'_MS_Sys_6')
DROP INDEX [_MS_Sys_6] ON [dbo].[custInfo] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [_MS_Sys_6]    Script Date: 06/08/2009 22:13:00 ******/
CREATE NONCLUSTERED INDEX [_MS_Sys_6] ON [dbo].[custInfo] 
(
	[mrecommend] ASC
)
INCLUDE ( [roleid],
[credit],
[closed]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CustInfo_index]

USE [bodb02]
GO
/****** Object:  Index [IX_CI_srecommend]    Script Date: 06/08/2009 22:13:09 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[custInfo]') AND name = N'IX_CI_srecommend')
DROP INDEX [IX_CI_srecommend] ON [dbo].[custInfo] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_CI_srecommend]    Script Date: 06/08/2009 22:13:16 ******/
CREATE NONCLUSTERED INDEX [IX_CI_srecommend] ON [dbo].[custInfo] 
(
	[srecommend] ASC
)
INCLUDE ( [closed],
[credit],
[roleid]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 50) ON [CustInfo_index]

USE [bodb02]
GO
/****** Object:  Index [IX_custinfo]    Script Date: 06/08/2009 22:13:23 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[custInfo]') AND name = N'IX_custinfo')
DROP INDEX [IX_custinfo] ON [dbo].[custInfo] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_custinfo]    Script Date: 06/08/2009 22:13:29 ******/
CREATE NONCLUSTERED INDEX [IX_custinfo] ON [dbo].[custInfo] 
(
	[mrecommend] ASC,
	[roleid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CustInfo_index]


USE [bodb02]
GO
/****** Object:  Index [IX_custinfo_1]    Script Date: 06/08/2009 22:13:38 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[custInfo]') AND name = N'IX_custinfo_1')
DROP INDEX [IX_custinfo_1] ON [dbo].[custInfo] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_custinfo_1]    Script Date: 06/08/2009 22:13:44 ******/
CREATE NONCLUSTERED INDEX [IX_custinfo_1] ON [dbo].[custInfo] 
(
	[recommend] ASC,
	[roleid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CustInfo_index]


--======================================================
--===================bettrans14=========================
--======================================================

USE [bodb02]
GO
/****** Object:  Index [bettrans1413]    Script Date: 06/08/2009 22:14:23 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans14]') AND name = N'bettrans1413')
DROP INDEX [bettrans1413] ON [dbo].[bettrans14] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [bettrans1413]    Script Date: 06/08/2009 22:14:34 ******/
CREATE NONCLUSTERED INDEX [bettrans1413] ON [dbo].[bettrans14] 
(
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [14_index]


USE [bodb02]
GO
/****** Object:  Index [bettrans1423]    Script Date: 06/08/2009 22:14:42 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans14]') AND name = N'bettrans1423')
DROP INDEX [bettrans1423] ON [dbo].[bettrans14] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [bettrans1423]    Script Date: 06/08/2009 22:14:49 ******/
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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [14_index]

USE [bodb02]
GO
/****** Object:  Index [bettrans143]    Script Date: 06/08/2009 22:14:56 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans14]') AND name = N'bettrans143')
DROP INDEX [bettrans143] ON [dbo].[bettrans14] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [bettrans143]    Script Date: 06/08/2009 22:15:02 ******/
CREATE NONCLUSTERED INDEX [bettrans143] ON [dbo].[bettrans14] 
(
	[recommend] ASC,
	[odds] ASC,
	[stake] ASC,
	[winlost] ASC,
	[awinlost] ASC,
	[mwinlost] ASC,
	[playercomm] ASC,
	[comm] ASC,
	[acomm] ASC,
	[tpositiontaking] ASC,
	[winlostdate] ASC,
	[mrecommend] ASC,
	[scomm] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [14_index]

USE [bodb02]
GO
/****** Object:  Index [IX_bettrans14]    Script Date: 06/08/2009 22:15:23 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans14]') AND name = N'IX_bettrans14')
DROP INDEX [IX_bettrans14] ON [dbo].[bettrans14] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_bettrans14]    Script Date: 06/08/2009 22:15:27 ******/
CREATE CLUSTERED INDEX [IX_bettrans14] ON [dbo].[bettrans14] 
(
	[winlostdate] ASC,
	[custid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [14_table]

USE [bodb02]
GO
/****** Object:  Index [IX_bettrans4]    Script Date: 06/08/2009 22:15:35 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans14]') AND name = N'IX_bettrans4')
DROP INDEX [IX_bettrans4] ON [dbo].[bettrans14] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_bettrans4]    Script Date: 06/08/2009 22:15:41 ******/
CREATE NONCLUSTERED INDEX [IX_bettrans4] ON [dbo].[bettrans14] 
(
	[mrecommend] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [14_index]

--======================================================
--===================Match=============================
--======================================================

USE [bodb02]
GO
/****** Object:  Index [IX_match]    Script Date: 06/08/2009 22:16:29 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[match]') AND name = N'IX_match')
DROP INDEX [IX_match] ON [dbo].[match] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_match]    Script Date: 06/08/2009 22:16:32 ******/
CREATE NONCLUSTERED INDEX [IX_match] ON [dbo].[match] 
(
	[leagueid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]

USE [bodb02]
GO
/****** Object:  Index [IX_match_1]    Script Date: 06/08/2009 22:16:44 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[match]') AND name = N'IX_match_1')
DROP INDEX [IX_match_1] ON [dbo].[match] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_match_1]    Script Date: 06/08/2009 22:16:49 ******/
CREATE NONCLUSTERED INDEX [IX_match_1] ON [dbo].[match] 
(
	[matchid] ASC,
	[leagueid] ASC,
	[homeid] ASC,
	[awayid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]

USE [bodb02]
GO
/****** Object:  Index [IX_match_2]    Script Date: 06/08/2009 22:16:56 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[match]') AND name = N'IX_match_2')
DROP INDEX [IX_match_2] ON [dbo].[match] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_match_2]    Script Date: 06/08/2009 22:17:02 ******/
CREATE NONCLUSTERED INDEX [IX_match_2] ON [dbo].[match] 
(
	[awayid] ASC,
	[homeid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]

USE [bodb02]
GO
/****** Object:  Index [IX_match_5]    Script Date: 06/08/2009 22:17:09 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[match]') AND name = N'IX_match_5')
DROP INDEX [IX_match_5] ON [dbo].[match] WITH ( ONLINE = OFF )


USE [bodb02]
GO
/****** Object:  Index [IX_match_5]    Script Date: 06/08/2009 22:17:16 ******/
CREATE NONCLUSTERED INDEX [IX_match_5] ON [dbo].[match] 
(
	[eventdate] ASC,
	[eventstatus] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]


--======================================================
--===================Bettransm14========================
--======================================================

USE [bodb02]
GO
/****** Object:  Index [IX_bettransm14]    Script Date: 06/08/2009 22:18:09 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettransm14]') AND name = N'IX_bettransm14')
DROP INDEX [IX_bettransm14] ON [dbo].[bettransm14] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_bettransm14]    Script Date: 06/08/2009 22:18:14 ******/
CREATE CLUSTERED INDEX [IX_bettransm14] ON [dbo].[bettransm14] 
(
	[refno] ASC,
	[custid] ASC,
	[matchid] ASC,
	[oddsid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [14_table]



--======================================================
--===================Match14========================
--======================================================
USE [bodb02]
GO
/****** Object:  Index [IX_match14]    Script Date: 06/08/2009 22:18:37 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[match14]') AND name = N'IX_match14')
DROP INDEX [IX_match14] ON [dbo].[match14] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_match14]    Script Date: 06/08/2009 22:19:00 ******/
CREATE NONCLUSTERED INDEX [IX_match14] ON [dbo].[match14] 
(
	[matchid] ASC,
	[eventdate] ASC,
	[eventstatus] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]

--======================================================
--===================Odds14========================
--======================================================

USE [bodb02]
GO
/****** Object:  Index [IX_odds14]    Script Date: 06/08/2009 22:19:24 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[odds14]') AND name = N'IX_odds14')
DROP INDEX [IX_odds14] ON [dbo].[odds14] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_odds14]    Script Date: 06/08/2009 22:19:29 ******/
CREATE CLUSTERED INDEX [IX_odds14] ON [dbo].[odds14] 
(
	[oddsid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]

--======================================================
--===================Bettrans===========================
--======================================================
USE [bodb02]
GO
/****** Object:  Index [_MS_Sys_38_52_42]    Script Date: 06/08/2009 22:20:45 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'_MS_Sys_38_52_42')
DROP INDEX [_MS_Sys_38_52_42] ON [dbo].[bettrans] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [_MS_Sys_38_52_42]    Script Date: 06/08/2009 22:20:53 ******/
CREATE NONCLUSTERED INDEX [_MS_Sys_38_52_42] ON [dbo].[bettrans] 
(
	[srecommend] ASC,
	[mrecommend] ASC,
	[recommend] ASC,
	[bettype] ASC,
	[ruben] ASC
)
INCLUDE ( [odds],
[stake],
[apositiontaking],
[mpositiontaking],
[livehomescore],
[liveawayscore],
[liveindicator],
[matchid],
[betteam],
[spositiontaking]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX_BETTRANS]

USE [bodb02]
GO
/****** Object:  Index [bettrans16]    Script Date: 06/08/2009 22:21:00 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'bettrans16')
DROP INDEX [bettrans16] ON [dbo].[bettrans] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [bettrans16]    Script Date: 06/08/2009 22:21:06 ******/
CREATE NONCLUSTERED INDEX [bettrans16] ON [dbo].[bettrans] 
(
	[mrecommend] ASC,
	[recommend] ASC,
	[winlostdate] ASC,
	[bettype] ASC,
	[ruben] ASC,
	[status] ASC
)
INCLUDE ( [mwinlost],
[playercomm],
[comm],
[acomm],
[stake],
[winlost],
[awinlost],
[odds]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 50) ON [INDEX_BETTRANS]

USE [bodb02]
GO
/****** Object:  Index [CIX_recommend_matchid_bettype]    Script Date: 06/08/2009 22:21:18 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'CIX_recommend_matchid_bettype')
DROP INDEX [CIX_recommend_matchid_bettype] ON [dbo].[bettrans] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [CIX_recommend_matchid_bettype]    Script Date: 06/08/2009 22:21:24 ******/
CREATE CLUSTERED INDEX [CIX_recommend_matchid_bettype] ON [dbo].[bettrans] 
(
	[recommend] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 50) ON [DATA]

USE [bodb02]
GO
/****** Object:  Index [IX_custid_matchid_bettype]    Script Date: 06/08/2009 22:21:31 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'IX_custid_matchid_bettype')
DROP INDEX [IX_custid_matchid_bettype] ON [dbo].[bettrans] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_custid_matchid_bettype]    Script Date: 06/08/2009 22:21:37 ******/
CREATE NONCLUSTERED INDEX [IX_custid_matchid_bettype] ON [dbo].[bettrans] 
(
	[custid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [INDEX_BETTRANS]

USE [bodb02]
GO
/****** Object:  Index [IX_matchid_bettype]    Script Date: 06/08/2009 22:21:45 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'IX_matchid_bettype')
DROP INDEX [IX_matchid_bettype] ON [dbo].[bettrans] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_matchid_bettype]    Script Date: 06/08/2009 22:21:50 ******/
CREATE NONCLUSTERED INDEX [IX_matchid_bettype] ON [dbo].[bettrans] 
(
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX_BETTRANS]

USE [bodb02]
GO
/****** Object:  Index [IX_srecommend]    Script Date: 06/08/2009 22:22:04 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'IX_srecommend')
DROP INDEX [IX_srecommend] ON [dbo].[bettrans] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_srecommend]    Script Date: 06/08/2009 22:22:09 ******/
CREATE NONCLUSTERED INDEX [IX_srecommend] ON [dbo].[bettrans] 
(
	[srecommend] ASC
)
INCLUDE ( [ruben],
[scomm],
[actual_stake],
[spositiontaking],
[swinlost],
[winlostdate],
[recommend],
[mrecommend],
[custid],
[awinlost],
[winlost],
[acomm],
[comm],
[playercomm],
[mwinlost]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX_BETTRANS]


USE [bodb02]
GO
/****** Object:  Index [IX_winlostdate]    Script Date: 06/08/2009 22:22:18 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'IX_winlostdate')
DROP INDEX [IX_winlostdate] ON [dbo].[bettrans] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_winlostdate]    Script Date: 06/08/2009 22:22:23 ******/
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettrans] 
(
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX_BETTRANS]

USE [bodb02]
GO
/****** Object:  Index [IXU_transid]    Script Date: 06/08/2009 22:22:30 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettrans]') AND name = N'IXU_transid')
DROP INDEX [IXU_transid] ON [dbo].[bettrans] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IXU_transid]    Script Date: 06/08/2009 22:22:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IXU_transid] ON [dbo].[bettrans] 
(
	[transid] ASC
)
INCLUDE ( [winlostdate],
[matchid],
[betteam],
[currency],
[ruben],
[bettype],
[liveindicator],
[liveawayscore],
[livehomescore],
[tpositiontaking],
[status],
[stake],
[custid],
[oddsid],
[hdp1],
[hdp2],
[odds]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX_BETTRANS]



--======================================================
--===================Odds===============================
--======================================================

USE [bodb02]
GO
/****** Object:  Index [IX_odds]    Script Date: 06/08/2009 22:22:59 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[odds]') AND name = N'IX_odds')
DROP INDEX [IX_odds] ON [dbo].[odds] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_odds]    Script Date: 06/08/2009 22:23:05 ******/
CREATE CLUSTERED INDEX [IX_odds] ON [dbo].[odds] 
(
	[oddsid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]


--======================================================
--===================Bettransm==========================
--======================================================
USE [bodb02]
GO
/****** Object:  Index [IX_bettransm]    Script Date: 06/08/2009 22:24:41 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettransm]') AND name = N'IX_bettransm')
DROP INDEX [IX_bettransm] ON [dbo].[bettransm] WITH ( ONLINE = OFF )
USE [bodb02]
GO
/****** Object:  Index [IX_bettransm]    Script Date: 06/08/2009 22:24:47 ******/
CREATE CLUSTERED INDEX [IX_bettransm] ON [dbo].[bettransm] 
(
	[custid] ASC,
	[refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 50) ON [DATA]

USE [bodb02]
GO
/****** Object:  Index [IX_bettransm_2]    Script Date: 06/08/2009 22:24:54 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettransm]') AND name = N'IX_bettransm_2')
DROP INDEX [IX_bettransm_2] ON [dbo].[bettransm] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_bettransm_2]    Script Date: 06/08/2009 22:25:00 ******/
CREATE NONCLUSTERED INDEX [IX_bettransm_2] ON [dbo].[bettransm] 
(
	[refno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]

USE [bodb02]
GO
/****** Object:  Index [IX_matchid]    Script Date: 06/08/2009 22:25:06 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[bettransm]') AND name = N'IX_matchid')
DROP INDEX [IX_matchid] ON [dbo].[bettransm] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_matchid]    Script Date: 06/08/2009 22:25:12 ******/
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[bettransm] 
(
	[matchid] ASC
)
INCLUDE ( [refno],
[statuswinlost]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]


--======================================================
--===================sum_winloss========================
--======================================================

USE [bodb02]
GO
/****** Object:  Index [IX_sum_winloss_ag]    Script Date: 06/08/2009 22:25:58 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[sum_winloss]') AND name = N'IX_sum_winloss_ag')
DROP INDEX [IX_sum_winloss_ag] ON [dbo].[sum_winloss] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_sum_winloss_ag]    Script Date: 06/08/2009 22:26:02 ******/
CREATE NONCLUSTERED INDEX [IX_sum_winloss_ag] ON [dbo].[sum_winloss] 
(
	[roleid] ASC,
	[recommend] ASC,
	[winlostdate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [14_index]

USE [bodb02]
GO
/****** Object:  Index [IX_sum_winloss_ma]    Script Date: 06/08/2009 22:26:14 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[sum_winloss]') AND name = N'IX_sum_winloss_ma')
DROP INDEX [IX_sum_winloss_ma] ON [dbo].[sum_winloss] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_sum_winloss_ma]    Script Date: 06/08/2009 22:26:19 ******/
CREATE CLUSTERED INDEX [IX_sum_winloss_ma] ON [dbo].[sum_winloss] 
(
	[winlostdate] ASC,
	[mrecommend] ASC,
	[roleid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [14_table]

USE [bodb02]
GO
/****** Object:  Index [IX_sum_winloss_sa]    Script Date: 06/08/2009 22:26:33 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[sum_winloss]') AND name = N'IX_sum_winloss_sa')
DROP INDEX [IX_sum_winloss_sa] ON [dbo].[sum_winloss] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_sum_winloss_sa]    Script Date: 06/08/2009 22:26:39 ******/
CREATE NONCLUSTERED INDEX [IX_sum_winloss_sa] ON [dbo].[sum_winloss] 
(
	[winlostdate] ASC,
	[srecommend] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [14_index]




--======================================================
--===================zzzbettrans========================
--======================================================

USE [bodb02]
GO
/****** Object:  Index [IX_zzzbettrans]    Script Date: 06/08/2009 22:27:38 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[zzzbettrans]') AND name = N'IX_zzzbettrans')
DROP INDEX [IX_zzzbettrans] ON [dbo].[zzzbettrans] WITH ( ONLINE = OFF )

USE [bodb02]
GO
/****** Object:  Index [IX_zzzbettrans]    Script Date: 06/08/2009 22:27:43 ******/
CREATE CLUSTERED INDEX [IX_zzzbettrans] ON [dbo].[zzzbettrans] 
(
	[custid] ASC,
	[matchid] ASC,
	[bettype] ASC,
	[status] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]

