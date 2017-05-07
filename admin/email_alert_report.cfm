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
<cfset FLGen_HasAdminAccess("1000000072-1000000075",true)>

<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="this_from_date" default="">
<cfparam name="this_to_date" default="">
<cfparam name="pgfn" default="list">

<cfparam name="where_string" default="">
<cfparam name="delete" default="">
<cfparam name="THIS_ITEMS_XREFS" default=""> 
<cfparam name="rowcolor" default=""> 

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- add --->
	<cfif pgfn EQ "add" OR pgfn EQ "copy">
		<cflock name="email_templateLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.email_template
						(created_user_ID, created_datetime, email_text, email_title, is_available)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.email_text#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email_title#" maxlength="40 ">,
						<cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_available#">
					)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.email_template
				</cfquery>
			</cftransaction>  
		</cflock>
		<cfset ID = getID.MaxID>
	<cfelseif pgfn EQ "edit">
		<!--- update --->
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.email_template
			SET	email_text = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.email_text#">,
				email_title = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email_title#" maxlength="40 ">,
				is_available = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_available#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.ID#" maxlength="10">
		</cfquery>
		<cfquery name="DeleteAssignedXrefs" datasource="#application.DS#">
			DELETE FROM #application.database#.xref_program_email_template
			WHERE email_template_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.ID#" maxlength="10">
		</cfquery>
	</cfif>

	<!--- FOR ASSIGN XREF - Save xref Groups --->
	<cfif IsDefined('form.assign_xref') AND form.assign_xref IS NOT "">
		<cfloop list="#form.assign_xref#" index="thisProgramID">
			<cfquery name="InsertTheseXref" datasource="#application.DS#">
				INSERT INTO #application.database#.xref_program_email_template
				(created_user_ID, created_datetime, email_template_ID, program_ID)
				VALUES (
				<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
				#FLGen_DateTimeToMySQL()#, 
				<cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#thisProgramID#" maxlength="10">
				)
			</cfquery>
		</cfloop>
	</cfif>	
	<cfset alert_msg = Application.DefaultSaveMessage>
	<cfset pgfn = "edit">
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000053)>
	<cfquery name="DeleteVendor" datasource="#application.DS#">
		DELETE FROM #application.database#.vendor
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>			
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "email_alert_report">
<cfinclude template="includes/header.cfm">

<SCRIPT LANGUAGE="JavaScript"><!-- 
function openURL() { 
	// grab index number of the selected option
	selInd = document.pageform.pageselect.selectedIndex; 
	// get value of the selected option
	goURL = document.pageform.pageselect.options[selInd].value;
	// redirect browser to the grabbed value (hopefully a URL)
	top.location.href = goURL; 
	}
