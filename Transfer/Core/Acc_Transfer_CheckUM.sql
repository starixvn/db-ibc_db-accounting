/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Transfer_CheckUM] 
	@CustID INT,
	@Language VARCHAR(2) = 'E',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
Created: 20200729@Sophia
Task:  Get UM Transfer Function
DB: DBTXN.bodb02
Revisions:	
	- 20200729@Sophia: Get UM Transfer Function [Redmine: #136992]

Param's Explanation:
	@CustID: all roleID
Examples :
	 DECLARE @ErrCode INT, @ErrMsg NVARCHAR(MAX)
	 EXEC [Acc_Transfer_CheckUM] @CustID = 16631688, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	 SELECT @ErrCode,  @ErrMsg 
*/
BEGIN 

	DECLARE @ErrorTemplate NVARCHAR(4000)
	DECLARE @FromTime VARCHAR(30), @ToTime VARCHAR(30) 
	SELECT @ErrMsg = '', @ErrCode = 0 

	SELECT  @FromTime = CONVERT(VARCHAR,DATEADD(HOUR, 12, MIN(c.BeginTime)),103) + ' ' + LTRIM(RIGHT(CONVERT(VARCHAR,DATEADD(HOUR, 12, MIN(c.BeginTime)),22),12)),
			@ToTime = CONVERT(VARCHAR,DATEADD(HOUR, 12, MAX(c.EndTime)),103) + ' ' + LTRIM(RIGHT(CONVERT(VARCHAR,DATEADD(HOUR, 12, MAX(c.EndTime)),22),12))
	FROM CUSTDB.dbo.customer cu WITH(NOLOCK)
		INNER JOIN CUSTDB.dbo.customer su WITH(NOLOCK) ON cu.srecommend = su.custid
		LEFT JOIN CUSTDB.dbo.customer ag WITH(NOLOCK) ON cu.recommend = ag.custid
		LEFT JOIN bodb02.dbo.site s WITH(NOLOCK) ON s.site = cu.site
		LEFT JOIN bodb02.dbo.site ags WITH(NOLOCK) ON ag.site = ags.site
		INNER JOIN CUSTDB.dbo.UMConfig c WITH(NOLOCK) ON c.SuperID IN (su.custid,0)
	WHERE GETDATE() BETWEEN c.BeginTime AND c.EndTime
		AND c.FunctionType = 101 --- transfer Func 
		AND c.SiteID IN (ISNULL(s.siteid,ags.siteid),0)
		AND c.Currency IN (cu.currency,0)
		AND cu.custid = @CustID	
		  
	
	IF @FromTime IS NOT NULL OR @ToTime IS NOT NULL
	BEGIN
		SELECT @ErrCode = 90015
		SELECT @ErrorTemplate = CUSTDB.dbo.f_Get_MsgNamebyMsgID (90015,@Language)
		SELECT @ErrMsg =   REPLACE(REPLACE(@ErrorTemplate,'<FromTime>',@FromTime),'<ToTime>',@ToTime)
	END

END 
GO
 
  


   