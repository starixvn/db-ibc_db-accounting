 /*
	Created by:Jamie@20110523
	Task: Insert new types for transfer with new ranges and delete old bet types 

*/

INSERT INTO [bodb02].[dbo].[bettype]
           ([typeid]
           ,[typenamee]
           ,[typenamec]
           ,[typedesc]
           ,[creator]
           ,[typenamec_uni]
           ,[typenamej]
           ,[typenamcn]
           ,[typenamecn]
           ,[typenameth]
           ,[typenameit]
           ,[typenameko]
           ,[typenameES]
           ,[typenameVN]
           ,[typenameEL]
           ,[typenamee_Eu])

SELECT	case typeid	when 99 then 19999
					when 100 then 20000
					when 101 then 21001
					when 102 then 21002
					when 103 then 21003
					when 104 then 21004
					when 105 then 21005
					when 106 then 21006
					when 107 then 22001
					when 108 then 22002
					when 109 then 22003
					when 110 then 22004
					when 111 then 22005
					when 115 then 22006
					when 116 then 22007
					when 112 then 23001
					when 113 then 23002
					when 114 then 23101
					when 117 then 23201
					when 118 then 23202
					else 0 end
      ,[typenamee]
      ,[typenamec]
      ,[typedesc]
      ,[creator]
      ,[typenamec_uni]
      ,[typenamej]
      ,[typenamcn]
      ,[typenamecn]
      ,[typenameth]
      ,[typenameit]
      ,[typenameko]
      ,[typenameES]
      ,[typenameVN]
      ,[typenameEL]
      ,[typenamee_Eu]
FROM [bodb02].[dbo].[bettype] WITH (NOLOCK)
WHERE typeID BETWEEN 100 AND 118 

/*
--delete old types 
delete from bettype with (rowlock)
where typeid between 100 and 118


*/