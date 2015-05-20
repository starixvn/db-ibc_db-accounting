ALTER TRIGGER [dbo].[custsetting_update] ON [dbo].[custSetting]

AFTER UPDATE

AS
/*
	Created by: ... 
	Task: Trigger for Updating CustSetting 
	DB: DB052.BODB02 
	
	Revisions: 
	
*/
    SET NOCOUNT ON;

INSERT INTO bodb_CustomerLog.dbo.custsetting_history (
                    custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking,
                      playerdiscount, discount, adiscount, sdiscount, groupa, groupb, groupc, groupd,
                        --groupe, groupf, --exclude these fields as they are not in use.
                    minbet, maxbet, autopositiontaking,
                      autolivepositiontaking, isautopositiontaking, isautolivepositiontaking, autompositiontaking, autolivempositiontaking, isautompositiontaking,
                      isautolivempositiontaking)
SELECT
                    custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking,
                      playerdiscount, discount, adiscount, sdiscount, groupa, groupb, groupc, groupd,
                        --groupe, groupf, --exclude these fields as they are not in use.
                    minbet, maxbet, autopositiontaking,
                      autolivepositiontaking, isautopositiontaking, isautolivepositiontaking, autompositiontaking, autolivempositiontaking, isautompositiontaking,
                      isautolivempositiontaking
FROM [DELETED]

GO
