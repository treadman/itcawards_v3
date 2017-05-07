<cfsetting requesttimeout="300">
<!--- function library --->
<cfinclude template="/cfscripts/dfm_common/function_library_form.cfm">
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<cfparam name="where_string" default="">
<cfparam name="ID" default="">
<cfparam name="datasaved" default="no">

<!--- param search criteria xS=ColumnSort xT=SearchString --->
<cfparam name="xS" default="program">
<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="this_from_date" default="">
<cfparam name="this_to_date" default="">
<cfparam name="only_unfulfilled" default="false">
<cfparam name="pgfn" default="list">

<!--- param a/e form fields --->
<cfparam name="status" default="">	
<cfparam name="x_date" default="">

<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif NOT request.is_admin>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>

	<!--- edit order information --->
	<cfif IsDefined('form.edit') AND form.edit EQ 'orderinformation'>
		<cfset this_order_note = "(*auto* edited order info) #Trim(order_note)#">
		<cfquery name="UpdateOrderInfo" datasource="#application.DS#">
			UPDATE #application.database#.order_info
			SET	snap_fname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_fname#" maxlength="30">,
				snap_lname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_lname#" maxlength="30">, 
				snap_ship_company = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_company#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_ship_company)))#">, 
				snap_ship_fname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_fname#" maxlength="30">, 
				snap_ship_lname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_lname#" maxlength="30">, 
				snap_ship_address1 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_address1#" maxlength="30">, 
				snap_ship_address2 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_address2#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_ship_address2)))#">, 
				snap_ship_city = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_city#" maxlength="30">, 
				snap_ship_state = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_state#" maxlength="10">, 
				snap_ship_zip = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_zip#" maxlength="10">, 
				snap_phone = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_phone#" maxlength="35">, 
			<cfif IsDefined('snap_bill_company') AND TRIM(snap_bill_company) NEQ "">
				snap_bill_company = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_company#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_company)))#">,  
			</cfif>
			<cfif IsDefined('snap_bill_fname') AND TRIM(snap_bill_fname) NEQ "">
				snap_bill_fname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_fname)))#">, 
			</cfif>
			<cfif IsDefined('snap_bill_lname') AND TRIM(snap_bill_lname) NEQ "">
				snap_bill_lname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_lname)))#">, 
			</cfif>
			<cfif IsDefined('snap_bill_address1') AND TRIM(snap_bill_address1) NEQ "">
				snap_bill_address1 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_address1#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_address1)))#">, 
			</cfif> 
			<cfif IsDefined('snap_bill_address2') AND TRIM(snap_bill_address2) NEQ "">
				snap_bill_address2 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_address2#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_address2)))#">,  
			</cfif>
			<cfif IsDefined('snap_bill_city') AND TRIM(snap_bill_city) NEQ "">
				snap_bill_city = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_city)))#">, 
			</cfif>
			<cfif IsDefined('snap_bill_state') AND TRIM(snap_bill_state) NEQ "">
				snap_bill_state = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_state#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_state)))#">, 
			</cfif>
			<cfif IsDefined('snap_bill_zip') AND TRIM(snap_bill_zip) NEQ "">
				snap_bill_zip = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_zip#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_zip)))#">, 
			</cfif>
				snap_email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_email#" maxlength="128">
				#FLGen_UpdateModConcatSQL(this_order_note)#
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
		</cfquery>
		<cfset datasaved = "yes">
		<cfset pgfn = "edit">
	
	<!--- edit item information --->
	<cfelseif IsDefined('form.edit') AND form.edit EQ 'editorderitem'>
		<!--- if adding quantity --->
		<cfif quantity GT original_quantity AND quantity NEQ 0>
			<!--- get user info if quantity is different from original_quantity and not zero --->
			<cfquery name="GetUserID" datasource="#application.DS#">
				SELECT created_user_ID
				FROM #application.database#.order_info
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10"> 
			</cfquery>
			<cfset ProgramUserInfo(GetUserID.created_user_ID)>
			<!--- the user has enough available credits --->
			<cfif user_totalpoints GTE ((quantity - original_quantity) * snap_productvalue)>
				<!--- update item --->
				<cfquery name="UpdateItemQuantity" datasource="#application.DS#">
					UPDATE #application.database#.inventory
					SET	quantity = <cfqueryparam cfsqltype="cf_sql_integer" value="#quantity#" maxlength="8">
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#inventory_ID#" maxlength="10">
						AND ship_date IS NULL
						AND po_ID = 0
				</cfquery>
				<!--- update snap_order_total, points_used, and note about this change --->
				<cfset add_this_amount = (quantity - original_quantity) * snap_productvalue>
				<cfset new_snap_order_total = (this_snap_order_total + add_this_amount)>
				<cfset new_points_used = (this_points_used + add_this_amount)>
				<cfset new_mod_note = "- item quantity changed from #original_quantity# to #quantity# SKU: #snap_sku# CAT: #snap_productvalue# PRODUCT: #snap_meta_name# #snap_options##Chr(13)##Chr(10)#- snap_order_total changed from #this_snap_order_total# to #new_snap_order_total##Chr(13)##Chr(10)#- points_used changed from #this_points_used# to #new_points_used#">
				<cfset datasaved = "yes">
				<cfset alert_msg = "The quantity was updated.">
				<cfset pgfn = "edititem">
			<cfelse>
				<!--- message that says they don't have enough credits available --->
				<cfset alert_error = "NOT SAVED. This user has #user_totalpoints# credits available.">
				<cfset pgfn = "edititem">
			</cfif>
		<!--- if subtracting quantity --->
		<cfelseif original_quantity GT quantity AND quantity NEQ 0>
			<!--- update item --->
			<cfquery name="UpdateItemQuantity" datasource="#application.DS#">
				UPDATE #application.database#.inventory
				SET	quantity = <cfqueryparam cfsqltype="cf_sql_integer" value="#quantity#" maxlength="8">
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#inventory_ID#" maxlength="10">
					AND ship_date IS NULL
					AND po_ID = 0
			</cfquery>
			<!--- update snap_order_total, points_used, and note about this change --->
			<cfset sub_this_amount = (original_quantity - quantity) * snap_productvalue>
			<cfset new_snap_order_total = (this_snap_order_total - sub_this_amount)>
			<cfset new_points_used = (this_points_used - sub_this_amount)>
			<cfset new_mod_note = "- item quantity changed from #original_quantity# to #quantity# SKU: #snap_sku# CAT: #snap_productvalue# PRODUCT: #snap_meta_name# #snap_options##Chr(13)##Chr(10)#- snap_order_total changed from #this_snap_order_total# to #new_snap_order_total##Chr(13)##Chr(10)#- points_used changed from #this_points_used# to #new_points_used#">
			<cfset datasaved = "yes">
			<cfset alert_msg = "The quantity was updated.">
			<cfset pgfn = "detail">
		<!--- if deleting item --->
		<cfelseif quantity EQ 0>
			<!--- delete item --->
			<cfquery name="DeleteInvItem" datasource="#application.DS#">
				DELETE FROM #application.database#.inventory
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#inventory_ID#" maxlength="10">
			</cfquery>
			<!--- update snap_order_total, points_used, and note about this change --->
			<cfset sub_this_amount = (original_quantity * snap_productvalue)>
			<cfset new_snap_order_total = (this_snap_order_total - sub_this_amount)>
			<cfset new_points_used = (this_points_used - sub_this_amount)>
			<cfset new_mod_note = "- item quantity changed from #original_quantity# to 0 (deleted) SKU: #snap_sku# CAT: #snap_productvalue# PRODUCT: #snap_meta_name# #snap_options##Chr(13)##Chr(10)#- snap_order_total changed from #this_snap_order_total# to #new_snap_order_total##Chr(13)##Chr(10)#- points_used changed from #this_points_used# to #new_points_used#">
			<cfset datasaved = "yes">
			<cfset alert_msg = "The item was deleted from the order.">
			<cfset pgfn = "detail">
		</cfif>
		
		<!--- if change was successful, update order information --->
		<cfif datasaved EQ "yes">
			<cfquery name="UpdateOrderInfo" datasource="#application.DS#">
				UPDATE #application.database#.order_info
				SET	snap_order_total = #new_snap_order_total#, 
					points_used = #new_points_used#
					#FLGen_UpdateModConcatSQL(new_mod_note)#
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			</cfquery>
		</cfif>
	
	<!--- add new item --->
	<cfelseif IsDefined('form.edit') AND form.edit EQ 'addorderitem'>
	
		<!--- get user total points --->
		<cfquery name="GetUserID" datasource="#application.DS#">
			SELECT created_user_ID, snap_order_total, points_used
			FROM #application.database#.order_info
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10"> 
		</cfquery>
		<cfset start_snap_order_total = GetUserID.snap_order_total>
		<cfset start_points_used = GetUserID.points_used>
		<cfset ProgramUserInfo(GetUserID.created_user_ID)>
		<!--- find the submitted addition --->
		<cfif IsDefined('form.FieldNames') AND Trim(#form.FieldNames#) IS NOT "">
			<cfloop List="#form.FieldNames#" Index="FormField">
				<cfif FormField CONTAINS "ADD_">
					<cfset fm_individual_ID = ListGetAt(FormField,2,"_")>
					<cfset fm_productvalue = ListGetAt(FormField,3,"_")>
				</cfif>
			</cfloop>
		</cfif>
		<!--- does the user have enough points to get this product? --->
		<cfif user_totalpoints GTE fm_productvalue>
			<!--- put the item into this order --->
			<!--- get the product's value --->
			<cfquery name="FindProdValue" datasource="#application.DS#">
				SELECT pvm.productvalue AS ThisPValue, pm.meta_name AS meta_name, pm.description AS description, p.sku AS sku, p.is_dropshipped
				FROM #application.database#.productvalue_master pvm
				JOIN #application.database#.product_meta pm ON pvm.ID = pm.productvalue_master_ID
					JOIN #application.database#.product p ON pm.ID = p.product_meta_ID
				WHERE p.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#fm_individual_ID#" maxlength="10">
			</cfquery>
			<cfset FPO_theseoptions = FindProductOptions(fm_individual_ID)>
			<!--- put item in the inventory table --->
			<cfquery name="InsertProduct" datasource="#application.DS#">
				INSERT INTO #application.database#.inventory
				(created_user_ID, created_datetime, product_ID, order_ID, quantity, snap_meta_name, snap_sku, snap_description, snap_productvalue, snap_options, snap_is_dropshipped, is_valid)
				VALUES
				(<cfqueryparam cfsqltype="cf_sql_integer" value="#GetUserID.created_user_ID#" maxlength="10">, 
					'#FLGen_DateTimeToMySQL()#', 
					<cfqueryparam cfsqltype="cf_sql_integer" value="#fm_individual_ID#" maxlength="10">, 
					<cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">, 
					1, 
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#FindProdValue.meta_name#" maxlength="64">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#FindProdValue.sku#" maxlength="64">,
					<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FindProdValue.description#">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FindProdValue.ThisPValue#" maxlength="80">,
					<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FPO_theseoptions#">,
					<cfqueryparam cfsqltype="cf_sql_tinyint" value="#FindProdValue.is_dropshipped#" maxlength="1">,
					1)
			</cfquery>
			<!--- if change was successful, update order information --->
			<cfset new_snap_order_total = (start_snap_order_total + FindProdValue.ThisPValue)>
			<cfset new_points_used = (start_points_used + FindProdValue.ThisPValue)>
			<cfset new_mod_note = "- (product added to order) QTY: 1 SKU: #FindProdValue.sku# CAT: #FindProdValue.ThisPValue# PRODUCT: #FindProdValue.meta_name# #FPO_theseoptions##Chr(13)##Chr(10)#- snap_order_total changed from #start_snap_order_total# to #new_snap_order_total##Chr(13)##Chr(10)#- points_used changed from #start_points_used# to #new_points_used#">
			<cfquery name="UpdateOrderInfo" datasource="#application.DS#">
				UPDATE #application.database#.order_info
				SET	snap_order_total = #new_snap_order_total#, 
					points_used = #new_points_used#
					#FLGen_UpdateModConcatSQL(new_mod_note)#
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			</cfquery>
			<cfset pgfn = "detail">
			<cfset alert_msg = "The product was added to the order.">
		<cfelse>
			<cfset pgfn = "additem">
			<cfset alert_error = "The user doesn't have enough points for that product.">
		</cfif>	
	</cfif>

<cfelseif pgfn EQ "deleteorder">

	<!--- make sure the order has no items in it. --->
	<cfquery name="FindOrderItems" datasource="#application.DS#">
		SELECT ID
		FROM #application.database#.inventory
		WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			AND is_valid = 1
	</cfquery>
	<cfif FindOrderItems.RecordCount GT 0>
		<cfset alertmsg = "You can not delete an order that has products in it.  Delete all the products in this order by setting their quantities to zero.">
	<cfelse>
		<!--- create the note that you are going to put in the mod concat --->
		<cfset new_mod_note = "- (Order Deleted)">
		<!--- update the order with mod concat and set to not valid --->
		<cfquery name="DeleteOrderInfo" datasource="#application.DS#">
			UPDATE #application.database#.order_info
			SET	is_valid = 0
				#FLGen_UpdateModConcatSQL(new_mod_note)#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
		</cfquery>
		<cfset pgfn = "list">
		<cfset alert_msg = "The order was deleted.">
	</cfif>

</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "orders">
<cfinclude template="includes/header.cfm">

<SCRIPT LANGUAGE="JavaScript"><!-- 
function openURL()
{ 
// grab index number of the selected option
selInd = document.pageform.pageselect.selectedIndex; 
// get value of the selected option
goURL = document.pageform.pageselect.options[selInd].value;
// redirect browser to the grabbed value (hopefully a URL)
top.location.href = goURL; 
}

function openURLAgain()
{ 
// grab index number of the selected option
selInd = document.pageform2.pageselect.selectedIndex; 
// get value of the selected option
goURL = document.pageform2.pageselect.options[selInd].value;
// redirect browser to the grabbed value (hopefully a URL)
top.location.href = goURL; 
}
//--> 
</SCRIPT>

<cfparam name="pgfn" default="list">

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">
	<!--- massage dates --->
	<cfif this_from_date NEQ "" AND IsDate(this_from_date)>
		<cfset xFD = FLGen_DateTimeToMySQL(this_from_date,'startofday')>
	</cfif>
	<cfif this_to_date NEQ "" AND IsDate(this_to_date)>
		<cfset xTD = FLGen_DateTimeToMySQL(this_to_date,'endofday')>
	</cfif>
	<cfif xFD NEQ "">
		<cfset x_date =  RemoveChars(Insert(',', Insert(',', xFD, 6),4),11,16)>
		<cfset this_from_date = ListGetAt(x_date,2) & '/' & ListGetAt(x_date,3) & '/' & ListGetAt(x_date,1)>
	</cfif>
	<cfif xTD NEQ "">
		<cfset x_date =  RemoveChars(Insert(',', Insert(',', xTD, 6),4),11,16)>
		<cfset this_to_date = ListGetAt(x_date,2) & '/' & ListGetAt(x_date,3) & '/' & ListGetAt(x_date,1)>
	</cfif>
	<!--- <cfif (only_unfulfilled OR xFD NEQ "" OR xTD NEQ "" OR xT NEQ "" OR this_from_date NEQ "" OR this_to_date NEQ "") OR CGI.REQUEST_METHOD EQ "Post"> --->
		<!--- run query --->
		<cfquery name="SelectList" datasource="#application.DS#">
			SELECT pg.company_name, pg.program_name, oi.ID AS order_ID, oi.order_number, Date_Format(oi.created_datetime,'%c/%d/%Y') AS created_date, CONCAT(oi.snap_fname,' ',oi.snap_lname) AS users_name	
			FROM #application.database#.order_info oi
			JOIN #application.database#.program pg ON oi.program_ID = pg.ID
			WHERE is_valid = 1 
			<cfif LEN(xT) GT 0>
				AND (oi.order_number LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> 
				OR oi.snap_fname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> 
				OR oi.snap_lname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">) 
			</cfif>
			<cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0>
				AND oi.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			</cfif>
			<cfif this_from_date NEQ "">
				AND oi.created_datetime >= <cfqueryparam value="#xFD#">
			</cfif>
			<cfif this_to_date NEQ "">
				AND oi.created_datetime <= <cfqueryparam value="#xTD#">
			</cfif>
			<cfif only_unfulfilled>
				AND oi.is_all_shipped = 0
			</cfif>
			ORDER BY pg.company_name, pg.program_name, oi.order_number DESC
		</cfquery>
		<!--- set the start/end/max display row numbers --->
		<cfparam name="OnPage" default="1">
		<cfset MaxRows_SelectList="50">
		<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
		<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
		<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	<!--- </cfif> --->
	
	<span class="pagetitle">Order List</span>
	<br />
	<br />
	<!--- search box --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	<tr class="contenthead">
	<td><span class="headertext">Search Criteria</span></td>
	<td align="right"><a href="<cfoutput>#CurrentPage#</cfoutput>" class="headertext">view all</a></td>
	</tr>
	<tr>
	<td class="contentsearch" colspan="2" align="center"><span class="sub">All fields are optional.  Leave unnecessary fields blank.</span></td>
	</tr>
	<tr>
	<td class="content" colspan="2" align="center">
		<cfoutput>
		<form action="#CurrentPage#" method="post">
			<table cellpadding="5" cellspacing="0" border="0" width="100%">
				<tr>
				<td align="center">
				<span class="sub">show:</span>
				<br>
				<select name="only_unfulfilled" size="2"><option value="false"#FLForm_Selected("false",only_unfulfilled," selected")#>All Orders</option><option value="true"#FLForm_Selected("true",only_unfulfilled," selected")#>Only Unfulfilled Orders</option></select>
				</td>
				<td align="right">	<span class="sub">order ## or user's name</span><br><input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20"><br><br>
					
					<span class="sub">From Date:</span> <input type="text" name="this_from_date" value="#this_from_date#" size="20" style="margin-bottom:5px"><br>
					<span class="sub">To Date:</span> <input type="text" name="this_to_date" value="#this_to_date#" size="20">
				</td>
				<td align="center">&nbsp;&nbsp;&nbsp;</td>
				<td>
					<input type="submit" name="search" value="search">
				</td>
				</tr>
			</table>
		</form>
		</cfoutput>
		<br>
	</td>
	</tr>
	</table>
	<br />
	<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0>
		<form name="pageform">
			<table cellpadding="0" cellspacing="0" border="0" width="100%">
			<tr>
			<td>
				<cfif OnPage GT 1>
					<a href="<cfoutput>#CurrentPage#?OnPage=1&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
				<cfelse>
					<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
				</cfif>
			</td>
			<td align="center" class="sub">[ page 	
				<cfoutput>
				<select name="pageselect" onChange="openURL()"> 
					<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
						<option value="#CurrentPage#?OnPage=#this_i#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
					</cfloop>
				</select>
				 of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
				</cfoutput>
			</td>
			<td align="right">
				<cfif OnPage LT TotalPages_SelectList>
					<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#</cfoutput>" class="pagingcontrols">&raquo;</a>
				<cfelse>
					<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
				</cfif>
			</td>
			</tr>
			</table>
		</form>
	</cfif>
	<!--- <cfif (only_unfulfilled OR xFD NEQ "" OR xTD NEQ "" OR xT NEQ "" OR this_from_date NEQ "" OR this_to_date NEQ "") OR CGI.REQUEST_METHOD EQ "Post"> --->
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<!--- header row --->
		<cfoutput>
		<tr class="contenthead">
		<td align="center">&nbsp;</td>
		<td><span class="headertext">Program</span> <img src="../pics/contrls-asc.gif" width="7" height="6"></td>
		<td><span class="headertext">Order Number</span></td>
		<td><span class="headertext">Date</span></td>
		<td><span class="headertext">User's Name</span></td>
		<td><span class="headertext">Status</span></td>
		</tr>
		<!--- if no records --->
		<cfif SelectList.RecordCount IS 0>
			<tr class="content2">
			<td colspan="7" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
			</tr>
		</cfif>
		</cfoutput>
		<!--- display found records --->
		<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
			<!--- determine the order's status --->
			<!--- are there products in the order?  --->
			<cfquery name="FindOrderItems" datasource="#application.DS#">
				SELECT ID
				FROM #application.database#.inventory
				WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
					AND is_valid = 1
			</cfquery>
			<cfif FindOrderItems.RecordCount NEQ 0>
				<!--- find all UNSHIPPED --->
				<cfquery name="FindUnshipped" datasource="#application.DS#">
					SELECT ID
					FROM #application.database#.inventory
					WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10"> 
						AND is_valid = 1 
						AND quantity <> 0 
						AND snap_is_dropshipped = 0 
						AND ship_date IS NULL 
						AND po_ID = 0
						AND po_rec_date IS NULL
				</cfquery>
				<!--- find all UN-DROPSHIPPED --->
				<cfquery name="FindUndropshipped" datasource="#application.DS#">
					SELECT ID
					FROM #application.database#.inventory
					WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10"> 
						AND is_valid = 1 
						AND quantity <> 0 
						AND snap_is_dropshipped = 1 
						AND ship_date IS NULL 
						AND po_ID = 0
						AND po_rec_date IS NULL
				</cfquery>
				<!--- find all UN-DROPSHIPPED --->
				<cfquery name="FindUndropshippedconf" datasource="#application.DS#">
					SELECT ID, po_ID 
					FROM #application.database#.inventory
					WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10"> 
						AND is_valid = 1 
						AND quantity <> 0 
						AND snap_is_dropshipped = 1 
						AND ship_date IS NULL 
						AND po_ID <> 0
						AND po_rec_date IS NULL
				</cfquery>
			</cfif>
			<!--- 	This is if I want the fulfilled orders to have the inactive bg color
				<tr class="<cfif FindUnshipped.RecordCount EQ 0 AND FindUndropshipped.RecordCount EQ 0>inactivebg<cfelse>#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))# </cfif>">
			 --->
			<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
			<td align="center">
				<a href="#CurrentPage#?pgfn=detail&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Detail</a>&nbsp;
				<a target="_blank" href="receipt.cfm?id=#order_ID#&t=0">Print</a>
			</td>
			<td valign="top">#HTMLEditFormat(company_name)# [#HTMLEditFormat(program_name)#]</td>
			<td valign="top">#HTMLEditFormat(order_number)#</td>
			<td valign="top">#HTMLEditFormat(created_date)#</td>
			<td valign="top">#HTMLEditFormat(users_name)#</td>
			<td valign="top"><cfif FindOrderItems.RecordCount EQ 0><span class="alert">NO PRODS</span><cfelse><cfif FindUnshipped.RecordCount NEQ 0><a href="order_ship.cfm?back=order&shipID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">ITC</a>&nbsp;&nbsp;&nbsp;</cfif><cfif FindUndropshipped.RecordCount NEQ 0><a href="report_po.cfm">DROP&nbsp;PO</a></cfif><cfif FindUndropshippedconf.RecordCount NEQ 0><a href="po_detail.cfm?pgfn=condrop&po_ID=#FindUndropshippedconf.po_ID#">DROP&nbsp;CONF</a></cfif><cfif FindUnshipped.RecordCount EQ 0 AND FindUndropshipped.RecordCount EQ 0 AND FindUndropshippedconf.RecordCount EQ 0><span class="sub">(fulfilled)</span></cfif></cfif></td>
			</tr>
		</cfoutput>
		</table>
		<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0>
			<form name="pageform2">
			<table cellpadding="0" cellspacing="0" border="0" width="100%">
			<tr>
			<td>
				<cfif OnPage GT 1>
					<a href="<cfoutput>#CurrentPage#?OnPage=1&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
				<cfelse>
					<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
				</cfif>
			</td>
			<td align="center" class="sub">[ page 	
				<cfoutput>
				<select name="pageselect" onChange="openURLAgain()"> 
					<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
						<option value="#CurrentPage#?OnPage=#this_i#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
					</cfloop>
				</select>
				 of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
				</cfoutput>
			</td>
			<td align="right">
				<cfif OnPage LT TotalPages_SelectList>
					<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#</cfoutput>" class="pagingcontrols">&raquo;</a>
				<cfelse>
					<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
				</cfif>
			</td>
			</tr>
			</table>
			</form>
		<!--- </cfif> --->
	<cfelse>
		Use the search criteria to find orders.
	</cfif>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "detail">
	<!--- START pgfn DETAIL --->

	<!--- ********************************* --->
	<!---  getting the cart display info    --->
	<!--- ********************************* --->
	<!--- get order info --->
	<cfquery name="FindOrderInfo" datasource="#application.DS#">
		SELECT ID AS order_ID, program_ID, order_number, snap_order_total, points_used,
			credit_multiplier, points_multiplier,cost_center_charge,
			credit_card_charge, snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname,
			snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip,
			snap_phone, snap_email, snap_bill_company, snap_bill_fname, snap_bill_lname,
			snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip,
			order_note, modified_concat, x_tran_ID, Date_Format(created_datetime,'%c/%d/%Y') AS created_date,
			shipping_charge, snap_signature_charge, shipping_desc, shipping_location_ID, shipper_corrected_address
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			AND is_valid = 1
	</cfquery>
	<cfset order_ID = FindOrderInfo.order_ID>
	<cfset program_ID = FindOrderInfo.program_ID>
	<cfset order_number = HTMLEditFormat(FindOrderInfo.order_number)>
	<cfset snap_order_total = HTMLEditFormat(FindOrderInfo.snap_order_total)>
	<cfset points_used = HTMLEditFormat(FindOrderInfo.points_used)>
	<cfset credit_multiplier = HTMLEditFormat(FindOrderInfo.credit_multiplier)>
	<cfset points_multiplier = HTMLEditFormat(FindOrderInfo.points_multiplier)>
	<cfset credit_card_charge = HTMLEditFormat(FindOrderInfo.credit_card_charge)>
	<cfset cost_center_charge = HTMLEditFormat(FindOrderInfo.cost_center_charge)>
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
	<cfset x_tran_ID = HTMLEditFormat(FindOrderInfo.x_tran_ID)>
	<cfset created_date = HTMLEditFormat(FindOrderInfo.created_date)>
	<cfset shipping_charge = FindOrderInfo.shipping_charge>
	<cfset snap_signature_charge = FindOrderInfo.snap_signature_charge>
	<cfset shipping_desc = FindOrderInfo.shipping_desc>
	<cfset shipping_location_ID = FindOrderInfo.shipping_location_ID>
	<cfset shipper_corrected_address = FindOrderInfo.shipper_corrected_address>

	<cfif shipping_location_ID GT 0>
		<cfquery name="GetSelectedShippingLocation" datasource="#application.DS#">
			SELECT location_name, company, attention, address1, address2, city, state, zip, phone
			FROM #application.database#.shipping_locations
			WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#FindOrderInfo.program_ID#" maxlength="10">
			AND ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#shipping_location_ID#" maxlength="10">
		</cfquery>
		<cfif GetSelectedShippingLocation.recordcount eq 0>
			<cfset shipping_location_ID = 0>
		</cfif>
	</cfif>

	<!--- get program information --->
	<cfquery name="FindProgramInfo" datasource="#application.DS#">
		SELECT company_name, program_name, is_one_item, credit_desc
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#FindOrderInfo.program_ID#" maxlength="10">
	</cfquery>
	<cfset company_name = htmleditformat(FindProgramInfo.company_name)>
	<cfset program_name = htmleditformat(FindProgramInfo.program_name)>
	<cfset is_one_item = htmleditformat(FindProgramInfo.is_one_item)>
	<cfset credit_desc = htmleditformat(FindProgramInfo.credit_desc)>

	<!--- find order items --->
	<cfquery name="FindOrderItems" datasource="#application.DS#">
		SELECT ID AS inventory_ID, snap_sku, snap_meta_name, snap_description, snap_productvalue, quantity, snap_options, snap_is_dropshipped, CAST(IFNULL(ship_date,"") AS CHAR) AS ship_date, CAST(IFNULL(drop_date,"") AS CHAR) AS drop_date, po_ID, po_rec_date 
		FROM #application.database#.inventory
		WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			AND is_valid = 1
	</cfquery>
 
	<span class="pagetitle">Order Detail<cfif x_tran_ID EQ "TEST TRANS ID"><span class="alert"> - TEST CREDIT CARD - DO NOT PROCESS</span></cfif></span>
	<br /><br />

	<cfoutput>

	<span class="pageinstructions">Return to <a href="#CurrentPage#?xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Order List</a> without making changes.</span>
	<br /><br />
	<!--- <span class="pageinstructions">Open <a href="order_detail_printable?order_ID=#order_ID#">printable order</a>.</span>
	<br /><br />
	 --->	
	<table cellpadding="3" cellspacing="1" border="0" width="100%">

	<tr>
	<td colspan="2" class="content2"><b>Award Program:</b> <span class="selecteditem">#company_name# [#program_name#]</span><cfif is_one_item GT 0> <span class="sub">(this is a #is_one_item#-item program)</span></cfif></td>
	</tr>
			
	<tr>
	<td colspan="2" class="contenthead"><cfif x_tran_ID EQ "TEST TRANS ID"><span class="alert"></cfif><b>Order #order_number#</b> on #created_date# for #snap_fname# #snap_lname# (#snap_email#)<cfif x_tran_ID EQ "TEST TRANS ID"></span></cfif></td>
	</tr>
			
	<tr>
	<td colspan="2" class="content2"><a href="#CurrentPage#?pgfn=edit&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Edit Order Information</a></td>
	</tr>
			
	<tr class="contenthead">
	<td>Shipping Information</td>
	<td><cfif snap_bill_fname NEQ "">Billing Information<cfelse>&nbsp;</cfif></td>
	</tr>
	
	<tr class="content">
	<td>

	<cfif shipping_location_ID GT 0>
		<cfif GetSelectedShippingLocation.company NEQ "">#GetSelectedShippingLocation.company#<br></cfif>
	<cfelse>
		<cfif snap_ship_company NEQ "">#snap_ship_company#<br></cfif>
	</cfif>
	<cfif shipping_location_ID GT 0>Order for: </cfif><cfif snap_ship_fname NEQ "">#snap_ship_fname#</cfif> <cfif snap_ship_lname NEQ "">#snap_ship_lname#</cfif><br>
	<cfif snap_ship_address1 NEQ "">#snap_ship_address1#<br></cfif>
	<cfif snap_ship_address2 NEQ "">#snap_ship_address2#<br></cfif>
	<cfif snap_ship_city NEQ "">#snap_ship_city#</cfif>, <cfif snap_ship_state NEQ "">#snap_ship_state#</cfif> <cfif snap_ship_zip NEQ "">#snap_ship_zip#</cfif><br><br>
	<cfif shipper_corrected_address neq "">
		FEDEX CORRECTED:<br>
		#shipper_corrected_address#<br><br>
	</cfif>
	<cfif shipping_location_ID GT 0 AND GetSelectedShippingLocation.attention NEQ "">ATTN: #GetSelectedShippingLocation.attention#<cfif GetSelectedShippingLocation.phone NEQ ""> -  #GetSelectedShippingLocation.phone#</cfif><br></cfif>
	<cfif snap_phone NEQ "">Phone: #snap_phone#</cfif><br>
	<cfif shipping_desc NEQ "">Ship via #shipping_desc#: #shipping_charge#<br></cfif>
	<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#<br></cfif>
	</td>
	<td valign="top">
	<cfif snap_bill_fname NEQ "">
	<cfif snap_bill_company NEQ "">#snap_bill_company#<br></cfif>
	<cfif snap_bill_fname NEQ "">#snap_bill_fname#</cfif> <cfif snap_bill_lname NEQ "">#snap_bill_lname#</cfif><br>
	<cfif snap_bill_address1 NEQ "">#snap_bill_address1#<br></cfif>
	<cfif snap_bill_address2 NEQ "">#snap_bill_address2#<br></cfif>
	<cfif snap_bill_city NEQ "">#snap_bill_city#</cfif>, <cfif snap_bill_state NEQ "">#snap_bill_state#</cfif> <cfif snap_bill_zip NEQ "">#snap_bill_zip#</cfif><br>
	<cfelse>&nbsp;</cfif>
	</td>
	</tr>
	
	<tr>
	<td colspan="2" class="contenthead">Order Note</td>
	</tr>

	<tr>
	<td colspan="2" class="content"><cfif order_note NEQ "">#Replace(HTMLEditFormat(order_note),chr(10),"<br>","ALL")#<cfelse><span class="sub">(none)</span></cfif></td>
	</tr>

	<tr class="contenthead">
	<td colspan="2" class="contenthead">Order Modification History </td>
	</tr>

	<tr class="content">
	<td colspan="2"><cfif TRIM(modified_concat) NEQ "">#FLGen_DisplayModConcat(modified_concat)#<cfelse><span class="sub">(none)</span></cfif></td>
	</tr>

	</table>
	<br><br>
	
	<cfif FindOrderItems.RecordCount EQ 0>
		There are no products in this order. <a href="#CurrentPage#?pgfn=deleteorder&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#" onclick="return confirm('Are you sure you want to delete this order?  There is NO UNDO.')">Delete this order.</a>
		<br /><br />
		<a href="#CurrentPage#?pgfn=additem&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Add a product to this order.</a>
	<cfelse>
		<table cellpadding="3" cellspacing="1" border="0" width="100%">
			<cfif credit_card_charge NEQ "" AND credit_card_charge NEQ 0 AND x_tran_ID EQ "">
			<tr>
			<td align="center" colspan="7"><span class="alert">Credit card may not have actually been charged!!!</span></td>
			</tr>
			</cfif>
		<tr class="contenthead">
		<td><a href="#CurrentPage#?pgfn=additem&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Add</a></td>
		<td><b>SKU</b></td>
		<td width="100%"><b>Description</b></td>
		<td><b>Status</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
		<td align="center"><b>Qty</b></td>
		<cfif is_one_item EQ 0>
			<td colspan="2" align="center"><b>#credit_desc#</b></td>
		</cfif>
		</tr>
		<cfset carttotal = 0>
	 	<cfloop query="FindOrderItems">
			<tr class="content">
			<td><a href="#CurrentPage#?pgfn=edititem&inventory_ID=#inventory_ID#&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Edit</a></td>
			<td>#snap_sku#</td>
			<td>#snap_meta_name#<cfif snap_options NEQ ""><br>#snap_options#</cfif></td>
			<td>
				<cfif snap_is_dropshipped EQ 1>
					<cfif drop_date EQ "">
						not dropshipped yet
					<cfelse>
						DROP PO #po_ID-1000000000#<br>
						sent #FLGen_DateTimeToDisplay(drop_date)#
						<cfif po_rec_date NEQ "">
							<br>conf #FLGen_DateTimeToDisplay(po_rec_date)#
						<cfelse>
							<br><a href="po_detail.cfm?pgfn=condrop&po_ID=#po_ID#">confirm drop</a>
						</cfif>
					</cfif>
				<cfelse>
					<cfif ship_date EQ "">
						not shipped yet
					<cfelse>
						shipped #FLGen_DateTimeToDisplay(ship_date)#
					</cfif>
				</cfif>
			</td>
			<td align="center" nowrap>#quantity#</td>
			<cfif is_one_item EQ 0>
			<td nowrap align="right">#snap_productvalue# <span class="sub">each</span></td>
			<td align="right">#snap_productvalue*quantity#</td>
			</cfif>
			</tr>
			<cfif is_one_item EQ 0>
				<cfset carttotal = carttotal + (snap_productvalue * quantity)>
			</cfif>
		</cfloop>
		<cfif is_one_item EQ 0>
			<tr>
			<td align="right" colspan="6"><b>Order Total:</b> </td>
			<td align="right" class="content"><b>#carttotal#</b></td>
			</tr>
		
			<tr>
			<td align="right" colspan="7"><img src="../pics/shim.gif" width="10" height="1"></td>
			</tr>
			<cfif points_used GT 0>
			<tr>
			<td align="right" colspan="6">
				<cfif credit_multiplier NEQ 1 AND credit_multiplier NEQ points_multiplier>
					(Multiplier: #credit_multiplier# - User paid #points_used*credit_multiplier#)
				</cfif>
			<b>Points Used:</b>
			</td>
			<td align="right" class="content"><b>#points_used#</b></td>
			</tr>
			</cfif>
			<cfif snap_signature_charge GT 0>
			<tr>
			<td align="right" colspan="6">
			<b>Signature Required Charge:</b>
			</td>
			<td align="right" class="content"><b>#snap_signature_charge#</b></td>
			</tr>
			</cfif>
			<cfif shipping_charge GT 0>
			<tr>
			<td align="right" colspan="6">
			<b>Shipping Charge:</b>
			</td>
			<td align="right" class="content"><b>#shipping_charge#</b></td>
			</tr>
			</cfif>
			<tr>
			<td align="right" colspan="6"> <b>Credit Card <cfif x_tran_ID NEQ "">Transaction: <cfif x_tran_ID EQ "TEST TRANS ID"><span class="alert"></cfif>#x_tran_ID#<cfif x_tran_ID EQ "TEST TRANS ID"></span></cfif><cfelse>Charge</cfif>:</b> </td>
			<td align="right" class="content"><cfif credit_card_charge NEQ "" AND credit_card_charge NEQ 0><b>#credit_card_charge#</b><cfelse><span class="sub">none</span></cfif></td>
			</tr>
			<cfif cost_center_charge NEQ "" AND cost_center_charge NEQ 0>
			<tr>
			<td align="right" colspan="6"> <b>Charged to Cost Center:</b> </td>
			<td align="right" class="content">#cost_center_charge#</b></td>
			</tr>
			</cfif>
		
		</cfif>
		</table>
	</cfif>
	</cfoutput>
	<!--- END pgfn DETAIL --->
<cfelseif pgfn EQ "edit">
	<!--- START pgfn EDIT --->
	<cfquery name="FindOrderInfo" datasource="#application.DS#">
		SELECT ID AS order_ID, program_ID, order_number, snap_order_total, points_used, credit_card_charge, snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email, snap_bill_company, snap_bill_fname, snap_bill_lname, snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip, order_note, modified_concat
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			AND is_valid = 1
	</cfquery>
	<cfset order_ID = FindOrderInfo.order_ID>
	<cfset program_ID = FindOrderInfo.program_ID>
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
	
	<cfoutput>
	<span class="pagetitle">Edit An Order</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Order #order_number# Detail</a> or <a href="#CurrentPage#?xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Order List</a> without making changes.</span>
	<br /><br />
	<span class="pageinstructions"><span class="alert">WARNING</span>: Changes only effect this order.  This page does not change the user's</span>
	<br />
	<span class="pageinstructions">information in their Program User record.</span>
	<br /><br />

	<cfif datasaved eq 'yes'>
		<span class="alert">#Application.DefaultSaveMessage#</span>
		<br /><br />
	</cfif>
	
	<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr>
	<td colspan="2" class="content2"><b>Award Program:</b> <span class="selecteditem">#GetProgramName(FindOrderInfo.program_ID)#</span></td>
	</tr>

	<tr class="contenthead">
	<td colspan="2" class="headertext">Order Information</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Order Number: </td>
	<td valign="top">#order_number#</td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Program User's Name: </td>
	<td valign="top">
		<input type="text" name="snap_fname" value="#snap_fname#" maxlength="30" size="20">&nbsp;&nbsp;
		<input type="text" name="snap_lname" value="#snap_lname#" maxlength="30" size="20">
	</td>
	</tr>
	
	<tr class="contenthead">
	<td colspan="2" class="headertext">Shipping Information</td>
	</tr>

	<tr class="content">
	<td align="right">Company&nbsp;</td>
	<td><input type="text" size="60" maxlength="60" name="snap_ship_company" value="#snap_ship_company#"></td>
	</tr>
	
	<tr class="content">
	<td align="right"><b>First&nbsp;Name</b>&nbsp;</td>
	<td><input type="text" size="60" maxlength="60" name="snap_ship_fname" value="#snap_ship_fname#">
	<input type="hidden" name="snap_ship_fname_required" value="Please enter a first name for shipping."></td>
	</tr>
		
	<tr class="content">
	<td align="right"><b>Last&nbsp;Name</b>&nbsp;</td>
	<td><input type="text" size="60" maxlength="60" name="snap_ship_lname" value="#snap_ship_lname#">
	<input type="hidden" name="snap_ship_lname_required" value="Please enter a last name for shipping."></td>
	</tr>
		
	<tr class="content">
	<td align="right"><b>Address&nbsp;Line&nbsp;1</b>&nbsp;</td>
	<td><input type="text" size="60" maxlength="60" name="snap_ship_address1" value="#snap_ship_address1#">
	<input type="hidden" name="snap_ship_address1_required" value="Please enter address information for shipping."></td>
	</tr>
	
	<tr class="content">
	<td align="right">Address&nbsp;Line&nbsp;2&nbsp;</td>
	<td><input type="text" size="60" maxlength="60" name="snap_ship_address2" value="#snap_ship_address2#"></td>
	</tr>
	
	<tr class="content">
	<td align="right"><b>City</b> </td>
	<td valign="top"><input type="text" name="snap_ship_city" value="#snap_ship_city#" maxlength="60" size="60">
	<input type="hidden" name="snap_ship_city_required" value="Please enter a city for shipping."></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top"><b>State</b> </td>
	<td valign="top"><cfoutput>#FLGen_SelectState("snap_ship_state","#snap_ship_state#","true")#</cfoutput> <span class="sub">(select last option if international)</span></td>
	</tr>
	
	<tr class="content">
	<td align="right"><b>Zip Code</b> </td>
	<td valign="top"><input type="text" name="snap_ship_zip" value="#snap_ship_zip#" maxlength="10" size="60">
	<input type="hidden" name="snap_ship_zip_required" value="Please enter a zip code for shipping."></td>
	</tr>
	
	<tr class="content">
	<td align="right"><b>Phone</b> </td>
	<td><input type="text" size="60" maxlength="35" name="snap_phone" value="#snap_phone#">
	<input type="hidden" name="snap_phone_required" value="Please enter a daytime phone number."></td>
	</tr>
		
	<tr class="content">
	<td align="right"><b>Email</b> </td>
	<td><input type="text" size="60" maxlength="128" name="snap_email" value="#snap_email#">
	<input type="hidden" name="snap_email_required" value="Please enter an email."></td>
	</tr>
	
	<!--- only if there is a balance due --->
	<!--- only if there is a balance due --->
	<!--- only if there is a balance due --->
	
	<cfif credit_card_charge NEQ "">
		
		<tr class="contenthead">
		<td class="headertext" colspan="2">Billing Information</td>
		</tr>
		
		<tr class="content">
		<td align="right">Company&nbsp;</td>
		<td><input type="text" size="60" maxlength="60" name="snap_bill_company" value="#snap_bill_company#"></td>
		</tr>
		
		<tr class="content">
		<td align="right">First&nbsp;Name&nbsp;</td>
		<td><input type="text" size="60" maxlength="60" name="snap_bill_fname" value="#snap_bill_fname#"></td>
		</tr>
			
		<tr class="content">
		<td align="right">Last&nbsp;Name&nbsp;</td>
		<td><input type="text" size="60" maxlength="60" name="snap_bill_lname" value="#snap_bill_lname#"></td>
		</tr>
			
		<tr class="content">
		<td align="right">Address&nbsp;Line&nbsp;1&nbsp;</td>
		<td><input type="text" size="60" maxlength="60" name="snap_bill_address1" value="#snap_bill_address1#"></td>
		</tr>
		
		<tr class="content">
		<td align="right">Address&nbsp;Line&nbsp;2&nbsp;</td>
		<td><input type="text" size="60" maxlength="60" name="snap_bill_address2" value="#snap_bill_address2#"></td>
		</tr>
		
		<tr class="content">
		<td align="right">City </td>
		<td valign="top"><input type="text" name="snap_bill_city" value="#snap_bill_city#" maxlength="60" size="60"></td>
		</tr>
		
		<tr class="content">
		<td align="right" valign="top">State </td>
		<td valign="top"><cfoutput>#FLGen_SelectState("snap_bill_state","#snap_bill_state#","true")#</cfoutput> <span class="sub">(select last option if international)</span></td>
		</tr>
		
		<tr class="content">
		<td align="right">Zip </td>
		<td valign="top"><input type="text" name="snap_bill_zip" value="#snap_bill_zip#" maxlength="10" size="60"></td>
		</tr>
		
	</cfif>

	<tr class="contenthead">
	<td class="headertext" colspan="2">Order Note </td>
	</tr>
	
	<tr class="content">
	<td valign="top" colspan="2"><cfif order_note NEQ "">#Replace(HTMLEditFormat(order_note),chr(10),"<br>","ALL")#<cfelse><span class="sub">(none)</span></cfif></td>
	</tr>
	
	<tr class="contenthead">
	<td colspan="2" class="headertext">Required Edit Note&nbsp;&nbsp;&nbsp;<span class="sub" style="font-weight:normal">(Please explain why you are editing the order information.)</span></td>
	</tr>
	
	<tr class="content">
	<td align="right">&nbsp;</td>
	<td valign="top"><textarea name="order_note" cols="58" rows="4"></textarea>
	<input type="hidden" name="order_note_required" value="Please enter a note explaining why you are editing this order's information."></td>
	</tr>
	
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="edit" value="orderinformation">
	<input type="hidden" name="xFD" value="#xFD#">
	<input type="hidden" name="order_ID" value="#order_ID#">
	<input type="hidden" name="xTD" value="#xTD#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	<input type="hidden" name="ID" value="#ID#">
			
	<input type="submit" name="submit" value="   Save Changes   " >

	</td>
	</tr>
	
	<cfif modified_concat NEQ "">
		<tr>
		<td colspan="4">&nbsp;</td>
		</tr>
		
		<tr class="contenthead">
		<td colspan="4" class="headertext">Order Modification History </td>
		</tr>
	
		<tr class="content">
		<td colspan="4">#FLGen_DisplayModConcat(modified_concat)#</td>
		</tr>
	</cfif>
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn EDIT --->
<cfelseif pgfn EQ "additem">
	<!--- START pgfn ADD ITEM --->
	<!--- get user's total available points --->
	<cfquery name="GetUserID" datasource="#application.DS#">
		SELECT created_user_ID
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10"> 
	</cfquery>
	<cfset ProgramUserInfo(GetUserID.created_user_ID)>
	
	<cfquery name="FindOrderInfo" datasource="#application.DS#">
		SELECT order_number
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
	</cfquery>
	<cfset order_number = HTMLEditFormat(FindOrderInfo.order_number)>
	
	<!--- Find all indv products --->
	<cfquery name="AllProductList" datasource="#application.DS#">
		SELECT 	meta.meta_name, prod.sku, pval.productvalue, prod.ID AS individual_ID, 
				IF((SELECT COUNT(*) FROM #application.database#.product_meta_option_category pm WHERE meta.ID = pm.product_meta_ID)=0,"false","true") AS has_options
		FROM #application.database#.product_meta meta
		JOIN #application.database#.product prod ON prod.product_meta_ID = meta.ID 
			JOIN #application.database#.productvalue_master pval ON pval.ID = meta.productvalue_master_ID
		WHERE prod.is_active = 1 AND prod.is_discontinued = 0 
		ORDER BY pval.sortorder, meta.sortorder, prod.sortorder
	</cfquery>

	<cfoutput>
	<span class="pagetitle">Add Order Item</span>
	<br /><br />
	
	<span class="pageinstructions">This user has <span class="selecteditem">#user_totalpoints#</span> points available.</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Order #order_number# Detail</a> or <a href="#CurrentPage#?xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Order List</a> without making changes.</span>
	<br /><br />
	</cfoutput>
	
	<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0">
	
	<cfoutput query="AllProductList" group="productvalue">
	
		<tr class="contenthead">
		<td colspan="3" class="headertext">Master Category #productvalue#</td>
		</tr>

		<cfoutput>
		<cfif has_options>
			<cfquery name="FindProductOptionInfo" datasource="#application.DS#">
				SELECT pmoc.category_name AS category_name, pmo.option_name AS option_name
				FROM #application.database#.product_meta_option_category pmoc
				JOIN #application.database#.product_meta_option pmo ON pmoc.ID = pmo.product_meta_option_category_ID 
				JOIN  #application.database#.product_option po ON pmo.ID = po.product_meta_option_ID
				WHERE po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#individual_ID#" maxlength="10"> 
				ORDER BY pmoc.sortorder
			</cfquery>
			<cfset optioncount = FindProductOptionInfo.RecordCount>
		<cfelse>
			<cfset optioncount = 0>
		</cfif>
	
		<tr class="content">
		<td><input type="submit" name="add_#individual_ID#_#productvalue#" value="Add To Order" ></td>
		<td>SKU: #sku#</td>
		<td>#meta_name#<cfif optioncount NEQ 0><cfloop query="FindProductOptionInfo"> [#category_name#: #option_name#] </cfloop></cfif></td>
		</tr>
		</cfoutput>
		
	<tr>
	<td colspan="3">&nbsp;</td>
	</tr>
	
	</cfoutput>
	<cfoutput>
	
	<input type="hidden" name="submit" value="submit">
	<input type="hidden" name="edit" value="addorderitem">
	<input type="hidden" name="order_ID" value="#order_ID#">

	<input type="hidden" name="xFD" value="#xFD#">
	<input type="hidden" name="xTD" value="#xTD#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	</cfoutput>
	
	</table>
	
	</form>
	
	<!--- END pgfn ADD ITEM --->
<cfelseif pgfn EQ "edititem">
	<!--- START pgfn EDIT ITEM --->

	<!--- find order item information --->
	<cfquery name="FindOrderItem" datasource="#application.DS#">
		SELECT snap_sku, snap_meta_name, snap_productvalue, quantity, snap_options, note AS inv_note, product_ID
		FROM #application.database#.inventory
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#inventory_ID#" maxlength="10">
			AND is_valid = 1
	</cfquery>
	<cfset snap_sku = HTMLEditFormat(FindOrderItem.snap_sku)>
	<cfset snap_meta_name = HTMLEditFormat(FindOrderItem.snap_meta_name)>
	<cfset snap_productvalue = HTMLEditFormat(FindOrderItem.snap_productvalue)>
	<cfset quantity = FindOrderItem.quantity>
	<cfset snap_options = HTMLEditFormat(FindOrderItem.snap_options)>
	<cfset inv_note = HTMLEditFormat(FindOrderItem.inv_note)>
		
	<cfquery name="FindOrderInfo" datasource="#application.DS#">
		SELECT order_number, snap_order_total, points_used
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
	</cfquery>
	<cfset order_number = HTMLEditFormat(FindOrderInfo.order_number)>
	<cfset snap_order_total = HTMLEditFormat(FindOrderInfo.snap_order_total)>
	<cfset points_used = HTMLEditFormat(FindOrderInfo.points_used)>
	<cfoutput>

	<span class="pagetitle">Edit Order Item</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Order #order_number# Detail</a> or <a href="#CurrentPage#?xT=#xT#&xTD=#xTD#&xFD=#xFD#&only_unfulfilled=#only_unfulfilled#&OnPage=#OnPage#">Order List</a> without making changes.</span>
	<br /><br />

	<cfif FindOrderItem.RecordCount EQ 1>

	<cfquery name="GetProduct" datasource="#application.DS#">
		SELECT 	meta.meta_name, prod.sku, pval.productvalue, prod.ID AS individual_ID, 
				IF((SELECT COUNT(*) FROM #application.database#.product_meta_option_category pm WHERE meta.ID = pm.product_meta_ID)=0,"false","true") AS has_options
		FROM #application.database#.product_meta meta
		JOIN #application.database#.product prod ON prod.product_meta_ID = meta.ID 
			JOIN #application.database#.productvalue_master pval ON pval.ID = meta.productvalue_master_ID
		WHERE prod.is_active = 1 AND prod.is_discontinued = 0
		AND prod.ID = #FindOrderItem.product_ID#
	</cfquery>
<cfset show_opts = false>
<cfif GetProduct.recordcount EQ 1 AND GetProduct.has_options EQ "true">
	<cfset show_opts = true>
</cfif>
<cfif show_opts>
			<cfquery name="FindProductOptionInfo" datasource="#application.DS#">
				SELECT pmoc.category_name AS category_name, pmo.option_name AS option_name
				FROM #application.database#.product_meta_option_category pmoc
				JOIN #application.database#.product_meta_option pmo ON pmoc.ID = pmo.product_meta_option_category_ID 
				JOIN #application.database#.product_option po ON pmo.ID = po.product_meta_option_ID
				WHERE po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#FindOrderItem.product_ID#" maxlength="10"> 
				ORDER BY pmoc.sortorder
			</cfquery>
<cfif show_opts><cfloop query="FindProductOptionInfo"> [#category_name#: #option_name#] </cfloop></cfif>
</cfif>
		<form method="post" action="#CurrentPage#">
	
		<table cellpadding="5" cellspacing="1" border="0">
		
		<tr class="contenthead">
		<td colspan="4" class="headertext">Edit Order Item</td>
		</tr>
	
		<tr class="content">
		<td><b>CAT:</b> #snap_productvalue#</td>
		<td><b>SKU:</b> #snap_sku#</td>
		<td><b>Description:</b> #snap_meta_name#<cfif snap_options NEQ ""><br>#snap_options#</cfif></td>
		<td><b>Quantity:</b> <input type="text" size="10" maxlength="8" name="quantity" value="#quantity#"></td>
		</tr>
		
		<tr class="content">
		<td colspan="4" align="center">
		
		<input type="hidden" name="edit" value="editorderitem">
		<input type="hidden" name="original_quantity" value="#quantity#">
		<input type="hidden" name="snap_sku" value="#snap_sku#">
		<input type="hidden" name="snap_meta_name" value="#snap_meta_name#">
		<input type="hidden" name="snap_options" value="#snap_options#">
		<input type="hidden" name="snap_productvalue" value="#snap_productvalue#">
		<input type="hidden" name="this_snap_order_total" value="#NumberFormat(snap_order_total,'_')#">
		<input type="hidden" name="this_points_used" value="#points_used#">
		<input type="hidden" name="xFD" value="#xFD#">
		<input type="hidden" name="order_ID" value="#order_ID#">
		<input type="hidden" name="inventory_ID" value="#inventory_ID#">
		<input type="hidden" name="xTD" value="#xTD#">
		<input type="hidden" name="xT" value="#xT#">
		<input type="hidden" name="OnPage" value="#OnPage#">

		<input type="submit" name="submit" value="   Save Changes  " >
	
		</td>
		</tr>
			
		</table>
		</form>
	</cfif>
	</cfoutput>
	<!--- END pgfn EDIT ITEM --->
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->