USE [CustDB]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_SubscriberSel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_SubscriberSel]
GO

USE [CustDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_SubscriberSel]
	@CustID		INT,
	@IsDeposit	BIT OUTPUT,
	@SiteName	VARCHAR(10) OUTPUT
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@CustID		: Customer ID.
			@IsDeposit	:
				= 1		: Deposit
				= 0		: Credit.
			@SiteName	: Site of Customer.
	*/
BEGIN
	SET NOCOUNT ON;
	SELECT	TOP(1) @IsDeposit = CASE WHEN c.site IS NULL THEN 0 ELSE 1 END 
			, @SiteName = c.site
	FROM	dbo.Customer c WITH(NOLOCK)
			INNER JOIN dbo.Customer sc WITH(NOLOCK)
			ON c.srecommend = sc.custid and sc.roleid = 4
			LEFT JOIN dbo.Dep_CustSuper s WITH(NOLOCK)
			ON c.srecommend = s.custid
	WHERE	c.CustID = @CustID
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_SubscriberSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_SubscriberSel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_SubscriberSel] TO [vnteam]
GO