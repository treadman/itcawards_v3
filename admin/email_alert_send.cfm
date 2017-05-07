<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000073-1000000075",true)>

<!--- ********************** --->
<!--- START form processing  --->
<!--- ********************** --->


<cffunction name="FLITCAwards_FindRecipients" output="true">
	<cfargument name="FLITCAwards_ChosenRecipients" required="yes">
	<cfargument name="FLITCAwards_ExpireDate" required="no" default="">
	<cfargument name="FLITCAwards_AwardLevel" required="no" default="">
	<cfargument name="FLITCAwards_DateOfAward" required="no" default="">
	<cfargument name="FLITCAwards_OnlyEmails" required="no" default="true">
	<cfargument name="FLITCAwards_return" required="no" default="true">
	<cfargument name="FLITCAwards_HasRadio" required="no" default="false">
	<cfargument name="FLITCAwards_ShowSupervisor" required="no" default="false">
	
	<cfset FLITCAwards_DateOfAward = DateFormat(FLITCAwards_DateOfAward,'yyyy-mm-dd')>
	<cfquery name="SelectProgramInfo" datasource="#application.DS#">
		SELECT points_multiplier
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cfset points_multiplier = SelectProgramInfo.points_multiplier>
	<cfquery name="FLITCAwards_SelectRecipients" datasource="#application.DS#">
		SELECT ID AS this_user_ID, fname, lname, email, Date_Format(expiration_date,'%c/%d/%Y') AS expiration_date, Format((((SELECT IFNULL(SUM(points),0)
		FROM #application.database#.awards_points
		WHERE user_ID = this_user_ID AND is_defered = 0) - (SELECT IFNULL(SUM(points_used),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1)) * #SelectProgramInfo.points_multiplier#),0) AS remaining_points, supervisor_email, level_of_award, username, 
		<cfif FLITCAwards_ChosenRecipients EQ 10>
		Format(((SELECT IFNULL(SUM(subpoints),0) FROM #application.database#.subprogram_points 
			WHERE user_ID = this_user_ID 
			AND subprogram_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#sub_ID#">) 
			 * #SelectProgramInfo.points_multiplier#),0) AS subprogram_points, 
		</cfif>
		<cfif FLITCAwards_OnlyEmails EQ true>
			email AS ListText
		<cfelse>
<!---
			CONCAT(IFNULL(fname,'(no first name)'),' ',IFNULL(lname,'(no last name)'),', <b>',email,IF(TRIM(supervisor_email) <> '',' has a supervisor',''),'</b> ',
				Format((((SELECT IFNULL(SUM(points),0) FROM #application.database#.awards_points WHERE user_ID = this_user_ID AND is_defered = 0) - (SELECT IFNULL(SUM(points_used),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1))* #SelectProgramInfo.points_multiplier#),0),' points'
			<cfif FLITCAwards_ChosenRecipients EQ 10>
					,' and ',Format(((SELECT IFNULL(SUM(subpoints),0) FROM #application.database#.subprogram_points WHERE user_ID = this_user_ID AND subprogram_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#sub_ID#">) * #SelectProgramInfo.points_multiplier#),0),' subpoints'
				
			</cfif>
				
			 ) AS ListText
--->
email AS ListText
		</cfif> 
		FROM #application.database#.program_user
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
			AND email <> ''
			AND email IS NOT NULL
			AND is_active = 1
			<!--- not expired --->
			<cfif FLITCAwards_ChosenRecipients EQ 2 OR FLITCAwards_ChosenRecipients EQ 3 OR FLITCAwards_ChosenRecipients EQ 6>
			AND (expiration_date >= CURDATE() OR expiration_date IS NULL)
			</cfif>
			<!--- expires on entered date --->
			<cfif (FLITCAwards_ChosenRecipients EQ 4 OR FLITCAwards_ChosenRecipients EQ 5) AND IsDate(FLITCAwards_ExpireDate)>
			AND expiration_date = <cfqueryparam cfsqltype="cf_sql_date" value="#FLITCAwards_ExpireDate#">
			</cfif>
			<!--- has remaining points --->
			<cfif FLITCAwards_ChosenRecipients EQ 3 OR FLITCAwards_ChosenRecipients EQ 5 OR FLITCAwards_ChosenRecipients EQ 6>
				AND 
				
				(SELECT IFNULL(SUM(points),0) FROM #application.database#.awards_points WHERE user_ID = this_user_ID AND is_defered = 0) 
				- 
				(SELECT IFNULL(SUM(points_used),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1)
				> 0
			</cfif>
			<!--- has THIS level of award --->
			<cfif FLITCAwards_ChosenRecipients EQ 6>
				AND level_of_award = <cfqueryparam cfsqltype="cf_sql_integer" value="#FLITCAwards_AwardLevel#">
			</cfif>
			<!--- has THIS award date --->
			<cfif FLITCAwards_ChosenRecipients EQ 7>
				AND ((	SELECT COUNT(ID) 
						FROM #application.database#.awards_points
						WHERE user_ID = this_user_ID
							AND DATE_FORMAT(created_datetime,'%Y-%m-%d') = '#FLITCAwards_DateOfAward#') >= 1)
			</cfif>
			<!--- is in this email alert group --->
			<cfif FLITCAwards_ChosenRecipients EQ 8>
				AND ((	SELECT COUNT(ID) 
						FROM #application.database#.xref_user_emailgroup 
						WHERE user_ID = this_user_ID
							AND emailgroup_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#email_alert_group#">) = 1)
			</cfif>
			<!--- has X point total --->
			<cfif FLITCAwards_ChosenRecipients EQ 9>
				AND 
				
				(SELECT IFNULL(SUM(points),0) FROM #application.database#.awards_points WHERE user_ID = this_user_ID AND is_defered = 0) 
				- 
				(SELECT IFNULL(SUM(points_used),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1)
				= <cfqueryparam cfsqltype="cf_sql_integer" value="#point_total#">
			</cfif>
			<cfif FLITCAwards_ChosenRecipients EQ 91>
				AND 
				
				(SELECT IFNULL(SUM(points),0) FROM #application.database#.awards_points WHERE user_ID = this_user_ID AND is_defered = 0) 
				- 
				(SELECT IFNULL(SUM(points_used),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1)
				<= <cfqueryparam cfsqltype="cf_sql_integer" value="#point_total#">
			</cfif>
			<cfif FLITCAwards_ChosenRecipients EQ 92>
				AND 
				
				(SELECT IFNULL(SUM(points),0) FROM #application.database#.awards_points WHERE user_ID = this_user_ID AND is_defered = 0) 
				- 
				(SELECT IFNULL(SUM(points_used),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1)
				>= <cfqueryparam cfsqltype="cf_sql_integer" value="#point_total#">
			</cfif>
			<!--- has a point total in X subprogram --->
			<cfif FLITCAwards_ChosenRecipients EQ 10 AND sub_ID NEQ "">
				AND 
				(SELECT IFNULL(SUM(subpoints),0) FROM #application.database#.subprogram_points WHERE user_ID = this_user_ID AND subprogram_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#sub_ID#">)
				> 0
			</cfif>
		ORDER BY lname, fname ASC 
	</cfquery>
	<cfif FLITCAwards_return EQ "true">
		<cfif FLITCAwards_SelectRecipients.RecordCount EQ 0>
			<cfreturn '<span class="alert">No Recipients</span> <a href="##" onClick="submitLinkForm('''',''4_pickrecipients'','''','''');return false;">Choose different recipients.</a>'>
			<cfset panel_number = "4_pickrecipients">
		<cfelseif FLITCAwards_OnlyEmails EQ true>
			<cfreturn ValueList(FLITCAwards_SelectRecipients.ListText,",")>
		<cfelseif FLITCAwards_HasRadio EQ true>
			<cfloop query="FLITCAwards_SelectRecipients">
				<input type="radio" name="spoof" value="#this_user_ID#"<cfif CurrentRow EQ 1> checked</cfif>> #ListText#<br>
			</cfloop>
		<cfelseif FLITCAwards_HasRadio EQ false>
			<cfreturn ValueList(FLITCAwards_SelectRecipients.ListText,"<br>")>
		</cfif>
	</cfif>
</cffunction>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "email_alert_send">
<cfinclude template="includes/header.cfm">

<cfif has_program>
<script language="javascript">
function validateDate() {
	s_d = document.getElementById('s_date_expire')
	d = document.getElementById('date_expire')
	s_d.value = s_d.value.replace(/[^\d\/]/g,"")

	if (s_d.value == "")
	{return false}
	DateArray =  s_d.value.split('/')

	if (DateArray.length != 3)
	{return false}
	
	Month = DateArray[0]
	Day = DateArray[1]
	Year = DateArray[2]
	
	if (Month == "" || Day == "" || Year == "")
	{return false}
	
	if (Month == 0 || Month > 12)
	{return false}
	
	if ((Month == 1 || Month == 3 || Month == 5 || Month == 7 || Month == 8 || Month == 10 || Month == 12) && (Day == 0 || Day > 31))
	{return false}
	
	if ((Month == 4 || Month == 6 || Month == 9 || Month == 11) && (Day == 0 || Day > 30))
	{return false}
	
	if ((Month == 2 && Day > 28) ||(Month == 2 && Day > 29))
	{return false}
	
	if (Year.length != 4)
	{return false}
	
	d.value = DateArray.join('/')
	return true
}
function trim (str) {
	str = this != window? this : str;
	return str.replace(/^\s+/, '').replace(/\s+$/, '');
}

function submitLinkForm(current_panel,next_panel,FromField,ToField) {
	// if panel 1_pickprogram was submitted
	if (current_panel == "1_pickprogram") {
		FromField = document.getElementById(FromField)
		FromValue = FromField.options[FromField.selectedIndex].value
		if (FromValue == "") {
			alert("Please select a program."); return false
		} else {
			ToField = document.getElementById(ToField)
			ToField.value = FromValue
		}
	}
	// if panel 2_picktemplate was submitted
	if (current_panel == "2_picktemplate") {
		FromField = document.getElementById(FromField)
		FromValue = FromField.options[FromField.selectedIndex].value
		ToField = document.getElementById(ToField)
		ToField.value = FromValue
	}
	// if panel 3_fillintheblank was submitted
	if (FromField == 's_fillin') {
		if (trim(document.getElementById('s_fillin').value) == "") {
			alert("Please enter the fill-in-the-blank text.\n\nIf you do not want fill-in-the-blank text, please\nedit this template (click Templates under Email Alerts)\nbefore you can send this broadcast.");
			return false;
		} else {
			FromField = document.getElementById(FromField)
			FromValue = trim(FromField.value)
			ToField = document.getElementById(ToField)
			ToField.value = FromValue
		}
	}
	// if panel 4_pickrecipients was submitted
	if (FromField == 's_recipients') {
		f = document.send_email_form;
		FromField = f.s_recipients;
		for(i=0;i<FromField.length;i++) { 
			if (FromField[i].checked) {
				FromValue = FromField[i].value
				ToField.value = FromValue
				break
			}
		}
		if ((FromValue == "4" || FromValue == "5") && !validateDate()) {
			alert('Please enter a vaild date.'); return false
		} else {
			ToField = document.getElementById(ToField)
			ToField.value = FromValue
		}
		if (FromValue == "6" && document.getElementById('s_award_level').value == "") {
			alert('Please enter a level of award.'); return false
		} else if (FromValue == "6" && document.getElementById('s_award_level').value != "") {
			document.getElementById('award_level').value = document.getElementById('s_award_level').value
			ToField = document.getElementById('recipients')
			ToField.value = FromValue
		}
		if (FromValue == "7" && document.getElementById('s_date_of_award').value == "") {
			alert('Please enter a date of award.'); return false
		} else if (FromValue == "7" && document.getElementById('s_date_of_award').value != "") {
			document.getElementById('date_of_award').value = document.getElementById('s_date_of_award').value
			ToField = document.getElementById('recipients')
			ToField.value = FromValue
		}
		if (FromValue == "8") {
			GroupField = document.getElementById('s_email_alert_group')
			GroupValue = GroupField.options[GroupField.selectedIndex].value
			document.getElementById('email_alert_group').value = GroupValue
			ToField = document.getElementById('recipients')
			ToField.value = FromValue
		}
		if (FromValue == "9" && trim(document.getElementById('s_point_total').value) == "") {
			alert('Please enter a point total.'); return false
		} else if (FromValue == "9" && isNaN(document.getElementById('s_point_total').value)) {
				alert('The point total must be a number.'); return false
		} else if (FromValue == "9" && trim(document.getElementById('s_point_total').value) != "") {
			document.getElementById('point_total').value = document.getElementById('s_point_total').value
			ToField = document.getElementById('recipients')
			ToField.value = FromValue
		}
		if (FromValue == "91" && trim(document.getElementById('s_point_total').value) == "") {
			alert('Please enter a point total.'); return false
		} else if (FromValue == "91" && isNaN(document.getElementById('s_point_total').value)) {
				alert('The point total must be a number.'); return false
		} else if (FromValue == "91" && trim(document.getElementById('s_point_total').value) != "") {
			document.getElementById('point_total').value = document.getElementById('s_point_total').value
			ToField = document.getElementById('recipients')
			ToField.value = FromValue
		}
		if (FromValue == "92" && trim(document.getElementById('s_point_total').value) == "") {
			alert('Please enter a point total.'); return false
		} else if (FromValue == "92" && isNaN(document.getElementById('s_point_total').value)) {
				alert('The point total must be a number.'); return false
		} else if (FromValue == "92" && trim(document.getElementById('s_point_total').value) != "") {
			document.getElementById('point_total').value = document.getElementById('s_point_total').value
			ToField = document.getElementById('recipients')
			ToField.value = FromValue
		}
		if (FromValue == "10" && document.getElementById('s_subprogram').value == "") {
			alert('Please choose a subprogram.'); return false
		} else if (FromValue == "10" && document.getElementById('s_subprogram').value != "") {
			document.getElementById('sub_ID').value = document.getElementById('s_subprogram').value
			ToField = document.getElementById('recipients')
			ToField.value = FromValue
		}
	}
	// if panel 5_preview, validate the test email info
	if (current_panel == "5_preview") {
		if (document.getElementById('s_email_subject').value == "" || document.getElementById('email_test').value == "" || document.getElementById('s_from_email').value == "") {
			alert('Please complete all three fields: email subject, to email, and from email.'); return false
		} else {
			document.getElementById('from_email').value = document.getElementById('s_from_email').value
			document.getElementById('email_subject').value = document.getElementById('s_email_subject').value
		}
	}
	// setting the next panel number and submitting the form
	f = document.send_email_form
	f.panel_number.value = next_panel
	f.submit()
}
// f = document.send_email_form
// ToField = document.getElementById(ToField)
// FromField = document.getElementById(FromField)
// FromValue = FromField.options[FromField.selectedIndex].value
// ToField.value = FromValue

TheWindow = null

function openPreview() {
	// if a window exists and is open, close it
	if (TheWindow != null) {
		TheWindow.close()
	}
	// find the selected one in the select
	previewId = document.getElementById('s_template_ID')
	previewIdValue = previewId.options[previewId.selectedIndex].value
	
	// open new window with preview	
	TheWindow = window.open('email_alert_preview.cfm?ID='+previewIdValue,'windowname');
	
}

function showThis(id) {
	if (document.all) {
		document.getElementById(id).style.display = 'inline';
	} else {
		document.getElementById(id).style.display = 'table-row';
	}
}

function hideThis(id) {
	document.getElementById(id).style.display = 'none';
}
</script>
</cfif>


<span class="pagetitle">Send an Email Alert<cfif has_program><cfoutput> for #request.program_name#</cfoutput></cfif></span>
<br /><br />

<cfif NOT has_program>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

<!--- START / PAGE SET UP --->

<!--- if a Program Admin, skip to panel 2 --->
<cfparam name="panel_number" default="2_picktemplate">

<!--- whether to show "go back to the start" link --->
<cfif panel_number NEQ "2_picktemplate">
	<span class="pageinstructions">Would you like to <a href="<cfoutput>#CurrentPage#</cfoutput>">start over</a>? You will lose all current settings.</span>
	<br /><br />
</cfif>

<!--- param form fields --->
<cfparam name="template_ID" default="">
<cfparam name="fillin" default="">
<cfparam name="recipients" default="">
<cfparam name="date_expire" default="">
<cfparam name="email_subject" default="">
<cfparam name="from_email" default="#Application.DefaultEmailFrom#">
<cfparam name="award_level" default="">
<cfparam name="date_of_award" default="">
<cfparam name="email_alert_group" default="">
<cfparam name="send_sup_email" default="">
<cfparam name="attach_cert" default="">
<cfparam name="point_total" default="">
<cfparam name="sub_ID" default="">

<cfoutput>
<form action="#CurrentPage#" method="post" name="send_email_form" id="send_email_form" onkeypress="return event.keyCode!=13">
	<input type="hidden" name="panel_number" id="panel_number" value="#panel_number#" />
	<input type="hidden" name="template_ID" id="template_ID" value="#template_ID#" />
	<input type="hidden" name="fillin" id="fillin" value="#HTMLEditFormat(fillin)#" />
	<input type="hidden" name="recipients" id="recipients" value="#recipients#" />
	<input type="hidden" name="date_expire" id="date_expire" value="#date_expire#" />
	<input type="hidden" name="email_subject" id="email_subject" value="#email_subject#" />
	<input type="hidden" name="from_email" id="from_email" value="#Application.DefaultEmailFrom#" />
	<input type="hidden" name="award_level" id="award_level" value="#award_level#" />
	<input type="hidden" name="date_of_award" id="date_of_award" value="#date_of_award#" />
	<input type="hidden" name="email_alert_group" id="email_alert_group" value="#email_alert_group#" />
	<input type="hidden" name="send_sup_email" id="send_sup_email" value="#send_sup_email#" />
	<input type="hidden" name="attach_cert" id="attach_cert" value="#attach_cert#" />
	<input type="hidden" name="point_total" id="point_total" value="#point_total#" />
	<input type="hidden" name="sub_ID" id="sub_ID" value="#sub_ID#" />
	<!--- set selected program name --->
	<cfif has_program>
		<cfset choosen_program = request.program_name>
	</cfif>
	<!--- set selected email template name --->
	<cfif template_ID NEQ "">
		<cfquery name="GetTemplateInfo" datasource="#application.DS#">
			SELECT email_title
			FROM #application.database#.email_template
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#template_ID#">
		</cfquery>
		<cfset choosen_template = GetTemplateInfo.email_title>
	</cfif>

	<!--- set selected email group name --->
	<cfif email_alert_group NEQ "">
		<cfquery name="GetGroupInfo" datasource="#application.DS#">
			SELECT emailgroup_name 
			FROM #application.database#.email_groups
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#email_alert_group#">
		</cfquery>
		<cfset choosen_group = GetGroupInfo.emailgroup_name>
	<cfelse>
		<cfset choosen_group = "It's Nothing!">
	</cfif>

	<!--- set selected subprogram name --->
	<cfif sub_ID NEQ "">
		<cfquery name="GetSubprogramName" datasource="#application.DS#">
			SELECT subprogram_name 
			FROM #application.database#.subprogram
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#sub_ID#">
		</cfquery>
		<cfset chosen_subprogram = GetSubprogramName.subprogram_name>
	<cfelse>
		<cfset chosen_subprogram = "It's Nothing!">
	</cfif>

	<!--- set selected recipient text --->
	<cfif recipients NEQ "">
		<cfswitch expression="#recipients#">	
			<cfcase value="1">
				<cfset choosen_recipients = "All program users">
			</cfcase>
			<cfcase value="2">
				<cfset choosen_recipients = "Program users who are not expired">
			</cfcase>
			<cfcase value="3">
				<cfset choosen_recipients = "Program users who are not expired and have points remaining">
			</cfcase>
			<cfcase value="4">
				<cfset choosen_recipients = "Program users that expire on #date_expire#">
			</cfcase>
			<cfcase value="5">
				<cfset choosen_recipients = "Program users that expire on #date_expire# and have points remaining">
			</cfcase>
			<cfcase value="6">
				<cfset choosen_recipients = "Program users whose level of award is #award_level# and have points remaining">
			</cfcase>
			<cfcase value="7">
				<cfset choosen_recipients = "Program users whose date of award is #date_of_award# and have points remaining">
			</cfcase>
			<cfcase value="8">
				<cfset choosen_recipients = "Program users who are in the Email Alert Group #choosen_group#">
			</cfcase>
			<cfcase value="9">
				<cfset choosen_recipients = "Program users who have a point total of #point_total#">
			</cfcase>
			<cfcase value="91">
				<cfset choosen_recipients = "Program users who have a point total of #point_total# or LESS">
			</cfcase>
			<cfcase value="92">
				<cfset choosen_recipients = "Program users who have a point total of #point_total# or MORE">
			</cfcase>
			<cfcase value="10">
				<cfset choosen_recipients = "Program users who have points assigned to the #chosen_subprogram# subprogram">
			</cfcase>
		</cfswitch>
	</cfif>

	<cfif send_sup_email EQ "1">
		<cfset choosen_recipients = choosen_recipients & "<br>Send Supervisor Copy, if user has a supervisor">
	</cfif>

	<cfif attach_cert EQ "1">
		<cfset choosen_recipients = choosen_recipients & "<br>Attach Certificate, if user has a certificate">
	</cfif>

	<!--- 
		PANELS:
		2_picktemplate
		3_fillintheblank
		4_pickrecipients
		5_preview
		6_sendtestemail
		7_sendemail
	 --->

	<!--- 2. pick an email template --->
	<cfif panel_number EQ "2_picktemplate">
		<cfquery name="SelectEmailTemplates" datasource="#application.DS#">
			SELECT ea.ID, ea.email_title 
			FROM #application.database#.email_template ea
			JOIN #application.database#.xref_program_email_template xref ON ea.ID = xref.email_template_ID
			WHERE ea.is_available = 1
			AND xref.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
			ORDER BY ea.email_title ASC
		</cfquery>
		<cfif SelectEmailTemplates.recordcount EQ 0>
			<span class="alert">There are no email templates assigned to #request.program_name#.</span>
		<cfelse>
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr class="contenthead">
		<td colspan="2" class="headertext">Select Email Alert Template</td>
		</tr>
		<tr class="content">
		<td colspan="2"><span class="sub">Program:</span> #choosen_program#</td>
		</tr>
		<tr class="content">
		<td>
			<select name="s_template_ID" id="s_template_ID">
				<cfloop query="SelectEmailTemplates">
				<option value="#ID#">#email_title#</option>
				</cfloop>
			</select>
			&nbsp;&nbsp;&nbsp;&nbsp;<a href="##" onClick="openPreview();return false;">preview selected template</a>
		</td>
		</tr>
		<tr class="content">
		<td><input type="submit" value="Select This Template" name="submit_button" onclick="submitLinkForm('2_picktemplate','3_fillintheblank','s_template_ID','template_ID');return false;"></td>
		</tr>
		</table>
		</cfif>
	<!--- 3.enter fill in the blank --->
	<cfelseif panel_number EQ "3_fillintheblank">
		<cfquery name="FindTemplateText" datasource="#application.DS#">
			SELECT email_text 
			FROM #application.database#.email_template
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#template_ID#">
		</cfquery>

		<!--- go to next step if no fill in the blank fields in email template --->
		<cfif Find("FILL-IN-THE-BLANK",FindTemplateText.email_text) EQ 0>
			<script language="javascript">submitLinkForm('3_fillintheblank','4_pickrecipients','','')</script>
		</cfif>

		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr class="contenthead">
		<td colspan="2" class="headertext">Enter Fill-In-The-Blank Text</td>
		</tr>
		<tr class="content">
		<td colspan="2"><span class="sub">Program:</span> #choosen_program#</td>
		</tr>
		<tr class="content">	
		<td colspan="2"><span class="sub">Template:</span> #choosen_template#&nbsp;&nbsp;&nbsp;&nbsp;<a href="email_alert_preview.cfm?ID=#template_ID#" target="_blank">preview</a></td>
		</tr>
		<tr class="content">
		<td>
		<span class="sub">This text will replace the template code FILL-IN-THE-BLANK and will be the same in every email.</span><br />
			<textarea name="s_fillin" id="s_fillin" rows="5" cols="80"></textarea>
		</td>
		</tr>
		<tr class="content">
		<td><input type="submit" value="Save Text" name="submit_button" onclick="submitLinkForm('3_fillintheblank','4_pickrecipients','s_fillin','fillin');return false;"></td>
		</tr>
		</table>

	<!--- 4. pick recipients --->
	<cfelseif panel_number EQ "4_pickrecipients">
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
			<tr class="contenthead">
				<td colspan="2" class="headertext">Choose Recipients</td>
			</tr>
			<tr class="content">
				<td colspan="2"><span class="sub">Program:</span> #choosen_program#</td>
			</tr>
			<tr class="content">
				<td colspan="2"><span class="sub">Template:</span> #choosen_template#&nbsp;&nbsp;&nbsp;&nbsp;<a href="email_alert_preview.cfm?ID=#template_ID#" target="_blank">preview</a></td>
			</tr>
			<cfif fillin NEQ "">
				<tr class="content">
					<td colspan="2"><span class="sub">Fill In The Blank:</span></td>
				</tr>
				<tr class="content2">
					<td colspan="2" style="padding-left:30px">#Replace(fillin,chr(10),"<br>","ALL")#</td>
				</tr>
			</cfif>
			<tr class="content">
				<td>
					<input type="radio" name="s_recipients" value="1" checked="checked" onClick="hideThis('date_line');hideThis('point_line');hideThis('group_line');hideThis('subprogram_line');"> All program users<br>
					<input type="radio" name="s_recipients" value="2" onClick="hideThis('date_line');hideThis('point_line');hideThis('group_line');hideThis('subprogram_line');"> Program users who are not expired<br>
					<input type="radio" name="s_recipients" value="3" onClick="hideThis('date_line');hideThis('point_line');hideThis('group_line');hideThis('subprogram_line');"> Program users who are not expired and have points remaining<br>
					<input type="radio" name="s_recipients" value="4" onClick="showThis('date_line');hideThis('point_line');hideThis('group_line');hideThis('subprogram_line');"> Program users that expire on a certain day<br>
					<input type="radio" name="s_recipients" value="5" onClick="showThis('date_line');hideThis('point_line');hideThis('group_line');hideThis('subprogram_line');"> Program users that expire on a certain day and have points remaining<br>
					<!--- show/hide DATE_LINE --->
					<div style="padding-left:30px;"><span id="date_line" style="display:none"><br>
					<b>Expiration Date: </b> <input type="text" name="s_date_expire" id="s_date_expire" size="15" maxlength="10"> format: 1/2/2006</span></div>
					<input type="radio" name="s_recipients" value="9" onClick="showThis('point_line');hideThis('date_line');hideThis('group_line');hideThis('subprogram_line');"> Program users who have a certain point total<br>
					<input type="radio" name="s_recipients" value="91" onClick="showThis('point_line');hideThis('date_line');hideThis('group_line');hideThis('subprogram_line');"> Program users who have a certain point total or LESS<br>
					<input type="radio" name="s_recipients" value="92" onClick="showThis('point_line');hideThis('date_line');hideThis('group_line');hideThis('subprogram_line');"> Program users who have a certain point total or MORE<br>
					<!--- show/hide POINT_LINE --->
					<div style="padding-left:30px;"><span id="point_line" style="display:none"><br>
					<b>Point Total: </b> <input type="text" name="s_point_total" id="s_point_total" size="15" maxlength="10"></span></div>
					<cfquery name="FindProgramsGroups" datasource="#application.DS#">
						SELECT ID, emailgroup_name 
						FROM #application.database#.email_groups
						WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
						ORDER BY emailgroup_name ASC 
					</cfquery>
					<cfif FindProgramsGroups.RecordCount GTE 1>
						<input type="radio" name="s_recipients" value="8" onClick="showThis('group_line');hideThis('date_line');hideThis('point_line');hideThis('subprogram_line');"> Program users who are in a certain Email Alert Group<br>
					</cfif>
					<!--- show/hide GROUP_LINE --->
					<div style="padding-left:30px;"><span id="group_line" style="display:none"><br>
					<b>Choose an Email Alert Group: </b> 
					<select name="s_email_alert_group" id="s_email_alert_group">
						<cfloop query="FindProgramsGroups">
						<option value="#ID#">#emailgroup_name#</option>
						</cfloop>
					</select>
					</span></div>
					<cfquery name="FindSubprograms" datasource="#application.DS#">
						SELECT ID, subprogram_name 
						FROM #application.database#.subprogram
						WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
							AND is_active = "1"
						ORDER BY sortorder ASC 
					</cfquery>
					<cfif FindSubprograms.RecordCount GTE 1>
						<input type="radio" name="s_recipients" value="10" onClick="showThis('subprogram_line');hideThis('date_line');hideThis('point_line');hideThis('group_line');"> Program users who have points in a certain Subprogram<br>
					</cfif>
					<!--- show/hide SUBPROGRAM_LINE --->
					<div style="padding-left:30px;"><span id="subprogram_line" style="display:none"><br>
					<b>Choose a Subprogram: </b> 
					<select name="s_subprogram" id="s_subprogram">
						<cfloop query="FindSubprograms">
						<option value="#ID#">#subprogram_name#</option>
						</cfloop>
					</select>
					</span></div>
					<br>
					<table width="100%" bgcolor="##FBFBD4" cellpadding="3">
						<tr>
							<td valign="top" nowrap="nowrap">Check all that apply:</td>
							<td width="99%">
								<input type="checkbox" name="send_sup_email" value="1"> Send Supervisor Copy, if user has a supervisor<br>
								<input type="checkbox" name="attach_cert" value="1"> Attach Certificate, if user has a certificate
							</td>
						</tr>
					</table>
				</td>
			</tr>
			<tr class="content">
				<td><input type="submit" value="Choose These Recipients" name="submit_button" onclick="submitLinkForm('4_pickrecipients','5_preview','s_recipients','recipients');return false;"></td>
			</tr>
		</table>

	<!--- 5. preview email and recipient list, enter subject, from email address and test email to address --->
	<cfelseif panel_number EQ "5_preview">
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr class="contenthead">
		<td colspan="2" class="headertext">Enter Subject and Test Email Alert</td>
		</tr>
		<tr class="content">
		<td colspan="2"><span class="sub">Program:</span> #choosen_program#</td>
		</tr>
		<tr class="content">
		<td colspan="2"><span class="sub">Template:</span> #choosen_template#&nbsp;&nbsp;&nbsp;&nbsp;<a href="email_alert_preview.cfm?ID=#template_ID#" target="_blank">preview</a></td>
		</tr>
		<cfif fillin NEQ "">
		<tr class="content">
		<td colspan="2"><span class="sub">Fill In The Blank:</span></td>
		</tr>
		<tr class="content2">
		<td colspan="2" style="padding-left:30px">#Replace(fillin,chr(10),"<br>","ALL")#</td>
		</tr>
		</cfif>
		<tr class="content">
		<td colspan="2"><span class="sub">Recipients:</span> <span style="padding-left:40px;display:block">#choosen_recipients#</span></td>
		</tr>
		<tr class="content2">
		<td style="padding-left:30px">Pick a user to spoof. The user's supervisor will not get the test email.
		<br>#FLITCAwards_FindRecipients(request.selected_program_ID,recipients,date_expire,award_level,date_of_award,true,true,true)#<br><cfif points_multiplier NEQ 1><br><span class="sub">(users' points shown times credit multiplier)</span></cfif></td>
		</tr>
		<tr class="content">
		<td>Email Subject: <input type="text" name="s_email_subject" id="s_email_subject" size="40" maxlength="60"></td>
		</tr>
		<tr class="content">
		<td>Send Email From: <input type="text" name="s_from_email" id="s_from_email" size="40" maxlength="128" value="#Application.DefaultEmailFrom#" readonly></td>
		</tr>
		<tr class="content">
		<td>Send Test Email To: <input type="text" name="email_test" id="email_test" size="40"></td>
		</tr>
		<tr class="content">
		<td><input type="submit" value="Save Subject and Send Test Email" name="submit_button" onclick="submitLinkForm('5_preview','6_sendtestemail','s_email_subject','email_subject');return false;"></td>
		</tr>
		</table>

	<!--- 6. send test email, and then press button to send email alert to recipient list --->
	<cfelseif panel_number EQ "6_sendtestemail">
		<!--- START Send Test Email --->
		<!--- find template --->
		<cfquery name="TESTFindTemplateText" datasource="#application.DS#">
			SELECT email_text
			FROM #application.database#.email_template
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#template_ID#">
		</cfquery>
		<cfset email_text = TESTFindTemplateText.email_text>

		<!--- find program info --->
		<cfquery name="TESTGetProgramInfo" datasource="#application.DS#">
			SELECT company_name, Date_Format(expiration_date,'%c/%d/%Y') AS expiration_date, points_multiplier
			FROM #application.database#.program
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		</cfquery>

		<!--- find spoof info --->
		<cfquery name="SpoofInfo" datasource="#application.DS#">
			SELECT ID AS this_user_ID, fname, lname, Date_Format(expiration_date,'%c/%d/%Y') AS expiration_date, Format((((SELECT IFNULL(SUM(points),0) FROM #application.database#.awards_points WHERE user_ID = this_user_ID AND is_defered = 0) - (SELECT IFNULL(SUM(points_used),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1)) * #TESTGetProgramInfo.points_multiplier#),0) AS remaining_points, level_of_award, username 
			FROM #application.database#.program_user
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.spoof#">
		</cfquery>

		<cfif FIND("USER-SUBPROGRAM-POINTS",email_text) AND sub_ID NEQ "">
			<cfquery name="SpoofSub" datasource="#application.DS#">
				SELECT IFNULL(SUM(subpoints),0) AS subpoints 
				FROM #application.database#.subprogram_points 
				WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.spoof#"> 
					AND subprogram_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#sub_ID#">
			</cfquery>
			<cfset spoof_subpoints = NumberFormat((SpoofSub.subpoints * TESTGetProgramInfo.points_multiplier),'_')>
		<cfelse>
			<cfset spoof_subpoints = "">
		</cfif>

		<!--- swap out the fill in the blank --->
		<cfif Find("FILL-IN-THE-BLANK",email_text) GT 0>
			<cfset email_text = Replace(email_text,"FILL-IN-THE-BLANK",#fillin#)>
		</cfif>

		<cfset email_text = Replace(email_text,"PROGRAM-NAME-HERE","#TESTGetProgramInfo.company_name#","all")>
		<cfset email_text = Replace(email_text,"PROGRAM-EXPIRATION-DATE","#TESTGetProgramInfo.expiration_date#","all")>
		<cfset email_text = Replace(email_text,"USER-FIRST-NAME",SpoofInfo.fname,"all")>
		<cfset email_text = Replace(email_text,"USER-LAST-NAME",SpoofInfo.lname,"all")>
		<cfset email_text = Replace(email_text,"USER-EXPIRATION-DATE",SpoofInfo.expiration_date,"all")>
		<cfset email_text = Replace(email_text,"USER-REMAINING-POINTS",SpoofInfo.remaining_points,"all")>
		<cfset email_text = Replace(email_text,"USER-SUBPROGRAM-POINTS",spoof_subpoints,"all")>
		<cfset email_text = Replace(email_text,"DATE-TODAY",DateFormat(Now(),'m/d/yyyy'),"all")>
		<cfset email_text = Replace(email_text,"LEVEL-OF-AWARD",SpoofInfo.level_of_award,"all")>
		<cfset email_text = Replace(email_text,"USER-NAME",SpoofInfo.username,"all")>

		<cfif application.OverrideEmail NEQ "">
			<cfset this_to = application.OverrideEmail>
		<cfelse>
			<cfset this_to = form.email_test>
		</cfif>
		<cfmail failto="#Application.ErrorEmailTo#" to="#this_to#" from="#from_email#" subject="TEST - #email_subject#" type="html">
			<cfif application.OverrideEmail NEQ "">
				Emails are being overridden.<br>
				Below is the email that would have been sent to #form.email_test#<br>
				<hr>
			</cfif>
<br><span class="alert" style="letter-spacing:3PX;padding-left:30px">EMAIL ALERT PREVIEW</span><br><br>
<hr size="1" width="100%">	
#email_text#

			<!--- Set Email Attachement --->
			<cfif FileExists(application.AbsPath & "award_certificate/" & SpoofInfo.username & "_certificate_" & request.selected_program_ID & ".pdf")>
				<cfmailparam file = "/award_certificate/#SpoofInfo.username#_certificate_#request.selected_program_ID#.pdf" type ="application/pdf">
			</cfif>
		</cfmail>
		<!--- END Send Test Email --->

		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr class="contenthead">
		<td colspan="2" class="headertext">Send Email Broadcast</td>
		</tr>
		<tr class="content">
		<td colspan="2"><span class="sub">Program:</span> #choosen_program#</td>
		</tr>
		<tr class="content">
		<td colspan="2"><span class="sub">Template:</span> #choosen_template#&nbsp;&nbsp;&nbsp;&nbsp;<a href="email_alert_preview.cfm?ID=#template_ID#" target="_blank">preview</a></td>
		</tr>
		<cfif fillin NEQ "">
		<tr class="content">
		<td colspan="2"><span class="sub">Fill In The Blank:</span></td>
		</tr>
		<tr class="content2">
		<td colspan="2" style="padding-left:30px">#Replace(fillin,chr(10),"<br>","ALL")#</td>
		</tr>
		</cfif>
		<tr class="content">
		<td colspan="2"><span class="sub">Recipients:</span> <span style="padding-left:40px;display:block">#choosen_recipients#</span></td>
		</tr>
		<tr class="content2">
		<td style="padding-left:30px">
			#FLITCAwards_FindRecipients(request.selected_program_ID,recipients,date_expire,award_level,date_of_award,false,true,false,true)#<br><cfif points_multiplier NEQ 1><span class="sub">(users' points shown times credit multiplier)</span><br></cfif>
		</td>
		</tr>
		<tr class="content">
		<td><span class="sub">Email Subject:</span> #email_subject#</td>
		</tr>
		<tr class="content">
		<td><span class="sub">Send Email From:</span> #from_email#</td>
		</tr>
		<tr class="content">
		<td>
		<br>
		<span class="alert">Please review the test email before sending the Email Alert.</span>
		<br><br>
		<input type="submit" value="Send Email To Recipient List" name="submit_button" onclick="submitLinkForm('6_sendtestemail','7_sendemail','','');return false;">
		</td>
		</tr>
		</table>

	<!--- 7. save alert info, send email alert to recipient list and save xref to alert, confirmation message --->
	<cfelseif panel_number EQ "7_sendemail">

		<!--- find template --->
		<cfquery name="ALERTFindTemplateText" datasource="#application.DS#">
			SELECT email_text
			FROM #application.database#.email_template
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#template_ID#">
		</cfquery>
		<cfset email_text = ALERTFindTemplateText.email_text>
	
		<!--- find program info --->
		<cfquery name="ALERTGetProgramInfo" datasource="#application.DS#">
			SELECT company_name, Date_Format(expiration_date,'%c/%d/%Y') AS expiration_date, points_multiplier
			FROM #application.database#.program
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		</cfquery>

		<!--- swap out the fill in the blank --->
		<cfif Find("FILL-IN-THE-BLANK",email_text) GT 0>
			<cfset email_text = Replace(email_text,"FILL-IN-THE-BLANK",#fillin#)>
		</cfif>
		<cfset email_text = Replace(email_text,"PROGRAM-NAME-HERE","#ALERTGetProgramInfo.company_name#","all")>
		<cfset email_text = Replace(email_text,"PROGRAM-EXPIRATION-DATE","#ALERTGetProgramInfo.expiration_date#","all")>
		<cfset email_text = Replace(email_text,"DATE-TODAY",DateFormat(Now(),'m/d/yyyy'),"all")>
		<cfset FLITCAwards_FindRecipients(request.selected_program_ID,recipients,date_expire,award_level,date_of_award,false,false)>

		<!--- insert email alert info --->
		<cflock name="email_alertsLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.email_alerts
					(created_user_ID, created_datetime, program_ID, template_ID, template_text, recipients, exp_date, email_subject, fillin, from_email)
					VALUES (
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#">,
					#FLGen_DateTimeToMySQL()#, 
					<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#template_ID#">,
					<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#email_text#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#choosen_recipients#" maxlength="255">,
					<cfqueryparam cfsqltype="cf_sql_date" value="#date_expire#" null="#YesNoFormat(NOT Len(Trim(date_expire)))#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#email_subject#" maxlength="60">,
					<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#fillin#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#from_email#" maxlength="128">
					)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.email_alerts
				</cfquery>
				<cfset alert_ID = getID.MaxID>
			</cftransaction>
		</cflock>

		<cfset catch_message = "">

		<!--- loop through recipients and swap info and send emails --->
		<br />Multiplier: #ALERTGetProgramInfo.points_multiplier#<br /><br />
		<cfloop query="FLITCAwards_SelectRecipients">
			<cfset email_sent = 'false'>
			<!--- swap out the fill in the blank --->
			<cfset user_email_text = email_text>
			<cfset user_email_text = Replace(user_email_text,"USER-FIRST-NAME",FLITCAwards_SelectRecipients.fname,"all")>
			<cfset user_email_text = Replace(user_email_text,"USER-LAST-NAME",FLITCAwards_SelectRecipients.lname,"all")>
			<cfset user_email_text = Replace(user_email_text,"USER-EXPIRATION-DATE",FLITCAwards_SelectRecipients.expiration_date,"all")>
			<cfset user_email_text = Replace(user_email_text,"USER-REMAINING-POINTS",FLITCAwards_SelectRecipients.remaining_points,"all")>
			<cfif Find("USER-SUBPROGRAM-POINTS",user_email_text) AND sub_ID NEQ "">
				<cfset user_email_text = Replace(user_email_text,"USER-SUBPROGRAM-POINTS",FLITCAwards_SelectRecipients.subprogram_points,"all")>
			</cfif>
			<cfset user_email_text = Replace(user_email_text,"LEVEL-OF-AWARD",FLITCAwards_SelectRecipients.level_of_award,"all")>
			<cfset user_email_text = Replace(user_email_text,"USER-NAME",FLITCAwards_SelectRecipients.username,"all")>
			<cfif application.OverrideEmail NEQ "">
				<cfset this_to = application.OverrideEmail>
			<cfelse>
				<cfset this_to = FLITCAwards_SelectRecipients.email>
			</cfif>
			<cftry>
				<!--- Send Email Alert --->
				<cfmail failto="#Application.ErrorEmailTo#" to="#this_to#" from="#from_email#" subject="#email_subject#" type="html">
					<cfif application.OverrideEmail NEQ "">
						Emails are being overridden.<br>
						Below is the email that would have been sent to #FLITCAwards_SelectRecipients.email#<br>
						<hr>
					</cfif>
#user_email_text#

					<!--- Set Email Attachement --->
					<cfif attach_cert EQ "1">
						<cfif FileExists(application.AbsPath & "award_certificate/" & FLITCAwards_SelectRecipients.username & "_certificate_" & request.selected_program_ID & ".pdf")>
							<cfmailparam file = "/award_certificate/#FLITCAwards_SelectRecipients.username#_certificate_#request.selected_program_ID#.pdf" type ="application/pdf">
						</cfif>
					</cfif>
				</cfmail>
				<cfset email_sent = true>
				<cfcatch><cfset catch_message = catch_message & "<br><br><b>email not sent</b> -- [username: #FLITCAwards_SelectRecipients.username#] [email: #FLITCAwards_SelectRecipients.email#]"></cfcatch>
			</cftry>
			<!--- Send Email Alert TO SUPERVISOR --->
			<cfif send_sup_email EQ "1">
				<cfif FLITCAwards_SelectRecipients.supervisor_email NEQ ""> 
					<cfif application.OverrideEmail NEQ "">
						<cfset this_to = application.OverrideEmail>
					<cfelse>
						<cfset this_to = FLITCAwards_SelectRecipients.supervisor_email>
					</cfif>
					<cftry>
						<cfmail failto="#Application.ErrorEmailTo#" to="#this_to#" from="#from_email#" subject="Supervisor Copy - #email_subject#" type="html">
							<cfif application.OverrideEmail NEQ "">
								Emails are being overridden.<br>
								Below is the email that would have been sent to #FLITCAwards_SelectRecipients.supervisor_email#<br>
								<hr>
							</cfif>
THIS EMAIL IS THE SUPERVISOR'S COPY - THE ORIGINAL WAS SENT TO THE EMPLOYEE
#user_email_text#
							<!--- Set Email Attachement --->
							<cfif attach_cert EQ "1">
								<cfif FileExists(application.AbsPath & "award_certificate/" & FLITCAwards_SelectRecipients.username & "_certificate_" & request.selected_program_ID & ".pdf")>
									<cfmailparam file = "/award_certificate/#FLITCAwards_SelectRecipients.username#_certificate_#request.selected_program_ID#.pdf" type ="application/pdf">
								</cfif>
							</cfif>
						</cfmail>
						<cfcatch><cfset catch_message = catch_message & "<br><br><b>supervisor email not sent</b> -- [username: #FLITCAwards_SelectRecipients.username#] [email: #FLITCAwards_SelectRecipients.email#] [sup email: #FLITCAwards_SelectRecipients.supervisor_email#]"></cfcatch>
					</cftry>
				</cfif>
			</cfif>
			<cfif ALERTGetProgramInfo.points_multiplier GT 1>
				<cfset snap_remaining_points = Replace(FLITCAwards_SelectRecipients.remaining_points,",","","all") / ALERTGetProgramInfo.points_multiplier>
			<cfelse>
				<cfset snap_remaining_points = Replace(FLITCAwards_SelectRecipients.remaining_points,",","","all")>
			</cfif>
			<cfif email_sent>
				<!--- insert xref --->
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.xref_alerts_users
					(created_user_ID, created_datetime, alert_ID, user_ID, user_points, user_email)
					VALUES (
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#">,
					#FLGen_DateTimeToMySQL()#, 
					<cfqueryparam cfsqltype="cf_sql_integer" value="#alert_ID#">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLITCAwards_SelectRecipients.this_user_ID#">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#snap_remaining_points#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#FLITCAwards_SelectRecipients.email#" maxlength="128">
					)
				</cfquery>
			</cfif>
		</cfloop>
		<span class="alert">Your email alert was sent.</span>  You can view the broadcast details by clicking Email Alert Reports at left.
		<cfif catch_message NEQ "">
			<br><br>
			<span class="alert">EXCEPTIONS:</span>
			#catch_message#
		</cfif>
	</cfif>
</form>
</cfoutput>
</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->