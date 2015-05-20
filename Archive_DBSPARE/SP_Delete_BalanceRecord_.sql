-------------------------------------------------------

--DISCARD OLD DATA FOR BALANCERECORD_BK

--Let's say we need to discard data of June-2011

--1. Create staging table BR_11M06 on the same [BR_11M06] filegroup.
--Need to check the field names which might be changed already
USE [bodb02]
GO
/****** Object:  Table [dbo].[BR_11M06]    Script Date: 07/18/2012 07:30:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BR_11M06](
	[RowID] [bigint] NOT NULL,
	[custid] [int] NOT NULL,
	[transid] [bigint] NOT NULL,
	[bettype] [smallint] NOT NULL,
	[actual_stake] [money] NOT NULL,
	[winlost] [money] NOT NULL,
	[playercomm] [money] NOT NULL,
	[BalanceChanged] [money] NOT NULL,
	[NewBalance] [money] NULL,
	[ActionDate] [datetime] NOT NULL,
	[ActionID] [tinyint] NULL,
	[Action] [varchar](200) NOT NULL,
	[BTBalance] [money] NULL
)

GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [CIX_custid_actiondate]    Script Date: 07/18/2012 07:30:59 ******/
CREATE CLUSTERED INDEX [CIX_custid_actiondate] ON [dbo].[BR_11M06] 
(
	[custid] ASC,
	[ActionDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BR_11M06]
GO

/****** Object:  Index [IX_RowID]    Script Date: 07/18/2012 07:30:59 ******/
CREATE NONCLUSTERED INDEX [IX_RowID] ON [dbo].[BR_11M06] 
(
	[RowID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [BR_11M06]

--2. Switch the old data out – into the staging table.
ALTER TABLE BalanceRecord_bk SWITCH PARTITION 1 TO BR_11M06

--3. Alter the partition function to "remove" the boundary point for 'June-2011'.
ALTER PARTITION FUNCTION pf_BR_monthly() MERGE RANGE ('2011-06-30 23:59:59.997')

--4. Export data for backup if need be

--5. Drop table BR_11M06
Drop table BR_11M06

--6. Drop [BR_11M06] filegroup
ALTER DATABASE [bodb02]  REMOVE FILE [BR_11M06]
GO
ALTER DATABASE [bodb02] REMOVE FILEGROUP [BR_11M06]
GO