


ALTER PROCEDURE [dbo].[Admin_Recalculate_Result]
(
	@matchid INT
)
AS
/*	
	Created by: 20111116@Lukas
	Task: Count affected tickets
	DB: DB052.BODB_REVIEW

	Revisions:		
		
*/
BEGIN
	
	SET NOCOUNT ON 

	DECLARE @Principal TABLE (principal VARCHAR(50), srecommend INT)

	-- get licensee
	INSERT INTO @Principal
		SELECT c.site, c.custid
		FROM bodb02.dbo.customer c WITH(NOLOCK)
				INNER JOIN bodb02.dbo.f_depsuper_1('ALL') s ON c.custid = s.custid


	SELECT CASE WHEN p.principal IS NULL THEN 'IBCBet' ELSE p.principal END AS Principal,
			bettype, COUNT('') AS betcount
	FROM (
			SELECT b.transid, b.srecommend, b.bettype
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN bodb02.dbo.bettrans bt WITH(NOLOCK) ON b.transid = bt.transid
			WHERE b.matchid = @matchid
				AND bt.statusID NOT IN (101,102,103)
				AND b.currency <> 20
				AND CHECKSUM(b.statusid, b.winlost, b.playercomm) <> CHECKSUM(bt.statusid, bt.winlost, bt.playercomm)
		) t LEFT JOIN @Principal p ON t.srecommend = p.srecommend
	GROUP BY principal, bettype
	ORDER BY principal, bettype
END

