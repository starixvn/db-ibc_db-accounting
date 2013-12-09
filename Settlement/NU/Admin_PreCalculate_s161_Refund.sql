USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Admin_PreCalculate_s161_Refund]    Script Date: 12/9/2013 12:31:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Admin_PreCalculate_s161_Refund] @matchid INT
	,@action VARCHAR(10) = 'Refund-FT' -- Refund / Refund-FT
AS
/*
	Created by:[Viet]
	Date:[20131208]
	Task: Settlement (Refund) 
	Original SP: Admin_Calculate_s161_Refund
	DB: DBTXN/BODB02		

	Revisions:		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IgnoreList VARCHAR(200)
	SET @IgnoreList = 'DB04,DB042,DB043,DB044'

	DECLARE @_xml XML, @_sXML VARCHAR(MAX)

	SET @_xml = '<root><r matchid="'+ CONVERT(VARCHAR(12), @matchid) +'" action="'+ @action +'" /></root>'

	SELECT @_sXML = CONVERT(VARCHAR(max), @_xml)

	EXEC dbo.Bet_ExecRep_05 @IgnoreList = @IgnoreList
		,@updatetype = 4 --refund NG
		,@_sXML = @_sXML		
END

