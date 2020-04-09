/*  
 Created by: 20200409@Malcolm
 Task: remove bettypes and sporttypes [Redmine : #131241]  
 DB : DBPRO/bodb02 
*/
DELETE bettype
WHERE typeid = 0

DELETE Sports
WHERE SportType = 0 OR SportType = 230