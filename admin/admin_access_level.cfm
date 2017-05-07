<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000007,true)>

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="sortorder">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="OnPage" default="1">

<!--- param a/e form fields --->
<cfparam name="ID" default="">	
<cfparam name="level_name" default="">
<cfparam name="sortorder" default="">
<cfparam name="note" default="">

<cfparam  name="pgfn" default="list">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- if sortorder is empty, save as zero --->
	<cfparam name="sortordervalue" default="0">
	<cfif form.sortorder EQ "">
		<cfset sortorder="0">
	</cfif>
	<!--- update --->
	<cfif form.pgfn EQ "edit">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.admin_level
			SET	level_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.level_name#" maxlength="60">,
				sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#sortorder#" maxlength="5">,
				note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.note#" null = "#YesNoFormat(NOT Len(Trim(form.note)))#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelse>
		<cflock name="admin_levelLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.admin_level
						(level_name, sortorder, note, created_user_ID, created_datetime)
					VALUES
						(<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.level_name#" maxlength="60">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#sortorder#" maxlength="5">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.note#" null = "#YesNoFormat(NOT Len(Trim(form.note)))#">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						#FLGen_DateTimeToMySQL()#)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.admin_level
				</cfquery>
				<cfset ID = getID.MaxID>
			</cftransaction>  
		</cflock>
	</cfif>
	<cfset alert_msg = Application.DefaultSaveMessage>
	<cfset pgfn = "edit">
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "admin_access_levels">
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
	<!--- Set the WHERE clause --->
	<!--- First check if a search string passed --->
	<cfif LEN(xT) GT 0>
		<cfset xL = "">
	</cfif>
	<!--- run query --->
	<cfif xS EQ "level_name" OR xS EQ "sortorder" OR xS EQ "ID">
		<cfquery name="SelectList" datasource="#application.DS#">
			SELECT ID, level_name, sortorder, IFNULL(note,"(no note)") AS note
			FROM #application.database#.admin_level
			<cfif LEN(xT) GT 0>
				WHERE ID LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> or level_name LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%"> or note LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">
					AND note <> 'NOT USED YET'
			<cfelseif LEN(xL) GT 0>
				WHERE #xS# LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xL#%" maxlength="3"> 
					AND note <> 'NOT USED YET'
			<cfelse>
				WHERE note <> 'NOT USED YET'
			</cfif>
			ORDER BY #xS# ASC
		</cfquery>
	</cfif>
	<!--- set the start/end/max display row numbers --->
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	<span class="pagetitle">Admin Access Level List</span>
	<br /><br />
	<span class="pageinstructions">Access levels are <b>only</b> effective if:</span>
	<br>
	<span class="pageinstructions">&nbsp;&nbsp;&nbsp;&middot;&nbsp;added here</span>
	<br>
	<span class="pageinstructions">&nbsp;&nbsp;&nbsp;&middot;&nbsp;assigned to admin users</span>
	<br>
	<span class="pageinstructions">&nbsp;&nbsp;&nbsp;&middot;&nbsp;incorporated into the website code</span>
	<br /><br />
	<span class="pageinstructions"><a href="admin_access_level_order.cfm">Set sort order</a> for admin access levels.  The sort order is only used on this page.</span>
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
		<br />		
		</cfoutput>
		<cfoutput><cfif LEN(xL) IS 0><span class="ltrON">ALL</span><cfelse><a href="#CurrentPage#?xL=&xS=#xS#" class="ltr">ALL</a></cfif></cfoutput><span class="ltrPIPE">&nbsp;&nbsp;</span><cfloop index = "LoopCount" from = "0" to = "9"><cfoutput><cfif xL IS LoopCount><span class="ltrON">#LoopCount#</span><cfelse><a href="#CurrentPage#?xL=#LoopCount#&xS=#xS#" class="ltr">#LoopCount#</a></cfif></cfoutput><span class="ltrPIPE">&nbsp;&nbsp;</span></cfloop><cfloop index = "LoopCount" from = "1" to = "26"><cfoutput><cfif xL IS CHR(LoopCount + 64)><span class="ltrON">#CHR(LoopCount + 64)#</span><cfelse><a href="#CurrentPage#?xL=#CHR(LoopCount + 64)#&xS=#xS#" class="ltr">#CHR(LoopCount + 64)#</a></cfif><span class="ltrPIPE">&nbsp;&nbsp;</span><cfif LoopCount NEQ 26></cfif></cfoutput></cfloop>
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
			<a href="<cfoutput>#CurrentPage#?OnPage=1&xS=#xS#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xS=#xS#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
		</cfif>
		</td>
		<td align="center" class="sub">[ page 	
		<cfoutput>
		<select name="pageselect" onChange="openURL()"> 
				<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
			<option value="#CurrentPage#?OnPage=#this_i#&xS=#xS#&xL=#xL#&xT=#xT#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
				</cfloop>
		</select> of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
		</cfoutput>
		</td>
		<td align="right">
			<cfif OnPage LT TotalPages_SelectList>
				<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xS=#xS#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xS=#xS#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&raquo;</a>
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
	<td align="center"><a href="#CurrentPage#?pgfn=add&xS=#xS#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Add</a></td>
	<td>
		<cfif xS IS "sortorder">
			<span class="headertext">Sort Order</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xS=sortorder&xL=#xL#&xT=#xT#" class="headertext">Sort Order</a>
		</cfif>
	</td>
	<td>
		<cfif xS IS "level_name">
			<span class="headertext">Level Name</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xS=level_name&xL=#xL#&xT=#xT#" class="headertext">Level Name</a>
		</cfif>
	</td>
	<td><span class="headertext">Note</span></td>
	</tr>
	</cfoutput>
	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="4" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
		</tr>
	<cfelse>
		<!--- display found records --->
		<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
			<cfif note EQ "header">
			<tr class="contentsearch">
			<td colspan="4" class="headertext">#HTMLEditFormat(level_name)# <span class="sub">[#HTMLEditFormat(sortorder)#]</span></td>
			</tr>
			<cfelse>
			<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
			<td align="right" valign="top" nowrap="nowrap">
				<a href="#CurrentPage#?pgfn=edit&id=#ID#&xS=#xS#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Edit</a>
				<a href="#CurrentPage#?pgfn=copy&id=#ID#&xS=#xS#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Copy</a>
			</td>
			<td valign="top">#HTMLEditFormat(sortorder)#</td>
			<td valign="top">#HTMLEditFormat(level_name)#</td>
			<td valign="top"><span class="sub">[code: #HTMLEditFormat(ID)#]</span><br />#Replace(HTMLEditFormat(note),chr(10),"<br>","ALL")#</td>
			</tr>
			</cfif>
		</cfoutput>
	</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit" OR pgfn EQ "copy">
	<!--- START pgfn ADD/EDIT --->
	<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> an Admin Access Level</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="<cfoutput>#CurrentPage#?&xS=#xS#&xL=#xL#&xT=#xT#&OnPage=#OnPage#</cfoutput>">Admin Access Level List</a> without making changes.</span>
	<br /><br />
	<cfif pgfn eq 'copy'>
		<span class="pageinstructions"><span class="alert">You are creating a new access level.</span> The form below is filled with</span>
		<br />
		<span class="pageinstructions">the information from the access level you requested to copy.</span>
		<br /><br />
	</cfif>
	<cfif pgfn EQ "edit" OR pgfn EQ "copy">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, level_name, sortorder, note
			FROM #application.database#.admin_level
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">
		</cfquery>
		<cfset ID = ToBeEdited.ID>
		<cfset sortorder = HTMLEditFormat(ToBeEdited.sortorder)>
		<cfset level_name = HTMLEditFormat(ToBeEdited.level_name)>
		<cfset note = HTMLEditFormat(ToBeEdited.note)>
	</cfif>
	<cfoutput>
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0">
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add">Add an</cfif> Admin Access Level <cfif pgfn EQ "edit">Edit</cfif></td>
	</tr>
	<cfif pgfn EQ "edit">	
		<tr class="content">
		<td align="right">Code Number: </td>
		<td>#ID#</td>
		</tr>
	</cfif>
	<tr class="content">
	<td align="right" valign="top">Level Name: </td>
	<td valign="top"><input type="text" name="level_name" value="#level_name#" maxlength="60" size="50"></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Sort Order: </td>
	<td valign="top"><input type="text" name="sortorder" value="#sortorder#" maxlength="5" size="7"></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Note: </td>
	<td valign="top"><textarea name="note" cols="58" rows="3">#note#</textarea></td>
	</tr>
		
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="xS" value="#xS#">
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	<input type="hidden" name="ID" value="#ID#">
	<input type="hidden" name="pgfn" value="#pgfn#">
	
	<input type="hidden" name="level_name_required" value="Please enter a level name.">
		
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