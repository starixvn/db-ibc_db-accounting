ALTER PROCEDURE [dbo].[NAP_SMATurnover_SMAControlSel]
	@SMAName VARCHAR(30) = '',

	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20140416
	Task : Retrieve configure TO information by SMA
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
	Example: EXEC NAP_SMATurnover_SMAControlSel @SMAName = 'SuperTest1'
	
*/
BEGIN
	SET NOCOUNT ON
	
	IF @SMAName = ''
	BEGIN
		SELECT c.UserName, c.custid, c.roleid, c.Currency, c.credit, sma.Offset
		FROM DownlineTo_SMAControl sma WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON sma.SMAID = c.custID
	END
	ELSE
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM bodb02.dbo.Customer WHERE UserName = @SMAName)
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Username does not exists.'
			RETURN
		END
		SELECT c.UserName, c.custid, c.roleid, c.Currency, ci.credit, sma.Offset
		FROM DownlineTo_SMAControl sma WITH (NOLOCK)
			INNER JOIN bodb02.dbo.custInfo ci WITH (NOLOCK) ON sma.SMAID = ci.custID
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON ci.custID = c.custID
		WHERE c.UserName = @SMAName
	END
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_SMAControlSel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_SMAControlSel] TO [vnteam] 