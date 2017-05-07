<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<cfparam name="where_string" default="">
<cfparam name="ID" default="">
<cfparam name="ordit" default="">

<!--- param search criteria FOR ORDER page --->
<cfparam name="back" default="">
<cfparam name="OnPage" default="1">
<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfif IsDefined('shipID') AND shipID IS NOT "">
	<cfset order_ID = shipID>
<cfelse>
	<cfset order_ID = order_ID>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfset any_shipped = "false">
	<cfset mod_note = "">
	<!--- find the submitted shipped items --->
	<cfif IsDefined('form.FieldNames') AND Trim(form.FieldNames) IS NOT "">
		<!--- loop through the form fields and when I find one that starts with "ship_" --->
		<cfloop List="#form.FieldNames#" Index="FormField">
			<cfif FormField CONTAINS "ship_">
				<cfset shipthis_ID = ListGetAt(FormField,2,"_")>
				<!--- update with (ship_date, tracking) --->
				<cfquery name="MarkItemShipped" datasource="#application.DS#">
					UPDATE #application.database#.inventory 
					SET	ship_date = <cfqueryparam cfsqltype="cf_sql_date" value="#ship_date#">, 
						tracking = <cfqueryparam cfsqltype="cf_sql_varchar" value="#tracking#" maxlength="32">
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#shipthis_ID#" maxlength="10">
				</cfquery>
				<cfset fake_form = "form." & shipthis_ID>				
				<cfset mod_note = mod_note & Chr(13) & Chr(10) & Evaluate(fake_form)>
				<cfset any_shipped = "true">
			</cfif>
		</cfloop>
	</cfif>
	<!--- as long as there was at least one item updated --->
	<cfif any_shipped>
		<!--- check for UNSHIPPED // UNDROPSHIPPED --->
		<cfquery name="ItemsNotShipped" datasource="#application.DS#">
			SELECT ID AS ItemsNotOut
			FROM #application.database#.inventory
			WHERE is_valid = 1 
				AND quantity <> 0 
				AND snap_is_dropshipped = 0  
				AND order_ID =  <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
				AND ship_date IS NULL 
				AND po_ID = 0
				AND po_rec_date IS NULL 
			
			UNION
			
			SELECT ID AS ItemsNotOut
			FROM #application.database#.inventory
			WHERE is_valid = 1 
				AND quantity <> 0 
				AND snap_is_dropshipped = 1  
				AND order_ID =  <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
				AND ship_date IS NULL 
				AND po_ID = 0
				AND po_rec_date IS NULL
			
		</cfquery>
		<!--- insert order mod note --->
		<cfset mod_note = "(*auto* item(s) shipped on #ship_date#, tracking ###tracking#) #mod_note#">
		<cfif ItemsNotShipped.RecordCount EQ 0><cfset mod_note = "(*auto* order completely fulfilled #FLGen_DateTimeToDisplay()#)" & Chr(13) & Chr(10) & "#mod_note#"></cfif>
		<!--- if appro, mark is_all_shipped (I checked for unshipped and undropshipped items above) --->
		<cfquery name="UpdateOrderInfo" datasource="#application.DS#">
			UPDATE #application.database#.order_info 
			SET is_valid = 1 
			<cfif ItemsNotShipped.RecordCount EQ 0>, is_all_shipped = 1 </cfif>
			#FLGen_UpdateModConcatSQL(mod_note)#
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
		</cfquery>
		<!--- This is where I would send the email, if there was one... --->
	</cfif>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "">
<cfinclude template="includes/header.cfm">

<!--- ********************************* --->
<!---  getting the cart display info    --->
<!--- ********************************* --->

<!--- get order info --->
<cfquery name="FindOrderInfo" datasource="#application.DS#">
	SELECT ID AS order_ID, program_ID AS this_program_ID, order_number, snap_order_total, points_used, credit_card_charge, snap_fname, snap_lname, snap_ship_company,
			snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email,
			snap_bill_company, snap_bill_fname, snap_bill_lname, snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip,
			order_note, modified_concat, shipping_charge, snap_signature_charge, shipping_desc
	FROM #application.database#.order_info
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
		AND is_valid = 1
