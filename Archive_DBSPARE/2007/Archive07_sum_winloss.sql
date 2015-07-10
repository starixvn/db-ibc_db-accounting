 USE bodb_Archive07
GO
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M01]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M02]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M03]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M04]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M05]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M06]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M07]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M08]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M09]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M10]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M11]
ALTER DATABASE bodb_Archive07 ADD filegroup [SUM_07M12]

GO

ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M01', filename ='P:\Archive\2007\SUM\SUM_07M01.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M01]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M02', filename ='P:\Archive\2007\SUM\SUM_07M02.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M02]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M03', filename ='P:\Archive\2007\SUM\SUM_07M03.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M03]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M04', filename ='P:\Archive\2007\SUM\SUM_07M04.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M04]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M05', filename ='P:\Archive\2007\SUM\SUM_07M05.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M05]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M06', filename ='P:\Archive\2007\SUM\SUM_07M06.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M06]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M07', filename ='P:\Archive\2007\SUM\SUM_07M07.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M07]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M08', filename ='P:\Archive\2007\SUM\SUM_07M08.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M08]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M09', filename ='P:\Archive\2007\SUM\SUM_07M09.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M09]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M10', filename ='P:\Archive\2007\SUM\SUM_07M10.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M10]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M11', filename ='P:\Archive\2007\SUM\SUM_07M11.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M11]
ALTER DATABASE bodb_Archive07 ADD FILE (name = 'SUM_07M12', filename ='P:\Archive\2007\SUM\SUM_07M12.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_07M12]
GO

--Create partition function
CREATE PARTITION FUNCTION pf_SUM_monthly (DATETIME) AS
RANGE LEFT FOR VALUES
(
'2007/01/31 23:59:59.997',
'2007/02/28 23:59:59.997',
'2007/03/31 23:59:59.997',
'2007/04/30 23:59:59.997',
'2007/05/31 23:59:59.997',
'2007/06/30 23:59:59.997',
'2007/07/31 23:59:59.997',
'2007/08/31 23:59:59.997',
'2007/09/30 23:59:59.997',
'2007/10/31 23:59:59.997',
'2007/11/30 23:59:59.997'
)

--Create partition schema
CREATE PARTITION SCHEME ps_SUM_monthly
AS PARTITION pf_SUM_monthly
TO
    (
    [SUM_07M01],
    [SUM_07M02],
    [SUM_07M03],
    [SUM_07M04],
    [SUM_07M05],
    [SUM_07M06],
    [SUM_07M07],
    [SUM_07M08],
    [SUM_07M09],
    [SUM_07M10],
    [SUM_07M11],
    [SUM_07M12]
 )               
GO
----------

CREATE TABLE [dbo].[sum_winloss_2007](
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
CREATE CLUSTERED INDEX [CIX_sum_winloss] ON [dbo].[sum_winloss_2007]
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
----------
--DOUBLE CHECK DATA
/*
2006
1	577196
2	598871
3	749659
4	843157
5	834398
6	1225845
7	979508
8	1185875
9	1328955
10	1366776
11	1425099
12	1356997

1	577196
2	598871
3	749659
4	843157
5	834398
6	1225845
7	979508
8	1185875
9	1328955
10	1366776
11	1425099
12	1356997
*/