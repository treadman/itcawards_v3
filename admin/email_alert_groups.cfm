<!--- function library --->
<cfinclude template="/cfscripts/dfm_common/function_library_form.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000072,true)>

<cfparam name="where_string" default="">
<cfparam name="delete" default="">
<cfparam name="THIS_ITEMS_XREFS" default=""> 
<cfparam name="rowcolor" default=""> 

<cfparam name="xT" default="">

<!--- param a/e form fields --->
<cfparam name="ID" default="">	
<cfparam name="emailgroup_name" default="">
<cfparam name="search_sort" default="">

<cfparam  name="pgfn" default="list">

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

<cfif IsDefined('form.Submit')>
	
	<!--- add --->
	<cfif form.pgfn EQ "add">
		<cfif has_program>
			<cflock name="email_groupsLock" timeout="10">
				<cftransaction>
					<cfquery name="InsertQuery" datasource="#application.DS#">
						INSERT INTO #application.database#.email_groups
							(created_user_ID, created_datetime, emailgroup_name, program_ID)
						VALUES
							(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#', 
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.emailgroup_name#" maxlength="40">,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">)
					</cfquery>
					<cfquery name="getID" datasource="#application.DS#">
						SELECT Max(ID) As MaxID FROM #application.database#.email_groups
					</cfquery>
					<cfset ID = getID.MaxID>
				</cftransaction>  
			</cflock>
		<cfelse>
			<cfset alert_error = "Please select a program before adding an email group.">
		</cfif>		
	<!--- update --->
	<cfelseif form.pgfn EQ "edit">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.email_groups
			SET	emailgroup_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.emailgroup_name#" maxlength="40">
				#FLGen_UpdateModConcatSQL()#
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.ID#" maxlength="10">
		</cfquery>
		
		<cfquery name="DeleteAssignedXrefs" datasource="#application.DS#">
			DELETE FROM #application.database#.xref_user_emailgroup
			WHERE emailgroup_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.ID#">
		</cfquery>

		<!--- FOR ASSIGN XREF - Save xref Groups --->
		<cfif IsDefined('form.assign_xref') AND form.assign_xref IS NOT "">
			<cfloop list="#form.assign_xref#" index="i">
				<cfquery name="InsertTheseXref" datasource="#application.DS#">
					INSERT INTO #application.database#.xref_user_emailgroup
					(created_user_ID, created_datetime, emailgroup_ID, user_ID)
					VALUES (
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
					#FLGen_DateTimeToMySQL()#, 
					<cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#i#" maxlength="10">
					)
				</cfquery>
			</cfloop>
		</cfif>	
	</cfif>
	<cfset alert_msg = Application.DefaultSaveMessage>
	<cfset pgfn = "edit">
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000072)>
	<cfquery name="DeleteItem1" datasource="#application.DS#">
		DELETE FROM #application.database#.xref_user_emailgroup
		WHERE emailgroup_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>			
	<cfquery name="DeleteItem2" datasource="#application.DS#">
		DELETE FROM #application.database#.email_groups
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>			
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfif pgfn EQ "add" AND NOT has_program>
	<cfset alert_error = "Please select a program before you adding an email group">
	<cfset pgfn = "list">
</cfif>

<cfset leftnavon = "email_alert_groups">
<cfinclude template="includes/header.cfm">

