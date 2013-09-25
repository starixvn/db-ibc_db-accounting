USE [bodb_RMS]
GO
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
  FROM [dbo].[rmSumWinloss] WITH(NOLOCK)
  WHERE winlostdate = @winlostdate
  
  IF @@ERROR > 0  
  BEGIN
	SELECT  @ErrCode = 100,
			@ErrMsg = 'Archiving data failed for date :' + CONVERT(VARCHAR(10),@winlostdate,120)
	RETURN
 END
 
 
END  


