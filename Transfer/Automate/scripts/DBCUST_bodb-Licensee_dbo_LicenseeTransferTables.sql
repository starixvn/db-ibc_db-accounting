--DBCUST/bodb_Licensee
USE [bodb_Licensee]
GO

IF(OBJECT_ID(N'LicenseeTransferCode') IS NOT NULL)
BEGIN
	DROP TABLE [dbo].[LicenseeTransferCode]
END
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

ALTER TABLE [dbo].[LicenseeTransferCode] ADD  DEFAULT ((1)) FOR [StatusID]
GO

IF(OBJECT_ID(N'LicenseeTransferMapping') IS NOT NULL)
BEGIN
	DROP TABLE [dbo].[LicenseeTransferMapping]
END
GO

CREATE TABLE [dbo].[LicenseeTransferMapping](
	[Username] [varchar](50) NOT NULL,
	[LicenseeName] [varchar](50) NOT NULL,
	[StatusID] [tinyint] NOT NULL
) ON [DATA]
GO


