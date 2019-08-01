--DBTXN/bodb02
USE [bodb02]
GO

CREATE TABLE [dbo].[LicenseeTransferPool](
	[TransferID] [int] IDENTITY(1,1) NOT NULL,
	[LicenseeName] [varchar](50) NULL,
	[FromCustId] [int] NULL,
	[FromCurrency] [int] NULL,
	[ToCustID] [int] NULL,
	[ToCurrency] [int] NULL,
	[ToUsername] [varchar](50) NULL,
	[FromAmount] [money] NULL,
	[FromExRate] [float] NULL,
	[ToExRate] [float] NULL,
	[ToAmount] [money] NULL,
	[Status] [varchar](10) NULL,
	[MonthDate] [smalldatetime] NULL,
	[TransferDate] [datetime] NULL,
	[Error] [varchar](4000) NULL
) ON [Others_table]

GO


