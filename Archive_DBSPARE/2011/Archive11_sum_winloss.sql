 USE bodb_Archive11
GO
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M01]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M02]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M03]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M04]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M05]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M06]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M07]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M08]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M09]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M10]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M11]
ALTER DATABASE bodb_Archive11 ADD filegroup [SUM_11M12]

GO

ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M01', filename ='Q:\Archive\2011\SUM\SUM_11M01.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M01]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M02', filename ='Q:\Archive\2011\SUM\SUM_11M02.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M02]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M03', filename ='Q:\Archive\2011\SUM\SUM_11M03.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M03]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M04', filename ='Q:\Archive\2011\SUM\SUM_11M04.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M04]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M05', filename ='Q:\Archive\2011\SUM\SUM_11M05.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M05]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M06', filename ='Q:\Archive\2011\SUM\SUM_11M06.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M06]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M07', filename ='Q:\Archive\2011\SUM\SUM_11M07.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M07]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M08', filename ='Q:\Archive\2011\SUM\SUM_11M08.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M08]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M09', filename ='Q:\Archive\2011\SUM\SUM_11M09.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M09]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M10', filename ='Q:\Archive\2011\SUM\SUM_11M10.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M10]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M11', filename ='Q:\Archive\2011\SUM\SUM_11M11.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M11]
ALTER DATABASE bodb_Archive11 ADD FILE (name = 'SUM_11M12', filename ='Q:\Archive\2011\SUM\SUM_11M12.ndf', SIZE = 50 MB ,FILEGROWTH = 10 MB ) TO filegroup [SUM_11M12]
GO

--Create partition function
CREATE PARTITION FUNCTION pf_SUM_monthly (SMALLDATETIME) AS
RANGE LEFT FOR VALUES
(
'2011/01/31 23:59:00',
'2011/02/28 23:59:00',
'2011/03/31 23:59:00',
'2011/04/30 23:59:00',
'2011/05/31 23:59:00',
'2011/06/30 23:59:00',
'2011/07/31 23:59:00',
'2011/08/31 23:59:00',
'2011/09/30 23:59:00',
'2011/10/31 23:59:00',
'2011/11/30 23:59:00'

)

--Create partition schema
CREATE PARTITION SCHEME ps_SUM_monthly
AS PARTITION pf_SUM_monthly
TO
    (
    [SUM_11M01],
    [SUM_11M02],
    [SUM_11M03],
    [SUM_11M04],
    [SUM_11M05],
    [SUM_11M06],
    [SUM_11M07],
    [SUM_11M08],
    [SUM_11M09],
    [SUM_11M10],
    [SUM_11M11],
    [SUM_11M12]
 )               
GO
----------

CREATE TABLE [dbo].[sum_winloss_2011](
    [keyid] [BIGINT]  NOT NULL,
    [winlostdate] [SMALLDATETIME] NULL,
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
CREATE CLUSTERED INDEX [CIX_sum_winloss] ON [dbo].[sum_winloss_2011]
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
WHERE WINLOSTDATE BETWEEN '2011/01/01' AND 	'2011/12/31 23:59:00'

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