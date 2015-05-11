USE [bodb_Archive10]
GO
/****** Object:  Table [dbo].[bingoBall_bk]    Script Date: 03/30/2013 06:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bingoBall_bk](
	[Matchid] [int] NOT NULL,
	[Seq] [tinyint] NOT NULL,
	[Number] [tinyint] NULL,
	[UpdateTime] [datetime] NULL,
 CONSTRAINT [PK_bingoBall_bk] PRIMARY KEY CLUSTERED 
(
	[Matchid] ASC,
	[Seq] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2010]
) ON [EVENT_2010]

GO
/****** Object:  Table [dbo].[Dot_Admin_Assignment_Operator_bk]    Script Date: 03/30/2013 06:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dot_Admin_Assignment_Operator_bk](
	[ID] [int] NOT NULL,
	[matchid] [int] NULL,
	[OperatorType] [int] NULL,
	[OperatorID] [int] NULL,
	[bettype] [smallint] NULL,
 CONSTRAINT [PK_Dot_admin_Assignment_Operator_bk] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2010]
) ON [EVENT_2010]

GO

/****** Object:  Index [IX_matchid]    Script Date: 03/30/2013 06:29:13 ******/
CREATE NONCLUSTERED INDEX [IX_matchid] ON [dbo].[Dot_Admin_Assignment_Operator_bk] 
(
	[matchid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EVENT_2010]
GO