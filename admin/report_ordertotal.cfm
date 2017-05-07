<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000035,true)>

<cfparam name="FromDate" default="">
<cfparam name="ToDate" default="">
<cfparam name="formatFromDate" default="">
<cfparam name="formatToDate" default="">

<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->
<cfset leftnavon = "ordertotalreport">
<cfinclude template="includes/header.cfm">

<cfoutput>
<span class="pagetitle">Order Totals Report for <cfif has_program>#request.program_name#</cfif></span>
<br /><br />
</cfoutput>

<!--- search box (START) --->
<table cellpadding="5" cellspacing="0" border="0" width="100%">

<tr class="contenthead">
<td colspan="3"><span class="headertext">Generate Order Totals Report</span></td>
</tr>

<cfif FromDate NEQ "">
	<cfset FromDate = FLGen_DateTimeToDisplay(FromDate)>
	<cfset formatFromDate = FLGen_DateTimeToMySQL(FromDate)>
	<cfif ToDate NEQ "">
		<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
		<cfset ToDate = FLGen_DateTimeToDisplay(ToDate)>
	<cfelse>
		<cfset ToDate = FLGen_DateTimeToDisplay()>
		<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
	</cfif>
</cfif>	

<cfoutput>
<form action="#CurrentPage#" method="post">
	<tr>
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
</form>
</cfoutput>

</table>
<br /><br />
<!--- search box (END) --->

<!--- **************** --->
<!--- if survey report --->
<!--- **************** --->

<cfset doit = true>
<cfif NOT has_program>
	<cfset doit = false>
<cfelse>
	<cfquery name="FirstOrder" datasource="#application.DS#">
		SELECT created_datetime
		FROM #application.database#.order_info
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND is_valid = 1
		ORDER BY created_datetime
		LIMIT 1
	</cfquery>
	<cfif FirstOrder.recordcount EQ 0>
		<cfset doit = false>
	</cfif>
</cfif>

<cfif not doit>
	<span class="alert">
	<cfif NOT has_program>
		<cfoutput>#application.AdminSelectProgram#</cfoutput>
	<cfelse>
		This program has no orders!
	</cfif>
	</span>
