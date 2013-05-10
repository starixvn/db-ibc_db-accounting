set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Acc_InsertDummy_All]
	@CurrencyName		VARCHAR(10),
	--@FIOffered			BIT = 1, -- Always checked in creating a new currency 
	@CSOffered			BIT = 1, -- Always checked in creating a new currency 
	@HRToteOffered		BIT = 1,
	@HRFixedOffered		BIT = 1,
	@AB88Offered		BIT = 1,
	@AB88CSOffered		BIT = 1,
	@12BETOffered		BIT = 1,
	@Mansion88Offered	BIT = 1,
	@BIOffered			BIT = 1,
	@NGOffered			BIT = 1,
	@DELAOffered		BIT = 1,
	@SPONOffered		BIT = 1,
	@TLCOffered			BIT = 1,
	@Z88Offered			BIT	= 1,--Zzun88 site
	@SCOffered			BIT = 1,--SunCity site
	@MFOffered			BIT	= 1,--MayFair site
	@HAIFAOffered		BIT = 1,--Haifa site
	@BODOGOffered		BIT = 1,--Bodog site
	@VWINOffered		BIT = 1,--Vwin
	@SG8Offered			BIT = 1,--Silver Goose88
	@GalaxyOffered		BIT	= 1,--Galaxy
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				VARCHAR(100) = '' OUTPUT	
AS
/*
Created: Jamie
Date: 2009-07-04
Task : Insert all dummy accounts based on new-added currencty
DB: DB02.bodb02
Original:

Revisions:
	- 20100406@Jamie: Add two param for checking whether create dummy FI and CS or not 
	- 20101005@Henry: Add Bingo and Number Game
	- 20101105@Henry: Add DELA and Spondemo site
	- 20101123@Henry: Add TLC site
	- 20110120@Johnson: Add Zzun88, SunCity, MayFair sites
	- 20111118@Kiwi: Add Haifa, Bodog, Vwin, Silver, Galaxy
Param's Explanation:
• @CurrencyName: input currency to create related dummies, this currency must be added to table exchange before

*/

SET NOCOUNT ON 
-- Finance Dummy 
/*IF @FIOffered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummyFI]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END */
-- Casino Dummy
IF @CSOffered = 1 
BEGIN
	EXEC [dbo].[Acc_InsertDummyCS]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END
-- AB88 Casino 
IF @AB88CSOffered = 1 
BEGIN 
	EXEC [dbo].[Acc_InsertDummyAB88CS]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END 

-- Horse Racing Tote Dummy 
IF @HRToteOffered = 1 
BEGIN
	EXEC [dbo].[Acc_InsertDummyHRTote]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

-- Horse Racing Fixed Dummy 
IF @HRFixedOffered = 1 
BEGIN
	EXEC [dbo].[Acc_InsertDummyHRFixed]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

-- AsiaBet88 
IF @AB88Offered = 1 
BEGIN
	EXEC [dbo].[Acc_InsertDummyAB88]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

-- 12BET 
IF @12BETOffered = 1 
BEGIN
	EXEC [dbo].[Acc_InsertDummy12BET]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--Mansion88
IF @Mansion88Offered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummyMansion88]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END 

--Bingo
IF @BIOffered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummyBI]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--Number Game
IF @NGOffered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummyNG]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--DELA
IF @DELAOffered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummyDELA]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--Spondemo
IF @SPONOffered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummySPONDEMO]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--TLC
IF @TLCOffered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummyTLC]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

-- Zzun88
IF @Z88Offered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummyZzun88]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

-- SunCity
IF @SCOffered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummySunCity]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

-- MayFair
IF @MFOffered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummyMayFair]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--HAIFA
IF @HAIFAOffered =1 
BEGIN
	EXEC [dbo].[Acc_InsertDummyHAIFA]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--Bodog
IF @BODOGOffered =1 
BEGIN
	EXEC [dbo].[Acc_InsertDummyBodog]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--Vwin
IF @VWINOffered =1 
BEGIN
	EXEC [dbo].[Acc_InsertDummyVwin]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--Silver Goose88
IF @SG8Offered =1 
BEGIN
	EXEC [dbo].[Acc_InsertDummySG8]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END

--Galaxy
IF @GalaxyOffered =1 
BEGIN
	EXEC [dbo].[Acc_InsertDummyGalaxy]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END
