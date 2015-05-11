 /*The script to CHECK the list need to update Max PT, Min PT*/
/***********ETUS (YEN)**********/
--create table #SuperIDs (custid int)
--insert into #SuperIDs
--select custid from custinfo with (nolock) where username in ('ea','ea5','eal','eb','eb5','eb6','eba','ebl','ec','ee','ef','eg','eh','ei','ej','eja','ek','el','em','en','eo','ep','eq','er','es','et','et9','eu','ev','ew','ex','ey','sc','sg','sh','sm','sq','ssa','ssb','ssc','sse','xa','xb','xc','xd','xe','xf','xg','xh','xj','xk','xl','xm','xn','xo','xp','xq','xr','xs','xt','xx','xxa','xxb','xxc','xxd','xxe','xxf','xxg','xxh','xxt','xy','xz')
--
----34 account need to update Max
--select * from custsettinggame cg with (nolock)
--inner join custoverridegame co with (nolock) on cg.custid=co.custid
--where cg.custid in (select custid from #SuperIDs)
--and (co.minpositiontaking=0)
--
---- 38 accounts need to update MIN PT & Max PT 
--select cg.spositiontaking,co.minpositiontaking,* from custsettinggame cg with (nolock)
--inner join custoverridegame co with (nolock) on cg.custid=co.custid
--where cg.custid in (select custid from #SuperIDs)
--and (cg.spositiontaking <> 0 and co.minpositiontaking<>0)
/***********ETUS (YEN)**********/

/***********************************/

-- TO UPDATE
DECLARE @SuperTable TABLE (custid INT)

INSERT INTO @SuperTable
SELECT c.custid
FROM Customer c WITH(NOLOCK)
	INNER JOIN CustSettingGame cg WITH(NOLOCK) ON c.custid = cg.custid
WHERE roleid = 4 and 
username IN ('ea','ea5','eal','eb','eb5','eb6','eba','ebl','ec','ee','ef','eg','eh','ei','ej','eja','ek','el','em','en','eo','ep','eq','er','es','et','et9','eu','ev','ew','ex','ey','sc','sg','sh','sm','sq','ssa','ssb','ssc','sse','xa','xb','xc','xd','xe','xf','xg','xh','xj','xk','xl','xm','xn','xo','xp','xq','xr','xs','xt','xx','xxa','xxb','xxc','xxd','xxe','xxf','xxg','xxh','xxt','xy','xz')
AND cg.spositiontaking <> 0.9


-- 72 rows affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.9
WHERE custid IN (SELECT custid FROM @SuperTable)