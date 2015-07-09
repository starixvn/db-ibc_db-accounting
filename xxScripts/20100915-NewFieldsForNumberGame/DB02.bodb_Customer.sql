/************************************************************************* 
 *   1. Add new fields to custinfo_old
 ************************************************************************/
ALTER TABLE dbo.custInfo_old ADD
    DisableBingo BIT NULL,
    DisableNumber BIT NULL,
    SyncBingo BIT NULL,
    MaxPerMatch161 MONEY NULL,
    MaxPerMatch99MP MONEY NULL
GO

/************************************************************************* 
 *   2. Add new fields to CustSetting3rd_old
 ************************************************************************/

ALTER TABLE dbo.CustSetting3rd_old ADD
    alivepositiontaking SMALLMONEY NULL,
    mlivepositiontaking SMALLMONEY NULL,
    slivepositiontaking SMALLMONEY NULL,   
    autolivepositiontaking SMALLMONEY NULL,
    isautolivepositiontaking BIT NULL,
    autolivempositiontaking SMALLMONEY NULL,
    isautolivempositiontaking SMALLMONEY NULL
GO

