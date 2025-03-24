-- sale detail
-- Invoicelineid, InvoiceId, TrackId, TrackName, Unitprice, Quantiy, TotalSale, InvoiceDate, CustomerId, CustomerName
drop table Sale_detail;
create table Sale_detail(
select i.InvoiceId,
i.CustomerId,
concat(c.FirstName," ",c.LastName) as "Customer_Name",
i.InvoiceDate,
UnitPrice,
sum(Quantity) as"Quanity",
count(il.TrackId) as "Total_Track",
sum(UnitPrice * Quantity) as"Total_Sale",
sum(sum(UnitPrice * Quantity)) over( partition by i.CustomerId) as "Total_Sale_By_Customer" 

from 
invoiceline il
join invoice i
on il.InvoiceId = i.InvoiceId
join customer c
on i.CustomerId = c.CustomerId

group by
i.InvoiceId,
i.CustomerId,
concat(c.FirstName," ",c.LastName),
i.InvoiceDate,
UnitPrice)
;

select *
from Sale_detail
;

-- Month over Month
With monthover as(
select
year(InvoiceDate) as "Year",
month(InvoiceDate) as "Month",
sum(Total_Sale) as "Total_Sale",
sum(Total_Track) as "Total_Track_Sold",
count(distinct CustomerId) as "Total_Customers"
from Sale_detail
group by year,month)
select 
Year,
Month,
Total_Sale as "Current_total_sale",
lag(Total_Sale) over (order by Year,Month) as "Previous_total_sale",
Total_Track_Sold as "Current_total_track_sold",
lag(Total_Track_Sold) over (order by Year,Month) as "Previous_total_track_sold",
Total_Customers as "Current_total_customers",
lag(Total_Customers) over (order by Year,Month) as "Previous_total_customers"
from monthover
;

