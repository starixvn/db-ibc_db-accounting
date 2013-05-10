ALTER PROCEDURE [dbo].[Acc_Set_MatchSel_2]
	@FromDate datetime,
	@ToDate datetime,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@UncalOnly bit = 0,	
	@UncalMultiOnly bit = 0,
	@sporttype tinyint = 0
AS

/*	Creator: Thien Pham
	Date: 2008
	Task: Results for calculating 
	DB: DB02.bodb02
	
	History:
		- 20090116@VinhTruong: Add filter for sporttype 
		- 20090206@PhuongNguyen: Get GoalRecord from Match table
		- 20090114@PhuongDao: Add Horse Racing results
		- 20090301@ThienPham: Fix the display of Horse Racing section
		- 20090311@PhuongDao: Show Horse Racing for calculating 
		- 20110907@Sophia: Add column IsHTCal, calculate
	
*/
SET NOCOUNT ON

select hthomescore,htawayscore, isnull(mr.calculate,0) IsCalculated, isnull(mr.multiple,0) IsMultiCaled,
	isnull(mr.refund,0) IsRefund, isnull(mr.calrefund,0) IsCalRefund,
	match.matchid, match.leagueid , 
	match.homeid, match.awayid,
	match.matchcode, match.kickofftime,
	match.finalhomescore,
    match.finalawayscore, match.betstatus,
	case	when match.betstatus like 'Refund FT%' then 'Refund FT'
			when match.betstatus like 'Refund%' then 'Refund'
			else match.eventstatus
	end as eventstatus,  
	match.sporttype,
	mr.ishtcal,
	isnull(match.isNeutral, CONVERT(BIT,0)) as IsNeutral,
	match.eventdate,
	match.goalrecord, --Phuong.Nguyen	
	ISNULL(mr.IsHTCal,0) as IsHTCal,
	ISNULL(mr.calculate,0) as calculate	
from match with (nolock)
	left outer join match_remark mr with (nolock) on match.matchid = mr.matchid
where match.eventdate between @FromDate and @ToDate
	and match.leagueID = case when @LeagueID <> 0 then @LeagueID else match.leagueID end
	and (@UncalOnly = 0 or isnull(mr.calculate,0) = 0)
	and (@UncalMultiOnly = 0 or isnull(mr.multiple,0) = 0)
	and match.sporttype = case when @sporttype = 0 then match.sporttype else @sporttype end

-- PhuongDao@20090114

UNION ALL
SELECT	o.IsFavor hthomescore,  --TF
		o.IsSCR   htawayscore,  --SCR
		0  IsCalculated, 
		0  IsMultiCaled,  
		0  IsRefund, 
		0  IsCalRefund,
		o.groupmatch  as matchid, --Race 
		o.leagueid , 
		o.teamid homeid, 0 awayid,
		o.matchcode,   --Horse 
		o.kickofftime,
		o.odds finalhomescore,
		o.placeodds finalawayscore, 
		case when o.placing = 0 then '5' else isnull(convert(varchar(2),placing) ,5) end betstatus, --Placing
		o.oddsstatus eventstatus, 
		151 sporttype,
		0 ishtcal, 0 IsNeutral,
		o.eventdate,
		'' as goalrecord, --Phuong.Nguyen 
		0 as IsHTCal,
		0 as calculate	
FROM	outright o with (nolock)
		INNER JOIN league l with (nolock)on  o.leagueid = l.leagueid 
WHERE	o.eventdate BETWEEN @FromDate AND @ToDate 
		and l.sporttype = case when @sporttype = 0 OR @sporttype = 151 then 151 else 0 end  
		and o.leagueid = case when @leagueid =0 then o.leagueid 
							 else @leagueid end 
		--	and o.oddsstatus ='completed' 

order by eventdate, eventstatus, sporttype, leagueid, matchid, betstatus, matchcode
GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSel_2] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_MatchSel_2] TO [VNTeam]