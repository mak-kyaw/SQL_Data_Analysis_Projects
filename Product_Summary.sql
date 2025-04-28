/*-- checking the playlist per track
select max(count_pl), TrackId
from
(select TrackId, count(distinct PlaylistId) As "count_pl"
from playlisttrack
Group by TrackId
Having count(distinct PlaylistId) > 1) As tc
Group by TrackId
; */

/*-- checking if missing values presence 
With missing as(
select 
case when length(AlbumId) = 0 or AlbumId is null then 1 else 0 end as "AlbumId_Null",
case when length(MediaTypeId) = 0 or MediaTypeId is null then 1 else 0 end as "MediaTypeId_Null",
case when length(GenreId) = 0 or GenreId is null then 1 else 0 end as "GenreId_Null"

from track)
select 
   Sum(AlbumId_Null),
   Sum(MediaTypeId_Null),
   Sum(GenreId_Null)
from missing ; */



drop event ps_etl;
SET GLOBAL event_scheduler = ON;
delimiter |
create event ps_etl
on schedule every 1 day
do
begin
drop table if exists product_summary;
create table product_summary(
select t.TrackId,
t.Name as "Track",
at.Name as "Artist",
a.Title as "Album",
mt.Name as "MediaType",
g.Name as "Genre",
(select group_concat(distinct Name separator ',') 
from playlist p
join playlisttrack pt
on p.PlaylistId = pt.PlaylistId
where pt.TrackId = t.TrackId
) as "Playlist",
Milliseconds/1000 as "second",
count(ivl.Quantity) as total_quantity,
t.UnitPrice,
ifnull(sum(t.UnitPrice * ivl.Quantity),0) as total_sale,
count(distinct InvoiceLineId) as total_invoice,
count(distinct CustomerId) as total_customer
from track t
join album a
on t.AlbumId = a.AlbumId
join mediatype mt
on t.MediaTypeId = mt.MediaTypeId
join genre g
on t.GenreId = g.GenreId
join artist at
on a.ArtistId = at.ArtistId
/*join playlisttrack plt
on t.TrackId = plt.TrackId
join playlist pl
on plt.PlaylistId = pl.PlaylistId*/
left join invoiceline ivl
on t.TrackId = ivl.TrackId
left join invoice iv
on ivl.InvoiceId = iv.InvoiceId
group by t.TrackId,
t.Name,
at.Name,
a.Title,
mt.Name,
g.Name,
Milliseconds/1000,
t.UnitPrice) ;
end |

delimiter ;


create table logs
( id int auto_increment primary key,
Checktype text,
result int,
created_at datetime default current_timestamp

);
select * from logs;
drop event logs_etl;
delimiter |
create event logs_etl
on schedule
every 1 day
do
begin

insert into logs(`Checktype`, `result`)
(select "Artist count", count(*)
from
(select count(*)
from album
group by AlbumId
having count(distinct ArtistId) > 1) as at_count_logs) ;



/*-- check missing values in playlist track
select t.TrackId
from track t
left join playlisttrack plt
on t.TrackId = plt.TrackId
where plt.TrackId is null
; */

/*-- check missing playlist in playlisttrack

select *
from playlisttrack plt
left join playlist pl
on plt.PlaylistId = pl.PlaylistId
where pl.PlaylistId is null
; */

-- checking discrepencies on sale between invoice and invoice line
insert into logs(`Checktype`,`result`)
(select "discrepencies on sale between invoice and invoice line",count(*)
from(
select 
iv.InvoiceId,
Total,
sum(UnitPrice * Quantity) as total_ivl
from
invoice iv
join 
invoiceline ivl
on iv.InvoiceId = ivl.InvoiceId
group by iv.InvoiceId,
Total
Having Total != total_ivl) check_discrepencies)
;

/*-- checking total sale with invoice data
select InvoiceId, Total, sum(total_sale) as test_sum
from (select t.TrackId,
t.Name as "Track",
at.Name as "Artist",
a.Title as "Album",
mt.Name as "MediaType",
g.Name as "Genre",
(select group_concat(distinct Name separator ',') 
from playlist p
join playlisttrack pt
on p.PlaylistId = pt.PlaylistId
where pt.TrackId = t.TrackId
) as "Playlist",
Milliseconds/1000 as "second",
count(ivl.Quantity) as total_quantity,
t.UnitPrice,
iv.InvoiceId,
iv.Total,
ifnull(sum(t.UnitPrice * ivl.Quantity),0) as total_sale,
count(distinct InvoiceLineId) as total_invoice,
count(distinct CustomerId) as total_customer
from track t
join album a
on t.AlbumId = a.AlbumId
join mediatype mt
on t.MediaTypeId = mt.MediaTypeId
join genre g
on t.GenreId = g.GenreId
join artist at
on a.ArtistId = at.ArtistId
/*join playlisttrack plt
on t.TrackId = plt.TrackId
join playlist pl
on plt.PlaylistId = pl.PlaylistId*/
/*left join invoiceline ivl
on t.TrackId = ivl.TrackId
left join invoice iv
on ivl.InvoiceId = iv.InvoiceId
group by t.TrackId,
t.Name,
at.Name,
a.Title,
mt.Name,
g.Name,
Milliseconds/1000,
t.UnitPrice,
iv.InvoiceId,
iv.Total
order by TrackId) as subquery
group by 
InvoiceId, Total
having Total != test_sum
; */

insert into logs(`Checktype`,`result`)
select "Album missing",AlbumId_Null
from
( select 
sum(case when length(AlbumId) = 0 or AlbumId is null then 1 else 0 end) as "AlbumId_Null"
from track) check_Abl_null;

insert into logs(`Checktype`,`result`)
select "MediaType missing", MediaTypeId_Null
from
( select 
sum(case when length(MediaTypeId) = 0 or MediaTypeId is null then 1 else 0 end) as "MediaTypeId_Null"
from track) check_medtyp_null;

insert into logs(`Checktype`,`result`)
select "Genre Missing", GenreId_Null
from
(select
sum(case when length(GenreId) = 0 or GenreId is null then 1 else 0 end) as "GenreId_Null"
from track) check_gen_null;
end |
delimiter ;

select * from logs ;





