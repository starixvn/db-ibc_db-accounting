/*<info serverAlias="DBCUST-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Transfer_CheckRunningByCust] 
	@CustID INT,
	@Language VARCHAR(2) = 'E',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
Created: 20200731@Sophia
Task:  Check Transfer Func is running by Job 
DB: DBCUST.bodb02
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
 
	DECLARE @Recommend INT, @MRecommend INT, @SRecommend INT, @RoleId INT
	SELECT @ErrMsg = '', @ErrCode = 0 

	SELECT 	@CustID = CustID, @Recommend = Recommend, @MRecommend = MRecommend, @SRecommend = SRecommend, @RoleId = RoleId
	FROM 	CUSTDB.dbo.customer c WITH(NOLOCK)
	WHERE 	CustID = @CustID
	
	IF EXISTS (
				SELECT 	TOP 1 1  
				FROM 	CUSTDB.dbo.Acc_ClearBalanceList s WITH(NOLOCK)
				WHERE 	--- check upline is transferring or not
						(
							(s.CustID IN (@CustID, @Recommend, @MRecommend, @SRecommend ) AND @RoleID = 1)
							OR (s.CustID IN (@Recommend, @MRecommend, @SRecommend) AND @RoleID = 2)
							OR (s.CustID IN (@MRecommend, @SRecommend) AND @RoleID = 3) 
							OR (s.CustID = @CustID AND @RoleID = 4)
						)
						AND isTransferring = 1	  				
				)
	BEGIN
		SELECT @ErrCode = 50015
		SELECT @ErrMsg = CUSTDB.dbo.f_Get_MsgNamebyMsgID (50015,@Language)
		 
	END

END 
GO
 
  


   