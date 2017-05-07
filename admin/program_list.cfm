<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfparam name="ID" default="">
<cfparam name="delete" default="">
<cfparam name="copy" default="">
<cfparam name="pgrm" default="">

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif delete NEQ '' AND FLGen_HasAdminAccess(1000000051)>
	<cfquery name="DeleteGroup" datasource="#application.DS#">
		DELETE FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#">
	</cfquery>
	<cfif has_program AND request.selected_program_ID EQ delete>
		<cflocation url="#CurrentPage#?program_select=0" addtoken="no">
	</cfif>			
</cfif>

<cfif copy NEQ ''>
	<cflock name="programLock" timeout="10">
		<cftransaction>
			<cfquery name="CopyProgram" datasource="#application.DS#">
				INSERT INTO #application.database#.program
					(created_user_ID, created_datetime, company_name, program_name, expiration_date, is_one_item, can_defer, defer_msg, has_welcomepage, welcome_bg, welcome_instructions, welcome_message, welcome_congrats, welcome_button, welcome_admin_button, admin_logo, logo, cross_color, main_bg, main_congrats, main_instructions, return_button, text_active, bg_active, text_selected, bg_selected, cart_exceeded_msg, cc_exceeded_msg, orders_to, orders_from, conf_email_text, program_email_subject, has_survey, display_col, display_row, menu_text, credit_desc, accepts_cc, login_prompt, is_active, display_welcomeyourname, display_youhavexcredits, credit_multiplier, points_multiplier, email_form_button, email_form_message, additional_content_button, additional_content_message, help_button, help_message, additional_content_button_unapproved, additional_content_message_unapproved, additional_content_program_admin_ID)
					SELECT '#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#', CONCAT(company_name,'-COPY') AS company_name, CONCAT(program_name,'-COPY') AS program_name, expiration_date, is_one_item, can_defer, defer_msg, has_welcomepage, welcome_bg, welcome_instructions, welcome_message, welcome_congrats, welcome_button, welcome_admin_button, admin_logo, logo, cross_color, main_bg, main_congrats, main_instructions, return_button, text_active, bg_active, text_selected, bg_selected, cart_exceeded_msg, cc_exceeded_msg, orders_to, orders_from, conf_email_text, program_email_subject, has_survey, display_col, display_row, menu_text, credit_desc, accepts_cc, login_prompt, is_active, display_welcomeyourname, display_youhavexcredits, credit_multiplier, points_multiplier, email_form_button, email_form_message, additional_content_button, additional_content_message, help_button, help_message, additional_content_button_unapproved, additional_content_message_unapproved, additional_content_program_admin_ID 
					FROM #application.database#.program
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#copy#">
			</cfquery>
			<cfquery name="getID" datasource="#application.DS#">
				SELECT Max(ID) As MaxID FROM #application.database#.program
			</cfquery>
			<cfset new_ID = getID.MaxID>
		</cftransaction>  
	</cflock>
	<cflocation url="program_details.cfm?program_select=#new_ID#" addtoken="no">
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset request.main_width="1000">
<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<!--- run query --->
<cfquery name="SelectList" datasource="#application.DS#">
	SELECT ID, company_name, program_name, is_active, expiration_date, return_button, text_active, bg_active, text_selected, bg_selected, cart_exceeded_msg, orders_from, program_email_subject, display_col, display_row, menu_text, credit_desc, login_prompt
	FROM #application.database#.program
	WHERE parent_ID = 0
	<cfif pgrm NEQ 'all'>
		AND is_active = 1
	</cfif>
	ORDER BY company_name, program_name ASC
</cfquery>

<span class="pagetitle">Award Program List</span>
<br />
<br />
<span class="pageinstructions">Items marked <span class="alert">setup</span> must be set up before that awards program is ready to go live.</span>
<br />
<br />
<span class="pageinstructions">
	<cfif pgrm EQ 'all'>
	<b>All Programs Are Displayed</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="program_list.cfm">Display Active Programs Only</a>
	<cfelse>
	<b>Only Active Programs Are Displayed</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="program_list.cfm?pgrm=all">Display All Programs</a>
	</cfif>
</span>
<br /><br />

