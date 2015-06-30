
ALTER PROCEDURE [dbo].[DBA_Rearrange_Partition] 
	@pf_name sysname,
	@ps_name sysname,
	@tablename sysname,
	@istest bit = 0
AS

DECLARE @LastDate datetime, @FirstDate datetime, @NextFG as sysname, @sql_cmd1 varchar(4000), @sql_cmd2 varchar(4000)

SET @LastDate = cast((select top 1 [value] from sys.partition_range_values (nolock)
       where function_id = (select function_id 
               from sys.partition_functions
               where name = @pf_name)
      order by boundary_id DESC) as datetime)
SET @LastDate = DATEADD(month, 1, @LastDate)

SET @FirstDate = cast((select top 1 [value] from sys.partition_range_values (nolock)
       where function_id = (select function_id 
               from sys.partition_functions
               where name = @pf_name)
      order by boundary_id ) as datetime)


--Get next FG and mark for next used.
SELECT top 1 @NextFG = fg.name
FROM (((sys.tables t (nolock)
   INNER JOIN sys.indexes i (nolock) ON (t.object_id = i.object_id))
   INNER JOIN sys.partition_schemes ps (nolock) ON (i.data_space_id = ps.data_space_id))
   INNER JOIN sys.destination_data_spaces dds (nolock) ON (ps.data_space_id = dds.partition_scheme_id))
   INNER JOIN sys.filegroups fg (nolock) ON dds.data_space_id = fg.data_space_id
WHERE (t.name = @tablename) AND (i.index_id IN (0,1)) 
AND dds.destination_id = 2

--Clean up
SELECT @sql_cmd2 = ''

SELECT @sql_cmd2 = @sql_cmd2 + 'DBCC SHRINKFILE (N''' + df.name + ''',0, TRUNCATEONLY);'
FROM (((sys.tables t (nolock)
   INNER JOIN sys.indexes i (nolock) ON (t.object_id = i.object_id))
   INNER JOIN sys.partition_schemes ps (nolock) ON (i.data_space_id = ps.data_space_id))
   INNER JOIN sys.destination_data_spaces dds (nolock) ON (ps.data_space_id = dds.partition_scheme_id))
   INNER JOIN sys.filegroups fg (nolock) ON dds.data_space_id = fg.data_space_id
   INNER JOIN sys.database_files df (nolock) on dds.data_space_id = df.data_space_id
WHERE (t.name = @tablename) AND (i.index_id IN (0,1)) 
AND dds.destination_id = 2

--Merge Old data
SELECT @sql_cmd1 = 'ALTER PARTITION FUNCTION ' + @pf_name + '() MERGE RANGE(''' + CAST(@FirstDate as varchar(50)) + ''')'
print @sql_cmd1
if(@istest = 0) 
	exec(@sql_cmd1)

--Clean up old filegroup
print 'GO'
print @sql_cmd2
if(@istest = 0) 
	exec(@sql_cmd2)


--Make the second partition for next use.
SELECT @sql_cmd1 = 'ALTER PARTITION SCHEME ' + @ps_name + ' NEXT USED ' + @NextFG
print 'GO'
print @sql_cmd1
if(@istest = 0) 
	EXEC(@sql_cmd1)


--Split new partition
SELECT @sql_cmd1 = 'ALTER PARTITION FUNCTION ' + @pf_name + '() SPLIT RANGE(''' + CAST(@LastDate as varchar(50)) + ''')'
print 'GO'
print @sql_cmd1
if(@istest = 0) 
	exec(@sql_cmd1)

--Clean up log file	
print 'go'
select @sql_cmd1= 'DBCC SHRINKDATABASE(bodb_CustomerLog)'
print @sql_cmd1
if(@istest = 0)
	exec(@sql_cmd1)
