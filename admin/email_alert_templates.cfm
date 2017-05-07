<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- function library --->
<cfinclude template="/cfscripts/dfm_common/function_library_form.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000072,true)>

<cfparam name="where_string" default="">
<cfparam name="delete" default="">
<cfparam name="this_items_xrefs" default=""> 
<cfparam name="rowcolor" default=""> 
<cfparam  name="pgfn" default="list">

<!--- param search criteria xT=SearchString --->
<cfparam name="xT" default="">

<!--- param a/e form fields --->
<cfparam name="ID" default="">	
<cfparam name="email_title" default="">
<cfparam name="email_text" default="">
<cfparam name="is_available" default="">
<cfparam name="is_program_admin_available" default=0>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- add --->
	<cfif form.pgfn EQ "add" OR form.pgfn EQ "copy">
		<cflock name="email_templateLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.email_template
						(created_user_ID, created_datetime, email_text, email_title, is_available, is_program_admin_available)
					VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#', 
							<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.email_text#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email_title#" maxlength="40 ">,
							<cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_available#">,
							<cfqueryparam cfsqltype="cf_sql_tinyint" value="#is_program_admin_available#">)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.email_template
				</cfquery>
				<cfset ID = getID.MaxID>
			</cftransaction>
		</cflock>
	<!--- update --->
	<cfelseif form.pgfn EQ "edit">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.email_template
			SET	email_text = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.email_text#">,
				email_title = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email_title#" maxlength="40 ">,
				is_available = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_available#">,
				is_program_admin_available = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_program_admin_available#">
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
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000072)>
	<cfquery name="DeleteItem" datasource="#application.DS#">
		DELETE FROM #application.database#.email_template
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "email_alert_templates">
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

