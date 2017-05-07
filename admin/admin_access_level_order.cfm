<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000007,true)>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- loop through the form fields and do individual updates --->
	<cfloop index="lc" from="1" to="#form.TotalRecords#">
		<cfset thisID = "form.lc" & lc & "_ID">
		<cfset thislevel_name = "form.lc" & lc & "_level_name">
		<cfset thissortorder = "form.lc" & lc & "_sortorder">
		<cfset thisID = Evaluate(thisID)>
		<cfset thislevel_name = Evaluate(thislevel_name)>
		<cfset thissortorder = Evaluate(thissortorder)>
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.admin_level
			SET	level_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#thislevel_name#" maxlength="60">,
				sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#thissortorder#" maxlength="5">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisID#" maxlength="10">
		</cfquery>
	</cfloop>
	<cfset alert_msg = Application.DefaultSaveMessage>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "admin_access_levels">
<cfinclude template="includes/header.cfm">

<cfquery name="SelectList" datasource="#application.DS#">
	SELECT ID, level_name, sortorder, IFNULL(note,"(no note)") AS note
	FROM #application.database#.admin_level
	WHERE note <> 'NOT USED YET' 
	ORDER BY sortorder ASC
</cfquery>

<span class="pagetitle">Set Sort Order for Admin Access Levels</span>
<br /><br />
<span class="pageinstructions">This sort order is used on the Manage Access page in the Admin User section.</span>
<br /><br />
<span class="pageinstructions">Return to <a href="admin_access_level.cfm" class="alert">Admin Access Level List</a> without making changes.</span>
<br /><br />

<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr class="contenthead">
	<td><span class="headertext">Code&nbsp;Number</span></td>
	<td><span class="headertext">Sort Order</span></td>
	<td><span class="headertext">Level Name</span></td>
	<td><span class="headertext">Note</span></td>
	</tr>
	<cfset loopcounter = 0>
	<cfoutput query="SelectList">
		<cfset loopcounter = loopcounter + 1>
		<cfset safe_sortorder = HTMLEditFormat(sortorder)>
		<cfset safe_level_name = HTMLEditFormat(level_name)>
		<cfset safe_note = Replace(HTMLEditFormat(note),chr(10),"<br>","ALL")>
		<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
		<td valign="top">#ID#<input type="hidden" name="lc#loopcounter#_ID" value="#ID#"></td>
		<td valign="top"><input type="text" name="lc#loopcounter#_sortorder" value="#safe_sortorder#" maxlength="5" size="7"></td>
		<td valign="top"><input type="text" name="lc#loopcounter#_level_name" value="#safe_level_name#" maxlength="60" size="32"></td>
		<td valign="top">#safe_note#
		<input type="hidden" name="lc#loopcounter#_sortorder_required" value="Please enter a sort order for code number #ID# (#safe_level_name#).">
		<input type="hidden" name="lc#loopcounter#_level_name_required" value="Please enter a level name for code number #ID#.">
		</td>
		</tr>
	</cfoutput>
	<tr class="content">
	<td colspan="4" align="center">
	<input type="hidden" name="TotalRecords" value="<cfoutput>#SelectList.RecordCount#</cfoutput>">
	<input type="submit" name="submit" value="Save All Changes" >
	</td>
	</tr>
	</table>
</form>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->