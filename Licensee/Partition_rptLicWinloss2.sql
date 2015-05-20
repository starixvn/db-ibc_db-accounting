USE bodb_licensee
GO

ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_10M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_11M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_12M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_13M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_MAX]
GO


ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_10M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_10M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_10M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M08', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M09', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M10', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M11', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_11M12', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_11M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_11M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M01', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M02', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M03', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M04', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M05', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M06', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M07', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M08', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M09', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M10', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M11', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_12M12', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_12M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_12M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M01', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M02', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M03', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M04', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M05', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M06', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M07', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M08', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M09', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M10', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M11', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_13M12', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_13M12.ndf', SIZE = 1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_13M12]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_MAX', filename ='R:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL_MAX.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicWL_MAX]


GO
CREATE PARTITION FUNCTION pf_rptLicWL_monthly (SMALLDATETIME)  AS
RANGE LEFT FOR VALUES
(
 '2010/01/31 23:59:00',
 '2010/02/28 23:59:00',
 '2010/03/31 23:59:00',
 '2010/04/30 23:59:00',
 '2010/05/31 23:59:00',
 '2010/06/30 23:59:00',
 '2010/07/31 23:59:00',
 '2010/08/31 23:59:00',
 '2010/09/30 23:59:00',
 '2010/10/31 23:59:00',
 '2010/11/30 23:59:00',
 '2010/12/31 23:59:00',
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
 '2011/11/30 23:59:00',
 '2011/12/31 23:59:00',
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
 '2013/12/31 23:59:00'
)

CREATE PARTITION SCHEME ps_rptLicWL_monthly
AS PARTITION pf_rptLicWL_monthly
TO
    (
    [rptLicWL_10M01],
    [rptLicWL_10M02],
    [rptLicWL_10M03],
    [rptLicWL_10M04],
    [rptLicWL_10M05],
    [rptLicWL_10M06],
    [rptLicWL_10M07],
    [rptLicWL_10M08],
    [rptLicWL_10M09],
    [rptLicWL_10M10],
    [rptLicWL_10M11],
    [rptLicWL_10M12],
    [rptLicWL_11M01],
    [rptLicWL_11M02],
    [rptLicWL_11M03],
    [rptLicWL_11M04],
    [rptLicWL_11M05],
    [rptLicWL_11M06],
    [rptLicWL_11M07],
    [rptLicWL_11M08],
    [rptLicWL_11M09],
    [rptLicWL_11M10],
    [rptLicWL_11M11],
    [rptLicWL_11M12],
    [rptLicWL_12M01],
    [rptLicWL_12M02],
    [rptLicWL_12M03],
    [rptLicWL_12M04],
    [rptLicWL_12M05],
    [rptLicWL_12M06],
    [rptLicWL_12M07],
    [rptLicWL_12M08],
    [rptLicWL_12M09],
    [rptLicWL_12M10],
    [rptLicWL_12M11],
    [rptLicWL_12M12],
    [rptLicWL_13M01],
    [rptLicWL_13M02],
    [rptLicWL_13M03],
    [rptLicWL_13M04],
    [rptLicWL_13M05],
    [rptLicWL_13M06],
    [rptLicWL_13M07],
    [rptLicWL_13M08],
    [rptLicWL_13M09],
    [rptLicWL_13M10],
    [rptLicWL_13M11],
    [rptLicWL_13M12],
    [rptLicWL_MAX]

   
 )              
GO
 
 
CREATE TABLE [dbo].[rptLicWinloss2](
    [keyid] [BIGINT] IDENTITY(1,1) NOT NULL,
    [winlostdate] [SMALLDATETIME] NULL,
    [username] [NVARCHAR](50)  NULL,
    [username2] [NVARCHAR](50) NULL,
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
    [winlostvirtual] [MONEY] NULL,
    [commvirtual] [MONEY] NULL,
    [BetCount] [INT] NULL,
    [Currency] [SMALLINT] NULL,
    [sporttype] [SMALLINT] NOT NULL,
    [bettype] [SMALLINT] NOT NULL,
	[statusID] [SMALLINT] NOT NULL,
	[isBA] [BIT] NOT NULL
) ON [DATA]

CREATE CLUSTERED INDEX  [CIX_rptLicWinloss2] ON [dbo].[rptLicWinloss2]
(
    [winlostdate] ASC,
    [srecommend] ASC,
    [mrecommend] ASC,
    [recommend] ASC,
    [roleid] ASC,
    [sporttype] ASC,
    [bettype] ASC,
    [statusID] ASC,
    [isBA] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON ps_rptLicWL_monthly(winlostdate)

CREATE NONCLUSTERED INDEX [IX_rptLicWinloss2_ag] ON [dbo].[rptLicWinloss2] 
(
	[recommend] ASC,
	[winlostdate] ASC,
	[roleid] ASC,
	[sporttype] ASC,
	[bettype] ASC,
	[statusID] ASC,
	[isBA] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) 
ON ps_rptLicWL_monthly(winlostdate)

GO
GRANT SELECT ON [dbo].[rptLicWinloss2] TO [bodbLicenseeNet]
GO
GRANT SELECT ON [dbo].[rptLicWinloss2] TO [bodbAdminNet]
   