<cfsilent>
<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000006,true)>

<cfparam name="HashedPassword" default="">
<cfparam name="SQLxUpdatePassword" default="">
<cfparam name="QueryString_nodupem" default="">
<cfparam name="show_delete" default="false">
<cfparam name="show_inactive" default="false">
<cfparam name="ID" default="">
<cfparam name="division_ID" default="">
<cfparam name="username" default="">
<cfparam  name="pgfn" default="list">
<cfparam  name="filter_type" default="admin">

<cfset admin_program_ID = 1000000001>

</cfsilent>
<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- if a password was entered then salt/hash it and add in the extra sql to save it --->
	<cfif IsDefined('form.password') AND form.password IS NOT "">
		<cfset HashedPassword = FLGen_CreateHash(Lcase(form.password))>
		<cfset SQLxUpdatePassword = ' , password = "#HashedPassword#" '>
	</cfif>
	<!--- copy --->
	<cfif form.ID GT 0 AND pgfn EQ 'copy'>
		<cflock name="admin_usersLock" timeout="10">
			<cftransaction>
				<cfquery name="AddAdminUser" datasource="#application.DS#">
					INSERT INTO #application.database#.admin_users
						(firstname, lastname, username, email, email_cc, program_ID, division_ID, password, created_user_ID, created_datetime)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.firstname#" maxlength="30">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.lastname#" maxlength="30">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.username#" maxlength="32">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.email#" maxlength="128">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.email_cc#" maxlength="128">,
						<cfif request.is_admin>
							<cfqueryparam cfsqltype="cf_sql_integer" value="#form.program_ID#">,
						<cfelse>
							<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
						</cfif>
						<cfqueryparam cfsqltype="cf_sql_integer" value="#division_ID#" null="#trim(division_ID) EQ ''#">,
						'#HashedPassword#',
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#')
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.admin_users
				</cfquery>
				<cfset new_user_ID = getID.MaxID>
			</cftransaction>
		</cflock>
		<cfquery name="FindUserAdminAccess" datasource="#application.DS#">
			SELECT al.ID AS this_access_ID
			FROM #application.database#.admin_level al
				LEFT JOIN #application.database#.admin_lookup lk ON al.ID = lk.access_level_ID 
			WHERE lk.user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.ID#" maxlength="10">
			ORDER BY al.sortorder ASC
		</cfquery>
		<cfloop query="FindUserAdminAccess">
			<cfquery name="InsertQuery" datasource="#application.DS#">
				INSERT INTO #application.database#.admin_lookup
					(created_user_ID, created_datetime, user_ID, access_level_ID)
				VALUES (
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
					'#FLGen_DateTimeToMySQL()#',
					<cfqueryparam cfsqltype="cf_sql_integer" value="#new_user_ID#" maxlength="10">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#this_access_ID#" maxlength="10">)
			</cfquery>
		</cfloop>
		<cfset pgfn = "list">
		<cfset alert_msg = "The new admin user was saved.">
	<!--- update --->
	<cfelseif form.ID GT 0>
		<cfquery name="UpdateAdminUser" datasource="#application.DS#">
			UPDATE #application.database#.admin_users
			SET	firstname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.firstname#" maxlength="30">,
				lastname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.lastname#" maxlength="30">,
				username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.username#" maxlength="32">,
				email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.email#" maxlength="128">,
				email_cc = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.email_cc#" maxlength="128">,
				<cfif request.is_admin>
					program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.program_ID#">,
				<cfelse>
					program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
				</cfif>
				division_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#division_ID#" null="#trim(division_ID) EQ ''#">
				#FLGen_UpdateModConcatSQL()#
				#SQLxUpdatePassword# 
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.ID#">
		</cfquery>
		<cfset pgfn = "list">
		<cfset alert_msg = Application.DefaultSaveMessage>
	<!--- add --->
	<cfelse>
		<cflock name="admin_usersLock" timeout="10">
			<cftransaction>
				<cfquery name="AddAdminUser" datasource="#application.DS#">
					INSERT INTO #application.database#.admin_users
						(firstname, lastname, username, email, email_cc, program_ID, password, created_user_ID, created_datetime)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.firstname#" maxlength="30">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.lastname#" maxlength="30">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.username#" maxlength="32">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.email#" maxlength="128">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.email_cc#" maxlength="128">,
						<cfif request.is_admin>
							<cfqueryparam cfsqltype="cf_sql_integer" value="#form.program_ID#">,
						<cfelse>
							<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
						</cfif>
						'#HashedPassword#',
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#')
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.admin_users
				</cfquery>
				<cfset ID = getID.MaxID>
			</cftransaction>
		</cflock>
		<cfset pgfn = "list">
		<cfset alert_msg = "The new admin user was saved.">
	</cfif>
</cfif>

<cfif pgfn EQ 'delete' and ID NEQ ''>
	<cfquery name="DeleteUser" datasource="#application.DS#">
		DELETE FROM #application.database#.admin_users
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		<cfif NOT request.is_admin>
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
		</cfif>
	</cfquery>
	<cfquery name="Access" datasource="#application.DS#">
		DELETE FROM #application.database#.admin_lookup
		WHERE user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
	</cfquery>
	<cfset pgfn = "list">
	<cfset alert_msg = "The admin user was deleted.">
</cfif>

<cfif pgfn EQ 'reset' and ID NEQ ''>
	<cfset new_password = FLGen_CreateHash(lcase(username))>
	<cfquery name="ResetUser" datasource="#application.DS#">
		UPDATE #application.database#.admin_users
		SET is_active = 0, password = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="32" value="#new_password#">
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		<cfif NOT request.is_admin>
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
		</cfif>
	</cfquery>
	<cfquery name="GetResetUser" datasource="#application.DS#">
		SELECT u.email, u.email_cc, u.firstname, u.lastname, IFNULL(p.company_name,"ITC") AS company 
		FROM #application.database#.admin_users u
		LEFT JOIN #application.database#.program p ON p.ID = u.program_ID
		WHERE u.ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		AND u.password =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#new_password#" maxlength="32">
	</cfquery>
	<cfif GetResetUser.recordcount NEQ 1>
		<cfset alert_msg = "An error occurred when resetting this users password.">
	<cfelse>
		<cfif application.OverrideEmail NEQ "">
			<cfset this_to = application.OverrideEmail>
			<cfset this_cc = application.OverrideEmail>
		<cfelse>
			<cfset this_to = GetResetUser.email>
			<cfset this_cc = GetResetUser.email_cc>
		</cfif>
		<cfmail from="#Application.DefaultEmailFrom#" to="#this_to#" cc="#this_cc#" subject="ITC Admin Password Reset" type="html">
			<cfif application.OverrideEmail NEQ "">
				Emails are being overridden.<br>
				Below is the email that would have been sent to #GetResetUser.email# and cc to #GetResetUser.email_cc#<br>
				<hr>
			</cfif>
			Dear #GetResetUser.firstname# #GetResetUser.lastname#,<br><br>
			Your administration account password for #GetResetUser.company# has been reset.<br><br>
			Click on the following link to create a new password:<br><br>
			<a href="#application.SecureWebPath#/admin/index.cfm?e=#GetResetUser.email#&v=#new_password#">Create New Password</a>
		</cfmail>
	</cfif>
	<cfset pgfn = "list">
	<cfset alert_msg = "The password has been reset and instructions to enter a new password has been sent to the user.">
</cfif>


<cfif pgfn EQ 'deactivate' and ID NEQ ''>
	<cfquery name="DeactivateUser" datasource="#application.DS#">
		UPDATE #application.database#.admin_users
		SET is_active = 0
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		<cfif NOT request.is_admin>
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
		</cfif>
	</cfquery>
	<cfset pgfn = "list">
	<cfset alert_msg = "The admin user was deactivated.">
</cfif>

<cfif pgfn EQ 'reactivate' and ID NEQ ''>
	<cfquery name="ReactivateUser" datasource="#application.DS#">
		UPDATE #application.database#.admin_users
		SET is_active = 1
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		<cfif NOT request.is_admin>
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
		</cfif>
	</cfquery>
	<cfset pgfn = "list">
	<cfset alert_msg = "The admin user was reactivated.">
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->
<cfsilent>
<cfif request.is_admin>
	<cfif pgfn EQ "add" OR pgfn EQ "edit" OR pgfn EQ "copy">
		<cfquery name="GetPrograms" datasource="#application.DS#">
			SELECT ID, company_name, program_name 
			FROM #application.database#.program
			WHERE is_active = 1
			AND parent_ID = 0
			ORDER BY company_name, program_name
		</cfquery>
	</cfif>
</cfif>

</cfsilent>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "admin_users">
<cfset request.main_width = 900>
<cfinclude template="includes/header.cfm">

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">
	<cfoutput>
	<span class="pagetitle"><cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0>Admin Users for #request.program.company_name# [#request.program.program_name#]<cfelseif request.is_admin>ITC Admin Users</cfif></span>
	<br /><br />
	<span class="pageinstructions">Delete users on their edit page.</span>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<cfif show_inactive>
		<a href="admin_user.cfm?show_inactive=false&filter_type=#filter_type#">Show only active users.</a>
	<cfelse>
		<a href="admin_user.cfm?show_inactive=true&filter_type=#filter_type#">Show inactive users.</a>
	</cfif>
	<br><br>
	<span class="pageinstructions">Users may be admin, CC approver or both.</span>
	<!--- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<cfif filter_type EQ "admin">
		Showing only admins.
	<cfelse>
		<a href="admin_user.cfm?show_inactive=#show_inactive#&filter_type=admin">Show only admins.</a>
	</cfif>
	&nbsp;&nbsp;&nbsp;
	<cfif filter_type EQ "approver">
		Showing only approvers.
	<cfelse>
		<a href="admin_user.cfm?show_inactive=#show_inactive#&filter_type=approver">Show only approvers.</a>
	</cfif>
	&nbsp;&nbsp;&nbsp;
	<cfif filter_type EQ "all">
		Showing all users.
	<cfelse>
		<a href="admin_user.cfm?show_inactive=#show_inactive#&filter_type=all">Show all users.</a>
	</cfif> --->
	<br /><br />
	</cfoutput>
	<cfset this_program_ID = admin_program_ID>
	<cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0>
		<cfset this_program_ID = request.selected_program_ID>
	</cfif>
	<cfquery name="SelectAdminUsers" datasource="#application.DS#">
		SELECT u.ID, u.firstname, u.lastname, u.username, u.program_ID, p.program_name, p.company_name, u.is_active, l.num_perms, c.num_ccs
		FROM #application.database#.admin_users u
		LEFT JOIN #application.database#.program p ON u.program_ID = p.ID
		LEFT JOIN (SELECT COUNT(ID) AS num_perms, user_ID FROM #application.database#.admin_lookup GROUP BY user_ID) l ON l.user_ID = u.ID
		LEFT JOIN (SELECT COUNT(ID) AS num_ccs, admin_user_ID FROM #application.database#.xref_cost_center_approvers GROUP BY admin_user_ID) c ON c.admin_user_ID = u.ID
		WHERE u.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_program_ID#">
		<cfif not show_inactive>
			AND u.is_active = 1
		</cfif>
		<!--- <cfif filter_type EQ "admin">
			AND (c.num_ccs IS NULL OR c.num_ccs = '')
		</cfif>
		<cfif filter_type EQ "approver">
			AND (l.num_perms IS NULL OR l.num_perms = '')
			AND c.num_ccs > 0
		</cfif> --->
		ORDER BY p.company_name, p.program_name, u.lastname ASC
	</cfquery>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<cfif SelectAdminUsers.recordcount GT 0>
		<tr class="contenthead">
		<td align="center"><a href="<cfoutput>#CurrentPage#?pgfn=add&show_inactive=#show_inactive#</cfoutput>">Add</a></td>
		<td class="headertext">Name</td>
		<td class="headertext">Username</td>
		<td class="headertext">Admin</td>
		<td class="headertext">Approver</td>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		</tr>
		<cfoutput query="SelectAdminUsers" group="program_ID">
			<!---<tr class="BGshowhide">
			<td>&nbsp;</td>
			<td colspan="3">
			<span class="program_headers"><cfif program_ID EQ admin_program_ID>#application.AdminName# Admin Users<cfelse>#company_name# [#program_name#]</cfif></span>
			</td>
			</tr>--->
			<cfoutput>
			<cfset show_delete = false>
			<tr class="#Iif(is_active EQ 1,de(Iif(((CurrentRow MOD 2) is 1),de('content2'),de('content'))), de('inactivebg'))#">
			<td><a href="#CurrentPage#?pgfn=edit&id=#ID#&show_inactive=#show_inactive#">Edit</a>&nbsp;&nbsp;<a href="#CurrentPage#?pgfn=copy&id=#ID#&show_inactive=#show_inactive#">Copy</a><cfif show_delete>&nbsp;&nbsp;<a href="#CurrentPage#?pgfn=delete&ID=#ID#&show_inactive=#show_inactive#" onclick="return confirm('Are you sure you want to delete this admin user?  There is NO UNDO.')">Delete</a></cfif></td>
			<td>#firstname# #lastname#</td>
			<td>#username#</td>
			<td><cfif isNumeric(num_perms) AND num_perms GT 0>yes<cfelse>no</cfif></td>
			<td><cfif isNumeric(num_ccs) AND num_ccs GT 0>yes<cfelse>no</cfif></td>
			<td><cfif FLGen_HasAdminAccess(1000000030)><a href="admin_user_access.cfm?userid=#ID#&show_inactive=#show_inactive#">Assign&nbsp;Access</a></cfif></td>
			<td><a href="#CurrentPage#?pgfn=reset&id=#ID#&username=#username#&show_inactive=#show_inactive#" onclick="return confirm('Are you sure you wish to send a `reset password` email to this admin user?')">Reset&nbsp;Password</a></td>
			</tr>
			</cfoutput>
		</cfoutput>
		<cfif SelectAdminUsers.recordcount MOD 2 EQ 1>
			<tr class="contenthead"><td colspan="100%"></td></tr>
		</cfif>
	<cfelse>
		<tr><td colspan="2" align="center" class="alert"><br><cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0>There are no admin users for <cfoutput>#request.program.company_name# [#request.program.program_name#]</cfoutput><cfelseif request.is_admin>There are no admin users</cfif> for your filter settings.
	</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<span class="pagetitle">
		<cfif pgfn EQ "add">
			Add an Admin User to
		<cfelse>
			Edit an Admin User in
		</cfif>
		<cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0>
			<cfoutput>#request.program.company_name# [#request.program.program_name#]</cfoutput>
		<cfelseif request.is_admin>
			<cfoutput>#application.adminName#</cfoutput>
		<cfelse>
			<cfabort showerror="This should not happen.  They are not an admin and have no program selected.  See Add or Edit in admin_user.cfm">
		</cfif>
	</span>
	<br /><br />
	<cfif pgfn EQ 'edit'>
	<span class="pageinstructions">Passwords are not retrievable.  If a password is forgotten, please set it to something new.</span>
	<br /><br />
	</cfif>
	<span class="pageinstructions">Return to <a href="<cfoutput>#CurrentPage#?show_inactive=#show_inactive#</cfoutput>">Admin User List</a> without making changes.</span>
	<br /><br />
	
	<cfif pgfn EQ "edit">
		<cfquery name="getUser" datasource="#application.DS#">
			SELECT ID, firstname, lastname, username, ID, email, email_cc, program_ID, is_active, division_ID 
			FROM #application.database#.admin_users
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">
			ORDER BY lastname ASC
		</cfquery>
		<cfset firstname = HTMLEditFormat(getUser.firstname)>
		<cfset lastname = HTMLEditFormat(getUser.lastname)>
		<cfset username = HTMLEditFormat(getUser.username)>
		<cfset email = HTMLEditFormat(getUser.email)>
		<cfset email_cc = HTMLEditFormat(getUser.email_cc)>
		<cfset division_ID = getUser.division_ID>
		<cfset program_ID = getUser.program_ID>
		<cfset is_active = getUser.is_active>
		<cfset ID = getUser.ID>
	<cfelse>
		<cfset firstname = "">
		<cfset lastname = "">
		<cfset username = "">
		<cfset email = "">
		<cfset email_cc = "">
		<cfset program_ID = 0>
		<cfset is_active = 1>
		<cfset ID = 0>
	</cfif>

	<!--- take the m=1 off the QS if it's already on there --->
	<cfset QueryString_nodupem = Replace(#CGI.QUERY_STRING#,"&m=1","")>
	<cfoutput>
	<form method="post" action="#CurrentPage#">
		<input type="hidden" name="show_inactive" value="#show_inactive#">
		<cfif pgfn EQ "edit">
			<span class="pageinstructions" style="display:block">
				<cfif CanDelete(ID)>
					<a href="#CurrentPage#?pgfn=delete&ID=#ID#&show_inactive=#show_inactive#" onclick="return confirm('Are you sure you want to delete this admin user?  There is NO UNDO.')">Delete</a>
				<cfelse>
					<cfif is_active>
						<a href="#CurrentPage#?pgfn=deactivate&ID=#ID#&show_inactive=#show_inactive#" onclick="return confirm('Are you sure you want to deactivate this admin user?')">Deactivate</a>&nbsp;&nbsp;&nbsp;This user <b>cannot be deleted</b> because they are linked with actions in the admin.  If you deactivate them, they will no longer appear on the Admin User list and they will no longer be able to login.
					<cfelse>
						<a href="#CurrentPage#?pgfn=reactivate&ID=#ID#&show_inactive=#show_inactive#" onclick="return confirm('Are you sure you want to reactivate this admin user?')">Reactivate</a>
					</cfif>
				</cfif>
			</span>
			<br>
		</cfif>
		<table cellpadding="5" cellspacing="1" border="0">
	
		<tr class="contenthead">
		<td colspan="2"><span class="headertext"><cfif pgfn EQ "add">Add an</cfif> Admin User <cfif pgfn EQ "edit">Edit</cfif></span></td>
		</tr>
		
		<tr class="content">
		<td align="right">First Name: </td>
		<td><input type="text" name="firstname" value="#firstname#" maxlength="30" size="40"></td>
		</tr>
		
		<tr class="content">
		<td align="right">Last Name: </td>
		<td><input type="text" name="lastname" value="#lastname#" maxlength="30" size="40"></td>
		</tr>
		
		<tr class="content">
		<td align="right">Username: </td>
		<td><input type="text" name="username" value="#username#" maxlength="30" size="40"></td>
		</tr>
		
		<cfif pgfn EQ "edit">
			<tr class="content2">
			<td align="right">&nbsp; </td>
			<td><img src="../pics/contrls-desc.gif"> Leave the password field blank to keep the user's current password.</td>
			</tr>
		</cfif>
		<tr class="content">
		<td align="right">Password: </td>
		<td><input type="text" name="password" maxlength="30" size="40"></td>
		</tr>

		<tr class="content">
		<td align="right">Email: </td>
		<td><input type="text" name="email" value="#email#" maxlength="30" size="40"></td>
		</tr>

		<tr class="content">
		<td align="right">CC Email: </td>
		<td><input type="text" name="email_cc" value="#email_cc#" maxlength="30" size="40"></td>
		</tr>

		<cfif request.is_admin>
			<tr class="content">
			<td align="right">Assign to this Program:</td>
			<td>
				<select name="program_ID">
					<option value=""> -- Select a Program -- </option>
					<option value="#admin_program_ID#" <cfif program_ID EQ admin_program_ID>selected</cfif>>#application.AdminName# Admin</option>
					<cfloop query="GetPrograms">
						<option value="#GetPrograms.ID#" <cfif program_ID EQ GetPrograms.ID>selected</cfif>>#GetPrograms.company_name# [#GetPrograms.program_name#]</option>
					</cfloop>
				</select>
			</td>
			</tr>
		</cfif>
		<cfif program_ID GT admin_program_ID> 
			<cfquery name="GetDivisions" datasource="#application.DS#">
				SELECT ID, company_name, program_name
				FROM #application.database#.program
				WHERE parent_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">
			</cfquery>
			<cfif GetDivisions.recordcount GT 0>
				<tr class="content">
				<td align="right">Assign to this Division:</td>
				<td>
					<select name="division_ID">
						<option value=""> -- All Divisions -- </option>
						<cfloop query="GetDivisions">
							<option value="#GetDivisions.ID#" <cfif division_ID EQ GetDivisions.ID>selected</cfif>>#GetDivisions.company_name#</option>
						</cfloop>
					</select>
				</td>
				</tr>
			</cfif>
		</cfif>
		<input type="hidden" name="ID" value="#ID#">
		<input type="hidden" name="firstname_required" value="Please enter a first name.">
		<input type="hidden" name="lastname_required" value="Please enter a last name.">
		<input type="hidden" name="username_required" value="Please enter a username.">
		<cfif pgfn EQ "add">
			<input type="hidden" name="password_required" value="Please enter a password.">
		</cfif>
		<input type="hidden" name="email_required" value="Please enter an email address.">
		<input type="hidden" name="pgfn" value="#pgfn#">

		<tr class="content">
		<td colspan="2" align="center"><input type="submit" name="submit" value="   Save Changes   " ></td>
		</tr>
		</table>
	</form>
	</cfoutput>
	<!--- END pgfn ADD/EDIT --->
<cfelseif pgfn EQ "copy">
	<!--- START pgfn COPY --->
	<span class="pagetitle">
		Copy an Admin User in
		<cfif isNumeric(request.selected_program_ID) AND request.selected_program_ID GT 0>
			<cfoutput>#request.program.company_name# [#request.program.program_name#]</cfoutput>
		<cfelseif request.is_admin>
			<cfoutput>#application.adminName#</cfoutput>
		<cfelse>
			<cfabort showerror="This should not happen.  They are not an admin and have no program selected.  See Copy in admin_user.cfm">
		</cfif>
	</span>
	<br /><br />
	<span class="pageinstructions"><span class="alert">!</span> You are adding a new user with the selected user's adminstrative access privledges.</span>
	<br /><br />
	<span class="pageinstructions">Please enter a unique username and password for this new user.</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="<cfoutput>#CurrentPage#?show_inactive=#show_inactive#</cfoutput>">Admin User List</a> without making changes.</span>
	<br /><br />

	<cfparam name="firstname" default="">
	<cfparam name="lastname" default="">
	<cfparam name="username" default="">
	<cfparam name="email" default="">
	<cfparam name="email_cc" default="">
	<cfparam name="program_ID" default="">
	<cfparam name="ID" default="">	

	<cfquery name="EditAdminUsers" datasource="#application.DS#">
		SELECT ID, firstname, lastname, username, ID, email, email_cc, program_ID 
		FROM #application.database#.admin_users
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">
		ORDER BY lastname ASC
	</cfquery>
	<cfset firstname = HTMLEditFormat(EditAdminUsers.firstname)>
	<cfset lastname = HTMLEditFormat(EditAdminUsers.lastname)>
	<cfset username = HTMLEditFormat(EditAdminUsers.username)>
	<cfset email = HTMLEditFormat(EditAdminUsers.email)>
	<cfset email_cc = HTMLEditFormat(EditAdminUsers.email_cc)>
	<cfset program_ID = HTMLEditFormat(EditAdminUsers.program_ID)>
	<cfset ID = HTMLEditFormat(EditAdminUsers.ID)>	

	<cfoutput>
	<form method="post" action="#CurrentPage#">
		<input type="hidden" name="show_inactive" value="#show_inactive#">
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		
		<tr class="contenthead">
		<td colspan="2"><span class="headertext">Copy an Admin User</span></td>
		</tr>
		
		<tr class="content">
		<td align="right">First Name: </td>
		<td width="100%"><input type="text" name="firstname" value="COPY-#firstname#" maxlength="30" size="40"></td>
		</tr>
		
		<tr class="content">
		<td align="right">Last Name: </td>
		<td><input type="text" name="lastname" value="COPY-#lastname#" maxlength="30" size="40"></td>
		</tr>
		
		<tr class="content">
		<td align="right">Username: </td>
		<td><input type="text" name="username" value="" maxlength="30" size="40"></td>
		</tr>
		
		<tr class="content">
		<td align="right">Password: </td>
		<td><input type="text" name="password" value="" maxlength="30" size="40"></td>
		</tr>
	
		<tr class="content">
		<td align="right">Email: </td>
		<td><input type="text" name="email" maxlength="30" size="40"></td>
		</tr>
		
		<tr class="content">
		<td align="right">CC Email: </td>
		<td><input type="text" name="email_cc" maxlength="30" size="40"></td>
		</tr>
		
		<cfif request.is_admin>
			<tr class="content">
			<td align="right">Assign to this Program:</td>
			<td>
				<select name="program_ID">
					<option value=""> -- Select a Program -- </option>
					<option value="#admin_program_ID#" <cfif program_ID EQ admin_program_ID>selected</cfif>>#application.AdminName# Admin</option>
					<cfloop query="GetPrograms">
						<option value="#GetPrograms.ID#" <cfif program_ID EQ GetPrograms.ID>selected</cfif>>#GetPrograms.company_name# [#GetPrograms.program_name#]</option>
					</cfloop>
				</select>
			</td>
			</tr>
		</cfif>
		
		<input type="hidden" name="ID" value="#ID#">
		<input type="hidden" name="firstname_required" value="Please enter a first name.">
		<input type="hidden" name="lastname_required" value="Please enter a last name.">
		<input type="hidden" name="username_required" value="Please enter a username.">
		<cfif pgfn EQ "add">
			<input type="hidden" name="password_required" value="Please enter a password.">
		</cfif>
		<input type="hidden" name="email_required" value="Please enter an email address.">
		<input type="hidden" name="pgfn" value="#pgfn#">
			
		<tr class="content">
		<td colspan="2" align="center"><input type="submit" name="submit" value="   Save Changes   " ></td>
		</tr>
			
		<cfquery name="FindUserAdminAccess" datasource="#application.DS#">
			SELECT al.ID, al.level_name, al.sortorder, IFNULL(al.note,"(no note)") AS note, al.sortorder
			FROM #application.database#.admin_level al
				LEFT JOIN #application.database#.admin_lookup lk ON al.ID = lk.access_level_ID 
			WHERE lk.user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">
				OR TRIM(al.note) = 'header'
			ORDER BY al.sortorder ASC
		</cfquery>
		
		<tr class="content">
		<td align="right" valign="top">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Admin&nbsp;Access: <br><br>Bold headers are displayed even if user has no assigned access under that header.</td>
		<td><cfloop query="FindUserAdminAccess"><cfif note EQ 'header'><b></cfif>#level_name#<cfif note EQ 'header'></b></cfif><br></cfloop></td>
		</tr>
		</table>
	</form>
	</cfoutput>
	<!--- END pgfn COPY --->

</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->

<cffunction name="CanDelete" output="false" returntype="boolean">
	<cfargument name="userID" required="yes">
	<cfset var CheckQuery = "">
	<cfset var TablesToCheck = "admin_level,admin_lookup,admin_users,awards_points,email_alerts,email_groups,email_template,image_content,inventory,manuf_logo,product,product_meta,product_meta_group,product_meta_group_lookup,product_meta_option,product_meta_option_category,product_option,productvalue_master,productvalue_program,program,program_login,program_product_exclude,program_user,program_user_category,purchase_order,subprogram,subprogram_points,survey,vendor,vendor_lookup,xref_alerts_users,xref_image_program,xref_program_email_template,xref_user_category,xref_user_emailgroup">
	<cfset var thisTable = "">
	<!--- check every table for activity --->
	<cfloop list="#TablesToCheck#" index="thisTable">
		<cfquery name="CheckQuery" datasource="#application.DS#">
			SELECT Count(ID) AS current_count
			FROM #application.database#.#thisTable#
			WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
		</cfquery>
		<cfif CheckQuery.current_count GT 0>
			<cfreturn false>
		</cfif>
	</cfloop>
	<cfreturn true>
</cffunction>
