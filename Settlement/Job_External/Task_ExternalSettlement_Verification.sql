ALTER PROCEDURE [dbo].[Task_ExternalSettlement_Verification]
(
	@latency INT = 60
)
AS
/*
	Created by:Lukas
	Date:20110112
	Task: Looking for delayed & failed settlement and raise
	DB: DB052.BODB02
	
	Revisions:
		- 20110217@Lukas: correct datatype of data
		- 20110711@Lukas: including long running process when alert
		- 20110912@Lukas: apply for DB053
		- 20120827@Lukas: retry settle several times after failing
		- 20121122@Jamie: Update new range for delay execution - tickets not match 
	Param explanation:					
		StatusID & Status
			+ 0		Waiting	
			+ 1		Running
			+ 2		Failed & retry 1
			+ 3		Failed & retry 2
			+ 4		Failed & retry 3
			
			+ 11	Failed & skip "Running" step 
			+ 12	Failed & delay execution 1 
			+ 13	Failed & delay execution 2 
			+ 14	Failed & delay execution 3 
				
			+ 98	Failed & waiting for notification
			+ 99	Failed & notified
			+ 100	Completed (successful)
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @sumFailed INT,
			@sumDelayed INT,
			@sumSlowed INT,
			@reminder INT,
			@errmsg VARCHAR(200),
			@rowcount INT 

	SELECT	@sumFailed		= SUM(CASE WHEN StatusID = 98 THEN 1 ELSE 0 END),
			@sumDelayed		= SUM(CASE WHEN StatusID = 0 THEN 1 ELSE 0 END),
			@sumSlowed		= SUM(CASE WHEN StatusID = 1 THEN 1 ELSE 0 END),
			@reminder		= SUM(CASE WHEN StatusID = 99 THEN 1 ELSE 0 END)
	FROM Acc_ExternalSettlement WITH(NOLOCK)
	WHERE 
		(	DATEDIFF(ss,CreatedDate,GETDATE()) > @latency
			AND 
			StatusID BETWEEN 0 AND 1 
		)
		OR 
		StatusID = 98
		OR
		(
			DATEDIFF(hh,CreatedDate,GETDATE()) > 1
			AND 
			StatusID = 99
		)
	IF @sumFailed > 0
	BEGIN
		UPDATE Acc_ExternalSettlement WITH(ROWLOCK,UPDLOCK)
		SET StatusID = 99,
			Status   = 'Failed & notified'
		WHERE StatusID = 98
	END


	SET @errmsg = 'FAILED:External Settlement: '	+ CONVERT(VARCHAR(10),@sumFailed) + ' failed(s), ' 
													+ CONVERT(VARCHAR(10),@sumDelayed) + ' delayed(s), '
													+ CONVERT(VARCHAR(10),@sumSlowed) + ' slow(s), and '	
													+ CONVERT(VARCHAR(10),@reminder) + ' reminder(s).'	
				 + ' [tsql]SELECT * FROM Acc_ExternalSettlement WITH(NOLOCK) WHERE statusID = 99[/stql]'

	IF @sumFailed > 0 OR @sumDelayed > 0 OR @sumSlowed > 0 OR @reminder > 0
	BEGIN
		RAISERROR( @errmsg,16,1)
	END
END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_ExternalSettlement_Verification] TO [vnteam]