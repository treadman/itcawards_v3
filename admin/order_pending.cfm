<!--- function library --->
<cfinclude template="/cfscripts/dfm_common/function_library_form.cfm">
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000115,true)>

<cfparam name="where_string" default="">
<cfparam name="ID" default="">
<cfparam name="datasaved" default="no">

<!--- param search criteria xS=ColumnSort xT=SearchString --->
<cfparam name="xS" default="program">
<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="xOF" default="Pending">
<cfparam name="this_from_date" default="">
<cfparam name="this_to_date" default="">
<cfparam name="pgfn" default="list">
<cfparam name="order_number" default="">

<!--- param a/e form fields --->
<cfparam name="status" default="">	
<cfparam name="x_date" default="">

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
<cfelse>
	<cfquery name="ProgramInfo" datasource="#application.DS#">
		SELECT company_name, orders_from, has_address_verification 
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
	</cfquery>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif has_program>
<cfif IsDefined('form.Submit')>

	<!--- edit order information --->
	<cfif IsDefined('form.edit') AND form.edit EQ 'orderinformation'>
		<cfset this_order_note = Trim(order_note)>
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

		<!--- Send email to user --->
		<cfif application.OverrideEmail NEQ "">
			<cfset this_to = application.OverrideEmail>
		<cfelse>
			<cfset this_to = snap_email>
		</cfif>
		<cfmail to="#this_to#" from="#ProgramInfo.orders_from#" subject="Update to your #ProgramInfo.company_name# Award Program order" failto="#Application.OrdersFailTo#">
			<cfif application.OverrideEmail NEQ "">
				Emails are being overridden.<br>
				Below is the email that would have been sent to #snap_email#<br>
				<hr>
			</cfif>
#DateFormat(Now(),"mm/dd/yyyy")#

Order #order_number# for #snap_fname# #snap_lname#

Your order contact information was modified:
#this_order_note#

SHIPPING ADDRESS:
#snap_ship_fname# #snap_ship_lname##CHR(10)#
#snap_ship_address1##CHR(10)#
<cfif Trim(snap_ship_address2) NEQ "">#snap_ship_address2##CHR(10)#</cfif>
#snap_ship_city#, #snap_ship_state# #snap_ship_zip#

PHONE: #snap_phone#
EMAIL: #snap_email#
</cfmail>

	
	<!--- edit item information --->
	<cfelseif IsDefined('form.edit') AND form.edit EQ 'editorderitem'>
		<!--- if adding quantity --->
		<cfif quantity GT original_quantity AND quantity NEQ 0>
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
					#FLGen_UpdateModConcatSQL(new_mod_note)#
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			</cfquery>
			<!--- Send email to user --->
			<cfquery name="GetUser" datasource="#application.DS#">
				SELECT created_user_ID, snap_email
				FROM #application.database#.order_info
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10"> 
			</cfquery>
			<cfif application.OverrideEmail NEQ "">
				<cfset this_to = application.OverrideEmail>
			<cfelse>
				<cfset this_to = GetUser.snap_email>
			</cfif>
			<cfmail to="#this_to#" from="#ProgramInfo.orders_from#" subject="Update to your #ProgramInfo.company_name# Award Program order" failto="#Application.OrdersFailTo#">
				<cfif application.OverrideEmail NEQ "">
					Emails are being overridden.<br>
					Below is the email that would have been sent to #GetUser.snap_email#<br>
					<hr>
				</cfif>
#DateFormat(Now(),"mm/dd/yyyy")#

Order #order_number# for #snap_fname# #snap_lname#

Line item change #new_mod_note#

</cfmail>

		</cfif>
	</cfif>

</cfif>

</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "pending">
<cfinclude template="includes/header.cfm">

<SCRIPT LANGUAGE="JavaScript"><!--

<cfif isdefined("url.sentit")>
	alert('Email sent');
</cfif> 
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

