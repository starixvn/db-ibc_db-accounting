--drop constraint  00:00:01"
ALTER TABLE [dbo].[Dot_Admin_MasterSetting] DROP CONSTRAINT [DF_Dot_Admin_MasterSetting_Enabled]<--¤£§tbettype¦ý»Ýdrop index

--drop index  00:18:45"
DROP INDEX [IX_BetHedgeRecord] ON [dbo].[BetHedgeRecord] WITH ( ONLINE = OFF )
DROP INDEX [CIX_matchid_bettype] ON [dbo].[bettrans] WITH ( ONLINE = OFF )
DROP INDEX [IX_recommend] ON [dbo].[bettrans] WITH ( ONLINE = OFF )
DROP INDEX [IX_bettrans14] ON [dbo].[bettrans14] WITH ( ONLINE = OFF )
DROP INDEX [bettrans1423] ON [dbo].[bettrans14] WITH ( ONLINE = OFF )
ALTER TABLE [Dot_Admin_MasterSetting] DROP CONSTRAINT [PK_Dot_Admin_MasterSetting]
ALTER TABLE [Dot_ParlayMatchSetting] DROP CONSTRAINT [PK_Dot_ParlayMatchSetting]
DROP INDEX [_MS_Sys_47_48_3] ON [dbo].[odds] WITH ( ONLINE = OFF )
DROP INDEX [IX_matchid] ON [dbo].[odds] WITH ( ONLINE = OFF )
DROP INDEX [UIX_GetAnOdds] ON [dbo].[odds] WITH ( ONLINE = OFF )
DROP INDEX [IX_zzzbettrans] ON [dbo].[zzzbettrans] WITH ( ONLINE = OFF )

--alter column
ALTER TABLE [dbo].[BetHedgeRecord] ALTER COLUMN [bettype] smallint
GO
ALTER TABLE [dbo].[bettrans] ALTER COLUMN [bettype] smallint
GO
ALTER TABLE [dbo].[bettrans14] ALTER COLUMN [bettype] smallint
GO
ALTER TABLE [dbo].[bettransm] ALTER COLUMN [bettype] smallint
GO
ALTER TABLE [dbo].[bettransm14] ALTER COLUMN [bettype] smallint
GO
ALTER TABLE [dbo].[bettranssum] ALTER COLUMN [bettype] smallint
GO
ALTER TABLE [dbo].[Dot_Admin_MasterSetting] ALTER COLUMN [Bettype] smallint NOT NULL
GO
ALTER TABLE [dbo].[Dot_ParlayMatchSetting] ALTER COLUMN [bettype] smallint NOT NULL
GO
ALTER TABLE [dbo].[odds] ALTER COLUMN [bettype] smallint
GO
ALTER TABLE [dbo].[Save_Jobs] ALTER COLUMN [BetType] smallint NOT NULL
GO
ALTER TABLE [dbo].[zzzbettrans] ALTER COLUMN [bettype] smallint
GO


--add PK constraint --00:00:01"
ALTER TABLE [dbo].[Dot_Admin_MasterSetting] ADD  CONSTRAINT [DF_Dot_Admin_MasterSetting_Enabled]  DEFAULT ((1)) FOR [Enabled]

--add constraint  --

--add index

CREATE CLUSTERED INDEX [IX_bettrans14] ON [dbo].[bettrans14] 
(
	[winlostdate] ASC,
	[custid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [Bettrans14_table]
GO
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
)WITH (IGNORE_DUP_KEY = OFF) ON [Bettrans14_index]
GO
ALTER TABLE [dbo].[Dot_ParlayMatchSetting] ADD  CONSTRAINT [PK_Dot_ParlayMatchSetting] PRIMARY KEY CLUSTERED 
(
	[matchid] ASC,
	[bettype] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [Event_table]
GO
ALTER TABLE [dbo].[Dot_Admin_MasterSetting] ADD  CONSTRAINT [PK_Dot_Admin_MasterSetting] PRIMARY KEY CLUSTERED 
(
	[LeagueID] ASC,
	[Range] ASC,
	[Bettype] ASC,
	[Seq] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [DATA]
GO

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
[sporttype]) WITH (IGNORE_DUP_KEY = OFF) ON [Odds_index]
GO
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[odds] 
(
	[matchid] ASC
)
INCLUDE ( [bettype],
[oddsid],
[oddsstatus],
[switch],
[diffbalance],
[changetime],
[newoffersetup],
[livehomescore],
[maxbet],
[site3],
[hometotal],
[awaytotal],
[liveindicator],
[liveawayscore],
[odds2a],
[odds1a],
[hdp2],
[hdp1],
[csstatus]) WITH (IGNORE_DUP_KEY = OFF) ON [Odds_index]
GO
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
[livehomescore],
[oddsstatus],
[sporttype]) WITH (IGNORE_DUP_KEY = OFF) ON [Odds_index]
GO
CREATE CLUSTERED INDEX [CIX_matchid_bettype] ON [dbo].[bettrans] 
(
	[matchid] ASC,
	[custid] ASC,
	[bettype] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [Bettrans_table]
GO

CREATE NONCLUSTERED INDEX [IX_recommend] ON [dbo].[bettrans] 
(
	[recommend] ASC
)
INCLUDE ( [winlostdate],
[bettype]) WITH (IGNORE_DUP_KEY = OFF) ON [Bettrans_index2]
GO
CREATE CLUSTERED INDEX [IX_BetHedgeRecord] ON [dbo].[BetHedgeRecord] 
(
	[matchid] ASC,
	[bettype] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [DATA]
GO
CREATE CLUSTERED INDEX [IX_zzzbettrans] ON [dbo].[zzzbettrans] 
(
	[custid] ASC,
	[matchid] ASC,
	[bettype] ASC,
	[status] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [Others_table]


