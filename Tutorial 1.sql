Create database SMS_May2024
 
Create Table Customer(
CustID varchar(5) primary key,
CustName varchar(100) not null,
Phone varchar(20),
Email varchar(200),
)
 
 
Create Table Product
(
ProductCode	Varchar(10) primary key,
ProductName	Varchar(100) unique,
CostPrice	Decimal(7,2),
SalePrice	Decimal(7,2)
)
 
Create Table [Transaction]
(
TransactionID	Int identity(1,1) primary key,
CustID	Varchar(5) references Customer(CustiD),
TransactionDate DateTime
)
 
Create Table [TransactionItem]
(
TransactionItemID int primary key identity(1,1),
TransactionID int references [Transaction](TransactionID),
ProductCode	Varchar(10) references Product(ProductCode),
Quantity Int
)

select * from Customer
insert into Customer Values
('C100','Ali','019456789','ali@yahoo.com'),
('C200','Chong','019456789','chong@yahoo.com')
 
select * from Product
insert into Product Values
('P10000','Chair',100,200),
('P20000','Table',300,500),
('P30000','Drawer',150,250)
 
select * from [Transaction]
insert into [Transaction] (CustID, TransactionDate)
values ('C100',getdate()-30)
insert into [Transaction] (CustID, TransactionDate)
values ('C100',getdate()-15)
insert into [Transaction] (CustID, TransactionDate)
values ('C100',getdate()-15)
 
select * from TransactionItem
insert into TransactionItem (TransactionID, ProductCode, Quantity)
values  ( 1, 'P10000',3)
insert into TransactionItem (TransactionID, ProductCode, Quantity)
values  ( 1, 'P20000',1)
 
insert into TransactionItem (TransactionID, ProductCode, Quantity)
values  ( 2, 'P10000',3)
insert into TransactionItem (TransactionID, ProductCode, Quantity)
values  ( 2, 'P20000',1)
insert into TransactionItem (TransactionID, ProductCode, Quantity)
values  ( 2, 'P30000',1)
 
insert into TransactionItem (TransactionID, ProductCode, Quantity)
values  ( 3, 'P10000',2)