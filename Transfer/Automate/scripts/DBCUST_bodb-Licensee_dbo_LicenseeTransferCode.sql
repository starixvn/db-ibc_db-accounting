--DBCUST/bodb_Licensee
USE [bodb_Licensee]
GO

/****** Object:  Table [dbo].[LicenseeTransferCode]    Script Date: 07/18/2019 14:39:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[LicenseeTransferCode](
	[LicenseeName] [varchar](50) NOT NULL,
	[CustID] [int] NOT NULL,
	[StatusID] [tinyint] NOT NULL,
	[LastMonthDate] [smalldatetime] NULL,
	[LastTransferDate] [datetime] NULL,
 CONSTRAINT [PK_LicenseeTransferCode] PRIMARY KEY CLUSTERED 
(
	[LicenseeName] ASC,
	[CustID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[LicenseeTransferCode] ADD  DEFAULT ((1)) FOR [StatusID]
GO


