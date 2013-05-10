

/****** Object:  Table [dbo].[CustSearchEx]    Script Date: 05/29/2010 09:56:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[CustSearchEx](
	[UserId] [int] NOT NULL,
	[Username] [varchar](30) NOT NULL,
	[SearchCount] [int] NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[Currency] [int] NULL,
 CONSTRAINT [PK_CustSearchEx] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[Username] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO

SET ANSI_PADDING OFF
GO

