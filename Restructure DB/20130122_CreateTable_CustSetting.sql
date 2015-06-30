 CREATE TABLE CustSetting_Member(
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype SMALLINT NOT NULL,
    islive BIT NOT NULL,    
    apositiontaking    TINYINT    NOT NULL,
    mpositiontaking    TINYINT    NOT NULL,
    spositiontaking    TINYINT    NOT NULL, 
    isautopositiontaking BIT NOT NULL,
    autopositiontaking TINYINT NOT NULL,
    isautompositiontaking BIT NOT NULL,
    autompositiontaking    TINYINT NOT NULL,
 CONSTRAINT [PK_CustSetting_Member] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC,
    [islive] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE CustSetting_Agent(    
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype SMALLINT NOT NULL,
    islive BIT NOT NULL,    
    apositiontaking    TINYINT    NOT NULL,
    mpositiontaking    TINYINT    NOT NULL,
    spositiontaking    TINYINT    NOT NULL, 
    isautopositiontaking BIT NOT NULL,
    autopositiontaking TINYINT NOT NULL,
    isautompositiontaking BIT NOT NULL,
    autompositiontaking    TINYINT NOT NULL,
    minPositiontaking TINYINT NOT NULL,
    maxPositiontaking TINYINT NOT NULL,
 CONSTRAINT [PK_CustSetting_Agent] PRIMARY KEY CLUSTERED 
(
    custid ASC,
    sporttype ASC,
    bettype ASC,
    islive ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE CustDiscount_Member(        
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    playerdiscount DECIMAL(9,8) NOT NULL,
    discount DECIMAL(9,8) NOT NULL,
    adiscount DECIMAL(9,8) NOT NULL,
    sdiscount DECIMAL(9,8) NOT NULL,
 CONSTRAINT [PK_CustDiscount_Member] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE CustDiscount_Agent(   
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    discounta DECIMAL(9,8) NOT NULL,
    discountb DECIMAL(9,8) NOT NULL,
    discountc DECIMAL(9,8) NOT NULL,
    discountd DECIMAL(9,8) NOT NULL,    
 CONSTRAINT [PK_CustDiscount_Agent] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE CustSetting_Bet(        
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    minbet MONEY NOT NULL,
    maxbet MONEY NOT NULL,
    maxpermatch    MONEY NOT NULL,
 CONSTRAINT [PK_CustSetting_Bet] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/*-------------------------------------------------------------------------------------------*/
CREATE TABLE CustSetting3rd_Member(
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype SMALLINT NOT NULL,
    islive BIT NOT NULL,    
    apositiontaking    TINYINT    NOT NULL,
    mpositiontaking    TINYINT    NOT NULL,
    spositiontaking    TINYINT    NOT NULL, 
    isautopositiontaking BIT NOT NULL,
    autopositiontaking TINYINT NOT NULL,
    isautompositiontaking BIT NOT NULL,
    autompositiontaking    TINYINT NOT NULL,
 CONSTRAINT [PK_CustSetting3rd_Member] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC,
    [islive] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE CustSetting3rd_Agent(       
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype SMALLINT NOT NULL,
    islive BIT NOT NULL,    
    apositiontaking    TINYINT    NOT NULL,
    mpositiontaking    TINYINT    NOT NULL,
    spositiontaking    TINYINT    NOT NULL, 
    isautopositiontaking BIT NOT NULL,
    autopositiontaking TINYINT NOT NULL,
    isautompositiontaking BIT NOT NULL,
    autompositiontaking    TINYINT NOT NULL,
    minPositiontaking TINYINT NOT NULL,
    maxPositiontaking TINYINT NOT NULL,
 CONSTRAINT [PK_CustSetting3rd_Agent] PRIMARY KEY CLUSTERED 
(
    custid ASC,
    sporttype ASC,
    bettype ASC,
    islive ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE CustDiscount3rd_Member(        
    custid INT    NOT NULL,
    sporttype SMALLINT    NOT NULL,
    bettype    SMALLINT    NOT NULL,
    playerdiscount DECIMAL(9,8)NOT NULL,
    discount DECIMAL(9,8)NOT NULL,
    adiscount DECIMAL(9,8)NOT NULL,
    sdiscount DECIMAL(9,8)NOT NULL,
 CONSTRAINT [PK_CustDiscount3rd_Member] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE CustDiscount3rd_Agent(   
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    discounta DECIMAL(9,8) NOT NULL,    
 CONSTRAINT [PK_CustDiscount3rd_Agent] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE CustSetting3rd_Bet(        
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    minbet MONEY NOT NULL,
    maxbet MONEY NOT NULL,
    maxpermatch    MONEY NOT NULL,
    maxperball MONEY NOT NULL,    
 CONSTRAINT [PK_CustSetting3rd_Bet] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/*-------------------------------------------------------------------------------------------*/
CREATE TABLE Dep_CustSetting_Member(   
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype SMALLINT NOT NULL,
    islive BIT NOT NULL,    
    apositiontaking    TINYINT    NOT NULL,
    mpositiontaking    TINYINT    NOT NULL,
    spositiontaking    TINYINT    NOT NULL,    
 CONSTRAINT [PK_Dep_CustSetting_Member] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC,
    [islive] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE Dep_CustSetting_Agent(    
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype SMALLINT NOT NULL,
    islive BIT NOT NULL,    
    apositiontaking    TINYINT    NOT NULL,
    mpositiontaking    TINYINT    NOT NULL,
    spositiontaking    TINYINT    NOT NULL,     
    minPositiontaking TINYINT NOT NULL,
    maxPositiontaking TINYINT NOT NULL,
 CONSTRAINT [PK_Dep_CustSetting_Agent] PRIMARY KEY CLUSTERED 
(
    custid ASC,
    sporttype ASC,
    bettype ASC,
    islive ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE Dep_CustDiscount_Member(        
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    playerdiscount DECIMAL(9,8) NOT NULL,
    discount DECIMAL(9,8) NOT NULL,
    adiscount DECIMAL(9,8) NOT NULL,
    sdiscount DECIMAL(9,8) NOT NULL,
 CONSTRAINT [PK_Dep_CustDiscount_Member] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE Dep_CustDiscount_Agent(   
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    discounta DECIMAL(9,8) NOT NULL,
 CONSTRAINT [PK_Dep_CustDiscount_Agent] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE Dep_CustSetting_Bet(        
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    minbet MONEY NOT NULL,
    maxbet MONEY NOT NULL,
    maxpermatch    MONEY NOT NULL,
 CONSTRAINT [PK_Dep_CustSetting_Bet] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/*-------------------------------------------------------------------------------------------*/
CREATE TABLE Dep_CustSetting3rd_Member(
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype SMALLINT NOT NULL,
    islive BIT NOT NULL,    
    apositiontaking    TINYINT    NOT NULL,
    mpositiontaking    TINYINT    NOT NULL,
    spositiontaking    TINYINT    NOT NULL,   
 CONSTRAINT [PK_Dep_CustSetting3rd_Member] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC,
    [islive] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE Dep_CustSetting3rd_Agent(    
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype SMALLINT NOT NULL,
    islive BIT NOT NULL,    
    apositiontaking    TINYINT    NOT NULL,
    mpositiontaking    TINYINT    NOT NULL,
    spositiontaking    TINYINT    NOT NULL,     
    minPositiontaking TINYINT NOT NULL,
    maxPositiontaking TINYINT NOT NULL,
 CONSTRAINT [PK_Dep_CustSetting3rd_Agent] PRIMARY KEY CLUSTERED 
(
    custid ASC,
    sporttype ASC,
    bettype ASC,
    islive ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE Dep_CustDiscount3rd_Member(        
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    playerdiscount DECIMAL(9,8) NOT NULL,
    discount DECIMAL(9,8) NOT NULL,
    adiscount DECIMAL(9,8) NOT NULL,
    sdiscount DECIMAL(9,8) NOT NULL,
 CONSTRAINT [PK_Dep_CustDiscount3rd_Member] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE Dep_CustDiscount3rd_Agent(   
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    discounta DECIMAL(9,8) NOT NULL,
 CONSTRAINT [PK_Dep_CustDiscount3rd_Agent] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE Dep_CustSetting3rd_Bet(        
    custid INT NOT NULL,
    sporttype SMALLINT NOT NULL,
    bettype    SMALLINT NOT NULL,
    minbet MONEY NOT NULL,
    maxbet MONEY NOT NULL,
    maxpermatch    MONEY NOT NULL,
    maxperball MONEY NOT NULL,
 CONSTRAINT [PK_Dep_CustSetting3rd_Bet] PRIMARY KEY CLUSTERED 
(
    [custid] ASC,
    [sporttype] ASC,
    [bettype] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO