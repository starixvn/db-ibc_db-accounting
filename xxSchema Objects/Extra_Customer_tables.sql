--Table [dbo].[CustAgent] 
CREATE TABLE [dbo].[CustAgent](
	[custid] [int] NOT NULL,
	[MaxCredit] [money] NOT NULL CONSTRAINT [DF_CustAgent_MaxCredit]  DEFAULT ((0)),
 CONSTRAINT [PK_CustAgent] PRIMARY KEY CLUSTERED 
(
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CustInfo_table]
) ON [CustInfo_table]
-------------------------
--Table [dbo].[CustMaster] 
CREATE TABLE [dbo].[CustMaster](
	[custid] [int] NOT NULL,
	[DisableAutoMPT] [bit] NOT NULL CONSTRAINT [DF_CustMaster_DisableAutoMPT]  DEFAULT ((0)),
 CONSTRAINT [PK_CustMaster] PRIMARY KEY CLUSTERED 
(
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CustInfo_table]
) ON [CustInfo_table]
-------------------------
--Table [dbo].[CustSuper] 
CREATE TABLE [dbo].[CustSuper](
	[custid] [int] NOT NULL,
	[AutoIBCPositionTaking_Tote] [smallmoney] NOT NULL CONSTRAINT [DF_CustSuper_AutoIBCPositionTaking_Tote]  DEFAULT ((0)),
	[AutoIBCPositionTaking_Fixed] [smallmoney] NOT NULL CONSTRAINT [DF_CustSuper_AutoIBCPositionTaking_Fixed]  DEFAULT ((0)),
 CONSTRAINT [PK_CustSuper] PRIMARY KEY CLUSTERED 
(
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [CustInfo_table]
) ON [CustInfo_table]
-------------------------
