ALTER PROCEDURE [dbo].[Acc_ExecRep_01]
	@AgentID	INT,
	@Type		BIT = 0 
WITH RECOMPILE	
AS 

/*
	Created by: Jamie
	Date: 2009-12-23
	Task: Archive unused Accounts 
	DB:DBTRANS.BODB02

	Revision:
				- 20110811@Kiwi: Keep Aus Tote for Horse Racing.
				- 20111007@Tom: Add table of P2P Game: P2PGameSetting, P2PGroupComm
				- 20111103@Lukas: Delete data in balance table
				- 20111130@Tom: 1. Add Check exist table ('P2PGameSetting','P2PGroupComm') before delete
								2. Add delete data of P2P Game: P2PGameSetting, P2PGroupComm in case of @Type = 1
				- 20120313@Lukas: Add deleting data of LiveCasino setting
				- 20130313@Thien: Change rowcount from 1000 to 10000
				- 20130913@Thien: Change from "Keep 7 typical/presentative records in custsetting" to "Delete all custseting records"
	Param's Explanation:
		@Type: 0-Stage 1 (enabled = 0); 1-Stage 2: 
 
*/
BEGIN
	IF @Type = 0 
	BEGIN 
		IF NOT EXISTS ( SELECT 1 FROM sys.tables WHERE Name='Custinfo') 
			RETURN
		ELSE 
		BEGIN
			WHILE (1=1)
			BEGIN 
				UPDATE TOP(10000) dbo.Custinfo WITH (UPDLOCK,ROWLOCK)
				SET		[enabled] = 0, closed = 1 
				WHERE	recommend = @AgentID AND ([enabled] = 1 OR closed = 0) 
				IF @@ROWCOUNT < 10000
					BREAK
			END 
		END 
		
		IF EXISTS (	
			SELECT COUNT(1) FROM sys.tables 
			WHERE Name IN('CustSetting','CustSetting3rd')
			HAVING COUNT(1) = 2 			
		)
		BEGIN
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.CustSetting WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) WHERE roleid = 1 AND recommend = @AgentID)
						
				IF @@ROWCOUNT < 10000 
					BREAK
			END
			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.CustSetting3rd WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) WHERE roleid = 1 AND recommend = @AgentID)
							
				IF @@ROWCOUNT < 10000
					BREAK			
			END
		END
	
		IF EXISTS ( SELECT COUNT(1) FROM sys.tables 
					WHERE Name IN ( 'P2PGameSetting','P2PGroupComm')
					HAVING COUNT(1) = 2 
			 )
		BEGIN			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.[P2PGameSetting] WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) 
									WHERE roleid = 1 
										AND recommend = @AgentID
										)
				IF @@ROWCOUNT < 10000 
					BREAK
			END			
			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.[P2PGroupComm] WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) 
										WHERE roleid = 1 
											AND recommend = @AgentID
											)
				IF @@ROWCOUNT < 10000 
					BREAK
			END				
		END		
		IF EXISTS (SELECT 1 FROM sys.tables WHERE name IN ('CustSettingGame'))
		BEGIN
			WHILE 1=1
			BEGIN
				DELETE TOP(10000) 
				FROM dbo.CustSettingGame WITH(ROWLOCK,UPDLOCK)	
				WHERE custid IN (SELECT custid 
								 FROM custinfo WITH(NOLOCK) 
								 WHERE roleid = 1 AND recommend = @AgentID
								)
				IF @@ROWCOUNT < 10000
					BREAK
			END
		END
		
	END 
	ELSE IF @Type = 1
	BEGIN
		IF EXISTS ( SELECT 1 FROM sys.tables WHERE Name='BalanceCredit') 		
		BEGIN
			WHILE (1=1)
			BEGIN
				DELETE TOP(10000) BalanceCredit WITH(ROWLOCK,UPDLOCK) 
				WHERE custid IN (	SELECT custid 
									FROM  Custinfo c WITH (NOLOCK)
									WHERE	c.roleid = 1 AND c.recommend = @AgentID 
								)
				IF @@ROWCOUNT < 10000
					BREAK
			END
		END

		IF EXISTS ( SELECT 1 FROM sys.tables WHERE Name='BalanceDebit') 		
		BEGIN
			WHILE (1=1)
			BEGIN
				DELETE TOP(10000) BalanceDebit WITH(ROWLOCK,UPDLOCK) 
				WHERE custid IN (	SELECT custid 
									FROM  Custinfo c WITH (NOLOCK)
									WHERE	c.roleid = 1 AND c.recommend = @AgentID 
								)
				IF @@ROWCOUNT < 10000
					BREAK
			END
		END
				
		IF EXISTS (
			SELECT COUNT(1) FROM sys.tables 
			WHERE Name IN ('Custinfo','Customer')
			HAVING COUNT(1) = 2 
		)
		BEGIN
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.Custinfo WITH (UPDLOCK,ROWLOCK)
				WHERE	roleid = 1 AND recommend = @AgentID 
				IF @@ROWCOUNT < 10000
					BREAK
			END 
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.Customer WITH (UPDLOCK,ROWLOCK)
				WHERE	roleid = 1 AND recommend = @AgentID 
				IF @@ROWCOUNT < 10000
					BREAK			
			END
		END
		
	END 
END 





GO
GRANT EXECUTE ON [dbo].[Acc_ExecRep_01] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_01] TO [vnteam] AS [dbo]