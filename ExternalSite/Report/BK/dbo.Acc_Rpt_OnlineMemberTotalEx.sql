ALTER PROCEDURE [dbo].[Acc_Rpt_OnlineMemberTotalEx]
@System		VARCHAR(50)='ACCTHAI'
AS
/*	Created by: Jamie
	Date: 2010-06-09
	Task: Total Online Members for Thai Site [755555]
	DB: DB03.ON_USER
	
	Revision: 
		- 20101130@Jamie: Get total online members for ACCINDO 
		- 20110310@Amy: Get total online members for ACCNTD and ACCYEN

	Param's Explanation:
		Reference:  DB03.ON_USER: Dot_Admin_GetTotalOnline_Report
		ServerID:	120000 -> 120999 ACCTHAI with Site: 755555
					101050 -> 101059 ACCINDO with Site: INDO 
					104000 -> 104999 ACCNTD and ACCYEN with Site: 789y 
*/
BEGIN
	SET NOCOUNT ON
	DECLARE	@ToDate SMALLDATETIME
	SELECT	@ToDate = DATEADD(Minute,-10,CURRENT_TIMESTAMP)

	IF	@System = 'ACCTHAI'
	BEGIN
		SELECT	TOP 1 SUM(Users) OnlineMemTotal
		FROM	TotalOnline WITH (NOLOCK)
		WHERE	ServerID BETWEEN 120000 AND 120999	
				AND LogDate >= @ToDate
		GROUP BY LogDate
		ORDER BY LogDate DESC 
	END
	ELSE IF	@System = 'ACCINDO'
	BEGIN
		SELECT	TOP 1 SUM(Users) OnlineMemTotal
		FROM	TotalOnline WITH (NOLOCK)
		WHERE	ServerID BETWEEN 101050 AND 101059	
				AND LogDate >= @ToDate
		GROUP BY LogDate
		ORDER BY LogDate DESC 
	END
	ELSE IF (@System = 'ACCYEN' OR @System = 'ACCNTD')
	BEGIN
		SELECT	TOP 1 SUM(Users) OnlineMemTotal
		FROM	TotalOnline WITH (NOLOCK)
		WHERE	ServerID BETWEEN 104000 AND 104999	
				AND LogDate >= @ToDate
		GROUP BY LogDate
		ORDER BY LogDate DESC
	END

END
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_OnlineMemberTotalEx] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_OnlineMemberTotalEx] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_OnlineMemberTotalEx] TO [VNTeam]