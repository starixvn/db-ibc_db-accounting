ALTER TRIGGER [dbo].[custsetting3rd_update] ON [dbo].[CustSetting3rd]
AFTER UPDATE
AS
/*
	Created by: ... 
	Task: Trigger for Updating CustSetting3rd  
	DB: DB052.BODB02 
	
	Revisions: 
	
*/
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