<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<!--- header row --->
	<tr class="contenthead">
	<td align="center"><a href="program_general.cfm?pgfn=add">Add</a></td>
	<td width="100%"><span class="headertext">Name</span> <img src="../pics/contrls-asc.gif" width="7" height="6"></td>
	<td align="center"><span class="headertext">Manage Logins</span></td>
	<td align="center"><span class="headertext">Manage Users</span></td>
	<td align="center"><span class="headertext">Manage Categories</span></td>
	<td align="center"><span class="headertext">Manage Products</span></td>
	<td align="center"><span class="headertext">Manage Cost&nbsp;Centers</span></td>
	<td align="center"><span class="headertext">Manage Shipping&nbsp;Locations</span></td>
	</tr>

	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="6" align="center"><span class="alert"><br>No Awards Programs found.<br><br></span></td>
		</tr>
	</cfif>

	<!--- display found records --->
	<cfoutput query="SelectList">

		<!--- set whether they need to enter details --->
		<cfif company_name EQ "" OR 
				program_name EQ "" OR 
				expiration_date EQ "" OR 
				return_button EQ "" OR 
				text_active EQ "" OR 
				bg_active EQ "" OR 
				text_selected EQ "" OR 
				bg_selected EQ "" OR 
				cart_exceeded_msg EQ "" OR 
				orders_from EQ "" OR 
				program_email_subject EQ "" OR 
				display_col EQ "" OR 
				display_row EQ "" OR 
				menu_text EQ "" OR 
				credit_desc EQ "" OR 
				login_prompt EQ "">
			<cfset setup_details = true>
		<cfelse>
			<cfset setup_details = false>
		</cfif>

		<!--- set whether they need to set up categories --->
		<cfquery name="HasCat" datasource="#application.DS#">
			SELECT ID
			FROM #application.database#.productvalue_program
			WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#SelectList.ID#" maxlength="10">
		</cfquery>

		<!--- set whether they need to set up logins --->
		<cfquery name="HasLog" datasource="#application.DS#">
			SELECT ID
			FROM #application.database#.program_login
			WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#SelectList.ID#" maxlength="10">
		</cfquery>

		<!--- set whether they need to set up users --->
		<cfquery name="HasUsers" datasource="#application.DS#">
			SELECT ID
			FROM #application.database#.program_user
			WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#SelectList.ID#" maxlength="10">
		</cfquery>

		<cfset show_delete = false>
		<cfif FLGen_HasAdminAccess(1000000051)>
			<cfquery name="FindLink1" datasource="#application.DS#">
				SELECT COUNT(ID) as thismany
				FROM #application.database#.program_login
				WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10"> 
			</cfquery>
			<cfif FindLink1.thismany EQ 0>
				<cfquery name="FindLink2" datasource="#application.DS#">
					SELECT COUNT(ID) as thismany
					FROM #application.database#.program_product_exclude 
					WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10"> 
				</cfquery>
				<cfif FindLink2.thismany EQ 0>
					<cfquery name="FindLink3" datasource="#application.DS#">
						SELECT COUNT(ID) as thismany
						FROM #application.database#.program_user 
						WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10"> 
					</cfquery>
					<cfif FindLink3.thismany EQ 0>
						<cfquery name="FindLink4" datasource="#application.DS#">
							SELECT COUNT(ID) as thismany
							FROM #application.database#.survey 
							WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10"> 
						</cfquery>
						<cfif FindLink4.thismany EQ 0>
							<cfquery name="FindLink5" datasource="#application.DS#">
								SELECT COUNT(ID) as thismany
								FROM #application.database#.productvalue_program 
								WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10"> 
							</cfquery>
							<cfif FindLink5.thismany EQ 0>
								<cfquery name="FindLink6" datasource="#application.DS#">
									SELECT COUNT(ID) as thismany
									FROM #application.database#.order_info 
									WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10"> 
										AND is_valid = 1
								</cfquery>
								<cfif FindLink6.thismany EQ 0>
									<cfquery name="FindLink7" datasource="#application.DS#">
										SELECT COUNT(ID) as thismany
										FROM #application.database#.admin_users 
										WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10"> 
									</cfquery>
									<cfif FindLink7.thismany EQ 0>
										<cfset show_delete = true>
									</cfif>
								</cfif>
							</cfif>
						</cfif>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
		<tr class="<cfif NOT is_active>inactivebg<cfelse>#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))# </cfif>">
		<td ><cfif setup_details><span class="alert">setup<br></span></cfif><a href="program_details.cfm?program_select=#ID#&division_select=">Details</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?copy=#ID#">Copy</a><cfif FLGen_HasAdminAccess(1000000051) and show_delete>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?delete=#ID#" onclick="return confirm('Are you sure you want to delete this program?  There is NO UNDO.')">Delete</a></cfif></td>
		<td valign="top">#htmleditformat(company_name)# <cfif Trim(program_name) NEQ ""><span class="sub">[#htmleditformat(program_name)#]</span></cfif></td>
		<td valign="top" align="right"><cfif HasLog.RecordCount IS 0><span class="alert">setup<br></span></cfif><a href="program_login.cfm?pgfn=list&program_select=#ID#">Logins</a></td>
		<td valign="top" align="right"><cfif HasUsers.RecordCount IS 0><span class="alert">setup<br></span> </cfif><a href="program_user.cfm?program_select=#ID#">Users</a></td>
		<td valign="top" align="right"><cfif HasCat.RecordCount IS 0><span class="alert">setup<br></span></cfif><a href="program_category.cfm?program_select=#ID#">Categories</a></td>
		<td valign="top" align="right"><cfif HasCat.RecordCount NEQ 0><a href="program_product.cfm?program_select=#ID#">Products</a></cfif></td>
		<td valign="top" align="right"><a href="cost_centers.cfm?program_select=#ID#">Cost&nbsp;Centers</a></td>
		<td valign="top" align="right"><a href="shipping_locations.cfm?program_select=#ID#">Shipping&nbsp;Locations</a></td>
		</tr>
	</cfoutput>
</table>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->