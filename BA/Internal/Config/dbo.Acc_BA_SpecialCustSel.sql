/*<info serverAlias="DBLIC-bodb_Licensee" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_BA_SpecialCustSel]
(
	@LicenseeID  INT,
	@ugroup VARCHAR (3)=NULL,
	@UserName  varchar(50)=''
)
AS
/*
Created: Henry
Date: 3-04-2012
Task : Replace hardcode member spread by web application
DB: DB052.bodb_Licensee
Original:

Revisions:
	- 20180809@Sophia: HA - remove LicenseeCustInfo table [Redmine: #99464]
	
Param's Explanation:
	
*/ 

SELECT @UserName = ltrim(rtrim(ISNULL(@UserName,'')))
DECLARE @CustID INT

IF @Username <> '' AND ISNUMERIC(@Username) = 1
BEGIN
	SELECT @CustID = CustID FROM LicenseeSpecialCust WITH (NOLOCK)
	WHERE 
		LicenseeID = @LicenseeID
		AND CustID = convert(INT,@Username)
END


IF ISNULL(@UserName,'') = ''
BEGIN
	SELECT  
		lsc.LicenseeID,
		lsc.CustID,
		SUBSTRING(lc.username2,  CHARINDEX('$',lc.username2)+1, LEN(lc.username2)-CHARINDEX('$',lc.username2)) AS ExternalID,
		lc.username SystemID,
		lsc.ugroup ugroup,
		c.custid modifybyID,
		c.username as Modifyby,
		lsc.modifydate,
		CASE WHEN ISNULL(lb.Custid,0)=0 THEN 'OFF' ELSE 'ON' END BAStatus
	FROM LicenseeSpecialCust lsc WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer lc WITH (NOLOCK) ON lc.Custid=lsc.Custid
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON lsc.ModifyBy = C.CustID
		LEFT JOIN LicenseeBAHistory lb(NOLOCK) ON lb.LicenseeID = lsc.LicenseeID AND lb.CustID=lsc.CustID  AND lb.Status='Running'
	WHERE 
		lsc.LicenseeID = @LicenseeID
		AND (ISNULL(@ugroup,'') = '' OR lsc.ugroup = @ugroup)
	ORDER BY lsc.modifydate DESC
END
ELSE 
BEGIN
	IF ISNULL(@CustID,0) = 0 
	BEGIN
		SELECT  
			lsc.LicenseeID,
			lsc.CustID,
			SUBSTRING(lc.username2,  CHARINDEX('$',lc.username2)+1, LEN(lc.username2)-CHARINDEX('$',lc.username2)) AS ExternalID,
			lc.username SystemID,
			lsc.ugroup,
			c.custid modifybyID,
			c.username as Modifyby,
			lsc.modifydate,
			CASE WHEN ISNULL(lb.Custid,0)=0 THEN 'OFF' ELSE 'ON' END BAStatus
		FROM LicenseeSpecialCust lsc WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Customer lc WITH (NOLOCK) ON lc.Custid=lsc.Custid
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON lsc.ModifyBy = C.CustID
			LEFT JOIN LicenseeBAHistory lb(NOLOCK) ON lb.LicenseeID = lsc.LicenseeID AND lb.CustID=lsc.CustID  AND lb.Status='Running'
		WHERE 
			lsc.LicenseeID = @LicenseeID
			AND (ISNULL(@ugroup,'') = '' OR lsc.ugroup = @ugroup)
			AND (@UserName='' OR (@UserName<>'' AND (lc.username2 LIKE + '%$' + @Username + '%' OR lc.username LIKE @Username + '%')))
		ORDER BY lsc.modifydate DESC
	END
	ELSE
	BEGIN
		SELECT  
			lsc.LicenseeID,
			lsc.CustID,
			SUBSTRING(lc.username2,  CHARINDEX('$',lc.username2)+1, LEN(lc.username2)-CHARINDEX('$',lc.username2)) AS ExternalID,
			lc.username SystemID,
			lsc.ugroup,
			c.custid modifybyID,
			c.username as Modifyby,
			lsc.modifydate,
			CASE WHEN ISNULL(lb.Custid,0)=0 THEN 'OFF' ELSE 'ON' END BAStatus
		FROM LicenseeSpecialCust lsc WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Customer lc WITH (NOLOCK) ON lc.Custid=lsc.Custid
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON lsc.ModifyBy = C.CustID
			LEFT JOIN LicenseeBAHistory lb(NOLOCK) ON lb.LicenseeID = lsc.LicenseeID AND lb.CustID=lsc.CustID  AND lb.Status='Running'
		WHERE 
			lsc.LicenseeID = @LicenseeID
			AND (ISNULL(@ugroup,'') = '' OR lsc.ugroup = @ugroup)
			AND lsc.CustID = @CustID
		ORDER BY lsc.modifydate DESC
	END
END


GO 