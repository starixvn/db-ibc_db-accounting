USE bodb_Archive06
GO
ALTER DATABASE bodb_Archive06 ADD filegroup [TRANSFER_06]

--63060517 --> 10920MB
--1497175 --> 260MB

ALTER DATABASE bodb_Archive06 ADD FILE (name = 'TRANSFER_06', filename ='P:\Archive\2006\TRANSFER\Transfer_06.ndf', SIZE = 260 MB ,FILEGROWTH = 32 MB ) TO filegroup [TRANSFER_06]


CREATE TABLE [dbo].[Transfer_2006](
	[transid] [int] NOT NULL,
	[custid] [int] NOT NULL,
	[transdate] [datetime] NOT NULL,
	[Debit] [money] NOT NULL,
	[Credit] [money] NOT NULL,
	[TransDesc] [nvarchar](300) NULL,
	[winlostdate] [smalldatetime] NOT NULL,
	[recommend] [int] NOT NULL,
	[mrecommend] [int] NOT NULL,
	[srecommend] [int] NOT NULL,
	[bettype] [tinyint] NOT NULL,
	[currency] [tinyint] NULL,
	[refno] [bigint] NOT NULL,
	[creator] [int] NULL
) ON [TRANSFER_06]

GO

/****** Object:  Index [IX_Transfer_Data]    Script Date: 11/15/2009 09:44:04 ******/
CREATE CLUSTERED INDEX [IX_Transfer_Data] ON [dbo].[Transfer_2006] 
(
	[winlostdate] ASC,
	[recommend] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = OFF) ON [TRANSFER_06]

-----------
--TO IMPORT DATA
SELECT [transid]
      ,[custid]
      ,[transdate]
      ,[Debit]
      ,[Credit]
      ,[TransDesc]
      ,[winlostdate]
      ,[recommend]
      ,[mrecommend]
      ,[srecommend]
      ,[bettype]
      ,[currency]
      ,[refno]
      ,[creator]
  FROM [bodb_Archive].[dbo].[Transfer_BK] with (nolock)
where winlostdate <'2007-01-01'
------------
--DELETE DATA
SET NOCOUNT ON
WHILE 1=1
BEGIN
    DELETE TOP(10000) FROM [dbo].[Transfer_BK] where winlostdate <'2007-01-01'
      
    IF @@ROWCOUNT < 10000
        BREAK

END
SET NOCOUNT OFF
-------------------------- DONE ------------------------