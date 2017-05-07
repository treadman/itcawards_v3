<cfset page_title = "Order Shipment Email Example">
<cfinclude template="includes/header_lite.cfm">

<b>The email will start with the text that you enter into the box (the text below is a sample). The items below the asterisks are the auto text the system generates:</b>
<br><br>
 

Order Shipment<br><br>

The items listed below were shipped via UPS.  You may track your package with the tracking number listed below at www.ups.com
<br><br>
If there are other items in your order, they will be shipped separately.
<br><br>
*********************************************
<br>
tracking number: 3763658356732<br>
<br>
QTY 1 Pearl Necklace<br>
QTY 3 Princes Puppy T-shirt
<br>
*********************************************
<cfinclude template="includes/footer.cfm">
