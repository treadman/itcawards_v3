<!--- Verify that a program was selected --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cflocation url="program_list.cfm" addtoken="no">
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfparam name="has_register" default="0">
<cfparam name="register_email_domain" default="">
<cfparam name="register_page_text" default="">
<cfparam name="register_form_text" default="">
<cfparam name="register_template_id" default="0">
<cfparam name="register_email_subject" default="">

<cfparam name="register_ID" default="">
<cfparam name="register_name" default="">
<cfparam name="date_start" default="">
<cfparam name="date_end" default="">
<cfparam name="award_points" default="10">

<cfparam name="pgfn" default="main">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.SaveMain')>

	<cfquery name="UpdateQuery" datasource="#application.DS#">
		UPDATE #application.database#.program
		SET	has_register = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#has_register#" maxlength="1">,
			register_email_domain = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#register_email_domain#" maxlength="255">,
			register_page_text = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#register_page_text#" null="#YesNoFormat(NOT Len(Trim(register_page_text)))#">,
			register_template_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#register_template_id#" maxlength="10">,
			register_email_subject = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#register_email_subject#" maxlength="64">,
			register_form_text = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#register_form_text#" null="#YesNoFormat(NOT Len(Trim(register_form_text)))#">
			#FLGen_UpdateModConcatSQL("from program_register.cfm")#
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cflocation addtoken="no" url="program_details.cfm">
</cfif>

