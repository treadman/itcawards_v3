<!--- Merge deactivated imported Lorillard Driving Excellence users --->

<cfsetting requesttimeout="500">

<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<cfset request.selected_program_ID = 1000000100>
<cfset request.selected_database = 'ITCAwards_v3'>

<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000014-1000000020",true)>

<cfparam name="pgfn" default="list">
<cfparam name="phase" default="merge">

<cfparam name="w2_id" default="">
<cfparam name="w3_id" default="">

<cfparam name="skip_names" default="">
<cfparam name="skip_it" default="">

<cfset message = "">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->
		
<cfif IsDefined('form.doMerge') AND isNumeric(w2_id) AND isNumeric(w3_id)>
<cfset ok = true>
	<cfquery name="get_w2_user" datasource="#application.DS#">
		SELECT username, cc_max
		FROM #request.selected_database#.program_user
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#w2_id#">
	</cfquery>
	<cfset w2_username=get_w2_user.username>
	<cfif get_w2_user.cc_max NEQ 1>
		<cfset message = message & "You selected a www3 for a www2!<br>">
		<cfset ok = false>
	</cfif>
	<cfquery name="get_w3_user" datasource="#application.DS#">
		SELECT username, cc_max
		FROM #request.selected_database#.program_user
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#w3_id#">
	</cfquery>
	<cfif get_w3_user.cc_max NEQ 0>
		<cfset message = message & "You selected a www2 for a www3!<br>">
		<cfset ok = false>
	</cfif>
	<cfif ok>
	<cfquery name="w2_points" datasource="#application.DS#">
		UPDATE #request.selected_database#.awards_points
		SET modified_concat=user_ID, user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#w3_id#">
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#w2_id#">
	</cfquery>
	<cfquery name="w2_user" datasource="#application.DS#">
		UPDATE #request.selected_database#.program_user
		SET username=concat(username,'|merged to user_id: ',#w3_id#), is_active = 0
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#w2_id#">
	</cfquery>
	<cfquery name="w3_user" datasource="#application.DS#">
		UPDATE #request.selected_database#.program_user
		SET badge_id='#w2_username#'
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#w3_id#">
	</cfquery>
	</cfif>
</cfif>

<cfif isDefined('form.doSkip') AND skip_it NEQ "">
	<cfset skip_names = ListAppend(skip_names,skip_it)>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "program_user">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Program Users</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<br>
<br />

<cfelse>
<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT lname
		FROM #request.selected_database#.program_user
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND is_active = '1'
		<cfif skip_names NEQ "">
			AND lname NOT IN (<cfqueryparam list="true" value="#skip_names#">)
		</cfif>
		ORDER BY lname, fname, cc_max
	</cfquery>
	<cfset sub_total = SelectList.recordCount>
	<cfset cnt_total = 0>
		<cfset this_lname = "FIRST_TIME">
		<cfset count = 0>
		<!--- display found records --->
		<cfloop query="SelectList">
			<cfset cnt_total = cnt_total + 1>
			<cfif this_lname EQ "FIRST_TIME">
				<cfset this_lname = SelectList.lname>
				<cfset count = 1>
			<cfelse>
				<cfif this_lname NEQ SelectList.lname>
					<cfif count GT 1>
						<cfbreak>
					<cfelse>
						<cfset this_lname = SelectList.lname>
						<cfset count = 1>
					</cfif>
				<cfelse>
					<cfset count = count + 1>
				</cfif>
			</cfif>
		</cfloop>


<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ID, username, fname, lname, email, If(is_active = 1,"active","inactive") AS is_active, cc_max, defer_allowed, IF(is_done=1,"ordered","not ordered") AS is_done
		FROM #request.selected_database#.program_user
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND is_active = '1'
		and lname = '#this_lname#'
		ORDER BY lname, fname, cc_max
	</cfquery>

<cfoutput>
<span class="pagetitle">Merge www2 users for #request.program_name#</span>
<br /><br />
<form method="post" action="#CurrentPage#">
	<input type="hidden" name="skip_it" value="#this_lname#">
	<input type="hidden" name="skip_names" value="#skip_names#">
	<br><br>
	<cfif phase EQ "merge">
		<input type="submit" name="doMerge" value="   Merge Selections   " >
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
		<input type="submit" name="doSkip" value="   Skip #this_lname#   " >
	</cfif>
<br><br>
<cfif message neq ''>
	<span class="alert">#message#</span>
	<br><br>
</cfif>
#cnt_total# of #sub_total#<br><br>
<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="100%" align="center"><span class="alert"><br />No records found.  Click "view all" to see all records.<br /><br /></span></td>
		</tr>
	<cfelse>
		<!--- display found records --->
		<cfloop query="SelectList">
			
	<!--- check to see if this username is already in use for this program --->
	<cfquery name="AnyDuplicateUsernames2" datasource="#application.DS#">
		SELECT ID
		FROM #request.selected_database#.program_user
		WHERE 
		(
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SelectList.username#">
			OR badge_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SelectList.username#">
		)
		AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND ID <> <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.ID#">
	</cfquery>
	<cfif AnyDuplicateUsernames2.recordCount gt 0>
		<tr><td colspan="100%" class="alert"><cfdump var="#AnyDuplicateUsernames2#"> DUPLICATE 2!</td></tr><cfabort>
	</cfif>
			<tr class="#Iif(is_active EQ "active",de(Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))), de('inactivebg'))#">
				<td>
					<span class="sub">www<cfif SelectList.cc_max EQ 0>3<cfelse>2</cfif></span>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
					<input type="radio" name="w3_id" value="#SelectList.ID#" <cfif SelectList.cc_max EQ 0>checked</cfif>> www3
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
					<input type="radio" name="w2_id" value="#SelectList.ID#" <cfif SelectList.cc_max EQ 1>checked</cfif>> www2
				</td>
				<td valign="top" colspan="3">#HTMLEditFormat(username)#<br />#HTMLEditFormat(fname)#&nbsp;#HTMLEditFormat(lname)#<br />#HTMLEditFormat(email)# </td>
				<cfif request.program.is_one_item EQ 0>

			<!--- look in the points database for the starting point amount --->
	<cfquery name="PosPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM(points),0) AS pos_pt
		FROM #request.selected_database#.awards_points
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.ID#">
		AND is_defered = 0
	</cfquery>
	<!--- look in the order database for orders/points_used --->
	<cfquery name="NegPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) AS neg_pt
		FROM #request.selected_database#.order_info
		WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.ID#">
		AND is_valid = 1
	</cfquery>
	<!--- find defered points --->
	<cfquery name="DefPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM(points),0) AS def_pt
		FROM #request.selected_database#.awards_points
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.ID#">
		AND is_defered = 1
	</cfquery>
	<cfset user_awardedpoints = PosPoints.pos_pt>
	<cfset user_usedpoints = NegPoints.neg_pt>
	<cfset user_totalpoints = user_awardedpoints - user_usedpoints>
	<cfset user_deferedpoints = DefPoints.def_pt>
	<cfif user_deferedpoints GT 0>
		<tr><td colspan="100%" class="alert">User def points!</td></tr><cfabort>
	</cfif>



	
						<td valign="middle" align="right">#user_totalpoints#</td>
				</cfif>
				<cfif request.program.accepts_cc EQ 1>
				<td valign="top" align="right"><span class="sub">$#cc_max#</span></td>
				</cfif>
				<cfif request.program.is_one_item GT 0>
				<td valign="top" align="right"><span class="sub">#is_done#</span>
				<br>
				</td>
				</cfif>
			</tr>
		</cfloop>
	</cfif>
</table>
</form>
</cfoutput>
<br />

	<!--- END pgfn LIST --->
<cfelse>
	<br><br>Done!<br><br>
</cfif>
</cfif>

<cfinclude template="includes/footer.cfm">












<cfabort>
<cfabort showerror="itg_w2_import.cfm has already been done.">
<cfsetting requesttimeout="500">
<!--- 


<cfset has_program = true>
<cfset request.program_selected_program_ID = 1000000035>
<cfset request.selected_program_ID = 1000000035>
<cfset request.target_program_ID = 1000000100>


Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<cfset request.selected_program_ID = 1000000035>
<cfset request.selected_database = 'ITCAwards'>

<cfset request.target_program_ID = 1000000100>
<cfset request.target_database = application.database>

<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000014-1000000020",true)>

<cfparam name="pgfn" default="list">
<cfparam name="phase" default="users">
<cfparam name="message" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.doUsers')>
	<!---
		2639 in www3
		 970 in www2
		3609	
	--->
	<cfquery result="result" datasource="#application.DS#" name="InsertQuery">
		INSERT INTO #request.target_database#.program_user
			(created_user_ID, created_datetime, modified_concat, program_ID, username, nickname, fname, lname, ship_company, ship_fname, ship_lname, ship_address1, ship_address2, ship_city, ship_state, ship_zip, ship_country, phone, email, bill_company, bill_fname, bill_lname, bill_address1, bill_address2, bill_city, bill_state, bill_zip, cc_max, is_active, is_done, defer_allowed, expiration_date, entered_by_program_admin, supervisor_email, level_of_award)
		SELECT
			created_user_ID, created_datetime, modified_concat, 1000000100, username, nickname, fname, lname, ship_company, ship_fname, ship_lname, ship_address1, ship_address2, ship_city, ship_state, ship_zip, ship_country, phone, email, bill_company, bill_fname, bill_lname, bill_address1, bill_address2, bill_city, bill_state, bill_zip, 1, is_active, is_done, defer_allowed, expiration_date, entered_by_program_admin, supervisor_email, level_of_award
		FROM #request.selected_database#.program_user
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND is_active = 1
	</cfquery>
	<cfset message = "Imported #ListLen(result.generatedkey)# users.">
	<cfset phase="points">
</cfif>

<cfif IsDefined('form.doPoints')>

	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT a.ID AS www2_ID, b.ID AS www3_ID
		FROM #request.selected_database#.program_user a
		LEFT JOIN #request.target_database#.program_user b ON b.username = a.username
		WHERE a.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND a.is_active = '1'
		ORDER BY a.username ASC
	</cfquery>
	<cfset total_num = 0>
	<cfset total_pts = 0>
	<!--- display found records --->
	<cfloop query="SelectList">
		<cfquery name="PosPoints" datasource="#application.DS#">
			SELECT IFNULL(SUM(points),0) AS pos_pt
			FROM #request.selected_database#.awards_points
			WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.www2_ID#">
			AND is_defered = 0
		</cfquery>
		<!--- look in the order database for orders/points_used --->
		<cfquery name="NegPoints" datasource="#application.DS#">
			SELECT IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) AS neg_pt, IFNULL(SUM(cc_charge),0) AS neg_cc
			FROM #request.selected_database#.order_info
			WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.www2_ID#">
			AND is_valid = 1
		</cfquery>
		<cfset user_awardedpoints = PosPoints.pos_pt>
		<cfset user_usedpoints = NegPoints.neg_pt>
		<cfset user_totalpoints = user_awardedpoints - user_usedpoints>
		<cfif user_totalpoints NEQ 0>
			<cfset this_notes = 'Imported from www2 <a href="https://www2.itcawards.com/admin/program_points.cfm?puser_ID=#SelectList.www2_ID#&xxS=username&xxA=&xxL=&xxT=&program_ID=1000000035&show_zip=all" target="_blank">View History</a>'>
			<cfquery name="InsertPoints" datasource="#application.DS#" result="result">
				INSERT INTO #request.target_database#.awards_points
					(created_user_ID, created_datetime, user_ID, points, notes, division_ID)
				VALUES (
					'#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#', #SelectList.www3_ID#, #user_totalpoints#, '#this_notes#', 1000000109
					)
			</cfquery>
			<cfset total_num = total_num +1>
			<cfset total_pts = total_pts + user_totalpoints>
		</cfif>
	</cfloop>
	<cfset message = "Imported #total_pts# points for #total_num# users, out of #SelectList.recordCount#.<br><br>The rest had none.">
	<cfset pgfn="done">
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "program_user">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Program Users</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<br>
<cfoutput>#message#</cfoutput>
<br />

