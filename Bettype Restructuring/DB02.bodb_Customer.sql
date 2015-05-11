ALTER TABLE [dbo].[CustSetting3rd_old] DROP CONSTRAINT [PK_CustSetting3rd]
GO
ALTER TABLE CustSetting3rd_old
ALTER COLUMN bettype SMALLINT NOT NULL

GO
ALTER TABLE CustSetting3rd_old
ALTER COLUMN sporttype SMALLINT NOT NULL

GO
USE [bodb_Customer]
GO
/****** Object:  Index [PK_CustSetting3rd]    Script Date: 02/10/2011 02:31:19 ******/
ALTER TABLE [dbo].[CustSetting3rd_old] ADD  CONSTRAINT [PK_CustSetting3rd] PRIMARY KEY CLUSTERED 
(
	[custid] ASC,
	[bettype] ASC,
	[sporttype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [Custsetting_table]

---------
--custSetting_old
ALTER TABLE [dbo].[custSetting_old] DROP CONSTRAINT [PK_custsetting]
GO
ALTER TABLE custSetting_old
ALTER COLUMN bettype SMALLINT NOT NULL

GO
ALTER TABLE custSetting_old
ALTER COLUMN sporttype SMALLINT NOT NULL

GO
USE [bodb_Customer]
GO
ALTER TABLE [dbo].[custSetting_old] ADD  CONSTRAINT [PK_custsetting] PRIMARY KEY CLUSTERED 
(
	[custid] ASC,
	[bettype] ASC,
	[sporttype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 50) ON [Custsetting_table]