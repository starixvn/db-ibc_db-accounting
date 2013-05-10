
ALTER PROCEDURE [dbo].[Acc_DailyTxn_Sel]
	@fromdate	datetime,	
	@Type		nvarchar(30) = '',
	@Creator	varchar(30) = '',
	@checkerID	TINYINT = 1 ,
	@checkerName varchar(50) = ''
as

/*
Created by: Jamie
Date: 2010-09-18
Task : Daily Transaction 
DB: DB06.bodb02
Original: Acc_RptStatementDaily

Revisions:
	- 20101124@Kevin: Add new parameter is @checkerName. 
	Select all transactions what verified by that user.	
	- 20101225@Lukas: Re-arrange bettype
	- 20111015@Lukas: remove paging

Param's Explanation: Daily transaction
	@Type   : Dep, Trac, ..
	@Creator: Admin's useranme
	@checkerID: 0 - Unverified ; 1 - All; 2 - Verified
*/
BEGIN
SET NOCOUNT ON


create table #StatementDaily
(	
	transid bigint,
	refno bigint,
	username varchar(50), 
	checkerID int,
	checkerName varchar(50),
	checkTime datetime,
	transdate smalldatetime, 
	amount money, 
	transdesc nvarchar(300), 
	typenamee nvarchar(30), 
	creator varchar(30)
)

IF @checkerID in (0,1)
begin 
	insert into #StatementDaily
	SELECT	b.transid,
			b.refno,
			b.username,
			b.betid, --checkerID 
			b.betcheck, --checkerName
			b.checkTime, 
			b.transdate,
			b.winlost-b.actual_stake amount,
			b.transdesc, 
			bt.typenamee,
			creator.username creator
	FROM bettrans b with (nolock)
		inner join CustSuper s with (nolock) on b.srecommend = s.custid 
		inner join customer creator WITH (NOLOCK) on creator.custid=b.creator
		inner join bettype bt WITH (NOLOCK) on bt.typeid=b.bettype
	WHERE
		bt.typeid>20000 AND
		b.MatchID=0 and
		creator.roleid>4 and
		s.isInternal = 1 and 
		b.winlostdate between @fromdate and Dateadd(d,1,@fromdate) and
		case when @Type <> '' then bt.typenamee else @Type end = @Type and
		case when @Creator <> '' then creator.username else @Creator end = @Creator and 	
		case when @checkerName <> '' and @checkerID = 1 then b.betcheck else @checkerName end = @checkerName 
			and
		case   
			when @checkerID = 0 then ISNULL(b.betid,0)
			when @checkerID = 1 then @checkerID  				
			end = @checkerID 
	
end 
ELSE 
BEGIN
	INSERT INTO #StatementDaily
	SELECT	b.transid,
			b.refno,
			b.username,
			b.betid, --checkerID 
			b.betcheck, --checkerName
			b.checkTime, 
			b.transdate,
			b.winlost-b.actual_stake amount,
			b.transdesc, 
			bt.typenamee,
			creator.username creator
	FROM bettrans b WITH(NOLOCK)
		inner join CustSuper s WITH(NOLOCK) ON b.srecommend = s.custid 
		inner join customer creator WITH(NOLOCK) ON creator.custid=b.creator
		inner join bettype bt WITH(NOLOCK) ON bt.typeid=b.bettype
	WHERE
		bt.typeid>20000 AND
		b.MatchID=0 and
		creator.roleid>4 and
		s.isInternal = 1 and 
		b.winlostdate between @fromdate and Dateadd(d,1,@fromdate) and
		case when @Type <> '' then bt.typenamee else @Type end = @Type and
		case when @Creator <> '' then creator.username else @Creator end = @Creator and
		case when @checkerName <> '' then b.betcheck else @checkerName end = @checkerName and
		ISNULL(b.betid,0)<> 0 
END 



SELECT * 
FROM #StatementDaily
ORDER BY transid

DROP TABLE #StatementDaily 

END






GO
GRANT EXECUTE ON [dbo].[Acc_DailyTxn_Sel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_DailyTxn_Sel] TO [vnteam]

