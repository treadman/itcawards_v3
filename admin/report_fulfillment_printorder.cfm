<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<!--- ************************************ --->
<!--- get report info                      --->
<!--- ************************************ --->

<cfset multi_order_ID = order>
<cfset FF_prodphyslist = "">
<cfset FF_prodORDlist = "">
<cfset multi_prod_orders = "">

<!--- get a distinct list of all the ordered products that are not shipped yet ordered by product value --->
<cfquery name="SelectDistinctProducts" datasource="#application.DS#">
	SELECT DISTINCT product_ID
	FROM #application.database#.inventory
	WHERE is_valid = 1 
		AND quantity <> 0 
		AND snap_is_dropshipped = 0 
		AND order_ID <> 0 
		AND ship_date IS NULL
		AND po_ID = 0
		AND po_rec_date IS NULL
	ORDER BY snap_productvalue 
</cfquery>

<!--- loop through the list and calc the physical inventory --->
<cfloop query="SelectDistinctProducts">
	<cfset thisDistinctProduct = SelectDistinctProducts.product_ID>
	<cfset PhysicalInvCalc(thisDistinctProduct)>
	
	<!--- if the physical inventory is gt 0, add to productID_physicalInventory list --->
	<cfif PIC_total_physical gt 0>
		<cfset FF_prodphyslist = ListAppend(FF_prodphyslist,thisDistinctProduct & "_" & PIC_total_physical)>
	</cfif>
</cfloop>
<cfif FF_prodphyslist EQ "">
	<cfset alert_error = "There are no products waiting to be shipped from ITC">
</cfif>
<!--- loop through the product list and select #physical_total# orders and create list of productID_orderID pairs --->
<cfif FF_prodphyslist NEQ "">
	<cfloop list="#FF_prodphyslist#" index="giraffe">
		<cfset giraffe_product_ID = ListGetAt(giraffe,1,"_")>
		<cfset giraffe_physicaltotal = ListGetAt(giraffe,2,"_")>

		<cfquery name="SelectOrderID" datasource="#application.DS#" maxrows="#giraffe_physicaltotal#">
			SELECT inv.order_ID, ord.program_ID, inv.quantity
			FROM #application.database#.inventory inv JOIN #application.database#.order_info ord ON inv.order_ID = ord.ID
			WHERE inv.is_valid = 1 
				AND inv.quantity <> 0 
				AND inv.snap_is_dropshipped = 0 
				AND inv.order_ID <> 0 
				AND inv.ship_date IS NULL
				AND inv.po_ID = 0
				AND inv.po_rec_date IS NULL
				AND inv.product_ID = #giraffe_product_ID#
			ORDER BY inv.created_datetime
		</cfquery>
		
		<cfset giraffe_qty_counter = 0>
		<cfloop query="SelectOrderID">
		<cfset giraffe_qty_counter = giraffe_qty_counter + SelectOrderID.quantity>
			<cfif giraffe_qty_counter LTE giraffe_physicaltotal>
				<cfset FF_prodORDlist = FF_prodORDlist & "," & giraffe_product_ID & "_" & SelectOrderID.program_ID & "_ord" & SelectOrderID.order_ID & "_" & SelectOrderID.quantity>
			<cfelse>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfloop>
	<cfif FF_prodORDlist NEQ "">
		<cfset FF_prodORDlist = RemoveChars(FF_prodORDlist,1,1)>
		<cfset FF_prodORDlist = ListSort(FF_prodORDlist,'text')>
	</cfif>
</cfif>
		
<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfinclude template="includes/header_lite.cfm">
		
<!--- get order info --->
<cfquery name="FindMultiOrderInfo" datasource="#application.DS#">
	SELECT ID AS order_ID, program_ID AS this_program_ID, order_number, snap_order_total, points_used, credit_card_charge,
		snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2,
		snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email, snap_bill_company, snap_bill_fname,
		snap_bill_lname, snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip,
		order_note, modified_concat, shipping_desc, shipping_charge, snap_signature_charge
	FROM #application.database#.order_info
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#multi_order_ID#" maxlength="10">
		AND is_valid = 1
</cfquery>
<cfset order_ID = FindMultiOrderInfo.order_ID>
<cfset this_program_ID = FindMultiOrderInfo.this_program_ID>
<cfset order_number = HTMLEditFormat(FindMultiOrderInfo.order_number)>
<cfset snap_order_total = HTMLEditFormat(FindMultiOrderInfo.snap_order_total)>
<cfset points_used = HTMLEditFormat(FindMultiOrderInfo.points_used)>
<cfset credit_card_charge = HTMLEditFormat(FindMultiOrderInfo.credit_card_charge)>
<cfset snap_fname = HTMLEditFormat(FindMultiOrderInfo.snap_fname)>
<cfset snap_lname = HTMLEditFormat(FindMultiOrderInfo.snap_lname)>
<cfset snap_ship_company = HTMLEditFormat(FindMultiOrderInfo.snap_ship_company)>
<cfset snap_ship_fname = HTMLEditFormat(FindMultiOrderInfo.snap_ship_fname)>
<cfset snap_ship_lname = HTMLEditFormat(FindMultiOrderInfo.snap_ship_lname)>
<cfset snap_ship_address1 = HTMLEditFormat(FindMultiOrderInfo.snap_ship_address1)>
<cfset snap_ship_address2 = HTMLEditFormat(FindMultiOrderInfo.snap_ship_address2)>
<cfset snap_ship_city = HTMLEditFormat(FindMultiOrderInfo.snap_ship_city)>
<cfset snap_ship_state = HTMLEditFormat(FindMultiOrderInfo.snap_ship_state)>
<cfset snap_ship_zip = HTMLEditFormat(FindMultiOrderInfo.snap_ship_zip)>
<cfset snap_phone = HTMLEditFormat(FindMultiOrderInfo.snap_phone)>
<cfset snap_email = HTMLEditFormat(FindMultiOrderInfo.snap_email)>
<cfset snap_bill_company = HTMLEditFormat(FindMultiOrderInfo.snap_bill_company)>
<cfset snap_bill_fname = HTMLEditFormat(FindMultiOrderInfo.snap_bill_fname)>
<cfset snap_bill_lname = HTMLEditFormat(FindMultiOrderInfo.snap_bill_lname)>
<cfset snap_bill_address1 = HTMLEditFormat(FindMultiOrderInfo.snap_bill_address1)>
<cfset snap_bill_address2 = HTMLEditFormat(FindMultiOrderInfo.snap_bill_address2)>
<cfset snap_bill_city = HTMLEditFormat(FindMultiOrderInfo.snap_bill_city)>
<cfset snap_bill_state = HTMLEditFormat(FindMultiOrderInfo.snap_bill_state)>
<cfset snap_bill_zip = HTMLEditFormat(FindMultiOrderInfo.snap_bill_zip)>
<cfset order_note = HTMLEditFormat(FindMultiOrderInfo.order_note)>
<cfset shipping_charge = FindMultiOrderInfo.shipping_charge>
<cfset snap_signature_charge = FindMultiOrderInfo.snap_signature_charge>
<cfset shipping_desc = FindMultiOrderInfo.shipping_desc>
<table cellpadding="5" cellspacing="0" border="0" width="90%" align="center">		

