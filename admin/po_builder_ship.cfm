<cfsetting showdebugoutput="false" >
<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
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

<cfset po_total_cost = "0">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>

	<cfset found_one = "false">
	<!--- make sure that a check box was submitted --->
	<cfif IsDefined('form.FieldNames') AND Trim(form.FieldNames) IS NOT "">
		<cfloop list="#form.FieldNames#" INDEX="FormField">
			<cfif FormField CONTAINS "prod_" AND Evaluate(FormField) NEQ "" AND  Evaluate(FormField) NEQ 0>
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
		<cfquery name="GetAdmin" datasource="#application.DS#">
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
				<cfquery name="insNewOrder" datasource="#application.DS#">
					INSERT INTO #application.database#.purchase_order 
					(created_user_ID, created_datetime, vendor_ID, is_dropship, snap_vendor, snap_attention, snap_phone, snap_fax, itc_name, itc_phone, itc_fax, itc_email)
					VALUES
					('#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#', '#GetVendorInfoForSnaps.vendor_ID#', 0, '#Replace(GetVendorInfoForSnaps.vendor," (DROPSHIP)","")#', '#GetVendorInfoForSnaps.attention#', '#GetVendorInfoForSnaps.phone#', '#GetVendorInfoForSnaps.fax#', '#thisName#', '302-266-6100', '302-266-6109', '#thisEmail#' )
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.purchase_order
				</cfquery>
				<cfset new_po_ID = getID.MaxID>
			</cftransaction>
		</cflock>

		<!--- create inventory entries with this PO_ID and snap_vendor and drop_date --->
		<cfif IsDefined('form.FieldNames') AND Trim(form.FieldNames) IS NOT "">
			<cfloop list="#form.FieldNames#" INDEX="FormField">
				<cfif FormField CONTAINS "prod_" AND Evaluate(FormField) NEQ "" AND  Evaluate(FormField) NEQ 0>
					<cfset this_po_prod = RemoveChars(FormField,1,5)>
					<cfset this_po_qty = Evaluate(FormField)>
					<!--- if ordered in packs and/or minimum, calculate new po qty --->
					<cfquery name="ProdVenLkup" datasource="#application.DS#">
						SELECT vl.vendor_sku, vl.vendor_min_qty, IFNULL(vl.pack_size,0) AS pack_size, vl.pack_desc 
						FROM #application.database#.vendor_lookup vl 
						WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_po_prod#">
							AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#">
					</cfquery>
					<cfif ProdVenLkup.pack_size NEQ 0>
						<cfset this_po_qty = this_po_qty * ProdVenLkup.pack_size>
					</cfif>
					<!---<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#Evaluate("form.desc_" & this_po_prod)#">--->
					<!--- Insert new inventory entry for po --->
					<cfquery name="insNewOrder" datasource="#application.DS#">
						INSERT INTO #application.database#.inventory 
						(created_user_ID, created_datetime, 
							is_valid,
							product_ID, 
							quantity,
							snap_meta_name, 
							snap_description, 
							snap_sku,
							snap_productvalue,
							snap_options,
							snap_is_dropshipped, 
							order_ID,
							po_ID,
							po_quantity,
							snap_vendor_sku,
							snap_vendor,
							vendor_ID)
						VALUES
						('#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#', 
							1,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#this_po_prod#" maxlength="10">, 
							0,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#Evaluate("form.name_" & this_po_prod)#" maxlength="64">, 
							'', 
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#Evaluate("form.sku_" & this_po_prod)#" maxlength="64">, 
							<cfqueryparam cfsqltype="cf_sql_integer" value="#Evaluate("form.pv_" & this_po_prod)#" maxlength="8">, 
							<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#Evaluate("form.opt_" & this_po_prod)#">, 
							0, 
							0,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#new_po_ID#" maxlength="10">, 
							<cfqueryparam cfsqltype="cf_sql_integer" value="#this_po_qty#" maxlength="8">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#ProdVenLkup.vendor_sku#" maxlength="128">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#Replace(GetVendorInfoForSnaps.vendor,' (DROPSHIP)','')#" maxlength="38">,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#GetVendorInfoForSnaps.vendor_ID#" maxlength="10">)
					</cfquery>
				</cfif>
			</cfloop>
		</cfif>
		<cflocation addtoken="no" url="po_detail.cfm?pgfn=detail&po_ID=#new_po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#&new=yes&set_ID=#set_ID#">
	<cfelse>
		<cfset alert_error = 'Please enter a value for the products you want to add to the new purchase order.'>
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

<span class="pagetitle">Build a New Purchase Order</span><br />
<br />
<span class="pageinstructions">You can change quantities after the Purchase Order is created.</span>
<br /><br />
<span class="pageinstructions"><b>Price</b> is per individual product, not per pack.</span>
<br /><br />
<span class="pageinstructions"><b>PO Qty</b> is the number packs to order, or individual products, if it doesn't come in packs.</span>
<br /><br />
<span class="pageinstructions">Leave PO Qty blank if you don't want the product to be included on the new PO.</span>
<br /><br />
<span class="pageinstructions">Return to <a href="report_po.cfm?set_ID=#set_ID#">Potential Purchase Orders</a> without making changes.</span>
<br /><br />

<!--- find vendor info --->
<cfquery name="FindVendor" datasource="#application.DS#">
	SELECT ID as vendor_ID, vendor, phone, fax, attention, min_order  
	FROM #application.database#.vendor 
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#">
</cfquery>
<cfset vendor = HTMLEditFormat(FindVendor.vendor)>
<cfset phone = HTMLEditFormat(FindVendor.phone)>
<cfset fax = HTMLEditFormat(FindVendor.fax)>
<cfset attention = HTMLEditFormat(FindVendor.attention)>
<cfset min_order = HTMLEditFormat(FindVendor.min_order)>

<!--- find all products assigned to this vendor --->
<cfquery name="FindVenProd" datasource="#application.DS#">
	SELECT vl.product_ID, prod.is_dropshipped, m.meta_name, m.description, prod.sku, pvm.productvalue AS this_productvalue
	FROM #application.database#.vendor_lookup vl
	JOIN #application.database#.product prod ON vl.product_ID = prod.ID
		JOIN #application.database#.product_meta m ON m.ID = prod.product_meta_ID 
		JOIN #application.database#.productvalue_master pvm ON pvm.ID = m.productvalue_master_ID
	WHERE vl.vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#">
	AND prod.ID IN (SELECT ID FROM #application.database#.product WHERE product_meta_ID IN (SELECT ID FROM #application.database#.product_meta WHERE product_set_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#set_ID#" maxlength="10">))
</cfquery>

<cfoutput>
<form method="post" action="#CurrentPage#?set_ID=#set_ID#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr class="contenthead">
	<td colspan="5"><b>#vendor#</b></td>
	</tr>
	<tr class="contentsearch">
	<td>Need</td>
	<td>Price</td>
	<td>PO&nbsp;Qty</td>
	<td>Pack&nbsp;(min&nbsp;qty)</td>
	<td width="100%">Product</td>
	</tr>
	<cfloop query="FindVenProd">
		<cfset product_ID = FindVenProd.product_ID>
		<!--- if shipped, see if physical inventory is lt 0 --->
		<cfif is_dropshipped EQ 0>
			<!--- find all the product that haven't been shipped yet --->
			<cfquery name="AnyUnShipped" datasource="#application.DS#">
				SELECT ID as inventory_ID, quantity, snap_meta_name, snap_options
				FROM #application.database#.inventory
				WHERE is_valid = 1
					AND quantity <> 0  
					AND snap_is_dropshipped = 0 
					AND order_ID <> 0 
					AND ship_date IS NULL
					AND po_ID = 0 
					AND po_rec_date IS NULL 
					AND product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
			</cfquery>
			<!--- if unshipped exist, check virtual inventory and see if negative --->
			<cfif AnyUnShipped.RecordCount GT 0>
				<cfset PhysicalInvCalc(product_ID)>
				<!--- if the virtual inventory is LT 0, list it here --->
				<cfif PIC_total_virtual LT 0>
					<!--- find the product/vendor lookup info --->
					<cfquery name="ProdVenLkup" datasource="#application.DS#">
						SELECT is_default, vendor_sku, vendor_cost, vendor_min_qty, pack_size, pack_desc 
						FROM #application.database#.vendor_lookup 
						WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#">
							AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#">
					</cfquery>
					<!--- find the product option info --->
					<cfset FPO_theseoptions = FindProductOptions(product_ID)>
					<!--- display UNSHIPPED products here --->
					<!--- total cost calculations --->
					<cfset po_lineitem_cost = Abs(PIC_total_virtual) * ProdVenLkup.vendor_cost>
					<cfset po_total_cost = po_total_cost + po_lineitem_cost>
					<tr class="content">
					<td align="center">#Abs(PIC_total_virtual)#<br><a href="unshipped.cfm?product_ID=#product_ID#" target="_blank">view&nbsp;list</a></td>
					<td align="right">$#ProdVenLkup.vendor_cost#</td>
					<td>
						<input type="text" name="prod_#product_ID#" size="6" maxlength="6" value="#Abs(PIC_total_virtual)#">
						<input type="hidden" name="name_#product_ID#" value="#HTMLEditFormat(meta_name)#">
						<!---<input type="hidden" name="desc_#product_ID#" value="#HTMLEditFormat(description)#">--->
						<input type="hidden" name="sku_#product_ID#" value="#HTMLEditFormat(sku)#">
						<input type="hidden" name="pv_#product_ID#" value="#HTMLEditFormat(this_productvalue)#">
						<input type="hidden" name="opt_#product_ID#" value="#HTMLEditFormat(FPO_theseoptions)#">
					</td>
					<td><cfif NOT ProdVenLkup.pack_size EQ "">#ProdVenLkup.pack_size#&nbsp;per&nbsp;#ProdVenLkup.pack_desc#</cfif><cfif ProdVenLkup.vendor_min_qty NEQ "1">&nbsp;(min&nbsp;#ProdVenLkup.vendor_min_qty#<cfif ProdVenLkup.pack_desc NEQ ""> #ProdVenLkup.pack_desc#(s)</cfif>)</cfif></td>
					<td><b>#meta_name#</b> #FPO_theseoptions#<br>ITC SKU: #sku#<br>Vendor SKU: #ProdVenLkup.vendor_sku#</td>
					</tr>
				</cfif>
			</cfif>
		</cfif>
	</cfloop>
	<tr class="content">
	<td>&nbsp;</td>
	<td align="right" class="headertext">$#po_total_cost#</td>
	<td colspan="3" class="headertext">Total <span class="sub">(if ordering just what is needed)</span></td>
	</tr>
	<cfif min_order NEQ 0>
		<tr class="content">
		<td>&nbsp;</td>
		<td class="alert" align="right">$#min_order#</td>
		<td colspan="3" class="alert">Minimum Order</td>
		</tr>
	</cfif>
	<tr class="content">
	<td colspan="5" align="center">	
		<input type="hidden" name="vendor_ID" value="#vendor_ID#">
		<input type="submit" name="submit" value="Create PO">
	</td>
	</tr>
	</table>
</form>
</cfoutput>

<!--- 
	<!--- if the product has multi vendors, indicate this, somehow --->
	<cfquery name="HasMultiVendors" datasource="#application.DS#">
		SELECT ID 
		FROM #application.database#.vendor_lookup 
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#FindVendorProds.product_ID#">
	</cfquery>
	
	<!--- if this product has multiple vendors, find out if this one is default or alternative vendor --->
	<cfif HasMultiVendors.RecordCount GT 1>
		<cfquery name="CheckIf" datasource="#application.DS#">
			SELECT IF(is_default=1, "true", "false") AS is_default  
			FROM #application.database#.vendor_lookup 
			WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#FindVendorProds.product_ID#">
				AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#">
		</cfquery>
	</cfif>
 --->

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->