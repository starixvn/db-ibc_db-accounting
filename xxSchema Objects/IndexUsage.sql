SELECT	o.name AS object_name, i.name AS index_name
   , i.type_desc, u.user_seeks, u.user_scans, u.user_lookups, u.user_updates

FROM	sys.indexes i
JOIN	sys.objects o
ON	i.object_id = o.object_id
LEFT JOIN	sys.dm_db_index_usage_stats u
ON	i.object_id = u.object_id
AND	i.index_id = u.index_id
AND	u.database_id = DB_ID()
WHERE	o.type <> 'S'		-- No system tables!
and o.name = 'bettrans'
ORDER BY	1,2,(ISNULL(u.user_seeks, 0) + ISNULL(u.user_scans, 0) + ISNULL(u.user_lookups, 0) 
   + ISNULL(u.user_updates, 0))--, o.name, i.name
