ALTER PROCEDURE [dbo].[Lrf_CustomerSelCheckAllowedDownlines]  
	@custid			INT = 0   
	,@sporttype		INT = 0 
	,@Language		VARCHAR(2) = 'E'  
	,@ErrCode		INT = 0 OUTPUT  
	,@ErrMsg		NVARCHAR(200) = '' OUTPUT    
AS    
/*  
Created by: Elodie
Date: 2015-01-12
Task : Check Allowed downlines during peak hour at weekend for Licensee
DB: DBAGE/bodb02        
Original SP: Acc_CustomerSelCheckAllowedDownlines        

Revisions:       

Param's Explanation: 
	+ @sporttype: 1: Sportsbook 
 
*/  
  
BEGIN    
	SET NOCOUNT ON  
	  
	DECLARE @LimitDownlinesMin INT,   --Peak hours
		@LimitDownlinesMax INT,		  -- Normal 
		@LimitDownlines INT,  
		@TotalDownlines INT  
	  
	SET @LimitDownlinesMin = 20000  
	SET @LimitDownlinesMax = 50000  
		 
	IF @sporttype = 1  -- Sportsbook 
	BEGIN
		SELECT	 @LimitDownlinesMin = 3000
				,@LimitDownlinesMax = 5000 
	END  
	  
	--GET TOTALDOWNLINE  
	SET @TotalDownlines=1  
	  	 
	SELECT  @TotalDownlines = count(1)   
	FROM Custinfo WITH (NOLOCK)  
	WHERE srecommend=@custID  	
	  	  
	SELECT  @LimitDownlines = CASE  WHEN datename(weekday, getdate()) in ('Saturday','Sunday') and   
											datepart(hour, getdate()) between 7 and  14 --Weekend's peak hour, from 7PM - 2AM (GMT+8)  
										THEN  @LimitDownlinesMin  
									ELSE @LimitDownlinesMax  END   
	  
	IF @TotalDownlines >  @LimitDownlines  
	BEGIN       
		SELECT	@ErrMsg= CASE @Language WHEN 'E' THEN 'This function is not available during peak hour since it might affect the performance of the whole system. Please contact IT for further assistance.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](90010,@Language) END
				,@ErrCode = 113 	     
	END   
END   
  