USE bodb_Archive06
GO
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M01]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M02]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M03]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M04]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M05]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M06]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M07]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M08]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M09]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M10]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M11]
ALTER DATABASE bodb_Archive06 ADD filegroup [SUM_06M12]

GO

ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M01', filename ='P:\Archive\2006\SUM\SUM_06M01.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M01]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M02', filename ='P:\Archive\2006\SUM\SUM_06M02.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M02]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M03', filename ='P:\Archive\2006\SUM\SUM_06M03.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M03]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M04', filename ='P:\Archive\2006\SUM\SUM_06M04.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M04]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M05', filename ='P:\Archive\2006\SUM\SUM_06M05.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M05]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M06', filename ='P:\Archive\2006\SUM\SUM_06M06.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M06]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M07', filename ='P:\Archive\2006\SUM\SUM_06M07.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M07]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M08', filename ='P:\Archive\2006\SUM\SUM_06M08.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M08]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M09', filename ='P:\Archive\2006\SUM\SUM_06M09.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M09]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M10', filename ='P:\Archive\2006\SUM\SUM_06M10.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M10]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M11', filename ='P:\Archive\2006\SUM\SUM_06M11.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M11]
ALTER DATABASE bodb_Archive06 ADD FILE (name = 'SUM_06M12', filename ='P:\Archive\2006\SUM\SUM_06M12.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_06M12]
GO

--Create partition function
CREATE PARTITION FUNCTION pf_SUM_monthly (DATETIME) AS
RANGE LEFT FOR VALUES
(
 '2006/01/31 23:59:59.997',
'2006/02/28 23:59:59.997',
'2006/03/31 23:59:59.997',
'2006/04/30 23:59:59.997',
'2006/05/31 23:59:59.997',
'2006/06/30 23:59:59.997',
'2006/07/31 23:59:59.997',
'2006/08/31 23:59:59.997',
'2006/09/30 23:59:59.997',
'2006/10/31 23:59:59.997',
'2006/11/30 23:59:59.997'
)

--Create partition schema
CREATE PARTITION SCHEME ps_SUM_monthly
AS PARTITION pf_SUM_monthly
TO
    (
    [SUM_06M01],
    [SUM_06M02],
    [SUM_06M03],
    [SUM_06M04],
    [SUM_06M05],
    [SUM_06M06],
    [SUM_06M07],
    [SUM_06M08],
    [SUM_06M09],
    [SUM_06M10],
    [SUM_06M11],
    [SUM_06M12]
 )               
GO
----------

CREATE TABLE [dbo].[sum_winloss_2006](
    [keyid] [INT] IDENTITY(1,1) NOT NULL,
    [winlostdate] [DATETIME] NULL,
    [username] [NVARCHAR](50) NULL,
    [custid] [INT] NULL,
    [roleid] [INT] NULL,
    [recommend] [INT] NULL,
    [mrecommend] [INT] NULL,
    [srecommend] [INT] NULL,
    [turnover] [MONEY] NULL,
    [winlost] [MONEY] NULL,
    [awinlost] [MONEY] NULL,
    [mwinlost] [MONEY] NULL,
    [swinlost] [MONEY] NULL,
    [playercomm] [MONEY] NULL,
    [comm] [MONEY] NULL,
    [acomm] [MONEY] NULL,
    [scomm] [MONEY] NULL,
    [BetCount] [INT] NULL,
    [grosscomm] [MONEY] NULL,
    [sporttype] [TINYINT] NOT NULL ,
    [bettype] [TINYINT] NOT NULL
) ON [PRIMARY]

GO

/****** Object:  Index [CIX_sum_winloss]    Script Date: 11/14/2009 23:56:36 ******/
CREATE CLUSTERED INDEX [CIX_sum_winloss] ON [dbo].[sum_winloss_2006]
(
    [winlostdate] ASC,
    [srecommend] ASC,
    [mrecommend] ASC,
    [recommend] ASC,
    [roleid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON ps_SUM_monthly(winlostdate)

GO