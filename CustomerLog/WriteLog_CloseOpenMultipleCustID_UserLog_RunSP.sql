ALTER PROCEDURE [dbo].[WriteLog_CloseOpenMultipleCustID_UserLog_RunSP]
		@UserID INT,
		@CustIDs VARCHAR(500) = '',
		@SPName VARCHAR(50)= NULL, -- USE FOR OLD FORMAT AND WILL REMOVE LATER
		@Doing	VARCHAR(4000) = NULL, --
		@Closed BIT,
		@ActionID INT = NULL,	
		@Language varchar(2) = 'E',
		@IP varchar(15)='',
		@ErrCode int = 0 OUTPUT,
		@ErrMsg nvarchar(200) = '',
		@Duration INT = NULL
		
/* Created:
    Task: ViewLog function 331
    DB: bodb_CustomerLog
	SERVER: DBTXN, DBAGE

	Revisions:
		
    Param's Explaination:    	
	- @UserID: UserId perform this action
	- @CustID: 
	- @ActionID: Log action Id
	- @TrackingValue: xml string format
*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;   

	INSERT INTO dbo.UserLog_RunSP(	UserID, 
									CustID, 
									SPName,
									Doing,
									ActionID, 
									TrackingValue,
									TrackingValue2,
									Duration
									)
	select @UserID,
			val CustID,
			@SPName,
			@Doing,
			@ActionId,
			'<'+@SPName+' CustID="'+CAST(val as varchar(10))+'" Closed="'+CAST(@closed as varchar(10))+'" SubAccName="" UserID="'+CAST(@UserID as varchar(10))+'" Language="'+@Language+'" ErrCode="'+CAST(@ErrCode as varchar(10))+'" ErrMsg="'+@ErrMsg+'" IP="'+@IP+'" />' as trackingvalue,
			'<'+@SPName+' CustID="'+CAST(val as varchar(10))+'" Closed="'+CASE @Closed WHEN 1 THEN '0' ELSE '1' END +'" SubAccName="" UserID="'+CAST(@UserID as varchar(10))+'" Language="'+@Language+'" ErrCode="'+CAST(@ErrCode as varchar(10))+'" ErrMsg="'+@ErrMsg+'" IP="'+@IP+'" />' as TrackingValue2,
			@Duration
	FROM bodb02.dbo.StrSplit(@CustIDs,',')
END
/*
GO
exec [WriteLog_CloseOpenMultipleCustID_UserLog_RunSP]
		@UserID =123,
		@CustIDs = '1,2,3,5,4,5,6',
		@SPName = 'aaaaaa', -- USE FOR OLD FORMAT AND WILL REMOVE LATER
		@Doing	= NULL, --
		@Closed =0,
		@ActionID = '123',	
		@Language = 'E',
		@IP ='',
		@ErrCode = 0 ,
		@ErrMsg = '',
		@Duration = NULL

*/		

