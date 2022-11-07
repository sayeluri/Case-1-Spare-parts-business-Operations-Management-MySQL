Create Database LearnMySQL;
Use LearnMySQL;
Select * from Delivery
Select * from Vendor
Update Delivery
Set Vendor_code = '1245', Qty_delivered = '15'
Where Transaction_ID = 12129;
/* Desired output must contain the following:
	1. Delivery_Date
    2. Number of distinct vendors who made delivery each day
    3. Vendor_code of vendor who made maximum number of deliveries
    4. Vendor name of vendor who made maximum number of deliveries */
    
/******************************************** Method 1 *************************************************/

With MaxDelEachDay as (
	Select Delivery_date,
		   Vendor_code,
           Rank() Over (Partition by Delivery_date order by DelCount Desc, Vendor_code) as RN
	From
	(Select Delivery_date, Vendor_code, Count(1) as DelCount
    From Delivery 
    Group By Delivery_date, Vendor_code) subQuery 
    ), DayWiseRank as (Select Delivery_date,
							  Vendor_code,
                              Dense_Rank() Over (Order by Delivery_date) as dayRN
							  From Delivery),
							  VendorCntTillDate as (Select Outtr.Delivery_date,
														   Outtr.Vendor_code,
                                                           Case When Outtr.Delivery_date = '2022-10-01' Then 1
																Else 1+(Select Count(Distinct d.Delivery_date)
													From Delivery d Where d.Vendor_code = Outtr.Vendor_code and
																		  d.Delivery_date < Outtr.Delivery_date)
																			End as PrevCnt,
                                                                            Outtr.dayRN
													From DayWiseRank Outtr), 
							 VendorDelEachDay as (Select Delivery_date,
												  Count(Distinct Vendor_code) VendorCnt
												From VendorCntTillDate
													Where PrevCnt = dayRN
												Group by Delivery_date)
                                                Select VendorDelEachDay.Delivery_date,
													   VendorDelEachDay.VendorCnt,
                                                       MaxDelEachDay.Vendor_code,
                                                       Vendor.Vendor_name
												From VendorDelEachDay
                                                Inner Join MaxDelEachDay
													on VendorDelEachDay.Delivery_date = MaxDelEachDay.Delivery_date
												Inner Join Vendor
													on Vendor.Vendor_code = MaxDelEachDay.Vendor_code
												Where MaxDelEachDay.RN = 1
											
/************************************************* Method 2 ******************************************/

Select Delivery_date,
	(Select Count(Distinct Vendor_code) as no_of_unique_vendor_id From Delivery D2
		Where D2.Delivery_date = D1.Delivery_date
        And (Select Count(Distinct D3.Delivery_date)
			From Delivery D3
            Where D3.Vendor_code = D2.Vendor_code
            And D3.Delivery_date < D1.Delivery_date
            ) = Datediff(D1.Delivery_date, '2022-10-01')
	) As no_of_unique_vendors,
		(Select Vendor_code from Delivery D2
			Where D2.Delivery_date = D1.Delivery_date
            Group by Vendor_code
            Order by Count(Transaction_ID) Desc, Vendor_code Asc Limit 1
		) As Max_Del_Vendor_code,
			(Select Vendor_Name from Vendor
				Where Vendor_code = Max_Del_Vendor_code
			) as Vendor_Name
	From (Select Distinct Delivery_date from Delivery) D1
    Group by Delivery_date;

/**************************************************** Method 3 *******************************/

Select d1.Delivery_date, d1.Vendor_cnt, d2.Vendor_code, v.Vendor_name
From
(Select Delivery_date, count(Distinct Vendor_code) as Vendor_cnt
From
(Select d.*, dense_rank() over(order by Delivery_date) as date_rank,
dense_rank() over(partition by Vendor_code order by Delivery_date) as Vendor_rank
From Delivery d) a
Where date_rank = Vendor_rank
Group by Delivery_date) d1
Join
(Select Delivery_date, Vendor_code,
	Rank() Over(partition by Delivery_date order by Delivery_cnt Desc, Vendor_code) as Max_rank
From (Select Delivery_date, Vendor_code, count(*) as Delivery_cnt
	From Delivery
    Group by Delivery_date, Vendor_code) b) d2
On d1.Delivery_date = d2.Delivery_date and d2.Max_rank = 1
Join Vendor v on v.Vendor_code = d2.Vendor_code
Order by 1;

													
											
													
                                                    
	