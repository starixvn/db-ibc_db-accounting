 USE bodb_Archive09
GO
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M01]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M02]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M03]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M04]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M05]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M06]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M07]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M08]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M09]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M10]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M11]
ALTER DATABASE bodb_Archive09 ADD filegroup [SUM_09M12]

GO

ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M01', filename ='P:\Archive\2009\SUM\SUM_09M01.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M01]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M02', filename ='P:\Archive\2009\SUM\SUM_09M02.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M02]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M03', filename ='P:\Archive\2009\SUM\SUM_09M03.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M03]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M04', filename ='P:\Archive\2009\SUM\SUM_09M04.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M04]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M05', filename ='P:\Archive\2009\SUM\SUM_09M05.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M05]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M06', filename ='P:\Archive\2009\SUM\SUM_09M06.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M06]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M07', filename ='P:\Archive\2009\SUM\SUM_09M07.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M07]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M08', filename ='P:\Archive\2009\SUM\SUM_09M08.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M08]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M09', filename ='P:\Archive\2009\SUM\SUM_09M09.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M09]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M10', filename ='P:\Archive\2009\SUM\SUM_09M10.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M10]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M11', filename ='P:\Archive\2009\SUM\SUM_09M11.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M11]
ALTER DATABASE bodb_Archive09 ADD FILE (name = 'SUM_09M12', filename ='P:\Archive\2009\SUM\SUM_09M12.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_09M12]
GO

--Create partition function
CREATE PARTITION FUNCTION pf_SUM_monthly (DATETIME) AS
RANGE LEFT FOR VALUES
(
'2009/01/31 23:59:59.997',
'2009/02/28 23:59:59.997',
'2009/03/31 23:59:59.997',
'2009/04/30 23:59:59.997',
'2009/05/31 23:59:59.997',
'2009/06/30 23:59:59.997',
'2009/07/31 23:59:59.997',
'2009/08/31 23:59:59.997',
'2009/09/30 23:59:59.997',
'2009/10/31 23:59:59.997',
'2009/11/30 23:59:59.997'
)

--Create partition schema
CREATE PARTITION SCHEME ps_SUM_monthly
AS PARTITION pf_SUM_monthly
TO
    (
    [SUM_09M01],
    [SUM_09M02],
    [SUM_09M03],
    [SUM_09M04],
    [SUM_09M05],
    [SUM_09M06],
    [SUM_09M07],
    [SUM_09M08],
    [SUM_09M09],
    [SUM_09M10],
    [SUM_09M11],
    [SUM_09M12]
 )               
GO
----------

CREATE TABLE [dbo].[sum_winloss_2009](
    [keyid] [BIGINT]  NOT NULL,
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
    [sporttype] [SMALLINT] NOT NULL ,
    [bettype] [SMALLINT] NOT NULL
) ON [PRIMARY]

GO

/****** Object:  Index [CIX_sum_winloss]    Script Date: 11/14/2009 23:56:36 ******/
CREATE CLUSTERED INDEX [CIX_sum_winloss] ON [dbo].[sum_winloss_2009]
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
--IMPORT DATA
SELECT     keyid, winlostdate, username, custid, roleid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost, 
                      playercomm, comm, acomm, scomm, BetCount, grosscomm, sporttype, bettype
FROM         sum_winloss_old WITH (nolock)
WHERE WINLOSTDATE BETWEEN '2009/01/01' AND 	'2009/12/31 23:59:00'

--DOUBLE CHECK DATA
/*
select * from partitionDetail
1	1741785
2	1517223
3	1689984
4	1725392
5	1608953
6	1961046
7	1369786
8	1879720
9	1971622
10	2251504
11	2409465
12	2310743
-------
1	1741785
2	1517223
3	1689984
4	1725392
5	1608953
6	1961046
7	1369786
8	1879720
9	1971622
10	2251504
11	2409465
12	2310743
*/