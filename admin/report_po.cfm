<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<cfparam name="set_ID" default="">
<cfif isNumeric(set_ID) AND set_ID GT 0>
	<cfquery name="ProductSet" datasource="#application.DS#">
		SELECT ID, set_name, note, sortorder
		FROM #application.database#.product_set
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#set_ID#" maxlength="10">
	</cfquery>
	<cfif ProductSet.recordcount NEQ 1>
		<cfset set_ID = 0>
	</cfif>
</cfif>

<cfset has_set = isNumeric(set_ID) AND set_ID GT 0>

<cfif has_set>


<!--- ************************************ --->
<!--- get report info                      --->
<!--- ************************************ --->

<cfset list_prodvir = "">
<cfset list_prod = "">

<!--- find all the dropship items that aren't dropshipped yet --->
<cfquery name="SelectDistinctDropProducts" datasource="#application.DS#">
	SELECT DISTINCT product_ID
	FROM #application.database#.inventory
	WHERE is_valid = 1 
	AND product_ID IN (SELECT ID FROM #application.database#.product WHERE product_meta_ID IN (SELECT ID FROM #application.database#.product_meta WHERE product_set_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#set_ID#" maxlength="10">))
		<!--- AND quantity <> 0 --->
		AND snap_is_dropshipped = 1 
		<!--- AND order_ID <> 0 ---> 
		<!--- AND ship_date IS NULL ---> 
		AND po_ID = 0 
		<!--- AND po_rec_date IS NULL ---> 
</cfquery>

<!--- loop through the list and calc the total ordered --->
<cfloop query="SelectDistinctDropProducts">

	<cfset thisDropProduct = SelectDistinctDropProducts.product_ID>
	
	<!--- find the undropped items --->
	<cfquery name="SumOfDropProd" datasource="#application.DS#">
		SELECT SUM(quantity) AS DropOrdered
		FROM #application.database#.inventory
		WHERE is_valid = 1 
			AND quantity <> 0 
			AND snap_is_dropshipped = 1 
			AND order_ID <> 0 
			AND ship_date IS NULL 
			AND po_ID = 0 
			AND po_rec_date IS NULL
			AND product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisDropProduct#" maxlength="10">
	</cfquery>

	<!--- add to to the prod list --->
	<cfset list_prodvir = list_prodvir & ",prod" & thisDropProduct & "_vir" & SumOfDropProd.DropOrdered & "_d">
	<cfset list_prod = list_prod & "," & thisDropProduct>
</cfloop>

<!--- find all the product that haven't been shipped yet --->
<cfquery name="SelectDistinctProducts" datasource="#application.DS#">
	SELECT DISTINCT product_ID
	FROM #application.database#.inventory
	WHERE is_valid = 1 
	AND product_ID IN (SELECT ID FROM #application.database#.product WHERE product_meta_ID IN (SELECT ID FROM #application.database#.product_meta WHERE product_set_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#set_ID#" maxlength="10">))
		AND snap_is_dropshipped = 0 
		AND order_ID <> 0 
		AND ship_date IS NULL 
		AND po_ID = 0 
		AND po_rec_date IS NULL
</cfquery>

<!--- loop through the list and calc the virtual inventory --->
<cfloop query="SelectDistinctProducts">
	<cfset thisDistinctProduct = SelectDistinctProducts.product_ID>
	<cfset PhysicalInvCalc(thisDistinctProduct)>
	
	<!--- if the virtual inventory is LT 0, add to productID_virtualInventory list --->
	<cfif PIC_total_virtual LT 0>
		<cfset list_prodvir = list_prodvir & ",prod" & thisDistinctProduct & "_vir" & Abs(PIC_total_virtual) & "_s">
		<cfset list_prod = list_prod & "," & thisDistinctProduct>
	</cfif>
</cfloop>

<!--- take off the first comma --->
<cfif list_prodvir NEQ "">
	<cfset list_prodvir = RemoveChars(list_prodvir,1,1)>
	<cfset list_prod = RemoveChars(list_prod,1,1)>
	
	<!--- list out the vendors, and if they have items in the above set of records, list the items --->
	<cfquery name="FindVendors" datasource="#application.DS#">
		SELECT DISTINCT vl.vendor_ID AS vendor_ID, v.vendor, IF(v.is_dropshipper=0,"false","true") AS is_dropshipper 
		FROM #application.database#.vendor_lookup vl
		JOIN #application.database#.vendor v ON vl.vendor_ID = v.ID  
		WHERE vl.product_ID IN (#list_prod#)
		ORDER BY vendor ASC 
	</cfquery>

<cfelse>
	<cfset alert_error = "There are no products in #ProductSet.set_name# that need purchase orders.">
</cfif>

</cfif>
		
<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "po_builder">
<cfinclude template="includes/header.cfm">

<cfif NOT has_set>
	<cfquery name="GetSets" datasource="#application.DS#">
		SELECT ID, set_name, note
		FROM #application.database#.product_set
		ORDER BY sortorder
	</cfquery>
<cfelse>
	<span class="pageinstructions">Product Set: <strong><cfoutput>#ProductSet.set_name#</cfoutput></strong></span>
	&nbsp;&nbsp;&nbsp;&nbsp;
	<a href="<cfoutput>#CurrentPage#</cfoutput>">Return to Set List</a>
</cfif>
<br><br>


<cfif NOT has_set>
	<cfoutput>
	<span class="pagetitle">Build Purchase by Product Set</span>
	<br /><br />
	<table cellpadding="5" cellspacing="0" border="0" width="80%">
		<tr class="contenthead">
			<td width="18%" class="headertext"></td>
			<td width="36%" class="headertext">Set Name</td>
			<td width="46%" class="headertext">Description</td>
		</tr>
		<cfloop query="GetSets">
			<tr class="#Iif(((GetSets.CurrentRow MOD 2) is 1),de('content2'),de('content'))#">
				<td nowrap="nowrap"><a href="#CurrentPage#?set_ID=#GetSets.ID#">Build PO</a></td>
				<td>#GetSets.set_name#</td>
				<td>#GetSets.note#</td>
			</tr>
		</cfloop>
		<tr class="contenthead" height="5px;"><td colspan="100%"></td></tr>
	</table>
	</cfoutput>
<cfelse>

<span class="pagetitle">Potential Purchase Orders</span>
<br /><br />

<cfif list_prodvir NEQ "">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<cfoutput>
	
	<!--- loop through the found vendors --->
	<cfloop query="FindVendors">
		<cfset vendor = FindVendors.vendor>
		<cfset vendor_ID = FindVendors.vendor_ID>
	
	<tr class="contenthead">
	<td align="center"><a href="<cfif FindVendors.is_dropshipper>po_builder_drop.cfm<cfelse>po_builder_ship.cfm</cfif>?vendor_ID=#vendor_ID#&set_ID=#set_ID#">Build&nbsp;PO</a></td>
	<td class="headertext" colspan="6">#vendor#</td>
	</tr>
		
		<!--- find all the products assigned to this vendor that need to be POd (check list_prod) --->
		<cfquery name="FindVendorProds" datasource="#application.DS#">
			SELECT pm.meta_name, p.sku, pv.productvalue, p.ID AS product_ID
			FROM #application.database#.product_meta pm
			JOIN #application.database#.product p ON p.product_meta_ID = pm.ID
			JOIN #application.database#.productvalue_master pv ON pm.productvalue_master_ID = pv.ID 
			JOIN #application.database#.vendor_lookup vl ON vl.product_ID = p.ID
			WHERE vl.product_ID IN (#list_prod#)
				AND vl.vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#" maxlength="10">
		</cfquery>
		
		<cfloop query="FindVendorProds">
		
			<cfset FPO_theseoptions = FindProductOptions(product_ID)>
					
			<!--- if the product has multi vendors, indicate this, somehow --->
			<cfquery name="HasMultiVendors" datasource="#application.DS#">
				SELECT ID 
				FROM #application.database#.vendor_lookup 
				WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#FindVendorProds.product_ID#" maxlength="10">
			</cfquery>
			
			<!--- if this product has multiple vendors, find out if this one is default or alternative vendor --->
			<cfif HasMultiVendors.RecordCount GT 1>
				<cfquery name="CheckIf" datasource="#application.DS#">
					SELECT IF(is_default=1, "true", "false") AS is_default  
					FROM #application.database#.vendor_lookup 
					WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#FindVendorProds.product_ID#" maxlength="10"> 
						AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#" maxlength="10">				
				</cfquery>
			</cfif>
			
			<!--- find the quantity and if drop or ship
			find in list_prod and then listgetat(list_prod_vir) same index --->
			<cfset this_prod_index = ListFind(list_prod,#FindVendorProds.product_ID#)>
			<cfset this_prod_info = ListGetAt(list_prodvir,#this_prod_index#)>
			<cfset this_prod_qty = RemoveChars(ListGetAt(this_prod_info,2,"_"),1,3)>
			<cfset this_prod_dORs = ListGetAt(this_prod_info,3,"_")>

	<tr <cfif HasMultiVendors.RecordCount GT 1><cfif CheckIf.is_default>class="selectedbgcolor"<cfelse>class="inactivebg"</cfif><cfelse>class="content"</cfif>>
	<td bgcolor="##FFFFFF">&nbsp;</td>
	<td><cfif HasMultiVendors.RecordCount GT 1><cfif CheckIf.is_default><span class="selecteditem">default</span><cfelse><span class="sub">alternate</span></cfif><cfelse>&nbsp;</cfif></td>
	<td>[#productvalue#]</td>
	<td><cfif this_prod_dORs EQ "d">DROP<cfelseif this_prod_dORs EQ "s">ITC</cfif></td>
	<td>
		<b>QTY: #this_prod_qty#</b><cfif this_prod_dORs EQ "s"> <a href="unshipped.cfm?product_ID=#product_ID#" target="_blank">view&nbsp;list</a></cfif><br>
		<b>#meta_name#</b> #FPO_theseoptions#<br>
		ITC SKU: #sku#</td>
	</tr>
		
		</cfloop>

	</cfloop>
	
	</cfoutput>
			
	</table>

</cfif>
</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->