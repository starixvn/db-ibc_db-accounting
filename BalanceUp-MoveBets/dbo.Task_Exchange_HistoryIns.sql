USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_Exchange_HistoryIns]    Script Date: 12/01/2009 23:19:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Exchange_HistoryIns    Script Date: 11/19/2009 1:20:30 PM ******/
ALTER PROCEDURE [dbo].[Task_Exchange_HistoryIns]
	@winlostdate	DATETIME
AS
/*	Created: Jamie
	Date: 2009-11-10
	Task: Job for storing currency daily 
	DB: DB052.BODB02 
*/
BEGIN
	SET NOCOUNT ON
	IF EXISTS (SELECT winlostdate FROM Exchange_History WITH (NOLOCK) WHERE winlostdate = @winlostdate)
	BEGIN
		DELETE FROM Exchange_History WHERE winlostdate = @winlostdate 
	END

	DECLARE	@USDRate FLOAT 
	DECLARE @tmpCurrency TABLE(	currency INT, actualrate FLOAT, USDRate FLOAT)
	SELECT	@USDRate = actualrate FROM Exchange WITH (NOLOCK) WHERE exchangeid = 3;

	INSERT INTO @tmpCurrency( currency, actualrate, USDRate)
	SELECT	f.currency, e.actualrate, e.actualrate/@USDRate  
	FROM	( SELECT DISTINCT currency FROM	dbo.f_DepSuperByCurrency('ALL') ) AS f
			INNER JOIN Exchange e WITH (NOLOCK) ON f.currency = e.exchangeid 

	INSERT INTO Exchange_History( 
		winlostdate, 
		currency, 
		actualrate, 
		USDRate,
		srecommendM88, 
		srecommend12BET, 
		srecommendAB88
	)
	SELECT	@winlostdate, 
			t.currency, 
			t.actualrate, 
			t.USDRate,
			ISNULL(m.custid,0) AS sM88 , 
			ISNULL(o.custid,0) AS s12BET, 
			ISNULL(a.custid,0) AS sAB88
	FROM	@tmpCurrency AS t 
			LEFT JOIN dbo.f_DepSuperByCurrency('Mansion88') m ON t.currency = m.currency 
			LEFT JOIN dbo.f_DepSuperByCurrency('12BET') o ON t.currency = o.currency 
			LEFT JOIN dbo.f_DepSuperByCurrency('Asiabet88') a ON t.currency = a.currency 
END