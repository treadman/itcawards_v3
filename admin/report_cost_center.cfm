<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000037-1000000076",true)>

<!--- ************************************ --->
<!--- param all variables used on this page --->
<!--- ************************************ --->
<cfparam name="FromDate" default="">
<cfparam name="ToDate" default="">
<cfparam name="formatFromDate" default="">
<cfparam name="formatToDate" default="">
<cfparam name="status" default="approved">

<!--- Verify that a program was selected --->
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

<cfset leftnavon = "costcenterreport">
<cfset request.main_width = 900>
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Cost Center Billing Report</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>
	<span class="pagetitle">Cost Center Billing Report for <cfoutput>#request.program_name#</cfoutput></span>
	<br /><br />
<!--- find program's min max order dates --->
	<cfif IsDefined('form.submit')>
		<cfset FromDate = FLGen_DateTimeToDisplay(FromDate)>
		<cfset formatFromDate = FLGen_DateTimeToMySQL(FromDate)>
		<cfset ToDate = FLGen_DateTimeToDisplay(ToDate)>
		<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
	</cfif>

	<cfoutput>
	<!--- search box (START) --->
	<table cellpadding="5" cellspacing="0" border="0" width="500">
		<tr class="contenthead">
			<td colspan="3"><span class="headertext">Generate Billing Report</span>&nbsp;&nbsp;&nbsp;&nbsp;<span class="sub"></span></td>
		</tr>
		<form action="#CurrentPage#" method="post">
			<tr>
				<td class="content">
				</td>
				<td class="content" align="right">From Date: </td>
				<td class="content" align="left"><input type="text" name="FromDate" value="#FromDate#" size="12"></td>
				<input type="hidden" name="FromDate_required" value="Please enter a from date.">
			</tr>
			<tr>
				<td class="content">
				</td>
				<td class="content" align="right">To Date:</td>
				<td class="content" align="left"><input type="text" name="ToDate" value="#ToDate#" size="12"></td>
				<input type="hidden" name="ToDate_required" value="Please enter a to date.">
			</tr>
			<tr>
				<td class="content">
				</td>
				<td class="content" align="right">Show:</td>
				<td class="content" align="left">
					<select name="status">
						<option value="approved" <cfif status eq "approved">selected</cfif>>Only Approved Orders</option>
						<option value="rejected" <cfif status eq "rejected">selected</cfif>>Only Declined Orders</option>
						<option value="pending" <cfif status eq "pending">selected</cfif>>Only Pending Orders</option>
						<option value="all" <cfif status eq "all">selected</cfif>>All Orders</option>
					</select>
				</td>
			</tr>
			<tr class="content">
				<td colspan="3" align="center"><input type="submit" name="submit" value="Generate Report"></td>
			</tr>
		</form>
	</table>
	<br /><br />
	</cfoutput>
	<!--- search box (END) --->
</cfif>

<!--- **************** --->
<!--- if survey report --->
<!--- **************** --->

