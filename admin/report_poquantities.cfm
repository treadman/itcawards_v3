<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000038,true)>

<cfparam name="vendor_ID" default="">
<cfparam name="FromDate" default="">
<cfparam name="ToDate" default="">
<cfparam name="formatFromDate" default="">
<cfparam name="formatToDate" default="">
<cfparam name="sort" default="sku">

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "poquantities">
<cfinclude template="includes/header.cfm">

<cfset vendor_name = "">
<cfif isNumeric(vendor_ID)>
	<cfquery name="VendorName" datasource="#application.DS#">
		SELECT vendor
		FROM #application.database#.vendor
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#">
	</cfquery>
	<cfset vendor_name = VendorName.vendor>
</cfif>

<cfoutput>
<span class="pagetitle">PO Quantity Report<cfif vendor_name NEQ ""> for #vendor_name#</cfif></span>
<br /><br />
<span class="pageinstructions">Leave the dates blank to see PO quantities for all time.</span>
<br /><br />
<form action="#CurrentPage#" method="post">
	<!--- search box (START) --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
		<tr class="contenthead">
			<td colspan="3"><span class="headertext">Generate PO Quantity Report</span></td>
		</tr>
		<tr>
			<td class="content" align="center" rowspan="2">
				#SelectVendor(vendor_ID,"For All Vendors")#<br><br>
				sort by: <select name="sort">
					<option value="sku"<cfif sort EQ "sku"> selected</cfif>>ITC SKU</option>
					<option value="name"<cfif sort EQ "name"> selected</cfif>>Product Name</option>
					<option value="name"<cfif sort EQ "vendor"> selected</cfif>>Vendor</option>
				</select>
			</td>
			<td class="content" align="right">From Date: </td>
			<td class="content" align="left"><input type="text" name="FromDate" value="#FromDate#" size="12"></td>
		</tr>
		<tr>
			<td class="content" align="right">To Date:</td>
			<td class="content" align="left"><input type="text" name="ToDate" value="#ToDate#" size="12"></td>
		</tr>
		<tr class="content">
			<td colspan="3" align="center"><input type="submit" name="submit" value="Generate Report"></td>
		</tr>
	</table>
</form>
<!--- search box (END) --->
</cfoutput>
<br /><br />
	
<!--- **************** --->
<!--- if survey report --->
<!--- **************** --->
	
<cfif IsDefined('form.submit')>
	<cfif FromDate NEQ "">
		<cfset formatFromDate = FLGen_DateTimeToMySQL(FromDate)>
	</cfif>	
	<cfif ToDate NEQ "">
		<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
	</cfif>	
	<cfquery name="getProducts" datasource="#application.DS#">
		SELECT inv.product_ID, inv.snap_meta_name, inv.snap_options, inv.snap_sku, inv.quantity,
			inv.po_quantity, inv.snap_vendor, po.vendor_ID, inv.snap_is_dropshipped,
			SUM(po_quantity) AS total_po_qty, SUM(quantity) AS total_qty
		FROM #application.database#.inventory inv JOIN #application.database#.purchase_order po ON inv.po_ID = po.ID
		WHERE inv.is_valid = 1
		AND inv.po_ID <> 0
		<cfif formatFromDate NEQ "">
			AND inv.created_datetime >= '#formatFromDate#' 
		</cfif>	
		<cfif formatToDate NEQ "">
			AND inv.created_datetime <= '#formatToDate#' 
		</cfif>	
		<cfif vendor_ID NEQ "">
			AND po.vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#vendor_ID#" maxlength="10"> 
		</cfif>
		GROUP BY inv.snap_meta_name, inv.snap_sku
		ORDER BY <cfif sort EQ "sku">inv.snap_sku<cfelseif sort EQ "name">inv.snap_meta_name<cfelseif sort EQ "vendor">po.vendor_ID</cfif> ASC 
	</cfquery>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<!--- header row --->
		<tr class="content2">
			<td colspan="5"><span class="headertext">Vendor: <span class="selecteditem"><cfif vendor_name NEQ ""><cfoutput>#vendor_name#</cfoutput><cfelse>All Vendors</cfif></span></span></td>
		</tr>
		<tr valign="top" class="contenthead">
			<td valign="top" class="headertext">ITC&nbsp;SKU<cfif sort EQ "sku">&nbsp;<img src="../pics/contrls-desc.gif"></cfif></td>
			<td valign="top" class="headertext">Vendor</td>
			<td valign="top" class="headertext" align="center"><span class="tooltip" title="Quantity Ordered">?</span></td>
			<td valign="top" class="headertext" align="center"><span class="tooltip" title="Quantity Received">?</span></td>
			<td valign="top" class="headertext">Product Name<cfif sort EQ "name">&nbsp;<img src="../pics/contrls-desc.gif"></cfif></td>
		</tr>
		<cfif getProducts.RecordCount EQ 0>
			<tr class="content2">
				<td colspan="5" align="center" class="alert"><br>There are no results to display.<br><br></td>
			</tr>
		<cfelse>
			<cfoutput query="getProducts">
				<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
					<td valign="top">#snap_sku#</td>
					<td valign="top">#snap_vendor#</td>
					<td valign="top" align="right"><cfif NOT snap_is_dropshipped>#total_po_qty#<cfelse>#total_qty#</cfif></td>
					<td valign="top" align="right"><span class="sub">[#total_qty#]</span></td>
					<td valign="top">#snap_meta_name# #snap_options#</td>
				</tr>
			</cfoutput>
		</cfif>
	</table>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->