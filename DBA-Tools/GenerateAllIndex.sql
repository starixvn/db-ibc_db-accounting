/*

Script will generate create index scripts for all secondary indexes and all

tables in a database. This script only works with SQL Server 2005 and handles 

the included columns as well.

The output of the script is formatted.



Configuration Variables:



@OnlineIfPossibleSetting this to 1 will generate online index statements if it is 

supported for the edition you are using and if the datatype allows

it.

@MoveToFileGroupThis will allow you to specify a file group to store the secondary 

indexes. If the index is clustered it will use the original file group.

Set this value to null to use the original file group



@DropCreateSetting this to 1 will set the drop and recreate the index if it

exists.



@FillFactorOverride Setting this value will set the fill factor to the value you select.

Setting this value to null will use the original fill factor



Gary L. Fry

Senior DBA III

Colonial Life

gfry@coloniallife.com

shamandba@gmail.com

*/



SET NOCOUNT ON



--Loop Variables

DECLARE @TableCounter INT

DECLARE @TotalTables INT

DECLARE @IndexCounter INT

DECLARE @TotalIndexes INT

DECLARE @IndexColumnCounter INT

DECLARE @TotalColumns INT

--End Loop Variables



DECLARE @SchemaName VARCHAR(100)

DECLARE @TableName VARCHAR(100)

DECLARE @IndexId INT

DECLARE @IndexName VARCHAR(500)

DECLARE @IsClustered BIT

DECLARE @IsUnique BIT

DECLARE @ColumnName VARCHAR(100)

DECLARE @KeyOrdinal INT

DECLARE @IsDescending BIT

DECLARE @SQL NVARCHAR(MAX)

DECLARE @IncludedColumns VARCHAR(MAX)

DECLARE @FirstIncludedColumn BIT

DECLARE @FirstColumn BIT

DECLARE @OrigFillFactor TINYINT

DECLARE @OrigFileGroup VARCHAR(128)



--Configuration Variables

DECLARE @MoveToFileGroup VARCHAR(20)

DECLARE @DropCreate BIT

DECLARE @OnlineIfPossible BIT

DECLARE @PadIndex BIT

DECLARE @StatsNoRecompute BIT

DECLARE @SortInTempDB BIT

DECLARE @IgnoreDupKey BIT

DECLARE @AllowRowLocks BIT

DECLARE @AllowPageLocks BIT

DECLARE @FillFactorOverride TINYINT





--Set configuration variables here

SET @MoveToFileGroup = null

SET @DropCreate = 1

SET @OnlineIfPossible = 1

SET @PadIndex = 1

SET @StatsNoRecompute = 0

SET @SortInTempDB = 0

SET @IgnoreDupKey = 0

SET @AllowRowLocks = 1

SET @AllowPageLocks = 1

SET @FillFactorOverride = NULL





SET @TableCounter = 1



--In Memory Table Declarations

DECLARE @Tables TABLE
(
RowId INT IDENTITY(1,1),
SchemaName VARCHAR(100),
TableName VARCHAR(100)
)



--End In Memory Table Declarations



INSERT INTO @Tables

(

SchemaName,

TableName

)

SELECT 

ss.[Name],

so.[Name]

FROM sys.Objects so

INNER JOIN sys.schemas ss

ON ss.[schema_id] = so.[schema_id]

WHERE [Type] = 'U'

AND so.[object_id] NOT IN

(

SELECT tbl.[object_id]

FROM sys.tables tbl

WHERE EXISTS

(

SELECT Major_Id

FROM sys.extended_properties

WHERE Major_id = tbl.[object_id]

AND Minor_id = 0

AND class = 1

AND [name] = N'microsoft_database_tools_support'

)

)



SELECT @TotalTables = COUNT(*)

FROM @Tables



WHILE @TableCounter <= @TotalTables

BEGIN



SELECT 

@SchemaName = SchemaName,

@TableName = TableName

FROM @Tables

WHERE RowId = @TableCounter



--PRINT @TableName

--Get all secondary indexes for the table



--For the indexes we need to use a temp table due to needing to reseed the identity values

CREATE TABLE #TableIndexes

