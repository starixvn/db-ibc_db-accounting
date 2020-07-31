/*<info serverAlias="DBTXN-bodb02" selecters="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" viewers="" isFunction="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_Transfer_CheckRunningByCust] 
	@CustID INT,
	@Language VARCHAR(2) = 'E',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
Created: 20200731@Sophia
Task:  Check Transfer Func is running by Job 
DB: DBTXN.bodb02
Revisions:	
	- 20200731@Sophia: initial SPs [Redmine: #137141]

Param's Explanation:
	@CustID: all roleID
Examples :
	 DECLARE @ErrCode INT, @ErrMsg NVARCHAR(MAX)
	 EXEC [Acc_Transfer_CheckRunningByCust] @CustID = 16631688, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	 SELECT @ErrCode,  @ErrMsg 
*/
BEGIN 

	DECLARE @ErrorTemplate NVARCHAR(4000) 
	DECLARE @Recommend INT, @MRecommend INT, @SRecommend INT, @RoleId INT
	SELECT @ErrMsg = '', @ErrCode = 0 

	SELECT  @Recommend, @MRecommend, @SRecommend, @RoleId
	FROM CUSTDB.dbo.customer c WITH(NOLOCK)
	WHERE CustID = @CustID
	
		 
				
				
				INNER JOIN CUSTDB.dbo.Acc_ClearBalanceList c WITH(NOLOCK) 
	  
		  
	
	IF @FromTime IS NOT NULL OR @ToTime IS NOT NULL
	BEGIN
		SELECT @ErrCode = 90015
		SELECT @ErrorTemplate = CUSTDB.dbo.f_Get_MsgNamebyMsgID (90015,@Language)
		SELECT @ErrMsg =   REPLACE(REPLACE(@ErrorTemplate,'<FromTime>',@FromTime),'<ToTime>',@ToTime)
	END

END 
GO
 
  


   