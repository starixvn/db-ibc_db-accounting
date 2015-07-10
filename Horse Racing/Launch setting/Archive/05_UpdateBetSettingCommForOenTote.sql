ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@username VARCHAR(50),
	@SiteType VARCHAR(50) = '',
	@Action VARCHAR(50) = ''
AS

--Setting for Open Tote(bettype 41,42; sporttype 151)
--Note:
/*
	Customers under 8 currencies: update min/max/maxpermatch, autoIBC position taking and not to update agent PT, comm.
	Customers not under 8 currencies: update position taking, commission, min/max/maxpermatch, auto IBC positiont taking.
*/

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE name = 'custinfo')
BEGIN
	RETURN
END

DECLARE @custid INT, @currency INT, @roleid TINYINT,
    @minbet MONEY, @maxbet MONEY, @maxpermatch MONEY,
    @maxPT SMALLMONEY, @Comm SMALLMONEY, @allowHRcurrency BIT

SELECT @custid = custid, @currency = currency, @roleid = roleid 
FROM custinfo WITH (NOLOCK) WHERE username = @username

IF @currency IN (1,2,3,4,5,6,12,13,15,16,17,20,22,33,34,35,36,40,43,47)
	SET @allowHRcurrency = 1
ELSE 
	SET @allowHRcurrency = 0

PRINT 'AllowHRcurrency:' + CONVERT(VARCHAR(1),@allowHRcurrency)

IF (@roleid NOT IN (4,3,2,1)) 
    RETURN

CREATE TABLE #tempExchange (Currency INT, CurName VARCHAR(50),
                minbet MONEY, maxbet MONEY, maxpermatch MONEY)
                
CREATE UNIQUE CLUSTERED INDEX IX_1 ON #tempExchange (currency)


INSERT INTO #tempExchange([Currency], [CurName], [MinBet], [MaxBet], [MaxPerMatch])
SELECT 2, N'RM', 30, 40000, 80000 UNION ALL
SELECT 35, N'$US', 10, 15000, 30000 UNION ALL
SELECT 9, N'AUD', 10, 15000, 30000 UNION ALL
SELECT 46, N'BND', 10, 15000, 30000 UNION ALL
SELECT 21, N'CAD', 10, 5000, 10000 UNION ALL
SELECT 41, N'CHF', 10, 10000, 20000 UNION ALL
SELECT 47, N'DDD', 100, 120000, 240000 UNION ALL
SELECT 6, N'EURO', 10, 10000, 20000 UNION ALL
SELECT 12, N'GBP', 10, 10000, 20000 UNION ALL
SELECT 5, N'HK$', 50, 80000, 160000 UNION ALL
SELECT 33, N'IDD', 100, 120000, 240000 UNION ALL
SELECT 34, N'IDR', 100, 120000, 240000 UNION ALL
SELECT 15, N'IN', 100, 120000, 240000 UNION ALL
SELECT 22, N'IND', 100, 120000, 240000 UNION ALL
SELECT 40, N'IRR', 10, 15000, 30000 UNION ALL
SELECT 32, N'JPY', 700, 1000000, 2000000 UNION ALL
SELECT 30, N'NT', 300, 400000, 800000 UNION ALL
SELECT 17, N'NTD', 10, 15000, 30000 UNION ALL
SELECT 37, N'P', 10, 10000, 20000 UNION ALL
SELECT 42, N'PE', 300, 400000, 800000 UNION ALL
SELECT 44, N'PT', 100, 120000, 240000 UNION ALL
SELECT 31, N'Pts', 600, 4000000, 8000000 UNION ALL
SELECT 13, N'RMB', 50, 80000, 160000 UNION ALL
SELECT 1, N'SD$', 10, 20000, 40000 UNION ALL
SELECT 4, N'TB', 300, 400000, 800000 UNION ALL
SELECT 43, N'THB', 300, 400000, 800000 UNION ALL
SELECT 3, N'US$', 10, 15000, 30000 UNION ALL
SELECT 45, N'Won', 7000, 16000000, 32000000 UNION ALL
SELECT 36, N'Y$US', 10, 15000, 30000 UNION ALL
SELECT 16, N'Yen', 10, 15000, 30000 UNION ALL
SELECT 48, N'ZAR', 50, 80000, 160000 UNION ALL
SELECT 20, N'UUS', 10, 499, 1500



