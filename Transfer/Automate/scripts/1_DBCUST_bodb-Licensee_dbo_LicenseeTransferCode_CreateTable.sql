--DBCUST/bodb_Licensee
USE [bodb_Licensee]
GO

CREATE TABLE [dbo].[LicenseeTransferCode](
	[LicenseeName] [varchar](50) NOT NULL,
	[CustID] [int] NOT NULL,
	[StatusID] [tinyint] NOT NULL DEFAULT(1),
	[LastMonthDate] [smalldatetime] NULL,
	[LastTransferDate] [datetime] NULL,
	CONSTRAINT [PK_LicenseeTransferCode] PRIMARY KEY CLUSTERED 
	(
		[LicenseeName] ASC,
		[CustID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Licensee_index]
) ON [Licensee_table]
GO
