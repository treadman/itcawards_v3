<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfif FLGen_AuthenticateAdmin() EQ true>
	<cfset pgfn = "welcome">
</cfif>
<cfparam name="username" default="">
<cfparam name="HashedPassword" default="">
<cfparam name="nomatch" default="no">
<cfparam name="pgfn" default="login">
<cfparam name="sUserAccess" default="">
<cfparam name="adminloginIDhash" default="">
<cfparam name="logout" default="">

<cfparam name="emailValidate" default="">
<cfparam name="hashedValidate" default="">

<cfset errorMessage = "">
<cfset validated = false>

<cfif isDefined("url.e") AND isDefined("url.v")>
	<cfset emailValidate = url.e>
	<cfset hashedValidate = url.v>
	<cfset pgfn = "validate">
	<cfif isDefined("url.o")>
		<!--- See if they already registered --->
		<cfquery name="CheckUser" datasource="#application.DS#">
			SELECT u.is_active
			FROM #application.database#.admin_users u
			LEFT JOIN #application.database#.program p ON p.ID = u.program_ID
			WHERE u.email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#emailValidate#" maxlength="128">
		</cfquery>
		<cfif CheckUser.recordCount EQ 1 and CheckUser.is_active EQ 1>
			<cfset pgfn = "login">
		</cfif>
	</cfif>
</cfif>