SELECT @minbet = minbet, @maxbet = maxbet, @maxpermatch = maxpermatch
FROM #tempExchange
WHERE currency = @currency

IF @SiteType IN ('Mansion88', 'AsiaBet88')
BEGIN
    SELECT @maxPT = 0, @Comm = 0.04
END
ELSE
BEGIN
    SELECT @maxPT = 0.5, @Comm = 0.01
END


IF @currency NOT IN (SELECT currency FROM #tempExchange)
BEGIN
    PRINT 'ERROR ACCOUNT: ' + @username
    RETURN
END

DROP TABLE #tempExchange

IF @roleid = 4
BEGIN
    UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
    SET maxpermatch151_OT = @maxpermatch
    WHERE srecommend = @custid

	UPDATE custSuper WITH(ROWLOCK,UPDLOCK)
	SET
		AutoIBCPositiontaking_Fixed = CASE
										WHEN @SiteType IN ('Mansion88', 'AsiaBet88') THEN 0.5
										ELSE 0
									  END
	WHERE custid = @custid
	
	IF @allowHRcurrency = 0
	    UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
		SET DisableOpenTote = CASE @Action
									WHEN 'disable' THEN 1
									WHEN 'enable' THEN 0                                    
									ELSE DisableOpenTote
								 END
		WHERE srecommend = @custid

END
IF NOT EXISTS  (SELECT COUNT(*) FROM dbo.sysobjects
                WHERE name IN ('custsetting3rd','custoverride3rd')
                    AND xtype = 'U'
                HAVING COUNT(*) = 2)
BEGIN
    RETURN
END

IF @roleid = 4
BEGIN
    UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
	SET	
        minbet = @minbet,
        maxbet = @maxbet
     WHERE sporttype = 151 AND bettype IN (41,42)
	    AND custid IN (SELECT custid FROM custinfo WITH (NOLOCK) WHERE srecommend = @custid)
	IF @allowHRcurrency = 0 
	BEGIN
		UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
		SET	
			sdiscount = @Comm,
			apositiontaking=0,
			mpositiontaking=0,
			spositiontaking=0,
			autopositiontaking=0,
			isautopositiontaking=0,
			autompositiontaking=0,
			isautompositiontaking=0,
			playerdiscount = 0,
			discount =0,
			adiscount=0
		 WHERE sporttype = 151 AND bettype IN (41,42)
			AND custid IN (SELECT custid FROM custinfo WITH (NOLOCK) WHERE srecommend = @custid)
	    UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
		SET
			apositiontaking=@maxPT, mpositiontaking=@maxPT, spositiontaking=@maxPT
		 WHERE sporttype = 151 AND bettype IN (41,42)
			AND custid = @custid
	    
		UPDATE custoverride3rd WITH(ROWLOCK,UPDLOCK)
		SET 
			minpositiontaking = 0, 
			maxpositiontaking = @maxPT
		WHERE sporttype = 151 AND bettype IN (41,42)
			AND custid IN (SELECT custid FROM custinfo WITH (NOLOCK) WHERE srecommend = @custid)

	END
END

IF @roleid = 3
BEGIN
	IF @allowHRcurrency = 0
	BEGIN
		UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
		SET        
			adiscount=@Comm       
		 WHERE sporttype = 151 AND bettype IN (41,42)
			AND custid IN (SELECT custid FROM custinfo WITH (NOLOCK) WHERE mrecommend = @custid)   	
	    
		UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
		SET    
			apositiontaking=0, mpositiontaking=@maxPT, spositiontaking=0
		 WHERE sporttype = 151 AND bettype IN (41,42)
			AND custid = @custid 
	END
END

IF @roleid = 2 AND @SiteType IN ('12Bet', 'Mansion88', 'AsiaBet88','Alog')
BEGIN	
	IF @allowHRcurrency = 0
	BEGIN
		UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
		SET
			apositiontaking=@maxPT, mpositiontaking=0, spositiontaking=0, 
			discount=@Comm       
		 WHERE sporttype = 151 AND bettype IN (41,42)
			AND custid IN (SELECT custid FROM custinfo WITH (NOLOCK) WHERE recommend = @custid)    
	END		
END

