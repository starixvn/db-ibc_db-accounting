 ALTER PROCEDURE [dbo].[Acc_SMATurnoverCheckList]	
	@UserID INT,
	@ListSMA XML,		
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(80) = '' OUTPUT
AS
/*
	Creator: Elodie
	Task : Check list SMA valid or invalid
	DB: DBAGE/bodb02
	Original: 

	Revisions:		

*/
BEGIN
SET NOCOUNT ON
			
	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SMATurnoverManagement]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	DECLARE @tblCust TABLE (
		SMAName VARCHAR(30),
		CustID INT,
		MatchID INT,
		MaxTurnover MONEY		
	)
	
	DECLARE @tblSucc TABLE (
		SMAName VARCHAR(30),
		CustID INT,
		MatchID INT,
		MaxTurnover MONEY
	)

	DECLARE @tblFail TABLE (
		SMAName VARCHAR(30),
		CustID INT,
		MatchID INT,
		MaxTurnover MONEY,
		Reason NVARCHAR(100)
	)
	
	INSERT INTO @tblCust(SMAName, MatchID, MaxTurnover)				
	SELECT	T.C.value('./@SMAName', 'varchar(30)'),
			T.C.value('./@MatchID', 'int'),
			T.C.value('./@MaxTurnover', 'money')
	FROM @ListSMA.nodes('/ListSMA/SMA') AS T(C)
	
	UPDATE @tblCust
	SET CustID = c.custid
	FROM custInfo c WITH (NOLOCK) 
	WHERE username = SMAName
	
	--Validate transaction
	INSERT INTO @tblSucc(SMAName, CustID, MatchID, MaxTurnover)
	SELECT	SMAName, CustID, MatchID, MaxTurnover			
	FROM	@tblCust as t
	WHERE ISNUMERIC(MaxTurnover)=1 and cast(MaxTurnover AS INT) = 1
			AND EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE roleid = 4 and custInfo.custid = t.CustID)
			AND NOT EXISTS (SELECT 1 FROM DownlineTurnOver_Setting ds WITH (NOLOCK) WHERE t.CustID <> ds.custid and t.MatchID <> ds.matchid)
			
	
	----Failed Transaction
	--INSERT INTO @tblFail(SMAName, CustID, MatchID, MaxTurnover, Reason)
	--SELECT	SMAName, CustID, MatchID, MaxTurnover,  
	--		CASE WHEN ISNUMERIC(MaxTurnover)=0 or cast(MaxTurnover AS INT) = 0 THEN '<b>Invalid Max Turnover.</b>'
	--			 WHEN ISNULL(FromCust,'') ='' and ISNULL(ToCust,'') ='' THEN '<b>Username cannot be blanked.</b>' 
	--			 WHEN FromCust = ToCust THEN '<b>From Cust must different To Cust.</b>' 
	--			 WHEN len(Description) > 200 THEN '<b>Maximum length of Description is 200 characters</b>' 				 
	--			 ELSE '<b>Invalid From Cust or To Cust.</b>' END AS Reason 	
	--FROM	(SELECT * FROM @tblCust WHERE Seq not in (SELECT Seq FROM @tblSucc)) AS temp
			
	
	SELECT * FROM @tblSucc ORDER BY MatchID, SMAName

	SELECT * FROM @tblFail ORDER BY MatchID, SMAName

END
GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnoverCheckList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnoverCheckList] TO [vnteam]