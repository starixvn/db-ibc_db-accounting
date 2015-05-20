ALTER PROCEDURE [dbo].[DBA_DepCustSuperIns]
(
	@CustID		INT
)
AS
/*
Created: Henry
Date: 20120508
Task : Add new super to Dep_CustSuper
DB: DBTRANS.bodb02
Original:

Revisions:
	
	
Param's Explanation:
	
*/
BEGIN

SET NOCOUNT ON

DECLARE @currency INT, @username nvarchar(50), @site nvarchar(50), @roleid INT

IF NOT EXISTS (SELECT 1 FROM Dep_CustSuper WITH (NOLOCK) WHERE CustID = @CustID)
BEGIN
	SELECT @roleid=roleid,@currency = currency, @username=username,@site=site 
	FROM Customer WITH (NOLOCK) WHERE CustID = @CustID
	
	SET @site = LTRIM(RTRIM(ISNULL(@site,'')))
	
	IF ISNULL(@roleid,0)<>4
	BEGIN
		print 'This customer is not a super, please check again!'
		RETURN
	END
	ELSE IF @site = ''
	BEGIN
		print 'This super is not belong to any site, please check again! '
		RETURN
	END
	
	INSERT INTO Dep_CustSuper(Custid,currency,username,site)
	VALUES(@CustID,@currency,@username,@site)
	
END
ELSE
BEGIN
	print 'This Super has been added before!'
	RETURN
END


END

GO
GRANT EXECUTE ON [dbo].[DBA_DepCustSuperIns] TO [vnteam] 