<cfif IsDefined('form.submit')>
	<cfset displayed_anything = false>
	<!--- find the users for this program --->
	<cfquery name="FindCCs" datasource="#application.DS#">
		SELECT DISTINCT c.ID, c.number, c.description
		FROM #application.database#.cost_centers c
		LEFT JOIN #application.database#.order_info o ON o.cost_center_ID = c.ID
		WHERE c.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		AND o.cost_center_ID > 0
		<cfswitch expression="#status#">
			<cfcase value="approved">
				AND o.approval = 3 AND o.is_valid = 1
			</cfcase>
			<cfcase value="rejected">
				AND o.approval = 9
			</cfcase>
			<cfcase value="pending">
				 AND o.approval IN (1,2)
			</cfcase>
			<cfcase value="all">
				AND (o.approval = 3 AND o.is_valid = 1)
				OR o.approval IN (1,2,9)
			</cfcase>
		</cfswitch>
		AND o.created_datetime >= <cfqueryparam value="#formatFromDate#">
		AND o.created_datetime <= <cfqueryparam value="#formatToDate#">
		ORDER BY c.number ASC 
	</cfquery>
	<cfoutput>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<!--- header row --->
		<tr class="content2">
			<td colspan="100%"><span class="headertext">Program: <span class="selecteditem">#request.program_name#</span></span></td>
		</tr>
		<tr class="content2">
			<td colspan="100%"><span class="headertext">Dates:&nbsp;&nbsp;&nbsp;<span class="selecteditem">#FromDate#<span class="reg">&nbsp;&nbsp;&nbsp;to&nbsp;&nbsp;&nbsp;</span>#ToDate#</span></span></td>
		</tr>
		<tr class="contenthead">
			<td class="headertext">Username</td>
			<td class="headertext">Name</td>
			<td class="headertext">Email Address</td>
			<td class="headertext" align="center">Charge</td>
			<td class="headertext" colspan="2" align="center">Order ## and Date</td>
			<td class="headertext">Status</td>
		</tr>
		<cfset old_cc = "FIRST">
		<cfset sub_total = 0>
		<cfset grand_total = 0> 
		<cfloop query="FindCCs">
			<cfif old_cc NEQ FindCCs.number>
				<cfif old_cc NEQ "FIRST">
					<tr><td colspan="3" align="right">Total for <strong>#old_cc#</strong></td><td align="right"><strong>#sub_total#</strong></td></tr>
					<cfset sub_total = 0>
				</cfif>
				<tr><td></td></tr>
				<tr><td colspan="100%">Cost Center: <strong>#FindCCs.number# - #FindCCs.description#</strong></td></tr>
			</cfif>
			<cfquery name="getOrders" datasource="#application.DS#">
				SELECT ID, created_user_ID, created_datetime, order_number, cost_center_charge, approval, cost_center_ID
				FROM #application.database#.order_info
				WHERE cost_center_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#FindCCs.ID#">
				<cfswitch expression="#status#">
					<cfcase value="approved">
						AND approval = 3 AND is_valid = 1
					</cfcase>
					<cfcase value="rejected">
						AND approval = 9
					</cfcase>
					<cfcase value="pending">
						 AND approval IN (1,2)
					</cfcase>
					<cfcase value="all">
						AND ((approval = 3 AND is_valid = 1)
						OR approval IN (1,2,9))
					</cfcase>
				</cfswitch>
				AND created_datetime >= <cfqueryparam value="#formatFromDate#">
				AND created_datetime <= <cfqueryparam value="#formatToDate#">
				ORDER BY created_datetime DESC
			</cfquery>
			<cfset class_num = "">
			<cfloop query="getOrders">
				<cfquery name="FindUser" datasource="#application.DS#">
					SELECT fname, lname, email, username
					FROM #application.database#.program_user
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#getOrders.created_user_ID#" maxlength="10">
					ORDER BY lname ASC 
				</cfquery>
				<tr class="content#class_num#">
					<td>#FindUser.username#</td>
					<td>#FindUser.lname#, #FindUser.fname#</td>
					<td>#FindUser.email#</td>
					<td align="right">#getOrders.cost_center_charge#</td>
					<td align="right">#getOrders.order_number#</td>
					<td>#dateFormat(getOrders.created_datetime,"mm/dd/yyyy")#</td>
					<td>
						<cfswitch expression="#getOrders.approval#">
							<cfcase value="3">
								Approved
							</cfcase>
							<cfcase value="9">
								Rejected
							</cfcase>
							<cfcase value="1,2">
								Pending
							</cfcase>
						</cfswitch>
					</td>
				</tr>
				<cfset sub_total = sub_total + getOrders.cost_center_charge>
				<cfset grand_total = grand_total + getOrders.cost_center_charge>
				<cfset displayed_anything = true>
				<cfif class_num EQ ""><cfset class_num = "2"><cfelse><cfset class_num = ""></cfif>
			</cfloop>
			<cfset old_cc = FindCCs.number>
		</cfloop>
		<tr><td colspan="3" align="right">Total for <strong>#old_cc#</strong></td><td align="right"><strong>#sub_total#</strong></td></tr>
		<tr><td colspan="3" align="right">Grand Total</td><td align="right"><strong>#grand_total#</strong></td></tr>
	</table>
	</cfoutput>
	<cfif NOT displayed_anything>
		<span class="alert">There is no information to display.</span>
	</cfif>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->