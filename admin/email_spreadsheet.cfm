<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000073",true)>

<cfparam name="url.pgfn" default="home">
<cfparam name="from_name" default="From Name">
<cfparam name="from_email" default="#Application.DefaultEmailFrom#">
<cfparam name="email_subject" default="">
<cfparam name="failto" default="#Application.OrdersFailTo#">
<cfparam name="email_text" default="">
<cfparam name="send_to" default="0">
<cfparam name="hasHeader" default="1">
<cfparam name="template_ID" default="">
<cfparam name="email" default="">
<cfparam name="firstname" default="">
<cfparam name="lastname" default="">
<cfparam name="points" default="">
<cfparam name="branchnum" default="">

<cfparam name="testing_email" default="">

<cfset num_sent = 0>
<cfset bad_emails = "">
<cfset alert_error = "">

<cfif IsDefined("form.submitUpload")>
	<cfif form.upload_txt NEQ "">
		<cfset result = FLGen_UploadThis("upload_txt","admin/upload/","spreadsheet")>
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

<cfif IsDefined("form.submitEmail")>
	<cfset hasFile = true>
	<cftry>
		<cffile action="read" variable="thisData" file="#application.FilePath#admin/upload/spreadsheet.csv">
		<cfcatch><cfset hasFile = false></cfcatch>
	</cftry>
	<cfif NOT hasFile>
		<cfset alert_error="Sorry, but the data was lost.  Please try again.">
	<cfelseif NOT IsNumeric(template_ID)>
		<cfset alert_error="Please select a template.">
	<cfelseif NOT isNumeric(email) OR email LTE 0>
		<cfset alert_error="Please enter the email address column number.">
	<cfelseif NOT send_to AND testing_email EQ "">
		<cfset alert_error="If you want to send to everyone on the list, please check the box next to Final Broadcast.">
	</cfif>
	<cfif alert_error EQ "">
		<cfquery name="getTemplate" datasource="#application.ds#">
			SELECT email_text
			FROM #application.database#.email_template
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#template_ID#">
		</cfquery>
		<cfset email_text = getTemplate.email_text>
		<cfset thisData = Replace(thisData,"#CHR(13)##CHR(10)#","|","ALL")>
		<cfset first_line = true>
		<cfif NOT hasHeader>
			<cfset first_line = false>
		</cfif>
		<cfloop list="#thisData#" index="thisLine" delimiters="|">
			<cfif NOT first_line>
				<cfset thisEmail = "">
				<cfset thisFirstname = "">
				<cfset thisLastname = "">
				<cfset thisPoints = "">
				<cfset thisBranchNum = "">
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
					<cfif branchnum NEQ "" AND col_num EQ branchnum>
						<cfset thisBranchNum = thisCol>
					</cfif>
					<cfset col_num = col_num + 1>
				</cfloop>
				<cfif thisEmail NEQ "" AND FLGen_IsValidEmail(thisEmail)>
					<cfset email_message = Replace(email_text,'USER-FIRST-NAME',thisFirstname,'all')>
					<cfset email_message = Replace(email_message,'USER-LAST-NAME',thisLastname,'all')>
					<cfset email_message = Replace(email_message,'USER-POINTS',thisPoints,'all')>
					<cfset email_message = Replace(email_message,'BRANCH-NUMBER',thisBranchNum,'all')>
					<cfset email_message = Replace(email_message,'DATE-TODAY',DateFormat(Now(),'mm/dd/yyyy'),'all')>
					<cfif NOT send_to>
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
						<cfbreak>
					<cfelse>
						<!--- Send to all on list --->
						<cfif application.OverrideEmail NEQ "">
							<cfset this_to = application.OverrideEmail>
						<cfelse>
							<cfset this_to = thisEmail>
						</cfif>
						<cfmail to="#this_to#" from="#from_email#" subject="#email_subject#" type="html">
							<cfif application.OverrideEmail NEQ "">
								Emails are being overridden.<br>
								Below is the email that would have been sent to #thisEmail#<br>
								<hr>
							</cfif>
