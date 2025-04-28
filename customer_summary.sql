
/* customerId, Employename, Company, Address, City, State, Country, PostalCode, Phone, Fax, Email, supportRepId
*/

-- customer status >> active or churn, no active buying within 6 months up to current date
-- totaltrack, totalinvoice, totalsale, totalquantity, firstpurchase,lastpurchase

-- checking validability of employeeId in customer table and employee table
select * from customer
where SupportRepId not in ( select EmployeeId
from employee);

select * from employee;

-- checking the customerId from both customer tabe and invoice table
select * 
from customer
where CustomerId not in ( select CustomerId
from invoice);

-- checking the purchase date from customers
select max(InvoiceDate)
from invoice;

delimiter  |
create event customers_summary
on schedule every 1 day
do 
begin
drop table if exists customers_summary;
create table customers_summary
select 
c.CustomerId,
concat(c.FirstName," ",c.LastName) as "FullName",
Company,
c.Address,
c.City,
c.State,
c.Country,
c.PostalCode,
c.Phone,
c.Fax,
c.Email,
case when max(i.InvoiceDate) > subdate(curdate(),interval 6 month) then "Active" else "Churn" end as "Customer's status",
SupportRepId as "EmployeeId",
concat(e.FirstName," ",e.LastName) as "EmployeeName",
count(distinct i.InvoiceId) as "Total_Invoice",
count(distinct il.TrackId) as "Total_Tracks",
sum(il.UnitPrice * il.Quantity) as "Total_Sale",
min(InvoiceDate) as "FirstpurchaseDate",
max(InvoiceDate) as "LastpurchaseDate"
from customer c
join employee e
on c.SupportRepId = e.EmployeeId
join invoice i
on c.CustomerId = i.CustomerId
join invoiceline il
on i.InvoiceId = il.InvoiceId
where i.InvoiceDate <= curdate()

group by
c.CustomerId,
concat(c.FirstName," ",c.LastName),
Company,
c.Address,
c.City,
c.State,
c.Country,
c.PostalCode,
c.Phone,
c.Fax,
c.Email,
case when i.InvoiceDate > subdate(curdate(),interval 6 month) then "Active" else "Churn" end,
SupportRepId,
concat(e.FirstName," ",e.LastName);
 end |
delimiter ;


-- checking discrepencies between Total from invoice and Total_Sale from customer_summary
with customer_summary as(
select 
c.CustomerId,
concat(c.FirstName," ",c.LastName) as "FullName",
Company,
c.Address,
c.City,
c.State,
c.Country,
c.PostalCode,
c.Phone,
c.Fax,
c.Email,
case when max(i.InvoiceDate) > subdate(curdate(),interval 6 month) then "Active" else "Churn" end as "Customer's status",
SupportRepId as "EmployeeId",
concat(e.FirstName," ",e.LastName) as "EmployeeName",
count(distinct i.InvoiceId) as "Total_Invoice",
count(distinct il.TrackId) as "Total_Tracks",
sum(il.UnitPrice * il.Quantity) as "Total_Sale",
min(InvoiceDate) as "FirstpurchaseDate",
max(InvoiceDate) as "LastpurchaseDate"
from customer c
join employee e
on c.SupportRepId = e.EmployeeId
join invoice i
on c.CustomerId = i.CustomerId
join invoiceline il
on i.InvoiceId = il.InvoiceId
where i.InvoiceDate <= curdate()

group by
c.CustomerId,
concat(c.FirstName," ",c.LastName),
Company,
c.Address,
c.City,
c.State,
c.Country,
c.PostalCode,
c.Phone,
c.Fax,
c.Email,
case when i.InvoiceDate > subdate(curdate(),interval 6 month) then "Active" else "Churn" end,
SupportRepId,
concat(e.FirstName," ",e.LastName)
)
select cs.CustomerId, sum(Total), Total_Sale
from invoice i
join customer_summary cs
on i.CustomerId = cs.CustomerId
where i.InvoiceDate <= curdate()
group by cs.CustomerId, Total_Sale
order by cs.CustomerId 
;



