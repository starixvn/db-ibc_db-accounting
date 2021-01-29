/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC dbo.Acc_AmendmentNotification_Ins
	@XmlEvent	XML
	,@XmlTicket XML
	,@IsCheck	BIT
	,@ErrCode	INT= 0 OUTPUT
	,@ErrMsg	NVARCHAR(MAX)='' OUTPUT

AS
/*
	Created: 20200127@Malcolm
	DB: DBEXT-bodb02
	Task: Result Amendment - Insert event and ticket to notify headlines

	Revisions:
		- 20200127@Malcolm: Initialize SP [RedmineID: #147470]

	Param's Explanation:
		.@XmlEvent = '<root><r SportType="" MatchId="" MatchCode="" EventType="" EventDate="" ActualResult="" WrongResult=""/></root>'
		.@XmlTicket = '<root><r RowAt="" CustId="" Username="" TicketRefNo="" RefTable="" Bettype=""/></root>'
		.@IsCheck = 0, Insert and Check
				  = 1, Only check data
*/

BEGIN
	
	SET NOCOUNT ON
	
	CREATE TABLE #EventInfo (Sporttype SMALLINT, MatchId INT, MatchCode NVARCHAR(100), EventType TINYINT, EventDate SMALLDATETIME, ActualResult NVARCHAR(MAX), WrongResult NVARCHAR(MAX))

	CREATE TABLE #TicketRefNo (RowAt INT, CustId INT, Username VARCHAR(30), TicketRefNo BIGINT, RefTable TINYINT, Bettype SMALLINT)

	DECLARE @EventTmp TABLE (EventId INT)

	DECLARE @EventId BIGINT = NULL, @NoRows INT= 0

	INSERT INTO #EventInfo (Sporttype, MatchId, MatchCode, EventType, EventDate, ActualResult, WrongResult)
	SELECT 
		T.c.value('@SportType', 'SMALLINT')
		,NULLIF(T.c.value('@MatchId', 'INT'),0)
		,NULLIF(T.c.value('@MatchCode','NVARCHAR(100)'),'')
		,T.c.value('@EventType', 'TINYINT')
		,T.c.value('@EventDate', 'SMALLDATETIME')
		,T.c.value('@ActualResult', 'NVARCHAR(MAX)')
		,T.c.value('@WrongResult', 'NVARCHAR(MAX)')
	FROM @XmlEvent.nodes('/root/r') AS T(c)

	INSERT INTO #TicketRefNo (RowAt, CustId, Username, TicketRefNo, RefTable, Bettype)
	SELECT
		T.c.value('@RowAt', 'INT')
		,T.c.value('@CustId','INT')
		,T.c.value('@Username', 'VARCHAR(30)')
		,T.c.value('@TicketRefNo', 'BIGINT')
		,T.c.value ('@RefTable', 'TINYINT')
		,T.c.value ('@Bettype', 'SMALLINT')
	FROM @XmlTicket.nodes('/root/r') T(c)

	--Check Data	
	SELECT @ErrMsg = COALESCE(@ErrMsg, '') + CONVERT(VARCHAR(30), r.RowAt) + ','
	FROM #TicketRefNo r
		INNER JOIN #EventInfo e ON 1 = 1
	WHERE EXISTS(
		SELECT TOP(1) 1
		FROM dbo.TicketRefNo t WITH(NOLOCK)
			INNER JOIN dbo.AmendmentEventInfo ev WITH(NOLOCK) ON ev.EventId = t.EventId
		WHERE t.CustId = r.CustId
			AND t.TicketRefNo = r.TicketRefNo
			AND ev.ActualResult = e.ActualResult
			AND ev.WrongResult = e.WrongResult
	)
	ORDER BY r.RowAt ASC

	SET @NoRows = @@ROWCOUNT

	IF @IsCheck = 1 OR @NoRows <> 0
	BEGIN
		IF @NoRows <> 0 
			SELECT @ErrCode = 100, @ErrMsg = 'These tickets have been uploaded to notify headline, please check at row: ' + SUBSTRING(@ErrMsg, 1, LEN(@ErrMsg) - 1)
		RETURN
	END

	--Insert Event and Ticket
	BEGIN TRY
		INSERT INTO dbo.AmendmentEventInfo (Sporttype, MatchId, MatchCode, EventType, EventDate, ActualResult, WrongResult)
		SELECT Sporttype, MatchId, MatchCode, EventType, EventDate, ActualResult, WrongResult
		FROM #EventInfo

		SET @EventId = SCOPE_IDENTITY()

		INSERT INTO dbo.TicketRefNo (CustId, TicketRefNo, EventId, RefTable, Bettype)
		SELECT CustId, TicketRefNo, @EventId, RefTable, Bettype
		FROM #TicketRefNo
		ORDER BY CustId ASC
	END TRY
	BEGIN CATCH
		IF @EventId IS NOT NULL
		BEGIN
			DELETE dbo.AmendmentEventInfo WITH(ROWLOCK, UPDLOCK) WHERE EventId = @EventId
			RETURN
		END
	END CATCH

	-- Delete ticket after 2 month
	DELETE dbo.AmendmentEventInfo WITH(ROWLOCK, UPDLOCK)
	WHERE CreatedDate < DATEADD(MONTH, -2, GETDATE())

	IF @@ROWCOUNT <> 0
	BEGIN
		DELETE e
		FROM dbo.TicketRefNo e WITH(ROWLOCK, UPDLOCK)
		WHERE EXISTS(SELECT TOP 1 1 FROM @EventTmp t WHERE t.EventId = e.EventId)
	END

	DROP TABLE #EventInfo
	DROP TABLE #TicketRefNo
END