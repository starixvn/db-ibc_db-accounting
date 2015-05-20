

EXEC SP_RENAME 'custSetting_history', 'custSetting_history_main'
GO
EXEC SP_RENAME 'custSetting_history2', 'custSetting_history'
---
ALTER TABLE custSetting_history_main
ALTER COLUMN sporttype smallint
---

EXEC SP_RENAME 'custSetting_history', 'custSetting_history_del'
GO
EXEC SP_RENAME 'custSetting_history_main', 'custSetting_history'

-------

INSERT INTO custSetting_history (UpdateTime, custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, 
                      playerdiscount, discount, adiscount, sdiscount, groupa, groupb, groupc, groupd, minbet, maxbet, autopositiontaking, autolivepositiontaking, 
                      isautopositiontaking, isautolivepositiontaking, autompositiontaking, autolivempositiontaking, isautompositiontaking, isautolivempositiontaking)

SELECT     UpdateTime, custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, 
                      playerdiscount, discount, adiscount, sdiscount, groupa, groupb, groupc, groupd, minbet, maxbet, autopositiontaking, autolivepositiontaking, 
                      isautopositiontaking, isautolivepositiontaking, autompositiontaking, autolivempositiontaking, isautompositiontaking, isautolivempositiontaking
FROM         custSetting_history_del WITH (nolock)
----------
drop table custSetting_history_del

----------
