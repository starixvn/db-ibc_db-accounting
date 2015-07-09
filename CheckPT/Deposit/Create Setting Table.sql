USE CheckLicenseeDB
GO 

/****** Object:  Table [dbo].[LicenseeBAConfig]    Script Date: 4/22/2014 8:23:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[LicenseeBAConfig](
	[InsertDate] [SmallDateTime] NOT NULL,
	[LicenseeID] [int] NOT NULL,
	[1x2Comm] [decimal](9, 8) NOT NULL,
	[OtherComm] [decimal](9, 8) NOT NULL,
	[EnableBA] [bit] NOT NULL,
	[ModifyBy] [int] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
	[groupa] [decimal](9, 8) NOT NULL,
	[groupb] [decimal](9, 8) NOT NULL,
	[groupc] [decimal](9, 8) NOT NULL,
	[groupd] [decimal](9, 8) NOT NULL,
 CONSTRAINT [PK_LicenseeBAConfig] PRIMARY KEY CLUSTERED 
(
	[InsertDate] ASC,
	[LicenseeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
) ON [CheckResultData]
 

CREATE TABLE [dbo].[LicenseeBAHistory](
	[InsertDate] [SmallDateTime] NOT NULL,
	[ID] [int] NOT NULL,
	[LicenseeID] [int] NOT NULL,
	[CustID] [int] NOT NULL,
	[OnDate] [datetime] NOT NULL,
	[OffDate] [datetime] NULL,
	[OnBy] [int] NOT NULL,
	[OffBy] [int] NULL,
	[GroupComm] [decimal](9, 8) NOT NULL,
	[1x2Comm] [decimal](9, 8) NOT NULL,
	[OtherComm] [decimal](9, 8) NOT NULL,
	[Status] [varchar](50) NOT NULL,
	[Ugroup] [varchar](3) NULL
) ON [CheckResultData]

GO

CREATE TABLE [dbo].[LicenseeSpecialCust](
	[InsertDate] [SmallDateTime] NOT NULL,
	[Licenseeid] [int] NOT NULL,
	[Custid] [int] NOT NULL,
	[ugroup] [varchar](3) NOT NULL,
	[ugroup_old] [varchar](3) NOT NULL,
	[modifyby] [int] NOT NULL,
	[modifydate] [datetime] NOT NULL,
 CONSTRAINT [PK_LicenseeSpecialCust] PRIMARY KEY CLUSTERED 
(
	[InsertDate] ASC,
	[Custid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
) ON [CheckResultData]

GO

CREATE TABLE [dbo].[LicenseeGroupComm](
	[InsertDate] [SmallDateTime] NOT NULL,
	[id] [int] NOT NULL,
	[Licenseeid] [int] NOT NULL,
	[GroupName] [varchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[SBComm] [decimal](9, 8) NOT NULL,
	[RacingComm] [decimal](9, 8) NOT NULL,
	[NGComm] [decimal](9, 8) NOT NULL,
	[color] [varchar](20) NULL,
	[IsDefault] [bit] NOT NULL,
	[LCComm] [decimal](9, 8) NOT NULL,
	[RNGComm] [decimal](9, 8) NOT NULL
) ON [CheckResultData]

GO

CREATE TABLE [dbo].[LicenseeCustComm](
	[InsertDate] [SmallDateTime] NOT NULL,
	[LicenseeID] [int] NOT NULL,
	[CustID] [int] NOT NULL,
	[SBComm] [decimal](9, 8) NULL,
	[RacingComm] [decimal](9, 8) NULL,
	[NGComm] [decimal](9, 8) NULL,
	[GroupCommID] [int] NOT NULL,
	[LCComm] [decimal](9, 8) NOT NULL,
	[RNGComm] [decimal](9, 8) NOT NULL,
 CONSTRAINT [PK_LicenseeCustComm] PRIMARY KEY CLUSTERED 
(
	[InsertDate] ASC,
	[CustID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
) ON [CheckResultData]
 
CREATE TABLE [dbo].[Licensees](
	[LicenseeID] [int] NOT NULL,
	[LicenseeName] [varchar](50) NOT NULL,
	[Description] [varchar](100) NULL,
	[IsDeposit] [bit] NULL,
	[AffectedDate] [datetime] NULL,
	[BrandName] [varchar](100) NOT NULL,
	[CompanyName] [varchar](100) NOT NULL,
	[IsAllowedMemberComm] [bit] NOT NULL,
 CONSTRAINT [PK_Licensees] PRIMARY KEY CLUSTERED 
(
	[LicenseeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [CheckResultData]
) ON [CheckResultData]

GO

SET ANSI_PADDING OFF
GO
