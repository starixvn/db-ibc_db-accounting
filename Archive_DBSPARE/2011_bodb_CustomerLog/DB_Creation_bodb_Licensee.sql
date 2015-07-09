 task_backupFull ''

RESTORE DATABASE [bodb_Licensee]
FROM  DISK = N'G:\Backup_Full\bodb_Licensee_backup_20121214_2023full.bak' WITH  FILE = 1, 
MOVE N'bodb_Licensee' TO N'G:\IBC_DB\bodb_Licensee\bodb_Licensee.mdf',
MOVE N'bodb_Licensee_log' TO N'G:\IBC_DB\bodb_Licensee\bodb_Licensee_log.ldf',
MOVE N'bodb_Licensee_log03' TO N'G:\IBC_DB\bodb_Licensee\bodb_Licensee_log03.ldf',
MOVE N'_rptLicIPBetting_10M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M01.ndf',
MOVE N'DW_transfer_DATA_04' TO N'G:\IBC_DB\bodb_Licensee\DW_transfer_DATA_04.ndf',
MOVE N'_rptLicIPBetting_10M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M02.ndf',
MOVE N'_rptLicIPBetting_10M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M03.ndf',
MOVE N'_rptLicIPBetting_10M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M04.ndf',
MOVE N'_rptLicIPBetting_10M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M05.ndf',
MOVE N'_rptLicIPBetting_10M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M06.ndf',
MOVE N'_rptLicIPBetting_10M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M07.ndf',
MOVE N'_rptLicIPBetting_10M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M08.ndf',
MOVE N'BA_Data_1' TO N'G:\IBC_DB\bodb_Licensee\BA\BA_Data_01.ndf',
MOVE N'_rptLicIPBetting_10M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M09.ndf',
MOVE N'data01' TO N'G:\IBC_DB\bodb_Licensee\data01.ndf',
MOVE N'data02' TO N'G:\IBC_DB\bodb_licensee\data02.ndf',
MOVE N'index_02' TO N'G:\IBC_DB\bodb_Licensee\index_02.ndf',
MOVE N'licensee_table_02' TO N'G:\IBC_DB\bodb_Licensee\licensee_table_02.ndf',
MOVE N'on_user_index_02' TO N'G:\IBC_DB\bodb_Licensee\on_user_index_02.ndf',
MOVE N'on_user_table_02' TO N'G:\IBC_DB\bodb_Licensee\on_user_table_02.ndf',
MOVE N'user_index_02' TO N'G:\IBC_DB\bodb_Licensee\user_index_02.ndf',
MOVE N'user_table_02' TO N'G:\IBC_DB\bodb_Licensee\user_table_02.ndf',
MOVE N'userlog_index_02' TO N'G:\IBC_DB\bodb_Licensee\userlog_index_02.ndf',
MOVE N'userlog_table_02' TO N'G:\IBC_DB\bodb_Licensee\userlog_table_02.ndf',
MOVE N'BATrans_01' TO N'G:\IBC_DB\bodb_Licensee\BATrans_01.ndf',
MOVE N'OWA_Data_02' TO N'G:\IBC_DB\bodb_Licensee\OWA\OWA_Data_02.ndf',
MOVE N'OWA_Index_02' TO N'G:\IBC_DB\bodb_Licensee\OWA\OWA_Index_02.ndf',
MOVE N'OWA_Userlog_data_03' TO N'G:\IBC_DB\bodb_Licensee\OWA\OWA_Userlog_data_03.ndf',
MOVE N'OWA_Userlog_index_03' TO N'G:\IBC_DB\bodb_Licensee\OWA\OWA_Userlog_index_03.ndf',
MOVE N'_rptLicIPBetting_10M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M10.ndf',
MOVE N'_rptLicIPBetting_10M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M11.ndf',
MOVE N'_rptLicIPBetting_10M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_10M12.ndf',
MOVE N'_rptLicIPBetting_11M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M01.ndf',
MOVE N'_rptLicIPBetting_11M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M02.ndf',
MOVE N'_rptLicIPBetting_11M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M03.ndf',
MOVE N'_rptLicIPBetting_11M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M04.ndf',
MOVE N'_rptLicIPBetting_11M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M05.ndf',
MOVE N'_rptLicIPBetting_11M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M06.ndf',
MOVE N'_rptLicIPBetting_11M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M07.ndf',
MOVE N'_rptLicIPBetting_11M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M08.ndf',
MOVE N'_rptLicIPBetting_11M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M09.ndf',
MOVE N'_rptLicIPBetting_11M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M10.ndf',
MOVE N'_rptLicIPBetting_11M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M11.ndf',
MOVE N'_rptLicIPBetting_11M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_11M12.ndf',
MOVE N'_rptLicIPBetting_12M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M01.ndf',
MOVE N'_rptLicIPBetting_12M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M02.ndf',
MOVE N'_rptLicIPBetting_12M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M03.ndf',
MOVE N'_rptLicIPBetting_12M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M04.ndf',
MOVE N'_rptLicIPBetting_12M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M05.ndf',
MOVE N'_rptLicIPBetting_12M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M06.ndf',
MOVE N'_rptLicIPBetting_12M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M07.ndf',
MOVE N'_rptLicIPBetting_12M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M08.ndf',
MOVE N'_rptLicIPBetting_12M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M09.ndf',
MOVE N'_rptLicIPBetting_12M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M10.ndf',
MOVE N'_rptLicIPBetting_12M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M11.ndf',
MOVE N'_rptLicIPBetting_12M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_12M12.ndf',
MOVE N'_rptLicIPBetting_13M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M01.ndf',
MOVE N'_rptLicIPBetting_13M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M02.ndf',
MOVE N'_rptLicIPBetting_13M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M03.ndf',
MOVE N'_rptLicIPBetting_13M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M04.ndf',
MOVE N'_rptLicIPBetting_13M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M05.ndf',
MOVE N'BATrans_BK_01' TO N'G:\IBC_DB\bodb_Licensee\BATrans_BK_01.ndf',
MOVE N'BATrans_BK_02' TO N'G:\IBC_DB\bodb_Licensee\BATrans_BK_02.ndf',
MOVE N'DW_transfer_DATA_01' TO N'G:\IBC_DB\bodb_Licensee\DW_transfer_DATA_01.ndf',
MOVE N'DW_transfer_DATA_02' TO N'G:\IBC_DB\bodb_Licensee\DW_transfer_DATA_02.ndf',
MOVE N'DW_transfer_DATA_03' TO N'G:\IBC_DB\bodb_Licensee\DW_transfer_DATA_03.ndf',
MOVE N'BA_Index_1' TO N'G:\IBC_DB\bodb_Licensee\BA\BA_Index_01.ndf',
MOVE N'licensee_index_2' TO N'G:\IBC_DB\bodb_licensee\licensee_index_02.ndf',
MOVE N'DW_KPI_DATA_01' TO N'G:\IBC_DB\bodb_Licensee\DW_KPI_DATA_01.ndf',
MOVE N'DW_staging_DATA_01' TO N'G:\IBC_DB\bodb_Licensee\DW_staging_DATA_01.ndf',
MOVE N'_rptLicIPBetting_13M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M06.ndf',
MOVE N'_rptLicIPBetting_13M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M07.ndf',
MOVE N'_rptLicIPBetting_13M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M08.ndf',
MOVE N'_rptLicIPBetting_13M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M09.ndf',
MOVE N'_rptLicIPBetting_13M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M10.ndf',
MOVE N'_rptLicIPBetting_13M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M11.ndf',
MOVE N'_rptLicIPBetting_13M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_13M12.ndf',
MOVE N'_rptLicIPBetting_MAX' TO N'G:\IBC_DB\bodb_Licensee\rptLicIPBetting\rptLicIPBetting_MAX.ndf',
MOVE N'_rptLicWL3_10M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M01.ndf',
MOVE N'_rptLicWL3_10M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M02.ndf',
MOVE N'_rptLicWL3_10M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M03.ndf',
MOVE N'_rptLicWL3_10M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M04.ndf',
MOVE N'_rptLicWL3_10M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M05.ndf',
MOVE N'_rptLicWL3_10M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M06.ndf',
MOVE N'_rptLicWL3_10M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M07.ndf',
MOVE N'_rptLicWL3_10M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M08.ndf',
MOVE N'_rptLicWL3_10M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M09.ndf',
MOVE N'_rptLicWL3_10M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M10.ndf',
MOVE N'_rptLicWL3_10M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M11.ndf',
MOVE N'_rptLicWL3_10M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_10M12.ndf',
MOVE N'_rptLicWL3_11M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M01.ndf',
MOVE N'_rptLicWL3_11M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M02.ndf',
MOVE N'_rptLicWL3_11M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M03.ndf',
MOVE N'_rptLicWL3_11M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M04.ndf',
MOVE N'_rptLicWL3_11M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M05.ndf',
MOVE N'_rptLicWL3_11M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M06.ndf',
MOVE N'_rptLicWL3_11M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M07.ndf',
MOVE N'_rptLicWL3_11M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M08.ndf',
MOVE N'_rptLicWL3_11M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M09.ndf',
MOVE N'_rptLicWL3_11M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M10.ndf',
MOVE N'_rptLicWL3_11M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M11.ndf',
MOVE N'_rptLicWL3_11M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_11M12.ndf',
MOVE N'_rptLicWL3_12M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M01.ndf',
MOVE N'_rptLicWL3_12M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M02.ndf',
MOVE N'_rptLicWL3_12M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M03.ndf',
MOVE N'_rptLicWL3_12M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M04.ndf',
MOVE N'_rptLicWL3_12M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M05.ndf',
MOVE N'_rptLicWL3_12M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M06.ndf',
MOVE N'_rptLicWL3_12M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M07.ndf',
MOVE N'_rptLicWL3_12M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M08.ndf',
MOVE N'_rptLicWL3_12M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M09.ndf',
MOVE N'_rptLicWL3_12M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M10.ndf',
MOVE N'_rptLicWL3_12M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M11.ndf',
MOVE N'_rptLicWL3_12M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_12M12.ndf',
MOVE N'_rptLicWL3_13M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M01.ndf',
MOVE N'_rptLicWL3_13M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M02.ndf',
MOVE N'_rptLicWL3_13M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M03.ndf',
MOVE N'_rptLicWL3_13M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M04.ndf',
MOVE N'_rptLicWL3_13M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M05.ndf',
MOVE N'_rptLicWL3_13M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M06.ndf',
MOVE N'_rptLicWL3_13M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M07.ndf',
MOVE N'_rptLicWL3_13M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M08.ndf',
MOVE N'_rptLicWL3_13M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M09.ndf',
MOVE N'_rptLicWL3_13M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M10.ndf',
MOVE N'_rptLicWL3_13M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M11.ndf',
MOVE N'_rptLicWL3_13M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_13M12.ndf',
MOVE N'_rptLicWL3_MAX' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL\rptLicWL3_MAX.ndf',
MOVE N'_rptBetting_09M01_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M01_DATA.ndf',
MOVE N'_rptBetting_09M02_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M02_DATA.ndf',
MOVE N'_rptBetting_09M03_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M03_DATA.ndf',
MOVE N'_rptBetting_09M04_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M04_DATA.ndf',
MOVE N'_rptBetting_09M05_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M05_DATA.ndf',
MOVE N'_rptBetting_09M06_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M06_DATA.ndf',
MOVE N'_rptBetting_09M07_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M07_DATA.ndf',
MOVE N'_rptBetting_09M08_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M08_DATA.ndf',
MOVE N'_rptBetting_09M09_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M09_DATA.ndf',
MOVE N'_rptBetting_09M10_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M10_DATA.ndf',
MOVE N'_rptBetting_09M11_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M11_DATA.ndf',
MOVE N'_rptBetting_09M12_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_09M12_DATA.ndf',
MOVE N'_rptBetting_10M01_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M01_DATA.ndf',
MOVE N'_rptBetting_10M02_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M02_DATA.ndf',
MOVE N'_rptBetting_10M03_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M03_DATA.ndf',
MOVE N'_rptBetting_10M04_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M04_DATA.ndf',
MOVE N'_rptBetting_10M05_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M05_DATA.ndf',
MOVE N'_rptBetting_10M06_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M06_DATA.ndf',
MOVE N'_rptBetting_10M07_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M07_DATA.ndf',
MOVE N'_rptBetting_10M08_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M08_DATA.ndf',
MOVE N'_rptBetting_10M09_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M09_DATA.ndf',
MOVE N'_rptBetting_10M10_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M10_DATA.ndf',
MOVE N'_rptBetting_10M11_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M11_DATA.ndf',
MOVE N'_rptBetting_10M12_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_10M12_DATA.ndf',
MOVE N'_rptBetting_11M01_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M01_DATA.ndf',
MOVE N'_rptBetting_11M02_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M02_DATA.ndf',
MOVE N'_rptBetting_11M03_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M03_DATA.ndf',
MOVE N'_rptBetting_11M04_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M04_DATA.ndf',
MOVE N'_rptBetting_11M05_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M05_DATA.ndf',
MOVE N'_rptBetting_11M06_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M06_DATA.ndf',
MOVE N'_rptBetting_11M07_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M07_DATA.ndf',
MOVE N'_rptBetting_11M08_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M08_DATA.ndf',
MOVE N'_rptBetting_11M09_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M09_DATA.ndf',
MOVE N'_rptBetting_11M10_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M10_DATA.ndf',
MOVE N'_rptBetting_11M11_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M11_DATA.ndf',
MOVE N'_rptBetting_11M12_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_11M12_DATA.ndf',
MOVE N'_rptBetting_12M01_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M01_DATA.ndf',
MOVE N'_rptBetting_12M02_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M02_DATA.ndf',
MOVE N'_rptBetting_12M03_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M03_DATA.ndf',
MOVE N'_rptBetting_12M04_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M04_DATA.ndf',
MOVE N'_rptBetting_12M05_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M05_DATA.ndf',
MOVE N'_rptBetting_12M06_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M06_DATA.ndf',
MOVE N'_rptBetting_12M07_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M07_DATA.ndf',
MOVE N'_rptBetting_12M08_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M08_DATA.ndf',
MOVE N'_rptBetting_12M09_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M09_DATA.ndf',
MOVE N'_rptBetting_12M10_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M10_DATA.ndf',
MOVE N'_rptBetting_12M11_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M11_DATA.ndf',
MOVE N'_rptBetting_12M12_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_12M12_DATA.ndf',
MOVE N'_rptBetting_13M01_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M01_DATA.ndf',
MOVE N'_rptBetting_13M02_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M02_DATA.ndf',
MOVE N'_rptBetting_13M03_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M03_DATA.ndf',
MOVE N'_rptBetting_13M04_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M04_DATA.ndf',
MOVE N'_rptBetting_13M05_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M05_DATA.ndf',
MOVE N'_rptBetting_13M06_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M06_DATA.ndf',
MOVE N'_rptBetting_13M07_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M07_DATA.ndf',
MOVE N'_rptBetting_13M08_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M08_DATA.ndf',
MOVE N'_rptBetting_13M09_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M09_DATA.ndf',
MOVE N'_rptBetting_13M10_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M10_DATA.ndf',
MOVE N'_rptBetting_13M11_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M11_DATA.ndf',
MOVE N'_rptBetting_13M12_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_13M12_DATA.ndf',
MOVE N'_rptBetting_Before09M01_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_Before09M01_DATA.ndf',
MOVE N'_rptBetting_MAX_DATA' TO N'G:\IBC_DB\bodb_Licensee\DW_rpt_Betting\rptBetting_MAX_DATA.ndf',
MOVE N'_rptLicWL_old_08M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M07.ndf',
MOVE N'_rptLicWL_old_08M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M08.ndf',
MOVE N'_rptLicWL_old_08M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M09.ndf',
MOVE N'_rptLicWL_old_08M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M10.ndf',
MOVE N'_rptLicWL_old_08M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M11.ndf',
MOVE N'_rptLicWL_old_08M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_08M12.ndf',
MOVE N'_rptLicWL_old_09M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M01.ndf',
MOVE N'_rptLicWL_old_09M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M02.ndf',
MOVE N'_rptLicWL_old_09M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M03.ndf',
MOVE N'_rptLicWL_old_09M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M04.ndf',
MOVE N'_rptLicWL_old_09M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M05.ndf',
MOVE N'_rptLicWL_old_09M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M06.ndf',
MOVE N'_rptLicWL_old_09M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M07.ndf',
MOVE N'_rptLicWL_old_09M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M08.ndf',
MOVE N'_rptLicWL_old_09M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M09.ndf',
MOVE N'_rptLicWL_old_09M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M10.ndf',
MOVE N'_rptLicWL_old_09M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M11.ndf',
MOVE N'_rptLicWL_old_09M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_09M12.ndf',
MOVE N'_rptLicWL_old_10M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M01.ndf',
MOVE N'_rptLicWL_old_10M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M02.ndf',
MOVE N'_rptLicWL_old_10M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M03.ndf',
MOVE N'_rptLicWL_old_10M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M04.ndf',
MOVE N'_rptLicWL_old_10M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M05.ndf',
MOVE N'_rptLicWL_old_10M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M06.ndf',
MOVE N'_rptLicWL_old_10M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M07.ndf',
MOVE N'_rptLicWL_old_10M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M08.ndf',
MOVE N'_rptLicWL_old_10M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M09.ndf',
MOVE N'_rptLicWL_old_10M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M10.ndf',
MOVE N'_rptLicWL_old_10M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M11.ndf',
MOVE N'_rptLicWL_old_10M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_10M12.ndf',
MOVE N'_rptLicWL_old_11M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M01.ndf',
MOVE N'_rptLicWL_old_11M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M02.ndf',
MOVE N'_rptLicWL_old_11M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M03.ndf',
MOVE N'_rptLicWL_old_11M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M04.ndf',
MOVE N'_rptLicWL_old_11M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M05.ndf',
MOVE N'_rptLicWL_old_11M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M06.ndf',
MOVE N'_rptLicWL_old_11M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M07.ndf',
MOVE N'_rptLicWL_old_11M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M08.ndf',
MOVE N'_rptLicWL_old_11M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M09.ndf',
MOVE N'_rptLicWL_old_11M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M10.ndf',
MOVE N'_rptLicWL_old_11M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M11.ndf',
MOVE N'_rptLicWL_old_11M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_11M12.ndf',
MOVE N'_rptLicWL_old_12M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M01.ndf',
MOVE N'_rptLicWL_old_12M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M02.ndf',
MOVE N'_rptLicWL_old_12M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M03.ndf',
MOVE N'_rptLicWL_old_12M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M04.ndf',
MOVE N'_rptLicWL_old_12M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M05.ndf',
MOVE N'_rptLicWL_old_12M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M06.ndf',
MOVE N'_rptLicWL_old_12M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M07.ndf',
MOVE N'_rptLicWL_old_12M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M08.ndf',
MOVE N'_rptLicWL_old_12M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M09.ndf',
MOVE N'_rptLicWL_old_12M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M10.ndf',
MOVE N'_rptLicWL_old_12M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M11.ndf',
MOVE N'_rptLicWL_old_12M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_12M12.ndf',
MOVE N'_rptLicWL_old_13M01' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M01.ndf',
MOVE N'_rptLicWL_old_13M02' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M02.ndf',
MOVE N'_rptLicWL_old_13M03' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M03.ndf',
MOVE N'_rptLicWL_old_13M04' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M04.ndf',
MOVE N'_rptLicWL_old_13M05' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M05.ndf',
MOVE N'_rptLicWL_old_13M06' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M06.ndf',
MOVE N'_rptLicWL_old_13M07' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M07.ndf',
MOVE N'_rptLicWL_old_13M08' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M08.ndf',
MOVE N'_rptLicWL_old_13M09' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M09.ndf',
MOVE N'_rptLicWL_old_13M10' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M10.ndf',
MOVE N'_rptLicWL_old_13M11' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M11.ndf',
MOVE N'_rptLicWL_old_13M12' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_13M12.ndf',
MOVE N'_rptLicWL_old_MAX' TO N'G:\IBC_DB\bodb_Licensee\rptLicWL_old\rptLicWL_old_MAX.ndf',
NORECOVERY,  NOUNLOAD,  STATS = 10
GO
---------
-- Restore differential
 NOUNLOAD,  STATS = 10
