/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROC dbo.Acc_Amendment_CheckAndNotifyNotification
	@XmlEvent	NVARCHAR(MAX)
	,@XmlTicket NVARCHAR(MAX)
	,@IsNotify	BIT = 0
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
		.@XmlEvent = '<root><r ProductId="" MatchId="" MatchCode="" EventType="" EventDate="" ActualResult="" WrongResult="" MessageId=""/></root>'
		.@XmlTicket = '<root><r RowAt="" CustId="" Username="" RefNo="" RefTable="" Bettype="" HeadlineId=""/></root>'
		.@IsCheck = 0, Insert and Check
				  = 1, Only check data
*/

BEGIN
	
	SET NOCOUNT ON
	
	CREATE TABLE #EventInfo (ProductId TINYINT, MatchId INT, MatchCode NVARCHAR(100), EventType TINYINT, EventDate SMALLDATETIME, MessageId INT,ActualResult NVARCHAR(MAX), WrongResult NVARCHAR(MAX))

	CREATE TABLE #TicketRefNo (ID INT, RowAt INT, CustId INT, Username VARCHAR(30), RefNo BIGINT, RefTable TINYINT, Bettype SMALLINT, HeadlineId INT)

	DECLARE @EventTmp TABLE (EventId INT)

	DECLARE @EventId BIGINT = NULL, @NoRows INT= 0, @ActualResult NVARCHAR(MAX), @WrongResult NVARCHAR(MAX), @MessageId INT, @_XmlEvent XML, @_XmlTicket XML

	SELECT @_XmlEvent = CONVERT(XML, @XmlEvent), @_XmlTicket = CONVERT(XML, @XmlTicket)

	INSERT INTO #EventInfo (ProductId, MatchId, MatchCode, EventType, EventDate, ActualResult, WrongResult, MessageId)
	SELECT 
		T.c.value('@ProductId', 'TINYINT')
		,NULLIF(T.c.value('@MatchId', 'INT'),0)
		,NULLIF(T.c.value('@MatchCode','NVARCHAR(100)'),'')
		,T.c.value('@EventType', 'TINYINT')
		,T.c.value('@EventDate', 'SMALLDATETIME')
		,T.c.value('@ActualResult', 'NVARCHAR(MAX)')
		,T.c.value('@WrongResult', 'NVARCHAR(MAX)')
		,NULLIF(T.c.value('@MessageId','INT'),0)
	FROM @_XmlEvent.nodes('/root/r') AS T(c)
	OPTION(OPTIMIZE FOR (@_XmlEvent = NULL))

	INSERT INTO #TicketRefNo (RowAt, CustId, Username, RefNo, RefTable, Bettype, HeadlineId)
	SELECT
		T.c.value('@RowAt', 'INT')
		,T.c.value('@CustId','INT')
		,T.c.value('@Username', 'VARCHAR(30)')
		,T.c.value('@RefNo', 'BIGINT')
		,T.c.value ('@RefTable', 'TINYINT')
		,T.c.value ('@Bettype', 'SMALLINT')
		,NULLIF(T.c.value('@HeadlineId','INT'), 0)
	FROM @_XmlTicket.nodes('/root/r') T(c)
	OPTION(OPTIMIZE FOR (@_XmlTicket = NULL))

	SELECT @ActualResult = e.ActualResult, @WrongResult = e.WrongResult FROM #EventInfo e

	--Check Data	
	SELECT @ErrMsg = COALESCE(@ErrMsg, '') + CONVERT(VARCHAR(30), r.RowAt) + ', '
	FROM #TicketRefNo r
	WHERE EXISTS(
		SELECT TOP(1) 1
		FROM dbo.TicketAmendment_Detail t WITH(NOLOCK)
		CROSS APPLY
		(
			SELECT TOP 1 1 
			FROM dbo.TicketAmendment_Event e WITH(NOLOCK) 
			WHERE e.TicketEventId = t.TicketEventId AND e.ActualResult = @ActualResult AND e.WrongResult = @WrongResult AND e.MessageId = @MessageId
		) AS Ev(m)		
		WHERE t.CustId = r.CustId
			AND t.RefNo = r.RefNo
	)
	ORDER BY r.RowAt ASC

	SET @NoRows = @@ROWCOUNT

	IF @IsNotify = 0 OR @NoRows <> 0
	BEGIN
		IF @NoRows <> 0 
			SELECT @ErrCode = 200,
				   @ErrMsg = 'These tickets have been uploaded to notify headline, please check at row: ' + SUBSTRING(@ErrMsg, 1, LEN(@ErrMsg) - 1)
							 + CHAR(13) + CHAR(10) + 'Please remove them and upload the file again!'
		RETURN
	END

	UPDATE x
	SET x.ID = x.RowNum
	FROM
	(
		SELECT t.ID,  
			   ROW_NUMBER() OVER(ORDER BY t.HeadlineId ASC, t.CustId ASC) AS RowNum
		FROM #TicketRefNo t
	) x

	--Insert Event and Ticket
	BEGIN TRY
		INSERT INTO dbo.TicketAmendment_Event (ProductId, MatchId, MatchCode, EventType, EventDate, ActualResult, WrongResult, Status, MessageId)
		SELECT ProductId, MatchId, MatchCode, EventType, EventDate, ActualResult, WrongResult, NULL, MessageId
		FROM #EventInfo

		SET @EventId = SCOPE_IDENTITY()

		DECLARE @ID INT = 2000

		WHILE 1 = 1
		BEGIN 
			INSERT INTO dbo.TicketAmendment_Detail (CustId, RefNo, TicketEventId, RefTable, Bettype)
			SELECT t.CustId, t.RefNo, @EventId, t.RefTable, t.Bettype 
			FROM #TicketRefNo t 
			WHERE t.ID < @ID 
			ORDER BY t.ID

			IF @@ROWCOUNT = 0
				BREAK

			DELETE t FROM #TicketRefNo t WHERE t.ID < @ID 

			SET @ID += 2000
		END

		UPDATE TicketAmendment_Event WITH(ROWLOCK)
			SET Status = 'Completed'
		WHERE TicketEventId = @EventId
		
	END TRY
	BEGIN CATCH
		IF @EventId IS NOT NULL
		BEGIN
			DELETE dbo.TicketAmendment_Event WITH(ROWLOCK, UPDLOCK) WHERE TicketEventId = @EventId
			RETURN
		END
	END CATCH

	-- Delete ticket after 2 month
	DELETE dbo.TicketAmendment_Event WITH(ROWLOCK, UPDLOCK)
	OUTPUT deleted.TicketEventId
		INTO @EventTmp
	WHERE CreatedDate < DATEADD(MONTH, -2, GETDATE())

	IF @@ROWCOUNT <> 0
	BEGIN
		DELETE e
		FROM dbo.TicketAmendment_Detail  e WITH(ROWLOCK, UPDLOCK)
		WHERE EXISTS(SELECT TOP 1 1 FROM @EventTmp t WHERE t.EventId = e.TicketEventId)
	END

	DROP TABLE #EventInfo
	DROP TABLE #TicketRefNo
END