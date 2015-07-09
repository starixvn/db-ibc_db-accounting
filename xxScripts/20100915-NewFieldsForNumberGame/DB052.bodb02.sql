-- TRIGGER DB052.bodb02.dbo.[dbo].[CustInfo_update]
ALTER TRIGGER [dbo].[CustInfo_update] ON [dbo].[custInfo]
AFTER UPDATE
AS
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

INSERT INTO bodb_CustomerLog.dbo.CustInfo_history (
                    username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, reject, credit, closed, MatchLimit,
                      VirtualMultiplier, maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, maxpermatch12,
                      maxpermatch99, [Enabled], danger, maxpermatch151, maxpermatch201, DisableHorseRacing, DisableFinancial, DisableCasino,
                      SyncCasino, danger2, danger3, DisableOutright, DisableOpenTote, maxpermatch151_OT
                      ,[DisableBingo]
                      ,[DisableNumber]
                      ,[SyncBingo]
                      ,[MaxPerMatch161]
                      ,[MaxPerMatch99MP])
SELECT
                    username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, reject, credit, closed, MatchLimit,
                      VirtualMultiplier, maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, maxpermatch12,
                      maxpermatch99, [Enabled], danger, maxpermatch151, maxpermatch201, DisableHorseRacing, DisableFinancial, DisableCasino,
                      SyncCasino, danger2, danger3, DisableOutright, DisableOpenTote, maxpermatch151_OT
                      ,[DisableBingo]
                      ,[DisableNumber]
                      ,[SyncBingo]
                      ,[MaxPerMatch161]
                      ,[MaxPerMatch99MP]
FROM [DELETED]
GO

-- TRIGGER DB052.bodb02.dbo.[dbo].[custsetting3rd_update]
ALTER TRIGGER [dbo].[custsetting3rd_update] ON [dbo].[CustSetting3rd]
AFTER UPDATE
AS
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
SET NOCOUNT ON;

INSERT INTO bodb_CustomerLog.dbo.custsetting3rd_history
        (    custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking,
            playerdiscount, discount, adiscount, sdiscount,
            minbet, maxbet, autopositiontaking,
            isautopositiontaking, autompositiontaking, isautompositiontaking
            ,[alivepositiontaking]
          ,[mlivepositiontaking]
          ,[slivepositiontaking]
          ,[autolivepositiontaking]
          ,[isautolivepositiontaking]
          ,[autolivempositiontaking]
          ,[isautolivempositiontaking])
SELECT
            custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking,
            playerdiscount, discount, adiscount, sdiscount,
            minbet, maxbet, autopositiontaking,
            isautopositiontaking, autompositiontaking, isautompositiontaking
            ,[alivepositiontaking]
          ,[mlivepositiontaking]
          ,[slivepositiontaking]
          ,[autolivepositiontaking]
          ,[isautolivepositiontaking]
          ,[autolivempositiontaking]
          ,[isautolivempositiontaking]
FROM [DELETED]
GO

-- TRIGGER DB052.bodb02.dbo.[dbo].[custOverride3rd_update]
ALTER TRIGGER [dbo].[custOverride3rd_update] ON [dbo].[custOverride3rd]
AFTER UPDATE
AS
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

INSERT INTO bodb_CustomerLog.dbo.custOverride3rd_history
                (custid, bettype, sporttype, minpositiontaking,maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
SELECT
                custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking
FROM [DELETED]
GO