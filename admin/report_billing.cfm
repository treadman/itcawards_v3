<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000037-1000000076",true)>

<cfparam name="report_type" default="">
<cfparam name="FromDate" default="">
<cfparam name="ToDate" default="">
<cfparam name="formatFromDate" default="">
<cfparam name="formatToDate" default="">

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

<cfset leftnavon = "billingreport">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Billing Report</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>
	<span class="pagetitle">Billing Report for <cfoutput>#request.program_name#</cfoutput></span>
	<br /><br />
	<span class="pageinstructions">Read a <a href="report_billing_explanation.cfm" target="_blank">detailed explanation</a> of how the report results are generated.</span>
	<br /><br />

	<!--- search box (START) --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="3"><span class="headertext">Generate Billing Report</span>&nbsp;&nbsp;&nbsp;&nbsp;<span class="sub">(dates are optional)</span></td>
	</tr>
	
	<cfif IsDefined('form.submit')>
		<cfif FromDate EQ "" OR ToDate EQ "">
			<!--- find program's min max order dates --->
			<cfquery name="MinMaxOrderDates" datasource="#application.DS#">
				SELECT MIN(created_datetime) AS first_order, MAX(created_datetime) AS last_order 
				FROM #application.database#.order_info
				WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
					AND is_valid = 1
			</cfquery>
			<cfif FromDate EQ "" AND MinMaxOrderDates.first_order NEQ "">
				<cfset FromDate = FLGen_DateTimeToDisplay(MinMaxOrderDates.first_order)>
			<cfelseif FromDate EQ "">
				<cfset FromDate = FLGen_DateTimeToDisplay()>
			</cfif>
			<cfif ToDate EQ "" AND MinMaxOrderDates.last_order NEQ "">
				<cfset ToDate = FLGen_DateTimeToDisplay(MinMaxOrderDates.last_order)>
			<cfelseif ToDate EQ "">
				<cfset ToDate = FLGen_DateTimeToDisplay()>
			</cfif>
		</cfif>
		<cfset FromDate = FLGen_DateTimeToDisplay(FromDate)>
		<cfset formatFromDate = FLGen_DateTimeToMySQL(FromDate)>
		<cfset ToDate = FLGen_DateTimeToDisplay(ToDate)>
		<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
	</cfif>
	<cfoutput>	
	<form action="#CurrentPage#" method="post">
	<tr>
	<td class="content" rowspan="2">
	Choose one:<br>
		<select name="report_type" size="4">
			<option value="zero"<cfif report_type EQ 'zero' OR report_type EQ ''> selected</cfif>>Display Zero Point Users</option>
			<option value="part"<cfif report_type EQ 'part'> selected</cfif>>Display Partial Point Users</option>
			<option value="bala"<cfif report_type EQ 'bala'> selected</cfif>>Display Users With Point Balance</option>
			<option value="tran"<cfif report_type EQ 'tran'> selected</cfif>>Display Order Transactions</option>
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
	<td colspan="3" align="center"><input type="submit" name="submit" value="   Generate Report  "></td>
	</tr>
	</form>
	</cfoutput>
	</table>
	<!--- search box (END) --->
	<br /><br />
	
