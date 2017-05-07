<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>
<cfset edit_division = false>
<cfif isNumeric(request.selected_division_ID) AND request.selected_division_ID GT 0>
	<cfset edit_division = true>
</cfif>


<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfparam name="pgfn" default="">

<!--- param a/e form fields --->
<cfparam name="company_name" default="">
<cfparam name="program_name" default="">
<cfparam name="date_expiration" default="">
<cfparam name="is_one_item" default="0">
<cfparam name="has_survey" default="0">
<cfparam name="is_active" default="0">
<cfparam name="email_login" default="0">
<cfparam name="has_password_recovery" default="1">
<cfparam name="use_master_categories" default="1">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>

	<cfif date_expiration EQ "">
		<cfset date_expiration = DateFormat(DateAdd('yyyy',1,Now()),'yyyy-mm-dd')>
	</cfif>

	<!--- update --->
	<cfif pgfn EQ "edit">
		<cfif has_program>
			<cfquery name="UpdateQuery" datasource="#application.DS#">
				UPDATE #application.database#.program
				SET	company_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#company_name#" maxlength="32">, 
					program_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#program_name#" maxlength="50">,
					expiration_date = <cfqueryparam cfsqltype="cf_sql_date" value="#date_expiration#">,
					is_one_item = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_one_item#" maxlength="1">,
					has_survey = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#has_survey#" maxlength="1">,
					has_password_recovery = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#has_password_recovery#" maxlength="1">,
					use_master_categories = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#use_master_categories#" maxlength="1">,
					email_login = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#email_login#" maxlength="1">,
					is_active = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_active#" maxlength="1">
					#FLGen_UpdateModConcatSQL()#
					WHERE ID =
					<cfif edit_division> 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
					<cfelse>
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
					</cfif>
			</cfquery>
			<cflocation addtoken="no" url="program_details.cfm">
		<cfelse>
			<cflocation addtoken="no" url="program_list.cfm">
		</cfif>
	<!--- add --->
	<cfelse>
		<cflock name="programLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.program
						(created_user_ID, created_datetime, company_name, program_name, expiration_date, is_one_item,
							has_survey, is_active, has_password_recovery, use_master_categories, email_login)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 		
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#company_name#" maxlength="32">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#program_name#" maxlength="50">, 
						<cfqueryparam cfsqltype="cf_sql_date" value="#date_expiration#">, 
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_one_item#" maxlength="1">, 
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#has_survey#" maxlength="1">, 
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_active#" maxlength="1">,
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#has_password_recovery#" maxlength="1">,
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#use_master_categories#" maxlength="1">,
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#email_login#" maxlength="1">
					)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.program
				</cfquery>
				<cfset newID = getID.MaxID>
			</cftransaction>  
		</cflock>
		<cflocation addtoken="no" url="program_details.cfm?program_select=#newID#">
	</cfif>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfoutput>
<span class="pagetitle">
	<cfif pgfn EQ "add">Add<cfelseif pgfn EQ "edit">Edit<cfelse>Copy</cfif>
	<cfif edit_division>
		<span class="highlight">Division of #request.program_name#</span>
	<cfelse>
	 	an Award Program
	</cfif>
</span>
<br /><br />
<span class="pageinstructions">Return to the <a href="program_details.cfm"><cfif edit_division>Division<cfelse>Award Program</cfif> Details</a><cfif edit_division> or the <a href="program_details.cfm?division_select=">Parent Program Details</a></cfif> or the <a href="program_list.cfm?division_select=">Award Program List</a> without making changes.</span>
<br /><br />
</cfoutput>

