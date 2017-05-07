<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000113,true)>

<cfset pgfn = "start">

<cfquery name="ProductSet" datasource="#application.DS#">
	SELECT ID, set_name, note, sortorder
	FROM #application.database#.product_set
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="1" maxlength="10">
</cfquery>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "products">
<cfinclude template="includes/header.cfm">

<cfset ProductPicsFolder = "pics/products/">
<cfset ProductSetID = 1>
<cfif isDefined("form.submit") AND isDefined("form.ok2continue")>
	<!--- Deletes --->
	<cfquery name="GetProductsToDelete" datasource="#application.DS#">
		SELECT ID, thumbnailname, imagename
		FROM #Application.database#.product_meta
		WHERE product_set_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProductSetID#">
	</cfquery>
	<!--- <cfloop query="GetProductsToDelete">
		<cftry>
			<cffile action="delete" file="/inetpub/wwwroot/htdocs/content/#Application.database#.com/pics/products/#GetProductsToDelete.thumbnailname#">
			<cfcatch></cfcatch>
		</cftry>
		<cftry>
			<cffile action="delete" file="/inetpub/wwwroot/htdocs/content/#Application.database#.com/pics/products/#GetProductsToDelete.imagename#">
			<cfcatch></cfcatch>
		</cftry>
	</cfloop> --->
	<cfquery name="DeleteProductMeta" datasource="#application.DS#">
		DELETE FROM #Application.database#.product_meta
		WHERE product_set_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="1">
	</cfquery>
	<cfquery name="DeleteProductMetaGroup" datasource="#application.DS#">
		DELETE FROM #Application.database#.product_meta_group
	</cfquery>
	<cfquery name="DeleteProductMetaGroupLookup" datasource="#application.DS#">
		DELETE FROM #Application.database#.product_meta_group_lookup
		WHERE product_meta_ID NOT IN ( SELECT ID FROM #Application.database#.product_meta )
	</cfquery>
	<cfquery name="DeleteProductMetaOptionCategory" datasource="#application.DS#">
		DELETE FROM #Application.database#.product_meta_option_category
		WHERE product_meta_ID NOT IN ( SELECT ID FROM #Application.database#.product_meta )
	</cfquery>
	<cfquery name="DeleteProduct" datasource="#application.DS#">
		DELETE FROM #Application.database#.product
		WHERE product_meta_ID NOT IN ( SELECT ID FROM #Application.database#.product_meta )
	</cfquery>
	<cfquery name="DeleteProductOption" datasource="#application.DS#">
		DELETE FROM #Application.database#.product_option
		WHERE product_ID NOT IN ( SELECT ID FROM #Application.database#.product )
	</cfquery>
	<cfquery name="DeleteProductOption" datasource="#application.DS#">
		DELETE FROM #Application.database#.product_meta_option
		WHERE product_meta_option_category_ID NOT IN ( SELECT ID FROM #Application.database#.product_meta_option_category )
	</cfquery>
	<!--- Get some ID Lists --->
	<cfquery name="GetProductIDs" datasource="#application.DS#">
		SELECT ID
		FROM #Application.product_database#.product
	</cfquery>
	<cfset ProductIDList = ValueList(GetProductIDs.ID)>
	<cfquery name="GetProductMetaIDs" datasource="#application.DS#">
		SELECT DISTINCT product_meta_ID
		FROM #Application.product_database#.product
	</cfquery>
	<cfset ProductMetaIDList = ValueList(GetProductMetaIDs.product_meta_ID)>
	<cfquery name="GetProductMetaOptionCatIDs" datasource="#application.DS#">
		SELECT ID
		FROM #Application.product_database#.product_meta_option_category
		WHERE product_meta_ID IN (#ProductMetaIDList#)
	</cfquery>
	<cfquery name="DeleteVendor" datasource="#application.DS#">
		DELETE FROM #Application.database#.vendor
		WHERE ID < 2000000000
	</cfquery>
	<cfquery name="DeleteVendorLookup" datasource="#application.DS#">
		DELETE FROM #Application.database#.vendor_lookup
		WHERE ID < 2000000000
	</cfquery>
	<cfset ProductMetaOptionCatIDList = ValueList(GetProductMetaOptionCatIDs.ID)>
	<!--- Import products from old system --->
	<cfquery name="CreateProduct" datasource="#application.DS#">
		INSERT INTO #Application.database#.product
				(ID, created_user_ID, created_datetime, modified_concat, product_meta_ID, sku, sortorder, is_dropshipped, is_active, is_discontinued)
			SELECT ID, created_user_ID, created_datetime, modified_concat, product_meta_ID, sku, sortorder, is_dropshipped, is_active, is_discontinued
			FROM #Application.product_database#.product
	</cfquery>
	<cfquery name="CreateProductMetas" datasource="#application.DS#">
		INSERT INTO #Application.database#.product_meta
				(ID, created_user_ID, created_datetime, modified_concat, productvalue_master_ID, manuf_logo_ID, product_set_ID, meta_name, meta_sku,
					description, sortorder, imagename, imagename_original, thumbnailname, thumbnailname_original, productvalue)
			SELECT pm.ID, pm.created_user_ID, pm.created_datetime, pm.modified_concat, pm.productvalue_master_ID, pm.manuf_logo_ID, #ProductSetID#, pm.meta_name, pm.meta_sku,
				pm.description, pm.sortorder, pm.imagename, pm.imagename_original, pm.thumbnailname, pm.thumbnailname_original, pv.productvalue
			FROM #Application.product_database#.product_meta pm
			LEFT JOIN #Application.product_database#.productvalue_master pv ON pv.ID = pm.productvalue_master_ID
			WHERE pm.ID IN (#ProductMetaIDList#)
	</cfquery>
	<cfquery name="CreateProductMetaOptionCats" datasource="#application.DS#">
		INSERT INTO #Application.database#.product_meta_option_category
				(ID, created_user_ID, created_datetime, modified_concat, product_meta_ID, category_name, sortorder)
			SELECT ID, created_user_ID, created_datetime, modified_concat, product_meta_ID, category_name, sortorder
			FROM #Application.product_database#.product_meta_option_category
			WHERE product_meta_ID IN (#ProductMetaIDList#)
	</cfquery>
	<cfquery name="CreateProductMetaOptions" datasource="#application.DS#">
		INSERT INTO #Application.database#.product_meta_option
				(ID, created_user_ID, created_datetime, modified_concat, product_meta_option_category_ID, option_name, sortorder)
			SELECT ID, created_user_ID, created_datetime, modified_concat, product_meta_option_category_ID, option_name, sortorder
			FROM #Application.product_database#.product_meta_option
			WHERE product_meta_option_category_ID IN (#ProductMetaOptionCatIDList#)
	</cfquery>
	<cfquery name="CreateProductOptions" datasource="#application.DS#">
		INSERT INTO #Application.database#.product_option
				(ID, created_user_ID, created_datetime, modified_concat, product_ID, product_meta_option_ID)
			SELECT ID, created_user_ID, created_datetime, modified_concat, product_ID, product_meta_option_ID
			FROM #Application.product_database#.product_option
			WHERE product_ID IN (#ProductIDList#)
	</cfquery>
	<cfquery name="CreateProductMetaGroupLookups" datasource="#application.DS#">
		INSERT INTO #Application.database#.product_meta_group_lookup
				(ID, created_user_ID, created_datetime, modified_concat, product_meta_ID, product_meta_group_ID)
			SELECT ID, created_user_ID, created_datetime, modified_concat, product_meta_ID, product_meta_group_ID
			FROM #Application.product_database#.product_meta_group_lookup
			WHERE product_meta_ID IN (#ProductMetaIDList#)
	</cfquery>
	<cfquery name="CreateProductMetaGroupLookups" datasource="#application.DS#">
		INSERT INTO #Application.database#.product_meta_group
				(ID, created_user_ID, created_datetime, modified_concat, name, sortorder)
			SELECT ID, created_user_ID, created_datetime, modified_concat, name, sortorder
			FROM #Application.product_database#.product_meta_group
	</cfquery>
	<cfquery name="CreateVendor" datasource="#application.DS#">
		INSERT INTO #Application.database#.vendor
				(ID, created_user_ID, created_datetime, modified_concat, vendor, is_dropshipper, address1, address2, city, state, zip, phone, fax, email, attention, notes, what_terms, min_order)
			SELECT ID, created_user_ID, created_datetime, modified_concat, vendor, is_dropshipper, address1, address2, city, state, zip, phone, fax, email, attention, notes, what_terms, min_order
			FROM #Application.product_database#.vendor
	</cfquery>
	<cfquery name="CreateVendorLookup" datasource="#application.DS#">
		INSERT INTO #Application.database#.vendor_lookup
				(ID, created_user_ID, created_datetime, modified_concat, vendor_ID, product_ID, is_default, vendor_sku, vendor_cost, vendor_min_qty, pack_size, pack_desc, vendor_PO_note)
			SELECT ID, created_user_ID, created_datetime, modified_concat, vendor_ID, product_ID, is_default, vendor_sku, vendor_cost, vendor_min_qty, pack_size, pack_desc, vendor_PO_note
			FROM #Application.product_database#.vendor_lookup
	</cfquery>
	<cfset pgfn = "done">
</cfif>


&nbsp;&nbsp;&nbsp;&nbsp;<a href="product.cfm?set_id=1">Return to Product List</a><br><br>
<span class="pagetitle">Import Products from Awards 2</span><br><br>

<cfif pgfn EQ "start">
	<cfoutput>
	<span class="alert">This will delete all #ProductSet.set_name# in www3 and import all of the products from www2.</span><br><br>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<form action="#CurrentPage#" method="post" name="importForm">
		Check to confirm: <input type="checkbox" name="ok2continue" value="1" />
		<input type="submit" name="submit" value="   Import   " />
	</form>
	</cfoutput>
<cfelseif pgfn EQ "done">
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Done Importing!
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->
