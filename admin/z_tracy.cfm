<!--- <cfabort showerror="Please do not run this file."> --->
<cfsetting requesttimeout="300" >
<cfinclude template="../includes/function_library_local.cfm">

<!--- --->
<!--- Compare spreadsheet for ITG users --->
<!--- --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	select program<cfabort>
</cfif>

<cfspreadsheet action="read" src="upload/ITG Employees.xlsx" query="GetFile1" rows="2-2584">

<!--- In Spreadsheet, but not in System:<br>
<cfloop query="GetFile1">
	<cfset user = LCase(GetFile1.col_1)>
	<cfset name = LCase(GetFile1.col_2)>
	<cfset email = LCase(GetFile1.col_10)>
	<cfquery name="GetUsers" datasource="#application.DS#">
		SELECT ID, badge_id, username, lname, fname, email
		FROM #application.database#.program_user
		WHERE program_ID = #request.selected_program_ID#
		AND is_active = 1
		AND ( 1=0
			<cfif trim(user) NEQ ''> OR username = '#user#' </cfif>
			<cfif trim(user) NEQ ''> OR badge_id = '#user#' </cfif>
			<cfif trim(email) NEQ ''> OR email = '#email#' </cfif>
		)
	</cfquery>
	<cfif GetUsers.recordcount EQ 0>
		<cfoutput>
		#user# - #name# - #email#<cfif trim(email) EQ ''>[no email address]</cfif><br>
		</cfoutput>
	</cfif>
</cfloop>
<br><br> --->

<!--- In Spreadsheet, and found multiple users in System:<br>
<cfloop query="GetFile1">
	<cfset user = LCase(GetFile1.col_1)>
	<cfset name = LCase(GetFile1.col_2)>
	<cfset email = LCase(GetFile1.col_10)>
	<cfquery name="GetUsers" datasource="#application.DS#">
		SELECT ID, badge_id, username, lname, fname, email
		FROM #application.database#.program_user
		WHERE program_ID = #request.selected_program_ID#
		AND is_active = 1
		AND ( 1=0
			<cfif trim(user) NEQ ''> OR username = '#user#' </cfif>
			<cfif trim(user) NEQ ''> OR badge_id = '#user#' </cfif>
			<cfif trim(email) NEQ ''> OR email = '#email#' </cfif>
		)
	</cfquery>
	<cfif GetUsers.recordcount GT 1>
		<cfoutput>
		#user# - #name# - #email#<cfif trim(email) EQ ''>[no email address]</cfif><br>
		<cfloop query="GetUsers">
			#GetUsers.ID# - #GetUsers.username# - #GetUsers.badge_id# - #GetUsers.lname#, #GetUsers.fname# - #GetUsers.email#<br>
		</cfloop>
		<br>
		</cfoutput>
	</cfif>
</cfloop>
<br><br> --->


<!--- In System, but not in Spreadsheet:<br>

<cfquery name="GetUsers" datasource="#application.DS#">
	SELECT badge_id, username, lname, fname, email
	FROM #application.database#.program_user
	WHERE program_ID = #request.selected_program_ID#
	AND is_active = 1
</cfquery>

<cfloop query="GetUsers">
	<cfset user = LCase(GetUsers.username)>
	<cfset badge = LCase(GetUsers.badge_id)>
	<cfset email = LCase(GetUsers.email)>
	<cfquery name="File1" dbtype="query">
		SELECT * FROM GetFile1
		WHERE LOWER(col_10) = '#email#'
		OR LOWER(col_1) = '#user#'
		OR LOWER(col_1) = '#badge#'
	</cfquery>
	<cfif File1.recordcount EQ 0>
		<cfoutput>
		#user# - #badge# - #lname#, #fname# - #email#<br>
		</cfoutput>
	</cfif>
</cfloop>
<br><br> --->

In System, and multiples found in Spreadsheet:<br>
<cfquery name="GetUsers" datasource="#application.DS#">
	SELECT badge_id, username, lname, fname, email
	FROM #application.database#.program_user
	WHERE program_ID = #request.selected_program_ID#
	AND is_active = 1
</cfquery>

