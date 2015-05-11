--BEGIN
create table #matchset2
(	matchid int,
	ResultID char(2),
	Result nvarchar(50),
	homevalue varchar(20),
	awayvalue varchar(20) )

create table #matchset1
(	matchid int,
	betstatus nvarchar(50),
	flag bit )

DECLARE @EVENTDATE datetime

SET @EVENTDATE = '2013-10-31 00:00:00.000'

IF @EVENTDATE IS NULL SET @EVENTDATE = convert(char(8),getdate ()-1,112)

INSERT INTO #matchset1
SELECT matchid,betstatus,0 as flag 
FROM Match_BK with(nolock)
WHERE sporttype = 5 and eventstatus = 'completed' and ( betstatus not like '%refund%' AND betstatus <> '')
	 and matchid not in ( SELECT matchid from ResultDetail_BK with(nolock)  )
	 and eventdate = @EVENTDATE

DECLARE	@cnt int,
		@matchid int,
		@betstsatus nvarchar(50)

SELECT @cnt = count(*) from #matchset1

While @cnt > 0
BEGIN
	SELECT top 1 @matchid = matchid ,   @betstsatus = betstatus
	FROM #matchset1
	WHERE flag = 0 

	INSERT INTO #matchset2
	SELECT @matchid,'0'+cast([rank] as char(1)),
		val,SUBSTRING(val,1,charindex('-',val)-1),
			SUBSTRING(val,charindex('-',val)+1,len(val)-charindex('-',val))
	FROM [dbo].[strSplit] ( @betstsatus ,',' )
	WHERE val <> '0-0'

	UPDATE #matchset1 SET flag = 1 WHERE matchid = @matchid
	SET @cnt = @cnt -1
END

--INSERT Full Event Final score
INSERT #matchset2
SELECT matchid,'00','00',sum(case when homevalue > awayvalue then 1 else 0 end),
					sum(case when homevalue < awayvalue then 1 else 0 end)	
FROM #matchset2
GROUP BY matchid

/*
INSERT Completed Event data
ResultStatusID : 5 = manually settled
SettlementStatusID : 4 = Completed 
*/
INSERT INTO ResultDetail_BK ( MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate )
SELECT m.matchid,tmp.ResultID,tmp.homevalue,tmp.awayvalue,5,4,m.creator,eventDate,creator,eventDate ----settletime 
FROM #matchset2 tmp inner join Match_BK m with(nolock)
	on tmp.matchid = m.matchid
/*
INSERT REFUND Event data
ResultStatusID : 5 = manually settled
SettlementStatusID : 1 = Refund 
*/
INSERT INTO ResultDetail_BK ( MatchID, ResourceID, HomeValue, AwayValue, ResultStatusID, SettlementStatusID, CreateBy, CreateDate, LastModifyBy, LastModifyDate )
SELECT matchid,'00','0','0',5,1,creator,eventDate,creator,eventDate 
FROM Match_BK with(nolock)
WHERE sporttype = 5 and eventstatus = 'completed' and betstatus like '%Refund%'
		and matchid not in ( SELECT matchid from ResultDetail_BK with(nolock)  )
		and eventdate = @EVENTDATE
--END

/*
select MAX(eventdate) from Match_BK nolock

select * from #matchset2
select * from #matchset1

update #matchset1 SET flag = 0
truncate table #matchset2


drop table #matchset2
drop table #matchset1
*/




drop table #matchset2
drop table #matchset1