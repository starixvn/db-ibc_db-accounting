 
ALTER DATABASE [bodb_customerLog]
ADD FILE ( NAME = N'bodb_CustSetting-01',
FILENAME = N'E:\IBC_DB\bodb_CustomerLog\bodb_CustSetting-01.ndf' , SIZE = 2048KB,
FILEGROWTH = 32MB ) TO FILEGROUP [CustSetting] 
GO

ALTER DATABASE [bodb_customerLog]
ADD FILE ( NAME = N'bodb_CustSetting-02',
FILENAME = N'E:\IBC_DB\bodb_CustomerLog\bodb_CustSetting-02.ndf' , SIZE = 2048KB,
FILEGROWTH = 32MB ) TO FILEGROUP [CustSetting] 
GO
ALTER DATABASE [bodb_customerLog]
ADD FILE ( NAME = N'bodb_CustSetting-03',
FILENAME = N'E:\IBC_DB\bodb_CustomerLog\bodb_CustSetting-03.ndf' , SIZE = 2048KB,
FILEGROWTH = 32MB ) TO FILEGROUP [CustSetting] 
GO
ALTER DATABASE [bodb_customerLog]
ADD FILE ( NAME = N'bodb_CustSetting-04',
FILENAME = N'E:\IBC_DB\bodb_CustomerLog\bodb_CustSetting-04.ndf' , SIZE = 2048KB,
FILEGROWTH = 32MB ) TO FILEGROUP [CustSetting] 
GO
--------

USE [master]
GO
ALTER DATABASE [bodb_CustomerLog] MODIFY FILE ( NAME = N'bodb_CustSetting-5', MAXSIZE = 2081MB )
GO

Name	Size-MB
bodb_CustSetting-1	797.1875
bodb_Custsetting-2	328.3125
bodb_Custsetting-3	335.375
bodb_Custsetting-4	2049
bodb_Custsetting-5	2081
----

DBCC SHRINKFILE (N'bodb_CustSetting-1' , EMPTYFILE) 
GO
DBCC SHRINKFILE (N'bodb_Custsetting-2' , EMPTYFILE) ;GO
DBCC SHRINKFILE (N'bodb_Custsetting-3' , EMPTYFILE) ;GO
DBCC SHRINKFILE (N'bodb_Custsetting-4' , EMPTYFILE) ;GO
DBCC SHRINKFILE (N'bodb_Custsetting-5' , EMPTYFILE) ;GO

ALTER DATABASE [bodb_CustomerLog]  REMOVE FILE [bodb_CustSetting-1]

---
DBCC SHRINKFILE (N'bodb_Custsetting-2' , 185) 
GO
DBCC SHRINKFILE (N'bodb_Custsetting-3' , 188) 
GO
DBCC SHRINKFILE (N'bodb_Custsetting-4' , 921) 
GO
DBCC SHRINKFILE (N'bodb_Custsetting-5' , 923) 
GO
-------

CREATE TABLE  #tmpspc (Fileid INT, FileGroup INT, TotalExtents INT, UsedExtents INT, Name sysname, FileName NCHAR(520))
INSERT #tmpspc EXEC ('dbcc showfilestats')

SELECT
    s.name AS [Name],
   
    s.physical_name AS [FileName],
    s.SIZE * CONVERT(FLOAT,8)/1024 AS [Size-MB],
    CAST(tspc.UsedExtents*CONVERT(FLOAT,64) AS FLOAT)/1024 AS [UsedSpace-MB],
    s.FILE_ID AS [ID], g.name AS [fileGroup], s.growth* CONVERT(FLOAT,8)/1024 AS [FileGrowth],
    s.SIZE * CONVERT(FLOAT,8)/1024 - CAST(tspc.UsedExtents*CONVERT(FLOAT,64) AS FLOAT)/1024 AS freeSpace,
    'ALTER DATABASE [bodb_Licensee] ADD FILE ( NAME = N'''
			+CAST(s.name AS VARCHAR(40))+''', FILENAME = N'''+replace(s.physical_name, 'G:\', 'E:\')+''' , SIZE = 1MB , FILEGROWTH = 32MB ) TO FILEGROUP ['+CAST(g.name AS VARCHAR(40))+'] ;GO',
    'DBCC SHRINKFILE (N'''+CAST(s.name AS VARCHAR(40))+''' , '
			+CAST(CAST((CAST(tspc.UsedExtents*CONVERT(FLOAT,64) AS FLOAT)/1024) AS INT) AS VARCHAR(20))+') ;GO',
    'ALTER DATABASE [bodb_Licensee] MODIFY FILE ( NAME = N'''
			+CAST(s.name AS VARCHAR(40))+''', MAXSIZE = '
			+cast(( cast((s.SIZE * CONVERT(FLOAT,8)/1024) as int)+1) as varchar(12))+'MB ) ;GO',
    'DBCC SHRINKFILE (N'''+CAST(s.name AS VARCHAR(40))+''' , EMPTYFILE) ;GO', 
    'ALTER DATABASE [bodb_Licensee]  REMOVE FILE ['+CAST(s.name AS VARCHAR(40))+'] ;GO'
FROM
    sys.filegroups AS g
    INNER JOIN sys.master_files AS s ON (s.type = 0 and s.database_id = DB_ID() and (s.drop_lsn IS NULL)) AND (s.data_space_id=g.data_space_id)
    INNER JOIN #tmpspc tspc ON tspc.Fileid = s.FILE_ID
WHERE
 (g.name like '%rptLicWL%' or g.name like '%Betting%')
 and g.name <> 'PRIMARY'
 and s.physical_name like 'G:\%'
ORDER BY 7, s.name ASC

DROP TABLE #tmpspc