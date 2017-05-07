<!--- *************************** --->
<!--- authenticate the admin user --->
<!--- *************************** --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000033,true)>

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<cfquery name="AdminLevels" datasource="#application.DS#">
	SELECT level_name, ID AS adminlevelID, note 
	FROM #application.database#.admin_level
	ORDER BY sortorder
</cfquery>

<cfquery name="AdminUsers" datasource="#application.DS#">
	SELECT u.firstname, u.lastname, u.ID, p.program_name, p.company_name, u.program_ID
	FROM #application.database#.admin_users u
	LEFT JOIN #application.database#.program p ON u.program_ID = p.ID 
	WHERE u.is_active = 1
	<cfif has_program>
		AND u.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
	</cfif>
</cfquery>

<cfset UserIDs = ValueList(AdminUsers.ID)>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "adminaccessreport">
<cfset request.main_width = 800>
<cfif AdminUsers.recordcount GT 10>
	<cfset request.main_width = 800 + ( (AdminUsers.recordcount-10) * 50 )>
</cfif>
<cfinclude template="includes/header.cfm">

<span class="pagetitle">Admin Access Report for <cfif has_program><cfoutput>#request.program_name# Administrators</cfoutput><cfelse>All Program Administrators and <cfoutput>#application.AdminName# Admin Users</cfoutput></cfif></span>
<br /><br />
<cfif AdminUsers.recordcount EQ 0>
	<br><br>
	<span class="alert"><cfoutput>#request.program_name# has no administrators.</cfoutput></span>
<cfelse>
	<span class="pageinstructions">Place your cursor over the user's initials to see their full name.</span>
	<br /><br />
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr class="contenthead">
			<td><span class="headertext">Admin Level</span></td>
			<cfoutput query="AdminUsers">
				<td align="center"><span title=" #firstname# #lastname# (<cfif AdminUsers.program_ID EQ 1000000001>#application.AdminName# Admin<cfelse>#AdminUsers.company_name# [#AdminUsers.program_name#]</cfif>)" class="tooltip">#RemoveChars(AdminUsers.firstname,2,Len(AdminUsers.firstname))##RemoveChars(AdminUsers.lastname,2,Len(AdminUsers.lastname))#</span></td>
			</cfoutput>
		</tr>
		<cfoutput query="AdminLevels">
			<cfif note EQ 'header'>
				<tr>
					<td colspan="#ListLen(UserIDs) + 1#" class="content2"><span class="headertext">#level_name#</span></td>
				</tr>
			<cfelse>
				<cfquery name="WhichAccess" datasource="#application.DS#">
					SELECT user_ID  
					FROM #application.database#.admin_lookup
					WHERE access_level_ID = #adminlevelID#
				</cfquery>
				<cfset WhichAccessIDs = ValueList(WhichAccess.user_ID)>
				<tr class="content">
					<td>#level_name#</td>
					<cfloop list="#UserIDs#" index="thisID">
						<td align="center"><cfif ListFind(WhichAccessIDs,thisID)><b>X</b><cfelse>&nbsp;</cfif></td>
					</cfloop>
				</tr>
			</cfif>
		</cfoutput>
	</table>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->