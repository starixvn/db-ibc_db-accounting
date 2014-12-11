CREATE PROCEDURE NAP_SMATurnoverGlobalSettingList
	@UserName NVARCHAR(30)=''
AS
BEGIN
	SET NOCOUNT ON;
	SELECT ci.UserName,
		CASE ci.RoleID WHEN  4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END [Level],
		ex.Currency,
		gst.MaxTurnover,
		gst.CustID
	FROM DownlineTurnOver_GlobalSetting gst WITH(NOLOCK) 
	INNER JOIN CustInfo ci WITH(NOLOCK) ON ci.CustID = gst.CustID
	INNER JOIN Exchange ex WITH(NOLOCK) ON ex.exchangeid = ci.currency
	WHERE (ISNULL(@UserName,'')='' OR ci.Username=@UserName)
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnoverGlobalSettingList] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnoverGlobalSettingList] TO [vnteam]