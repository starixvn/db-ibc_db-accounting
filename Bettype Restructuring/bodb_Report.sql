ALTER DATABASE [bodb_Report] ADD FILEGROUP [rptWinLost] 
 GO 
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'rptWinLost_01',
FILENAME = N'G:\IBC_DB\bodb_Report\bodb_Report_rptWinLost_01.ndf' ,
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [rptWinLost] 
 GO 
ALTER DATABASE [bodb_Report] ADD FILE ( NAME = N'rptWinLost_02',
FILENAME = N'G:\IBC_DB\bodb_Report\bodb_Report_rptWinLost_02.ndf' ,
SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP [rptWinLost] 
 GO 
