<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000111,true)>

<cfparam name="url.pgfn" default="home">

<cfparam name="send_email" default="0">
<cfparam name="from_name" default="From Name">
<cfparam name="from_email" default="#Application.DefaultEmailFrom#">
<cfparam name="email_subject" default="">
<cfparam name="failto" default="#Application.OrdersFailTo#">
<cfparam name="email_text" default="">
<cfparam name="hasHeader" default="1">
<cfparam name="template_ID" default="">
<cfparam name="email" default="">
<cfparam name="firstname" default="">
<cfparam name="lastname" default="">
<cfparam name="points" default="">
<cfparam name="username" default="">
<cfparam name="note" default="">
<cfparam name="address1" default="">
<cfparam name="address2" default="">
<cfparam name="city" default="">
<cfparam name="state" default="">
<cfparam name="zip" default="">

<cfparam name="testing_email" default="">
<cfset alert_error = "">

<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<cfif has_program>
<cfset num_sent = 0>
<cfset DisplayResults = "">
<cfset thisFileName = "upload_points#Replace(CGI.REMOTE_ADDR,'.','','ALL')#">

<cfif IsDefined("form.submitUpload")>
	<cfif form.upload_txt NEQ "">
		<cfset result = FLGen_UploadThis("upload_txt","admin/upload/",thisFileName)>
		<cfif result EQ "false,false">
			<cfset alert_error = "There was an error uploading the file.">
		<cfelse>
			<cfif right(ListLast(result),3) NEQ "csv">
				<cfset alert_error = "That was not a CSV file.">
			<cfelse>
				<cfset url.pgfn = "email_setup">
			</cfif>
		</cfif>
		<cfif alert_error NEQ "">
			<cfset url.pgfn = "upload">
		</cfif>
	</cfif>
</cfif>