<!--- **************** --->
<!--- if survey report --->
<!--- **************** --->
<cfif IsDefined('form.submit')>

	<cfset displayed_anything = false>

	<cfif report_type EQ 'tran'>
		<!--- find the users for this program --->
		<cfquery name="FindAllUsers" datasource="#application.DS#">
			SELECT u.ID AS user_ID, u.username, u.fname, u.lname, u.nickname, o.order_number, o.points_used, o.created_datetime 
			FROM #application.database#.order_info o
			LEFT JOIN #application.database#.program_user u ON u.ID = o.created_user_ID
			WHERE u.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND o.created_datetime >= <cfqueryparam value="#formatFromDate#">
			AND o.created_datetime <= <cfqueryparam value="#formatToDate#">
			AND o.is_valid = 1
			ORDER BY u.lname, o.created_datetime 
		</cfquery>

	<cfelse>
		<!--- find the users for this program --->
		<cfquery name="FindAllUsers" datasource="#application.DS#">
			SELECT u.ID AS user_ID, u.username, u.fname, u.lname, u.nickname
			FROM #application.database#.program_user u
			WHERE u.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			ORDER BY u.lname ASC 
		</cfquery>
	</cfif>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<!--- header row --->
	<tr class="content2">
	<td colspan="<cfif report_type EQ 'tran'>5<cfelse>6</cfif>"><span class="headertext">Program: <span class="selecteditem"><cfoutput>#request.program_name#</cfoutput></span></span></td>
	</tr>
	
	<tr class="content2">
	<td colspan="<cfif report_type EQ 'tran'>5<cfelse>6</cfif>"><span class="headertext">Dates:&nbsp;&nbsp;&nbsp;<span class="selecteditem"><cfoutput>#FromDate#</cfoutput><span class="reg">&nbsp;&nbsp;&nbsp;to&nbsp;&nbsp;&nbsp;</span><cfoutput>#ToDate#</cfoutput></span></span></td>
	</tr>
	
	<cfoutput>
	<cfif report_type EQ 'tran'>
		<tr class="contenthead">
			<td class="headertext">Username</td>
			<td class="headertext">Name</td>
			<td class="headertext" align="center">Points</td>
			<td class="headertext">Order Number</td>
			<td class="headertext">Date</td>
		</tr>
	<cfelse>
		<tr class="contenthead">
			<td class="headertext" rowspan="2">Username</td>
			<td class="headertext" rowspan="2">Name</td>
			<td class="headertext" align="center" colspan="3">Points</td>
			<td class="headertext" rowspan="2">Date of Last Order</td>
		</tr>
		<tr class="contenthead">
			<td class="headertext" align="center">Awarded</td>
			<td class="headertext" align="center">Used</td>
			<td class="headertext" align="center">Remaining</td>
		</tr>
	</cfif>
	
	<cfloop query="FindAllUsers">
		<cfset thisUserID = FindAllUsers.user_ID>
		<cfset thisUsername = FindAllUsers.username>
		<cfset thisFname = FindAllUsers.fname>
		<cfset thisLname = FindAllUsers.lname>
		<cfset thisNickname = FindAllUsers.nickname>

		<!--- code for zero report --->
		<!--- code for zero report --->
		<!--- code for zero report --->
		<cfif report_type EQ 'zero' OR report_type EQ 'part' OR report_type EQ 'bala'>
			<cfset ProgramUserInfoConstrained(thisUserID,formatFromDate,formatToDate)>
			<!--- 	BRp_pospoints
					BRp_negpoints
					BRp_totalpoints
					BRp_deferedpoints
					BRp_order_in_range
					BRp_last_order 	--->
			<!--- IF	ZERO BALANCE 
						has no points left
						had points to start with
						didn't defer the points
						and has an order within the date range --->
			<cfif report_type EQ 'zero' AND BRp_totalpoints EQ 0 AND BRp_deferedpoints EQ 0 AND BRp_pospoints NEQ 0 AND BRp_order_in_range>
				<tr class="content">
					<td>#thisUsername#</td>
					<td>#thisLname#, #thisFname#<cfif thisNickname NEQ ""> (#thisNickname#)</cfif></td>
					<td align="right">#BRp_pospoints#</td>
					<td align="right">#BRp_negpoints#</td>
					<td align="right">#BRp_totalpoints#</td>
					<td>#BRp_last_order#<cfset displayed_anything = true></td>
				</tr>
			<cfelseif report_type EQ 'part' AND BRp_totalpoints GT 0 AND BRp_deferedpoints EQ 0 AND BRp_negpoints GT 0 AND BRp_order_in_range>
				<tr class="content">
				<td>#thisUsername#</td>
				<td>#thisLname#, #thisFname#<cfif thisNickname NEQ ""> (#thisNickname#)</cfif></td>
				<td align="right">#BRp_pospoints#</td>
				<td align="right">#BRp_negpoints#</td>
				<td align="right">#BRp_totalpoints#</td>
				<td>#BRp_last_order#<cfset displayed_anything = true></td>
				</tr>
			<cfelseif report_type EQ 'bala' AND BRp_totalpoints GT 0>
				<tr class="content">
				<td>#thisUsername#</td>
				<td>#thisLname#, #thisFname#<cfif thisNickname NEQ ""> (#thisNickname#)</cfif></td>
				<td align="right">#BRp_pospoints#</td>
				<td align="right">#BRp_negpoints#</td>
				<td align="right">#BRp_totalpoints#</td>
				<td><cfif IsDefined('BRp_last_order') AND BRp_last_order NEQ "">#BRp_last_order#<cfelse>(none)</cfif><cfset displayed_anything = true></td>
				</tr>
			</cfif>

			<!--- code for tran report --->
			<!--- code for tran report --->
			<!--- code for tran report --->
		<cfelseif report_type EQ 'tran_old'>
	
			<!--- find this user's orders --->
			<cfquery name="FindUserOrders" datasource="#application.DS#">
				SELECT order_number, points_used, created_datetime 
				FROM #application.database#.order_info
				WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisUserID#" maxlength="10">
					AND created_datetime >= <cfqueryparam value="#formatFromDate#">
					AND created_datetime <= <cfqueryparam value="#formatToDate#">
					AND is_valid = 1
				ORDER BY created_datetime 
			</cfquery>
	
			<cfif FindUserOrders.RecordCount NEQ 0>
				<cfset displayed_anything = true>
				<cfloop query="FindUserOrders">
					<tr class="content">
					<td>#thisUsername#</td>
					<td>#thisLname#, #thisFname#<cfif thisNickname NEQ ""> (#thisNickname#)</cfif></td>
					<td align="right">#FindUserOrders.points_used#</td>
					<td>#FindUserOrders.order_number#</td>
					<td>#FLGen_DateTimeToDisplay(FindUserOrders.created_datetime)#</td>
					</tr>
				</cfloop>
			</cfif>
		<cfelseif report_type EQ 'tran'>
			<tr class="content">
			<td>#thisUsername#</td>
			<td>#thisLname#, #thisFname#<cfif thisNickname NEQ ""> (#thisNickname#)</cfif></td>
			<td align="right">#FindAllUsers.points_used#</td>
			<td>#FindAllUsers.order_number#</td>
			<td>#FLGen_DateTimeToDisplay(FindAllUsers.created_datetime)#</td>
			</tr>
			<cfset displayed_anything = true>
		</cfif>
	</cfloop>
	</cfoutput>
	</table>
	<cfif NOT displayed_anything>
		<span class="alert">There is no information to display.</span>
	</cfif>
</cfif>
</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->