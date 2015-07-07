USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_SubscriberSel]    Script Date: 07/07/2015 16:10:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_SubscriberSel]
	@CustID int,
	@IsDeposit bit output,
	@SiteName varchar(10) output
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
	*/
BEGIN
	SET NOCOUNT ON;
	SELECT @IsDeposit = CASE WHEN s.site IS NULL THEN 0 ELSE 1 END 
		, @SiteName = sc.site
	FROM dbo.WinLimit_CustSetting cs WITH(NOLOCK)
		 INNER JOIN dbo.Customer c WITH(NOLOCK)
		 ON cs.CustID = c.custid
		 INNER JOIN dbo.Customer sc WITH(NOLOCK)
		 ON c.srecommend = sc.custid and sc.roleid = 4
		 LEFT JOIN dbo.Dep_CustSuper s WITH(NOLOCK)
		 ON c.srecommend = s.custid
	WHERE cs.CustID = @CustID
END
GO

