

/*
	Insert default setting for some offered currencies
*/

INSERT INTO P2PDefaultSetting (Currency, MinCredit, MaxCredit, Maxsdiscount, Maxadiscount,Maxdiscount,MaxPlayerdiscount)
SELECT 9, 100, 100000, 0.7, 0.55, 0.4, 0.3  -- AUD
UNION ALL
SELECT 32, 7500, 7500000, 0.7, 0.55, 0.4, 0.3  -- JPY
UNION ALL
SELECT 30, 3000, 3000000, 0.7, 0.55, 0.4, 0.3  -- NT
UNION ALL
SELECT 37, 100, 100000, 0.7, 0.55, 0.4, 0.3 --- P
UNION ALL
SELECT 44, 1000, 1000000, 0.7, 0.55, 0.4, 0.3 --- PT
UNION ALL
SELECT 31, 7500, 7500000, 0.7, 0.55, 0.4, 0.3 -- Pts
UNION ALL
SELECT 4, 3000, 3000000, 0.7, 0.55, 0.4, 0.3 -- TB



/*
	Insert default setting for currencies not offered yet
*/
INSERT INTO P2PDefaultSetting (Currency, MinCredit, MaxCredit, Maxsdiscount, Maxadiscount,Maxdiscount,MaxPlayerdiscount)
SELECT exchangeid , 0, 0, 0, 0, 0, 0
FROM exchange e WITH(NOLOCK)
WHERE description <> 'Unused'
AND exchangeID NOT IN (SELECT currency FROM P2PDefaultSetting WITH(NOLOCK))