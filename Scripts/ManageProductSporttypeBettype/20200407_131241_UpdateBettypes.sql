/*  
 Created by: 20200407@Malcolm
 Task: update typenamec of some bettypes[Redmine : #131241]  
 DB : DBPRO/bodb02 
*/
UPDATE t
SET t.typenamec = '&#20126;&#27954;&#30436;'
FROM bettype t
WHERE typeid = 1

UPDATE t
SET t.typenamec = '&#21934;&#38617;&#30436;'
FROM bettype t
WHERE typeid = 2

UPDATE t
SET t.typenamec = '&#22823;&#23567;&#30436;'
FROM bettype t
WHERE typeid = 3

UPDATE t
SET t.typenamec = '&#27874;&#33213;'
FROM bettype t
WHERE typeid = 4