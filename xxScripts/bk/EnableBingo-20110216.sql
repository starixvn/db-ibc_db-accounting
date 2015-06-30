ALTER PROCEDURE [dbo].[Acc_ExecRep_09] 
	@custid int,
	@roleid int
AS

if NOT exists (select * from dbo.sysobjects where name = 'Custinfo') RETURN

IF @roleid = 4
BEGIN
	UPDATE dbo.custinfo with (rowlock, updlock)
	SET DisableBingo = 0, SyncBingo = 1
	WHERE custid = @custid

	UPDATE dbo.custinfo with (rowlock, updlock)
	SET DisableBingo = 0, SyncBingo = 1
	WHERE custinfo.mrecommend IN 
		(SELECT custid FROM dbo.custinfo 
		WHERE srecommend = @custid AND roleid = 3)
END
ELSE IF @roleid = 3
	UPDATE dbo.custinfo with (rowlock, updlock)
	SET DisableBingo = 0, SyncBingo = 1
	WHERE custinfo.mrecommend = @custid
GO

-----------------------------------------------------
-----------------------------------------------------

CREATE TABLE #list (custid int primary key, roleid int, cnt int, done bit)
create index done on #list (done)

insert into #list

SELECT srecommend, 4 roleid, count(*) cnt, 0
FROM Custinfo with(nolock)
WHERE srecommend in (
	select custid
	from Custinfo c with(nolock)
	where roleid=4 and custid > 100
		and custid not in (
			SELECT custid
			FROM customer WITH(NOLOCK)
			WHERE 
				roleid = 4
				AND
				(
					username LIKE '3rdSuper%'  
					OR username LIKE '12BETACCSuper%'
					OR username LIKE 'MS88ACCSuper%'
					OR username LIKE 'AB88ACCSuper%'
					OR username LIKE 'ALogACCSuper%'
					OR username LIKE 'DELAACCSuper%'
					OR username LIKE 'STEST%'  
					OR username like 'DELASuper%'
					OR username like 'TLCACCSuper%'
					OR username like 'MFACCSuper%'
					OR username like 'SCACCSuper%'

				)				
		)
		AND custid not in (1015419,1015427,791081,836212,1813575,836218,836226,1752415,836203,791080,916498,179457,3167631,932167,932188,932209,932253,1004374,932181,932063,925144,2564717,1574016,1574083,1573960,1573975,1574024,1574102,1574028,1574008,1574036,1573967,1573954,1574095,2397872,2397885,3287311,2308771,2308841,2308796,2308733,2747862,2747736,2747989,3114255,3289719,3289746,3417070,3293743,3293760,3229876,3319756,3319994,3320067,3233912,3544878,3544528,3578505,3544695,3544783,3543918,3544240,3544312,3544377,1505137,1505140,1539339,1667537,1731862,1889065,1935648,2063714,2063723,2426461,2426467,2426472,2571383,2877058,3002011,3002015,3043749,3043753,3318714,3318716,3370732,3379262,3379272,1317452,1698753,300958,636678,3397263,3397267,3397270,3581460,595565,1935623,1935638)
		AND CustID not in (835418,549191,706886,1575555,1584509,2078394, 753492,344472,1690560,1207541,1402421,523974,2518720,2214708,838365,914842,2034918,2772842,838215,324557,2285864,398615,398636,735044,840993,1923414,1374344,1574950,1768087,1865464)
	)
	AND recommend not in (2430074,1937408,3023,9636,2690,7984)
	AND mrecommend not in (3144218,11266,89436,15219,47030,506977,3144085,1068024,97430,523977)
group by srecommend

union 
--INSERT INTO @custid
select mrecommend, 3 roleid, count(*), 0 --CustID 
from custinfo with(nolock) 
where mrecommend in (
		select custid
		from Custinfo with(nolock)
		where roleid=3 and srecommend < 100		
	)  
	AND recommend not in (2430074,1937408,3023,9636,2690,7984)
	AND mrecommend not in (3144218,11266,89436,15219,47030,506977,3144085,1068024,97430,523977)
group by mrecommend

------------------------
declare @ncustid int, @nroleid int
declare @mcustid int, @mroleid int

select top 1 @ncustid = custid, @nroleid = roleid from #list where done = 0 ORDER BY cnt asc
select top 1 @mcustid = custid, @mroleid = roleid from #list where done = 0 ORDER BY cnt desc

exec [Acc_ExecRep_09] @ncustid, @nroleid
exec [Acc_ExecRep_09] @mcustid, @mroleid

update #list 
set done = 1
where custid in (@ncustid, @mcustid)