<SCRIPT LANGUAGE="JavaScript"><!-- 
function openURL()
{ 
// grab index number of the selected option
selInd = document.pageform.pageselect.selectedIndex; 
// get value of the selected option
goURL = document.pageform.pageselect.options[selInd].value;
// redirect browser to the grabbed value (hopefully a URL)
top.location.href = goURL; 
}
//--> 
</SCRIPT>

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT g.ID, g.emailgroup_name, g.program_ID, p.program_name, p.company_name, COUNT(x.ID) AS group_count
		FROM #application.database#.email_groups g
		LEFT JOIN #application.database#.program p ON p.ID = g.program_ID
		LEFT JOIN #application.database#.xref_user_emailgroup x ON x.emailgroup_ID = g.ID
		WHERE 1=1 
		<cfif LEN(xT) GT 0>
			AND g.email_group_name LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">
		</cfif>
		<cfif has_program>
			AND g.program_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#request.selected_program_ID#">
		</cfif>
		GROUP BY g.ID
		ORDER BY g.program_ID, g.emailgroup_name
	</cfquery>

	<!--- set the start/end/max display row numbers --->
	<cfparam name="OnPage" default="1">
	<cfset MaxRows_SelectList="20">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>

	<span class="pagetitle">Email Alert Group List for <cfif has_program><cfoutput>#request.program_name#</cfoutput><cfelse>All Programs</cfif></span>
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
			text: <input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20">
			<input type="submit" name="search" value="   Search   ">
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
		<td><span class="headertext">Users</span></td>
		<td><span class="headertext">Email Group</span> <img src="../pics/contrls-asc.gif" width="7" height="6"></td>
		<td><span class="headertext">Award Program</span></td>
	</tr>
	</cfoutput>

	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
			<td colspan="4" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
		</tr>
	</cfif>

	<!--- display found records --->
	<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
		<tr class="content<cfif CurrentRow MOD 2 EQ 0>2</cfif>">
		<td nowrap="nowrap"><a href="#CurrentPage#?pgfn=edit&id=#ID#&xT=#xT#&OnPage=#OnPage#">Edit</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?delete=#ID#&xT=#xT#&OnPage=#OnPage#" onclick="return confirm('Are you sure you want to delete this email group?  There is NO UNDO.')">Delete</a></td>
		<td valign="top" nowrap="nowrap"><cfif SelectList.group_count EQ 0><span class="alert">NONE</span><cfelse>#SelectList.group_count#</cfif></td>
		<td valign="top">#emailgroup_name#</td>
		<td valign="top" nowrap="nowrap">#HTMLEditFormat(SelectList.company_name) & " [" & HTMLEditFormat(SelectList.program_name) & "]"#</td>
		</tr>
	</cfoutput>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add" OR pgfn EQ "copy">Add<cfelse>Edit</cfif> an Email Alert Group</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?xT=#xT#&OnPage=#OnPage#">Email Alert Group List</a> without making changes.</span>
	<br /><br />
	</cfoutput>

	<cfif pgfn EQ "edit">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, emailgroup_name, program_ID 
			FROM #application.database#.email_groups
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#">
		</cfquery>
		<cfset this_program_ID = ToBeEdited.program_ID>
		<cfset emailgroup_name = htmleditformat(ToBeEdited.emailgroup_name)>
		
		<!--- FOR ASSIGN XREF (CHANGE (1) select field (2) table name (3) where field ) --->
		<cfquery name="FindThisItemsXrefs" datasource="#application.DS#">
			SELECT user_ID AS this_xref_ID
			FROM #application.database#.xref_user_emailgroup
			WHERE emailgroup_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#">
		</cfquery>
				
		<cfif FindThisItemsXrefs.RecordCount NEQ 0>
			<cfloop query="FindThisItemsXrefs">
				<cfset this_items_xrefs = ValueList(FindThisItemsXrefs.this_xref_ID)>
			</cfloop>
		</cfif>
		<!--- END XREF --->
	</cfif>

	<cfoutput>

	<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> an Email Alert Template</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Email Alert Group Name: </td>
	<td valign="top"><input type="text" name="emailgroup_name" value="#emailgroup_name#" maxlength="40" size="40"><input type="hidden" name="emailgroup_name_required" value="Please enter a name for the email alert group."></td>
	</tr>
	

	<!--- User Selection --->
	<cfif pgfn EQ 'edit'>
	
		<!--- there are no users assigned and no search_sort --->
		<cfif this_items_xrefs EQ "" AND search_sort EQ ''>
					
			<cfquery name="SelectProgramCats" datasource="#application.DS#">
				SELECT ID, category_name  
				FROM #application.database#.program_user_category
				WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_program_ID#">
				ORDER BY sortorder ASC 
			</cfquery>
			
	<tr class="content">
	<td align="right" valign="top">Cross-section:&nbsp;<br><span class="sub">(choose one)</span>&nbsp;</td>
	<td valign="top">
	
		<table width="100%" cellpadding="0" cellspacing="5">
		
		<tr>
		<td valign="top"><input type="radio" name="search_sort" value="all" checked="checked"></td>
		<td width="99%" valign="top" colspan="2">Show All Program Users</td>
		</tr>
		
			<cfloop query="SelectProgramCats">
	
				<cfquery name="SelectCatValues" datasource="#application.DS#">
					SELECT DISTINCT category_data  
					FROM #application.database#.xref_user_category
					WHERE category_ID = #SelectProgramCats.ID#
					ORDER BY category_data ASC 
				</cfquery>
				<cfset select_list = ValueList(SelectCatValues.category_data)>
				<cfif ListLen(select_list) GT 0>
					<cfif IsNumeric(ListGetAt(select_list,1))>
						<cfset select_list = ListSort(select_list,'numeric')>
					</cfif>
				</cfif>
			
				<cfset category_tag = SelectProgramCats.ID>
		<tr>
		<td valign="top"><input type="radio" name="search_sort" value="#category_tag#"></td>
		<td valign="top" nowrap="nowrap">#category_name#</td>
		<td valign="top" width="99%">
			<select name="#category_tag#">
				<cfloop list="#select_list#" index="i">
				<option value="#i#">#i#</option>
				</cfloop>
			</select>
		</td>
		</tr>
		  
			</cfloop>
		
		</table>
		
	</td>
	</tr>
		
		<!--- Either there are users assigned, or there is search_sort --->
		<cfelse>
			
			<cfif this_items_xrefs NEQ "">
		
	<tr class="content">
	<td align="right" valign="top">#ListLen(this_items_xrefs)# Assigned User<cfif ListLen(this_items_xrefs) NEQ 1>s</cfif>: <br><span class="sub">(as selected below)</span></td>
	<td valign="top">
				<cfloop list="#this_items_xrefs#" index="i">
					<cfquery name="SelectAllXrefItems" datasource="#application.DS#">
						SELECT CONCAT(fname,' ',lname,', ',IFNULL(email,'')) AS list_text 
						FROM #application.database#.program_user
						WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#i#">
						ORDER BY lname,fname ASC 
					</cfquery>
				#SelectAllXrefItems.list_text#<br>
				</cfloop>
	</td>
	</tr>

			</cfif>
				
	<!--- FOR ASSIGN XREF - (change (1) select field (2) table name (3) order by clause --->		
			<cfquery name="SelectAllXrefItems" datasource="#application.DS#">
				SELECT ID AS this_xitem_ID, CONCAT(fname,' ',lname,', ',IFNULL(email,'')) AS checkbox_text 
				FROM #application.database#.program_user
				WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_program_ID#">
				
					<cfif search_sort NEQ '' AND search_sort NEQ 'all'>
					<!--- look for the user category and the category data that was submitted --->
					AND (	SELECT COUNT(ID) 
							FROM #application.database#.xref_user_category 
							WHERE user_ID = this_xitem_ID AND category_data = '#form[search_sort]#') = 1
					</cfif>
				ORDER BY lname,fname ASC 
			</cfquery>

	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Program Users: </td>
	<td valign="top">
	
			<cfloop query="SelectAllXrefItems">
			<input type="checkbox" name="assign_xref" value="#this_xitem_ID#" #FLForm_Selected(this_items_xrefs,this_xitem_ID)#>
				<cfif FLForm_Selected(this_items_xrefs,this_xitem_ID,"yes") EQ "yes">
					<cfset xref_class = 'selecteditem'>
				<cfelse>
					<cfset xref_class = 'reg'>
				</cfif>
			
			<span class="#xref_class#">#checkbox_text#</span><br>
			</cfloop>
	
	</td>
	</tr>
	<!--- END XREF --->
	
		</cfif>

	</cfif>
	
	<cfif pgfn EQ 'add'>
		<cfset save_button = "Save and Go To User Selection">
	<cfelseif this_items_xrefs EQ "" AND search_sort EQ ''>
		<cfset save_button = "Go To User List">
	<cfelse>
		<cfset save_button = "Save Selected Users">
	</cfif>
	<tr class="content">
	<td colspan="2" align="center">
		<input type="hidden" name="pgfn" value="#pgfn#">
		<input type="hidden" name="xT" value="#xT#">
		<input type="hidden" name="OnPage" value="#OnPage#">
		<input type="hidden" name="ID" value="#ID#">
		<input type="submit" name="submit" value="   #save_button#   " >
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
