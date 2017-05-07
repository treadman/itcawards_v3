<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="v_ID" default="">
<cfparam name="OnPage" default="1">
<cfparam name="set_ID" default="">

<cfif NOT isNumeric(set_ID) OR set_ID LT 1>
	<cflocation url="report_po.cfm" addtoken="no">
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>

	<cfset found_one = "false">
	<!--- make sure that a check box was submitted --->
	<cfif IsDefined('form.FieldNames') AND Trim(form.FieldNames) IS NOT "">
		<cfloop list="#form.FieldNames#" INDEX="FormField">
			<cfif FormField CONTAINS "inv_">
				<cfset found_one = "true">
				<cfbreak>
			</cfif>
		</cfloop>
	</cfif>

	<!--- create PO record and get ID --->
	<cfif found_one>
	
		<!--- get vendor info --->
		<cfquery name="GetVendorInfoForSnaps" datasource="#application.DS#">
			SELECT ID AS vendor_ID, vendor, attention, phone, fax 
			FROM #application.database#.vendor 
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#">
		</cfquery>
		<!--- get logged in user info --->
		<cfquery name="GetAdmin" datasource="#application.ds#">
			SELECT U.email, U.firstname, U.lastname
			FROM #application.database#.admin_login L
			LEFT JOIN #application.database#.admin_users U ON U.ID = L.created_user_ID
			WHERE L.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListFirst(cookie.admin_login,'-')#" maxlength="10">
		</cfquery>
		<cfif GetAdmin.recordcount GT 0>
			<cfset thisEmail = GetAdmin.email>
			<cfset thisName = GetAdmin.firstname&" "&GetAdmin.lastname>
		<cfelse>
			<cfset thisEmail = "#application.AwardsProgramAdminEmail#">
			<cfset thisName = "Sarah Woodland">
		</cfif>
		<!--- create a new po --->
		<cflock name="purchase_orderLock" timeout="10">
			<cftransaction>
				<!--- TODO:  There are hard coded values here for "ITC_" fields in this table.  They should be in an adminable place. --->
				<cfquery datasource="#application.DS#" name="insNewOrder">
					INSERT INTO #application.database#.purchase_order 
					(created_user_ID, created_datetime, vendor_ID, is_dropship, snap_vendor, snap_attention, snap_phone, snap_fax, itc_name, itc_phone, itc_fax, itc_email)
					VALUES
					('#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#', '#GetVendorInfoForSnaps.vendor_ID#', 1, '#Replace(GetVendorInfoForSnaps.vendor," (DROPSHIP)","")#', '#GetVendorInfoForSnaps.attention#', '#GetVendorInfoForSnaps.phone#', '#GetVendorInfoForSnaps.fax#', '#thisName#', '302-266-6100', '302-266-6109', '#thisEmail#' )
				</cfquery>
				<cfquery datasource="#application.DS#" name="getID">
					SELECT Max(ID) As MaxID FROM #application.database#.purchase_order
				</cfquery>
				<cfset new_po_ID = getID.MaxID>
			</cftransaction>
		</cflock>

		<!--- update the submitted checkboxes with the PO_ID and snap_vendor and drop_date --->
		<cfif IsDefined('form.FieldNames') AND Trim(form.FieldNames) IS NOT "">
			<cfloop list="#form.FieldNames#" INDEX="FormField">
				<cfif FormField CONTAINS "inv_">
					<cfset this_inv_item = RemoveChars(FormField,1,4)>
					<cfset mod_note = "(*auto* dropship PO generated)">
					<cfquery name="FindVendorSku" datasource="#application.DS#">
						SELECT vl.vendor_sku 
						FROM #application.database#.vendor_lookup vl JOIN #application.database#.product prod ON vl.product_ID = prod.ID 
							JOIN #application.database#.inventory inv ON inv.product_ID = prod.ID 
						WHERE vl.vendor_ID ='#GetVendorInfoForSnaps.vendor_ID#' 
						AND inv.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_inv_item#">
					</cfquery>
					<cfquery name="UpdateDropItem" datasource="#application.DS#">
						UPDATE #application.database#.inventory 
						SET po_ID= <cfqueryparam cfsqltype="cf_sql_integer" value="#new_po_ID#" maxlength="10">,
							snap_vendor = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Replace(GetVendorInfoForSnaps.vendor," (DROPSHIP)","")#" maxlength="60">, 
							snap_vendor_sku = '#FindVendorSku.vendor_sku#',
							drop_date = #Now()#
							#FLGen_UpdateModConcatSQL(mod_note)#
							WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_inv_item#">
					</cfquery>
				</cfif>
			</cfloop>
		</cfif>
		
		<cflocation addtoken="no" url="po_detail.cfm?pgfn=detail&po_ID=#new_po_ID#&xT=#xTD#=&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#&new=yes&set_ID=#set_ID#">
	<cfelse>
		<cfset alert_error = 'Please select at least one item to create a new purchase order.'>	
	</cfif>
	
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "po_builder">
<cfinclude template="includes/header.cfm">

