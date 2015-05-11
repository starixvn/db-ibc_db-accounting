USE [bodb_dwrs]
GO
/****** Object:  StoredProcedure [dbo].[Acc_SelTopPunterByCustID]    Script Date: 12/13/2012 04:09:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_SelTopPunterByCustID    Script Date: 11/9/2012 8:52:19 AM ******/

/*
	exec Acc_SelTopPunterByCustID_xtest
@fromdate='2012-01-01 00:00:00:000',
@todate='2012-01-31 00:00:00:000',
@sporttype=N'0',@custid=3293,@orderby=1,@ordertype=1,@debug=1 
*/
ALTER PROCEDURE [dbo].[Acc_SelTopPunterByCustID]
	@CustID int=null,
	@UserName varchar(30) = Null,
	@Sporttype VARCHAR(1000)=NULL,
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@OrderBy tinyint = 1,
	@OrderType bit = 0,
	@debug 	bit=0
AS
/*
Created: 20100211@Phuc
Task : Get winlost/turnover by custid
DB: DBDW2.bodb_dwrs

Revisions:
20111130@Jim:
		+Support new bettype (1x2 Asia Handicap):change condition (bettype<31 OR bettype=1001 )=> (((bettype NOT BETWEEN 31 AND 120) AND bettype <=999) and bettype <> 9)
20120525@Jim:  add more betcount column in result return
20121030@Jim:  Change IBC's Turnover & Winloss to Member's Turnover & Winloss
20121213@Dan: Change linked server from DB052-->DBEXT   

Param's Explanation:
*/
SET NOCOUNT ON
DECLARE @SQL nvarchar(MAX)

SELECT @SQL=+'DECLARE @curmonth smalldatetime'+char(13)+
			'SET @curmonth='''+Convert(varchar(10),@Fromdate,120)+''''+char(13)+
			'DECLARE @MonthYear table(rptmonth int, rptyear int)'+char(13)+
			'WHILE (@Curmonth<'''+Convert(varchar(10),@ToDate,120)+''''+')'+char(13)+
			'BEGIN '+char(13)+
			'insert into @MonthYear(rptmonth, rptyear)
			values(month(@curmonth), year(@curmonth))
			select @curmonth = dateadd(month,1,@curmonth)'+char(13)+
			'END '+char(13)
SELECT @SQL=@SQL+'BEGIN'+char(13)
IF @Sporttype<>'0'
BEGIN
SELECT @SQL=@SQL+'DECLARE  @tblSporttype  AS TABLE (Sporttype INT )
				  INSERT INTO @tblSporttype 
			      SELECT VAL FROM bodb02.dbo.strSplit('''+@sporttype+''','','')'+char(13)
END
IF ISNULL(@UserName,'')<>''
BEGIN
SELECT @SQL=@SQL+'	
	DECLARE @usr INT 
	SELECT @usr=CustID FROM bodb02.dbo.customer with (NOLOCK)
	WHERE username ='''+@Username+''' OR username2='''+@Username+'''
	'+char(13)
END 	
SELECT @SQL=@SQL+'SELECT 
			CustID,SportName, SportType, winloss, turnover, Margin,Betcount,'+
			CASE
				WHEN @orderby = 1 and @ordertype = 0 THEN 'result.winloss'
				WHEN @orderby = 2 and @ordertype = 0 THEN 'result.turnover'
				WHEN @orderby = 3 and @ordertype = 0 THEN 'result.margin'
				ELSE 'NULL'+char(13)
			END +char(13)+'AS SortASC,'+char(13)+
			CASE
				WHEN @orderby = 1 and @ordertype = 1 THEN 'result.winloss'
				WHEN @orderby = 2 and @ordertype = 1 THEN 'result.turnover'
				WHEN @orderby = 3 and @ordertype = 1 THEN 'result.margin'
				ELSE 'NULL'+char(13)
			END +char(13)+'AS SortDESC'+char(13)+
		'FROM'+char(13)

SELECT @SQL=@SQL+
'
(			select 
				cl.custid,
				s.sportname SportName,
				s.sporttype SportType,
				sum(winloss) winloss,
				sum(stake)   turnover,
				sum(winloss)/(case when isnull(sum(stake),0) = 0 then 1 else sum(stake) end) as Margin,
				sum(isnull(cl.betcount,0)) as Betcount
			from bodb_Account.dbo.rptCustomerLeague cl WITH (nolock)
				inner join @MonthYear my on my.rptmonth = cl.rptmonth and my.rptyear = cl.rptyear
				inner join bodb02.dbo.League l WITH (nolock) on cl.leagueid = l.leagueid
				inner join bodb02.dbo.customer c WITH (NOLOCK) ON cl.CustID=c.CustID
				inner join DBEXT.bodb02.dbo.Sports s With (NOLOCK) ON l.sporttype=s.sporttype'+char(13)+
				CASE WHEN @Sporttype<>'0' THEN 'inner join @tblSporttype st ON l.sporttype=st.sporttype' ELSE '' END+char(13)+
				'
				WHERE 
				(
					( cl.bettype NOT  BETWEEN 31 AND 120 ) and ( cl.bettype <= 999 OR cl.bettype = 18999 )
				)
				and cl.bettype not in (9,29)'+char(13)
			+CASE WHEN 	ISNULL(@CustID,'')<>'' THEN 'AND cl.CustID='''+CONVERT(VARCHAR,@CustID)+'''' ELSE '' END +char(13)+
			'group by cl.custid ,s.sportname ,s.sporttype'+char(13)+
			'UNION ALL '+char(13)+
			'SELECT cl.CustID, '' Parlay''AS SportName,100 as Sporttype,
			sum(winloss) winloss,
			sum(stake) turnover,
			sum(winloss)/(case when isnull(sum(stake),0) = 0 then 1 else sum(stake) end) as Margin,
			sum(isnull(cl.betcount,0)) as Betcount
			FROM bodb_Account.dbo.rptCustomerLeague cl WITH (nolock)
			INNER JOIN  @MonthYear my on my.rptmonth = cl.rptmonth and my.rptyear = cl.rptyear
			INNER JOIN  bodb02.dbo.League l (nolock) on cl.leagueid = l.leagueid
			INNER JOIN  bodb02.dbo.customer c (NOLOCK) ON cl.CustID=c.CustID
			'+char(13)+
			'WHERE  cl.bettype in (9,29)'+char(13)+
			CASE WHEN ISNULL(@CustID,'')<>'' THEN 'AND cl.custid ='''+CONVERT(VARCHAR,@CustID)+''''ELSE '' END +char(13)+
			'GROUP BY cl.CustID '+char(13)+
')result'+char(13)+
CASE WHEN ISNULL(@UserName,'')<>'' THEN 'WHERE result.CustID=@usr' ELSE '' END+char(13)+
'order by SortASC, SortDESC desc'+char(13)
SELECT @SQL=@SQL+'END'+char(13)
IF (@debug=1)
	PRINT @SQL
exec sp_executesql @sql