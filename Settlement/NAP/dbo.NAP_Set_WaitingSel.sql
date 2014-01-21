ALTER PROCEDURE [NAP_Set_WaitingSel]
	@MatchCode nvarchar(50) = '',
	@SportType tinyint = 0,
	@LeagueID int = 0 -- 0 for ALL Leagues
AS
/*
	Created: 20140103@Kathy
	Task: get status for a match
	DB: DBTXN/BODB02
	
	Revision:
	
	Param's explanation:  
		
*/
BEGIN

	SET NOCOUNT ON 
	DECLARE @matchid int 
	SELECT @MatchCode = ISNULL(@MatchCode,''), @LeagueID = ISNULL(@LeagueID,0),@SportType = ISNULL(@SportType, 0)

	IF (@matchcode <> '')
	BEGIN TRY	
		SET @matchid = CASE WHEN ISNUMERIC(@MatchCode) = 1 THEN CAST(@MatchCode AS INT) ELSE NULL END
	END TRY
	BEGIN CATCH
		SET @matchid=NULL
	END CATCH

	DECLARE @tblSingle table(matchid int, seq int)
	DECLARE @tblParlay table(matchid int, seq int)

	;WITH SingleTicket AS
	(
		SELECT s.matchid, CASE WHEN s.IsCalculating = 1 then 1
								when s.IsCalculating = 0 then 2
								WHEN s.IsCalculating = 2 then 3
							END as seq
		FROM Single_WaitingList s WITH(NOLOCK)
	)
	INSERT INTO @tblSingle
	SELECT matchid, min(seq)
	FROM SingleTicket
	group BY matchid

	;WITH ParlayTicket AS
	(
		SELECT s.matchid, CASE WHEN s.IsCalculating = 1 then 1
								when s.IsCalculating = 0 then 2
								WHEN s.IsCalculating = 2 then 3
							END as seq
		FROM Parlay_WaitingList s WITH(NOLOCK)
	)
	INSERT INTO @tblParlay
	SELECT matchid, min(seq)
	FROM ParlayTicket
	group BY matchid

	SELECT m.matchid, m.leagueid ,
		hthomescore HalfTimeHomeScore,
		htawayscore HalfTimeAwayScore, 
		isnull(mr.calculate,0) IsCalculated, isnull(mr.multiple,0) IsMultiCaled,  
		isnull(mr.refund,0) IsRefund, isnull(mr.calrefund,0) IsCalRefund,  		
		m.homeid, m.awayid,  
		m.matchcode, m.kickofftime,  
		m.finalhomescore,  
		m.finalawayscore, m.betstatus,  
		case when m.betstatus like 'Refund FT%' then 'Refund FT'  
		when m.betstatus like 'Refund HT%' then 'Refund HT'  
		when m.betstatus like 'Refund%' then 'Refund'  
		else m.eventstatus  
		end as eventstatus,    
		'' as Foddsstatus,  
		m.sporttype,  
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
		m.eventdate,  
		m.goalrecord, 
		case mr.ConfirmHT when 0 then '' else (select username from CustDB.dbo.custInfo (nolock) where custid = mr.ConfirmHT ) end suspenderHalfTime,   
		case mr.ConfirmFT when 0 then '' else (select username from CustDB.dbo.custInfo (nolock) where custid = mr.ConfirmFT ) end suspenderFullTime,  
		ISNULL(mr.IsHTCal,0) as IsHalfTimeCal,  		
		ISNULL(mr.isPending,0) as isPending,  
		ISNULL(mr.isUndecided,0) as isUndecided,  
		CAST(CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore ,
		case when s.seq = 1 THEN 1
					WHEN s.seq = 2 then 0
					when s.seq = 3 then 2 
				END as IsCalculating,
		0 IsMixParlay
	FROM @tblSingle s 
	INNER JOIN match m with(NOLOCK) ON m.matchid = s.matchid
	LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON s.matchid = mr.matchid
	WHERE  m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
		AND m.sporttype = case when @sporttype = 0 then m.sporttype else @sporttype end  	  		
		AND (@matchcode = '' or (m.matchid = @matchid OR m.matchcode = @matchcode)) 

	UNION ALL
	SELECT m.matchid, m.leagueid ,
		hthomescore HalfTimeHomeScore,
		htawayscore HalfTimeAwayScore, 
		isnull(mr.calculate,0) IsCalculated, isnull(mr.multiple,0) IsMultiCaled,  
		isnull(mr.refund,0) IsRefund, isnull(mr.calrefund,0) IsCalRefund,  		
		m.homeid, m.awayid,  
		m.matchcode, m.kickofftime,  
		m.finalhomescore,  
		m.finalawayscore, m.betstatus,  
		case when m.betstatus like 'Refund FT%' then 'Refund FT'  
		when m.betstatus like 'Refund HT%' then 'Refund HT'  
		when m.betstatus like 'Refund%' then 'Refund'  
		else m.eventstatus  
		end as eventstatus,    
		'' as Foddsstatus,  
		m.sporttype,  
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
		m.eventdate,  
		m.goalrecord, 
		case mr.ConfirmHT when 0 then '' else (select username from CustDB.dbo.custInfo (nolock) where custid = mr.ConfirmHT ) end suspenderHalfTime,   
		case mr.ConfirmFT when 0 then '' else (select username from CustDB.dbo.custInfo (nolock) where custid = mr.ConfirmFT ) end suspenderFullTime,  
		ISNULL(mr.IsHTCal,0) as IsHalfTimeCal,  		
		ISNULL(mr.isPending,0) as isPending,  
		ISNULL(mr.isUndecided,0) as isUndecided,  
		CAST(CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore ,
		case when p.seq = 1 THEN 1
					WHEN p.seq = 2 then 0
					when p.seq = 3 then 2 
				END as IsCalculating,
		1 IsMixParlay
	FROM @tblParlay p 
	INNER JOIN match m with(NOLOCK) ON m.matchid = p.matchid
	LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON p.matchid = mr.matchid
	WHERE  m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
		AND m.sporttype = case when @sporttype = 0 then m.sporttype else @sporttype end  	  		
		AND (@matchcode = '' or (m.matchid = @matchid OR m.matchcode = @matchcode)) 
	ORDER BY matchid

END

GO

GRANT EXECUTE ON [NAP_Set_WaitingSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_WaitingSel] TO [vnteam] AS [dbo]
GO


