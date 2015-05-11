USE bodb_ABS
GO

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M01]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M02]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M03]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M04]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M05]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M06]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M07]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M08]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M09]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M10]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M11]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_12M12]

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M01]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M02]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M03]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M04]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M05]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M06]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M07]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M08]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M09]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M10]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M11]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_13M12]

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M01]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M02]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M03]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M04]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M05]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M06]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M07]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M08]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M09]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M10]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M11]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_14M12]

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M01]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M02]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M03]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M04]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M05]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M06]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M07]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M08]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M09]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M10]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M11]
ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_15M12]

ALTER DATABASE bodb_ABS ADD filegroup [abSumWinlossOld_Max]
GO

ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M01', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M01.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M01]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M02', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M02.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M02]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M03', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M03.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M03]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M04', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M04.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M04]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M05', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M05.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M05]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M06', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M06.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M06]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M07', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M07.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M07]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M08', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M08.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M08]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M09', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M09.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M09]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M10', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M10.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M10]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M11', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M11.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M11]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_12M12', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_12M12.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_12M12] 

ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M01', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M01.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M01]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M02', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M02.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M02]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M03', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M03.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M03]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M04', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M04.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M04]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M05', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M05.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M05]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M06', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M06.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M06]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M07', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M07.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M07]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M08', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M08.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M08]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M09', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M09.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M09]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M10', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M10.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M10]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M11', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M11.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M11]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_13M12', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_13M12.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_13M12] 


ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M01', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M01.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M01]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M02', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M02.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M02]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M03', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M03.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M03]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M04', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M04.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M04]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M05', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M05.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M05]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M06', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M06.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M06]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M07', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M07.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M07]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M08', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M08.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M08]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M09', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M09.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M09]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M10', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M10.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M10]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M11', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M11.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M11]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_14M12', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_14M12.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_14M12] 

ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M01', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M01.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M01]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M02', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M02.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M02]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M03', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M03.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M03]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M04', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M04.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M04]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M05', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M05.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M05]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M06', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M06.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M06]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M07', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M07.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M07]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M08', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M08.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M08]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M09', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M09.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M09]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M10', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M10.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M10]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M11', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M11.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M11]
ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_15M12', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_15M12.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_15M12] 

ALTER DATABASE bodb_ABS ADD FILE (name = 'abSumWinlossOld_MAX', filename = 'D:\IBC_DB\bodb_ABS\abSumWinlossOld_MAX.ndf', SIZE = 1024KB ,FILEGROWTH = 1024KB ) TO filegroup [abSumWinlossOld_MAX] 
GO

CREATE PARTITION FUNCTION pf_ABSum_Winloss_Old_monthly(DATETIME) AS
RANGE LEFT FOR VALUES
(
 '2012/01/31 23:59:00',
 '2012/02/29 23:59:00',
 '2012/03/31 23:59:00',
 '2012/04/30 23:59:00',
 '2012/05/31 23:59:00',
 '2012/06/30 23:59:00',
 '2012/07/31 23:59:00',
 '2012/08/31 23:59:00',
 '2012/09/30 23:59:00',
 '2012/10/31 23:59:00',
 '2012/11/30 23:59:00',
 '2012/12/31 23:59:00',
 '2013/01/31 23:59:00',
 '2013/02/28 23:59:00',
 '2013/03/31 23:59:00',
 '2013/04/30 23:59:00',
 '2013/05/31 23:59:00',
 '2013/06/30 23:59:00',
 '2013/07/31 23:59:00',
 '2013/08/31 23:59:00',
 '2013/09/30 23:59:00',
 '2013/10/31 23:59:00',
 '2013/11/30 23:59:00',
 '2013/12/31 23:59:00',
 '2014/01/31 23:59:00',
 '2014/02/28 23:59:00',
 '2014/03/31 23:59:00',
 '2014/04/30 23:59:00',
 '2014/05/31 23:59:00',
 '2014/06/30 23:59:00',
 '2014/07/31 23:59:00',
 '2014/08/31 23:59:00',
 '2014/09/30 23:59:00',
 '2014/10/31 23:59:00',
 '2014/11/30 23:59:00',
 '2014/12/31 23:59:00',
 '2015/01/31 23:59:00',
 '2015/02/28 23:59:00',
 '2015/03/31 23:59:00',
 '2015/04/30 23:59:00',
 '2015/05/31 23:59:00',
 '2015/06/30 23:59:00',
 '2015/07/31 23:59:00',
 '2015/08/31 23:59:00',
 '2015/09/30 23:59:00',
 '2015/10/31 23:59:00',
 '2015/11/30 23:59:00',
 '2015/12/31 23:59:00'	
)