//--></SCRIPT>

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">
	<!--- massage dates --->
	<cfif this_from_date NEQ "" AND IsDate(this_from_date)>
		<cfset xFD = FLGen_DateTimeToMySQL(this_from_date,'startofday')>
	</cfif>
	<cfif this_to_date NEQ "" AND IsDate(this_to_date)>
		<cfset xTD = FLGen_DateTimeToMySQL(this_to_date,'endofday')>
	</cfif>
	<cfif xFD NEQ "">
		<cfset x_date =  RemoveChars(Insert(',', Insert(',', xFD, 6),4),11,16)>
		<cfset this_from_date = ListGetAt(x_date,2) & '/' & ListGetAt(x_date,3) & '/' & ListGetAt(x_date,1)>
	</cfif>
	<cfif xTD NEQ "">
		<cfset x_date =  RemoveChars(Insert(',', Insert(',', xTD, 6),4),11,16)>
		<cfset this_to_date = ListGetAt(x_date,2) & '/' & ListGetAt(x_date,3) & '/' & ListGetAt(x_date,1)>
	</cfif>
	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ea.ID, Date_Format(ea.created_datetime,'%c/%d/%Y') AS created_date, ea.program_ID AS this_program_ID, ea.template_ID, (SELECT COUNT(xau.ID) FROM #application.database#.xref_alerts_users xau WHERE xau.alert_ID = ea.ID) AS number_of_emails_sent 
		FROM #application.database#.email_alerts ea
		JOIN #application.database#.admin_users au ON ea.created_user_ID = au.ID 
		WHERE 1=1 
		<cfif this_from_date NEQ "">
			AND ea.created_datetime >= <cfqueryparam value="#xFD#">
		</cfif>
		<cfif this_to_date NEQ "">
			AND ea.created_datetime <= <cfqueryparam value="#xTD#">
		</cfif>
		<cfif has_program>
			AND ea.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		</cfif>
		ORDER BY ea.created_datetime DESC, ea.program_ID
	</cfquery>
	<!--- set the start/end/max display row numbers --->
	<cfparam name="OnPage" default="1">
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	<span class="pagetitle">Email Alert Report for <cfif has_program><cfoutput>#request.program_name#</cfoutput><cfelse>All Programs</cfif></span>
	<br /><br />
	<!--- search box --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td class="headertext">Search Criteria</td>
	<td align="right"><a href="<cfoutput>#CurrentPage#</cfoutput>" class="headertext">view all</a></td>
	</tr>
	
	<tr>
	<td class="content" colspan="2" align="center">
		<cfoutput>
		<form action="#CurrentPage#" method="post">
		<table cellpadding="5" cellspacing="0" border="0" width="100%">
		<tr>
		<td align="right">			
			<span class="sub">From Date:</span> <input type="text" name="this_from_date" value="#this_from_date#" size="20"><br>
			<span class="sub">To Date:</span> <input type="text" name="this_to_date" value="#this_to_date#" size="20">
		</td>
		<td align="center">&nbsp;&nbsp;&nbsp;</td>
		<td>			
			<input type="submit" name="submit" value="search">
		</td>
		</tr>
		
		</table>
		</form>
		</cfoutput>
	</td>
	</tr>
	</table>
	<br />
	<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0>
	<form name="pageform">
	<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr>
	<td>
		<cfif OnPage GT 1>
			<a href="<cfoutput>#CurrentPage#?OnPage=1&xFD=#xFD#&xTD=#xTD#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xFD=#xFD#&xTD=#xTD#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
		</cfif>
	</td>
	<td align="center" class="sub">[ page 	
	<cfoutput>
	<select name="pageselect" onChange="openURL()"> 
		<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
			<option value="#CurrentPage#?OnPage=#this_i#&xFD=#xFD#&xTD=#xTD#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
		</cfloop>
	</select> of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
	</cfoutput>
	</td>
	<td align="right">
		<cfif OnPage LT TotalPages_SelectList>
			<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xFD=#xFD#&xTD=#xTD#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xFD=#xFD#&xTD=#xTD#</cfoutput>" class="pagingcontrols">&raquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
		</cfif>
	</td>
	</tr>
	</table>
	</form>
	</cfif>
	
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<!--- header row --->
		<cfoutput>	
		<tr class="contenthead">
		<td align="center">&nbsp;</td>
		<td><span class="headertext" nowrap="nowrap">Date</span> <img src="../pics/contrls-desc.gif" width="7" height="6"></td>
		<td align="center">&nbsp;</td>
		<td><span class="headertext">Program</span></td>
		<td><span class="headertext">Template Title</span></td>
		</tr>
		</cfoutput>
		<!--- if no records --->
		<cfif SelectList.RecordCount IS 0>
			<tr class="content2">
			<td colspan="5" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
			</tr>
		<cfelse>
			<!--- display found records --->
			<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
				<cfquery name="FindProgram" datasource="#application.DS#">
					SELECT company_name, program_name 
					FROM #application.database#.program
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_program_ID#">
				</cfquery>
				<cfquery name="FindTemplateTitle" datasource="#application.DS#">
					SELECT email_title 
					FROM #application.database#.email_template
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#template_ID#">
				</cfquery>
				<tr class="content<cfif CurrentRow MOD 2 is 0>2</cfif>">
				<td nowrap="nowrap"><a href="#CurrentPage#?pgfn=details&id=#ID#&xFD=#xFD#&xTD=#xTD#&OnPage=#OnPage#">Details</a>&nbsp;&nbsp;&nbsp;</td>
				<td valign="top" nowrap="nowrap">#created_date#</td>
				<td valign="top">[#number_of_emails_sent#]</td>
				<td valign="top" width="50%">#FindProgram.company_name# <span class="sub">[#FindProgram.program_name#]</span></td>
				<td valign="top" width="50%">#FindTemplateTitle.email_title#</td>
				</tr>
			</cfoutput>
		</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "details">
	<!--- START pgfn DETAILS --->
	<cfoutput>
	<span class="pagetitle">Email Alert Details</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?xFD=#xFD#&xTD=#xTD#&OnPage=#OnPage#">Email Alert Report</a>.</span>
	<br /><br />
	</cfoutput>
	<cfquery name="SelectDetail" datasource="#application.DS#">
		SELECT Date_Format(ea.created_datetime,'%c/%d/%Y') AS created_date, CONCAT(au.firstname,' ',au.lastname) AS admin_name, ea.program_ID AS this_program_ID, ea.template_ID, ea.template_text, ea.recipients, Date_Format(ea.exp_date,'%c/%d/%Y') AS exp_date, ea.email_subject, ea.fillin, ea.from_email, (SELECT COUNT(xau.ID) FROM #application.database#.xref_alerts_users xau WHERE xau.alert_ID = ea.ID) AS number_of_emails_sent
		FROM #application.database#.email_alerts ea
		JOIN #application.database#.admin_users au ON ea.created_user_ID = au.ID 
		WHERE ea.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#">
		<cfif has_program>
			AND ea.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" />
		</cfif>
	</cfquery>
	<cfset created_date = SelectDetail.created_date>
	<cfset admin_name = htmleditformat(SelectDetail.admin_name)>
	<cfset this_program_ID = SelectDetail.this_program_ID>
	<cfset template_text = SelectDetail.template_text>
	<cfset recipients = htmleditformat(SelectDetail.recipients)>
	<cfset exp_date = SelectDetail.exp_date>
	<cfset email_subject = htmleditformat(SelectDetail.email_subject)>
	<cfset from_email = htmleditformat(SelectDetail.from_email)>
	<cfset number_of_emails_sent = SelectDetail.number_of_emails_sent>
	<cfquery name="FindProgram" datasource="#application.DS#">
		SELECT company_name, program_name 
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_program_ID#">
	</cfquery>
	<cfoutput>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext">Email Alert Detail</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Sent: </td>
	<td valign="top">#created_date# by #admin_name#</td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Awards Program: </td>
	<td valign="top">#FindProgram.company_name# <span class="sub">[#FindProgram.program_name#]</span></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Recipients: </td>
	<td valign="top">#recipients#<cfif exp_date NEQ "">: <b>#exp_date#</b></cfif></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Number of Emails Sent: </td>
	<td valign="top">#number_of_emails_sent#</span></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Email Sent From: </td>
	<td valign="top">#from_email#</span></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Email Subject: </td>
	<td valign="top">#email_subject#</span></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Email Text: </td>
	<td valign="top">#Replace(template_text,chr(10),"<br>","ALL")#</span></td>
	</tr>
	
	

	<tr class="content">
	<td valign="top" colspan="2">Recipients: <br><br>
		<table cellpadding="2" cellspacing="1" border="0" width="100%">
		<tr bgcolor="##CCCCCC"><td><b>Name</b></td><td><b>Email</b></td><td><b>Points</b></td></tr>

	<cfquery name="FindRecipients" datasource="#application.DS#">
		SELECT xau.user_points,  xau.user_email, up.fname, up.lname  
		FROM #application.database#.xref_alerts_users xau 
		JOIN #application.database#.program_user up ON xau.user_ID = up.ID
		WHERE xau.alert_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#">
		<cfif has_program>
			AND (SELECT COUNT(ID) FROM #application.database#.email_alerts ea WHERE ea.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#"> and ea.ID = xau.alert_ID) = 1 
		</cfif>
	</cfquery>
	<cfloop query="FindRecipients">
		<tr bgcolor="##dddddd"><td>#fname# #lname#</td><td>#user_email#</td><td>#user_points#</td></tr>
	</cfloop>

		</table>
	</td>
	</tr>

	</table>
	</cfoutput>
	<!--- END pgfn DETAILS --->
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->