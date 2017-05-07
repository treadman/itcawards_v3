<!--- Verify that a program was selected --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cflocation url="cost_centers.cfm" addtoken="no">
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<cfparam name="cost_center_ID" default="">
<cfif isNumeric(cost_center_ID)>
	<cfquery name="GetCostCenter" datasource="#application.DS#">
		SELECT number, description 
		FROM #application.database#.cost_centers
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
	</cfquery>
	<cfif GetCostCenter.recordcount neq 1>
		<cfset cost_center_ID = "">
	</cfif>
</cfif>
<cfif NOT isNumeric(cost_center_ID)>
	<cflocation url="cost_centers.cfm" addtoken="no">
</cfif> 

<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<!--- run query --->
<cfquery name="GetAdminUsers" datasource="#application.DS#">
	SELECT ID, firstname, lastname, username, email, program_ID, is_active
	FROM #application.database#.admin_users
	WHERE program_ID IN (<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#,1000000001" list="yes">)
	ORDER BY program_ID desc, lastname, firstname
</cfquery>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfquery name="DeleteCurrentSettings" datasource="#application.DS#">
		DELETE FROM #application.database#.xref_cost_center_approvers
		WHERE cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
	</cfquery>
	<cfloop query="GetAdminUsers">
		<cfif isDefined(GetAdminUsers.ID)>
			<cfset admin_id = GetAdminUsers.ID>
			<cfset levels = evaluate("form."&admin_id)>
			<cfloop list="#levels#" index="level">
				<cfquery name="AddSetting" datasource="#application.DS#">
					INSERT INTO #application.database#.xref_cost_center_approvers
						(cost_center_ID, admin_user_ID, level)
					VALUES (
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">,
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#admin_id#" maxlength="10">,
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#level#" maxlength="1">
					)
				</cfquery>
			</cfloop>
		</cfif>
	</cfloop>
	<cfset alert_msg = Application.DefaultSaveMessage>
</cfif>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "cost_centers">
<cfinclude template="includes/header.cfm">

<span class="pagetitle">Approvers for Cost Center <cfoutput>#GetCostCenter.number# in #request.program_name#</cfoutput></span>
<br /><br />
<span class="pageinstructions">Return to <a href="cost_centers.cfm">Cost Center List</a> or <a href="program_list.cfm">Award Program List</a> without making changes.</span>
<br /><br />

<cfif GetAdminUsers.RecordCount EQ 0>
	<br><br>
	<span class="alert">There are no admin users!</span>
<cfelse>
	<form name="approvers_form" method="post" action="<cfoutput>#CurrentPage#</cfoutput>">
		<input type="hidden" name="cost_center_ID" value="<cfoutput>#cost_center_ID#</cfoutput>">
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
			<tr class="contenthead">
				<td class="headertext">Name</td>
				<td class="headertext">Username</td>
				<td class="headertext">Email</td>
				<td class="headertext">Level 1</td>
				<td class="headertext">Level 2</td>
			</tr>
			<cfset oldProgramID = "FIRST_TIME">
			<cfoutput query="GetAdminUsers">
				<cfif program_ID neq oldProgramID>
					<tr class="BGshowhide">
					<td colspan="100%">
						<span class="program_headers"><cfif program_ID EQ 1000000001>#application.AdminName# Admin<cfelse>#request.program_name#</cfif> Users</span>
					</td>
					</tr>
				</cfif>
				<cfset thisClass = Iif(((CurrentRow MOD 2) is 0),de('content'),de('content2'))>
				<cfif is_active EQ 0>
					<cfset thisClass = "inactivebg">
				</cfif>
				<tr class="#thisClass#">
					<td>#firstname# #lastname#</td>
					<td>#username#</td>
					<td>#email#</td>
					<cfquery name="GetLevel1" datasource="#application.DS#">
						SELECT ID FROM #application.database#.xref_cost_center_approvers
						WHERE cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
						AND admin_user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
						AND level = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="1" maxlength="1">
					</cfquery>
					<cfset checked = "">
					<cfif GetLevel1.recordcount GT 0>
						<cfset checked = "checked">
					</cfif>
					<td><input type="checkbox" name="#ID#" value="1" #checked#></td>
					<cfquery name="GetLevel2" datasource="#application.DS#">
						SELECT ID FROM #application.database#.xref_cost_center_approvers
						WHERE cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
						AND admin_user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
						AND level = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="2" maxlength="1">
					</cfquery>
					<cfset checked = "">
					<cfif GetLevel2.recordcount GT 0>
						<cfset checked = " checked">
					</cfif>
					<td><input type="checkbox" name="#ID#" value="2" #checked#></td>
				</tr>
				<cfset oldProgramID = program_ID>
			</cfoutput>
			<tr>
			<td colspan="100%" align="center"><br><input type="submit" name="submit" value="   Save Changes   " ></td>
			</tr>
		</table>
	</form>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->