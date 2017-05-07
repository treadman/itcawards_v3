<cfset page_title = "Packing Slip">
<cfinclude template="includes/header_lite.cfm">

<cfparam name="order_ID" default="">
<cfparam name="ordit" default="">

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

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

<span class="pagetitle">Shipment Information</span>
<br /><br />

<cfoutput>
<table cellpadding="3" cellspacing="1" border="0">

	<tr>
	<td colspan="2" class="contenthead"><b>#company_name# [#program_name#] Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)</b></td>
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
<cfif ordit EQ "">
	<span class="pageinstructions"><span class="alert">There may be no physical stock for the items below:</span></span>
<cfelse>
	<span class="pageinstructions">Only the highlighted products have available inventory:</span>
</cfif>
<br />
	
	<table cellpadding="3" cellspacing="1" border="0">
		
	<tr class="contentsearch">
	<td align="center" class="headertext" width="20">&nbsp;</td>
	<td align="center" class="headertext" width="30">QTY</td>
	<!--- <td class="headertext">CAT</td> --->
	<td align="center" class="headertext" width="50">SKU</td>
	<td class="headertext" width="400">Description</td>
	<td class="headertext">Status<!--- #RepeatString("&nbsp;",50)# ---></td>
	</tr>
	
	<cfset any_to_be_shipped = "false">
 	<cfloop query="FindOrderItems">
		<tr height="30" class="<cfif ListContains(ordit,product_ID,"x") NEQ 0>selectedbgcolor<cfelse>content</cfif>">
		<td align="center">
			<cfif snap_is_dropshipped EQ 0 AND ship_date EQ "">
				<img src="pics/check_box.gif" border="0" height="15" width="15">
				<cfset any_to_be_shipped = "true">
			</cfif>
		</td>
		<td align="center">#quantity#</td>
		<!--- <td>#snap_productvalue#</td> --->
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
	
	<cfelse>
	
	<span class="alert">There are no items to be shipped.</span>
<br>
	</cfif>
		

<cfif TRIM(modified_concat) NEQ "">
	
	<table cellpadding="3" cellspacing="1" border="0">

	<tr class="contenthead">
	<td colspan="2" class="headertext">Order Modification History </td>
	</tr>

	<tr class="content">
	<td colspan="2">#FLGen_DisplayModConcat(modified_concat)#</td>
	</tr>
			
	</table>
	
</cfif>
</cfoutput>

</body>
</html>

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->