create database airport;
use airport;
alter table airport2 change ï»¿origin_airport origin_airport varchar(50);
alter table airport2 change distance_km distance int;
select * from airport2;

######## Q.1.find Total No of passengers travel between which 2 airports? ##########
select
Origin_airport,
destination_airport,
sum(passengers) as Total_passenegers
from airport2 
group by 
Origin_airport,
destination_airport
order by Total_passenegers desc;

######## Q.2.Identify Highest & lowest Seat Occupancy ##########

select 
Origin_airport,
destination_airport,
avg((passengers )/(seats))*100 as seats_available 
from airport2
group by 
Origin_airport,
destination_airport 
order by 
seats_available desc;


######## Q.3.Find out most frequent Travel route   ##########
select
Origin_airport,
destination_airport,
origin_city,
destination_city,
sum(passengers) as Total_passenegers
from airport2 
group by 
Origin_airport,
destination_airport,
origin_city,
destination_city
order by Total_passenegers desc
limit 5;

######## Q.4.Find out activity level at various origin cities  ##########
select 
origin_city,
count(flights) as Total_flights,
sum(passengers) as Total_passengers
from 
airport2
group by 
origin_city
order by 
Total_passengers desc;

######## Q.5.Look into travel patterns ##########
select
origin_city,
origin_airport,
sum(distance) as Total_distance
from airport2
group by origin_city,origin_airport
order by Total_distance desc;

######## Q.6.Find out seasonal trends (in which month most of passengers travelled ##########
select 
Year(fly_date) as Year,
Month(fly_date) as Month,
count(flights) as Total_flights,
sum(passengers) as Total_passengers,
avg(distance) as Avg_distance
from  airport2
group by 
Year,Month
order by 
Year desc,Month desc;

######## Q.7.Find the underutilized route (least used routes)  ##########
select
origin_airport, 
destination_airport,
sum(passengers) as total_passengers,
sum(seats) as total_seats,
sum(passengers)*1.0/sum(seats) as passengers_seats
from airport2
group by 
origin_airport,
destination_airport 
having 
passengers_seats < 10000
order by 
passengers_seats; 


######## Q.8.Find out the airport where highest frquency of Flights ##########
select origin_airport,origin_city,
sum(flights) as total_flights
from airport2
group by origin_airport,origin_city
order by total_flights desc;


######## Q.9.Find a city where most of passengers travels  ##########
select 
origin_city,
sum(flights) as total_flights,
sum(passengers) as total_passengers
from airport2
where
destination_city = "Mumbai" and
origin_city<>"Mumbai"
group by 
origin_city
order by 
total_flights desc,
total_passengers desc;


######## Q.10.Find Maximum extensive travel connection (Flights which travel maximum distance)  ##########
select 
origin_airport,
destination_airport,
Max(distance) as Long_distance
from
airport2
group by 
origin_airport,
destination_airport
order by 
Long_distance desc;
        

######## Q.11. Calculate  the origincity ,destination city ,total passenegers ,total flights, total seats , total seats , find out the dates of all flights Between Two cities   ##########

select 
		origin_city,
        destination_city,
        fly_date as all_dates,
        sum(passengers) as total_passengers,
        sum(flights) as total_flights,
        sum(seats) as total_seats,
        sum(distance) as total_distance,
        count(fly_date) as fly_days
        
from
airport2
where 
origin_city in ('Mumbai','Goa') 
and destination_city in (
'Delhi',
'Goa',
'Chennai',
'Hyderabad',
'Mumbai'
)
group by 
origin_city,
destination_city,
fly_date;


######## Q.12.Find out most & least Count of flight across multiple years (find count of flights based on month ) ##########
 with Monthly_flights as  (select 
Month(fly_date) as Month,
sum(flights) as Total_flights
from airport2
group by
Month(fly_date) )

select 
	Month,
    Total_flights,
    CASE
        when Total_flights = (select MAX(Total_flights) from Monthly_flights ) then 'Most Busy'
        when Total_flights = (select Min(Total_flights) from Monthly_flights ) then 'least Busy'
	Else NULL
    END as status
    from Monthly_flights
    Where 
		Total_flights = (select MAX(Total_flights) from Monthly_flights ) or
        Total_flights = (select Min(Total_flights) from Monthly_flights );
        
        
######## Q.13.Calculate year over year percentage growth in passengers ##########
with passenger_summary as
(select
		origin_airport,
        destination_airport,
        sum(passengers) as total_passengers,
        Year(fly_date) as Year 
from airport2
group by
		origin_airport,
        destination_airport,
        Year(fly_date)),

passenger_growth as      
(select 
		origin_airport,
        destination_airport,
        year,
        total_passengers,
            lag(total_passengers) over (partition by origin_airport ,destination_airport order by year) as previous_year_passenger
		from 
			passenger_summary)
            
select 
		origin_airport,
        destination_airport,
        year,
        total_passengers,
        case 
        when previous_year_passenger is not null then 
        ((total_passengers-previous_year_passenger)*100/nullif(previous_year_passenger,0))
        End as Growth_percentage
