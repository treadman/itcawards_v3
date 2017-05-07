<cfsetting showdebugoutput="no" enablecfoutputonly="yes">
<cfset error = "">
<cfparam name="po_ID" default="">
<cfif NOT isNumeric(po_ID)>
	<cfset error = po_ID&" is an invalid PO number">
	<cfset po_ID = 0>
</cfif>
<cfheader name="Content-Disposition" value="attachment;filename=po_#po_ID-1000000000#.csv">
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
		<cfoutput>PO #po_ID-1000000000# not found!</cfoutput>
	<cfelse>
		<cfquery name="GetPOInvItems" datasource="#application.DS#">
			SELECT <cfif GetPOInfo.is_dropship EQ 1>quantity<cfelse>po_quantity</cfif> AS qty, snap_meta_name, snap_description, snap_sku, snap_vendor_sku, snap_sku, snap_options, snap_productvalue , order_ID, ID AS inventory_ID, product_ID 
			FROM #application.database#.inventory
			WHERE po_ID =<cfqueryparam cfsqltype="cf_sql_integer" value="#po_ID#" maxlength="10"> 
				AND is_valid = 1 
			ORDER BY product_ID
		</cfquery>
		<cfoutput>Quantity,Description,Option, Vendor SKU
</cfoutput>
		<cfloop query="GetPOInvItems">
			<!--- need to get the pack size/desc, min qty, and min order $ --->
			<cfquery name="ProdVenLkup" datasource="#application.DS#">
				SELECT is_default, vendor_sku, vendor_cost, vendor_min_qty, pack_size, pack_desc 
				FROM #application.database#.vendor_lookup 
				WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
				AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GetPOInfo.vendor_ID#" maxlength="10"> 
			</cfquery>
			<!--- if this prod has packs, make adjustment to qty --->
			<cfif ProdVenLkup.pack_size NEQ "">
				<cfset qty_display = "#qty / ProdVenLkup.pack_size# #ProdVenLkup.pack_desc#(s) (#qty# pieces)">
			<cfelse>
				<cfset qty_display = qty>
			</cfif>
			<cfoutput>#qty_display#,</cfoutput>
			<cfoutput>#snap_meta_name#,#snap_options#,#snap_vendor_sku#
</cfoutput>
		</cfloop>
	</cfif>
</cfif>
