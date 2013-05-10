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
*/
	SELECT distinct winlostdate FROM bettrans with (nolock) WHERE winlostdate = @winlostdate AND bettype < 19999
	IF @@ROWCOUNT = 1
	BEGIN
		DELETE FROM bodb_Report.dbo.rptWinlost
		WHERE winlostdate = @winlostdate

		INSERT INTO bodb_Report.dbo.rptWinlost
		SELECT
			winlostdate,
			matchid, bettype, liveindicator, Status,
			case when recommend = 52466 then 1 when recommend = 5707545 then 2 else 0 end ibc,
			sum((winlost-actual_stake)* actualrate)  winlost,
			sum((awinlost+mwinlost+swinlost)* actualrate) pos,
			sum((scomm) * actualrate) comm,
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

		UPDATE bodb_Report.dbo.rptWinlost
		SET SportType = CASE
			WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
			WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
			ELSE l.sporttype END, exrisk = m.exrisk
		FROM match m with (nolock)
			inner join league l with (nolock) ON m.leagueid = l.leagueid
		WHERE bodb_Report.dbo.rptWinlost.matchid = m.matchid
		AND m.eventdate = @winlostdate AND bodb_Report.dbo.rptWinlost.winlostdate = @winlostdate
		AND bodb_Report.dbo.rptWinlost.bettype not in (10,31,32,33) --20120626@Elodie: exclude outright from sportbook

		UPDATE bodb_Report.dbo.rptWinlost
		SET SportType = CASE
			WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
			WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
			ELSE l.sporttype END
		FROM outright o with (nolock) INNER JOIN league l with (nolock) ON o.leagueid = l.leagueid
		WHERE bodb_Report.dbo.rptWinlost.matchid = o.orid
		AND bodb_Report.dbo.rptWinlost.winlostdate = @winlostdate
		AND bodb_Report.dbo.rptWinlost.bettype = 10

	END
	ELSE
	BEGIN -- check from BetTrans14
		SELECT distinct winlostdate FROM bettrans14 with (nolock) WHERE winlostdate = @winlostdate AND bettype < 19999

		IF @@ROWCOUNT = 1
		BEGIN
			DELETE FROM bodb_Report.dbo.rptWinlost
			WHERE winlostdate = @winlostdate

			INSERT INTO bodb_Report.dbo.rptWinlost
			SELECT
				winlostdate,
				matchid, bettype, liveindicator, Status,
				case when recommend = 52466 then 1 when recommend = 5707545 then 2 else 0 end ibc,
				sum((winlost-actual_stake)* actualrate)  winlost,
				sum((awinlost+mwinlost+swinlost)* actualrate) pos,
				sum((scomm) * actualrate) comm,
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

			UPDATE bodb_Report.dbo.rptWinlost
			SET SportType = CASE
				WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
				WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
				ELSE l.sporttype END, exrisk = m.exrisk
			FROM match14 m with (nolock)
				inner join league l with (nolock) ON m.leagueid = l.leagueid
			WHERE bodb_Report.dbo.rptWinlost.matchid = m.matchid
			AND m.eventdate = @winlostdate AND bodb_Report.dbo.rptWinlost.winlostdate = @winlostdate
			AND bodb_Report.dbo.rptWinlost.bettype not in (10,31,32,33) --20120626@Elodie: exclude outright from sportbook
			
			UPDATE bodb_Report.dbo.rptWinlost
			SET SportType = CASE
				WHEN leaguename LIKE '%NFL%' AND l.sporttype = 2 THEN 3
				WHEN (leaguename LIKE '%NHL%' OR leaguename LIKE '%hockey%') AND l.sporttype = 2 THEN 4
				ELSE l.sporttype END
			FROM outright14 o with (nolock) INNER JOIN league l with (nolock) ON o.leagueid = l.leagueid
			WHERE bodb_Report.dbo.rptWinlost.matchid = o.orid
			AND bodb_Report.dbo.rptWinlost.winlostdate = @winlostdate
			AND bodb_Report.dbo.rptWinlost.bettype = 10
		END
	END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_rptWinLost_UpdateTable] TO [vnteam]