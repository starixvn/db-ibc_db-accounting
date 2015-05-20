---starlit

USE DWDB
GO

DROP TABLE TEMP

CREATE TABLE [dbo].[TEMP](
	[mm] tinyint NOT NULL,
	[fromdate] [datetime] NOT NULL,
	[todate] [datetime] NOT NULL,
	[status] [varchar](10) NOT NULL,
	[updatetime] [datetime] NULL
) ON [DATA]

INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (1, '1 Jan 2012', '31 Jan 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (2, '1 Feb 2012', '29 Feb 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (3, '1 Mar 2012', '31 Mar 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (4, '1 Apr 2012', '30 Apr 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (5, '1 May 2012', '31 May 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (6, '1 Jun 2012', '30 Jun 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (7, '1 Jul 2012', '31 Jul 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (8, '1 Aug 2012', '31 Aug 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (9, '1 Sep 2012', '30 Sep 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (10, '1 Oct 2012', '31 Oct 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (11, '1 Nov 2012', '30 Nov 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (12, '1 Dec 2012', '31 Dec 2012', '')


UPDATE TEMP SET status = '', updatetime = NULL

WHILE (1 = 1)
BEGIN
	DECLARE @mm tinyint, @fromdate datetime, @todate datetime

	SELECT TOP 1 @mm = mm 
	FROM TEMP with(nolock) 
	where status <> 'done'
	order by 1
	
	IF @@ROWCOUNT = 0 BREAK

	UPDATE TEMP
	SET status = 'processing'
		,updatetime = CURRENT_TIMESTAMP
		,@fromdate = fromdate
		,@todate = todate
	WHERE mm = @mm
	
	--SELECT @mm, @fromdate, @todate	
				
	------ start copying ------------------------	
		update b
		set tickettype = 'BA'
		from bettrans_dw b
			inner join dbo.LicenseeBATransaction_bk ba with(nolock) on b.transid = ba.transid
		where b.winlostdate between @fromdate and @todate
		
	------/ finished copying -----------------------------	
	
	UPDATE TEMP
	SET status = 'done'
		,updatetime = CURRENT_TIMESTAMP
	WHERE mm = @mm		
END
	
select * from TEMP	

-----


----------------------- TEST -----------------------
USE DWDB
GO

DROP TABLE TEMP

CREATE TABLE [dbo].[TEMP](
	[mm] tinyint NOT NULL,
	[fromdate] [datetime] NOT NULL,
	[todate] [datetime] NOT NULL,
	[status] [varchar](10) NOT NULL,
	[updatetime] [datetime] NULL
) ON [DATA]

INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (1, '1 Jan 2012', '31 Jan 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (2, '1 Feb 2012', '29 Feb 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (3, '1 Mar 2012', '31 Mar 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (4, '1 Apr 2012', '30 Apr 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (5, '1 May 2012', '31 May 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (6, '1 Jun 2012', '30 Jun 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (7, '1 Jul 2012', '31 Jul 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (8, '1 Aug 2012', '31 Aug 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (9, '1 Sep 2012', '30 Sep 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (10, '1 Oct 2012', '31 Oct 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (11, '1 Nov 2012', '30 Nov 2012', '')
INSERT INTO DWDB.dbo.TEMP (mm, fromdate, todate, status) values (12, '1 Dec 2012', '31 Dec 2012', '')


UPDATE TEMP SET status = '', updatetime = NULL

WHILE (1 = 1)
BEGIN
	DECLARE @mm tinyint, @fromdate datetime, @todate datetime

	SELECT TOP 1 @mm = mm 
	FROM TEMP with(nolock) 
	where status <> 'done'
	order by 1
	
	IF @@ROWCOUNT = 0 BREAK

	UPDATE TEMP
	SET status = 'processing'
		,updatetime = CURRENT_TIMESTAMP
		,@fromdate = fromdate
		,@todate = todate
	WHERE mm = @mm
	
	--SELECT @mm, @fromdate, @todate	
				
	------ start copying ------------------------	
		update b
		set isBA = 1
		from bettrans_test b
			inner join dbo.LicenseeBATransaction_bk ba with(nolock) on b.transid = ba.transid
		where b.winlostdate between @fromdate and @todate
		
	------/ finished copying -----------------------------	
	
	UPDATE TEMP
	SET status = 'done'
		,updatetime = CURRENT_TIMESTAMP
	WHERE mm = @mm		
END
	
select * from TEMP	