<cfif NOT has_program>
	<span class="pagetitle">Pending Orders</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

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
	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT pg.company_name, pg.program_name, oi.ID AS order_ID, oi.order_number,
				oi.cost_center_code, oi.approval, oi.cost_center_ID, <cfif NOT ProgramInfo.has_address_verification>c.number,</cfif> 
				Date_Format(oi.created_datetime,'%c/%d/%Y') AS created_date,
				CONCAT(oi.snap_fname,' ',oi.snap_lname) AS users_name,oi.snap_email
		FROM #application.database#.order_info oi
		INNER JOIN #application.database#.program pg ON oi.program_ID = pg.ID
		<cfif NOT ProgramInfo.has_address_verification>
			LEFT JOIN #application.database#.cost_centers c on c.ID = oi.cost_center_ID
		</cfif>
		WHERE oi.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		AND (
			oi.cost_center_ID > 0
			<cfif ProgramInfo.has_address_verification>
				OR oi.approval = 1
			</cfif>
			)
		<cfif xOF NEQ "All">
			AND is_valid = <cfif xOF EQ "Approved">1<cfelse>0</cfif>
			AND approval
			<cfswitch expression="#xOF#">
				<cfcase value="Pending"> IN (1,2)</cfcase>
				<cfcase value="Rejected">= 9</cfcase>
				<cfcase value="Approved">= 3</cfcase>
				<cfdefaultcase>>=0</cfdefaultcase>
			</cfswitch>
		</cfif>
		<cfif LEN(xT) GT 0>
			AND (oi.order_number LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> 
			OR oi.snap_fname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> 
			OR oi.snap_lname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">) 
		</cfif>
		<cfif this_from_date NEQ "">
			AND oi.created_datetime >= <cfqueryparam value="#xFD#">
		</cfif>
		<cfif this_to_date NEQ "">
			AND oi.created_datetime <= <cfqueryparam value="#xTD#">
		</cfif>
		ORDER BY pg.company_name, pg.program_name, oi.order_number DESC
	</cfquery>
	<!--- set the start/end/max display row numbers --->
	<cfparam name="OnPage" default="1">
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	
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
					<select name="xOF" size="4">
						<option value="Pending" <cfif xOF EQ "Pending"> selected</cfif>>Pending Orders</option>
						<option value="Rejected" <cfif xOF EQ "Rejected"> selected</cfif>>Declined Orders</option>
						<option value="Approved" <cfif xOF EQ "Approved"> selected</cfif>>Approved Orders</option>
						<option value="All" <cfif xOF EQ "All"> selected</cfif>>All Orders</option>
					</select>
				</td>
				<td align="right">	<span class="sub">order ## or user's name</span><br><input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20"><br><br>
					<span class="sub">From Date:</span> <input type="text" name="this_from_date" value="#this_from_date#" size="20" style="margin-bottom:5px"><br>
					<span class="sub">To Date:</span> <input type="text" name="this_to_date" value="#this_to_date#" size="20">
				</td>
				<td align="center">&nbsp;&nbsp;&nbsp;</td>
				<td>
					<input type="submit" name="search" value="  Search  ">
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
	<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0 AND TotalPages_SelectList GT 1>
		<form name="pageform">
			<table cellpadding="0" cellspacing="0" border="0" width="100%">
			<tr>
			<td>
				<cfif OnPage GT 1>
					<a href="<cfoutput>#CurrentPage#?OnPage=1&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
				<cfelse>
					<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
				</cfif>
			</td>
			<td align="center" class="sub">[ page 	
				<cfoutput>
				<select name="pageselect" onChange="openURL()"> 
					<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
						<option value="#CurrentPage#?OnPage=#this_i#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
					</cfloop>
				</select>
				 of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
				</cfoutput>
			</td>
			<td align="right">
				<cfif OnPage LT TotalPages_SelectList>
					<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#</cfoutput>" class="pagingcontrols">&raquo;</a>
				<cfelse>
					<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
				</cfif>
			</td>
			</tr>
			</table>
		</form>
	</cfif>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<!--- header row --->
	<cfoutput>
	<tr class="contenthead">
	<!---<td class="headertext">Program</td>--->
	<td class="headertext">Order ##</td>
	<td class="headertext">Date</td>
	<td class="headertext">User</td>
	<td class="headertext">Approval</td>
	<cfif NOT ProgramInfo.has_address_verification>
		<td class="headertext">Approver</td>
		<td class="headertext">Cost Center</td>
	</cfif>
	</tr>
	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="100%" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
		</tr>
	</cfif>
	</cfoutput>
	<!--- display found records --->
	<cfset CostCenters = StructNew()>
	<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
		<cfset approvers = "">
		<cfset email_list = "">
		<cfset email_cc_list = "">
		<cfif not StructKeyExists(CostCenters,cost_center_ID)>
			<cfif approval EQ 1>
				<cfquery name="GetLevel1" datasource="#application.DS#">
					SELECT a.admin_user_ID, u.firstname, u.lastname, u.email, u.email_cc, c.number, c.description,
						CONCAT(u.firstname,' ',u.lastname) AS approver
					FROM #application.database#.xref_cost_center_approvers a
					INNER JOIN #application.database#.admin_users u ON u.ID = a.admin_user_ID
					INNER JOIN #application.database#.cost_centers c ON c.ID = a.cost_center_ID
					WHERE a.cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
					AND a.level = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="1" maxlength="1">
				</cfquery>
				<cfif GetLevel1.recordcount gt 0>
					<cfloop query="GetLevel1">
						<cfquery name="GetCostCenterUser" datasource="#application.DS#">
							SELECT ID
							FROM #application.database#.cost_center_user
							WHERE mgr_email = <cfqueryparam cfsqltype="varchar" value="#GetLevel1.email#" >
							AND email = <cfqueryparam cfsqltype="varchar" value="#SelectList.snap_email#" >
						</cfquery>
						<cfif GetCostCenterUser.recordCount GT 0>
							<cfset approvers = ListAppend(approvers,GetLevel1.approver)>
							<cfset email_list = ListAppend(email_list,GetLevel1.email)>
							<cfset email_cc_list = ListAppend(email_cc_list,GetLevel1.email_cc&" ")>
						</cfif>
					</cfloop>
				</cfif>
			<cfelseif approval EQ 2>
				<cfquery name="GetLevel2" datasource="#application.DS#">
					SELECT a.admin_user_ID, u.firstname, u.lastname, u.email, u.email_cc, c.number, c.description,
						CONCAT(u.firstname,' ',u.lastname) AS approver
					FROM #application.database#.xref_cost_center_approvers a
					INNER JOIN #application.database#.admin_users u ON u.ID = a.admin_user_ID
					INNER JOIN #application.database#.cost_centers c ON c.ID = a.cost_center_ID
					WHERE a.cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
					AND a.level = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="2" maxlength="1">
				</cfquery>
				<cfif GetLevel2.recordcount gt 0>
					<cfloop query="GetLevel2">
						<cfquery name="GetCostCenterUser" datasource="#application.DS#">
							SELECT ID
							FROM #application.database#.cost_center_user
							WHERE mc_email = <cfqueryparam cfsqltype="varchar" value="#GetLevel2.email#" >
							AND email = <cfqueryparam cfsqltype="varchar" value="#SelectList.snap_email#" >
						</cfquery>
						<cfif GetCostCenterUser.recordCount GT 0>
							<cfset approvers = ListAppend(approvers,GetLevel2.approver)>
							<cfset email_list = ListAppend(email_list,GetLevel2.email)>
							<cfset email_cc_list = ListAppend(email_cc_list,GetLevel2.email_cc&" ")>
						</cfif>
					</cfloop>
				</cfif>
			</cfif>
		</cfif>
		<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
		<!---<td valign="top">#HTMLEditFormat(company_name)#</td>--->
		<td valign="top">#HTMLEditFormat(order_number)#</td>
		<td valign="top">#HTMLEditFormat(created_date)#</td>
		<td valign="top">#HTMLEditFormat(users_name)#</td>
		<td valign="top">
			<cfif ProgramInfo.has_address_verification>
				<a href="order_approve.cfm?o=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">
					Verify Address
				</a>
			<cfelse>
				<a href="order_approve.cfm?o=#cost_center_code#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">
					<cfif approval eq 9>Declined<cfelseif approval eq 3>Approved<cfelse>Level #approval#</cfif>
				</a>
			</cfif>
		</td>
		<cfif NOT ProgramInfo.has_address_verification>
			<td valign="top">
				<!---#HTMLEditFormat(number)#<cfif ListFind("1,2",approval)> #CostCenters[cost_center_ID][approval]#<cfelse><br><br></cfif>--->
				<cfif approvers EQ "">
					<span class="alert">No approvers!</span>
				<cfelse>
					<cfloop from="1" to="#ListLen(approvers)#" index="n">
						<a href="order_approve_resend.cfm?o=#cost_center_code#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#&email=#ListGetAt(email_list,n)#&email_cc=#trim(ListGetAt(email_cc_list,n))#&order_ID=#order_ID#&approver=#ListGetAt(approvers,n)#&cc_number=#number#">#ListGetAt(approvers,n)#</a><br>
					</cfloop>
				</cfif>
			</td>
			<td valign="top">#number#</td>
		</cfif>
		</tr>
	</cfoutput>
	</table>
	<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0 AND TotalPages_SelectList GT 1>
		<form name="pageform2">
		<table cellpadding="0" cellspacing="0" border="0" width="100%">
		<tr>
		<td>
			<cfif OnPage GT 1>
				<a href="<cfoutput>#CurrentPage#?OnPage=1&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
			<cfelse>
				<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
			</cfif>
		</td>
		<td align="center" class="sub">[ page 	
			<cfoutput>
			<select name="pageselect" onChange="openURLAgain()"> 
				<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
					<option value="#CurrentPage#?OnPage=#this_i#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
				</cfloop>
			</select>
			 of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
			</cfoutput>
		</td>
		<td align="right">
			<cfif OnPage LT TotalPages_SelectList>
				<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xT=#xT#&xTD=#xTD#&xOF=#xOF#</cfoutput>" class="pagingcontrols">&raquo;</a>
			<cfelse>
				<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
			</cfif>
		</td>
		</tr>
		</table>
		</form>
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
			credit_multiplier, points_multiplier,
			credit_card_charge, cost_center_charge, snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname,
			snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip,
			snap_phone, snap_email, snap_bill_company, snap_bill_fname, snap_bill_lname,
			snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip,
			order_note, modified_concat, Date_Format(created_datetime,'%c/%d/%Y') AS created_date,
			shipping_charge, snap_signature_charge, shipping_desc, shipping_location_ID
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			AND is_valid = 0 AND approval BETWEEN 1 AND 2
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
	<cfset created_date = HTMLEditFormat(FindOrderInfo.created_date)>
	<cfset shipping_charge = FindOrderInfo.shipping_charge>
	<cfset snap_signature_charge = FindOrderInfo.snap_signature_charge>
	<cfset shipping_desc = FindOrderInfo.shipping_desc>
	<cfset shipping_location_ID = FindOrderInfo.shipping_location_ID>

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
		SELECT ID AS inventory_ID, snap_sku, snap_meta_name, snap_description, snap_productvalue, quantity, snap_options, snap_is_dropshipped, CAST(IFNULL(ship_date,"") AS CHAR) AS ship_date, IFNULL(drop_date,"") AS drop_date, po_ID, po_rec_date 
		FROM #application.database#.inventory
		WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
	</cfquery>
 
	<span class="pagetitle">Order Detail</span>
	<br /><br />

	<cfoutput>

	<span class="pageinstructions">Return to <a href="#CurrentPage#?xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">Order List</a> without making changes.</span>
	<br /><br />
	<!--- <span class="pageinstructions">Open <a href="order_detail_printable?order_ID=#order_ID#">printable order</a>.</span>
	<br /><br />
	 --->	
	<table cellpadding="3" cellspacing="1" border="0" width="100%">

	<tr>
	<td colspan="2" class="content2"><b>Award Program:</b> <span class="selecteditem">#company_name# [#program_name#]</span><cfif is_one_item GT 0> <span class="sub">(this is a #is_one_item#-item store)</span></cfif></td>
	</tr>
			
	<tr>
	<td colspan="2" class="contenthead"><b>Order #order_number#</b> on #created_date# for #snap_fname# #snap_lname# (#snap_email#)</td>
	</tr>
			
	<tr>
	<td colspan="2" class="content2"><a href="#CurrentPage#?pgfn=edit&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">Edit Order Information</a></td>
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
	<cfif snap_ship_city NEQ "">#snap_ship_city#</cfif>, <cfif snap_ship_state NEQ "">#snap_ship_state#</cfif> <cfif snap_ship_zip NEQ "">#snap_ship_zip#</cfif><br>
	<cfif shipping_location_ID GT 0 AND GetSelectedShippingLocation.attention NEQ "">ATTN: #GetSelectedShippingLocation.attention#<cfif GetSelectedShippingLocation.phone NEQ ""> -  #GetSelectedShippingLocation.phone#</cfif><br></cfif>
	<cfif snap_phone NEQ "">Phone: #snap_phone#</cfif><br>
	<cfif shipping_desc NEQ "">Ship via #shipping_desc#: #shipping_charge#</cfif>
	<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#</cfif>
	</td>
	<td>
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
		There are no products in this order.
	<cfelse>
		<table cellpadding="3" cellspacing="1" border="0" width="100%">
		<tr class="contenthead">
		<td></td>
		<td><b>SKU</b></td>
		<td width="100%"><b>Description</b></td>
		<td align="center"><b>Qty</b></td>
		<cfif is_one_item EQ 0>
			<td colspan="2" align="center"><b>#credit_desc#</b></td>
		</cfif>
		</tr>
		<cfset carttotal = 0>
	 	<cfloop query="FindOrderItems">
			<tr class="content">
			<td><a href="#CurrentPage#?pgfn=edititem&inventory_ID=#inventory_ID#&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">Edit</a></td>
			<td>#snap_sku#</td>
			<td>#snap_meta_name#<cfif snap_options NEQ ""><br>#snap_options#</cfif></td>
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
			<td align="right" colspan="5"><b>Order Total:</b> </td>
			<td align="right" class="content"><b>#carttotal#</b></td>
			</tr>
		
			<!---<tr>
			<td align="right" colspan="7"><img src="../pics/shim.gif" width="10" height="1"></td>
			</tr>
			
			<tr>
			<td align="right" colspan="6">
				<cfif credit_multiplier NEQ 1 AND credit_multiplier NEQ points_multiplier>
					(Multiplier: #credit_multiplier# - User paid #points_used*credit_multiplier#)
				</cfif>
			<b>Points Used:</b>
			</td>
			<td align="right" class="content"><b>#points_used#</b></td>
			</tr>--->
			
			<tr>
			<td align="right" colspan="5"> <b>Charge to Credit Card:</b> </td>
			<td align="right" class="content"><b>#NumberFormat(credit_card_charge,'_.__')#</b></td>
			</tr>
			<tr>
			<td align="right" colspan="5"> <b>Charge to Cost Center:</b> </td>
			<td align="right" class="content"><b>#NumberFormat(cost_center_charge,'_.__')#</b></td>
			</tr>
		
		</cfif>
		</table>
	</cfif>
	</cfoutput>
	<!--- END pgfn DETAIL --->
<cfelseif pgfn EQ "edit">
	<!--- START pgfn EDIT --->
	<cfquery name="FindOrderInfo" datasource="#application.DS#">
		SELECT ID AS order_ID, program_ID, order_number, snap_order_total, points_used, credit_card_charge, cost_center_charge, 
			snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2,
			snap_ship_city, snap_ship_state, snap_ship_zip, snap_phone, snap_email, snap_bill_company, snap_bill_fname, snap_bill_lname,
			snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip, order_note, modified_concat
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			AND is_valid = 0 AND approval BETWEEN 1 AND 2
	</cfquery>
	<cfset order_ID = FindOrderInfo.order_ID>
	<cfset program_ID = FindOrderInfo.program_ID>
	<cfset order_number = HTMLEditFormat(FindOrderInfo.order_number)>
	<cfset snap_order_total = HTMLEditFormat(FindOrderInfo.snap_order_total)>
	<cfset points_used = HTMLEditFormat(FindOrderInfo.points_used)>
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
	
	<cfoutput>
	<span class="pagetitle">Edit An Order</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">Order #order_number# Detail</a> or <a href="#CurrentPage#?xT=#xT#&xTD=#xTD#&xFD=#xOF#&xFD=#xOF#&OnPage=#OnPage#">Order List</a> without making changes.</span>
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
	
	<tr class="contenthead">
	<td class="headertext" colspan="2">Order Note </td>
	</tr>
	
	<tr class="content">
	<td valign="top" colspan="2"><cfif order_note NEQ "">#Replace(HTMLEditFormat(order_note),chr(10),"<br>","ALL")#<cfelse><span class="sub">(none)</span></cfif></td>
	</tr>
	
	<tr class="contenthead">
	<td colspan="2" class="headertext">Required Edit Note&nbsp;&nbsp;&nbsp;<span class="sub" style="font-weight:normal"><br>Please explain what and why you are editing the order information.<br>This note will be sent to the above email address.</span></td>
	</tr>
	
	<tr class="content">
	<td align="right">&nbsp;</td>
	<td valign="top"><textarea name="order_note" cols="58" rows="4"></textarea>
	<input type="hidden" name="order_note_required" value="Please enter a note explaining why you are editing this order's information."></td>
	</tr>
	
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="edit" value="orderinformation">
	<input type="hidden" name="xOF" value="#xOF#">
	<input type="hidden" name="xFD" value="#xFD#">
	<input type="hidden" name="order_ID" value="#order_ID#">
	<input type="hidden" name="xTD" value="#xTD#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	<input type="hidden" name="order_number" value="#order_number#">
	
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
<cfelseif pgfn EQ "edititem">
	<!--- START pgfn EDIT ITEM --->

	<!--- find order item information --->
	<cfquery name="FindOrderItem" datasource="#application.DS#">
		SELECT snap_sku, snap_meta_name, snap_productvalue, quantity, snap_options, note AS inv_note, product_ID
		FROM #application.database#.inventory
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#inventory_ID#" maxlength="10">
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
	<span class="pageinstructions">Return to <a href="#CurrentPage#?pgfn=detail&order_ID=#order_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">Order #order_number# Detail</a> or <a href="#CurrentPage#?xT=#xT#&xTD=#xTD#&xFD=#xFD#&xOF=#xOF#&OnPage=#OnPage#">Order List</a> without making changes.</span>
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
			<cfloop query="FindProductOptionInfo"> [#category_name#: #option_name#] </cfloop>
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
		<input type="hidden" name="xOF" value="#xOF#">
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
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->