<cfif IsDefined('form.SaveRegister')>
	<cfif pgfn EQ "edit">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.program_register
			SET	register_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.register_name#" maxlength="32">,
				date_start = <cfqueryparam cfsqltype="cf_sql_date" value="#form.date_start#">,
				date_end = <cfqueryparam cfsqltype="cf_sql_date" value="#form.date_end#">,
				award_points = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.award_points#">
				#FLGen_UpdateModConcatSQL()#
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.register_ID#" maxlength="10">
		</cfquery>
	<cfelseif pgfn EQ "add">
		<cfquery name="InsertQuery" datasource="#application.DS#">
			INSERT INTO #application.database#.program_register
				(created_user_ID, created_datetime, register_name, date_start, date_end, award_points, program_ID)
			VALUES (
				<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
				'#FLGen_DateTimeToMySQL()#', 
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.register_name#" maxlength="32">,
				<cfqueryparam cfsqltype="cf_sql_date" value="#form.date_start#">,
				<cfqueryparam cfsqltype="cf_sql_date" value="#form.date_end#">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#form.award_points#" maxlength="10">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			)
		</cfquery>
	</cfif>
	<cfset pgfn = "main">
</cfif>

<cfif isDefined("delete")>
	<cfquery name="DeleteQuery" datasource="#application.DS#">
		DELETE FROM #application.database#.program_register
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
		AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<!--- <cfset request.main_width = 900> --->
<cfinclude template="includes/header.cfm">

<cfif pgfn EQ "main">
	<cfoutput>
	<span class="pagetitle">Edit Registration for #request.program_name#</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="program_details.cfm">Award Program Details</a> or <a href="program_list.cfm">Award Program List</a> without making changes.</span>
	<br /><br />
	</cfoutput>

<cfset tinymce_fields = "register_page_text,register_form_text">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">

	<cfquery name="ToBeEdited" datasource="#application.DS#">
		SELECT has_register, register_email_domain, register_page_text, register_form_text, register_template_id, register_email_subject
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cfset has_register = htmleditformat(ToBeEdited.has_register)>
	<cfset register_email_domain = htmleditformat(ToBeEdited.register_email_domain)>
	<cfset register_page_text = htmleditformat(ToBeEdited.register_page_text)>
	<cfset register_form_text = htmleditformat(ToBeEdited.register_form_text)>
	<cfset register_template_id = htmleditformat(ToBeEdited.register_template_id)>
	<cfset register_email_subject = htmleditformat(ToBeEdited.register_email_subject)>
	

	<cfoutput>
	
	<form method="post" action="#CurrentPage#">
	
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		
		<tr class="contenthead">
		<td colspan="2" class="headertext">Registration Page</td>
		</tr>
						
		<tr class="content">
		<td align="right" valign="top">Public site has a user register page? </td>
		<td valign="top">
			<select name="has_register">
				<option value="1"<cfif has_register EQ 1> selected</cfif>>Yes</option>
				<option value="0"<cfif has_register EQ 0> selected</cfif>>No</option>
			</select>
		</td>
		</tr>
	
		<tr class="content">
		<td align="right" valign="top">Restrict users to certain email domains?<br><span class="sub">[example:  #ListLast(Application.DefaultEmailFrom,'@')#]</span> </td>
		<td valign="top"><input type="text" name="register_email_domain" value="#register_email_domain#" maxlength="255" size="40"><br>
			<span class="sub">Leave blank if user may have any email address.</span>
		</td>
		</tr>

		<cfquery name="SelectEmailTemplates" datasource="#application.DS#">
			SELECT ea.ID, ea.email_title 
			FROM #application.database#.email_template ea
			JOIN #application.database#.xref_program_email_template xref ON ea.ID = xref.email_template_ID
			WHERE ea.is_available = 1
			AND xref.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
			ORDER BY ea.email_title ASC
		</cfquery>
		<tr class="content">
		<td align="right" valign="top">Registration Confirmation Email Template:</td>
		<td valign="top">
			<select name="register_template_id" id="s_template_ID">
				<option value="0">-- Do not send registration confirmation email --</option>
				<cfloop query="SelectEmailTemplates">
				<option value="#SelectEmailTemplates.ID#" <cfif SelectEmailTemplates.ID EQ register_template_id>selected</cfif>>#SelectEmailTemplates.email_title#</option>
				</cfloop>
			</select>
			<br>
			&nbsp;&nbsp;&nbsp;&nbsp;<a href="##" onClick="openPreview();return false;">preview selected template</a>
		</td>
		</tr>
		<tr class="content">
		<td align="right" valign="top">Registration Confirmation Email Subject: </td>
		<td valign="top"><input type="text" name="register_email_subject" value="#register_email_subject#" maxlength="64" size="40">
		</td>
		</tr>


		<tr class="contenthead">
		<td colspan="2">&nbsp;&nbsp;&nbsp;&nbsp;<strong>Registration Menu text</strong>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="sub">Appears to the left of the registration page</span></td>
		</tr>
		<tr class="content">
		<td colspan="2" align="center"><textarea name="register_page_text" cols="60" rows="15">#register_page_text#</textarea></td>
		</tr>
	
		<tr class="contenthead">
		<td colspan="2">&nbsp;&nbsp;&nbsp;&nbsp;<strong>Text above registration form</strong></td>
		</tr>
		<tr class="content">
		<td colspan="2" align="center"><textarea name="register_form_text" cols="60" rows="15">#register_form_text#</textarea></td>
		</tr>
	
		<tr class="content">
		<td colspan="2" align="center">
			
		<input type="submit" name="SaveMain" value="   Save Changes   " >
	
		</td>
		</tr>
			
		</table>
	
	</form>
	</cfoutput>
	<cfquery name="SelectRegisters" datasource="#application.DS#">
		SELECT ID, register_name, date_start, date_end, award_points
		FROM #application.database#.program_register
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		ORDER BY date_start DESC
	</cfquery>
	<cfoutput>
	<br /><br />
	<span class="pagetitle">Registrations</span>
	<br /><br />
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
		<tr class="contenthead">
		<td colspan="5" class="headertext">Program Registrations</td>
		</tr>
		<tr class="contenthead">
		<td><a href="#CurrentPage#?pgfn=add">Add</a></td>
		<td class="headertext">Name</td>
		<td class="headertext">Start Date</td>
		<td class="headertext">End Date</td>
		<td class="headertext" align="right">Awards Points</td>
		</tr>
		<cfif SelectRegisters.RecordCount IS 0>
			<tr class="content2">
			<td colspan="5" align="center"><br>No registrations found.<br><br>Click "add" to enter a registration for this program.<br><br></td>
			</tr>
		</cfif>
		<cfloop query="SelectRegisters">
			<tr class="#Iif(((SelectRegisters.CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
			<td><a href="#CurrentPage#?pgfn=edit&register_ID=#SelectRegisters.ID#">Edit</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?delete=#SelectRegisters.ID#" onclick="return confirm('Are you sure you want to delete this program registration?  There is NO UNDO.')">Delete</a></td>
			<td>#HTMLEditFormat(register_name)#</td>
			<td>#DateFormat(date_start,"mm/dd/yyyy")#</td>
			<td>#DateFormat(date_end,"mm/dd/yyyy")#</td>
			<td align="right">#award_points#</td>
			</tr>
		</cfloop>	
	</table>
	</cfoutput>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<cfif pgfn EQ "edit">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, register_name, date_start, date_end, award_points
			FROM #application.database#.program_register
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#register_ID#" maxlength="10">
		</cfquery>
		<cfset register_ID = ToBeEdited.ID>
		<cfset register_name = htmleditformat(ToBeEdited.register_name)>
		<cfset date_start = dateformat(ToBeEdited.date_start,"mm/dd/yyyy")>
		<cfset date_end = dateformat(ToBeEdited.date_end,"mm/dd/yyyy")>
		<cfset award_points = ToBeEdited.award_points>
	</cfif>
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Program Registration for #request.program_name#</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#">Program Register Page</a> or <a href="program_list.cfm">Award Program List</a> without making changes.</span>
	<br /><br />
	
	<form method="post" action="#CurrentPage#">

		<table cellpadding="5" cellspacing="1" border="0">
		
		<tr class="contenthead">
		<td colspan="100%"><span class="headertext">Program Registration</span></td>
		</tr>
		
		<tr class="content">
		<td align="right">Registration name:<br> <span class="sub">Only used here in admin</span> </td>
		<td><input type="text" name="register_name" value="#register_name#" maxlength="32" size="30"></td>
		</tr>
		
		<tr class="content">
		<td align="right">Start Date: </td>
		<td><input type="text" name="date_start" value="#date_start#" maxlength="10" size="10"></td>
		</tr>
		
		<tr class="content">
		<td align="right">End Date: </td>
		<td><input type="text" name="date_end" value="#date_end#" maxlength="10" size="10"></td>
		</tr>
			
		<tr class="content">
		<td align="right">Points to Award: </td>
		<td><input type="text" name="award_points" value="#award_points#" maxlength="10" size="10"></td>
		</tr>
			
		<tr class="content">
		<td colspan="100%" align="center">
		
		<input type="hidden" name="pgfn" value="#pgfn#">
		
		<input type="hidden" name="register_ID" value="#register_ID#">
		
		<input type="submit" name="SaveRegister" value="   Save Changes   " >
	
		</td>
		</tr>
			
		</table>
	</form>
	</cfoutput>
	<!--- END pgfn ADD/EDIT --->
</cfif>
<script>
var TheWindow = null

function openPreview() {
	// if a window exists and is open, close it
	if (TheWindow != null) {
		TheWindow.close()
	}
	// find the selected one in the select
	previewId = document.getElementById('s_template_ID')
	previewIdValue = previewId.options[previewId.selectedIndex].value
	if (previewIdValue > 0) {
		// open new window with preview	
		TheWindow = window.open('email_alert_preview.cfm?ID=' + previewIdValue, 'windowname');
	} else {
		alert('Please select a template to preview.');
	}
}

</script>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->