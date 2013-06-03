

/*
Rows affected: 5 ( do not need to put to execRep)
*/

SET NOCOUNT ON

DECLARE @MaxTransferP2P MONEY
DECLARE @IsAutoResetP2P BIT   
DECLARE @DISABLEP2P BIT   
DECLARE @DISABLEFUNP2P BIT   
DECLARE @sDiscount DECIMAL(9, 8)

DECLARE @tbl TABLE (custid INT)
DECLARE @custid INT

SET @custid = 98626  --- billma01

INSERT INTO @tbl 
	SELECT custid FROM custinfo WITH(NOLOCK) WHERE recommend = @custid


INSERT INTO @tbl 
	SELECT  2   ---- SA-RM
	UNION ALL
	SELECT 8619  ---- billma


/*
ACGUUS        615976
SA-UUS        20
*/
SELECT @MaxTransferP2P = 100000
		,@IsAutoResetP2P = 1
		,@DISABLEP2P = 0
		,@DISABLEFUNP2P = 0
		,@sDiscount = 0.67

/* BEGIN Bet Setting */
UPDATE custinfo WITH (ROWLOCK,UPDLOCK)
SET MaxTransferP2P	= @MaxTransferP2P
    ,IsAutoResetP2P	= @IsAutoResetP2P
    ,DISABLEP2P     = @DISABLEP2P
    ,DISABLEFUNP2P  = @DISABLEFUNP2P
WHERE custid IN (SELECT custid FROM @tbl)
/* End Bet Setting */


/* BEGIN Game Setting*/
INSERT INTO P2PGameSetting (custid,bettype,StakeLevel1,StakeLevel2,StakeLevel3,StakeLevel4,StakeLevel5    )
SELECT c.custid,t.bettype,1 ,1 ,1 ,1 ,1 
FROM custinfo c WITH(NOLOCK)
    CROSS JOIN (
				SELECT 1001 AS bettype
				UNION ALL       
				SELECT 1002 AS bettype
			   ) t
WHERE c.custid IN (SELECT custid FROM @tbl)
/* END Game Setting*/


/* BEGIN Commission*/
INSERT INTO P2PGroupComm (Custid,GroupID,sDiscount,aDiscount,Discount,PlayerDiscount)
SELECT c.custid, t.GroupID, CASE WHEN roleid = 4 THEN @sdiscount ELSE 0 END sDiscount
		,0 aDiscount, 0 Discount, 0 PlayerDiscount
FROM custinfo c WITH(NOLOCK)
    CROSS JOIN (    SELECT 1 GroupID       
					UNION ALL       
					SELECT 2 GroupID
				) t
WHERE c.custid IN (SELECT custid FROM @tbl)

/* END Commission*/