<cfloop query="GetUsers">
	<cfset user = LCase(GetUsers.username)>
	<cfset badge = LCase(GetUsers.badge_id)>
	<cfset email = LCase(GetUsers.email)>
	<cfquery name="File1" dbtype="query">
		SELECT * FROM GetFile1
		WHERE 1=0
			<cfif trim(email) NEQ ''> OR LOWER(col_10) = '#email#'</cfif>
			<cfif trim(user) NEQ ''> OR LOWER(col_1) = '#user#' </cfif>
			<cfif trim(badge) NEQ ''>OR LOWER(col_1) = '#badge#' </cfif>
	</cfquery>
	<cfif File1.recordcount GT 1>
		<cfoutput>
		#user# - #badge# - #GetUsers.lname#, #GetUsers.fname# - #email#<br>
		<cfloop query="File1">
			#File1.col_1# - #File1.col_2# - #File1.col_10#<br>
		</cfloop>
		<br>
		</cfoutput>
	</cfif>

</cfloop>
<br><br>



<!--- --->
<!--- Set up KCG users for cost centers and create the approvers --->
<!--- --->
<!--- 

<cfset this_program_ID = 1000000096>
<cfset this_permission = 1000000116>

<!--- Import KCG cost center users --->
<cfquery name="GetUsers" datasource="#application.DS#">
	SELECT
		u.ID as user_ID,
		u.program_ID,
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
	LEFT JOIN #application.database#.program_user u ON u.email = t.email
	WHERE TRIM(t.email) != ''
