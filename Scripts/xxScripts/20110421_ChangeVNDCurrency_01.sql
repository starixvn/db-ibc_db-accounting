/*
--Check duplicated Q character with Dummy Transfer Account
select username from custinfo(nolock)
where currency = 51 
and roleid = 1 
and username like '%Q%'
and srecommend in (51, 3167456, 3167631, 3167992, 3287311, 3287405, 3353831, 3353983, 3417070, 3417217, 3651223, 3663860)
and recommend in (select custid from custinfo(nolock) where username like '%ACC%' and roleid =2)

--Check duplicated Q character in custinfo/customer
select count(1) from custinfo(nolock)
where username like '%Q%Q%'
and srecommend in (51, 3167456, 3167631, 3167992, 3287311, 3287405, 3353831, 3353983, 3417070, 3417217, 3651223, 3663860)
and currency = 51 

--Check duplicated Q character in custSub table
select count(1) from custsub(nolock)
WHERE custid in (select custid 
					from custinfo(nolock) 
					where srecommend IN (51,3167456,3167631,3167992,3287311,3287405,3353831,3353983,3417070,3417217,3651223,3663860) 
							and roleid =2)
and username like '%Q%Q%'
*/


EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 51
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3167456
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3167631
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3167992
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3287311
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3287405
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3353831
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3353983
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3417070
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3417217
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3651223
GO
EXEC [Acc_ExecRep_09] @Mode =1,	@srecommend = 3663860

/*
	@Mode = 1: Update [Customer]
	@Mode = 2: Update [custInfo]
	@Mode = 3: Update [bettrans]
	@Mode = 4: Update [sum_winloss]
	@Mode = 5: Update [bettrans14]
	srecommend in(51,3167456,3167631,3167992,3287311,3287405,3353831,
					3353983,3417070,3417217,3651223,3663860)
*/

ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@Mode int,
	@srecommend int
AS

/*
	@Mode = 1: Update [Customer]
	@Mode = 2: Update [custInfo]
	@Mode = 3: Update [bettrans]
	@Mode = 4: Update [sum_winloss]
	@Mode = 5: Update [bettrans14]
*/
IF @Mode = 1
BEGIN 
	IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'Customer' AND TYPE = 'u')
	BEGIN
		RETURN
	END

	WHILE (1=1)
	BEGIN
		UPDATE TOP(1000) [dbo].[Customer] WITH (ROWLOCK, UPDLOCK)
		set username = replace (username, 'Q', 'INH')
		WHERE srecommend = @srecommend
			and username like '%Q%' and currency = 51
		IF @@ROWCOUNT < 1000
			BREAK
	END	
END
ELSE IF @Mode = 2
BEGIN
	IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custInfo' AND TYPE = 'u')
	BEGIN
		RETURN
	END

	WHILE (1=1)
	BEGIN
		UPDATE TOP(1000) [dbo].[custinfo] WITH (ROWLOCK, UPDLOCK)
		set username = replace (username, 'Q', 'INH')
		WHERE srecommend  = @srecommend
			and username like '%Q%' and currency = 51
		IF @@ROWCOUNT < 1000
			BREAK
	END
END
ELSE IF @Mode = 3
BEGIN 
	IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'bettrans' AND TYPE = 'u')
	BEGIN
		RETURN
	END
	ELSE
	BEGIN
		WHILE (1=1)
		BEGIN	
			UPDATE TOP(5000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK)
			SET currencyname = 'INH',
				username = replace(username, 'Q', 'INH')
			WHERE currency = 51 and currencyname <> 'INH' 
				and srecommend = @srecommend 
	    	
			IF  @@ROWCOUNT < 5000
				BREAK 
			WAITFOR DELAY '000:00:00.200'      
		END
	END
END
ELSE IF @Mode = 4
BEGIN
	IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'sum_winloss' AND TYPE = 'u')
	BEGIN
		RETURN
	END
	ELSE
	BEGIN
		WHILE (1=1)
		BEGIN	
			UPDATE TOP(2000) [dbo].[sum_winloss] WITH (ROWLOCK, UPDLOCK)
			SET username = replace(username, 'Q', 'INH')
			WHERE username like '%Q%'
				 and srecommend = @srecommend
	    	
			IF  @@ROWCOUNT < 2000
				BREAK
			WAITFOR DELAY '000:00:00.200'        
		END 
	END
END
ELSE IF @Mode = 5
BEGIN
	IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'bettrans14' AND TYPE = 'u')
	BEGIN
		RETURN
	END
	ELSE
	BEGIN
		WHILE (1=1)
		BEGIN	
			UPDATE TOP(2000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK)
			SET currencyname = 'INH',
				username = replace(username, 'Q', 'INH')
			WHERE currency = 51 and currencyname <> 'INH' 
				and srecommend = @srecommend 
	    	
			IF  @@ROWCOUNT < 2000
				BREAK
			WAITFOR DELAY '000:00:00.200'         
		END 
	END
END
GO
GRANT EXECUTE ON [dbo].[Acc_ExecRep_09] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_09] TO [vnteam]