GO


sp_change_users_login 'update_one', bodb, bodb
 GO
sp_change_users_login 'update_one', bodbAdminNet, bodbAdminNet
 GO
sp_change_users_login 'update_one', bodbDownlineNet, bodbDownlineNet
 GO
sp_change_users_login 'update_one', bodbDownlineNetView, bodbDownlineNetView
 GO
sp_change_users_login 'update_one', bodbExAdminNet, bodbExAdminNet
 GO
sp_change_users_login 'update_one', bodbMemberNet, bodbMemberNet
 GO
sp_change_users_login 'update_one', bodbSuperNet, bodbSuperNet
 GO
sp_change_users_login 'update_one', bodbAdmin, bodbAdmin
 GO
sp_change_users_login 'update_one', bodbMember, bodbMember
 GO
sp_change_users_login 'update_one', Dot_Admin, Dot_Admin
 GO
sp_change_users_login 'update_one', Dot_Member, Dot_Member
 GO
sp_change_users_login 'update_one', Dot_Casino, Dot_Casino
 GO
sp_change_users_login 'update_one', Dot_P2P, Dot_P2P
 GO
sp_change_users_login 'update_one', dwrs, dwrs
 GO
sp_change_users_login 'update_one', dwrs1, dwrs1
 GO
 sp_change_users_login 'update_one', dwrs1, dwrs1
 GO
 -----
 
 select  u. name,
'sp_change_users_login ''update_one'', ' +CAST( u.name as varchar (20))+ ', '+CAST( u.name as varchar (20))+ ' ;GO'
        ,case when (r .principal_id is null) then 'public' else r .name end
        ,l. default_database_name
        ,u. default_schema_name
        ,u. principal_id
from sys .database_principals u
    left join (sys .database_role_members m join sys .database_principals r on m. role_principal_id = r .principal_id)
        on m. member_principal_id = u .principal_id
    left join sys. server_principals l on u.sid = l .sid
    where u. type <> 'R'


select 'EXEC sp_change_users_login ''update_one'',' + name + ',' + name
from sys.sysusers 
where issqlrole = 0 
and hasdbaccess = 1
and uid > 1 -- exclude dbo

 
