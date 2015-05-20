/*
--00. Verify the setting/structure
--'custOverride', 'custOverride3rd', 'custSetting', 'CustSetting3rd', 'sum_winloss', 'sum_winloss_tmp'
--sum_winloss_tmp: DB02.bodb02 (already done)
--sum_winloss:
    + KBT: DB02, DB04, DB042, DB05, DB052, DB06, DBDW, DBDW2, DBTW
    + MNL: DB02PH, DB04, DB05, DB06
--custsetting/custoverride/custsetting3rd/custoverride3rd
    + KBT: DB02, DB05, DB052, DB06
    + MNL: DB02PH, DB05, DB06
*/

 SELECT so.name [TABLE Name], sc.name [COLUMN Name], st.name [DATA type], sc.length [Length], sc.prec [PRECISION],
    CASE WHEN pk.Constraint_name IS not null THEN 1 ELSE 0 END [PRIMARY KEY]
FROM sysobjects so
    INNER join syscolumns sc ON so.id = sc.id
    INNER join systypes st ON sc.xtype = st.xusertype   
    LEFT join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk ON so.name = pk.table_name and sc.name = pk.column_name
WHERE so.xtype = 'U'
    and (sc.name like '%bettype%' or sc.name like '%sporttype%' )
	and so.name in ( 'custOverride', 'custOverride3rd', 'custSetting', 'CustSetting3rd', 'sum_winloss', 'sum_winloss_tmp')

SELECT
    t.name AS tableName,ind.name, ind.index_id, ic.index_column_id, col.name
FROM
    sys.indexes ind
    INNER join sys.index_columns ic ON
        ind.OBJECT_ID = ic.OBJECT_ID and ind.index_id = ic.index_id
    INNER join   sys.columns col ON
        ic.OBJECT_ID = col.OBJECT_ID and ic.column_id = col.column_id
    INNER join sys.tables t ON
        ind.OBJECT_ID = t.OBJECT_ID
WHERE (col.name like '%bettype%' or col.name like '%sporttype%')
	and t.name in ( 'custOverride', 'custOverride3rd', 'custSetting', 'CustSetting3rd', 'sum_winloss', 'sum_winloss_tmp')

SELECT 
    t_obj.name                          AS TABLE_NAME
    ,c_obj.name                         AS CONSTRAINT_NAME
    ,col.name                           AS COLUMN_NAME

FROM    sysobjects      c_obj
    join    sysobjects      t_obj ON c_obj.parent_obj = t_obj.id 
    join    sysconstraints con ON c_obj.id  = con.constid
    join    syscolumns      col ON t_obj.id = col.id
                and con.colid = col.colid
WHERE
    c_obj.xtype = 'D'
    and (col.name like '%bettype%' or col.name like '%sporttype%')
	and t_obj.name  in ( 'custOverride', 'custOverride3rd', 'custSetting', 'CustSetting3rd', 'sum_winloss', 'sum_winloss_tmp')
 ---------
 
--01. sum_winloss_tmp table on DB02.bodb02 (already done)
ALTER TABLE dbo.sum_winloss_tmp
	DROP CONSTRAINT DF_sum_winloss_tmp_sporttype
GO
ALTER TABLE dbo.sum_winloss_tmp
	DROP CONSTRAINT DF_sum_winloss_tmp_bettype
GO
ALTER TABLE sum_winloss_tmp
ALTER COLUMN bettype SMALLINT NOT NULL

GO
ALTER TABLE sum_winloss_tmp
ALTER COLUMN sporttype SMALLINT NOT NULL


GO
ALTER TABLE dbo.sum_winloss_tmp ADD CONSTRAINT
	DF_sum_winloss_tmp_sporttype DEFAULT ((0)) FOR sporttype
GO
ALTER TABLE dbo.sum_winloss_tmp ADD CONSTRAINT
	DF_sum_winloss_tmp_bettype DEFAULT ((0)) FOR bettype
	
