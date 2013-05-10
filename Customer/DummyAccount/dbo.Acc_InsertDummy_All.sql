ALTER PROCEDURE [dbo].[Acc_InsertDummy_All]
	@CurrencyName		VARCHAR(10),
	@FIOffered			BIT = 1, -- Always checked in creating a new currency 
	@CSOffered			BIT = 1, -- Always checked in creating a new currency 
	@HRToteOffered		BIT = 1,
	@HRFixedOffered		BIT = 1,
	@AB88Offered		BIT = 1,
	@AB88CSOffered		BIT = 1,
	@12BETOffered		BIT = 1,
	@Mansion88Offered	BIT = 1,
	@BIOffered			BIT = 1,
	@NGOffered			BIT = 1,
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

Param's Explanation:
• @CurrencyName: input currency to create related dummies, this currency must be added to table exchange before

*/

SET NOCOUNT ON 
-- Finance Dummy 
IF @FIOffered = 1
BEGIN
	EXEC [dbo].[Acc_InsertDummyFI]
		@currencyName = @currencyName,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
END 
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

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_InsertDummy_All] TO [vnteam]