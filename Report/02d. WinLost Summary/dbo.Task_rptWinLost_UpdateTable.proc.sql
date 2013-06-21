ALTER PROCEDURE [dbo].[Task_rptWinLost_UpdateTable]
	@winlostdate smalldatetime
AS
/*
Name : rpt_WinLost_UpdateTable
Creator : Joe
Created : 2007-01-29 01:30
Task : update summary for winlost report
DB: DB06.bodb02
Revision:
	- 20110516@Lukas: re-arrange bettype
	- 20120420@Hurri: add tickets of member under agent BARM into IBC winlost
	- 20120626@Elodie: exclude outright, HR from sportbook ( in case of matchid = orid)
	- 20130620@Johnson: copy data to rptWinlost2
*/
	
	SELECT distinct winlostdate FROM bettrans with (nolock) WHERE winlostdate = @winlostdate AND bettype < 19999
	IF @@ROWCOUNT = 1
	BEGIN
		DELETE FROM bodb_Report.dbo.rptWinlost
		WHERE winlostdate = @winlostdate
		
		DELETE FROM bodb_Report.dbo.rptWinlost2
		WHERE winlostdate = @winlostdate
		

		INSERT INTO bodb_Report.dbo.rptWinlost2
			(
				[winlostdate]
			   ,[matchid]
			   ,[bettype]
			   ,[liveindicator]
			   ,[Status]
			   ,[IBC]
			   ,[RealTurnover]
			   ,[RealWinLost]
			   ,[RealPosition]
			   ,[RealCommission]
			   ,[RealLineTotal]
			   ,[VirtualTurnover]
			   ,[VirtualLineTotal]
			   ,[SportType]
			   ,[exrisk]
			)	
		SELECT
			winlostdate,
			matchid, bettype, liveindicator, Status,
			case when recommend = 52466 then 1 when recommend = 5707545 then 2 else 0 end ibc,
			sum(case when bettype = 1000 then 0 else (1-tpositiontaking)*abs(stake)*actualrate end) as realturnover,
			sum((winlost-actual_stake)* actualrate)  realWinlost,
			sum((awinlost+mwinlost+swinlost)* actualrate) realPos,
			sum((scomm) * actualrate) realComm,
			sum((case when bettype = 1000 then -1*(odds-scomm) else winlost-actual_stake+awinlost+mwinlost+swinlost+scomm end)*actualrate) realLineTotal,
			sum((1-tpositiontaking)*abs(CASE WHEN bettype = 29 AND betid > 0 THEN actual_stake ELSE stake END)*virtualrate) as virtualTurnover,
			sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) as virtualLineTotal,
			0, 0
		FROM
			bettrans b with (nolock)
		WHERE
			bettype < 19999
			AND winlostdate = @winlostdate
			AND statusID NOT IN (101, 102) --('VOID', 'REJECT') 
			AND ruben = 1
		GROUP BY
			winlostdate, matchid, bettype, liveindicator, status,
			case when recommend = 52466 then 1 when recommend = 5707545 then 2 else 0 end

		UPDATE bodb_Report.dbo.rptWinlost2
		SET SportType = CASE
			WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
			WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
			ELSE l.sporttype END, exrisk = m.exrisk
		FROM match m with (nolock)
			inner join league l with (nolock) ON m.leagueid = l.leagueid
		WHERE bodb_Report.dbo.rptWinlost2.matchid = m.matchid
		AND m.eventdate = @winlostdate AND bodb_Report.dbo.rptWinlost2.winlostdate = @winlostdate
		AND bodb_Report.dbo.rptWinlost2.bettype not in (10,31,32,33) --20120626@Elodie: exclude outright from sportbook

		UPDATE bodb_Report.dbo.rptWinlost2
		SET SportType = CASE
			WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
			WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
			ELSE l.sporttype END
		FROM outright o with (nolock) INNER JOIN league l with (nolock) ON o.leagueid = l.leagueid
		WHERE bodb_Report.dbo.rptWinlost2.matchid = o.orid
		AND bodb_Report.dbo.rptWinlost2.winlostdate = @winlostdate
		AND bodb_Report.dbo.rptWinlost2.bettype = 10
		
		INSERT INTO [bodb_report].[dbo].[rptWinLost]
           ([winlostdate]
           ,[matchid]
           ,[bettype]
           ,[liveindicator]
           ,[Status]
           ,[IBC]
           ,[WinLost]
           ,[Position]
           ,[Commission]
           ,[SportType]
           ,[exrisk])
      SELECT	
			[winlostdate]
           ,[matchid]
           ,[bettype]
           ,[liveindicator]
           ,[Status]
           ,[IBC]
           ,[RealWinlost]
           ,[RealPosition]
           ,[RealCommission]
           ,[SportType]
           ,[exrisk]
      FROM [bodb_report].[dbo].[rptWinLost2] WITH(NOLOCK)
      WHERE winlostdate = @winlostdate
	
	 
		UPDATE bodb_Report.dbo.rptWinlost2
		SET SportType = CASE
			WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
			WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
			ELSE l.sporttype END
		FROM outright o with (nolock) INNER JOIN league l with (nolock) ON o.leagueid = l.leagueid
		WHERE bodb_Report.dbo.rptWinlost2.matchid = o.orid
		AND bodb_Report.dbo.rptWinlost2.winlostdate = @winlostdate
		AND bodb_Report.dbo.rptWinlost2.bettype BETWEEN 31 AND 33			
	END
	ELSE
	BEGIN -- check from BetTrans14
		SELECT distinct winlostdate FROM bettrans14 with (nolock) WHERE winlostdate = @winlostdate AND bettype < 19999

		IF @@ROWCOUNT = 1
		BEGIN
			DELETE FROM bodb_Report.dbo.rptWinlost
			WHERE winlostdate = @winlostdate
			
			DELETE FROM bodb_Report.dbo.rptWinlost2
			WHERE winlostdate = @winlostdate
		

			INSERT INTO bodb_Report.dbo.rptWinlost2
				(
					[winlostdate]
				   ,[matchid]
				   ,[bettype]
				   ,[liveindicator]
				   ,[Status]
				   ,[IBC]
				   ,[RealTurnover]
				   ,[RealWinLost]
				   ,[RealPosition]
				   ,[RealCommission]
				   ,[RealLineTotal]
				   ,[VirtualTurnover]
				   ,[VirtualLineTotal]
				   ,[SportType]
				   ,[exrisk]
				)				
			SELECT
				winlostdate,
				matchid, bettype, liveindicator, Status,
				case when recommend = 52466 then 1 when recommend = 5707545 then 2 else 0 end ibc,
				sum((1-tpositiontaking)*abs(stake)*actualrate) realturnover,
				sum((winlost-actual_stake)* actualrate)  realwinlost,
				sum((awinlost+mwinlost+swinlost)* actualrate) realposition,				
				sum((scomm) * actualrate) realcomm,
				sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*actualrate) as realLineTotal,				
				sum((1-tpositiontaking)*abs(CASE WHEN bettype = 29 AND betid > 0 THEN actual_stake ELSE stake END)*virtualrate) as virtualTurnover,
				sum((winlost-actual_stake+awinlost+mwinlost+swinlost+scomm)*virtualrate) as virtualLineTotal,				
				0, 0
			FROM
				bettrans14 b with (nolock)
			WHERE
				bettype < 19999
				AND winlostdate = @winlostdate
				AND statusID NOT IN (101, 102) --('VOID', 'REJECT') 
				AND ruben = 1
			GROUP BY
				winlostdate, matchid, bettype, liveindicator, status,
				case when recommend = 52466 then 1 when recommend = 5707545 then 2 else 0 end

			UPDATE bodb_Report.dbo.rptWinlost2
			SET SportType = CASE
				WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
				WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
				ELSE l.sporttype END, exrisk = m.exrisk
			FROM match14 m with (nolock)
				inner join league l with (nolock) ON m.leagueid = l.leagueid
			WHERE bodb_Report.dbo.rptWinlost2.matchid = m.matchid
			AND m.eventdate = @winlostdate AND bodb_Report.dbo.rptWinlost2.winlostdate = @winlostdate
			AND bodb_Report.dbo.rptWinlost2.bettype not in (10,31,32,33) --20120626@Elodie: exclude outright from sportbook
			
			UPDATE bodb_Report.dbo.rptWinlost2
			SET SportType = CASE
				WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
				WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
				ELSE l.sporttype END
			FROM outright14 o with (nolock) INNER JOIN league l with (nolock) ON o.leagueid = l.leagueid
			WHERE bodb_Report.dbo.rptWinlost2.matchid = o.orid
			AND bodb_Report.dbo.rptWinlost2.winlostdate = @winlostdate
			AND bodb_Report.dbo.rptWinlost2.bettype = 10
			
			INSERT INTO [bodb_report].[dbo].[rptWinLost]
			   ([winlostdate]
			   ,[matchid]
			   ,[bettype]
			   ,[liveindicator]
			   ,[Status]
			   ,[IBC]
			   ,[WinLost]
			   ,[Position]
			   ,[Commission]
			   ,[SportType]
			   ,[exrisk])
			SELECT	
				[winlostdate]
			   ,[matchid]
			   ,[bettype]
			   ,[liveindicator]
			   ,[Status]
			   ,[IBC]
			   ,[RealWinlost]
			   ,[RealPosition]
			   ,[RealCommission]
			   ,[SportType]
			   ,[exrisk]
			FROM [bodb_report].[dbo].[rptWinLost2] WITH(NOLOCK)
			WHERE winlostdate = @winlostdate
		
		 
			UPDATE bodb_Report.dbo.rptWinlost2
			SET SportType = CASE
				WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
				WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
				ELSE l.sporttype END
			FROM outright o with (nolock) INNER JOIN league l with (nolock) ON o.leagueid = l.leagueid
			WHERE bodb_Report.dbo.rptWinlost2.matchid = o.orid
			AND bodb_Report.dbo.rptWinlost2.winlostdate = @winlostdate
			AND bodb_Report.dbo.rptWinlost2.bettype BETWEEN 31 AND 33		
		END
	END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_rptWinLost_UpdateTable] TO [vnteam]