GO
--------------------
--2. sum_winloss table
--2.1 sum_winloss table: verify data
SELECT so.name [TABLE Name], sc.name [COLUMN Name], st.name [DATA type], sc.length [Length], sc.prec [PRECISION],
    CASE WHEN pk.Constraint_name IS not null THEN 1 ELSE 0 END [PRIMARY KEY]
FROM sysobjects so
    INNER join syscolumns sc ON so.id = sc.id
    INNER join systypes st ON sc.xtype = st.xusertype   
    LEFT join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk ON so.name = pk.table_name and sc.name = pk.column_name
WHERE so.xtype = 'U'
    and (sc.name like '%bettype%' or sc.name like '%sporttype%' or sc.name like '%keyid%' )
	and so.name in (  'sum_winloss')

SELECT
    t.name AS tableName,ind.name, ind.index_id, ic.index_column_id, col.name
FROM
    sys.indexes ind
    INNER join sys.index_columns ic ON
        ind.OBJECT_ID = ic.OBJECT_ID and ind.index_id = ic.index_id
    INNER join   sys.columns col ON
        ic.OBJECT_ID = col.OBJECT_ID and ic.column_id = col.column_id
    INNER join sys.tables t ON
        ind.OBJECT_ID = t.OBJECT_ID
WHERE (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t.name in (  'sum_winloss')

SELECT 
    t_obj.name                          AS TABLE_NAME
    ,c_obj.name                         AS CONSTRAINT_NAME
    ,col.name                           AS COLUMN_NAME

FROM    sysobjects      c_obj
    join    sysobjects      t_obj ON c_obj.parent_obj = t_obj.id 
    join    sysconstraints con ON c_obj.id  = con.constid
    join    syscolumns      col ON t_obj.id = col.id
                and con.colid = col.colid
WHERE
    c_obj.xtype = 'D'
    and (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t_obj.name  in (  'sum_winloss')
	
--3. custsetting table
--3.1 custsetting table: verify data
SELECT so.name [TABLE Name], sc.name [COLUMN Name], st.name [DATA type], sc.length [Length], sc.prec [PRECISION],
    CASE WHEN pk.Constraint_name IS not null THEN 1 ELSE 0 END [PRIMARY KEY]
FROM sysobjects so
    INNER join syscolumns sc ON so.id = sc.id
    INNER join systypes st ON sc.xtype = st.xusertype   
    LEFT join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk ON so.name = pk.table_name and sc.name = pk.column_name
WHERE so.xtype = 'U'
    and (sc.name like '%bettype%' or sc.name like '%sporttype%' or sc.name like '%keyid%' )
	and so.name in (  'custsetting')

SELECT
    t.name AS tableName,ind.name, ind.index_id, ic.index_column_id, col.name
FROM
    sys.indexes ind
    INNER join sys.index_columns ic ON
        ind.OBJECT_ID = ic.OBJECT_ID and ind.index_id = ic.index_id
    INNER join   sys.columns col ON
        ic.OBJECT_ID = col.OBJECT_ID and ic.column_id = col.column_id
    INNER join sys.tables t ON
        ind.OBJECT_ID = t.OBJECT_ID
WHERE (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t.name in (  'custsetting')

SELECT 
    t_obj.name                          AS TABLE_NAME
    ,c_obj.name                         AS CONSTRAINT_NAME
    ,col.name                           AS COLUMN_NAME

FROM    sysobjects      c_obj
    join    sysobjects      t_obj ON c_obj.parent_obj = t_obj.id 
    join    sysconstraints con ON c_obj.id  = con.constid
    join    syscolumns      col ON t_obj.id = col.id
                and con.colid = col.colid
WHERE
    c_obj.xtype = 'D'
    and (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t_obj.name  in (  'custsetting')
---------------
--4. custoverride table
--4.1 custoverride table: verify data
SELECT so.name [TABLE Name], sc.name [COLUMN Name], st.name [DATA type], sc.length [Length], sc.prec [PRECISION],
    CASE WHEN pk.Constraint_name IS not null THEN 1 ELSE 0 END [PRIMARY KEY]
FROM sysobjects so
    INNER join syscolumns sc ON so.id = sc.id
    INNER join systypes st ON sc.xtype = st.xusertype   
    LEFT join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk ON so.name = pk.table_name and sc.name = pk.column_name
WHERE so.xtype = 'U'
    and (sc.name like '%bettype%' or sc.name like '%sporttype%' or sc.name like '%keyid%' )
	and so.name in (  'custoverride')

SELECT
    t.name AS tableName,ind.name, ind.index_id, ic.index_column_id, col.name
FROM
    sys.indexes ind
    INNER join sys.index_columns ic ON
        ind.OBJECT_ID = ic.OBJECT_ID and ind.index_id = ic.index_id
    INNER join   sys.columns col ON
        ic.OBJECT_ID = col.OBJECT_ID and ic.column_id = col.column_id
    INNER join sys.tables t ON
        ind.OBJECT_ID = t.OBJECT_ID
WHERE (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t.name in (  'custoverride')

SELECT 
    t_obj.name                          AS TABLE_NAME
    ,c_obj.name                         AS CONSTRAINT_NAME
    ,col.name                           AS COLUMN_NAME

FROM    sysobjects      c_obj
    join    sysobjects      t_obj ON c_obj.parent_obj = t_obj.id 
    join    sysconstraints con ON c_obj.id  = con.constid
    join    syscolumns      col ON t_obj.id = col.id
                and con.colid = col.colid
WHERE
    c_obj.xtype = 'D'
    and (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t_obj.name  in (  'custoverride')
-----------
--5. custsetting3rd table
--5.1 custsetting3rd table: verify data
SELECT so.name [TABLE Name], sc.name [COLUMN Name], st.name [DATA type], sc.length [Length], sc.prec [PRECISION],
    CASE WHEN pk.Constraint_name IS not null THEN 1 ELSE 0 END [PRIMARY KEY]
FROM sysobjects so
    INNER join syscolumns sc ON so.id = sc.id
    INNER join systypes st ON sc.xtype = st.xusertype   
    LEFT join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk ON so.name = pk.table_name and sc.name = pk.column_name
WHERE so.xtype = 'U'
    and (sc.name like '%bettype%' or sc.name like '%sporttype%' or sc.name like '%keyid%' )
	and so.name in (  'custsetting3rd')

SELECT
    t.name AS tableName,ind.name, ind.index_id, ic.index_column_id, col.name
FROM
    sys.indexes ind
    INNER join sys.index_columns ic ON
        ind.OBJECT_ID = ic.OBJECT_ID and ind.index_id = ic.index_id
    INNER join   sys.columns col ON
        ic.OBJECT_ID = col.OBJECT_ID and ic.column_id = col.column_id
    INNER join sys.tables t ON
        ind.OBJECT_ID = t.OBJECT_ID
WHERE (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t.name in (  'custsetting3rd')

SELECT 
    t_obj.name                          AS TABLE_NAME
    ,c_obj.name                         AS CONSTRAINT_NAME
    ,col.name                           AS COLUMN_NAME

FROM    sysobjects      c_obj
    join    sysobjects      t_obj ON c_obj.parent_obj = t_obj.id 
    join    sysconstraints con ON c_obj.id  = con.constid
    join    syscolumns      col ON t_obj.id = col.id
                and con.colid = col.colid
WHERE
    c_obj.xtype = 'D'
    and (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t_obj.name  in (  'custsetting3rd')
------
--6. custoverride3rd table
--6.1 custoverride3rd table: verify data
SELECT so.name [TABLE Name], sc.name [COLUMN Name], st.name [DATA type], sc.length [Length], sc.prec [PRECISION],
    CASE WHEN pk.Constraint_name IS not null THEN 1 ELSE 0 END [PRIMARY KEY]
FROM sysobjects so
    INNER join syscolumns sc ON so.id = sc.id
    INNER join systypes st ON sc.xtype = st.xusertype   
    LEFT join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk ON so.name = pk.table_name and sc.name = pk.column_name
WHERE so.xtype = 'U'
    and (sc.name like '%bettype%' or sc.name like '%sporttype%' or sc.name like '%keyid%' )
	and so.name in (  'custoverride3rd')

SELECT
    t.name AS tableName,ind.name, ind.index_id, ic.index_column_id, col.name
FROM
    sys.indexes ind
    INNER join sys.index_columns ic ON
        ind.OBJECT_ID = ic.OBJECT_ID and ind.index_id = ic.index_id
    INNER join   sys.columns col ON
        ic.OBJECT_ID = col.OBJECT_ID and ic.column_id = col.column_id
    INNER join sys.tables t ON
        ind.OBJECT_ID = t.OBJECT_ID
WHERE (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t.name in (  'custoverride3rd')

SELECT 
    t_obj.name                          AS TABLE_NAME
    ,c_obj.name                         AS CONSTRAINT_NAME
    ,col.name                           AS COLUMN_NAME

FROM    sysobjects      c_obj
    join    sysobjects      t_obj ON c_obj.parent_obj = t_obj.id 
    join    sysconstraints con ON c_obj.id  = con.constid
    join    syscolumns      col ON t_obj.id = col.id
                and con.colid = col.colid
WHERE
    c_obj.xtype = 'D'
    and (col.name like '%bettype%' or col.name like '%sporttype%' or col.name like '%keyid%')
	and t_obj.name  in (  'custoverride3rd')
--------------------
--7. Others tables for DB05, DB052: verify data
SELECT so.name [TABLE Name], sc.name [COLUMN Name], st.name [DATA type], sc.length [Length], sc.prec [PRECISION],
    CASE WHEN pk.Constraint_name IS not null THEN 1 ELSE 0 END [PRIMARY KEY]
FROM sysobjects so
    INNER join syscolumns sc ON so.id = sc.id
    INNER join systypes st ON sc.xtype = st.xusertype   
    LEFT join INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk ON so.name = pk.table_name and sc.name = pk.column_name
WHERE so.xtype = 'U'
    and (sc.name like '%bettype%' )
	and so.name NOT in ( 'custOverride', 'custOverride3rd', 'custSetting', 'CustSetting3rd', 'sum_winloss', 'sum_winloss_tmp')
order by so.name

SELECT
    t.name AS tableName,ind.name, ind.index_id, ic.index_column_id, col.name
FROM
    sys.indexes ind
    INNER join sys.index_columns ic ON
        ind.OBJECT_ID = ic.OBJECT_ID and ind.index_id = ic.index_id
    INNER join   sys.columns col ON
        ic.OBJECT_ID = col.OBJECT_ID and ic.column_id = col.column_id
    INNER join sys.tables t ON
        ind.OBJECT_ID = t.OBJECT_ID
WHERE (col.name like '%bettype%')
	and t.name NOT in ( 'custOverride', 'custOverride3rd', 'custSetting', 'CustSetting3rd', 'sum_winloss', 'sum_winloss_tmp')
order by t.name,ind.name


SELECT 
    t_obj.name                          AS TABLE_NAME
    ,c_obj.name                         AS CONSTRAINT_NAME
    ,col.name                           AS COLUMN_NAME

FROM    sysobjects      c_obj
    join    sysobjects      t_obj ON c_obj.parent_obj = t_obj.id 
    join    sysconstraints con ON c_obj.id  = con.constid
    join    syscolumns      col ON t_obj.id = col.id
                and con.colid = col.colid
WHERE
    c_obj.xtype = 'D'
    and (col.name like '%bettype%')
	and t_obj.name NOT in ( 'custOverride', 'custOverride3rd', 'custSetting', 'CustSetting3rd', 'sum_winloss', 'sum_winloss_tmp')
order by t_obj.name
 ---------
--script to check the statistics
select OBJECT_NAME(sc.object_id) as TblName, c.name as ColumnName,
	sc.stats_column_id, s.name as StatName, s.*
from sys.stats_columns sc
	inner join sys.columns c on sc.column_id = c.column_id and sc.object_id = c.object_id
	inner join sys.stats s on s.stats_id = sc.stats_id and sc.object_id = s.object_id
	left outer join sys.indexes i on i.index_id = s.stats_id and i.object_id = s.object_id
where i.name is null
	and c.name like '%bettype%'
	and user_created = 1
order by 1, s.name