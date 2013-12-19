ALTER PROCEDURE [dbo].[Acc_BettransSelSpecialDel]
	@MatchID int,
	@FromRefNo bigint,
	@ToRefNo bigint,	
	@hdp smallmoney = 9999,
	@liveindicator int = 0,
	@livehomescore smallint = NULL,
    @liveawayscore smallint = NULL,
	@FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@bettypes varchar(128) = '',	
	@betteam1378 varchar(10) = 'ALL',
	@betteam515 varchar(10) = 'ALL',
	@betteam430 varchar(120) = '',
	@betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
	@UserName varchar(50) = '',
    @SAFilter tinyint = 0 	
AS
BEGIN
/*
    Created by: Daniel
	Date: 
	Original: account\dele\teamlisting.asp
	Task: Select bets transaction need to delete
	DB: DBAGE/BODB02

	History:
		- ADMIN SITE
		
		- 20060225@: remove refno
		- 20091206@Hiep: divide to 4 datasets (1 normal and 3 special bets for optional delete)
		- 20090517@Khoa: Allow user to select multiple bet types
		- 20090729@Khoa: Only steven OR JOE can delete bet of "complete" match
		- 20090925@khoa: Deleted option for member belong to master  MHCRM, MHCEU, MHCUS
		- 20091006@Simon: Get Odds && OddsType columns.
		- 20091007@Khoa: Add more condition to search live or Dead ball for bettype 2 & 12
		- 20091019@Daniel: Revert changed made by 20091006@Simon
		- 20091127@Khoa: Suport more option search with Correct Score and remove table exchange
		-- 20100526@Henry: Change to use StatusID instead of Status in WHERE statement
		-- 20100917@Robert: include betfrom='e' into deposit group
		-- 20101001@Henry: Using f_GetBetDaqCustomer to query betdaq customer
		- 20101222@Johnson: change the length of parameter bettype
		- 20110408@Amy: Change function to get Odds value and odds type
		- 20110523@Amy: Re-arrange bettype
		- 20110817@Elly: add bettype =6,14,16
		- 20110922@Tom: Add new bettypes 30, apply new bet type 1st correct score on Sport Books
				Replace parameter input @betteam4 => @betteam430
		- 20111110@Sophia: Add new parametter @livehomescore, @liveawayscore, @transdate to filter by livehomescore and liveawayscore
		- 20111122@Sophia: Add Checktime and SecAcceptFlag to show status waiting or running
	    - 20120210@Daniel: Add filter param to list out SA (secondAccept) tickets:
		- 20120309@Sophia: Change param @transdate to @FromTransdate and @ToTransdate
		- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype, f_GetChoice for odds, Oddstype, betteam
		- 20120711@Sophia: Add condition 'L' in betfrom to check Deposit
		- 20130604@Johnson: change to use stake instead stakepositiontaking
		- 20131210@Kathy: Using Dep_CustSuper table to find deposit ticket instead of betfrom in ('D', 'M', 'E', 'L') [Redmine:#9321]
	Explanation's Param:
	    - @SAFilter: 
	      + 0: All tickets
          + 1: Normal tickets only
	      + 2: SA tickets only
     
		-	@liveindicator:
		 + 0: Dead
		 + 1: Live
		 + 2: All


*/
	SET NOCOUNT ON
	CREATE TABLE #SpecialDeleteBets (transid bigint,custid int,username varchar(30),odds smallmoney, OddsType int, transdate datetime,bettype smallint, betteam nvarchar(10),hdp1 smallmoney, hdp2 smallmoney,livehomescore smallint, liveawayscore smallint,creator varchar(30),Stake money,currency tinyint,IsDeposit tinyint,site varchar(10),status nvarchar(10), mrecommend int, recommend int, SecAcceptFlag bit)

	IF exists( SELECT convert(int,val) FROM dbo.strSplit(@bettypes,'^') Where convert(int,val) in (4,30) )
		insert into #SpecialDeleteBets
		select
			b.transid,
			b.custid,
			b.username,
			b.odds,   
			b.OddsType,  
			b.transdate,
			b.bettype,
			betteam,
			hdp1,
			hdp2,
			livehomescore,
			liveawayscore,
			cr.username as creator,	
			stake,
			b.currency, 
			--case when betfrom IN ('D', 'M', 'E', 'L') then 1 else 0 end as IsDeposit,
			case WHEN b.srecommend IN (SELECT Dep_CustSuper.custid FROM Dep_CustSuper with(NOLOCK)) then 1 ELSE 0 end as IsDeposit,
			ag.site,
			CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE b.status 
				 END as status,
			b.mrecommend,
			b.recommend,
			ISNULL(SecAcceptFlag,0) SecAcceptFlag
		from 
			bettrans b with (NOLOCK)
			INNER JOIN customer ag with (NOLOCK) ON b.recommend = ag.custid
			INNER JOIN customer cr with (NOLOCK) ON cr.custid = b.creator
		where
			matchid=@matchid 
			and b.transid between @FromRefNo and @ToRefNo 	
			AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
			AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
			AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
			AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
							AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
			and b.bettype in ( SELECT convert(int,val) FROM dbo.strSplit(@bettypes,'^') )
			and statusID NOT IN (101,102 )
			and b.bettype in (4,30)
			and b.betteam in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam430 = 'All' then betteam else @betteam430 end,'^'))
    		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
			


	insert into #SpecialDeleteBets
	select
		b.transid,
		b.custid,
		b.username,
		b.odds,   
		b.OddsType,  
		b.transdate,
		b.bettype,
		betteam,
		hdp1,
		hdp2,
		livehomescore,
		liveawayscore,
		cr.username as creator,	
		stake,
		b.currency, 
		--case when betfrom IN ('D', 'M', 'E' ,'L') then 1 else 0 end as IsDeposit,
		case WHEN b.srecommend IN (SELECT Dep_CustSuper.custid FROM Dep_CustSuper with(NOLOCK)) then 1 ELSE 0 end as IsDeposit,
		ag.site,
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,
		b.mrecommend,
		b.recommend,
		ISNULL(SecAcceptFlag,0) SecAcceptFlag
	from 
		bettrans b with (NOLOCK)
		--INNER JOIN customer  with (NOLOCK) ON customer.custid=b.custid
		INNER JOIN customer ag with (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN customer cr with (NOLOCK) ON cr.custid = b.creator
	where
		matchid=@matchid 
		and b.transid between @FromRefNo and @ToRefNo 	
		and b.bettype in ( SELECT convert(int,val) FROM dbo.strSplit(@bettypes,'^') )
		--and status NOT IN ('Void', 'Reject')
		and statusID NOT IN (101,102)

		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		AND CASE
			WHEN b.bettype in (1,3,7,8,2,12) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
			WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END		
			ELSE betteam 
			END = betteam		
		AND CASE WHEN b.bettype in (1,3,7,8) THEN CASE 
													WHEN @hdp = 9999 THEN 1
													WHEN @hdp = (hdp1 + hdp2) THEN 1
													ELSE 0 
											 END
			ELSE 1 END = 1
		AND b.bettype NOT IN(4,6,14,16,30)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END

	UNION ALL

	select
		b.transid,
		b.custid,
		b.username,
		b.odds,   
		b.OddsType,  
		b.transdate,
		b.bettype,
		betteam,
		hdp1,
		hdp2,
		livehomescore,
		liveawayscore,
		cr.username as creator,	
		stake,
		b.currency, 
		--case when betfrom IN ('D', 'M', 'E', 'L') then 1 else 0 end as IsDeposit,
		case WHEN b.srecommend IN (SELECT Dep_CustSuper.custid FROM Dep_CustSuper with(NOLOCK)) then 1 ELSE 0 end as IsDeposit,
		ag.site,
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,
		b.mrecommend,
		b.recommend,
		ISNULL(SecAcceptFlag,0) SecAcceptFlag		
	from 
		dbo.bettrans b with (NOLOCK)
		--INNER JOIN customer  with (NOLOCK) ON customer.custid=b.custid
		INNER JOIN dbo.customer ag with (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN dbo.customer cr with (NOLOCK) ON cr.custid = b.creator
	where
		matchid=@matchid 
		and b.transid between @FromRefNo and @ToRefNo 			 
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		--and status NOT IN ('Void', 'Reject')
		and statusID NOT IN (101,102)		
		--Begin Elly add	
		AND(
			(b.bettype = 6 
			AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam6 = 'All' then betteam else @betteam6 end,'^'))  
			)			
			OR
			(b.bettype = 16
			AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam16 = 'All' then betteam else @betteam16 end,'^'))  
			)
		)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	
	UNION ALL 
	
	select
		b.transid,
		b.custid,
		b.username,
		b.odds,   
		b.OddsType,  
		b.transdate,
		b.bettype,
		betteam,
		hdp1,
		hdp2,
		livehomescore,
		liveawayscore,
		cr.username as creator,	
		stake,
		b.currency, 
		--case when betfrom IN ('D', 'M', 'E', 'L') then 1 else 0 end as IsDeposit,
		case WHEN b.srecommend IN (SELECT Dep_CustSuper.custid FROM Dep_CustSuper with(NOLOCK)) then 1 ELSE 0 end as IsDeposit,
		ag.site,
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,
		b.mrecommend,
		b.recommend,
		ISNULL(SecAcceptFlag,0) SecAcceptFlag		
	from 
		dbo.bettrans b with (NOLOCK)		
		INNER JOIN dbo.customer ag with (NOLOCK) ON b.recommend = ag.custid
		INNER JOIN dbo.customer cr with (NOLOCK) ON cr.custid = b.creator
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS goal ON goal.val=b.betteam--dbo.Acc_SplitIndex(b.betteam,':',2)			
	where
		matchid=@matchid 
		and b.transid between @FromRefNo and @ToRefNo 			 
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		--and status NOT IN ('Void', 'Reject')
		and statusID NOT IN (101,102)
		AND b.bettype=14
		AND (@betteam14='All' OR goal.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	--End Elly add
--order by IsDeposit desc, transid


	--0. For Normal bets
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE
		custid not in ( Select CustID from  [f_GetBetDaqCustomer] (1))
		and 
		username <> '12EU'
	AND IsDeposit = 0
	AND mrecommend not in (105181, 118473, 105183)
	ORDER BY transid

		
	--1. For Deposit bets
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE 
		custid not in ( Select CustID from  [f_GetBetDaqCustomer] (1))
		and 
		username <> '12EU'
	AND IsDeposit = 1	
	AND mrecommend not in (105181, 118473, 105183)
	ORDER BY transid
		
	--2. For Special bets
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE custid in (Select CustID from  [f_GetBetDaqCustomer] (1))
	ORDER BY IsDeposit desc, transid

	--3. For 12EU
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE username = '12EU'
	ORDER BY IsDeposit desc, transid

	--4. For member of master: MHCEU (105181), MHCRM (118473), MHCUS(105183)
	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	WHERE mrecommend in (105181, 118473, 105183)
	ORDER BY IsDeposit desc, transid

	DROP TABLE #SpecialDeleteBets
	
	SET NOCOUNT OFF
/*
*/
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelSpecialDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelSpecialDel] TO [vnteam]