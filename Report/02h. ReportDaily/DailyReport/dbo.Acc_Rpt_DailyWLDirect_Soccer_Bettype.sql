ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Soccer_Bettype]
	@winlostdate	datetime,
	@SoccerType		INT = 1,
	@IncludeBettype VARCHAR(MAX) = ''
AS
SET NOCOUNT ON

/*	Creator: Phuong Dao
	Date: 2009-02-26
	Task: WinLost Summary report - History
	DB: DBACC/bodb02
	
	Revisions:
		- 20090714@Kiwi: Exclude 'Refund' ticket
		- 20090731@Jamie: Not to view data in range of date, but only one date at once
		- 20091109@Kiwi: Declare @temp table to contain all matches based on @winlostdate
		- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement
		- 16Dec2010@Viet: Correct Turnover's value, will revert back when old data's gone
		- 20110824@Johnson: - remove check winlostdate with '16 Dec 2010' for sumary turnover, get from stake instead actual_stake
		- 20110824@Elly: - Correct Turnover of sports book since Sep 01, 2011
		- 20110826@Lukas: Modify to get bettype automatically
		- 20111202@Sophia: . Add new range for sportbook from 121 to 999
						   . Remove @NegativeBetEffectiveDate
		- 20120412@Hurri: Get win lost of agent 'BARM'
		- 20120530@Elodie: Change formula of 8RM/BARM winloss
		- 20120628@Elodie: check case of matchid = orid
		- 20121018@Lukas: use temp table to enhance performance
		- 20130408@Elodie: Add RealLineTotal field for all products that enable virtual currency
		- 20130522@Elodie: Get more fields RealTurnover, VirtualTurnover
		- 20130731@Johnson: Separate win loss by credit/deposit site(1: credit, 2: deposit)				  
		- 20140711@Johnson: Separate major and minor bettypes of soccer
		- 20141110@Johnson: include additional bettypes into report 
		- 20150108@Dom: Apply sport bettype matrix
		- 20150204@Johnson: move 1H Double Chance bet type to major bettype [RedmineID: #27216]
		- 20150525@Sophia: Apply Metric Gaming - SuperLive and revise Sport Betype Matrix [#35359] 

	Param's Explanation: 
		- @SoccerType= 1: Major bettypes
					= 2: Minor bettypes	
		- @IncludeBettype: include more bettypes in some specific cases(minor bettypes soccer get some major bettypes)
*/		
	
	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT, SubProduct VARCHAR(500))
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 5, @Sporttype = 1 


	Declare @tmpBettype table (	Bettype			int primary key, 
								DisplayOrder	int)
	
	CREATE TABLE #DepAgent (custid int primary key)
		
	INSERT INTO #DepAgent 
	SELECT custid
	FROM custInfo with(NOLOCK)
	WHERE srecommend IN (SELECT custid FROM f_DepSuper_1('All'))
		AND roleid = 2								
	UNION
	SELECT 5707545--BARM	
	
	Insert into @tmpBettype
	select 1,  1 --'Handicap',
	UNION ALL
	Select 3,  2 --'Over/Under',
	UNION ALL
	select 7,  3 --'1st Half Handicap',
	UNION ALL
	Select 8,  4 --'1st Half Over/Under',
	UNION ALL
	select 2,  5 --'Odd/Even',
	UNION ALL
	select 5,  6 --'1x2',
	UNION ALL
	Select 4,  7 --'Correct Score',
	UNION ALL
	Select 6,  8 --'Total Goal',
	UNION ALL 
	Select 10,  10 --'Outright',


	INSERT INTO @tmpBettype
		SELECT typeid, typeid
		FROM bettype WITH(NOLOCK)
		WHERE (typeid > 10 AND typeid < 31) OR typeid BETWEEN 121 AND 999
	
	DELETE @tmpBettype 
	WHERE 1 = CASE WHEN @SoccerType = 1 AND Bettype NOT IN (1,2,3,5,6,7,8,12,15,24,25,28,121,122,123,126,151) THEN 1
					WHEN @SoccerType = 2 AND Bettype IN (1,2,3,5,6,7,8,12,15,24,25,28,121,122,123,126,151) THEN 1 ELSE 0 END
	
	IF ISNULL(@IncludeBettype,'') <> ''
	BEGIN
		INSERT INTO @tmpBettype
		SELECT val, val
		FROM dbo.strSplit(@IncludeBettype,',')
			LEFT JOIN @tmpBettype t ON val = t.bettype
		WHERE t.Bettype IS NULL
	END
					
	--Declare @temp table to contain all matches based on @winlostdate
	DECLARE @Match TABLE (matchid INT, matchcode NVARCHAR(50), type varchar(10), primary key(matchid, type))
	INSERT INTO @Match 
	SELECT	m.matchid, 
			m.matchcode,
			m.type
	FROM (
			SELECT matchid, leagueid, exrisk, matchcode, 'match' as type FROM MATCH WITH (NOLOCK) WHERE eventdate = @winlostdate
			UNION ALL
			SELECT orid, leagueid, 0, matchcode, 'outright' as type FROM outright WITH (NOLOCK) WHERE eventdate = @winlostdate
			)m	
	INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid	
	INNER JOIN Sports s WITH (NOLOCK) ON l.sporttype = s.sporttype 
	WHERE s.sporttype = 1

	CREATE TABLE #TempBettrans (liveindicator BIT, Bettype INT, matchid INT, site tinyint, WinLost MONEY, Position MONEY, Commission MONEY, LineTotal_actualrate MONEY, LineTotal_virtualrate MONEY, Turnover_actualrate MONEY, Turnover_virtualrate MONEY)
	INSERT INTO #TempBettrans	
	SELECT		
			liveindicator,
			b.Bettype,			
			matchid,
			case when dep.custid is null then 1 else 2 end as site,
			sum((winlost-actual_stake)*virtualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*virtualrate) Position,
			sum(scomm*virtualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal_actualrate,
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) LineTotal_virtualrate,
			sum((1-tpositiontaking)*ABS(stake)*actualrate) Turnover_actualrate,
			sum((1-tpositiontaking)*ABS(stake)*virtualrate) Turnover_virtualrate
	FROM	bettrans b WITH (NOLOCK)	
		inner join @SportBettype s ON s.bettype = b.bettype
		left join (select custid from #DepAgent) dep ON b.recommend = dep.custid		
	WHERE	s.EventType IN (1,2)
			AND s.SubProduct NOT IN ('MG-SuperLive')
			AND b.winlostdate = @winlostdate
			--AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999)	
			AND matchid > 0		
			AND statusID NOT IN (101, 102,103) 
			AND ruben = 1			
	GROUP BY		
			liveindicator,
			b.Bettype,
			matchid,
			case when dep.custid is null then 1 else 2 end 	
	
	SELECT		
			b.liveindicator,
			bt.Bettype,
			case when m.matchcode like '%hedge%' then ' (hedge)' else '' end isHedge,
			site,
			sum(WinLost) winlost,
			sum(Position) position,
			sum(Commission) commission,	
			sum(LineTotal_actualrate) RealLineTotal,
			sum(LineTotal_virtualrate) VirtualLineTotal,
			sum(Turnover_actualrate) RealTurnover,
			sum(Turnover_virtualrate) VirtualTurnover
	FROM	#TempBettrans b
			INNER JOIN @Match m on b.matchid = m.matchid 	
			INNER JOIN @tmpBettype bt ON b.bettype = bt.Bettype
	WHERE   m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END
	GROUP BY		
			b.liveindicator,
			bt.Bettype, 
			case when m.matchcode like '%hedge%' then ' (hedge)' else '' end ,	
			bt.DisplayOrder,
			site
	ORDER BY
			b.liveindicator, bt.DisplayOrder,site

	select	b.liveindicator, 
			1 as ibc,--8RM
			-sum(winlost-actual_stake) WinLost,
			-sum(awinlost+mwinlost+swinlost) Position,
			sum(scomm) Commission,				
			-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) RealLineTotal,
			-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) VirtualLineTotal,
			-sum((1-tpositiontaking)*ABS(stake)) RealTurnover,
			-sum((1-tpositiontaking)*ABS(stake)) VirtualTurnover
	FROM	bettrans b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid 	
			inner join @SportBettype s ON s.bettype = b.bettype
			INNER JOIN @tmpBettype bt ON b.bettype = bt.Bettype
	WHERE	s.EventType IN (1,2)
			AND s.SubProduct NOT IN ('MG-SuperLive')
			AND b.winlostdate = @winlostdate
			--AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999)
			AND b.matchid > 0 
			AND b.statusID NOT IN (101, 102,103) 
			AND b.ruben = 1		
			AND recommend = 52466
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
	GROUP BY b.liveindicator 	
	
	-- 20120412@Hurri: Get win lost of agent 'BARM'	
	select	b.liveindicator, 
			2 as ibc,--BARM
			-sum(winlost-actual_stake) WinLost,
			-sum(awinlost+mwinlost+swinlost) Position,
			sum(scomm) Commission,				
			-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) RealLineTotal,
			-sum(winlost - actual_stake + awinlost + mwinlost + swinlost + scomm) VirtualLineTotal,
			-sum((1-tpositiontaking)*ABS(stake)) RealTurnover,
			-sum((1-tpositiontaking)*ABS(stake)) VirtualTurnover
	FROM	bettrans b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid
			inner join @SportBettype s ON s.bettype = b.bettype
			INNER JOIN @tmpBettype bt ON b.bettype = bt.Bettype 	
	WHERE	s.EventType IN (1,2)
			AND s.SubProduct NOT IN ('MG-SuperLive')
			AND b.winlostdate = @winlostdate
			--AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999)
			AND b.matchid > 0 
			AND b.statusID NOT IN (101, 102,103) 
			AND b.ruben = 1		
			AND recommend = 5707545
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END -- 20120628@Elodie: check case of matchid = orid
	GROUP BY b.liveindicator

DROP TABLE #TempBettrans
DROP TABLE #DepAgent


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Soccer_Bettype] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Soccer_Bettype] TO [vnteam]