<cfif pgfn EQ "edit" OR pgfn EQ "copy">
	<cfquery name="ToBeEdited" datasource="#application.DS#">
		SELECT company_name, program_name, expiration_date, is_one_item, has_survey, is_active, has_password_recovery, use_master_categories, email_login
		FROM #application.database#.program
		WHERE ID =
		<cfif edit_division> 
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
		<cfelse>
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		</cfif>
	</cfquery>
	<cfset company_name = htmleditformat(ToBeEdited.company_name)>
	<cfset program_name = htmleditformat(ToBeEdited.program_name)>
	<cfset date_expiration = FLGen_DateTimeToDisplay(htmleditformat(ToBeEdited.expiration_date))>
	<cfset is_one_item = htmleditformat(ToBeEdited.is_one_item)>
	<cfset has_survey = htmleditformat(ToBeEdited.has_survey)>
	<cfset is_active = htmleditformat(ToBeEdited.is_active)>
	<cfset has_password_recovery = htmleditformat(ToBeEdited.has_password_recovery)>
	<cfset use_master_categories = htmleditformat(ToBeEdited.use_master_categories)>
	<cfset email_login = ToBeEdited.email_login>
</cfif>

<cfoutput>
<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext <cfif edit_division>highlight</cfif>">General Information</td>
	</tr>

	<tr class="content">
	<td width="40%" align="right" valign="top">Award Program Company Name*: </td>
	<td width="60%" valign="top"><input type="text" name="company_name" value="<cfif pgfn eq 'copy'>COPY-</cfif>#company_name#" maxlength="32" size="40">
		<input type="hidden" name="company_name_required" value="Please enter an award program company name."></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Award Program Name <span class="sub">[admin only]</span>*: </td>
	<td valign="top"><input type="text" name="program_name" value="#program_name#" maxlength="32" size="40">
		<input type="hidden" name="program_name_required" value="Please enter an award program name."></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Is Active?: </td>
	<td valign="top">
		<select name="is_active">
			<option value="0"<cfif is_active EQ 0> selected</cfif>>No
			<option value="1"<cfif is_active EQ 1> selected</cfif>>Yes
		</select>

	</td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Expiration Date*: </td>
	<td valign="top"><input type="text" name="date_expiration" value="#date_expiration#" maxlength="10" size="12"><br>
	<span class="sub">(Please use 4 digit years, for example: #DateFormat(Now(),"mm/dd/yyyy")#)</span>
	<input type="hidden" name="date_expiration_required" value="Please enter an expiration date."></td>
	</tr>
								
	<tr class="content">
	<td align="right" valign="top">Has a survey?: </td>
	<td valign="top">
		<select name="has_survey">
			<option value="1"<cfif has_survey EQ 1> selected</cfif>>Yes
			<option value="0"<cfif has_survey EQ 0> selected</cfif>>No
		</select>
	</td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Limited item store?: </td>
	<td valign="top">
		<select name="is_one_item">
			<option value="0"<cfif is_one_item EQ 0> selected</cfif>>No
			<option value="1"<cfif is_one_item EQ 1> selected</cfif>>One Item Store
			<option value="2"<cfif is_one_item EQ 2> selected</cfif>>Two Item Store
		</select>
	</td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Has password recovery?: </td>
	<td valign="top">
		<select name="has_password_recovery">
			<option value="1"<cfif has_password_recovery EQ 1> selected</cfif>>Yes
			<option value="0"<cfif has_password_recovery EQ 0> selected</cfif>>No
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Requires email login?: </td>
	<td valign="top">
		<select name="email_login">
			<option value="1"<cfif email_login EQ 1> selected</cfif>>Yes
			<option value="0"<cfif email_login EQ 0> selected</cfif>>No
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Category Style: </td>
	<td valign="top">
		<select name="use_master_categories">
			<option value="0"<cfif use_master_categories EQ 0> selected</cfif>>"Old Style" category buttons (master categories)</option>
			<option value="1"<cfif use_master_categories EQ 1> selected</cfif>>"Old Style" category buttons (search options)</option>
			<option value="2"<cfif use_master_categories EQ 2> selected</cfif>>"Stacked" category buttons (search options)</option>
			<option value="3"<cfif use_master_categories EQ 3> selected</cfif>>"New Style" category tabs (master categories)</option>
			<option value="4"<cfif use_master_categories EQ 4> selected</cfif>>"New Style" category tabs (search options)</option>
		</select>
	</td>
	</tr>

								
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="pgfn" value="#pgfn#">
			
	<input type="submit" name="submit" value="   Save Changes   " >

	</td>
	</tr>
		
	</table>

</form>
</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->