<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000013,true)>

<cfparam name="where_string" default="">
<cfparam name="meta_ID" default="">

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfinclude template="includes/header_lite.cfm">

<!--- display the inventory adjustment history --->

<cfoutput>

<cfquery name="GetInvHistory" datasource="#application.DS#">

	<!--- orders --->
	SELECT inv.created_datetime, inv.quantity, inv.note, (SELECT CONCAT(up.fname,' ',up.lname) FROM #application.database#.program_user up WHERE up.ID = inv.created_user_ID) AS persons_name, (SELECT CONCAT('Order ## ',CAST(oi.order_number AS CHAR),' from ',pg.company_name,' [',pg.program_name,']') FROM #application.database#.order_info oi JOIN #application.database#.program pg ON oi.program_ID = pg.ID WHERE oi.ID = inv.order_ID) AS ref_activity, IF(inv.ship_date IS NULL,'not shipped yet',CONCAT('shipped on ',CAST(Date_Format(inv.ship_date,'%c/%d/%Y') AS CHAR))) AS ref_happen, 'ord' AS activity
	FROM #application.database#.inventory inv
	WHERE inv.product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#product_ID#" maxlength="10"> 
		AND inv.is_valid = 1 
		AND inv.quantity <> 0 
		AND inv.snap_is_dropshipped = 0 
		AND inv.order_ID <> 0
		AND ship_date IS NULL
		AND inv.po_ID = 0 
		AND inv.po_rec_date IS NULL
	ORDER BY created_datetime
	
</cfquery>


<table cellpadding="5" cellspacing="1" border="0" width="80%" align="center">

	<!--- find product name --->
	<cfquery name="FindProductInfo" datasource="#application.DS#">
		SELECT m.meta_name, m.meta_sku 
		FROM #application.database#.product_meta m
		JOIN #application.database#.product p ON p.product_meta_ID = m.ID
		WHERE p.ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#product_ID#" maxlength="10">
	</cfquery>

	<!--- find product's options --->
	<cfquery name="FindProductOptionInfo" datasource="#application.DS#">
		SELECT pmoc.category_name AS category_name, pmo.option_name AS option_name
		FROM #application.database#.product_meta_option_category pmoc, #application.database#.product_meta_option pmo, #application.database#.product_option po
		WHERE pmo.ID = po.product_meta_option_ID AND po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#product_ID#" maxlength="10"> AND pmoc.ID = pmo.product_meta_option_category_ID
		ORDER BY pmoc.sortorder
	</cfquery>
	
<tr>
<td colspan="4"><span class="pagetitle">Unshipped<br>Product: #FindProductInfo.meta_name# #FindProductOptions(product_ID)#</span>
<br /><br />
If the number needed doesn't match the number of products listed here, there might be<br>an unfulfilled PO. Check the <a href="inventory.cfm?&xS=name&xL=&xT=<cfoutput>#FindProductInfo.meta_sku#</cfoutput>&xW=1&OnPage=1">inventory</a> page for more details.<br><br>

</td>
</tr>

<tr class="contenthead">
<td class="headertext">Date</td>
<td class="headertext">Quantity</td>
<td class="headertext">Activity</td>
<td class="headertext">note</td>
</tr>

<cfloop query="GetInvHistory">
<tr class="content">
<td>#FLGen_DateTimeToDisplay(created_datetime)#</td>
<td align="right"><cfif activity EQ 'ord'>-<cfelseif activity EQ 'pos'>+<cfelseif activity EQ 'man' AND quantity GT 0>+</cfif>#quantity#</td>
<td>#ref_activity# <cfif persons_name NEQ "">by #persons_name# </cfif><cfif ref_happen NEQ "">(#ref_happen#)</cfif></td>
<td><cfif note NEQ ''>note: #note#</cfif></td>
</tr>
</cfloop>
		
</table>

</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->