<tr>
<td colspan="2"><span class="pagetitle">I T C&nbsp;&nbsp;&nbsp;A W A R D S&nbsp;&nbsp;&nbsp;-&nbsp;&nbsp;&nbsp;M U L T I&nbsp;&nbsp;&nbsp;P R O D U C T&nbsp;&nbsp;&nbsp;O R D E R S&nbsp;&nbsp;&nbsp;-&nbsp;&nbsp;&nbsp;
<cfoutput>#FLGen_DateTimeToDisplay()#</cfoutput><br></span>
</td>
		</tr>

<cfoutput>
<tr class="printext">
<td valign="top" width="50%"><b><span class="highlight">#GetProgramName(FindMultiOrderInfo.this_program_ID)#</span> Order #order_number#</b><br>
	User: <cfif snap_fname NEQ "">#snap_fname#</cfif> <cfif snap_lname NEQ "">#snap_lname#<br></cfif>
	<cfif snap_phone NEQ "">Phone: #snap_phone#<br></cfif>
	<cfif snap_email NEQ "">Email: #snap_email#<br></cfif>
</td>
<td valign="top" width="50%">
		SHIP TO:<br>
		<cfif snap_ship_company NEQ "">#snap_ship_company#<br></cfif>
		<cfif snap_ship_fname NEQ "">#snap_ship_fname#</cfif> <cfif snap_ship_lname NEQ "">#snap_ship_lname#</cfif><br>
		<cfif snap_ship_address1 NEQ "">#snap_ship_address1#<br></cfif>
		<cfif snap_ship_address2 NEQ "">#snap_ship_address2#<br></cfif>
		<cfif snap_ship_city NEQ "">#snap_ship_city#</cfif>, <cfif snap_ship_state NEQ "">#snap_ship_state#</cfif> <cfif snap_ship_zip NEQ "">#snap_ship_zip#</cfif><br>
	<cfif order_note NEQ "">#Replace(HTMLEditFormat(order_note),chr(10),"<br>","ALL")#<cfelse><span class="sub">(no order note)</span></cfif><br>
	<cfif shipping_desc NEQ "">Ship via #shipping_desc#: #shipping_charge#</cfif>
	<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#</cfif>
</td>
</tr>

<!--- find order items --->
<cfquery name="FindOrderItems" datasource="#application.DS#">
	SELECT ID AS inventory_ID, snap_sku, snap_meta_name, snap_description, snap_productvalue, quantity, snap_options, product_ID
	FROM #application.database#.inventory
	WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#multi_order_ID#" maxlength="10">
		AND is_valid = 1
</cfquery>

<tr class="printext">
<td colspan="2">
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	<cfloop query="FindOrderItems">
		<cfset checkforthisprod = "#product_ID#_#this_program_ID#_ord#multi_order_ID#_#quantity#">
		<cfif ListContains(FF_prodORDlist,checkforthisprod)>
		
			<!--- find vendor sku(s) --->
			<cfquery name="FindVendorSku" datasource="#application.DS#">
				SELECT vl.vendor_sku, v.vendor 
				FROM #application.database#.vendor_lookup vl JOIN #application.database#.vendor v ON vl.vendor_ID = v.ID 
				WHERE vl.product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10">
			</cfquery>

	<tr>
	<td><span class="highlight">CAT: #snap_productvalue#</span></td>
	<td><cfif quantity GT 1><span class="highlight">QTY: #quantity#</span><cfelse>QTY: #quantity#</cfif></td>
	<td>
	<span class="highlight">#snap_meta_name#</span><cfif snap_options NEQ ""><br>#snap_options#</cfif><br>
	SKU: #snap_sku#
		<cfif FindVendorSku.RecordCount GT 0>
			<cfloop query="FindVendorSku">
				<br />Vendor SKU: (#vendor#) #vendor_sku#
			</cfloop>
		</cfif>

	</td>
	</tr>
	
	<tr>
	<td colspan="4"><hr width="90%" align="left"></td>
	</tr>

		</cfif>
	</cfloop>
	</table>
</td>
</tr>

<tr>
<td colspan="2">&nbsp;</td>
</tr>

</cfoutput>
		

</table>
	
</table>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->