</cfquery>
<!---<cfdump var="#GetUsers#">--->
<cfoutput>
<cfloop query="GetUsers">
	<cfset this_user_ID = 0>
	<cfset this_cc_number = "">
	<cfset this_cc_desc = "">
	<!---<cfif GetUsers.user_ID EQ ''>--->
	<!---</cfif>--->
	<cfif GetUsers.program_ID NEQ '' AND GetUsers.program_ID neq this_program_ID>
		ERROR!  #GetUsers.email# in wrong program. (#GetUsers.program_ID#)
		<cfabort showerror="Error Occurred!" >
	<cfelseif GetUsers.mc_lastname EQ '' OR GetUsers.mc_firstname EQ '' OR GetUsers.mc_email EQ '' OR GetUsers.mgr_lastname EQ '' OR GetUsers.mgr_firstname EQ '' OR GetUsers.mgr_email EQ ''>>
		No approver for  #GetUsers.email#.
		<cfabort showerror="Error Occurred!" >
	<cfelseif GetUsers.user_ID NEQ ''>
		#GetUsers.firstname# #GetUsers.lastname# - #GetUsers.email#:<br>
		<cfset this_user_ID = GetUsers.user_ID>
		<cfset this_cc_number = trim(GetUsers.cc_code)>
		<cfset this_cc_desc = trim(GetUsers.cc_desc)>
		<cfset this_mgr_username = ListFirst(GetUsers.mgr_email,'@')>
		<cfset this_mgr_lastname = trim(GetUsers.mgr_lastname)>
		<cfset this_mgr_firstname = trim(GetUsers.mgr_firstname)>
		<cfset this_mgr_email = trim(GetUsers.mgr_email)>
		<cfset this_mgr_password = FLGen_CreateHash(Lcase(this_mgr_username))>
		<cfset this_mc_username = ListFirst(GetUsers.mc_email,'@')>
		<cfset this_mc_lastname = trim(GetUsers.mc_lastname)>
		<cfset this_mc_firstname = trim(GetUsers.mc_firstname)>
		<cfset this_mc_email = trim(GetUsers.mc_email)>
		<cfset this_mc_password = FLGen_CreateHash(Lcase(this_mc_username))>
		<!---<cfset ProgramUserInfo(this_user_ID)>
		<cfif user_totalpoints GT 0>
			Points: #user_totalpoints#
		</cfif>
		Updating...
		<br>--->
	<cfelse>
		<!---They need to register...<br>
		<cfquery name="GetUser" datasource="#application.DS#">
			SELECT username, fname, lname, email, is_active
			FROM #application.database#.program_user
			WHERE program_ID = #this_program_ID# 
			AND lname = '#GetUsers.lastname#'
		</cfquery>
		<cfif GetUser.recordcount> 
			<cfdump var="#GetUser#">
		</cfif>--->
	</cfif>
	<cfif this_user_ID GT 0 AND this_cc_number NEQ "">
		<cfset this_cc_ID = 0>
		<!---Look up cost center--->
		<cfquery name="GetCostCenter" datasource="#application.DS#">
			SELECT ID
			FROM #application.database#.cost_centers
			WHERE program_ID = #this_program_ID# 
			AND number = '#this_cc_number#'
		</cfquery>
		CC #this_cc_number#
		<cfif GetCostCenter.recordcount EQ 1>
			<cfset this_cc_ID = GetCostCenter.ID>
			Found: 
		<cfelse>
			Added:
			<cfquery name="AddCostCenter" datasource="#application.DS#" result="stResult">
				INSERT INTO #application.database#.cost_centers
					(created_user_ID, created_datetime, program_ID, number, description)
				VALUES
					(1212121212, NOW(), #this_program_ID#, '#this_cc_number#', '#this_cc_desc#')
			</cfquery>
			<cfset this_cc_ID = stResult.GENERATED_KEY>
		</cfif>
		#this_cc_ID#
		<!--- Look up mgr_email in admin_users --->
		<cfset this_mgr_ID = 0>
		<cfquery name="GetMgr" datasource="#application.DS#">
			SELECT ID
			FROM #application.database#.admin_users
			WHERE username = '#this_mgr_username#'
		</cfquery>
		Mgr #this_mgr_username#
		<cfif GetMgr.recordcount EQ 1>
			<cfset this_mgr_ID = GetMgr.ID>
			Found: 
		<cfelse>
			Added:
			<cfquery name="AddMgr" datasource="#application.DS#" result="stResult">
				INSERT INTO #application.database#.admin_users
					(created_user_ID, created_datetime, firstname, lastname, username, password, email, program_ID, is_active)
				VALUES
					(1212121212, NOW(), '#this_mgr_firstname#', '#this_mgr_lastname#', '#this_mgr_username#', '#this_mgr_password#', '#this_mgr_email#', #this_program_ID#, 0)
			</cfquery>
			<cfset this_mgr_ID = stResult.GENERATED_KEY>
			<cfquery name="AddPerm" datasource="#application.DS#">
				INSERT INTO #application.database#.admin_lookup
					(created_user_ID, created_datetime, user_ID, access_level_ID)
				VALUES
					(1212121212, NOW(), #this_mgr_ID#, #this_permission#)
			</cfquery>
		</cfif>
		#this_mgr_ID# <!--- This is level 1 approver --->
		<cftry>
		<cfquery name="AddMgrToCC" datasource="#application.DS#">
			INSERT INTO #application.database#.xref_cost_center_approvers
				(cost_center_ID, admin_user_ID, level)
			VALUES
				(#this_CC_ID#, #this_mgr_ID#, 1)
		</cfquery>
		<cfcatch></cfcatch></cftry>
		<!--- Look up mc_email in admin_users --->
		<cfset this_mc_ID = 0>
		<cfquery name="GetMc" datasource="#application.DS#">
			SELECT ID
			FROM #application.database#.admin_users
			WHERE username = '#this_mc_username#'
		</cfquery>
		Mc #this_mc_username#
		<cfif GetMc.recordcount EQ 1>
			<cfset this_mc_ID = GetMc.ID>
			Found: 
		<cfelse>
			Added:
			<cfquery name="AddMc" datasource="#application.DS#" result="stResult">
				INSERT INTO #application.database#.admin_users
					(created_user_ID, created_datetime, firstname, lastname, username, password, email, program_ID, is_active)
				VALUES
					(1212121212, NOW(), '#this_mc_firstname#', '#this_mc_lastname#', '#this_mc_username#', '#this_mc_password#', '#this_mc_email#', #this_program_ID#, 1)
			</cfquery>
			<cfset this_mc_ID = stResult.GENERATED_KEY>
			<cfquery name="AddPerm" datasource="#application.DS#">
				INSERT INTO #application.database#.admin_lookup
					(created_user_ID, created_datetime, user_ID, access_level_ID)
				VALUES
					(1212121212, NOW(), #this_mc_ID#, #this_permission#)
			</cfquery>
		</cfif>
		#this_mc_ID# <!--- This is level 2 approver --->
		<cftry>
		<cfquery name="AddMcToCC" datasource="#application.DS#">
			INSERT INTO #application.database#.xref_cost_center_approvers
				(cost_center_ID, admin_user_ID, level)
			VALUES
				(#this_CC_ID#, #this_mc_ID#, 2)
		</cfquery>
		<cfcatch></cfcatch></cftry>
		<!--- Check if user is in cost center --->
		<cftry>
		<cfquery name="AddUserToCC" datasource="#application.DS#">
			INSERT INTO #application.database#.xref_cost_center_users
				(cost_center_ID, program_user_ID)
			VALUES
				(#this_CC_ID#, #this_user_ID#)
		</cfquery>
		<cfcatch></cfcatch></cftry>
		<!--- Mark user as uses_cost_center = 1 --->
		<cfquery name="UpdateUser" datasource="#application.DS#">
			UPDATE #application.database#.program_user
			SET uses_cost_center = 2
			WHERE ID = #this_user_ID#
		</cfquery>
		<br>
	</cfif>
</cfloop>
</cfoutput>
--->






<!--- --->
<!--- GETCO Update points for expired users --->
<!--- --->
<!--- 
<cfquery name="GetUsers" datasource="#application.DS#">
	SELECT u.ID, u.username, e.first, e.last, e.points
	FROM getco_expiring e
	LEFT JOIN program_user u ON u.fname = e.first AND u.lname = e.last
	WHERE u.program_ID = 1000000087
	AND u.is_active = 1
</cfquery>
<cfoutput>
<table>
<tr><td>username</td><td>name</td><td>spreadsheet</td><td>system (points * 2) </td><td>points +/-</td>
<cfloop query="GetUsers">
	<cfset ProgramUserInfo(GetUsers.ID)>
	<cfset total = user_totalpoints * 2>
	<cfset updatePoints = int((GetUsers.points - total) / 2)>
	<cfif updatePoints neq 0>
		<cfquery name="UpdateAwardsPoints" datasource="#application.DS#">
			INSERT INTO #application.database#.awards_points
				(created_user_ID, created_datetime, user_ID, points, notes)
			VALUES
				(1212121212, '2012-09-02 08:50:00', #GetUsers.ID#, #updatePoints#, 'Eric\'s Spreadsheet Adjustment')
		</cfquery>
	</cfif>
	<tr>
		<td>#GetUsers.username#</td>
		<td>#GetUsers.last#, #GetUsers.first#</td>
		<td align="right">#GetUsers.points#</td>
		<td align="right">#total#</td>
		<td align="right">#updatePoints#</td>
	</tr>
</cfloop>
</table>
<br /><br />
Done!
</cfoutput>

--->
<!--- authenticate the admin user
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000008,true)>

<cfquery name="GetMeta" datasource="#application.DS#">
	SELECT ID FROM product_meta where ID NOT IN (SELECT product_meta_ID FROM product_meta_group_lookup)
</cfquery>
<cfset IDList = ValueList(GetMeta.ID)>
<cfset thisGroup = "1000000028">

<cfloop list="#IDList#" index="thisMeta">
	<cfquery name="GetExisting" datasource="#application.DS#">
		SELECT ID FROM product_meta_group_lookup
		WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#thisMeta#" maxlength="10">
		AND product_meta_group_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#thisGroup#" maxlength="10">
	</cfquery>
	<cfif GetExisting.recordcount EQ 0>
		<cfquery name="InsertGroupLookup" datasource="#application.DS#">
			INSERT INTO #application.database#.product_meta_group_lookup
			(created_user_ID, created_datetime, product_meta_ID, product_meta_group_ID)
			VALUES
			(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
			 '#FLGen_DateTimeToMySQL()#',
			  <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#thisMeta#" maxlength="10">,
			 <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#thisGroup#" maxlength="10">)			
		</cfquery>
	</cfif>
</cfloop>
 --->
<br><br> 
EOF!