#email_message#
						</cfmail>
						<cfset num_sent = num_sent + 1>
					</cfif>
				<cfelseif thisEmail NEQ "">
					<cfset bad_emails = ListAppend(bad_emails,thisEmail)>
				</cfif>
			</cfif>
			<cfset first_line = false>
		</cfloop>
		<cfif send_to>
			<cfset url.pgfn = "done">
		</cfif>
	</cfif>
	<cfif alert_error NEQ "">
		<cfset url.pgfn = "email_setup">
	</cfif>
</cfif>


<cfset leftnavon = 'email_spreadsheet'>
<cfinclude template="includes/header.cfm">

<span class="pagetitle">
	Send email to people in a spreadsheet.
	<cfif url.pgfn NEQ "home">
		<a href="<cfoutput>#CurrentPage#</cfoutput>">Start Over</a>
	</cfif>
</span>
<br /><br />
<span class="alert">REMOVE ALL COMMAS FROM YOUR DATA!!!!</span>
<br /><br />

<cfif url.pgfn EQ "home">
	<!--- Page Title --->
	<span class="pageinstructions">
		This is an email broadcaster that allows you to send email to a set of people in a spreadsheet.<br /><br />
	</span>
	<span class="pageinstructions">
		The spreadsheet must be saved in CSV format.<br /><br />
	</span>
	<span class="pageinstructions">
		After uploading the spreadsheet you will indicate which column is the email address,<br />
	</span>
	<span class="pageinstructions">
		and which columns will be merged to the email template.
	</span>
	<br /><br />
	<a href="<cfoutput>#CurrentPage#</cfoutput>?pgfn=upload" class="actionlink">Upload Spreadsheet</a>
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
				<li>Click "File" (or Office Button in Office 2007) then "Save As".
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
		<cffile action="read" variable="thisData" file="#application.FilePath#admin/upload/spreadsheet.csv">
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
		<tr><td align="right">Which column is the first name?</td><td><input type="text" name="firstname" value="#firstname#" size="5" maxlength="3"> &nbsp; Merge code: USER-FIRST-NAME</td></tr>
		<tr><td align="right">Which column is the last name?</td><td><input type="text" name="lastname" value="#lastname#" size="5" maxlength="3"> &nbsp; Merge code: USER-LAST-NAME</td></tr>
		<tr><td align="right">Which column is the points?</td><td><input type="text" name="points" value="#points#" size="5" maxlength="3"> &nbsp; Merge code: USER-POINTS</td></tr>
		<tr><td align="right">Which column is the branch number?</td><td><input type="text" name="branchnum" value="#branchnum#" size="5" maxlength="3"> &nbsp; Merge code: BRANCH-NUMBER</td></tr>

	
	<cfquery name="getTemplates" datasource="#application.ds#">
		SELECT ID, email_title
		FROM #application.database#.email_template
		WHERE is_available = 1
		ORDER BY email_title
	</cfquery>
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
	<td colspan="2" align="center" id="submit_cell_1"><input type="submit" name="submitEmail" value="Send Test Email To Above Addresses" /></td>
	</tr>
	
	<tr class="BGdark">
	<td colspan="2" class="TEXTheader"> Final Broadcast  <input type="checkbox" name="send_to" value="1" /></td>
	</tr>
	
	<tr class="BGlight1">
	<td colspan="2" align="center" id="submit_cell_2"><input type="submit" name="submitEmail" value="Send Email To Entire List" /></td>
	</tr>
		</table>
</cfoutput>
	<cfelse>
		<span class="pageinstructions">Sorry, but the data was lost.  You'll have to upload it again.</span>
	</cfif>
<cfelseif url.pgfn EQ "done">
	<cfoutput>#num_sent#</cfoutput> emails sent.<br><br>
	<cfif bad_emails NEQ "">
		Bad emails: <cfoutput>#replace(bad_emails,",","<br>","ALL")#</cfoutput>
	</cfif>
</cfif>

<cfinclude template="includes/footer.cfm">
