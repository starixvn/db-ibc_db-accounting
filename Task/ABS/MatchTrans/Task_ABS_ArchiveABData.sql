ALTER PROCEDURE [dbo].[Task_ABS_ArchiveABData]
AS
/*
	Created: Viet
	Date: 20121115
	Task: archive data for ABTransaction and ABMatch_Remark
	DB: DB052.bodb_abs
	
	Revisions:
		- 20121129@Jamie: fix check error code 
	Paramters Explanation:
*/
SET NOCOUNT ON	

	declare @matchIDs as table(matchid int)
	INSERT INTO @matchIDs (matchid)
	select distinct m.matchid
	FROM dbo.ABMatch_Remark rm with(nolock)
		inner join bodb02.dbo.match14 m with(nolock) on rm.matchid = m.matchid		

	IF @@rowcount = 0 RETURN		
			
	INSERT INTO dbo.ABMatch_Remark_bk (matchid, bettype, hdp, odds, transid)
	SELECT matchid, bettype, hdp, odds, transid
	FROM dbo.ABMatch_Remark s with(rowlock)
	WHERE matchid in (select matchid from @matchIDs)
		AND NOT EXISTS (
			SELECT matchid, bettype 
			FROM ABMatch_Remark_bk d with(nolock)
			WHERE s.matchid = d.matchid and s.bettype = d.bettype
		)	
	
	IF @@error=0
	BEGIN
		DELETE dbo.ABMatch_Remark
		WHERE matchid in (select matchid from @matchIDs)
	END
		
	INSERT INTO dbo.ABTransaction_bk (transid, punterid, custid, remark, matchid, bettype)
	SELECT transid, punterid, custid, remark, matchid, bettype
	FROM dbo.ABTransaction s with(rowlock)
	WHERE matchid in (select matchid from @matchIDs)
		AND NOT EXISTS (
			SELECT transid 
			FROM ABTransaction_bk d with(nolock)
			WHERE s.transid = d.transid
		)	
	IF @@error=0
	BEGIN
		DELETE dbo.ABTransaction
		WHERE matchid in (select matchid from @matchIDs)
	END

SET NOCOUNT OFF	