from 
passenger_growth
order by
origin_airport,
destination_airport,
year;

######## Q.14.Finding Trending route  ##########
With growth_summary as(
select
origin_airport,
destination_airport,
Year(fly_date) as year,
count(flights) as total_flights
from
	airport2
group by
origin_airport,
destination_airport,
year),
flight_growth as
(select 
origin_airport,
destination_airport,
year,
total_flights,
lag(total_flights) over (partition by origin_airport,destination_airport order by year) as previous_year_flights
from
growth_summary),
growth_rates as(
select
origin_airport,
destination_airport,
year,
total_flights,
case
when
(previous_year_flights is not null and previous_year_flights)>0 then
((total_flights-previous_year_flights)*100.0/previous_year_flights)
else
	null
    End as growth_rate,
    case
when
(previous_year_flights is not null and previous_year_flights)>previous_year_flights then
1
else 0
    End as growth_indicator
from 
flight_growth)

select 
origin_airport,
destination_airport,
Max(growth_rate) as maximum_growth_rate,
Min(growth_rate) as minimum_growth_rate
from growth_rates
where 
 growth_indicator=0
 group by
 origin_airport,
destination_airport
having
Min(growth_rate)=0
order by
 origin_airport,
destination_airport;



############ Q.15.Find out passneger to seat ratio Of Top 3 Airport ########
with utilization_ratio as(select 
origin_airport,
sum(passengers) as total_passengers,
sum(seats) as total_seats,
count(flights) as total_flights,
sum(passengers)*1.0/sum(seats) as passenger_seat_ratio
from airport2
group by origin_airport),

wighted_utilization as
(select
origin_airport,
total_seats,
total_passengers,
total_flights,
passenger_seat_ratio,
(passenger_seat_ratio * total_flights)/ sum(total_flights)
over () as wighted_utilization
from utilization_ratio)

select
origin_airport,
total_seats,
total_passengers,
total_flights,
wighted_utilization
from wighted_utilization
order by wighted_utilization desc
limit 3;


############ Q.16.Find out the seasonal travel pattern  ########
with monthly_passengers_count as (select
origin_city,
Year(fly_date) as year,
month(fly_date) as month,
sum(passengers) as total_passengers
from airport2
group by
origin_city,
year,
month),

max_passengers_per_city as
(select
origin_city,
max(total_passengers) as peak_passengers
from monthly_passengers_count
group by
origin_city)

select 
mpc.origin_city,
mpc.year,
mpc.month,
mpc.total_passengers
from monthly_passengers_count mpc join
max_passengers_per_city mp on
mpc.origin_city = mp.origin_city and
mpc.total_passengers = mp.peak_passengers
order by
mpc.origin_city,
mpc.year,
mpc.month;



############ Q.17.Find the routes which demand is reduced ########
WITH Yearly_passenger_count AS (
    SELECT
        origin_airport,
        destination_airport,
        YEAR(fly_date) AS year,
        SUM(passengers) AS total_passenger
    FROM airport2
    GROUP BY
        origin_airport,
        destination_airport,
        YEAR(fly_date)
),

yearly_decline AS (
    SELECT 
        y1.origin_airport,
        y1.destination_airport,
        y1.year AS year1,
        y1.total_passenger AS passengers_year1,
        y2.year AS year2,
        y2.total_passenger AS passengers_year2,
        
        (
            (y2.total_passenger - y1.total_passenger)
            / NULLIF(y1.total_passenger, 0)
        ) * 100 AS percentage_change

    FROM Yearly_passenger_count y1

    JOIN Yearly_passenger_count y2 
        ON y1.origin_airport = y2.origin_airport
        AND y1.destination_airport = y2.destination_airport
        AND y2.year = y1.year + 1
)

SELECT
    origin_airport,
    destination_airport,
    year1,
    passengers_year1,
    year2,
    passengers_year2,
    percentage_change

FROM yearly_decline

WHERE percentage_change < 0

ORDER BY percentage_change

LIMIT 5;

############ Q.18.Find the underperforming routes  ########
WITH flights_stats AS (
    SELECT  
        origin_airport,
        destination_airport,
        COUNT(flights) AS total_flights,
        SUM(passengers) AS total_passengers,
        SUM(seats) AS total_seats,
        SUM(passengers) / NULLIF(SUM(seats), 0) AS avg_seat_utilization
    FROM airport2
    GROUP BY origin_airport, destination_airport
)
SELECT
    origin_airport,
    destination_airport,
    total_flights,
    total_passengers,
    total_seats,
    ROUND(avg_seat_utilization * 100, 2) AS avg_seat_utilization_percentage
FROM flights_stats
WHERE total_flights >= 10
ORDER BY avg_seat_utilization_percentage;

############ Q.19.Longest avg distance route  ########
with distance_stat as (select 
origin_airport,
destination_airport,
avg(distance) as avg_fight_distance
from airport2
group by 
origin_airport,
destination_airport )
select
origin_airport,
destination_airport,
round(avg_fight_distance ,2) as  avg_fight_distance
from distance_stat
order by
avg_fight_distance desc;