<cfif emailValidate NEQ "">
	<cfquery name="GetUser" datasource="#application.DS#">
		SELECT u.ID, u.firstname, u.lastname, u.username, IFNULL(p.company_name,"ITC") AS company, u.is_active, u.program_ID
		FROM #application.database#.admin_users u
		LEFT JOIN #application.database#.program p ON p.ID = u.program_ID
		WHERE u.email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#emailValidate#" maxlength="128">
		AND u.password =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#hashedValidate#" maxlength="32">
	</cfquery>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif isDefined("form.password1") AND isDefined("form.password2")>
	<cfset pgfn = "validate">
	<cfif trim(form.password1) EQ "">
		<cfset errorMessage = "Please enter a password.">
	<cfelseif form.password1 NEQ form.password2>
		<cfset errorMessage = "The two passwords did not match.">
	<cfelseif GetUser.recordcount NEQ 1>
		<cfset errorMessage = "Could not find that user.">
	<cfelse>
		<!--- Check if that password is in use --->
		<cfquery name="GetExistingUser" datasource="#application.DS#">
			SELECT username
			FROM #application.database#.program_user
			WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" maxlength="10" value="#GetUser.program_ID#">
			AND email != <cfqueryparam cfsqltype="cf_sql_varchar" value="#emailValidate#" maxlength="128">
			AND username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.password1#" maxlength="128">
		</cfquery>
		<cfif GetExistingUser.recordcount GT 0>
			<cfset errorMessage = "That password is not valid.  Please try again.">
		<cfelse>
			<cfset HashedPassword = FLGen_CreateHash(Lcase(form.password1))>
			<cfquery name="UpdateUser" datasource="#application.DS#">
				UPDATE #application.database#.admin_users
				SET password =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#HashedPassword#" maxlength="32">,
					is_active = 1
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" maxlength="10" value="#GetUser.ID#">
			</cfquery>
			<cfset validated = true>
			<!--- Go ahead and log them in I guess --->
			<cfif not isDefined('form.order_id')>
				<cfset form.order_id = "">
				<cfif isDefined('url.o')>
					<cfset form.order_id = url.o>
				</cfif>
			</cfif>
			<cfset form.username = GetUser.username>
			<cfset form.password = form.password1>
			<!--- Add the user and award them points --->
			<cfquery name="GetProgramUser" datasource="#application.DS#">
				SELECT username
				FROM #application.database#.program_user
				WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" maxlength="10" value="#GetUser.program_ID#">
				AND email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#emailValidate#" maxlength="128">
			</cfquery>
			<cfif GetProgramUser.recordcount EQ 0>
				<cfquery name="GetRegister" datasource="#application.DS#">
					SELECT ID, register_name, date_start, date_end, award_points
					FROM #application.database#.program_register
					WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#GetUser.program_ID#">
					AND date_start <= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#">
					AND date_end >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#">
				</cfquery>
				<cfset points=0>
				<cfif GetRegister.recordcount GT 0>
					<cfset points = GetRegister.award_points>
				</cfif>
				<cfquery name="AddProgramUser" datasource="#application.DS#" result="stResult">
					INSERT INTO #application.database#.program_user (
						created_user_ID, created_datetime, program_ID, username, fname, lname, email, is_active)
					VALUES (
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#GetUser.program_ID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#',
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#GetUser.program_ID#" maxlength="10">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.password1#" maxlength="16">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getUser.firstname#" maxlength="30">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getUser.lastname#" maxlength="30">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#emailValidate#" maxlength="128">,
						1)
				</cfquery>
				<cfset programUserID = stResult.GENERATED_KEY>
				<cfif points GT 0>
					<cfset Notes = "#Points# points for registering." & CHR(13) & CHR(10)>
					<cfquery name="AwardPoints" datasource="#application.DS#">
						INSERT INTO #application.database#.awards_points (
							created_user_ID, created_datetime, user_ID, points, notes)
						VALUES (
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#GetUser.program_ID#" maxlength="10">,
							'#FLGen_DateTimeToMySQL()#',
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#programUserID#" maxlength="10">,
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#points#">,
							<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#Notes#">
						)
					</cfquery>
				</cfif>
				<!--- Check if they are a cost center user --->
				<cfquery name="GetUsers" datasource="#application.DS#">
					SELECT
						cc_code,
						cc_desc,
						mgr_lastname,
						mgr_firstname,
						mgr_email,
						mc_lastname,
						mc_firstname,
						mc_email
					FROM #application.database#.cost_center_user
					WHERE email = <cfqueryparam value="#emailValidate#" cfsqltype="CF_SQL_VARCHAR">
				</cfquery>
				<cfif GetUsers.recordcount EQ 1>
					<cfset this_cc_number = trim(GetUsers.cc_code)>
					<cfif programUserID GT 0 AND this_cc_number NEQ "">
						<cfset this_cc_ID = 0>
						<!---Look up cost center--->
						<cfquery name="GetCostCenter" datasource="#application.DS#">
							SELECT ID
							FROM #application.database#.cost_centers
							WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#GetUser.program_ID#">
							AND number = '#this_cc_number#'
						</cfquery>
						<cfif GetCostCenter.recordcount EQ 1>
							<cfset this_cc_ID = GetCostCenter.ID>
							<!--- Check if user is in cost center --->
							<cftry>
							<cfquery name="AddUserToCC" datasource="#application.DS#">
								INSERT INTO #application.database#.xref_cost_center_users
									(cost_center_ID, program_user_ID)
								VALUES
									(#this_CC_ID#, #programUserID#)
							</cfquery>
							<cfcatch></cfcatch></cftry>
						</cfif>
						<!--- Mark user as uses_cost_center = 2 --->
						<cfquery name="UpdateUser" datasource="#application.DS#">
							UPDATE #application.database#.program_user
							SET uses_cost_center = 2
							WHERE ID = #programUserID#
						</cfquery>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
	</cfif>
</cfif>

<cfif isDefined('url.i') OR (IsDefined('form.username') AND form.username IS NOT "" AND IsDefined('form.password') AND form.password IS NOT "")>

	<cfset login_sso = "">
	<cfif isDefined('url.i')>
		<!--- First check if time stamp is ok --->
		<cfset date_ok = false>
		<cfset today_date = now()>
		<cfset admin_datehash = mid(url.i,1,4)&mid(url.i,9,4)&mid(url.i,17,4)&mid(url.i,25,4)&mid(url.i,33,4)&mid(url.i,41,4)&mid(url.i,49,4)&mid(url.i,57,4)>
		<cfloop from="0" to="1" index="i">
			<cfset local_datehash = hash(dateformat(dateadd('n',-i,today_date),'mmmm d yyyy ') & timeformat(dateadd('n',-i,today_date),'HHmm'),'MD5') >
			<cfif admin_datehash EQ local_datehash>
				<cfset date_ok = true>
				<cfbreak>
			<cfelse>
			</cfif>
		</cfloop>

		<!--- Next see if there are any active admins that match --->
		<cfif date_ok>
			<cfset admin_userhash = mid(url.i,5,4)&mid(url.i,13,4)&mid(url.i,21,4)&mid(url.i,29,4)&mid(url.i,37,4)&mid(url.i,45,4)&mid(url.i,53,4)&mid(url.i,61,4)>
			<cfquery name="GetAdmins" datasource="#application.DS#">
				SELECT username
				FROM #application.database#.admin_users
				WHERE is_active = 1
			</cfquery>
			<cfloop query="GetAdmins">
				<cfset local_userhash = hash(GetAdmins.username,'MD5')>
				<cfif admin_userhash EQ local_userhash>
					<cfset login_sso = GetAdmins.username>
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif> 
	</cfif>

	<!--- hash the password --->
	<cfif login_sso EQ "">
		<cfset HashedPassword = FLGen_CreateHash(Lcase(form.password))>
		<cfset ThisUsername = form.username>
	<cfelse>
		<cfset ThisUsername = login_sso>
	</cfif>

	<!--- check the database for the username hash match --->
	<cfquery name="CheckLogin" datasource="#application.DS#">
		SELECT ID, IFNULL(program_ID,0) AS program_ID, IFNULL(division_ID,0) AS division_ID, firstname
		FROM #application.database#.admin_users
		WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ThisUsername#" maxlength="32">
		AND is_active = 1
		<cfif login_sso EQ "">
			AND password='#HashedPassword#'
		</cfif> 
	</cfquery>
	<cfif CheckLogin.RecordCount IS 0>
		<cfset nomatch = "yes">
		<cfset username = #form.username#>
	<cfelse>
	
		<cfset query_string = "">
		<cfif isDefined("form.order_id")>
			<!--- get order info --->
			<cfquery name="FindOrderInfo" datasource="#application.DS#">
				SELECT program_ID
				FROM #application.database#.order_info
				WHERE cost_center_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.order_id#" maxlength="32">
			</cfquery>
			<cfif FindOrderInfo.recordcount eq 1 AND (CheckLogin.program_ID EQ '1000000001' OR CheckLogin.program_ID EQ FindOrderInfo.program_ID)>
				<cfset query_string = "?o=#form.order_id#">
				<cfset HashedProgramID = FLGen_CreateHash(CheckLogin.program_ID)>
				<cfcookie name="itc_program" value="#CheckLogin.program_ID#-#HashedProgramID#">
				<cfset HashedProgramID = FLGen_CreateHash(FindOrderInfo.program_ID)>
				<cfcookie name="program_id" value="#FindOrderInfo.program_ID#-#HashedProgramID#">
			</cfif>
		</cfif>
		<cfif query_string EQ "">
			<!--- SET PROGRAM INFO, if assigned to a program --->
			<cfif CheckLogin.program_ID GT 0>
				<!--- hash program ID and save cookie --->
				<cfset HashedProgramID = FLGen_CreateHash(CheckLogin.program_ID)>
				<cfcookie name="itc_program" value="#CheckLogin.program_ID#-#HashedProgramID#">
				<cfset request.is_admin = false>
				<cfset request.selected_program_ID = CheckLogin.program_ID>
				<cfif CheckLogin.program_ID EQ '1000000001'>
					<cfset request.is_admin = true>
					<cfset request.selected_program_ID = 0>
				</cfif>
			</cfif>
			<!--- SET Division INFO, if assigned to a division --->
			<cfif CheckLogin.division_ID GT 0>
				<cfset HashedDivisionID = FLGen_CreateHash(CheckLogin.division_ID)>
				<cfcookie name="division_id" value="#CheckLogin.division_ID#-#HashedDivisionID#">
				<cfset request.selected_division_ID = CheckLogin.division_ID>
			</cfif>
		</cfif>
	
		<!--- grab the user's admin access levels and save in var --->
		<cfquery name="GetAccess" datasource="#application.DS#">
			SELECT access_level_ID
			FROM #application.database#.admin_lookup
			WHERE user_ID = '#CheckLogin.ID#'
		</cfquery>
		<cfloop query="GetAccess">
			<cfset sUserAccess = #sUserAccess# & " " & #GetAccess.access_level_ID#>
		</cfloop>
			
		<!--- entry into admin_login table, get ID --->
		<cflock name="admin_loginLock" timeout="10">
			<cftransaction>
				<cfset aToday = FLGen_DateTimeToMySQL()>
				<cfquery datasource="#application.DS#" name="InsertLogin">
					INSERT INTO #application.database#.admin_login (created_user_ID, created_datetime) 
					VALUES ('#CheckLogin.ID#', '#aToday#')
				</cfquery>
				<cfquery name="getPK" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.admin_login
				</cfquery>
			</cftransaction>  
		</cflock>

		<!--- hash admin_login ID --->	
		<cfset adminloginIDhash = FLGen_CreateHash(getPK.MaxID)>
		<!--- write cookies --->
	 	<cfcookie name="admin_login" value="#getPK.MaxID#-#adminloginIDhash#">
		<cfcookie name="admin_name" value="#CheckLogin.firstname#">

		<!--- Self-locate to get updated cookie --->
		<cfif FLGen_AuthenticateAdmin()>
			<cflocation url="index.cfm#query_string#" addtoken="no">
		</cfif>
	</cfif>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->


<cfinclude template="includes/header.cfm">

<cfswitch expression = "#pgfn#">
	<cfcase value="validate">
		<!--- Validating their email address as an admin user --->
		<table cellpadding="5" cellspacing="0" width="900" border="0">
		<tr>
			<td valign="top" width="150">&nbsp;</td>
			<td valign="top" width="30">&nbsp;</td>
			<td valign="top">
				<br /><span class="pagetitle">Validate Administrative User</span><br /><br />
				<cfif GetUser.recordcount NEQ 1>
					<span class="alert">User not found!</span><br /><br />
					<cflocation url="index.cfm" addtoken="no" >
				<cfelse>
					<cfoutput>
					<span class="pageinstructions">#GetUser.firstname# #GetUser.lastname# (#emailValidate#) has been set up as an administrator for #GetUser.company#.</span><br /><br>
					<span class="pageinstructions">Username: #GetUser.username#</span><br /><br />
					<cfif validated>
						<span class="pagetitle">Thank you. Your admin account is now set up.</span><br /><br />
						<a href="index.cfm">Log in</a>
					<cfelse>
						<!--- See if there is a program_user for this email address --->
						<cfquery name="GetProgramUser" datasource="#application.DS#">
							SELECT username
							FROM #application.database#.program_user
							WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" maxlength="10" value="#GetUser.program_ID#">
							AND email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#emailValidate#" maxlength="128">
						</cfquery>
						<cfset this_password = "">
						<cfif GetProgramUser.recordcount EQ 1>
							<cfset this_password = GetProgramUser.username>
						</cfif>
						<span class="pageinstructions">Please create a password:</span><br /><br />
						<cfif errorMessage NEQ "">
							<span class="alert">#errorMessage#</span><br /><br />
						</cfif>
						<form id="foo" method="post" action="#application.SecureWebPath#/admin/index.cfm<cfif isDefined('url.o')>?o=#url.o#</cfif>">
							<input type="hidden" name="emailValidate" value="#emailValidate#">
							<input type="hidden" name="hashedValidate" value="#hashedValidate#">
							<cfif this_password NEQ "">
								<input type="hidden" name="password1" value="#this_password#">
								<input type="hidden" name="password2" value="#this_password#">
							<cfelse>
								<table cellpadding="7" cellspacing="0" border="0">
									<tr class="contenthead">
										<td class="headertext" colspan="2">Create password</td>
									</tr>
									<tr class="content2">
										<td align="right">Enter a password: </td>
										<td><input type="password" maxlength="20" size="32" name="password1"></td>
									</tr>
									<tr class="content2">
										<td align="right">Reenter password: </td>
										<td><input type="password" maxlength="20" size="32" name="password2"></td>
									</tr>
									<tr class="contentsearch">
										<td colspan="2" align="center"><input type="submit" name="Validate" value="  Create Password  " ></td>
									</tr>
								</table>
							</cfif>
						</form>
						<cfif this_password NEQ "">
							<script type="text/javascript">
							    function myfunc () {
						        	var frm = document.getElementById("foo");
						        	frm.submit();
    							}
    							window.onload = myfunc;
							</script>
						</cfif>
					</cfif>
					</cfoutput>
				</cfif>
			</td>
		</tr>
		</table>
	</cfcase>
	<cfcase value="login">
		<table cellpadding="5" cellspacing="0" width="900" border="0">
			<tr>
				<td valign="top" width="150">&nbsp;</td>
				<td valign="top" width="30">&nbsp;</td>
				<td valign="top">
					<br /><span class="pagetitle">Administrative Login</span><br /><br />
					<span class="pageinstructions">If you have forgotten your password, please contact</span><br />
					<span class="pageinstructions">another administrative user to reset it for you.</span><br /><br />
					<cfif nomatch IS "yes">
						<span class="alert">That is an invalid username and password.</span><br /><br />
					</cfif>
					<cfif logout IS "y">
						<span class="alert">You have been logged out.</span><br /><br />
					</cfif>
					<cfoutput>
					<form method="post" action="#application.SecureWebPath#/admin/index.cfm">
						<cfif isDefined("url.o")>
							<!--- Clicked a link to a pending order in their email --->
							<input type="hidden" name="order_id" value="#url.o#">
						<cfelseif isDefined("form.order_id")>
							<!--- Login failed --->
							<input type="hidden" name="order_id" value="#form.order_id#">
						</cfif>
						<cfif isDefined("url.e")>
							<cfset username = url.e>
						</cfif>
						<table cellpadding="5" cellspacing="1" border="0">
							<tr class="contenthead">
								<td colspan="2">Login</td>
							</tr>
							<tr class="content">
								<td align="right"><cfif isDefined('url.o') OR isDefined("form.order_id")>Email Address<cfelse>Username</cfif>: </td>
								<td><input type="text" maxlength="32" size="32" name="username" value="#HTMLEditFormat(username)#"></td>
							</tr>
							<tr class="content">
								<td align="right">Password: </td>
								<td><input type="password" maxlength="20" size="32" name="password"></td>
							</tr>
							<tr class="content">
								<td colspan="2" align="center"><input type="submit" name="Login" value="  Login  " ></td>
							</tr>
						</table>
					</form>
					</cfoutput>
				</td>
			</tr>
		</table>
	</cfcase>
	<cfcase value="welcome">
		<cfif isDefined("url.o")>
			<cfif request.is_admin>
				<!--- get order info --->
				<cfquery name="FindOrderInfo" datasource="#application.DS#">
					SELECT program_ID
					FROM #application.database#.order_info
					WHERE cost_center_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#url.o#" maxlength="32">
				</cfquery>
				<cfif FindOrderInfo.recordcount eq 1>
					<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0 OR request.selected_program_ID NEQ FindOrderInfo.program_ID>
						<cfset HashedProgramID = FLGen_CreateHash(FindOrderInfo.program_ID)>
						<cfcookie name="program_id" value="#FindOrderInfo.program_ID#-#HashedProgramID#">
					</cfif>
				</cfif>
			</cfif>
			<cflocation url="order_approve.cfm?o=#url.o#" addtoken="no">
		</cfif>
		<cfset leftnavon = "index">
		<table cellpadding="5" cellspacing="0" width="800" border="0">
			<tr>
				<td valign="top" width="185" class="leftnav"><cfinclude template="includes/leftnav.cfm"></td>
				<td valign="top" width="25">&nbsp;</td>
				<td valign="top" width="575">
					<!--- Content goes here --->
					<br>
					<span class="pagetitle">Welcome to the ITC Awards Administration System!</span>
					<br><br>
					<cfif request.selected_program_ID EQ 0>
						<cfquery name="GetOneItems" datasource="#application.DS#">
							SELECT ID, company_name, program_name
							FROM #application.database#.program
							WHERE is_one_item = 1
							AND parent_ID = 0
							AND expiration_date >= CURDATE()
						</cfquery>
						<cfloop query="GetOneItems">
							<cfquery name="CheckDupeOrders" datasource="#application.DS#">
								SELECT created_user_ID, snap_fname, snap_lname, count(*) as num
								FROM #application.database#.order_info
								WHERE program_ID = #GetOneItems.ID#
								AND is_valid = 1
								GROUP BY created_user_ID
								HAVING num > 1
								ORDER BY snap_lname
							</cfquery>
							<cfif CheckDupeOrders.recordcount gt 0>
								<span class="alert"><cfoutput>#GetOneItems.company_name# [#GetOneItems.program_name#] has users with more than one order:<br><br></cfoutput></span>
								<table cellpadding="5" cellspacing="1" border="0" >
									<tr class="contenthead"><td class="headertext">First Name</td><td class="headertext">Last Name</td><td class="headertext">Number of Orders</td></tr>
									<cfoutput query="CheckDupeOrders">
										<tr class="#Iif(((CurrentRow MOD 2) is 1),de('content2'),de('content'))#"><td>#snap_fname#</td><td>#snap_lname#</td><td align="right">#num#</td></tr>
									</cfoutput>
								</table>
								<br><br>
							</cfif>
						</cfloop>
					</cfif>
					<a href="fedex_test.cfm">Test Fedex Rates</a>
					<br><br>
					<cfif isDefined("GetProgramNames")>
						<cfloop query="GetProgramNames">
							<cfif request.selected_program_ID EQ 0 OR request.selected_program_ID EQ GetProgramNames.ID>
								<cfquery name="GetProgramDivisions" datasource="#application.DS#">
									SELECT ID, company_name, program_name, welcome_button
									FROM #application.database#.program
									WHERE parent_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#GetProgramNames.ID#" maxlength="10">
								</cfquery>
								<cfif GetProgramDivisions.recordcount GT 0>
									<cfset unassigned_points = hasUserUnassignedPoints()>
									<cfif unassigned_points.recordcount GT 0>
										<span class="alert"><cfoutput>#unassigned_points.company_name# has #unassigned_points.total# unassigned points.<br><br></cfoutput></span>
									</cfif>
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
					<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
					<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>
				</td>
			</tr>
		</table>
	</cfcase>
</cfswitch>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->