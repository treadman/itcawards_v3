<!--- import function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000076,true)>

<!--- ************************************ --->
<!--- param all variables used on this page --->
<!--- ************************************ --->
<cfparam name="vendor_ID" default="">
<cfparam name="FromDate" default="">
<cfparam name="ToDate" default="">
<cfparam name="formatFromDate" default="">
<cfparam name="formatToDate" default="">
<cfparam name="sort" default="sku">

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

<cfset leftnavon = "report_redeemed">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Billing Report</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>


<cfoutput>
	<span class="pagetitle">Reedemed Report for <cfoutput><cfif request.selected_division_ID GT 0>#request.division_name# at </cfif>#request.program_name#</cfoutput></span>

<br /><br />
<span class="pageinstructions">Leave the dates blank to see all points that have been redeemed.</span>
<br /><br />

<!--- search box (START) --->
<form action="#CurrentPage#" method="post">
	<table cellpadding="5" cellspacing="0" border="0" width="70%">
	<tr class="contenthead">
		<td colspan="4"><span class="headertext">Redeemed Report</span></td>
	</tr>
	<tr>
		<td class="content" align="right">From Date: </td>
		<td class="content" align="left"><input type="text" name="FromDate" value="#FromDate#" size="12"></td>
		<td class="content" align="right">To Date:</td>
		<td class="content" align="left"><input type="text" name="ToDate" value="#ToDate#" size="12"></td>
	</tr>
	<tr class="content">
		<td colspan="2" align="center"><input type="submit" name="submit" value="Generate Report"></td>
		<td colspan="2" align="right"><!---<a href="report_redeemed_compare.cfm">Download exception report</a>---></td>
	</tr>
	</table>
</form>
</cfoutput>
<!--- search box (END) --->
<br /><br />
	
<!--- **************** --->
<!--- if survey report --->
<!--- **************** --->
	
<cfif isDefined("form.submit")>

	<cfif FromDate NEQ "">
		<cfset formatFromDate = FLGen_DateTimeToMySQL(FromDate)>
	</cfif>	
	<cfif ToDate NEQ "">
		<cfset formatToDate = FLGen_DateTimeToMySQL(ToDate & "23:59:59")>
	</cfif>	

	<!---<cfset merged_id = 0>
	<cfset merged_db = application.database>
	<cfif left(request.program.merged_from,5) EQ 'www2:'>
		<cfset merged_id = mid(request.program.merged_from,6,10)>
		<cfset merged_db = "ITCAwards">
	</cfif>--->

	<cfquery name="ReportRedeemed" datasource="#application.DS#">
		<!---(--->
		SELECT Date_Format(o.created_datetime,'%Y%m%d') AS order_date, p.username, p.badge_id, p.lname,
			<cfif request.selected_division_ID GT 0>
				x.award_points AS points_used
			<cfelse>
				o.points_used
			</cfif>
		FROM #application.database#.order_info o
		<cfif request.selected_division_ID GT 0>
			INNER JOIN #application.database#.xref_order_division x ON x.order_ID = o.ID
		</cfif>
		LEFT JOIN #application.database#.program_user p ON o.created_user_ID = p.ID
		WHERE o.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		<cfif request.selected_division_ID GT 0>
			AND x.division_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_division_ID#" maxlength="10">
		</cfif>
		AND o.is_valid = '1'
		AND o.points_used > 0 
		<cfif formatFromDate NEQ "">
			AND o.created_datetime >= '#formatFromDate#' 
		</cfif>	
		<cfif formatToDate NEQ "">
			AND o.created_datetime <= '#formatToDate#' 
		</cfif>
		<!---) UNION (
		SELECT Date_Format(o.created_datetime,'%Y%m%d') AS order_date, o.points_used, p.username, p.lname 
		FROM #merged_db#.order_info o
		LEFT JOIN #merged_db#.program_user p ON o.created_user_ID = p.ID
		WHERE o.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#merged_id#" maxlength="10">
		AND o.is_valid = '1'
		AND o.points_used > 0 
		<cfif formatFromDate NEQ "">
			AND o.created_datetime >= '#formatFromDate#' 
		</cfif>	
		<cfif formatToDate NEQ "">
			AND o.created_datetime <= '#formatToDate#' 
		</cfif>
		)--->
		ORDER BY order_date ASC 
	</cfquery>
	
	<cfquery name="GetMultiplier" datasource="#application.DS#">
		SELECT points_multiplier 
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	
	<cfoutput><a href="report_redeemed_export.cfm?formatFromDate=#formatFromDate#&formatToDate=#formatToDate#">Export Report to Excel</a></cfoutput><br><br>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<!--- header row --->
	<tr valign="top" class="contenthead">
		<td valign="top" class="headertext">PIN</td>
		<td valign="top" class="headertext">Points Redeemed</td>
		<td valign="top" class="headertext">Points Redeemed Date</td>
		<td valign="top" class="headertext">Last Name</td>
	</tr>
	
	<cfif ReportRedeemed.RecordCount EQ 0>
		<tr class="content2">
			<td colspan="4" align="center" class="alert"><br>There are no results to display.<br><br></td>
		</tr>
	<cfelse>
		<cfoutput query="ReportRedeemed">
			<tr class="content<cfif (CurrentRow MOD 2) is 0>2</cfif>">
				<!--- TODO:  This is another ITG hack:  Ugh!!!  Keep these to a minimum! --->
				<td valign="top"><cfif trim(badge_id) NEQ "">#badge_id#<cfelse>#username#</cfif></td>
				<td valign="top">#points_used * GetMultiplier.points_multiplier#</span></td>
				<td valign="top">#order_date#</span></td>
				<td valign="top">#lname#</td>
			</tr>
		</cfoutput>
	</cfif>
	</table>

</cfif>

</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->