set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER PROCEDURE [dbo].[Acc_BA_SpecialCust_ViewLog]
	(
		@LicenseeID INT =NULL,
		@UserName   varchar(50)='',
		@ErrCode	INT = 0 OUTPUT,		
		@ErrMsg		varchar(1000)='' OUTPUT 
	)
AS
/*
Created: Jim
Date: 5-03-2012
Task : Replace hardcode member spread by web application
DB: DB052.bodb_Licensee
Original:

Revisions:
	
Param's Explanation:
	
*/
SELECT @UserName= ltrim(rtrim(ISNULL(@UserName,'')))
DECLARE @CustID INT 
IF @Username <> '' AND ISNUMERIC(@Username) = 1
BEGIN
	SELECT @CustID = CustID FROM LicenseeSpecialCust WITH (NOLOCK)
	WHERE 
		 CustID = convert(INT,@Username)
END
IF ISNULL(@UserName,'')=''
	BEGIN
		SELECT  ulc.LicenseeID,l.licenseeName,ulc.CustID,SUBSTRING(c.username2,  CHARINDEX('$',c.username2)+1, len(c.username2)-CHARINDEX('$',c.username2)) AS  ExternalID,c.username SystemID,ulc.ugroup,ulc.ugroup_old,co.username Modifyby,ulc.modifydate,ulc.IP
		FROM UserLog_LicenseeSpecialCust ulc WITH (NOLOCK) 
			 INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON ulc.CustID=c.CustID
			 INNER JOIN Licensees l WITH (NOLOCK) ON ulc.licenseeID=l.licenseeID 
			 INNER JOIN bodb02.dbo.Custinfo co with (nolock) ON ulc.modifyBy=co.CustID 
		WHERE (ISNULL (@LicenseeID,0)=0 OR (ISNULL (@LicenseeID,0)<>0 AND l.LicenseeID = @LicenseeID))	 
		ORDER BY ulc.modifydate DESC
	END
ELSE 	
		IF ISNULL(@CustID,0)=0
			BEGIN
				SELECT  ulc.LicenseeID,l.licenseeName,ulc.CustID,SUBSTRING(c.username2,  CHARINDEX('$',c.username2)+1, len(c.username2)-CHARINDEX('$',c.username2)) AS  ExternalID,c.username SystemID,ulc.ugroup,ulc.ugroup_old,co.username Modifyby,ulc.modifydate,ulc.IP
				FROM UserLog_LicenseeSpecialCust ulc WITH (NOLOCK) 
					 INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON ulc.CustID=c.CustID
					 INNER JOIN Licensees l WITH (NOLOCK) ON ulc.licenseeID=l.licenseeID 
					 INNER JOIN bodb02.dbo.Custinfo co with (nolock) ON ulc.modifyBy=co.CustID 
				WHERE (ISNULL (@LicenseeID,0)=0 OR (ISNULL (@LicenseeID,0)<>0 AND l.LicenseeID = @LicenseeID))
						AND (@UserName='' OR (@UserName<>'' AND (c.username2 LIKE + '%$' + @Username + '%' OR c.username LIKE @Username + '%')))	
				ORDER BY ulc.modifydate DESC	
			END 
		ELSE 	
			IF  ISNULL(@CustID,0)<>0 
			BEGIN
				SELECT  ulc.LicenseeID,l.licenseeName,ulc.CustID,SUBSTRING(c.username2,  CHARINDEX('$',c.username2)+1, len(c.username2)-CHARINDEX('$',c.username2)) AS  ExternalID,c.username SystemID,ulc.ugroup,ulc.ugroup_old,co.username Modifyby,ulc.modifydate,ulc.IP
				FROM UserLog_LicenseeSpecialCust ulc WITH (NOLOCK) 
					 INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON ulc.CustID=c.CustID
					 INNER JOIN Licensees l WITH (NOLOCK) ON ulc.licenseeID=l.licenseeID 
					 INNER JOIN bodb02.dbo.Custinfo co with (nolock) ON ulc.modifyBy=co.CustID 
				WHERE  (ISNULL (@LicenseeID,0)=0 OR (ISNULL (@LicenseeID,0)<>0 AND l.LicenseeID = @LicenseeID))
				AND ulc.CustID = @CustID
				ORDER BY ulc.modifydate DESC	
			END

GO
GRANT EXECUTE ON [dbo].[Acc_BA_SpecialCust_ViewLog] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BA_SpecialCust_ViewLog] TO [vnteam] 



