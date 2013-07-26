ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Casino]
	@winlostdate	datetime
AS
	/*	Creator: Phuong Dao
		Date: 2009-05-14
		Task: Casino WinLost Summary report
		DB: DB06.bodb02
		
		Revisions:
			- 20090731@Jamie: Not to view data in range of date, but only one date at once 
			-- 20100525@Henry: Change to use StatusID instead of Status in WHERE statement
			- 20120405@Hurri: Exclude bettype 72 (P2P bet ticket) in the calculation of Casino
			- 20130703@Kathy: Update matchid for RnG Casino (71)
			- 20130717@Kathy: Apply Progressive Bonus: add bettype 72 for Casino

	*/
BEGIN
	SET NOCOUNT ON
	SELECT		
			71 bettype,
			sum((winlost-actual_stake)*actualrate) WinLost,
			sum((awinlost+mwinlost+swinlost)*actualrate) Position,
			sum(scomm*actualrate) Commission,	
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) LineTotal,
			0 Turnover
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.winlostdate = @winlostdate
			AND b.bettype IN(71, 72)								--20120405@Hurri
			AND b.matchid IN (0, 71)
			--AND b.status NOT IN ('VOID', 'REJECT','done','REFUND') 
			AND b.statusID NOT IN (102, 101,121,103) 
			AND b.ruben = 1		
	GROUP BY b.Bettype
	ORDER BY b.Bettype	

END 


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Casino] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_DailyWLDirect_Casino] TO [vnteam]