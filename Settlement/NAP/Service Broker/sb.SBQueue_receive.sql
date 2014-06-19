ALTER PROCEDURE [sb].[SBQueue_receive]
AS
/*  Created: Viet @ 20140210
	Task : queue receive
	DB: bodb02 @ DB052/DB053/DB054/DB06
	Revisions:  
		- 20140619@Viet: send email to DBA once transaction is doomed.
			
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @conversation_handle UNIQUEIDENTIFIER
	DECLARE @message_type SYSNAME
	DECLARE @message_body NVARCHAR(MAX)

	-- Error variables.
	DECLARE @error_number INT
	DECLARE @error_message VARCHAR(4000)
	DECLARE @error_severity INT
	DECLARE @error_state INT
	DECLARE @error_procedure SYSNAME
	DECLARE @error_line INT
	DECLARE @error_dialog VARCHAR(50)

	BEGIN TRY
		BEGIN TRANSACTION
		
		WAITFOR (
			RECEIVE TOP (1)		   
			   @conversation_handle = [conversation_handle],
			   @message_type = [message_type_name],
			   @message_body = CONVERT(nvarchar(max),[message_body])
			FROM [dbo].[//Queue/Calculation_receive]	
			), TIMEOUT 100 -- if the queue is empty for 100 miliseconds, give up and go away
					
			IF @@ROWCOUNT > 0
			BEGIN
				BEGIN TRY
					IF @message_type IN ('//Message/Calculation')
					BEGIN					
						DECLARE @starttime datetime, @duration int
						SET @starttime = CURRENT_TIMESTAMP
						-- put your code here	
													
						EXEC sp_executesql @message_body
						
						-- viet test: will remove this later	
						SET @duration = datediff(second, @starttime, CURRENT_TIMESTAMP)
						INSERT INTO sb.Logs(message_type, message_body, duration) 
						VALUES(@message_type, @message_body, @duration)		
						-- / viet test: will remove this later					
									
					END
					ELSE IF @message_type = '//Message/EndOfStream'
					BEGIN
						-- initiator is signaling end of message stream: end the dialog
						END CONVERSATION @conversation_handle
					END
					ELSE IF @message_type = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
					BEGIN
						-- If the message_type indicates that the message is an error,
						-- raise the error and end the conversation.
						WITH XMLNAMESPACES ('http://schemas.microsoft.com/SQL/ServiceBroker/Error' AS sb)
						SELECT
							@error_number = CAST(@message_body AS XML).value('(//sb:Error/sb:Code)[1]', 'INT'),
							@error_message = CAST(@message_body AS XML).value('(//sb:Error/sb:Description)[1]', 'VARCHAR(4000)')
						
						SET @error_dialog = CAST(@conversation_handle AS VARCHAR(50))
						RAISERROR('Error in dialog %s: %s (%i)', 16, 1, @error_dialog, @error_message, @error_number)
						
						END CONVERSATION @conversation_handle
					END
				END TRY
				BEGIN CATCH
					SET @error_number = ERROR_NUMBER()
					SET @error_message = ERROR_MESSAGE()
					SET @error_severity = ERROR_SEVERITY()
					SET @error_state = ERROR_STATE()
					SET @error_procedure = ERROR_PROCEDURE()
					SET @error_line = ERROR_LINE()

					IF XACT_STATE() = -1
					BEGIN
						-- The transaction is doomed. Only rollback possible.
						-- This could disable the queue if done 5 times consecutively!
						ROLLBACK TRANSACTION

						-- Record the error.
						BEGIN TRANSACTION
							INSERT INTO [sb].[ProcessingErrors] (error_conversation, error_number, error_message, error_severity, error_state, error_procedure, error_line, doomed_transaction, [message])
							VALUES(NULL, @error_number, @error_message, @error_severity, @error_state, @error_procedure, @error_line, 1, @message_body)
						COMMIT

						-- For this level of error, it is best to exit the proc
						-- and give the queue monitor control.
						-- Breaking to the outer catch will accomplish this.
						RAISERROR ('Message processing error', 16, 1)
					END
					ELSE IF XACT_STATE() = 1
					BEGIN
						-- Record error and continue processing messages.
						-- Failing message could also be put aside for later processing here.
						-- Otherwise it will be discarded.
						INSERT INTO [sb].[ProcessingErrors] (error_conversation, error_number, error_message, error_severity, error_state, error_procedure, error_line, doomed_transaction, [message])
						VALUES(NULL, @error_number, @error_message, @error_severity, @error_state, @error_procedure, @error_line, 0, @message_body)
					END
				END CATCH
			END		
			
			COMMIT
	END TRY		
	BEGIN CATCH
		-- Process the error and exit the proc to give the queue monitor control
		SET @error_number = ERROR_NUMBER()
		SET @error_message = ERROR_MESSAGE()
		SET @error_severity = ERROR_SEVERITY()
		SET @error_state = ERROR_STATE()
		SET @error_procedure = ERROR_PROCEDURE()
		SET @error_line = ERROR_LINE()

		IF XACT_STATE() = -1
		BEGIN
			-- The transaction is doomed. Only rollback possible.
			-- This could disable the queue if done 5 times consecutively!
			ROLLBACK TRANSACTION

			-- Record the error.
			BEGIN TRANSACTION
				INSERT INTO [sb].[ProcessingErrors] (error_conversation, error_number, error_message, error_severity, error_state, error_procedure, error_line, doomed_transaction)
				VALUES(NULL, @error_number, @error_message, @error_severity, @error_state, @error_procedure, @error_line, 1)
			COMMIT
			
			-- SEND warning email to DBA
			BEGIN TRANSACTION
				DECLARE @body VARCHAR(MAX), @profile_name SYSNAME
				
				SELECT TOP (1) @profile_name = name FROM MSDB.dbo.sysmail_profile								
				SET @body = 'Hi There, '+char(13)+char(13)
				SELECT @body = char(13) + 'ERROR: ' + @error_message + char(13) + '--------------------------------' + char(13)
				SELECT @body = @body + char(13) + 'NOTEs: The transaction is doomed. This could disable the queue-receive if done 5 times consecutively!'
				SELECT @body = @body + char(13) + char(13) + '-- SELECT TOP(5) * FROM sb.ProcessingErrors WITH(NOLOCK) ORDER BY updatedtime DESC'
								
				EXEC msdb.dbo.sp_send_dbmail
				@recipients=N'dbaadmin@starixsoft.com',
				@body=@body,
				@sensitivity ='Personal',
				@importance ='High',				
				@copy_recipients ='dbaadmin@onelab.tw',
				@subject ='CRITICAL: Service broker problem notification',
				@profile_name =@profile_name;
			COMMIT
			-------------------------------
		END
		ELSE IF XACT_STATE() = 1
		BEGIN
			-- Record error and commit transaction.
			INSERT INTO [sb].[ProcessingErrors] (error_conversation, error_number, error_message, error_severity, error_state, error_procedure, error_line, doomed_transaction)
			VALUES(NULL, @error_number, @error_message, @error_severity, @error_state, @error_procedure, @error_line, 0)
			
			COMMIT
		END
	END CATCH
END

GO
GRANT VIEW DEFINITION ON [sb].[SBQueue_receive] TO [vnteam] AS [dbo]
