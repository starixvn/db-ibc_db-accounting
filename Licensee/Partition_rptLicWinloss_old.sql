USE bodb_licensee
GO
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_08M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_08M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_08M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_08M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_08M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_08M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_09M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_10M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_11M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_12M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M01]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M02]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M03]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M04]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M05]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M06]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M07]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M08]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M09]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M10]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M11]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_13M12]
ALTER DATABASE bodb_licensee ADD filegroup [rptLicWL_old_MAX]
GO

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_08M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_08M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_08M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_08M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_08M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_08M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_08M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_08M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_08M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_08M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_08M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_08M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_09M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_09M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_10M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_10M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_11M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_11M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_12M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_12M12]

ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M01', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M01.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M01]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M02', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M02.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M02]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M03', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M03.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M03]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M04', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M04.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M04]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M05', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M05.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M05]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M06', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M06.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M06]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M07', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M07.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M07]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M08', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M08.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M08]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M09', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M09.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M09]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M10', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M10.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M10]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M11', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M11.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M11]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_13M12', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M12.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_13M12]
ALTER DATABASE bodb_licensee ADD FILE (name = 'rptLicWL_old_MAX', filename ='G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_MAX.ndf', SIZE =  1024KB ,FILEGROWTH = 32768KB  ) TO filegroup [rptLicWL_old_MAX]

GO
CREATE PARTITION FUNCTION pf_rptLicWL_old_monthly (SMALLDATETIME)  AS
RANGE LEFT FOR VALUES
(
 '2008/07/31 23:59:00',
 '2008/08/31 23:59:00',
 '2008/09/30 23:59:00',
 '2008/10/31 23:59:00',
 '2008/11/30 23:59:00',
 '2008/12/31 23:59:00',	
 '2009/01/31 23:59:00',
 '2009/02/28 23:59:00',
 '2009/03/31 23:59:00',
 '2009/04/30 23:59:00',
 '2009/05/31 23:59:00',
 '2009/06/30 23:59:00',
 '2009/07/31 23:59:00',
 '2009/08/31 23:59:00',
 '2009/09/30 23:59:00',
 '2009/10/31 23:59:00',
 '2009/11/30 23:59:00',
 '2009/12/31 23:59:00',
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

CREATE PARTITION SCHEME ps_rptLicWL_old_monthly
AS PARTITION pf_rptLicWL_old_monthly
TO
    (
	[rptLicWL_old_08M07],
    [rptLicWL_old_08M08],
    [rptLicWL_old_08M09],
    [rptLicWL_old_08M10],
    [rptLicWL_old_08M11],
    [rptLicWL_old_08M12],
    [rptLicWL_old_09M01],
    [rptLicWL_old_09M02],
    [rptLicWL_old_09M03],
    [rptLicWL_old_09M04],
    [rptLicWL_old_09M05],
    [rptLicWL_old_09M06],
    [rptLicWL_old_09M07],
    [rptLicWL_old_09M08],
    [rptLicWL_old_09M09],
    [rptLicWL_old_09M10],
    [rptLicWL_old_09M11],
    [rptLicWL_old_09M12],
    [rptLicWL_old_10M01],
    [rptLicWL_old_10M02],
    [rptLicWL_old_10M03],
    [rptLicWL_old_10M04],
    [rptLicWL_old_10M05],
    [rptLicWL_old_10M06],
    [rptLicWL_old_10M07],
    [rptLicWL_old_10M08],
    [rptLicWL_old_10M09],
    [rptLicWL_old_10M10],
    [rptLicWL_old_10M11],
    [rptLicWL_old_10M12],
    [rptLicWL_old_11M01],
    [rptLicWL_old_11M02],
    [rptLicWL_old_11M03],
    [rptLicWL_old_11M04],
    [rptLicWL_old_11M05],
    [rptLicWL_old_11M06],
    [rptLicWL_old_11M07],
    [rptLicWL_old_11M08],
    [rptLicWL_old_11M09],
    [rptLicWL_old_11M10],
    [rptLicWL_old_11M11],
    [rptLicWL_old_11M12],
    [rptLicWL_old_12M01],
    [rptLicWL_old_12M02],
    [rptLicWL_old_12M03],
    [rptLicWL_old_12M04],
    [rptLicWL_old_12M05],
    [rptLicWL_old_12M06],
    [rptLicWL_old_12M07],
    [rptLicWL_old_12M08],
    [rptLicWL_old_12M09],
    [rptLicWL_old_12M10],
    [rptLicWL_old_12M11],
    [rptLicWL_old_12M12],
    [rptLicWL_old_13M01],
    [rptLicWL_old_13M02],
    [rptLicWL_old_13M03],
    [rptLicWL_old_13M04],
    [rptLicWL_old_13M05],
    [rptLicWL_old_13M06],
    [rptLicWL_old_13M07],
    [rptLicWL_old_13M08],
    [rptLicWL_old_13M09],
    [rptLicWL_old_13M10],
    [rptLicWL_old_13M11],
    [rptLicWL_old_13M12],
    [rptLicWL_old_MAX]   
 )              
GO
 
CREATE TABLE [dbo].[rptLicWinloss_old](
    [keyid] [BIGINT] IDENTITY(1,1) NOT NULL,
    [winlostdate] [SMALLDATETIME] NULL,
    [username] [NVARCHAR](50)  NULL,
    [username2] [NVARCHAR](50) NULL,
    [custid] [INT] NULL,
    [roleid] [INT] NULL,
    [recommend] [INT] NULL,
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
    [BetCount] [INT] NULL ,
    [Currency] [SMALLINT] NULL,
    [sporttype] [SMALLINT] NOT NULL ,
    [bettype] [SMALLINT] NOT NULL,
	[statusID] [SMALLINT] NOT NULL,
	[isBA] [BIT] NOT NULL,
	[isMobile] [BIT] NOT NULL,
	[betfrom] [NVARCHAR](1) NOT NULL DEFAULT('')

) ON [DATA]

CREATE CLUSTERED INDEX  [CIX_rptLicWinloss_old] ON [dbo].[rptLicWinloss_old]
(
    [winlostdate] ASC,
    [srecommend] ASC,
    [recommend] ASC,
    [roleid] ASC,
    [sporttype] ASC,
    [isBA] ASC,
    [statusID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
ON ps_rptLicWL_old_monthly(winlostdate)


GO
GRANT SELECT ON [dbo].[rptLicWinloss_old] TO [bodbLicenseeNet]
GO
GRANT SELECT ON [dbo].[rptLicWinloss_old] TO [bodbAdminNet]
 