</cfquery>
<cfset order_ID = FindOrderInfo.order_ID>
<cfset this_program_ID = FindOrderInfo.this_program_ID>
<cfset order_number = HTMLEditFormat(FindOrderInfo.order_number)>
<cfset snap_order_total = HTMLEditFormat(FindOrderInfo.snap_order_total)>
<cfset points_used = HTMLEditFormat(FindOrderInfo.points_used)>
<cfset credit_card_charge = HTMLEditFormat(FindOrderInfo.credit_card_charge)>
<cfset snap_fname = HTMLEditFormat(FindOrderInfo.snap_fname)>
<cfset snap_lname = HTMLEditFormat(FindOrderInfo.snap_lname)>
<cfset snap_ship_company = HTMLEditFormat(FindOrderInfo.snap_ship_company)>
<cfset snap_ship_fname = HTMLEditFormat(FindOrderInfo.snap_ship_fname)>
<cfset snap_ship_lname = HTMLEditFormat(FindOrderInfo.snap_ship_lname)>
<cfset snap_ship_address1 = HTMLEditFormat(FindOrderInfo.snap_ship_address1)>
<cfset snap_ship_address2 = HTMLEditFormat(FindOrderInfo.snap_ship_address2)>
<cfset snap_ship_city = HTMLEditFormat(FindOrderInfo.snap_ship_city)>
<cfset snap_ship_state = HTMLEditFormat(FindOrderInfo.snap_ship_state)>
<cfset snap_ship_zip = HTMLEditFormat(FindOrderInfo.snap_ship_zip)>
<cfset snap_phone = HTMLEditFormat(FindOrderInfo.snap_phone)>
<cfset snap_email = HTMLEditFormat(FindOrderInfo.snap_email)>
<cfset snap_bill_company = HTMLEditFormat(FindOrderInfo.snap_bill_company)>
<cfset snap_bill_fname = HTMLEditFormat(FindOrderInfo.snap_bill_fname)>
<cfset snap_bill_lname = HTMLEditFormat(FindOrderInfo.snap_bill_lname)>
<cfset snap_bill_address1 = HTMLEditFormat(FindOrderInfo.snap_bill_address1)>
<cfset snap_bill_address2 = HTMLEditFormat(FindOrderInfo.snap_bill_address2)>
<cfset snap_bill_city = HTMLEditFormat(FindOrderInfo.snap_bill_city)>
<cfset snap_bill_state = HTMLEditFormat(FindOrderInfo.snap_bill_state)>
<cfset snap_bill_zip = HTMLEditFormat(FindOrderInfo.snap_bill_zip)>
<cfset order_note = HTMLEditFormat(FindOrderInfo.order_note)>
<cfset modified_concat = HTMLEditFormat(FindOrderInfo.modified_concat)>
<cfset shipping_charge = FindOrderInfo.shipping_charge>
<cfset snap_signature_charge = FindOrderInfo.snap_signature_charge>
<cfset shipping_desc = FindOrderInfo.shipping_desc>

<!--- get program information --->
<cfquery name="FindProgramInfo" datasource="#application.DS#">
	SELECT company_name, program_name, is_one_item, credit_desc
	FROM #application.database#.program
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#FindOrderInfo.this_program_ID#" maxlength="10">
</cfquery>
<cfset company_name = htmleditformat(FindProgramInfo.company_name)>
<cfset program_name = htmleditformat(FindProgramInfo.program_name)>
<cfset is_one_item = htmleditformat(FindProgramInfo.is_one_item)>
<cfset credit_desc = htmleditformat(FindProgramInfo.credit_desc)>

<!--- find order items --->
<cfquery name="FindOrderItems" datasource="#application.DS#">
	SELECT ID AS inventory_ID, snap_sku, snap_meta_name, snap_description, snap_productvalue, quantity, snap_options, snap_is_dropshipped, order_ID, ship_date, tracking, po_ID, snap_vendor, product_ID, drop_date 
	FROM #application.database#.inventory
	WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
		AND is_valid = 1
