CREATE PROCEDURE [NAP_Set_WaitingSel]
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

	DECLARE @tblSingle table(matchid int, seqS int, seqP int) 
	DECLARE	@tblParlay table(matchid int, seqS int,seqP int)
	DECLARE	@tblSingle_Parlay table(matchid int, seqS int, seqP int)
	DECLARE	@tblResult table(matchid int, seqS int, seqP int, IsExistFGLG bit)
	DECLARE @strmatchid VARCHAR(MAX),
			@betstatus VARCHAR(8000),
			@intDocHandle INT


	;WITH SingleTicket AS
	(
		SELECT s.matchid, CASE WHEN s.IsCalculating = 1 then 1
								when s.IsCalculating = 0 then 2
								WHEN s.IsCalculating = 2 then 3
								when s.IsCalculating = 3 then 4
							END as seqS
		FROM Single_Calculate_Queue s WITH(NOLOCK)
		where s.matchid NOT IN (SELECT matchid FROM Parlay_Calculate_Queue with(NOLOCK))
	)
	INSERT INTO @tblSingle
	SELECT s.matchid, min(seqS), NULL
	FROM SingleTicket s
	group BY s.matchid

	;WITH ParlayTicket AS
	(
		SELECT p.matchid, CASE WHEN p.IsCalculating = 1 then 1
								when p.IsCalculating = 0 then 2
								WHEN p.IsCalculating = 2 then 3
								when p.IsCalculating = 3 then 4
							END as seqP
		FROM Parlay_Calculate_Queue p WITH(NOLOCK)
		where p.matchid NOT IN (SELECT matchid FROM Single_Calculate_Queue with(NOLOCK))
	)
	INSERT INTO @tblParlay
	SELECT p.matchid, NULL, min(seqP)
	FROM ParlayTicket p 	
	group BY p.matchid	

	;WITH SingleParlayTicket AS
	(
		SELECT s.matchid, CASE WHEN s.IsCalculating = 1 then 1
								when s.IsCalculating = 0 then 2
								WHEN s.IsCalculating = 2 then 3
								when s.IsCalculating = 3 then 4
							END as seqS,
						  CASE WHEN p.IsCalculating = 1 then 1
								when p.IsCalculating = 0 then 2
								WHEN p.IsCalculating = 2 then 3
								when p.IsCalculating = 3 then 4
							END as seqP
		FROM Single_Calculate_Queue s WITH(NOLOCK)
		INNER JOIN Parlay_Calculate_Queue p with(NOLOCK) ON s.matchid = p.matchid
	)
	INSERT INTO @tblSingle_Parlay
	SELECT matchid, min(seqS), min(seqP)
	FROM SingleParlayTicket 
	group BY matchid	

	INSERT INTO @tblResult
	SELECT matchid, seqS, seqP, 0
	FROM @tblSingle
	UNION ALL
	SELECT matchid, seqS, seqP, 0
	FROM @tblParlay
	UNION ALL
	SELECT matchid, seqS, seqP, 0
	FROM @tblSingle_Parlay

	SELECT @strmatchid = (
			SELECT matchid 
			FROM @tblResult
			FOR XML PATH('match'), ROOT('root')
		)

	EXEC DBTXN.bodb02.dbo.NAP_Set_MatchBetStatusSel @matchid = @strmatchid, @betstatus = @betstatus OUTPUT
		
		--Create an internal representation of the XML document.      
	EXEC sp_xml_preparedocument @intDocHandle OUTPUT, @betstatus

	UPDATE m
		SET IsExistFGLG = CASE WHEN rs.cnt = 0 OR rs.cnt IS NULL THEN 0 ELSE 1 END
		FROM @tblResult m
			LEFT JOIN (
					SELECT matchid, cnt
					FROM OPENXML(@intDocHandle,'/root/match',2)
					with (matchid INT,
						cnt INT) 
			)rs ON m.matchid = rs.matchid

	
	select m.matchid, m.leagueid ,
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
		t.IsExistFGLG,
		case when t.seqS = 1 THEN 1
					WHEN t.seqS = 2 then 0
					when t.seqS = 3 then 2 
					when t.seqS = 4 THEN 3
				END as IsCalculatingSingle,
		case when t.seqP = 1 THEN 1
					WHEN t.seqP = 2 then 0
					when t.seqP = 3 then 2 
					when t.seqP = 4 then 3
				END as IsCalculatingMP,
		convert(bit, CASE WHEN t.seqS IS NULL THEN 0 ELSE 1 END) as IsSingle,
		convert(bit, CASE when t.seqP IS NULL THEN 0 ELSE 1 END) as IsMixParlay
	FROM @tblResult t
	INNER JOIN match m with(NOLOCK) ON m.matchid = t.matchid
	LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON t.matchid = mr.matchid
	WHERE  m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
		AND m.sporttype = case when @sporttype = 0 then m.sporttype else @sporttype end  	  		
		AND (@matchcode = '' or (m.matchid = @matchid OR m.matchcode = @matchcode)) 
END

GO

GRANT EXECUTE ON [NAP_Set_WaitingSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Set_WaitingSel] TO [vnteam] AS [dbo]
GO


