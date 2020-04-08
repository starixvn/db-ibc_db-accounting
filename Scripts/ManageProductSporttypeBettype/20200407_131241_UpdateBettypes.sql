/*  
 Created by: 20200407@Malcolm
 Task: update typenamec of some bettypes[Redmine : #131241]  
 DB : DBPRO/bodb02 
*/
UPDATE t
SET t.typenamec = N'亞洲盤'
FROM bettype t
WHERE typeid = 1

UPDATE t
SET t.typenamcn = N'亚洲盘'
FROM bettype t
WHERE typeid = 1

UPDATE t
SET t.typenamec = N'單雙盤'
FROM bettype t
WHERE typeid = 2

UPDATE t
SET t.typenamec = N'大小盤'
FROM bettype t
WHERE typeid = 3

UPDATE t
SET t.typenamec = N'波膽'
FROM bettype t
WHERE typeid = 4

UPDATE t
SET t.typenamec = N'總進球'
FROM bettype t
WHERE typeid = 6

UPDATE t
SET t.typenamec = N'上半場亚洲盤'
FROM bettype t
WHERE typeid = 7

UPDATE t
SET t.typenamec = N'上半場大小盤'
FROM bettype t
WHERE typeid = 8

UPDATE t
SET t.typenamec = N'混合過關'
FROM bettype t
WHERE typeid = 9

UPDATE t
SET t.typenamec = N'優勝冠軍'
FROM bettype t
WHERE typeid = 10