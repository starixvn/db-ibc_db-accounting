USE [bodb_RMS]
GO
/****** Object:  StoredProcedure [dbo].[Task_RMS_SumWinloss_Archive]    Script Date: 09/27/2013 10:06:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_RMS_SumWinloss_Archive]
	@winlostdate	DATETIME,
	@errCode		INT				= 0 OUTPUT,
	@errMsg			VARCHAR(1000)	= '' OUTPUT
 AS
	/*
		Created: Johnson
		Date: 2012-12-12
		Task: Archive rmSumWinloss to rmSumWinloss_Old
		DB: DBRMS/bobdb_RMS
		
		Revisions:
			- 20130814@Johnson: archive rmSumWinloss2
			- 20130918@Johnson: change to use table rmSumWinloss_Old instead of rmSumWinloss_Old2
			- 20130924@Johnson: add column recommend into rmSumWinloss_Old
		Parameter's Explanation:
		
	*/
SET NOCOUNT ON
BEGIN
	INSERT INTO rmSumWinloss_old(
		[winlostdate]
      ,[custid]
      ,[sporttype]
      ,[statusid]
      ,[combo]
      ,[username]
      ,[currency]
      ,[stake]
      ,[winlost]
      ,[company_stake]
      ,[company_winlost]
      ,[actualrate]
      ,[odds]
      ,[betcount]
      ,[recommend]
	)
	SELECT [winlostdate]
      ,[custid]
      ,[sporttype]
      ,[statusid]
      ,[combo]
      ,[username]
      ,[currency]
      ,[stake]
      ,[winlost]
      ,[company_stake]
      ,[company_winlost]
      ,[actualrate]
      ,[odds]
      ,[betcount]
      ,[recommend]
  FROM [dbo].[rmSumWinloss] WITH(NOLOCK)
  WHERE winlostdate = @winlostdate
  
  IF @@ERROR > 0  
  BEGIN
	SELECT  @ErrCode = 100,
			@ErrMsg = 'Archiving data failed for date :' + CONVERT(VARCHAR(10),@winlostdate,120)
	RETURN
 END
 
 
END  


