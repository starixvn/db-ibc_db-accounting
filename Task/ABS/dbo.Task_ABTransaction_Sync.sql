ALTER PROCEDURE [dbo].[Task_ABTransaction_Sync]
	@punterid	INT,
	@custid		INT =0,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 23Dec2011
		Task: Synchronize old transactions after adding new customer
		DB: DB052.BODB02
		
		Revisions:
		
		Parameters Explanation:
	*/ 
SET NOCOUNT ON
	
	IF @custid <> 0
	BEGIN
		WHILE (1=1)
		BEGIN
			INSERT INTO ABTransaction (transid, punterid, custid)
			SELECT top 20000 b.transid , @punterid , @custid 
			FROM
				bettrans b WITH(NOLOCK)
				INNER JOIN match m WITH(NOLOCK) ON b.matchid = m.matchid
			WHERE b.custid = @custid
				AND b.transid NOT IN (SELECT transid FROM ABTransaction WITH(NOLOCK) WHERE custid = @custid)
				AND b.bettype IN (1,3,5,7,8,15)
				AND m.sporttype = 1
			
			IF @@ERROR > 0
			BEGIN
				SELECT @ErrCode = 100,
					@ErrMsg = 'Synchronize data fail.'
				RETURN
			END
			
			IF @@ROWCOUNT < 20000
				BREAK
		END
	END
	ELSE 
	BEGIN 
		WHILE (1=1)
		BEGIN
			INSERT INTO ABTransaction (transid, punterid, custid)
			SELECT top 20000 b.transid , ab.punterid , ab.custid 
			FROM
				ABCustomer ab WITH(NOLOCK)
				INNER JOIN bettrans b WITH(NOLOCK) ON ab.custid = b.custid
				INNER JOIN match m WITH(NOLOCK) ON b.matchid = m.matchid
			WHERE ab.punterid = @punterid
				AND b.transid NOT IN (SELECT transid FROM ABTransaction WITH(NOLOCK) WHERE custid IN (SELECT custid FROM ABCustomer WITH(NOLOCK) WHERE punterid = @punterid))
				AND b.bettype IN (1,3,5,7,8,15)
				AND m.sporttype = 1
			
			IF @@ERROR > 0
			BEGIN
				SELECT @ErrCode = 100,
					@ErrMsg = 'Synchronize data fail.'
				RETURN
			END
			
			IF @@ROWCOUNT < 20000
				BREAK
		END
	END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_ABTransaction_Sync] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Task_ABTransaction_Sync] TO [bodbAdminNet]