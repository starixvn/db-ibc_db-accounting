ALTER PROCEDURE [dbo].[Acc_ExecRep_Cust_01]
	@AgentID	INT,
	@Type		BIT = 0 
WITH RECOMPILE	
AS 
/*
	Created by: Elodie
	Date: 2013-08-08
	Task: Archive unused Accounts 
	DB: DBTXN/CustDB
	Original: Acc_ExecRep_01
	Revision:
		- 20131230@Elodie: Update credit = 0 when account is disabled, check correct server name 
		- 201406180@Elodie: Remove setting of Keno
		- 20150514@Elodie: Apply CustVirtualRate table
	   	- 20150610@Daniel: 
		   + Improve medthod check table existing in subscribers	
		   + Separate custDB to new server DBCUST		
		- 20150808@Elodie: Balance Improvement [Redmine:#40125]	
		- 20151029@Billy: Using new Virtual Rate structure - Apply CustVirtualSetting table [Redmine: #46541]

	Param's Explanation:
		@Type: 0-Stage 1 (enabled = 0); 1-Stage 2: 
 
*/
BEGIN
	IF @Type = 0 
	BEGIN 
		IF dbo.f_CheckRepTable('Custinfo') = 0
			RETURN
		ELSE 
		BEGIN
			WHILE (1=1)
			BEGIN 
				UPDATE TOP(10000) dbo.Custinfo WITH (UPDLOCK,ROWLOCK)
				SET		[enabled] = 0, closed = 1, credit = 0
				WHERE	recommend = @AgentID AND ([enabled] = 1 OR closed = 0) 
				IF @@ROWCOUNT < 10000
					BREAK
			END 
		END 
		
		IF dbo.f_CheckRepTable('CustVirtualRate') = 1
		BEGIN
			WHILE 1=1
			BEGIN
				DELETE TOP(10000) 
				FROM dbo.CustVirtualRate WITH(ROWLOCK,UPDLOCK)	
				WHERE custid IN (SELECT custid 
								 FROM custinfo WITH(NOLOCK) 
								 WHERE roleid = 1 AND recommend = @AgentID
								)
				IF @@ROWCOUNT < 10000
					BREAK
			END
		END

		IF dbo.f_CheckRepTable('CustVirtualSetting') = 1
		BEGIN
			WHILE 1=1
			BEGIN
				DELETE TOP(10000)
				FROM dbo.CustVirtualSetting WITH(ROWLOCK,UPDLOCK)
				WHERE custid IN (SELECT custid 
								 FROM custinfo WITH(NOLOCK) 
								 WHERE roleid = 1 AND recommend = @AgentID
								)
				IF @@ROWCOUNT < 10000
					BREAK
			END
		END


	     IF (dbo.f_CheckRepTable('CustSetting') = 1 
		  AND dbo.f_CheckRepTable('CustSetting3rd') = 1 
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
	
	     IF (dbo.f_CheckRepTable('P2PGameSetting') = 1 
		  AND dbo.f_CheckRepTable('P2PGroupComm') = 1 
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

	     IF (dbo.f_CheckRepTable('CustSettingGame') = 1 
		  AND dbo.f_CheckRepTable('CustGameType') = 1 
	     )
		BEGIN			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.[CustSettingGame] WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) 
									WHERE roleid = 1 
										AND recommend = @AgentID
										)
				IF @@ROWCOUNT < 10000 
					BREAK
			END			
			
			WHILE(1=1)
			BEGIN
				DELETE TOP(10000) dbo.[CustGameType] WITH (UPDLOCK,ROWLOCK)
				WHERE	custid IN (SELECT custid FROM Custinfo WITH (NOLOCK) 
										WHERE roleid = 1 
											AND recommend = @AgentID
											)
				IF @@ROWCOUNT < 10000 
					BREAK
			END				
		END		

		
		
	END 
	ELSE IF @Type = 1
	BEGIN
		IF @@SERVERNAME = 'DBTRANS'
		BEGIN
			--IF dbo.f_CheckRepTable('BalanceCredit') = 1 				
			--BEGIN
			--	WHILE (1=1)
			--	BEGIN
			--		DELETE TOP(10000) bodb02.dbo.BalanceCredit WITH(ROWLOCK,UPDLOCK) 
			--		WHERE custid IN (	SELECT custid 
			--							FROM  Custinfo c WITH (NOLOCK)
			--							WHERE	c.roleid = 1 AND c.recommend = @AgentID 
			--						)
			--		IF @@ROWCOUNT < 10000
			--			BREAK
			--	END
			--END

			--IF dbo.f_CheckRepTable('BalanceDebit') = 1 		
			--BEGIN
			--	WHILE (1=1)
			--	BEGIN
			--		DELETE TOP(10000) bodb02.dbo.BalanceDebit WITH(ROWLOCK,UPDLOCK) 
			--		WHERE custid IN (	SELECT custid 
			--							FROM  Custinfo c WITH (NOLOCK)
			--							WHERE	c.roleid = 1 AND c.recommend = @AgentID 
			--						)
			--		IF @@ROWCOUNT < 10000
			--			BREAK
			--	END
			--END
			IF dbo.f_CheckRepTable('BalCreditSports') = 1 				
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalCreditSports WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END

			IF dbo.f_CheckRepTable('BalDebitSports') = 1 		
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalDebitSports WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END
			IF dbo.f_CheckRepTable('BalCreditCasino') = 1 				
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalCreditCasino WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END

			IF dbo.f_CheckRepTable('BalDebitCasino') = 1 		
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalDebitCasino WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END
			IF dbo.f_CheckRepTable('BalCreditOthers') = 1 				
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalCreditOthers WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END

			IF dbo.f_CheckRepTable('BalDebitOthers') = 1 		
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalDebitOthers WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END
			IF dbo.f_CheckRepTable('BalCreditTransfer') = 1 				
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalCreditTransfer WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END

			IF dbo.f_CheckRepTable('BalDebitTransfer') = 1 		
			BEGIN
				WHILE (1=1)
				BEGIN
					DELETE TOP(10000) bodb02.dbo.BalDebitTransfer WITH(ROWLOCK,UPDLOCK) 
					WHERE custid IN (	SELECT custid 
										FROM  Custinfo c WITH (NOLOCK)
										WHERE	c.roleid = 1 AND c.recommend = @AgentID 
									)
					IF @@ROWCOUNT < 10000
						BREAK
				END
			END
		END
				
	     IF (dbo.f_CheckRepTable('Custinfo') = 1 
		  AND dbo.f_CheckRepTable('Customer') = 1 
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