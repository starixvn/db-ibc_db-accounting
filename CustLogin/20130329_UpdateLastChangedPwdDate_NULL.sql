 --CHECKING 
SELECT	COUNT(1) 
FROM	CustLoginInfo l WITH (NOLOCK) 
		INNER JOIN customer c WITH (NOLOCK) ON l.custid = c.custid 
where	c.PWDexpiry ='2013-03-29'
		AND c.roleid between 2 and 4

--658639 row affected 

	UPDATE	CustLoginInfo WITH (UPDLOCK,ROWLOCK)
	SET		LastChangedPwd = NULL 
	FROM	CustLoginInfo l 
			INNER JOIN customer c WITH (NOLOCK) ON l.custid = c.custid 
	WHERE	c.PWDexpiry ='2013-03-29'
			AND c.roleid between 2 and 4
			

			