CREATE PARTITION SCHEME ps_ABSum_Winloss_Old_monthly
AS PARTITION pf_ABSum_Winloss_Old_monthly
TO
(
	[abSumWinlossOld_12M01],
	[abSumWinlossOld_12M02],
	[abSumWinlossOld_12M03],
	[abSumWinlossOld_12M04],
	[abSumWinlossOld_12M05],
	[abSumWinlossOld_12M06],
	[abSumWinlossOld_12M07],
	[abSumWinlossOld_12M08],
	[abSumWinlossOld_12M09],
	[abSumWinlossOld_12M10],
	[abSumWinlossOld_12M11],
	[abSumWinlossOld_12M12],
	
	[abSumWinlossOld_13M01],
	[abSumWinlossOld_13M02],
	[abSumWinlossOld_13M03],
	[abSumWinlossOld_13M04],
	[abSumWinlossOld_13M05],
	[abSumWinlossOld_13M06],
	[abSumWinlossOld_13M07],
	[abSumWinlossOld_13M08],
	[abSumWinlossOld_13M09],
	[abSumWinlossOld_13M10],
	[abSumWinlossOld_13M11],
	[abSumWinlossOld_13M12],
	
	[abSumWinlossOld_14M01],
	[abSumWinlossOld_14M02],
	[abSumWinlossOld_14M03],
	[abSumWinlossOld_14M04],
	[abSumWinlossOld_14M05],
	[abSumWinlossOld_14M06],
	[abSumWinlossOld_14M07],
	[abSumWinlossOld_14M08],
	[abSumWinlossOld_14M09],
	[abSumWinlossOld_14M10],
	[abSumWinlossOld_14M11],
	[abSumWinlossOld_14M12],

	[abSumWinlossOld_15M01],
	[abSumWinlossOld_15M02],
	[abSumWinlossOld_15M03],
	[abSumWinlossOld_15M04],
	[abSumWinlossOld_15M05],
	[abSumWinlossOld_15M06],
	[abSumWinlossOld_15M07],
	[abSumWinlossOld_15M08],
	[abSumWinlossOld_15M09],
	[abSumWinlossOld_15M10],
	[abSumWinlossOld_15M11],
	[abSumWinlossOld_15M12],
	[abSumWinlossOld_MAX]
)
GO

CREATE TABLE [dbo].[ABSum_winloss_Old](
	[winlostdate] [datetime] NOT NULL,
	[punterid] [int] NOT NULL,
	[leagueid] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[bettype] [int] NOT NULL,
	[currency] [int] NULL,
	[statusid] [tinyint] NULL,
	[turnover] [money] NULL,
	[comm] [money] NULL,
	[winlost] [money] NULL,
	[betcount] [int] NULL
) ON [absSUM]

CREATE CLUSTERED INDEX [CIX_ABSum_winloss_Old] ON [dbo].[ABSum_winloss_Old] 
(
	[winlostdate] ASC,
	[punterid] ASC,
	[leagueid] ASC,
	[matchid] ASC,
	[bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) 
ON ps_ABSum_Winloss_Old_monthly(winlostdate)