<cfelse>
<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ID, username, fname, lname, email, If(is_active = 1,"active","inactive") AS is_active, cc_max, defer_allowed, IF(is_done=1,"ordered","not ordered") AS is_done
		FROM #request.selected_database#.program_user
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND is_active = '1'
		ORDER BY username ASC
	</cfquery>

<cfoutput>
<span class="pagetitle">IMPORT from www2 - Program Users for #request.program_name#</span>
<br /><br />
<form method="post" action="#CurrentPage#">
	<cfif phase EQ "users">
		<input type="submit" name="doUsers" value="   Import #SelectList.RecordCount# Users   " >
	<cfelseif phase EQ "points">
		<input type="submit" name="doPoints" value="   Import Points   " >
	</cfif>
</form>
</cfoutput>
<br />

<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="100%" align="center"><span class="alert"><br />No records found.  Click "view all" to see all records.<br /><br /></span></td>
		</tr>
	<cfelse>
		<!--- display found records --->
		<cfoutput query="SelectList">

	<!--- check to see if this username is already in use for this program --->
	<cfquery name="AnyDuplicateUsernames2" datasource="#application.DS#">
		SELECT ID
		FROM #request.selected_database#.program_user
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SelectList.username#">
		AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		AND ID <> <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.ID#">
	</cfquery>
	<cfif AnyDuplicateUsernames2.recordCount gt 0>
		<tr><td colspan="100%" class="alert"><cfdump var="#AnyDuplicateUsernames2#"> DUPLICATE 2!</td></tr><cfabort>
	</cfif>
	<cfif phase EQ "users">
		<cfquery name="AnyDuplicateUsernames3" datasource="#application.DS#">
			SELECT ID
			FROM #request.target_database#.program_user
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SelectList.username#">
			AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.target_program_ID#">
		</cfquery>
		<cfif AnyDuplicateUsernames3.recordCount gt 0>
			<tr><td colspan="100%" class="alert"><cfdump var="#AnyDuplicateUsernames3#"> DUPLICATE 3!</td></tr><cfabort>
		</cfif>
	</cfif>
			<tr class="#Iif(is_active EQ "active",de(Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))), de('inactivebg'))#">
				<td></td>
				<td valign="top" colspan="3">#HTMLEditFormat(username)#<br />#HTMLEditFormat(fname)#&nbsp;#HTMLEditFormat(lname)#<br />#HTMLEditFormat(email)# </td>
				<cfif request.program.is_one_item EQ 0>

			<!--- look in the points database for the starting point amount --->
	<cfquery name="PosPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM(points),0) AS pos_pt
		FROM #request.selected_database#.awards_points
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.ID#">
		AND is_defered = 0
	</cfquery>
	<!--- look in the order database for orders/points_used --->
	<cfquery name="NegPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) AS neg_pt, IFNULL(SUM(cc_charge),0) AS neg_cc
		FROM #request.selected_database#.order_info
		WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.ID#">
		AND is_valid = 1
	</cfquery>
	<!--- find defered points --->
	<cfquery name="DefPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM(points),0) AS def_pt
		FROM #request.selected_database#.awards_points
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectList.ID#">
		AND is_defered = 1
	</cfquery>
	<cfset user_awardedpoints = PosPoints.pos_pt>
	<cfset user_usedpoints = NegPoints.neg_pt>
	<cfset user_totalpoints = user_awardedpoints - user_usedpoints>
	<cfset user_deferedpoints = DefPoints.def_pt>
	<cfif user_deferedpoints GT 0>
		<tr><td colspan="100%" class="alert">User def points!</td></tr><cfabort>
	</cfif>



	
						<td valign="middle" align="right">#user_totalpoints#</td>
				</cfif>
				<cfif request.program.accepts_cc EQ 1>
				<td valign="top" align="right"><span class="sub">$#cc_max#</span></td>
				</cfif>
				<cfif request.program.is_one_item GT 0>
				<td valign="top" align="right"><span class="sub">#is_done#</span>
				<br>
				</td>
				</cfif>
			</tr>
		</cfoutput>
	</cfif>
</table>

	<!--- END pgfn LIST --->
<cfelse>
	<br><br>Done!<br><br>
</cfif>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->
