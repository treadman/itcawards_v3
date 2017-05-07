<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000112,true)>

<cfset thisYear = Year(Now())>

<cfparam name="FromDate" default="01/01/#thisYear#">
<cfparam name="ToDate" default="12/31/#thisYear#">
<cfparam name="formatFromDate" default="">
<cfparam name="formatToDate" default="">
<cfparam name="points_threshold" default="600">

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
<cfset request.main_width = 1300>
<cfset leftnavon = "report_1099">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">1099 Report</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>
	<span class="pagetitle">1099 Report for <cfoutput>#request.program_name#</cfoutput></span>
	<br /><br />

<!--- search box (START) --->
<table cellpadding="5" cellspacing="0" border="0" width="40%">

<tr class="contenthead">
<td colspan="100%"><span class="headertext">Generate Report</span></td>
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
	<td class="content" colspan="2">&nbsp;</td>
	<td class="content" align="right">From Date: </td>
	<td class="content" align="left"><input type="text" name="FromDate" value="#FromDate#" size="12"></td>
	</tr>
	
	<tr>
	<td class="content" align="right">Points Threshold: </td>
	<td class="content" align="left"><input type="text" name="points_threshold" value="#points_threshold#" size="12"></td>
	<td class="content" align="right">To Date:</td>
	<td class="content" align="left"><input type="text" name="ToDate" value="#ToDate#" size="12"></td>
	</tr>
	
	<tr class="content">
	<td colspan="100%" align="center"><input type="submit" name="submit" value="Generate Report"></td>
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

<cfif not doit>
	<span class="alert">This program has no orders!</span>
<cfelseif IsDefined('form.submit')>
	<cfquery name="PointsRedeemed" datasource="#application.DS#">
		SELECT IFNULL(SUM(o.points_used),0) AS total_points, p.lname, p.username, p.fname,
			o.snap_ship_fname, o.snap_ship_lname, o.snap_ship_address1, o.snap_ship_address2, o.snap_ship_city,
			o.snap_ship_state, o.snap_ship_zip, o.snap_email
		FROM #application.database#.order_info o
		LEFT JOIN #application.database#.program_user p ON o.created_user_ID = p.ID
		WHERE o.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" />
		<cfif formatFromDate NEQ "">
			AND o.created_datetime >= '#formatFromDate#' 
		</cfif>	
		<cfif formatToDate NEQ "">
			AND o.created_datetime <= '#formatToDate#' 
		</cfif>	
		GROUP BY o.snap_ship_lname, o.snap_ship_fname HAVING total_points >= <cfqueryparam cfsqltype="cf_sql_integer" value="#points_threshold#" />
		ORDER BY snap_ship_lname, snap_ship_fname
	</cfquery>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<!--- header row --->
	<tr class="contenthead">
		<td class="headertext">Taxform ID</td>
		<td class="headertext">Code</td>
		<td class="headertext">PTIN</td>
		<td class="headertext">AccountNo</td>
		<td class="headertext">AccountName</td>
		<td class="headertext">TIN</td>
		<td class="headertext">Name</td>
		<td class="headertext">Address</td>
		<td class="headertext">Address2</td>
		<td class="headertext">City</td>
		<td class="headertext">State</td>
		<td class="headertext">Zip</td>
		<td class="headertext">ProvinceCode</td>
		<td class="headertext">Source</td>
		<td class="headertext">Info1</td>
		<td class="headertext">Email</td>
		<td class="headertext">TranDate</td>
		<td class="headertext" align="right">Dollar Amount</td>
	</tr>
	<cfif PointsRedeemed.recordcount EQ 0>
		<tr class="content">
			<td class="alert" colspan="100%"><br>There are no users who have spent more than <cfoutput>#points_threshold#</cfoutput> points.<br><br></td>
		</tr>
	<cfelse>
		<cfoutput>
		<cfloop query="PointsRedeemed">
			<tr class="content<cfif PointsRedeemed.currentrow MOD 2 EQ 0>2</cfif>">
				<td>M</td>
				<td>9480</td>
				<td>410957894</td>
				<td>#PointsRedeemed.username#</td>
				<td>#PointsRedeemed.fname# #PointsRedeemed.lname#</td>
				<td>&nbsp;</td>
				<td>#PointsRedeemed.snap_ship_fname# #PointsRedeemed.snap_ship_lname#</td>
				<td>#PointsRedeemed.snap_ship_address1#</td>
				<td>#PointsRedeemed.snap_ship_address2#</td>
				<td>#PointsRedeemed.snap_ship_city#</td>
				<td>#PointsRedeemed.snap_ship_state#</td>
				<td>#PointsRedeemed.snap_ship_zip#</td>
				<td>&nbsp;</td>
				<td>REWARDS</td>
				<td>07</td>
				<td>#PointsRedeemed.snap_email#</td>
				<td>&nbsp;</td>
				<td align="right">#PointsRedeemed.total_points#</td>
			</tr>
		</cfloop>
		</cfoutput>
	</cfif>
	</table>
</cfif>

</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->