</cfquery>

<span class="pagetitle">Save Order Shipment Information</span>
<br /><br />

<cfif ordit EQ "">
	<span class="pageinstructions"><span class="alert">There may be no physical stock for the items below.</span> For details about availability,</span>
	<br />
	<span class="pageinstructions">click "Ship From ITC" on the left.</span>
	<br />
	<br />
<cfelse>
	<span class="pageinstructions">Only the highlighted products have available inventory.</span>
	<br />
	<br />
</cfif>
<cfoutput>

	
<form method="post" action="#CurrentPage#">
	
	<table cellpadding="3" cellspacing="1" border="0" width="100%">
	<tr><td colspan="5">
<cfif back EQ "order">
	<span class="pageinstructions">Return to <a href="#back#.cfm?&xT=#xT#&xTD=#xTD#&xFD=#xFD#&OnPage=#OnPage#">Order List</a> without making changes.</span>
<cfelseif back EQ "report_fulfillment">
	<span class="pageinstructions">Return to <a href="#back#.cfm?&xT=#xT#&xTD=#xTD#&xFD=#xFD#&OnPage=#OnPage#">Ship From ITC</a> without making changes.</span>
</cfif>
</td>
<td align="right" style="white-space:nowrap;">
<cfif back EQ "report_fulfillment">
<span class="pageinstructions"><a href="order_ship_packing_slip.cfm?order_ID=#order_ID#&ordit=#ordit#" target="_blank">Print Packing Slip</a></span>
&nbsp;&nbsp;&nbsp;&nbsp;
</cfif>
</td>
</tr>
		<!--- <span class="pageinstructions">Open <a href="order_detail_printable?order_ID=#order_ID#">printable order</a>.</span>
<br /><br />
 --->	

	<tr class="contenthead">
	<td colspan="6" class="headertext">(1) Pick items in shipment</td>
	</tr>
	
	<tr class="contentsearch">
	<td align="center" class="headertext">&nbsp;</td>
	<td align="center" class="headertext">QTY</td>
	<td class="headertext">CAT</td>
	<td class="headertext">SKU</td>
	<td class="headertext">Description</td>
	<td class="headertext">Status</td>
	</tr>
	
	<cfset any_to_be_shipped = "false">
 	<cfloop query="FindOrderItems">
		<tr class="<cfif ListContains(ordit,product_ID,"x") NEQ 0>selectedbgcolor<cfelse>content</cfif>">
		<td align="center">
			<cfif snap_is_dropshipped EQ 0 AND ship_date EQ "">
				Ship This &raquo; <input type="checkbox" name="ship_#inventory_ID#" value="shipthis">
				<input type="hidden" name="#inventory_ID#" value="QTY: #quantity# CAT: #snap_productvalue# SKU: #HTMLEditFormat(snap_sku)# PRODUCT: #snap_meta_name#<cfif snap_options NEQ ""> #snap_options#</cfif>">
				<cfset any_to_be_shipped = "true">
			</cfif>
		</td>
		<td align="center">#quantity#</td>
		<td>#snap_productvalue#</td>
		<td>#HTMLEditFormat(snap_sku)#</td>
		<td>#snap_meta_name#<cfif snap_options NEQ ""><br>#snap_options#</cfif></td>
		<td>
			<cfif snap_is_dropshipped EQ 0 AND ship_date NEQ "">
				<span class="sub">shipped #FLGen_DateTimeToDisplay(ship_date)#<br>tracking## #tracking#</span>
			<cfelseif snap_is_dropshipped EQ 1 AND po_ID EQ "0">
				to be dropshipped
			<cfelseif snap_is_dropshipped EQ 1 AND po_ID NEQ "0">
				<span class="sub">dropshipped #FLGen_DateTimeToDisplay(drop_date)#</span>
			</cfif>
		</td>
		</tr>
	</cfloop>
	</table>
	<br>
	<cfif any_to_be_shipped>
	
	<table cellpadding="3" cellspacing="1" border="0" width="100%">
			
	<tr class="contenthead">
	<td colspan="4" class="headertext">(2) Enter shipment information</td>
	</tr>
	
	<tr class="content">
	<td align="right" width="125">tracking number:</td>
	<td><input type="text" name="tracking" value=""><input type="hidden" name="tracking_required" value="Please enter a tracking number."></td>
	<td align="right">date of shipment:</td>
	<td><input type="text" name="ship_date" value="#FLGen_DateTimeToDisplay()#"><input type="hidden" name="ship_date_required" value="Please enter a date of shipment."></td>
	</tr>
	
	</table>
	
