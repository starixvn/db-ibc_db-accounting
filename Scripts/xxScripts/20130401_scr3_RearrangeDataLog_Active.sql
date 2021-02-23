 
/*Acc_ExternalSettlement_Log: delete data with logdate < '2012-01-01'*/
-- rows affected 771851
WHILE 1 = 1  
BEGIN 
	DELETE TOP(10000) Acc_ExternalSettlement_Log WITH(ROWLOCK,UPDLOCK)
	WHERE LogDate < '2012-01-01'
	
	IF @@ROWCOUNT <> 10000
		BREAK
	WAITFOR DELAY '00:00:01'		
END



/* AgentFunctionUsage */
-- logdate < '2012-01-01' rows affected: 128267
WHILE 1 = 1  
BEGIN 
	DELETE TOP(10000) AgentFunctionUsage WITH(ROWLOCK,UPDLOCK)
	WHERE LogDate < '2012-01-01'
	
	IF @@ROWCOUNT <> 10000
		BREAK
	WAITFOR DELAY '00:00:01'		
END


/*CompanyBalance_History*/
-- rows affected: 1041
DELETE FROM CompanyBalance_History  WITH(ROWLOCK,UPDLOCK)
WHERE BalanceUpDay < '2012-01-01'



/* UserLog_Exchange */
-- rows affected: 3621
DELETE FROM UserLog_Exchange  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate < '2012-01-01'



/* UserLog_Login_Lrf */
-- rows affected: 19418
DELETE FROM UserLog_Login_Lrf  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate < '2012-01-01'




/* UserLog_Settle */
-- logdate < '2011-01-01' rows affected: 1274017
WHILE 1 = 1  
BEGIN 
	DELETE TOP(10000) UserLog_Settle WITH(ROWLOCK,UPDLOCK)
	WHERE LogDate < '2012-01-01'
	
	IF @@ROWCOUNT <> 10000
		BREAK
	WAITFOR DELAY '00:00:01'		
END



/* UserLog_Transaction */
-- rows affected: 577
DELETE FROM UserLog_Transaction  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate < '2012-01-01'


/* UserLog_UserControl_BK */
-- rows affected: 6282
DELETE FROM UserLog_UserControl_BK  WITH(ROWLOCK,UPDLOCK)
WHERE LogDate < '2012-01-01'
