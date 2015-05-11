     SELECT    b.currency, e.currency,                   
                        sum(winlost) TurnOver_origin
                FROM bettrans14 b with (nolock)  
                    inner join exchange e (nolock) on b.currency = e.exchangeid            
                WHERE
                    ruben =1 and bettype in (31,32,33)
                    and winlostdate = '2009-03-21'
                    and custid in (
								1150907, --	TO4HREURO
								1150932, --	TO4HRGBP
								1151036, --	TO4HRHK$
								1150973, --	TO4HRRM
								1151020, --	TO4HRRMB
								1151004, --	TO4HRSD$
								1150880, --	TO4HRUS$
								1249344, -- TO4HRNTD
								1249364, -- TO4HRIRR
								1249373, -- TO4HRY$US
								1249353, -- TO4HR$US
								1249383, -- TO4HRYen
								1493975	 --TO4HRTB
							 )

    group by b.currency, e.currency