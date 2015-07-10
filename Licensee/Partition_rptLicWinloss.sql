USE bodb_licensee
GO
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_10M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_11M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_12M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_13M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_14M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicensee_MAX]
GO



ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M01', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M02', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M03', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M04', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M05', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M06', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M07', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M08', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M09', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M10', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M11', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_10M12', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_10M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_10M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M01', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M02', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M03', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M04', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M05', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M06', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M07', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M08', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M09', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M10', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M11', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_11M12', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_11M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_11M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M01', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M02', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M03', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M04', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M05', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M06', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M07', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M08', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M09', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M10', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M11', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_12M12', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_12M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_12M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M01', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M02', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M03', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M04', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M05', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M06', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M07', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M08', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M09', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M10', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M11', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_13M12', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_13M12.ndf', SIZE = 1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_13M12]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M01', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M01.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M02', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M02.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M04', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M04.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M04', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M04.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M05', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M05.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M06', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M06.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M07', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M07.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M08', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M08.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M09', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M09.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M10', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M10.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M11', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M11.ndf', SIZE =  1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_14M12', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_14M12.ndf', SIZE = 1024KB ,FILEGROWTH = 42768KB ) TO filegroup [rptLicensee_14M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicensee_MAX', filename ='G:\IBC_DB\bodb_Licensee\rptLic\rptLicensee_MAX.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB ) TO filegroup [rptLicensee_MAX]


GO
CREATE PARTITION FUNCTION pf_rptLicensee_monthly (SMALLDATETIME)  AS
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
 '2014/12/31 23:59:00'
)

CREATE PARTITION SCHEME ps_rptLicensee_monthly
AS PARTITION pf_rptLicensee_monthly
TO
    (
    [rptLicensee_10M01],
    [rptLicensee_10M02],
    [rptLicensee_10M03],
    [rptLicensee_10M04],
    [rptLicensee_10M05],
    [rptLicensee_10M06],
    [rptLicensee_10M07],
    [rptLicensee_10M08],
    [rptLicensee_10M09],
    [rptLicensee_10M10],
    [rptLicensee_10M11],
    [rptLicensee_10M12],
    [rptLicensee_11M01],
    [rptLicensee_11M02],
    [rptLicensee_11M03],
    [rptLicensee_11M04],
    [rptLicensee_11M05],
    [rptLicensee_11M06],
    [rptLicensee_11M07],
    [rptLicensee_11M08],
    [rptLicensee_11M09],
    [rptLicensee_11M10],
    [rptLicensee_11M11],
    [rptLicensee_11M12],
    [rptLicensee_12M01],
    [rptLicensee_12M02],
    [rptLicensee_12M03],
    [rptLicensee_12M04],
    [rptLicensee_12M05],
    [rptLicensee_12M06],
    [rptLicensee_12M07],
    [rptLicensee_12M08],
    [rptLicensee_12M09],
    [rptLicensee_12M10],
    [rptLicensee_12M11],
    [rptLicensee_12M12],
    [rptLicensee_13M01],
    [rptLicensee_13M02],
    [rptLicensee_13M03],
    [rptLicensee_13M04],
    [rptLicensee_13M05],
    [rptLicensee_13M06],
    [rptLicensee_13M07],
    [rptLicensee_13M08],
    [rptLicensee_13M09],
    [rptLicensee_13M10],
    [rptLicensee_13M11],
    [rptLicensee_13M12],
    [rptLicensee_14M01],
    [rptLicensee_14M02],
    [rptLicensee_14M03],
    [rptLicensee_14M04],
    [rptLicensee_14M05],
    [rptLicensee_14M06],
    [rptLicensee_14M07],
    [rptLicensee_14M08],
    [rptLicensee_14M09],
    [rptLicensee_14M10],
    [rptLicensee_14M11],
    [rptLicensee_14M12],
    [rptLicensee_MAX]

   
 )              
GO
 
 
CREATE TABLE [dbo].[rptLicWinloss](
    [keyid] [bigint] IDENTITY(1,1) NOT NULL,
	[winlostdate] [smalldatetime] NULL,
	[username] [nvarchar](50) NULL,
	[username2] [nvarchar](50) NULL,
	[custid] [int] NULL,
	[roleid] [int] NULL,
	[recommend] [int] NULL,
	[mrecommend] [int] NULL,
	[srecommend] [int] NULL,
	[turnover] [money] NULL,
	[winlost] [money] NULL,
	[awinlost] [money] NULL,
	[mwinlost] [money] NULL,
	[swinlost] [money] NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL,
	[winlostvirtual] [money] NULL,
	[commvirtual] [money] NULL,
	[BetCount] [int] NULL,
	[Currency] [smallint] NULL,
	[sporttype] [smallint] NOT NULL,
	[bettype] [smallint] NOT NULL,
	[statusID] [smallint] NOT NULL,
	[isBA] [bit] NOT NULL,
	[isMobile] [bit] NOT NULL,
	[betfrom] [NVARCHAR](1) NOT NULL DEFAULT('')
 CONSTRAINT [PK_rptLicWinloss] PRIMARY KEY NONCLUSTERED
(
    [keyid] ASC
)
) ON [DATA]

CREATE CLUSTERED INDEX  [CIX_rptLicWinloss] ON [dbo].[rptLicWinloss]
(
    [winlostdate] ASC,
	[srecommend] ASC,
	[mrecommend] ASC,
	[recommend] ASC,
	[roleid] ASC,
	[sporttype] ASC,
	[bettype] ASC,
	[isBA] ASC,
	[statusID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON ps_rptLicensee_monthly(winlostdate)

CREATE NONCLUSTERED INDEX [IX_recommend] ON [dbo].[rptLicWinloss] 
(
	[recommend] ASC,
	[roleid] ASC,
	[isBA] ASC,
	[sporttype] ASC,
	[statusID] ASC
)
INCLUDE ( [turnover],
[winlost],
[awinlost],
[playercomm],
[comm],
[Currency],
[BetCount],
[isMobile],
[betfrom],
[custid]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO

GO
GRANT SELECT ON [dbo].[rptLicWinloss] TO [bodbLicenseeNet]
GO
GRANT SELECT ON [dbo].[rptLicWinloss] TO [bodbAdminNet]
  