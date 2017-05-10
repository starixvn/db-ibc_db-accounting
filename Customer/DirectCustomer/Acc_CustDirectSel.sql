/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROC Acc_CustDirectSel
(
	@CustID INT
	
)
AS
/*
Created: 20170419@Helen
Task: Add Extra information for Direct Accounts, for NAP only - [Redmine:72339]
DB: DBAGE/BODB02

Revisions:
	
*/
BEGIN

	SELECT 
		cda.CustID AS CustID
		, cr.Username AS  CreatedBy
		, ISNULL(cda.ProcessedBy,'') AS ProcessedBy
		, ISNULL(cda.Boss,'') AS Boss
		, ISNULL(cda.RequestedBy,'') AS RequestBy
		, ISNULL(cda.ApprovedBy,'') AS ApprovedBy
		, ISNULL(c.mobilephone,'') AS Mobilephone
		, ISNULL(ls.MaxLoss,0) AS MaxLoss
		, ISNULL(GroupHeadline.GroupID,0) AS GroupHeadlineID
		, CASE WHEN e.ExchangeID = 20 THEN 'UUS' ELSE e.Currency END AS Currency
		, Headline.username AS Headline
		
	FROM dbo.CustDirectAccount cda WITH (NOLOCK)
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON cda.CustID = c.CustID
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON e.ExchangeID = c.Currency
		INNER JOIN dbo.Customer cr WITH (NOLOCK) ON c.creator = cr.CustID
		LEFT JOIN custaccount AS GroupHeadline WITH (NOLOCK) ON GroupHeadline.CUSTID = @CustID AND GroupHeadline.GroupID > 0 
		OUTER APPLY (SELECT C.username
					 FROM dbo.custaccount ca WITH (NOLOCK)
						INNER JOIN Customer C ON CA.custid = C.custid 
					 WHERE ca.GroupID = GroupHeadline.GroupID AND ca.IsGroupHeadLine = 1 
					) AS Headline
						 
		LEFT JOIN bodb_Age.dbo.LimitLoss_Setting ls WITH (NOLOCK) ON cda.Custid = ls.CustID
		
	WHERE cda.Custid = @CustID
	
END
GO
GRANT EXECUTE ON [dbo].Acc_CustDirectSel TO [bodbAdminNet] 
GO