<cfparam  name="pgfn" default="list">

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT t.ID, t.email_title, t.is_available, pr.company_name, pr.program_name
		FROM #application.database#.email_template t
		LEFT JOIN #application.database#.xref_program_email_template x ON x.email_template_ID = t.id
		LEFT JOIN #application.database#.program pr ON pr.ID = x.program_ID
		WHERE 1=1
		<cfif has_program>
			AND x.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		</cfif>
		<cfif LEN(xT) GT 0>
			AND ( t.email_text LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">
				OR t.email_title LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> )
		</cfif>
		ORDER BY t.email_title, pr.company_name, pr.program_name
	</cfquery>

	<!--- set the start/end/max display row numbers --->
	<cfparam name="OnPage" default="1">
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>

	<span class="pagetitle">Email Alert Template List for <cfif has_program><cfoutput>#request.program_name#</cfoutput><cfelse>All Programs</cfif></span>
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
			<input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20">
			<input type="submit" name="search" value="search">
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
				<a href="<cfoutput>#CurrentPage#?OnPage=1&xT=#xT#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xT=#xT#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
			<cfelse>
				<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
			</cfif>
		</td>
		<td align="center" class="sub">[ page 	
		<cfoutput>
		<select name="pageselect" onChange="openURL()"> 
			<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
				<option value="#CurrentPage#?OnPage=#this_i#&xT=#xT#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
			</cfloop>
		</select> of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
		</cfoutput>
		</td>
		<td align="right">
			<cfif OnPage LT TotalPages_SelectList>
				<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xT=#xT#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xT=#xT#</cfoutput>" class="pagingcontrols">&raquo;</a>
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
	<td align="center"><a href="#CurrentPage#?pgfn=add&xT=#xT#&OnPage=#OnPage#">Add</a></td>
	<td><span class="headertext">Title</span> <img src="../pics/contrls-asc.gif" width="7" height="6"></td>
	<td><span class="headertext">Assigned To</span></td>
	</tr>
	</cfoutput>

	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
			<td colspan="3" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
		</tr>
	<cfelse>
		<!--- display found records --->
		<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#" group="ID">
			<cfif is_available EQ "0">
				<cfset rowcolor = "inactivebg">
			<cfelseif (CurrentRow MOD 2) is 0>
				<cfset rowcolor = "content2">
			<cfelseif (CurrentRow MOD 2) is 0>
				<cfset rowcolor = "content">
			</cfif>
			<tr class="#rowcolor#">
			<td nowrap="nowrap"><a href="#CurrentPage#?pgfn=edit&id=#ID#&xT=#xT#&OnPage=#OnPage#">Edit</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?pgfn=copy&id=#ID#&xT=#xT#&OnPage=#OnPage#">Copy</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?delete=#ID#&xT=#xT#&OnPage=#OnPage#" onclick="return confirm('Are you sure you want to delete this email template?  There is NO UNDO.')">Delete</a></td>
			<td valign="top" width="100%"><a href="email_alert_preview.cfm?ID=#ID#" target="_blank">Open Preview</a><Br>#htmleditformat(email_title)#</td>
			<td valign="top" nowrap="nowrap"><cfoutput><cfif company_name EQ "" AND program_name EQ ""><span class="sub">(none)</span><cfelse>#company_name# <span class="sub">[#program_name#]</span><br /></cfif></cfoutput></td>
			</tr>
		</cfoutput>
	</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit" OR pgfn EQ "copy">
	<!--- START pgfn ADD/EDIT --->
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add" OR pgfn EQ "copy">Add<cfelse>Edit</cfif> an Email Alert Template</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?xT=#xT#&OnPage=#OnPage#">Email Alert Template List</a> without making changes.</span>
	<br /><br />
	</cfoutput>

	<cfif pgfn eq 'copy'>
		<span class="pageinstructions"><span class="alert">You are creating a new email alert template.</span> The form below is filled with</span>
		<br />
		<span class="pageinstructions">the information from the email alert template you requested to copy.</span>
		<br /><br />
	</cfif>

	<cfif pgfn EQ "edit" OR pgfn EQ "copy">
<cfset tinymce_fields = "email_text">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, email_text, email_title, is_available, is_program_admin_available
			FROM #application.database#.email_template
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#">
		</cfquery>
		<cfset ID = ToBeEdited.ID>
		<cfset email_text = htmleditformat(ToBeEdited.email_text)>
		<cfset email_title = htmleditformat(ToBeEdited.email_title)>
		<cfset is_available = htmleditformat(ToBeEdited.is_available)>
		<cfset is_program_admin_available = htmleditformat(ToBeEdited.is_program_admin_available)>
		<cfquery name="FindThisItemsXrefs" datasource="#application.DS#">
			SELECT program_ID AS this_xref_ID
			FROM #application.database#.xref_program_email_template
			WHERE email_template_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
		<cfset this_items_xrefs = ValueList(FindThisItemsXrefs.this_xref_ID)>
	</cfif>
	<cfoutput>
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add" OR pgfn EQ "copy">Add<cfelse>Edit</cfif> an Email Alert Template</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Available?: </td>
	<td valign="top">
		<select name="is_available">
			<option value="1"<cfif is_available EQ "1"> selected</cfif>>Yes. This template can be used.
			<option value="0"<cfif is_available EQ "0"> selected</cfif>>No. This template can not be used.
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Program Administrator?: </td>
	<td valign="top">
		<select name="is_program_admin_available">
			<option value="1"<cfif is_program_admin_available EQ "1"> selected</cfif>>Yes. This template is available to program administrator.
			<option value="0"<cfif is_program_admin_available EQ "0"> selected</cfif>>No. This template can not be used by a program administrator.
		</select>
	</td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Title (used in admin only): </td>
	<td valign="top"><input type="text" name="email_title" value="#email_title#" maxlength="40" size="40"><input type="hidden" name="email_title_required" value="Please enter a title for the email."></td>
	</tr>
	
	<tr class="content">
	<td valign="top" colspan="2">
	<div align="right" class="sub" style="font-size:9"><cfif pgfn NEQ "add">
	<a href="email_alert_preview.cfm?ID=#ID#" target="_blank">Preview Current Email Alert</a> (opens in new window)
	<br><br></cfif>
	<a href="email_alert_template_images.cfm" target="_blank">Available Images</a> (opens in new window)
	<br><br>
	<a href="email_alert_template_mergecodes.cfm" target="_blank">Merge Codes and Formatting</a> (opens in new window)
	</div>
	Email Text:
	</td>
	</tr>
	
	<tr class="content">
	<td valign="top" colspan="2" align="center">
	<textarea name="email_text" cols="80" rows="30">#email_text#</textarea>

	</td>
	</tr>

	<!--- FOR ASSIGN XREF - (change (1) select field (2) table name (3) order by clause --->
	<cfquery name="SelectAllXrefItems" datasource="#application.DS#">
		SELECT ID AS this_xitem_ID, CONCAT(company_name,' [',program_name,']') AS checkbox_text 
		FROM #application.database#.program
		WHERE parent_ID = 0
		ORDER BY company_name, program_name ASC 
	</cfquery>

	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Available for: </td>
	<td valign="top">
		<cfloop query="SelectAllXrefItems">
			<input type="checkbox" name="assign_xref" value="#this_xitem_ID#" #FLForm_Selected(this_items_xrefs,this_xitem_ID)#>
			<cfset this_class = IIF(FLForm_Selected(this_items_xrefs,this_xitem_ID,"yes") EQ "yes",DE(true),DE(false))>
			<span class="<cfif this_class>selecteditem<cfelse>reg</cfif>">#checkbox_text#</span><br>
		</cfloop>
	</td>
	</tr>
	<!--- END XREF --->
	<tr class="content">
	<td colspan="2" align="center">
		<input type="hidden" name="pgfn" value="#pgfn#">
		<input type="hidden" name="xT" value="#xT#">
		<input type="hidden" name="OnPage" value="#OnPage#">
		<input type="hidden" name="ID" value="#ID#">
		<input type="submit" name="submit" value="   Save Changes   " >
	</td>
	</tr>
		
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn ADD/EDIT --->
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->