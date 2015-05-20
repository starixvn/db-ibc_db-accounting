ALTER PROCEDURE [dbo].[DBA_ArchiveAccount2_Rollback_Balance]
	@minCustID INT,	
	@Step INT,
	@index INT, 
	@AgentID INT,
	@roleid INT
AS
BEGIN
	CREATE TABLE #Member (custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int)
	
	IF @roleid = 2
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
		FROM DBARCCUST.bodb_Customer.dbo.custinfo_old c (nolock)			
		WHERE  c.recommend = @AgentID AND c.roleid = 1
			AND custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
			
	END
	IF @roleid = 3
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
		FROM DBARCCUST.bodb_Customer.dbo.custinfo_old c (nolock)		
		WHERE c.mrecommend = @AgentID AND c.roleid = 1			
			AND custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
		
	END
	IF @roleid = 4
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
		FROM DBARCCUST.bodb_Customer.dbo.custinfo_old c (nolock)
		WHERE c.srecommend = @AgentID AND c.roleid = 1		
			AND custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
	END
	
	INSERT INTO BalanceCredit
			SELECT custid, 0
			FROM #Member WITH (NOLOCK) 

	INSERT INTO BalanceDebit
			SELECT custid, 0
			FROM #Member WITH (NOLOCK) 
	DROP TABLE #Member
END

GO
GRANT EXECUTE ON [dbo].[DBA_ArchiveAccount2_Rollback_Balance] TO [bodbadminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount2_Rollback_Balance] TO [vnteam] AS [dbo]