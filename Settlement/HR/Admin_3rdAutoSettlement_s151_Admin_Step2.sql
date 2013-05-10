USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Admin_3rdAutoSettlement_s151_Admin_Step2]    Script Date: 09/07/2012 12:37:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[Admin_3rdAutoSettlement_s151_Admin_Step2]
	@LeagueID int,
	@raceNumber int,
	@eventdate smalldatetime,
	@programdate smalldatetime='',
	@Action varchar(10) = 'CAL'
AS
BEGIN
/* @Action input
CAL: (default) settle
REFUND: race abandon

Revisions:
	- 20100916@Jamie: Update changeTime for Outright table 
	- 20110617@Victor: Splitting POC SP , Mark That Part for New Create SP On TranDB works 
	- 20110902@Vivi: Add write log
	- 20120717@Cooper: add try catch 
	- 20120927@Elodie: No need to add dummy transaction into bettrans and backup table (bettrans2)
*/
    IF @programdate='' set @programdate=@eventdate

	-- Code to Log Message put here		
	Declare @LogData as nvarchar(300)
	SET @LogData = 'Calculate Result (' + @Action + ') [Admin_3rdAutoSettlement_s151_Admin_Step2] for Horse League ID:' + CAST(@LeagueID as nvarchar(20)) + ' race:' + CAST(@raceNumber as nvarchar(20)) + ' eventdate:' + CAST(@eventdate as nvarchar(20))+ ' programdate:' + CAST(@programdate as nvarchar(20))
	EXEC dbo.WriteLog_UserLog 151, @LogData
	
	-- start settlement
	IF @Action='CAL'
	BEGIN

		BEGIN TRY 
					EXEC dbo.Admin_3rdCalculate_s151_Reject_Admin @LeagueID, @raceNumber, @eventdate 
		END TRY
		BEGIN CATCH 
					SET @LogData = 'Admin_3rdAutoSettlement_s151_Admin_Step2_SET1_ErrorNumber:' + cast ( ERROR_NUMBER() as varchar(10) )
					+'.ErrorSeverity:' + cast ( ERROR_SEVERITY() as varchar(10))
					+'.ErrorState:' + cast ( ERROR_STATE() as varchar(10) )
					+'.ErrorProcedure:' + isnull(ERROR_PROCEDURE(),'')
					+'.ErrorLine:' + cast ( ERROR_LINE() as varchar(10) )
					+'.ErrorMessage:' +ERROR_MESSAGE() 
					EXEC dbo.WriteLog_UserLog 151, @LogData
		END CATCH
		BEGIN TRY
					EXEC dbo.Admin_3rdCalculate_s151_Admin @LeagueID, @raceNumber, @eventdate
		END TRY
		BEGIN CATCH
					SET @LogData = 'Admin_3rdAutoSettlement_s151_Admin_Step2_SET2_ErrorNumber:' + cast ( ERROR_NUMBER() as varchar(10) )
					+'.ErrorSeverity:' + cast ( ERROR_SEVERITY() as varchar(10))
					+'.ErrorState:' + cast ( ERROR_STATE() as varchar(10) )
					+'.ErrorProcedure:' + isnull(ERROR_PROCEDURE(),'')
					+'.ErrorLine:' + cast ( ERROR_LINE() as varchar(10) )
					+'.ErrorMessage:' +ERROR_MESSAGE() 
					EXEC dbo.WriteLog_UserLog 151, @LogData
		END CATCH	
		-- 20120927@Elodie: No need to add dummy transaction into bettrans and backup table (bettrans2)
		/*
		BEGIN TRY
					EXEC dbo.Admin_3rdDummyTransfer_s151_Admin @LeagueID, @raceNumber, @eventdate ,@programdate
		END TRY
		BEGIN CATCH
					SET @LogData = 'Admin_3rdAutoSettlement_s151_Admin_Step2_SET3_ErrorNumber:' + cast ( ERROR_NUMBER() as varchar(10) )
					+'.ErrorSeverity:' + cast ( ERROR_SEVERITY() as varchar(10))
					+'.ErrorState:' + cast ( ERROR_STATE() as varchar(10) )
					+'.ErrorProcedure:' + isnull(ERROR_PROCEDURE(),'')
					+'.ErrorLine:' + cast ( ERROR_LINE() as varchar(10) )
					+'.ErrorMessage:' +ERROR_MESSAGE() 	
					EXEC dbo.WriteLog_UserLog 151, @LogData
		END CATCH
		*/
	END
	ELSE
	BEGIN
		-- REFUND
		EXEC dbo.Admin_3rdCalculate_s151_Refund_Admin @LeagueID, @raceNumber, @eventdate
	END
END

GO
GRANT EXECUTE ON [dbo].[Admin_3rdAutoSettlement_s151_Admin_Step2] TO [Dot_3rdparty]
GO
GRANT EXECUTE ON [dbo].[Admin_3rdAutoSettlement_s151_Admin_Step2] TO [Dot_Admin]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdAutoSettlement_s151_Admin_Step2] TO [vnteam]