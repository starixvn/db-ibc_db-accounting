ALTER PROCEDURE [dbo].[Acc_CustomerSelClearBalance]
	@custid INT
WITH RECOMPILE
AS
SET NOCOUNT ON
/*
Created: 
Task : Clear Balance
DB: DBACC.bodb02
Original:

Revisions:
	- 20100709@Khoa: add more column SyncCasino
	- 20110517@Lukas: re-arrange bettype
	- 20110830@Jamie: COUNT phonebetting's negative stake as positive number
	- 20140305@Dom: Update outstanding for keno
Param's Explanation:
	
*/  
 SET NOCOUNT ON 
 DECLARE @NegativeBetEffectiveDate datetime,@TranslogOT money
 SET @NegativeBetEffectiveDate='2011-09-01'
 DECLARE @currentDate datetime 
 SELECT @currentDate = convert(varchar(10), current_timestamp, 120)

 SELECT 
	c.username,
	c.custid,
	c.closed,
	c.firstname,
	c.lastname,
	isnull(b.outstanding,0)+ISNULL(translog.TranslogOT,0) outstanding,
	isnull(b.balance,0) balance,
	(isnull(b.balance,0) - isnull(today_balance.y_balance,0)) yesterday_balance,
	c.credit AS credit,
	@custid as member_recommend,
	member_mrecommend,
	SyncCasino
 FROM 
	 (	SELECT 
			customer.custid, 
			customer.username, 
			ci.closed, 
			customer.firstname, 
			customer.lastname,
			ci.credit,
			customer.mrecommend as member_mrecommend,
			ci.SyncCasino
		FROM 
			customer WITH (NOLOCK)
			INNER JOIN CustInfo as ci with (NOLOCK) on Customer.CustID = ci.custid
		WHERE 
			customer.recommend = @custid AND
			customer.roleid = 1
	) AS c 
	LEFT JOIN 
        ( SELECT custid, 
				 isnull(SUM(CASE WHEN ruben=0 THEN (CASE WHEN winlostdate <@NegativeBetEffectiveDate THEN actual_stake ELSE ABS(actual_stake) END) END),0) outstanding,
				 isnull(SUM(CASE WHEN ruben=1 THEN winlost-actual_stake+playercomm END), 0) balance
		  FROM bettrans  WITH (NOLOCK)
		  WHERE recommend =@custid 
		  GROUP BY custid
		) AS b 	ON c.custid = b.custid
	LEFT JOIN 
		( SELECT custid, 
				 SUM( winlost-actual_stake+playercomm) y_balance
		  FROM bettrans  WITH (NOLOCK)
		  WHERE recommend =@custid AND ruben =1 AND bettype < 19001 
				AND winlostdate >= convert(varchar(10), CURRENT_TIMESTAMP, 120)
		  GROUP BY custid
		) today_balance on c.custid = today_balance.custid 
	LEFT JOIN 
		(
			SELECT TranslogOT = SUM(ABS(actual_stake)),
					custid
			 FROM translog(NOLOCK) WHERE recommend = @custid
			 GROUP BY custid
		) translog on translog.custid = c.custid

ORDER BY closed, username