<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<cfset error = "">
<cfparam name="po_ID" default="">
<cfif NOT isNumeric(po_ID)>
	<cfset error = "Invalid PO Number">
	<cfset po_ID = 0>
</cfif>

<cfinclude template="includes/header_lite.cfm">

<cfif error NEQ "">
	<cfoutput>#error#</cfoutput>
<cfelse>
	<!--- get po info --->
	<cfquery name="GetPOInfo" datasource="#application.DS#">
		SELECT vendor_ID, snap_vendor, snap_attention, snap_phone, snap_fax, is_dropship, po_rec_date, itc_name, itc_phone, itc_fax, itc_email, po_printed_note, Date_Format(created_datetime,'%c/%d/%Y') AS created_date   
		FROM #application.database#.purchase_order 
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#" maxlength="10">
	</cfquery>
<cfif GetPOInfo.recordcount NEQ 1>
	PO not found!
<cfelse>
<table cellpadding="0" cellspacing="0" border="0" width="593" align="center">
<tr>
	<td colspan="2" align="left"><img src="../pics/itclogo.jpg" width="794" height="149"></td>
</tr>
<tr>
	<td colspan="2" align="left">
		<table cellspacing="0" cellpadding="6" width="593" style="border:2px solid #000000;">
		<cfoutput>
		<tr>
			<td align="left" width="297" class="printhead" style="border-bottom:2px solid ##000000">Purchase Order</td>
			<td align="right" width="296" class="printlabel" style="border-bottom:2px solid ##000000;border-left:2px solid ##000000">#GetPOInfo.created_date#</td>
		</tr>
		<tr>
		<td align="left" width="297" valign="top" class="printlabel">
			For: #GetPOInfo.snap_vendor#<br /><br />
			Attn: #GetPOInfo.snap_attention#<br /><br />
			Phone: #GetPOInfo.snap_phone#<br /><br />
			Fax: #GetPOInfo.snap_fax#
		</td>
		<td align=left width=296 valign="top" class="printlabel" style="border-left:2px solid ##000000">
			From: #GetPOInfo.itc_name#<br /><br />
			Phone: #GetPOInfo.itc_phone#<br /><br />
			Fax: #GetPOInfo.itc_fax#<br /><br />
			Email: #GetPOInfo.itc_email#
		</td>
		</tr>
		</cfoutput>
		</table>
	</td>
</tr>
<tr>
	<td colspan=2 align=center height=10>&nbsp;</td>
</tr>
<tr>
	<td colspan="2" align="center" class="printlabel">Purchase Order <cfoutput>#po_ID-1000000000#</cfoutput></td>
</tr>
<tr>
	<td colspan=2 align="center" height="20">&nbsp;</td>
</tr>
<cfquery name="GetPOInvItems" datasource="#application.DS#">
	SELECT <cfif GetPOInfo.is_dropship EQ 1>quantity<cfelse>po_quantity</cfif> AS qty, snap_meta_name, snap_description, snap_sku, snap_vendor_sku, snap_sku, snap_options, snap_productvalue , order_ID, ID AS inventory_ID, product_ID 
	FROM #application.database#.inventory
	WHERE po_ID =<cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#" maxlength="10"> 
		AND is_valid = 1 
	ORDER BY product_ID
</cfquery>
<cfset old_product_id = "">
<cfset old_ship_to = "FIRST_TIME">
<cfloop query="GetPOInvItems">
	<!--- need to get the pack size/desc, min qty, and min order $ --->
	<cfquery name="ProdVenLkup" datasource="#application.DS#">
		SELECT is_default, vendor_sku, vendor_cost, vendor_min_qty, pack_size, pack_desc 
		FROM #application.database#.vendor_lookup 
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
		AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#" maxlength="10"> 
	</cfquery>
	<cfif GetPOInfo.is_dropship EQ 1>
		<!--- find the shipto address --->
		<cfquery name="OrderInfo" datasource="#application.DS#">
			SELECT snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, 
				snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone 
			FROM #application.database#.order_info
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
		</cfquery>
		<cfset this_ship_to = "#OrderInfo.snap_ship_fname# #OrderInfo.snap_ship_lname#<br>#OrderInfo.snap_ship_address1#<br>">
		<cfif OrderInfo.snap_ship_address2 NEQ ""><cfset this_ship_to = this_ship_to & "#OrderInfo.snap_ship_address2#<br>"></cfif>
		<cfset this_ship_to = this_ship_to & "#OrderInfo.snap_ship_city#, #OrderInfo.snap_ship_state# #OrderInfo.snap_ship_zip#<br>#OrderInfo.snap_phone#">
		<cfif old_ship_to NEQ "FIRST_TIME" AND old_ship_to NEQ this_ship_to>
			<tr>
				<td class="printtext" align="right" valign="top">SHIP TO:&nbsp;&nbsp;&nbsp;</td>
				<td valign="top">
					<cfoutput>#old_ship_to#</cfoutput>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
				</td>
			</tr>
			<tr>
				<td colspan="2">&nbsp;</td>
			</tr>
		</cfif>
		<cfset old_ship_to = this_ship_to>
	</cfif>
	<!---<cfif old_product_id NEQ product_ID>--->
		<tr>
			<td colspan="2" class="printlabel"><cfoutput>#snap_meta_name# #snap_options#<cfif snap_vendor_sku NEQ ""><br><span class="printtext">Vendor SKU: #snap_vendor_sku#</span></cfif></cfoutput></td>
		</tr>
	<!---</cfif>--->
	<!--- if this prod has packs, make adjustment to qty --->
	<cfif ProdVenLkup.pack_size NEQ "">
		<cfset qty_display = "#qty / ProdVenLkup.pack_size# #ProdVenLkup.pack_desc#(s) (#qty# pieces)">
	<cfelse>
		<cfset qty_display = qty>
	</cfif>
	<tr>
		<td colspan="2" class="printtext" valign="top">Quantity: <cfoutput>#qty_display#</cfoutput></td>
	</tr>
	<tr>
		<td colspan="2">&nbsp;</td>
	</tr>
	<cfset old_product_id = product_ID>
</cfloop>
<tr>
	<td class="printtext" align="right" valign="top">SHIP TO:&nbsp;&nbsp;&nbsp;</td>
	<td valign="top">
		<cfif GetPOInfo.is_dropship EQ 0>
			ITC Specialty<br>Attn: Awards<br>13 Garfield Way<br>Newark, DE 19713
		<cfelse>
			<cfif old_ship_to NEQ "FIRST_TIME">
				<cfoutput>#old_ship_to#</cfoutput>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			</cfif>
		</cfif>
	</td>
</tr>
<tr>
	<td colspan="2">&nbsp;</td>
</tr>
<cfquery name="FindVendor" datasource="#application.DS#">
	SELECT what_terms   
	FROM #application.database#.vendor 
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#" maxlength="10">
</cfquery>
<cfset what_terms = HTMLEditFormat(FindVendor.what_terms)>
<tr>
	<td colspan="2" align="left" class="printtext">
		<cfoutput>
		Terms: #what_terms#
		<cfif GetPOInfo.po_printed_note NEQ ''>
			<br><br>
			Note:<br>
			#Replace(HTMLEditFormat(GetPOInfo.po_printed_note),chr(10),"<br>","ALL")#
		</cfif>
		</cfoutput>
		<br><br>
		Thank you
	</td>
</tr>
</table>
</cfif>
</cfif>
<cfinclude template="includes/footer.cfm">