(

RowId INT IDENTITY(1,1),
IndexId INT,
IndexName VARCHAR(500),
IsClustered BIT,
IsUnique BIT,
OrigFillFactor TINYINT,
OrigFileGroup VARCHAR(128)
)



INSERT INTO #TableIndexes

(

IndexId,

IndexName,

IsClustered,

IsUnique,

OrigFillFactor,

OrigFileGroup

)

SELECT 

si.index_id,

si.name,

INDEXPROPERTY(si.Object_Id, si.[name], 'IsClustered'),

INDEXPROPERTY(si.Object_Id, si.[name], 'IsUnique'),

si.fill_factor,

sf.name AS OrigFileGroup 

FROM sys.indexes si WITH (NOLOCK)

INNER JOIN sys.Objects so WITH (NOLOCK) 

ON so.[Object_Id] = si.[Object_Id]

INNER JOIN sys.schemas sa WITH (NOLOCK)

ON sa.[schema_id] = so.[schema_id]

INNER JOIN sys.filegroups sf

ON sf.data_space_id = si.data_space_id

WHERE so.type = 'U'

AND si.index_id > 0 

AND si.index_id < 255 

AND INDEXPROPERTY(si.Object_Id, si.[name], 'IsStatistics') = 0

AND si.is_primary_key = 0

AND si.[object_id] = OBJECT_ID('[' + @SchemaName + '].[' + @TableName + ']')

ORDER BY Index_ID DESC



SET @IndexCounter = 1



SELECT @TotalIndexes = COUNT(*)

FROM #TableIndexes



WHILE @IndexCounter <= @TotalIndexes

BEGIN



SELECT

@IndexId = IndexId,

@IndexName = IndexName,

@IsClustered = IsClustered,

@IsUnique = IsUnique,

@OrigFillFactor = OrigFillFactor,

@OrigFileGroup = OrigFileGroup

FROM #TableIndexes

WHERE RowId = @IndexCounter



SET @SQL = 'CREATE '



IF @IsUnique = 1

BEGIN

SET @SQL = @SQL + 'UNIQUE '

END



IF @IsClustered = 1

BEGIN

SET @SQL = @SQL + 'CLUSTERED '

END



SET @SQL = @SQL + 'INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + ']'

SET @SQL = @SQL + CHAR(13)

SET @SQL = @SQL + '('

SET @SQL = @SQL + CHAR(13)





CREATE TABLE #IndexColumns

(

RowId INT IDENTITY(1,1),

ColumnName VARCHAR(100),

KeyOrdinal INT,

IsDescending INT

)



INSERT INTO #IndexColumns

(

ColumnName,

KeyOrdinal,

IsDescending

)

SELECT

sc.name,

ic.Key_Ordinal,

ic.Is_Descending_Key

FROM sys.index_columns ic 

INNER JOIN sys.columns sc

ON ic.object_id = sc.object_id

AND ic.column_id = sc.column_id

WHERE ic.[object_id] = OBJECT_ID('[' + @SchemaName + '].[' + @TableName + ']')

AND ic.Index_Id = @IndexId

ORDER BY ic.Key_Ordinal



SET @IndexColumnCounter = 1



SELECT @TotalColumns = COUNT(*)

FROM #IndexColumns



SET @FirstIncludedColumn = 1

SET @FirstColumn = 1

SET @IncludedColumns = ''



WHILE @IndexColumnCounter <= @TotalColumns

BEGIN



SELECT 

@ColumnName = ColumnName,

@KeyOrdinal= KeyOrdinal,

@IsDescending = IsDescending

FROM #IndexColumns

WHERE RowId = @IndexColumnCounter







IF @KeyOrdinal = 0

BEGIN

IF @FirstIncludedColumn = 1

BEGIN

SET @FirstIncludedColumn = 0

END

ELSE

BEGIN

SET @IncludedColumns = @IncludedColumns + ', ' + CHAR(13)

END



SET @IncludedColumns = @IncludedColumns + CHAR(9) + '[' + @ColumnName + ']'

END

ELSE

BEGIN

IF @FirstColumn = 1

BEGIN

SET @FirstColumn = 0

END

ELSE

BEGIN

