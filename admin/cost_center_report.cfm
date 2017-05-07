<cfsetting requesttimeout="300">

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfset crlf = "<br>">

<cfparam name="pgfn" default="report">

<cfset errors_found = false>
<cfset alert_msg = "">
<cfset DisplayResults = "">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->


<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Cost Center Report</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

<span class="pagetitle">
	<cfoutput>#request.program_name#</cfoutput> Cost Centers  &nbsp;&nbsp;&nbsp;&nbsp;
</span>
<br /><br />
<span class="pageinstructions">Return to <a href="cost_centers.cfm">Cost Center List</a> or <a href="program_list.cfm">Award Program List</a></span>
<br><br>

<cfif pgfn EQ "report">
	<cfquery name="GetCostCenterUser" datasource="#application.DS#">
		SELECT
			t.ID,
			t.program_ID,
			u.ID as user_ID,
			u.program_ID AS user_program_id,
			t.employeeID,
			t.lastname,
			t.firstname,
			t.email,
			t.cc_code,
			t.cc_desc,
			t.mgr_lastname,
			t.mgr_firstname,
			t.mgr_email,
			t.mc_lastname,
			t.mc_firstname,
			t.mc_email
		FROM #application.database#.cost_center_user t
		LEFT JOIN #application.database#.program_user u ON u.email = t.email AND u.program_ID = t.program_ID
		WHERE t.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" maxlength="10" value="#request.selected_program_ID#">
		ORDER BY t.lastname, t.firstname
	</cfquery>
	<cfsetting enablecfoutputonly="true">
	<cfloop query="GetCostCenterUser">
		<cfoutput>#GetCostCenterUser.lastname#,#GetCostCenterUser.firstname#,</cfoutput>
		<cfif isNumeric(GetCostCenterUser.user_ID)>
			<cfquery name="GetCostCenter" datasource="#application.DS#">
				SELECT c.ID, c.number, c.description
				FROM #application.database#.cost_centers c
				INNER JOIN #application.database#.xref_cost_center_users x ON x.cost_center_ID = c.ID
				WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" maxlength="10" value="#request.selected_program_ID#">
				AND x.program_user_ID = #GetCostCenterUser.user_ID# 
			</cfquery>
			<cfif GetCostCenter.recordcount EQ 0>
				<cfoutput>no CC,</cfoutput>
			<cfelse>
				<cfoutput>#valuelist(GetCostCenter.number,'|')#,</cfoutput>
			</cfif>
			<cfoutput>is registered,</cfoutput>
		<cfelse>
			<cfoutput>not registered,</cfoutput>
		</cfif>
		<cfoutput>#GetCostCenterUser.mgr_lastname#,#GetCostCenterUser.mgr_firstname#,</cfoutput>
		<cfoutput>#GetCostCenterUser.mc_lastname#,#GetCostCenterUser.mc_firstname#</cfoutput>
		<cfoutput>#crlf#</cfoutput>
	</cfloop>
	<cfsetting enablecfoutputonly="false">
</cfif>
</cfif>
<cfinclude template="includes/footer.cfm">
