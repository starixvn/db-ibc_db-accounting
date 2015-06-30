ALTER PROCEDURE [dbo].[DBA_GenTestViewLog]
	@UserID		INT,
	@CustID		INT,	
	@ActionID	INT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
AS
BEGIN		
	
	DECLARE	@Log TABLE (LogID BIGINT)	
	IF @ActionID IN (200,201,202,203,204,205,206,207,209,210,211,212,213,216,220,221,222,223,224,225,226,227,300,301,302,303,304,305,306,307,313,314,315,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,351,352,353,354,356,357,358,359,360,361,362,363,364,365,366,370,371,372,373,375,400,401,402,403,404,406,407,409,410,411,412,413,417,418,419,420,421,422,424,425,426,427,428,429,430,431,432,433,434,435,500,502,503,504,600,601,602,603,604,605,606,607,608,609,610,611,612,615,617,621,622,627,628,629,630,700,701,702,703,704,900,901,902,903,904,1100,1101,1102,1103,1104,1105,1108,1107,1109,1111,1113,1116,1117,1118,1119,1120,1121,1125,1126,1127,1128,1129,1130,1132,1134,1136)
	BEGIN
		INSERT INTO UserLog_RunSP (userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2)
		OUTPUT INSERTED.logid INTO @Log (LogID)
		SELECT TOP 2 @UserID, spname, doing, getdate(), @CustID, @ActionID, TrackingValue, Duration, TrackingValue2
		FROM UserLog_RunSP lg WITH (NOLOCK) 
		WHERE ActionID = @ActionID
		
		SELECT * FROM UserLog_RunSP WITH (NOLOCK) WHERE logid IN (SELECT LogID FROM @Log)	
	END		
	
	IF @ActionID between 1200 and 1211
	BEGIN
		INSERT INTO UserLog_Credit (userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID)
		OUTPUT INSERTED.logid INTO @Log (LogID)
		SELECT TOP 2 @UserID, @CustID, getdate(), spname, OldValue, NewValue, ip, doing, @ActionID
		FROM UserLog_Credit lg WITH (NOLOCK) 
		WHERE ActionID = @ActionID
		
		SELECT * FROM UserLog_Credit WITH (NOLOCK) WHERE logid IN (SELECT LogID FROM @Log)	
	END	
	
	IF @ActionID between 1300 and 1317
	BEGIN
		INSERT INTO UserLog_Login (UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration, username2)
		OUTPUT INSERTED.logid INTO @Log (LogID)
		SELECT TOP 2 @CustID, RoleID, SubAccID, ServerID, IP, getdate(), @ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration, username2
		FROM UserLog_Login lg WITH (NOLOCK) 
		WHERE ActionID = @ActionID
		
		SELECT * FROM UserLog_Login WITH (NOLOCK) WHERE logid IN (SELECT LogID FROM @Log)	
	END	
END
