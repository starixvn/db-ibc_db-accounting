USE [bodb02]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[CustInfo_update] ON [dbo].[custInfo] AFTER UPDATE
AS
/*
Created by: 20120731@
Task: Trigger for updating Custinfo table 
DB: DBEXT/bodb02
Revisions: 
    - 20120731@Dan: add fields for Virtual soccer
    - 20120821@Elodie: add Abnormal fields to support Abnormal bets
    - 20120925@Dan: add fields for LCS-Win Limit
    - 20121004@Johnson: add double comm losing status
    - 20130125@Tom: add fields for Virtual Tennis
    - 20130221@Elodie: add field maxpermatch181 for Virtual Horse Racing
    - 20130604@Jamie: Add new field maxpermatch182 for Virtual Greyhound
    - 20130718@Lukas: add column DisableCasinoBonus 
    - 20130830@Jamie: Add MaxPerMatch184 for Virtual Motor Racing 
    - 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
    - 20131022@Lukas: add autosuspend2 for other sports [Redmine:#5520]
    - 20131022@Lukas: add maxpermatch for virtual Speedway & Cycling [Redmine:#5520]
    - 20140224@Elodie: Add Keno [Redmine:#11658]
    - 20140402@Lukas: add some columns that missed before 
         Disable151_AU
         Disable152_AU
         Disable152_UK
         Disable153_AU
         MaxPerMatch151_AU
         MaxPerMatch152_AU
         MaxPerMatch152_UK
         MaxPerMatch153_AU
    - 20141022@Logan: Add DisableEsports [Redmine: #20531]

*/
SET NOCOUNT ON
INSERT INTO bodb_CustomerLog.dbo.CustInfo_history (
                username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, autosuspend, reject, credit, closed, MatchLimit,
                  VirtualMultiplier, maxpermatch, maxpermatch2, maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, maxpermatch12,
                  maxpermatch99, [Enabled], danger, maxpermatch151, maxpermatch201, DisableHorseRacing, DisableFinancial, DisableCasino,
                  SyncCasino, danger2, danger3, DisableOutright, DisableOpenTote, maxpermatch151_OT
                  ,[DisableBingo]
                  ,[DisableNumber]
                  ,[SyncBingo]
                  ,[MaxPerMatch161]
                  ,[MaxPerMatch99MP]
                  ,[MaxPerBall161]
                  ,MaxtransferP2P
                  ,IsAutoResetP2P
                  ,DisableP2P
                  ,DisableFunP2P
                  ,DisableLiveCasino
                  ,SyncLiveCasino
                  ,DisableVirtualSports
                  ,HideVirtualSports
                  ,maxpermatch180
                  ,maxpermatch181
                  ,maxpermatch182
                  ,maxpermatch186
                  ,Abnormal
                  ,isAutoResetLiveCasino
                  ,MaxWinLiveCasino
                  ,DoubleCommLosing
                  ,DisableCasinoBonus 
                  ,maxpermatch184
                  ,MaxPerMatch154
                  ,DisableHRFixedOdds
                  ,autosuspend2
      ,maxpermatch183
      ,maxpermatch185
      ,HideKeno
      ,Disable151_AU
      ,Disable152_AU
      ,Disable152_UK
      ,Disable153_AU
      ,MaxPerMatch151_AU
      ,MaxPerMatch152_AU
      ,MaxPerMatch152_UK
      ,MaxPerMatch153_AU
      ,DisableEsports
                )
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
                  ,[MaxPerBall161]
                  ,MaxtransferP2P
                  ,IsAutoResetP2P
                  ,DisableP2P
                  ,DisableFunP2P
                  ,DisableLiveCasino
                  ,SyncLiveCasino
                  ,DisableVirtualSports
                  ,HideVirtualSports
                  ,maxpermatch180
                  ,maxpermatch181
                  ,maxpermatch182
                  ,maxpermatch186
                  ,Abnormal
                  ,isAutoResetLiveCasino
                  ,MaxWinLiveCasino
                  ,DoubleCommLosing
                  ,DisableCasinoBonus 
                  ,maxpermatch184
      ,MaxPerMatch154
                  ,DisableHRFixedOdds
                  ,autosuspend2
      ,maxpermatch183
      ,maxpermatch185
      ,HideKeno
      ,Disable151_AU
      ,Disable152_AU
      ,Disable152_UK
      ,Disable153_AU
      ,MaxPerMatch151_AU
      ,MaxPerMatch152_AU
      ,MaxPerMatch152_UK
      ,MaxPerMatch153_AU
      ,DisableEsports
FROM [DELETED]