<span class="pagetitle">Build a New Purchase Order</span>
<br /><br />
<span class="pageinstructions">Return to <a href="report_po.cfm?set_ID=#set_ID#">Potential Purchase Orders</a> without making changes.</span>
<br /><br />

<!--- find vendor info --->
<cfquery name="FindVendor" datasource="#application.DS#">
	SELECT ID as vendor_ID, vendor, phone, fax, attention, what_terms  
	FROM #application.database#.vendor 
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#" maxlength="10">
</cfquery>
<cfset vendor = HTMLEditFormat(FindVendor.vendor)>
<cfset phone = HTMLEditFormat(FindVendor.phone)>
<cfset fax = HTMLEditFormat(FindVendor.fax)>
<cfset attention = HTMLEditFormat(FindVendor.attention)>
<cfset what_terms = HTMLEditFormat(FindVendor.what_terms)>

<!--- find all products assigned to this vendor --->
<cfquery name="FindVenProd" datasource="#application.DS#">
	SELECT vl.product_ID, prod.is_dropshipped 
	FROM #application.database#.vendor_lookup vl JOIN #application.database#.product prod ON vl.product_ID = prod.ID 
	WHERE vl.vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#" maxlength="10">
	AND prod.ID IN (SELECT ID FROM #application.database#.product WHERE product_meta_ID IN (SELECT ID FROM #application.database#.product_meta WHERE product_set_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#set_ID#" maxlength="10">))
</cfquery>

<cfoutput>
<form method="post" action="#CurrentPage#?set_ID=#set_ID#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr class="contenthead">
	<td colspan="2"><b>#vendor#</b></td>
	</tr>
	<cfloop query="FindVenProd">
		<cfset product_ID = FindVenProd.product_ID>
		<!--- if dropshipped, see if any undropshipped --->
		<cfif is_dropshipped EQ 1>
			<cfquery name="AnyUnDropped" datasource="#application.DS#">
				SELECT ID as inventory_ID, quantity, snap_meta_name, snap_sku, snap_options, order_ID, snap_vendor_sku 
				FROM #application.database#.inventory
				WHERE is_valid = 1 
					AND order_ID <> 0 
					AND snap_is_dropshipped = 1 
					AND order_ID <> 0 
					AND ship_date IS NULL 
					AND po_ID = 0 
					AND po_rec_date IS NULL 
					AND product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
			</cfquery>
			<!--- display UNDROPSHIPPED products here --->
			<cfloop query="AnyUnDropped">
				<!--- any other vendor for this product? --->
				<cfquery name="HasMultiVendors" datasource="#application.DS#">
					SELECT ID 
					FROM #application.database#.vendor_lookup 
					WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
				</cfquery>
				<!--- if this product has multiple vendors, find out if this one is default or alternative vendor --->
				<cfif HasMultiVendors.RecordCount GT 1>
					<cfquery name="CheckIf" datasource="#application.DS#">
						SELECT IF(is_default=1, "true", "false") AS is_default  
						FROM #application.database#.vendor_lookup 
						WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
							AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#">
					</cfquery>
				</cfif>
				<tr <cfif HasMultiVendors.RecordCount GT 1><cfif CheckIf.is_default>class="selectedbgcolor"<cfelse>class="inactivebg"</cfif><cfelse>class="content"</cfif>>
				<td align="right"><cfif HasMultiVendors.RecordCount GT 1><cfif CheckIf.is_default><span class="selecteditem">default</span><cfelse><span class="sub">alternate</span></cfif><cfelse>&nbsp;</cfif>
				<input type="checkbox" name="inv_#inventory_ID#" value="yes">
				</td>
				<td>QTY: #quantity# <b>#snap_meta_name#</b> #snap_options#<br>ITC SKU: #snap_sku#<br>Vendor SKU: #snap_vendor_sku#</td>
				</tr>
				<cfquery name="OrderInfo" datasource="#application.DS#">
					SELECT order_number, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip, program_ID 
					FROM #application.database#.order_info
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#">
				</cfquery>
				<tr <cfif HasMultiVendors.RecordCount GT 1><cfif CheckIf.is_default>class="selectedbgcolor"<cfelse>class="inactivebg"</cfif><cfelse>class="content"</cfif>>
				<td>&nbsp;</td>
				<td>#GetProgramName(OrderInfo.program_ID)# Order #OrderInfo.order_number#<br>SHIP TO: #OrderInfo.snap_ship_fname# #OrderInfo.snap_ship_lname#, #OrderInfo.snap_ship_address1# #OrderInfo.snap_ship_address2#, #OrderInfo.snap_ship_city#, #OrderInfo.snap_ship_state# #OrderInfo.snap_ship_zip#</td>
				</tr>
			</cfloop>
		</cfif>
	</cfloop>
	<tr class="content">
	<td colspan="2" align="center">	
		<input type="hidden" name="vendor_ID" value="#vendor_ID#">
		<input type="submit" name="submit" value="Create PO">
	</td>
	</tr>
	</table>
</form>
</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->