USE bodb_licensee
GO

ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_10M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_11M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_12M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_13M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicIPBetting_MAX]
GO


ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_10M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_10M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_11M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_11M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_12M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_12M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_13M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M12.ndf', SIZE = 1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_13M12]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicIPBetting_MAX', filename ='G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_MAX.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicIPBetting_MAX]


GO
CREATE PARTITION FUNCTION pf_rptLicIPBetting_monthly (SMALLDATETIME)  AS
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

CREATE PARTITION SCHEME ps_rptLicIPBetting_monthly
AS PARTITION pf_rptLicIPBetting_monthly
TO
    (
    [rptLicIPBetting_10M01],
    [rptLicIPBetting_10M02],
    [rptLicIPBetting_10M03],
    [rptLicIPBetting_10M04],
    [rptLicIPBetting_10M05],
    [rptLicIPBetting_10M06],
    [rptLicIPBetting_10M07],
    [rptLicIPBetting_10M08],
    [rptLicIPBetting_10M09],
    [rptLicIPBetting_10M10],
    [rptLicIPBetting_10M11],
    [rptLicIPBetting_10M12],
    [rptLicIPBetting_11M01],
    [rptLicIPBetting_11M02],
    [rptLicIPBetting_11M03],
    [rptLicIPBetting_11M04],
    [rptLicIPBetting_11M05],
    [rptLicIPBetting_11M06],
    [rptLicIPBetting_11M07],
    [rptLicIPBetting_11M08],
    [rptLicIPBetting_11M09],
    [rptLicIPBetting_11M10],
    [rptLicIPBetting_11M11],
    [rptLicIPBetting_11M12],
    [rptLicIPBetting_12M01],
    [rptLicIPBetting_12M02],
    [rptLicIPBetting_12M03],
    [rptLicIPBetting_12M04],
    [rptLicIPBetting_12M05],
    [rptLicIPBetting_12M06],
    [rptLicIPBetting_12M07],
    [rptLicIPBetting_12M08],
    [rptLicIPBetting_12M09],
    [rptLicIPBetting_12M10],
    [rptLicIPBetting_12M11],
    [rptLicIPBetting_12M12],
    [rptLicIPBetting_13M01],
    [rptLicIPBetting_13M02],
    [rptLicIPBetting_13M03],
    [rptLicIPBetting_13M04],
    [rptLicIPBetting_13M05],
    [rptLicIPBetting_13M06],
    [rptLicIPBetting_13M07],
    [rptLicIPBetting_13M08],
    [rptLicIPBetting_13M09],
    [rptLicIPBetting_13M10],
    [rptLicIPBetting_13M11],
    [rptLicIPBetting_13M12],
    [rptLicIPBetting_MAX]

   
 )              
GO
 
CREATE TABLE [dbo].[rptLicIPBetting](
    [keyid] [BIGINT] IDENTITY(1,1) NOT NULL,
    [winlostdate] [SMALLDATETIME] NULL,
    [Licenseeid] INT  NULL,
    [countrySHORT] VARCHAR(2) NULL,
    [Currency] [SMALLINT] NULL,
    [CustID] INT NULL,
    [ip] VARCHAR(20) NULL,
    [turnover] [MONEY] NULL,
    [winlost] [MONEY] NULL,
    [BetCount] [INT] NULL,
    [statusID] [SMALLINT] NULL
) ON [DATA]

CREATE CLUSTERED INDEX  [CIX_rptLicIPBetting] ON [dbo].[rptLicIPBetting]
(
    [winlostdate] ASC,
    [Licenseeid] ASC,
    [countrySHORT] ASC,
    [currency] ASC,
    [statusID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON ps_rptLicIPBetting_monthly(winlostdate)



GO
GRANT SELECT ON [dbo].[rptLicIPBetting] TO [bodbLicenseeNet]
GO
GRANT SELECT ON [dbo].[rptLicIPBetting] TO [bodbAdminNet]
    