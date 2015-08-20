ALTER PROCEDURE [dbo].[Acc_MT_BetTypeSel]
	@Sporttype INT = NULL
AS

/*
Created: 
Task : Retrieve Customer Setting Bet types.
DB: DBCUST.CustDB
Original:

Revisions:
	- 20091201@Kiwi: Union with CustSetting3rd.
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB, use temp table for bettype)

*/

SET NOCOUNT ON

----- 20150610@Kos -------------------
DECLARE @tmp_Bettype TABLE (TypeID INT, TypeNamee NVARCHAR(50))

BEGIN TRY
	INSERT INTO @tmp_Bettype (TypeID, TypeNamee)
	SELECT TypeID, TypeNamee FROM DBAGE.bodb02.dbo.Bettype WITH (NOLOCK)
END TRY
BEGIN CATCH
	INSERT INTO @tmp_Bettype (TypeID, TypeNamee)
	SELECT TypeID, TypeNamee FROM DBTXN.bodb02.dbo.Bettype WITH (NOLOCK)
END CATCH
----- 20150610@Kos -------------------

SELECT DISTINCT t.bettype, b.typenamee 
FROM 
	(	SELECT cs.custid, cs.bettype, cs.sporttype FROM CustSetting cs WITH (NOLOCK)
		UNION 
		SELECT cs3rd.custid, cs3rd.bettype, cs3rd.sporttype FROM CustSetting3rd cs3rd WITH (NOLOCK)
	 ) t
	INNER JOIN @tmp_Bettype b ON t.bettype = b.typeid
WHERE t.custid IN( 73104) AND t.sporttype = ISNULL(@sporttype, t.sporttype)
ORDER BY t.bettype


GO
GRANT EXECUTE ON [dbo].[Acc_MT_BetTypeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MT_BetTypeSel] TO [vnteam]