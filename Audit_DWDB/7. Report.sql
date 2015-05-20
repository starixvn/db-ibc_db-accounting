-- Jan
DECLARE @date smalldatetime, @maxdate smalldatetime

SET @date = '1 Jan 2012'
SELECT @maxdate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@date)+1,0))

CREATE TABLE ##TMP_date (dd smalldatetime)

WHILE @date <= @maxdate
BEGIN 
	INSERT INTO DWDB_2012.dbo.Report_12M01(
		transid, LCSid, custid, transdate, status, winlostdate, isBA, isInternal, matchid
	)
	SELECT transid
		,LCSid
		,custid
		,transdate
		,status
		,winlostdate
		,case ticketType WHEN 'ba' THEN 1 ELSE 0 END -- isBA
		,case ticketType WHEN 'internal' THEN 1 ELSE 0 END -- isInternal
		,matchid
	FROM bettrans_dw with(nolock)
	WHERE winlostdate = @date
	
	INSERT INTO ##TMP_date (dd) values (@date)
	SET @date = DATEADD(d, 1, @date)
END

select * from ##TMP_date order by 1
DROP TABLE ##TMP_date

-- then do the same thing for other months