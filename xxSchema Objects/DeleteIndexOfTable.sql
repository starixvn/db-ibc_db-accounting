DECLARE @indexName NVARCHAR(128)
DECLARE @dropIndexSql NVARCHAR(4000)
declare @tablename nvarchar(4000), @_tablename varchar(50)
select @tablename = 'Customer,custSub,custinfo,bettrans14,match,bettransm14,match14,odds14,bettrans,odds,bettransm,sum_winloss,zzzbettrans,exchange,Site,team'
DECLARE tables CURSOR FOR
select val from strSplit(@tablename,',')

OPEN tables
FETCH NEXT FROM tables INTO @_tablename
WHILE @@fetch_status = 0
BEGIN
	DECLARE tableIndexes CURSOR FOR
	SELECT name FROM sysindexes
	WHERE id = OBJECT_ID(@_tablename) AND
	  indid > 0 AND indid < 255 AND
	  INDEXPROPERTY(id, name, 'IsStatistics') = 0
	ORDER BY indid DESC

	OPEN tableIndexes
	FETCH NEXT FROM tableIndexes INTO @indexName
	WHILE @@fetch_status = 0
	BEGIN
	  SET @dropIndexSql = N'DROP INDEX '+ @_tablename + '.' + @indexName
	  begin try 
		EXEC sp_executesql @dropIndexSql
	  end try
	  begin catch 
	    print ERROR_MESSAGE() 
      end catch
	  print @dropIndexSql
	  FETCH NEXT FROM tableIndexes INTO @indexName
	END
	CLOSE tableIndexes
	DEALLOCATE tableIndexes
FETCH NEXT FROM tables INTO @_tablename

END

CLOSE tables
DEALLOCATE tables