<cfelseif IsDefined('form.submit')>

	<!--- USER TOTALS --->
	<!--- USER TOTALS --->
	<!--- USER TOTALS --->

	<!--- total user for this program --->
	<cfquery name="UserTotal" datasource="#application.DS#">
		SELECT u.ID AS total_users_ID, IFNULL(SUM(p.points),0) AS def_pt
		FROM #application.database#.program_user u
		LEFT JOIN #application.database#.awards_points p ON p.user_ID = u.ID AND p.is_defered = 1
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		GROUP BY u.ID
	</cfquery>
	<cfset total_users = UserTotal.RecordCount>

	<!--- users that have ordered --->
	<cfquery name="UserOrderTotal" datasource="#application.DS#">
		SELECT created_user_ID AS order_users_ID, COUNT(*) AS total_orders
		FROM #application.database#.order_info
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND is_valid = 1
		GROUP BY created_user_ID
		ORDER BY created_user_ID
	</cfquery>
	<cfset total_users_withorders = UserOrderTotal.RecordCount>

	<cfif FromDate NEQ "">
		<!--- users that have ordered --->
		<cfquery name="CON_UserOrderTotal" datasource="#application.DS#">
			SELECT DISTINCT created_user_ID AS order_users_ID
			FROM #application.database#.order_info
			WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
				AND is_valid = 1
				AND created_datetime >= <cfqueryparam value="#formatFromDate#">
				AND created_datetime <= <cfqueryparam value="#formatToDate#">
		</cfquery>
		<cfset CON_total_users_withorders = CON_UserOrderTotal.RecordCount>
	</cfif>

	<!--- users that have not ordered yet --->
	<cfset total_users_withoutorders = total_users - total_users_withorders>

	<!--- users that have deferred --->
	<cfset total_users_defer = 0>
	<cfloop query="UserTotal">
		<cfif UserTotal.def_pt NEQ 0>
			<cfset total_users_defer = IncrementValue(total_users_defer)>
		</cfif>
	</cfloop>

	<cfif FromDate NEQ "">
		<!--- users that have deferred --->
		<cfquery name="CON_UserDefer" datasource="#application.DS#">
			SELECT COUNT(up.ID) as CON_DeferUser
			FROM #application.database#.program_user up
			JOIN #application.database#.awards_points ap ON up.ID = ap.user_ID
			WHERE up.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
				AND ap.is_defered = 1
				AND ap.created_datetime >= <cfqueryparam value="#formatFromDate#">
				AND ap.created_datetime <= <cfqueryparam value="#formatToDate#">
		</cfquery>
		<cfset CON_total_users_defer = CON_UserDefer.CON_DeferUser>
	</cfif>

	<!--- users that have ordered and have points left --->
	<!--- users that have ordered and have NO points left --->
	<cfset total_users_withpoints = 0>
	<cfset total_users_withoutpoints = 0>
	<cfloop query="UserOrderTotal">
		<cfset ProgramUserInfo(order_users_ID)>
		<cfif user_totalpoints NEQ 0>
			<cfset total_users_withpoints = IncrementValue(total_users_withpoints)>
		<cfelseif user_totalpoints EQ 0>
			<cfset total_users_withoutpoints = IncrementValue(total_users_withoutpoints)>
		</cfif>
	</cfloop>

	<!--- potential order makers --->
	<cfset total_users_potentialorderers = total_users_withoutorders + total_users_withpoints>

	<!--- users that have made multiple orders --->
	<cfquery name="multiorders" dbtype="query">
		SELECT total_orders
		FROM UserOrderTotal
		WHERE total_orders > 1
	</cfquery>
	<!--- <cfset total_users_withmultiorders = 0>
	<cfloop query="UserOrderTotal">
		<cfif UserOrderTotal.total_orders GT 1>
			<cfset total_users_withmultiorders = IncrementValue(total_users_withmultiorders)>
		</cfif>
	</cfloop> --->

	<!--- ORDER TOTALS --->
	<!--- ORDER TOTALS --->
	<!--- ORDER TOTALS --->

	<cfset date_first_order = FirstOrder.created_datetime>

	<!--- total orders for program --->
	<cfquery name="TotalOrders" datasource="#application.DS#">
		SELECT ID as totalorders_ID, is_all_shipped, order_number
		FROM #application.database#.order_info
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND is_valid = 1
	</cfquery>
	<cfset total_orders = TotalOrders.RecordCount>

	<!--- set variables --->
	<cfset total_order_fulfilled = 0>
	<cfset total_order_fulfilledconf = 0>
	<cfset total_order_fulfillednotconf = 0>
	<cfset total_order_partiallyfulfilledconf = 0>
	<cfset total_order_partiallyfulfillednotconf = 0>
	<cfset total_order_notfulfilled = 0>

	<!--- loop through orders --->
	<cfloop query="TotalOrders">

		<cfif is_all_shipped EQ 1>
			<cfset total_order_fulfilled = IncrementValue(total_order_fulfilled)>
		<cfelse>

			<!--- find items in order --->
			<cfquery name="OrderItems" datasource="#application.DS#">
				SELECT CAST(IFNULL(ship_date,'') AS CHAR) AS ship_date , IFNULL(po_rec_date,'') AS po_rec_date, po_ID, snap_is_dropshipped 
				FROM #application.database#.inventory
				WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#totalorders_ID#" maxlength="10">
					AND is_valid = 1
			</cfquery>
			<!--- set variables --->
			<cfset j_total_items = OrderItems.RecordCount>
			<cfset j_total_dropitems = 0>
			<cfset j_total_shipitems = 0>
			<cfset j_nodrop = 0>
			<cfset j_dropnoconf = 0>
			<cfset j_dropconf = 0>
			<cfset j_notshipped = 0>
			<cfset j_shipped = 0>

			<!--- loop through items in order --->
			<cfloop query="OrderItems">
				<cfif OrderItems.snap_is_dropshipped EQ 1>
					<cfset j_total_dropitems = IncrementValue(j_total_dropitems)>
					<cfif OrderItems.po_rec_date EQ '' AND po_ID EQ 0>
						<cfset j_nodrop = IncrementValue(j_nodrop)>
					<cfelseif OrderItems.po_rec_date EQ '' AND po_ID NEQ 0>
						<cfset j_dropnoconf = IncrementValue(j_dropnoconf)>
					<cfelse>
						<cfset j_dropconf = IncrementValue(j_dropconf)>
					</cfif>
				<cfelseif OrderItems.snap_is_dropshipped EQ 0>
					<cfset j_total_shipitems = IncrementValue(j_total_shipitems)>
					<cfif OrderItems.ship_date EQ ''>
						<cfset j_notshipped = IncrementValue(j_notshipped)>
					<cfelse>
						<cfset j_shipped = IncrementValue(j_shipped)>
					</cfif>
				</cfif>
			</cfloop>

			<!--- determine status of order fulfillment and increment appropriately --->
			<!--- total items = not shipped + not dropshipped items, then it's not fullfilled --->
			<cfif j_total_items EQ (j_nodrop + j_notshipped)>
				<cfset total_order_NOTfulfilled = IncrementValue(total_order_NOTfulfilled)>
			<!--- total items = shipped + drop conf, then it's fullfilled conf --->
			<cfelseif j_total_items EQ (j_dropconf + j_shipped)>
				<cfset total_order_fulfilledconf = IncrementValue(total_order_fulfilledconf)>
			<!--- total items = shipped + drop conf + drop no conf, then it's fullfilled not conf --->
			<cfelseif j_total_items EQ (j_dropnoconf + j_dropconf + j_shipped)>
				<cfset total_order_fulfillednotconf = IncrementValue(total_order_fulfillednotconf)>
			<!--- otherwise, it's partially fulfilled, so let's check if all the dropshipped items are conf --->
			<cfelse>
				<cfif j_total_dropitems EQ j_dropconf>
					<cfset total_order_partiallyfulfilledconf = IncrementValue(total_order_partiallyfulfilledconf)>
				<cfelse>
					<cfset total_order_partiallyfulfillednotconf = IncrementValue(total_order_partiallyfulfillednotconf)>
				</cfif>
			</cfif>
	
		</cfif>

	</cfloop>

	<!--- ORDER TOTALS - CONSTRAINED --->
	<!--- ORDER TOTALS - CONSTRAINED --->
	<!--- ORDER TOTALS - CONSTRAINED --->

	<!--- total orders for program --->
	<cfquery name="CON_TotalOrders" datasource="#application.DS#">
		SELECT ID as CON_totalorders_ID, is_all_shipped, order_number
		FROM #application.database#.order_info
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND is_valid = 1
			AND created_datetime >= <cfqueryparam value="#formatFromDate#">
			AND created_datetime <= <cfqueryparam value="#formatToDate#">
	</cfquery>
	<cfset CON_total_order = CON_TotalOrders.RecordCount>

	<!--- set variables --->
	<cfset CON_total_order_fulfilled = 0>
	<cfset CON_total_order_fulfilledconf = 0>
	<cfset CON_total_order_fulfillednotconf = 0>
	<cfset CON_total_order_partiallyfulfilledconf = 0>
	<cfset CON_total_order_partiallyfulfillednotconf = 0>
	<cfset CON_total_order_notfulfilled = 0>

	<!--- loop through orders --->
	<cfloop query="CON_TotalOrders">

		<cfif is_all_shipped EQ 1>
			<cfset CON_total_order_fulfilled = IncrementValue(CON_total_order_fulfilled)>
		<cfelse>

			<!--- find items in order --->
			<cfquery name="CON_OrderItems" datasource="#application.DS#">
				SELECT CAST(IFNULL(ship_date,'') AS CHAR) AS ship_date, CAST(IFNULL(po_rec_date,'') AS CHAR) AS po_rec_date, po_ID, snap_is_dropshipped 
				FROM #application.database#.inventory
				WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#CON_totalorders_ID#" maxlength="10">
					AND is_valid = 1
			</cfquery>
			<!--- set variables --->
			<cfset CON_j_total_items = CON_OrderItems.RecordCount>
			<cfset CON_j_total_dropitems = 0>
			<cfset CON_j_total_shipitems = 0>
			<cfset CON_j_nodrop = 0>
			<cfset CON_j_dropnoconf = 0>
			<cfset CON_j_dropconf = 0>
			<cfset CON_j_notshipped = 0>
			<cfset CON_j_shipped = 0>

			<!--- loop through items in order --->
			<cfloop query="CON_OrderItems">
				<cfif CON_OrderItems.snap_is_dropshipped EQ 1>
					<cfset CON_j_total_dropitems = IncrementValue(CON_j_total_dropitems)>
					<cfif CON_OrderItems.po_rec_date EQ '' AND po_ID EQ 0>
						<cfset CON_j_nodrop = IncrementValue(CON_j_nodrop)>
					<cfelseif CON_OrderItems.po_rec_date EQ '' AND po_ID NEQ 0>
						<cfset CON_j_dropnoconf = IncrementValue(CON_j_dropnoconf)>
					<cfelse>
						<cfset CON_j_dropconf = IncrementValue(CON_j_dropconf)>
					</cfif>
				<cfelseif CON_OrderItems.snap_is_dropshipped EQ 0>
					<cfset CON_j_total_shipitems = IncrementValue(CON_j_total_shipitems)>
					<cfif CON_OrderItems.ship_date EQ ''>
						<cfset CON_j_notshipped = IncrementValue(CON_j_notshipped)>
					<cfelse>
						<cfset CON_j_shipped = IncrementValue(CON_j_shipped)>
					</cfif>
				</cfif>
			</cfloop>

			<!--- determine status of order fulfillment and increment appropriately --->
			<!--- total items = not shipped + not dropshipped items, then it's not fullfilled --->
			<cfif CON_j_total_items EQ (CON_j_nodrop + CON_j_notshipped)>
				<cfset CON_total_order_NOTfulfilled = IncrementValue(CON_total_order_NOTfulfilled)>
			<!--- total items = shipped + drop conf, then it's fullfilled conf --->
			<cfelseif CON_j_total_items EQ (CON_j_dropconf + CON_j_shipped)>
				<cfset CON_otal_order_fulfilledconf = IncrementValue(CON_total_order_fulfilledconf)>
			<!--- total items = shipped + drop conf + drop no conf, then it's fullfilled not conf --->
			<cfelseif CON_j_total_items EQ (CON_j_dropnoconf + CON_j_dropconf + CON_j_shipped)>
				<cfset CON_total_order_fulfillednotconf = IncrementValue(CON_total_order_fulfillednotconf)>
			<!--- otherwise, it's partially fulfilled, so let's check if all the dropshipped items are conf --->
			<cfelse>
				<cfif CON_j_total_dropitems EQ CON_j_dropconf>
					<cfset CON_total_order_partiallyfulfilledconf = IncrementValue(CON_total_order_partiallyfulfilledconf)>
				<cfelse>
					<cfset CON_total_order_partiallyfulfillednotconf = IncrementValue(CON_total_order_partiallyfulfillednotconf)>
				</cfif>
			</cfif>

		</cfif>

	</cfloop>

	<table cellpadding="5" cellspacing="1" border="0" width="100%">

		<!--- header row --->
		<tr class="content2">
		<td colspan="<cfif FromDate NEQ ''>3<cfelse>2</cfif>"><span class="headertext">Program: <span class="selecteditem"><cfoutput>#request.program_name#</span></span></cfoutput></td>
		</tr>

		<tr>
		<td colspan="<cfif FromDate NEQ ''>3<cfelse>2</cfif>" class="contenthead"><span class="headertext">U S E R S</span></td>
		</tr>

		<cfoutput>
		<tr class="contentsearch">
		<cfif FromDate NEQ ''>
			<td align="center">#FromDate#<br>to<br>#ToDate#</td>
		</cfif>
		<td align="center">#FLGen_DateTimeToDisplay(date_first_order)#<br>to<br>#FLGen_DateTimeToDisplay()#</td>
		<td class="headertext" width="100%">&nbsp;</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">&nbsp;</td>
		</cfif>
		<td align="right">#total_users#</td>
		<td>TOTAL USERS</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">#CON_total_users_defer#</td>
		</cfif>
		<td align="right">#total_users_defer#</td>
		<td>Defered Points</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">&nbsp;</td>
		</cfif>
		<td align="right">#total_users_withoutorders#</td>
		<td>Not Ordered</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">#CON_total_users_withorders#</td>
		</cfif>
		<td align="right">#total_users_withorders#</td>
		<td>Ordered</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">&nbsp;</td>
		</cfif>
		<td align="right">#total_users_withpoints#</td>
		<td>Ordered (points remaining)</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">&nbsp;</td>
		</cfif>
		<td align="right">#total_users_withoutpoints#</td>
		<td>Ordered (no points remaining)</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">&nbsp;</td>
		</cfif>
		<td align="right">#total_users_potentialorderers#</td>
		<td>Potential Order Makers&nbsp;&nbsp;&nbsp;<a href="report_potentialorderers.cfm" target="_blank">view list</a></td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">&nbsp;</td>
		</cfif>
		<td align="right">#multiorders.recordcount#</td>
		<td>Users with multiple orders</td>
		</tr>

		<tr>
		<td colspan="<cfif FromDate NEQ ''>3<cfelse>2</cfif>" class="contenthead"><span class="headertext">O R D E R S</span></td>
		</tr>

		<tr class="contentsearch">
		<cfif FromDate NEQ ''>
			<td  align="center">#FromDate#<br>to<br>#ToDate#</td>
		</cfif>
		<td align="center">#FLGen_DateTimeToDisplay(date_first_order)#<br>to<br>#FLGen_DateTimeToDisplay()#</td>
		<td align="center">&nbsp;</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">#Con_total_order#</td>
		</cfif>
		<td align="right">#total_orders#</td>
		<td>TOTAL ORDERS</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">#CON_total_order_fulfilled + CON_total_order_fulfillednotconf + CON_total_order_fulfilledconf#</td>
		</cfif>
		<td align="right">#total_order_fulfilled + total_order_fulfillednotconf + total_order_fulfilledconf#</td>
		<td>Completely fulfilled</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">#CON_total_order_partiallyfulfillednotconf#</td>
		</cfif>
		<td align="right">#total_order_partiallyfulfillednotconf#</td>
		<td>Partially fulfilled</td>
		</tr>

		<tr class="content">
		<cfif FromDate NEQ ''>
			<td align="right">#CON_total_order_NOTfulfilled#</td>
		</cfif>
		<td align="right">#total_order_NOTfulfilled#</td>
		<td>Not fulfilled</td>
		</tr>

		<tr class="contentsearch">
		<cfif FromDate NEQ ''>
			<td align="right">#CON_total_order_fulfillednotconf#</td>
		</cfif>
		<td align="right">#total_order_fulfillednotconf#</td>
		<td>Completely fulfilled<br>with unconfirmed dropship items</td>
		</tr>

		<tr class="contentsearch">
		<cfif FromDate NEQ ''>
			<td align="right">#CON_total_order_partiallyfulfillednotconf#</td>
		</cfif>
		<td align="right">#total_order_partiallyfulfillednotconf#</td>
		<td>Partially fulfilled<br>with unconfirmed dropship items</td>
		</tr>

		</cfoutput>

	</table>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->