SET @SQL = @SQL + ', ' + CHAR(13)

END



SET @SQL = @SQL + CHAR(9) + '[' + @ColumnName + ']'



IF @IsDescending = 1

BEGIN

SET @SQL = @SQL + ' DESC'

END

ELSE

BEGIN

SET @SQL = @SQL + ' ASC'

END





END



SET @IndexColumnCounter = @IndexColumnCounter + 1

END --End Index Column Loop



SET @SQL = @SQL + CHAR(13) + ')' + CHAR(13)



IF LEN(@IncludedColumns) <> 0

BEGIN



SET @SQL = @SQL + 'INCLUDE' + CHAR(13) + '(' + CHAR(13) + @IncludedColumns + CHAR(13) + ')' + CHAR(13)



END



SET @SQL = @SQL + 'WITH'

SET @SQL = @SQL + CHAR(13)

SET @SQL = @SQL + '('



IF @PadIndex = 1

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'PAD_INDEX = ON, '

END

ELSE

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'PAD_INDEX = OFF, '

END



IF @StatsNoRecompute = 1

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'STATISTICS_NORECOMPUTE = ON'

END

ELSE

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'STATISTICS_NORECOMPUTE = OFF, '

END



IF @SortInTempDB = 1

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'SORT_IN_TEMPDB = ON, '

END

ELSE

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'SORT_IN_TEMPDB = OFF, '

END



IF @IgnoreDupKey = 1

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'IGNORE_DUP_KEY = ON, '

END

ELSE

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'IGNORE_DUP_KEY = OFF, '

END



IF @DropCreate = 1

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'DROP_EXISTING = ON, '

END

ELSE

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'DROP_EXISTING = OFF, '

END



IF @OnlineIfPossible = 1 

AND

(

SELECT COUNT(*) 

FROM sys.columns sc WITH (NOLOCK)

WHERE sc.OBJECT_ID = OBJECT_ID('[' + @SchemaName + '].[' + @TableName + ']')

AND sc.system_type_id IN (34,35,99,241)

) = 0

AND

(

CAST(SERVERPROPERTY ('Edition') AS VARCHAR(50)) LIKE 'Enterprise%'

OR

CAST(SERVERPROPERTY ('Edition') AS VARCHAR(50)) LIKE 'Developer%'

)

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'ONLINE = ON, '

END

ELSE

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'ONLINE = OFF, '

END



IF @AllowRowLocks = 1

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'ALLOW_ROW_LOCKS = ON, '

END

ELSE

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'ALLOW_ROW_LOCKS = OFF, '

END



IF @AllowPageLocks = 1

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'ALLOW_PAGE_LOCKS = ON '

END

ELSE

BEGIN

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'ALLOW_PAGE_LOCKS = OFF '

END



IF @FillFactorOverride IS NOT NULL

BEGIN

SET @SQL = @SQL + ','

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'FILLFACTOR = ' + CAST(@FillFactorOverride AS VARCHAR(3))

END

ELSE

BEGIN

IF @OrigFillFactor > 0

BEGIN

SET @SQL = @SQL + ','

SET @SQL = @SQL + CHAR(13) + CHAR(9) + 'FILLFACTOR = ' + CAST(@OrigFillFactor AS VARCHAR(3))

END

END

SET @SQL = @SQL + CHAR(13)

SET @SQL = @SQL + ')'

SET @SQL = @SQL + CHAR(13)





IF @IsClustered = 1

BEGIN

SET @SQL = @SQL + 'ON [' + @OrigFileGroup + '];' + CHAR(13) 

END

ELSE

BEGIN

IF @MoveToFileGroup IS NULL

BEGIN

SET @SQL = @SQL + 'ON [' + @OrigFileGroup + '];' + CHAR(13)

END

ELSE 

BEGIN

SET @SQL = @SQL + 'ON [' + @MoveToFileGroup + '];' + CHAR(13)

END 

END





DROP TABLE #IndexColumns


PRINT 'GO'
PRINT @SQL



SET @IndexCounter = @IndexCounter + 1



END

--End Get all secondary indexes for table



DROP TABLE #TableIndexes



SET @TableCounter = @TableCounter + 1

END--End Table Loop
