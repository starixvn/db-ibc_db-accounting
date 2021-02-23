/************************************************************************* 
 *   1. Add new fields to custinfo_history
 ************************************************************************/
ALTER TABLE dbo.CustInfo_history ADD
    DisableBingo BIT NULL DEFAULT 0,
    DisableNumber BIT NULL DEFAULT 0,
    SyncBingo BIT NULL DEFAULT 0,
    MaxPerMatch161 MONEY NULL DEFAULT 0,
    MaxPerMatch99MP MONEY NULL DEFAULT 0
GO

/************************************************************************* 
 *   2. Add new fields to CustSetting3rd_history
 ************************************************************************/
ALTER TABLE dbo.CustSetting3rd_history ADD
    alivepositiontaking SMALLMONEY NULL DEFAULT (0),
    mlivepositiontaking SMALLMONEY NULL DEFAULT (0),
    slivepositiontaking SMALLMONEY NULL DEFAULT (0),   
    autolivepositiontaking SMALLMONEY NULL DEFAULT (0),
    isautolivepositiontaking BIT NULL DEFAULT (0),
    autolivempositiontaking SMALLMONEY NULL DEFAULT (0),
    isautolivempositiontaking SMALLMONEY NULL DEFAULT (0)
GO



/************************************************************************* 
 *   3. Add new fields to custOverride3rd_history
 ************************************************************************/
ALTER TABLE dbo.custOverride3rd_history ADD
    minlivepositiontaking SMALLMONEY NULL DEFAULT (0),
    maxlivepositiontaking SMALLMONEY NULL DEFAULT (0.7)
GO
