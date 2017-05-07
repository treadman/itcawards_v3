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
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfparam name="where_string" default="">
<cfparam name="ID" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="number">
<cfparam name="xT" default="">
<cfparam name="xL" default="">

<!--- param a/e form fields --->
<cfparam name="ID" default="">	
<cfparam name="number" default="">
<cfparam name="description" default="">
<cfparam name="delete" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif has_program>
<cfif IsDefined('form.Submit')>

	<!--- update --->
	<cfif form.pgfn EQ "edit">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.cost_centers
			SET	number = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.number#" maxlength="5">,
				description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.description#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.description)))#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelseif form.pgfn EQ "add" OR form.pgfn EQ "copy">
		<cflock name="ccLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#" result="stResult">
					INSERT INTO #application.database#.cost_centers
						(created_user_ID, created_datetime, number, program_ID, description)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#',
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#number#" maxlength="5">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">, 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.description#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.description)))#">
					)
				</cfquery>
				<cfset ID = stResult.GENERATED_KEY>
			</cftransaction>  
		</cflock>
	</cfif>
	<cfset alert_msg = Application.DefaultSaveMessage>
	<cfset pgfn = "list">
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000053)>
	<cfquery name="DeleteCC" datasource="#application.DS#">
		DELETE FROM #application.database#.cost_centers
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>			
	<cfset pgfn = "list">
</cfif>
</cfif>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfparam  name="pgfn" default="list">

<cfif NOT has_program>
	<span class="pagetitle">Cost Centers</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

	<!--- Set the WHERE clause --->
	<!--- First check if a search string passed --->
	<cfif LEN(xT) GT 0>
		<cfset xL = "">
	</cfif>
	
	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ID, number, description
		FROM #application.database#.cost_centers
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		<cfif LEN(xT) GT 0>
			AND number LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">
		<cfelseif LEN(xL) GT 0>
			AND number LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xL#%">
		</cfif>
		ORDER BY number
	</cfquery>
	
	<!--- set the start/end/max display row numbers --->
	<cfparam name="OnPage" default="1">
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	
	<span class="pagetitle">Cost Center List for <cfoutput>#request.program_name#</cfoutput></span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="program_list.cfm">Award Program List</a> without making changes.</span>
	<cfoutput>#RepeatString('&nbsp;',28)#</cfoutput>
	<span class="pageinstructions"><a href="cost_center_upload.cfm">Upload Cost Centers</a></span>
	<br /><br />

	<!--- search box --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td><span class="headertext">Search Criteria</span></td>
	<td align="right"><a href="<cfoutput>#CurrentPage#</cfoutput>" class="headertext">view all</a></td>
	</tr>
	
	<tr>
	<td class="content" colspan="2" align="center">
		<cfoutput>
		<form action="#CurrentPage#" method="post">
			<input type="hidden" name="xL" value="#xL#">
			<input type="hidden" name="xS" value="#xS#">
			<input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20">
			<input type="submit" name="search" value="search">
		</form>
		<br>		
		<cfif LEN(xL) IS 0><span class="ltrON">ALL</span><cfelse><a href="#CurrentPage#?xL=" class="ltr">ALL</a></cfif><span class="ltrPIPE">&nbsp;&nbsp;</span><cfloop index = "LoopCount" from = "0" to = "9"><cfoutput><cfif xL IS LoopCount><span class="ltrON">#LoopCount#</span><cfelse><a href="#CurrentPage#?xL=#LoopCount#" class="ltr">#LoopCount#</a></cfif></cfoutput><span class="ltrPIPE">&nbsp;&nbsp;</span></cfloop><cfloop index = "LoopCount" from = "1" to = "26"><cfoutput><cfif xL IS CHR(LoopCount + 64)><span class="ltrON">#CHR(LoopCount + 64)#</span><cfelse><a href="#CurrentPage#?xL=#CHR(LoopCount + 64)#" class="ltr">#CHR(LoopCount + 64)#</a></cfif></cfoutput><cfif LoopCount NEQ 26><span class="ltrPIPE">&nbsp;&nbsp;</span></cfif></cfloop>
		</cfoutput>
	</td>
	</tr>
	
	</table>
	
	<br />
	
	<cfif SelectList.RecordCount GT 0>
		<form name="pageform">
		<table cellpadding="0" cellspacing="0" border="0" width="100%">
		<tr>
		<td>
			<cfif OnPage GT 1>
				<a href="<cfoutput>#CurrentPage#?OnPage=1&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
			<cfelse>
				<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
			</cfif>
		</td>
		<td align="center" class="sub">[ page 	
			<cfoutput>
			<select name="pageselect" onChange="openURL()"> 
				<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
					<option value="#CurrentPage#?OnPage=#this_i#&xL=#xL#&xT=#xT#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
				</cfloop>
			</select>
			of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
			</cfoutput>
		</td>
		<td align="right">
			<cfif OnPage LT TotalPages_SelectList>
				<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&raquo;</a>
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
		<td align="center"><a href="#CurrentPage#?pgfn=add&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Add</a></td>
		<td>
			<span class="headertext">Cost Center</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		</td>
		<td>Description</td>
		<td></td>
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
		<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content'),de('content2'))#">
		<td><a href="#CurrentPage#?pgfn=edit&id=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Edit</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?pgfn=copy&id=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Copy</a><cfif FLGen_HasAdminAccess(9990000053)>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?delete=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#" onclick="return confirm('Are you sure you want to delete this cost center?  There is NO UNDO.')">Delete</a></cfif></td>
		<td valign="top">#htmleditformat(number)#</td>
		<td valign="top">#htmleditformat(description)#</td>
		<td valign="top"><a href="cost_center_approvers.cfm?cost_center_ID=#ID#">Approvers</a></td>
		</tr>
	</cfoutput>

	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit" OR pgfn EQ "copy">
	<!--- START pgfn ADD/EDIT --->
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add" OR pgfn EQ "copy">Add<cfelse>Edit</cfif> a Cost Center</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Cost Center List</a> without making changes.</span>
	<br /><br />
	</cfoutput>

	<cfif pgfn eq 'copy'>
		<span class="pageinstructions"><span class="alert">You are creating a new cost center.</span> The form below is filled with</span>
		<br />
		<span class="pageinstructions">the information from the cost center you requested to copy.</span>
		<br /><br />
	</cfif>

	<cfif pgfn EQ "edit" OR pgfn EQ "copy">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, number, description 
			FROM #application.database#.cost_centers
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
		<cfset ID = ToBeEdited.ID>
		<cfset number = htmleditformat(ToBeEdited.number)>
		<cfset description = htmleditformat(ToBeEdited.description)>
	</cfif>

	<form method="post" action="#CurrentPage#">
	<cfoutput>

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add" OR pgfn EQ "copy">Add<cfelse>Edit</cfif> a Cost Center</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Cost Center Number: </td>
	<td valign="top"><input type="text" name="number" value="#number#" maxlength="5" size="5"></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Description: </td>
	<td valign="top"><input type="text" name="description" value="#description#" maxlength="64" size="40"></td>
	</tr>
			
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="pgfn" value="#pgfn#">
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	<input type="hidden" name="ID" value="#ID#">
	<input type="hidden" name="number_required" value="Please enter a cost center number.">
		
	<input type="submit" name="submit" value="   Save Changes   " >
	</td>
	</tr>
	</table>
	</cfoutput>
	</form>

	<!--- END pgfn ADD/EDIT --->
</cfif>

</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->