<!---
	
	<br>
	
	<table cellpadding="3" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td class="headertext">(3) Send Email</td>
	</tr>
	
	<tr class="content">
	<td><input type="checkbox" name="send_email" value="yes"> Send shipment email to user.</td>
	</tr>
	
	<tr class="content2">
	<td class="sub">In addition to the text below, the user's email will contain the tracking number and a<br>list of the items checked above. View <a href="order_ship_emailsample.cfm" target="_blank">example</a>.</td>
	</tr>
	
	<tr class="content">
	<td style="padding:10px"><textarea name="emailtext" cols="78" rows="7">Order Shipment
	
The items listed below were shipped via UPS.  You may track your package with the tracking number listed below at www.ups.com
	 
If there are additional items in your order, they will be shipped separately.</textarea></td>
	</tr>
	
	</table>

--->
		
	<br>
	
	<table cellpadding="3" cellspacing="1" border="0" width="100%">
	
	<tr>
	<td align="center">
		<input type="hidden" name="order_ID" value="#order_ID#">
		<input type="hidden" name="back" value="#back#">
		<input type="submit" name="submit" value="Save Shipment Information">
	</td>
	</tr>
	
	</table>
	
	<cfelse>
	
	<span class="alert">There are no items to be shipped.</span>

	</cfif>
		
</form>
<br><br>
<table cellpadding="3" cellspacing="1" border="0" width="100%">

	<tr>
	<td colspan="2" class="contenthead"><b>#company_name# [#program_name#] Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)</b></td>
	</tr>
			
	<tr>
	<td colspan="2" class="content2"><a href="order.cfm?pgfn=edit&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&OnPage=#OnPage#">Edit Order Information</a></td>
	</tr>
			
	<tr class="content">
	<td valign="top">Ship To:<br>
		<cfif snap_ship_company NEQ "">#snap_ship_company#<br></cfif>
		<cfif snap_ship_fname NEQ "">#snap_ship_fname#</cfif> <cfif snap_ship_lname NEQ "">#snap_ship_lname#</cfif><br>
		<cfif snap_ship_address1 NEQ "">#snap_ship_address1#<br></cfif>
		<cfif snap_ship_address2 NEQ "">#snap_ship_address2#<br></cfif>
		<cfif snap_ship_city NEQ "">#snap_ship_city#</cfif>, <cfif snap_ship_state NEQ "">#snap_ship_state#</cfif> <cfif snap_ship_zip NEQ "">#snap_ship_zip#</cfif><br>
		<cfif snap_phone NEQ "">Phone: #snap_phone#</cfif><br>
		<cfif shipping_desc NEQ "">Ship via #shipping_desc#: #shipping_charge#</cfif>
		<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#</cfif>
	</td>
	<td valign="top">Order Note:<br><cfif order_note NEQ "">#Replace(HTMLEditFormat(order_note),chr(10),"<br>","ALL")#<cfelse><span class="sub">(none)</span></cfif></td>
	</tr>
</table>
<br>
<cfif TRIM(modified_concat) NEQ "">
	
	<table cellpadding="3" cellspacing="1" border="0" width="100%">

	<tr class="contenthead">
	<td colspan="2" class="headertext">Order Modification History </td>
	</tr>

	<tr class="content">
	<td colspan="2">#FLGen_DisplayModConcat(modified_concat)#</td>
	</tr>
			
	</table>
	
</cfif>
</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->