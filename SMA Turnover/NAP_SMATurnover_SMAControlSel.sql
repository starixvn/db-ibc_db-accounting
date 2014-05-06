ALTER PROCEDURE [dbo].[NAP_SMATurnover_SMAControlSel]
	@SMAName VARCHAR(30) = ''
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve configure TO information by SMA
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_SMAControlSel @SMAName = 'Super'
	
*/
BEGIN
	SET NOCOUNT ON
	
	IF @SMAName = ''
	BEGIN
		SELECT c.UserName, c.custid, c.roleid, e.currency, c.credit, sma.Offset
		FROM DownlineTo_SMAControl sma WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON sma.SMAID = c.custID
			INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON e.exchangeid = c.currency
		ORDER BY c.UserName
	END
	ELSE
	BEGIN		
		SELECT ci.UserName, ci.custid, ci.roleid, e.currency, ci.credit, sma.Offset
		FROM DownlineTo_SMAControl sma WITH (NOLOCK)
			INNER JOIN bodb02.dbo.custInfo ci WITH (NOLOCK) ON sma.SMAID = ci.custID
			INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON e.exchangeid = ci.currency
			--INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON ci.custID = c.custID
		WHERE ci.UserName like '%' + @SMAName + '%'
		ORDER BY ci.UserName
	END
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SMAControlSel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SMAControlSel] TO [vnteam] 