<cfif IsDefined("form.submitEmail") OR IsDefined("form.submitTest")>
	<cfset testing_only = IsDefined("form.submitTest")>
	<cfset hasFile = true>
	<cftry>
		<cffile action="read" variable="thisData" file="#application.FilePath#admin/upload/#thisFileName#.csv">
		<cfcatch><cfset hasFile = false></cfcatch>
	</cftry>
	<cfif NOT hasFile>
		<cfset alert_error="Sorry, but the data was lost.  You will have to upload it again.">
	<cfelseif NOT isNumeric(username) OR username LTE 0>
		<cfset alert_error="Please enter the unique identifier column number.">
	</cfif>
	<cfif alert_error EQ "" AND send_email>
		<cfif NOT isNumeric(email) OR email LTE 0>
			<cfset alert_error="Please enter the email address column number.">
		<cfelseif NOT IsNumeric(template_ID)>
			<cfset alert_error="Please select a template.">
		<cfelseif testing_email EQ "" AND testing_only>
			<cfset alert_error="Please enter an email address to send the test to.">
		</cfif>
	</cfif>
	<cfif alert_error EQ "">
		<cfif send_email>
			<cfquery name="getTemplate" datasource="#application.ds#">
				SELECT email_text
				FROM #application.database#.email_template
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#template_ID#">
			</cfquery>
			<cfset email_text = getTemplate.email_text>
		</cfif>
		<cfset thisData = Replace(thisData,"#CHR(13)##CHR(10)#","|","ALL")>
		<cfset first_line = true>
		<cfif NOT hasHeader>
			<cfset first_line = false>
		</cfif>
		<cfset DisplayResults = '<table width="100%" cellpadding="3"><tr><td>Email</td><td>User</td><td>Password</td><td>Notes</td><td align="right">Points</td><tr>'>
		<cfloop list="#thisData#" index="thisLine" delimiters="|">
			<cfif NOT first_line>
				<cfset thisEmail = "">
				<cfset thisFirstname = "">
				<cfset thisLastname = "">
				<cfset thisPoints = "">
				<cfset thisUsername = "">
				<cfset thisAddress1="">
				<cfset thisAddress2="">
				<cfset thisCity="">
				<cfset thisState="">
				<cfset thisZip="">
				<cfset col_num = 1>
				<cfloop list="#thisLine#" index="thisCol">
					<cfif col_num EQ email>
						<cfset thisEmail = thisCol>
					</cfif>
					<cfif firstname NEQ "" AND col_num EQ firstname>
						<cfset thisFirstname = thisCol>
					</cfif>
					<cfif lastname NEQ "" AND col_num EQ lastname>
						<cfset thisLastname = thisCol>
					</cfif>
					<cfif points NEQ "" AND col_num EQ points>
						<cfset thisPoints = thisCol>
					</cfif>
					<cfif username NEQ "" AND col_num EQ username>
						<cfset thisUsername = thisCol>
					</cfif>
					<cfif address1 NEQ "" AND col_num EQ address1>
						<cfset thisaddress1 = thisCol>
					</cfif>
					<cfif address2 NEQ "" AND col_num EQ address2>
						<cfset thisaddress2 = thisCol>
					</cfif>
					<cfif city NEQ "" AND col_num EQ city>
						<cfset thiscity = thisCol>
					</cfif>
					<cfif state NEQ "" AND col_num EQ state>
						<cfset thisstate = thisCol>
					</cfif>
					<cfif zip NEQ "" AND col_num EQ zip>
						<cfset thiszip = thisCol>
					</cfif>
					<cfset col_num = col_num + 1>
				</cfloop>
				<cfset DisplayResults = DisplayResults & '<tr><td>#thisEmail#</td><td>#thisFirstName# #thisLastName#</td><td>#thisUsername#</td>'>
				<!--- Look up user --->
				<cfset User_ID = 0>
				<cfif thisEmail EQ "" OR FLGen_IsValidEmail(thisEmail)>
					<cfif request.program.register_email_domain NEQ "" AND NOT ListFind(request.program.register_email_domain,ListLast(thisEmail,"@"))>
						<cfset DisplayResults = DisplayResults & '<td>WRONG EMAIL DOMAIN</td>'>
					<cfelse>
						<cfquery name="getExistingUser" datasource="#application.DS#">
							SELECT ID, username, fname, lname, expiration_date
							FROM #application.database#.program_user
							WHERE username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#thisUsername#">
							AND program_ID = <cfqueryparam value="#request.selected_program_ID#" cfsqltype="CF_SQL_INTEGER">
						</cfquery>
						<cfif getExistingUser.recordcount EQ 1>
							<cfset DisplayResults = DisplayResults & '<td>Username Found</td>'>
							<cfset User_ID = getExistingUser.ID>
						<cfelseif getExistingUser.recordcount EQ 0>
							<cfif NOT testing_only>
								<cflock name="AddUserLock" timeout="10">
									<cfquery name="AddUser" datasource="#application.DS#" result="stResult">
										INSERT INTO #application.database#.program_user 
											(created_user_ID, 
											created_datetime, 
											program_ID, 
											username,
											fname, 
											lname, 
											email,
											ship_address1,
											ship_address2,
											ship_city,
											ship_state,
											ship_zip,
											ship_country,
											is_active)
										VALUES
											(<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#FLGen_adminID#" maxlength="10">, 
											'#FLGen_DateTimeToMySQL()#', 
											<cfqueryparam value="#request.selected_program_ID#" cfsqltype="CF_SQL_INTEGER" maxlength="10">, 
											<cfqueryparam value="#thisUsername#" cfsqltype="CF_SQL_VARCHAR" maxlength="128">, 
											<cfqueryparam value="#thisFirstname#" cfsqltype="CF_SQL_VARCHAR" maxlength="30">, 
											<cfqueryparam value="#thisLastname#" cfsqltype="CF_SQL_VARCHAR" maxlength="30">, 
											<cfqueryparam value="#thisEmail#" cfsqltype="CF_SQL_VARCHAR" maxlength="128">,
											<cfqueryparam value="#thisAddress1#" cfsqltype="CF_SQL_VARCHAR" maxlength="64">,
											<cfqueryparam value="#thisAddress2#" cfsqltype="CF_SQL_VARCHAR" maxlength="64">,
											<cfqueryparam value="#thisCity#" cfsqltype="CF_SQL_VARCHAR" maxlength="30">,
											<cfqueryparam value="#thisState#" cfsqltype="CF_SQL_VARCHAR" maxlength="32">,
											<cfqueryparam value="#thisZip#" cfsqltype="CF_SQL_VARCHAR" maxlength="32">,
											'',
											1)
									</cfquery>
									<!---<cfset DisplayResults = DisplayResults & 'end '>--->
									<cfset User_ID = stResult.GENERATED_KEY>
									
								</cflock>
							</cfif>
							<cfset DisplayResults = DisplayResults & '<td>Create New</td>'>
						<cfelse>
							<cfset DisplayResults = DisplayResults & '<td>MULTIPLES</td>'>
						</cfif>
					</cfif>
				<cfelse>
					<cfset DisplayResults = DisplayResults & '<td>BAD EMAIL</td>'>
				</cfif>
				<cfif send_email AND FLGen_IsValidEmail(thisEmail)>
					<cfif User_ID GT 0>
						<cfquery name="GetUserInfo" datasource="#application.DS#">
							SELECT ID AS this_user_ID, Format((((SELECT IFNULL(SUM(points),0) FROM #application.database#.awards_points WHERE user_ID = this_user_ID AND is_defered = 0) - (SELECT IFNULL(SUM(points_used),0) FROM #application.database#.order_info WHERE created_user_ID = this_user_ID AND is_valid = 1))),0) AS remaining_points 
							FROM #application.database#.program_user
							WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#User_ID#" maxlength="10">
						</cfquery>
						<cfset current_balance = GetUserInfo.remaining_points>
						<cfif testing_only AND isNumeric(thisPoints) AND thisPoints GT 0>
							<cfset current_balance = current_balance + thisPoints>
						</cfif>
					<cfelseif isNumeric(thisPoints) AND thisPoints GT 0>
						<cfset current_balance = thisPoints>
					<cfelse>
						<cfset current_balance = 0>
					</cfif>
					<cfset email_message = Replace(email_text,'USER-FIRST-NAME',thisFirstname,'all')>
					<cfset email_message = Replace(email_message,'USER-NAME',thisUsername,'all')>
					<cfset email_message = Replace(email_message,'USER-LAST-NAME',thisLastname,'all')>
					<cfset email_message = Replace(email_message,'USER-POINTS-EARNED',thisPoints,'all')>
					<cfset email_message = Replace(email_message,'USER-POINTS',thisPoints,'all')>
					<cfset email_message = Replace(email_message,'DATE-TODAY',DateFormat(Now(),'mm/dd/yyyy'),'all')>
					<cfset email_message = Replace(email_message,"USER-REMAINING-POINTS",current_balance,"all")>
					<cfif testing_only>
						<cfif num_sent EQ 0>
							<!--- Send tests --->
							<cfif Application.OverrideEmail NEQ "">
								<cfset this_to = Application.OverrideEmail>
							<cfelse>
								<cfset this_to = testing_email>
							</cfif>
							<cfmail to="#this_to#" from="#from_email#" subject="#email_subject#" type="html">
								<cfif Application.OverrideEmail NEQ "">
									Emails are being overridden.<br>
									Below is the email that would have been sent to #testing_email#<br>
									<hr>
								</cfif>
#email_message#
							</cfmail>
							<cfset url.pgfn = "email_setup">
						</cfif>
					<cfelse>
						<!--- Send to all on list --->
						<cfif Application.OverrideEmail NEQ "">
							<cfset this_to = Application.OverrideEmail>
						<cfelse>
							<cfset this_to = thisEmail>
						</cfif>
						<cfmail to="#this_to#" from="#from_email#" subject="#email_subject#" type="html">
							<cfif Application.OverrideEmail NEQ "">
								Emails are being overridden.<br>
								Below is the email that would have been sent to #thisEmail#<br>
								<hr>
							</cfif>
#email_message#
						</cfmail>
					</cfif>
					<cfset num_sent = num_sent + 1>
				</cfif>
				<cfif NOT testing_only AND isNumeric(thisPoints) AND thisPoints GT 0>
					<cfquery name="AwardPoints" datasource="#application.DS#">
						INSERT INTO #application.database#.awards_points (
							created_user_ID, created_datetime, user_ID, points, notes)
						VALUES (
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#FLGen_adminID#" maxlength="10">,
							'#FLGen_DateTimeToMySQL()#',
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#User_ID#" maxlength="10">,
							<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#thisPoints#">,
							<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#note#">
						)
					</cfquery>
				</cfif>
				<cfset DisplayResults = DisplayResults & '<td align="right">#thisPoints#</td>'>
			</cfif>
			<cfset first_line = false>
		</cfloop>
		<cfif testing_only>
			<cfset alert_msg = "Test email sent to #testing_email#.">
		<cfelse>
			<cfset FLGen_DeleteThisFile("#thisFileName#.csv","admin/upload/")>
			<cfset url.pgfn = "done">
		</cfif>
	</cfif>
	<cfif alert_error NEQ "" OR testing_only>
		<cfset url.pgfn = "email_setup">
	</cfif>
</cfif>
</cfif>

<cfset leftnavon = 'upload_points'>
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Upload Points</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

<script src="../includes/showhide.js"></script>

<span class="pagetitle">
	Upload points to <cfoutput>#request.program_name#</cfoutput> &nbsp;&nbsp;&nbsp;&nbsp; <a href="<cfoutput>#CurrentPage#</cfoutput>">Start Over</a>
</span>
<br /><br />

<cfif url.pgfn EQ "home">
	<span class="alert">REMOVE ALL COMMAS FROM YOUR DATA!!!!</span>
	<br /><br />
	<cfset FLGen_DeleteThisFile("#thisFileName#.csv","admin/upload/")>
	<!--- Page Title --->
	<span class="pageinstructions">
		This is a points uploader that allows you to upload points and (optionally) send an email to a set of people in a spreadsheet.<br /><br />
	</span>
	<span class="pageinstructions">
		The spreadsheet must be saved in CSV format.<br /><br />
	</span>
	<span class="pageinstructions">
		After uploading the spreadsheet you will indicate which column is the email address,<br />
	</span>
	<span class="pageinstructions">
		and which columns will be merged to the email template and points to award.
	</span>
	<br /><br />
	<a href="<cfoutput>#CurrentPage#?pgfn=upload</cfoutput>" class="actionlink">Upload Spreadsheet</a>
<cfelseif url.pgfn EQ "upload">
	<!--- Page Title --->
	<span class="pagetitle">Upload the Spreadsheet</span>
	<br /><br />
	<span class="pageinstructions">
	Before uploading the spreadsheet, please save it in the proper format.<br><br>
	<ol>
		<li>Open the file in Excel.</li><br><br>
		<li>Save the file as a comma-separated values (csv) file.
			<ul type="disc">
				<li>Click "File" (or Office Button in Office 2007) then "Save As".</li>
				<li>In the "Save As" dialog window, under the "File name" input field is a drop-down select box for "Save as type:".</li>
				<li>Scroll down to select the "CSV (Comma Delimited) (*.csv)" option.</li>
				<li>If the xls file has more than one worksheet you will get a window asking "The selected file type does not support ... multiple worksheets."  Click "OK".</li>
				<li>Then you'll probably get a message saying "export...csv may contain features that are incompatible..."  Click "Yes"</li>
			</ul>
		</li><br>
		<li>When you close Excel or close the file, Excel asks again to save the txt file.  There is no need to do this, so click "No".</li><br><br>
	</ol>
	<cfoutput>
	<form method="post" action="#CurrentPage#" name="uploadSpreadsheet" enctype="multipart/form-data">
		<input name="upload_txt" type="file" size="48" value=""><br><br>
		<input type="submit" name="submitUpload" value="  Upload  " >
	</form>
	</cfoutput>
	</span>
<cfelseif url.pgfn EQ "email_setup">
	<cfset hasFile = true>
	<cftry>
		<cffile action="read" variable="thisData" file="#application.FilePath#admin/upload/#thisFileName#.csv">
		<cfcatch><cfset hasFile = false></cfcatch>
	</cftry>
	<cfif hasFile>
		<cfset thisData = Replace(thisData,"#CHR(13)##CHR(10)#","|","ALL")>
		Here is the first line of your spreadsheet:<br>
		<cfset thisLineOne = ListFirst(thisData,"|")>
		<cfset colNum = 1>
		<cfloop list="#thisLineOne#" index="thisCol">
			<cfoutput>#colNum#) #thisCol#</cfoutput><br>
			<cfset colNum = colNum + 1>
		</cfloop>
		<cfoutput>
		<br>
		<form method="post" action="#CurrentPage#" name="emailSetup">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<tr class="BGdark">
	<td colspan="2" class="TEXTheader"> First row is header  <input type="checkbox" name="hasHeader" value="1" <cfif hasHeader>checked</cfif> /> <i>Uncheck this if the first row is a data row.</i></td>
	</tr>

		<tr><td align="right">Which column is the email address?</td><td><input type="text" name="email" value="#email#" size="5" maxlength="3"></td></tr>
		<tr><td align="right">Which column is the unique identifier?</td><td><input type="text" name="username" value="#username#" size="5" maxlength="3"> &nbsp; Merge code: USER-NAME</td></tr>
		<tr><td align="right">Which column is the first name?</td><td><input type="text" name="firstname" value="#firstname#" size="5" maxlength="3"> &nbsp; Merge code: USER-FIRST-NAME</td></tr>
		<tr><td align="right">Which column is the last name?</td><td><input type="text" name="lastname" value="#lastname#" size="5" maxlength="3"> &nbsp; Merge code: USER-LAST-NAME</td></tr>
		<tr><td align="right">Which column is the points?</td><td><input type="text" name="points" value="#points#" size="5" maxlength="3"> &nbsp; Merge code: USER-POINTS</td></tr>
		<tr><td align="right">Which column is the address line 1?</td><td><input type="text" name="address1" value="#address1#" size="5" maxlength="3"></td></tr>
		<tr><td align="right">Which column is the address line 2?</td><td><input type="text" name="address2" value="#address2#" size="5" maxlength="3"></td></tr>
		<tr><td align="right">Which column is the city?</td><td><input type="text" name="city" value="#city#" size="5" maxlength="3"></td></tr>
		<tr><td align="right">Which column is the state?</td><td><input type="text" name="state" value="#state#" size="5" maxlength="3"></td></tr>
		<tr><td align="right">Which column is the zip/postal code?</td><td><input type="text" name="zip" value="#zip#" size="5" maxlength="3"></td></tr>

	<tr>
	<td valign="bottom" align="right"><br>Note for points entry:</td><td></td>
	</tr>
	<tr>
	<td valign="top" align="center" colspan="2"><textarea name="note" cols="70" rows="3">#note#</textarea></td>
	</tr>
	
	<tr class="BGlight1">
		<td align="right">Send Email to Recipients?</td>
		<td>
			<input type="radio" name="send_email" value="1" onClick="showThis('email_lines')" <cfif send_email>checked</cfif>> Yes
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			<input type="radio" name="send_email" value="0" onClick="hideThis('email_lines')" <cfif NOT send_email>checked</cfif>> No
		</td>
	</tr>
	</table>
	<cfquery name="getTemplates" datasource="#application.ds#">
		SELECT ID, email_title
		FROM #application.database#.email_template
		WHERE is_available = 1
		ORDER BY email_title
	</cfquery>
	<table cellpadding="5" cellspacing="1" border="0" width="100%" id="email_lines" style="display:<cfif send_email>block<cfelse>none</cfif>">
	<tr class="BGlight1">
	<td align="right">email template:</td>
	<td>
		<select name="template_ID" id="template_ID">
			<option value="">--- Select Template ---</option>
			<cfloop query="getTemplates">
				<option value="#getTemplates.ID#" <cfif template_ID EQ getTemplates.ID>selected</cfif>>#getTemplates.email_title#</option>
			</cfloop>
		</select>
		<!--- &nbsp;&nbsp;&nbsp;&nbsp;<a href="##" onClick="openPreview();return false;">preview selected template</a> --->
	</td>
	</tr>
	
	<tr class="BGlight1">
	<td align="right">email subject:</td><td><input type="text" name="email_subject" value="#email_subject#" size="45" />
</td>
	</tr>
	
	<!--- <tr class="BGlight1">
	<td align="right">sender name:</td><td><input type="text" name="from_name" value="#from_name#" size="45" />
</td>
	</tr> --->
	
	<tr class="BGlight1">
	<td align="right">sender email address:</td><td><input type="text" name="from_email" value="#Application.DefaultEmailFrom#" size="45" readonly />
</td>
	</tr>
	
	<tr class="BGlight1">
	<td align="right">send bounced emails to:</td><td><input type="text" name="failto" value="#failto#" size="45" />
</td>
	</tr>

	<tr class="BGdark">
	<td class="TEXTheader" colspan="2" nowrap="nowrap">Test Email</td>
	</tr>
	<tr class="BGlight2">
	<td colspan="2"><img src="../pics/contrls-desc.gif" > Enter one or more emails (separated by commas) to receive the test email.</td>
	</tr>
	
	<tr class="BGlight1">
	<td colspan="2" align="center"><input type="text" name="testing_email" size="80" value="" /></td>
	</tr>
	
	<tr class="BGlight1">
	<td colspan="2" align="center" id="submit_cell_1"><input type="submit" name="submitTest" value="Send Test Email To Above Addresses" /></td>
	</tr>
	</table>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr class="BGlight1">
	<td colspan="2" align="center" id="submit_cell_2"><input type="submit" name="submitEmail" value="Post Points<!---  and Send Email To Entire List --->" /></td>
	</tr>
	</table>
	</form>
</cfoutput>
	<cfelse>
		<span class="pageinstructions">Sorry, but the data was lost.  You'll have to upload it again.</span>
	</cfif>
<cfelseif url.pgfn EQ "done">
	<cfoutput>
	#num_sent# emails sent.<br><br>
	</cfoutput>
</cfif>


<cfoutput>#DisplayResults#</cfoutput>
</cfif>
<cfinclude template="includes/footer.cfm">
