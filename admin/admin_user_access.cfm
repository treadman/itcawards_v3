<cfif NOT isDefined("userID") OR userID LTE 0>
	<cflocation url="admin_user.cfm" addtoken="no">
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000030,true)>

<cfparam name="currentrow" default=0>
<cfparam name="accessred" default="">
<cfparam name="checkaccess" default="">
<cfparam name="vGetThisAccess" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- delete all the entries for this user --->
	<cfquery name="DeleteUserAccess" datasource="#application.DS#">
		DELETE FROM #application.database#.admin_lookup
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.userid#" maxlength="10">
	</cfquery>
	<!--- loop through the form fields and do individual inserts --->
	<cfloop index="lc" from="1" to="#form.TotalRecords#">
		<cfset thisID = "LC" & lc & "_ID">
		<cfset thisIDform = "form.LC" & lc & "_ID">
		<cfif ListContains(form.FieldNames,thisID)>
			<cfset thisIDform = Evaluate(thisIDform)>
			<cfquery name="InsertQuery" datasource="#application.DS#">
				INSERT INTO #application.database#.admin_lookup
					(created_user_ID, created_datetime, user_ID, access_level_ID)
				VALUES (
					<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
					'#FLGen_DateTimeToMySQL()#',
					<cfqueryparam cfsqltype="cf_sql_integer" value="#userID#" maxlength="10">,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#thisIDform#" maxlength="10">)
			</cfquery>
		</cfif>
	</cfloop>
	<cflocation url="admin_user.cfm?alert_msg=#urlencodedformat(Application.DefaultSaveMessage)#" addtoken="no">
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "admin_users">
<cfinclude template="includes/header.cfm">

<cfquery name="SelectUserInfo" datasource="#application.DS#">
	SELECT firstname, lastname
	FROM #application.database#.admin_users
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#userID#" maxlength="10">
</cfquery>

<!--- if no user is found, send back to user page --->
<cfif SelectUserInfo.RecordCount EQ 0><cflocation url="admin_user.cfm" addtoken="no"></cfif>

<cfquery name="SelectList" datasource="#application.DS#">
	SELECT ID, level_name, sortorder, IFNULL(note,"(no note)") AS note, sortorder
	FROM #application.database#.admin_level
	WHERE note <> 'NOT USED YET' 
	ORDER BY sortorder ASC
</cfquery>

<!--- look in adminaccess db for current user access levels --->
<cfquery name="GetThisAccess" datasource="#application.DS#">
	SELECT access_level_ID
	FROM #application.database#.admin_lookup
	WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#userID#" maxlength="10">
</cfquery>

<cfparam name="vGetThisAccess" default="">

<cfloop query="GetThisAccess">
	<cfset vGetThisAccess = vGetThisAccess & " " & GetThisAccess.access_level_ID>
</cfloop>

<cfoutput>
<span class="pagetitle">Assign Admin Access</span>
<br /><br />
<span class="pageinstructions">Current access level assignments are in bold below.</span>
<br /><br />
<span class="pageinstructions">Return to <a href="admin_user.cfm">Admin User List</a> without making changes.</span>
<br /><br />

<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr class="content">
	<td colspan="4"><span class="headertext">Admin User: <span class="selecteditem">#SelectUserInfo.firstname# #SelectUserInfo.lastname#</span></span></td>
	</tr>
	
	<tr class="contenthead">
	<td class="headertext"></td>
	<td class="headertext">Code Number</td>
	<td class="headertext">Level Name</td>
	<td class="headertext">[Sort Order] Note</td>
	</tr>
	
	<cfloop query="SelectList">
		<cfif note EQ 'header'>
			<tr class="contentsearch">
				<td colspan="100%" class="headertext">#level_name# <span class="sub">[#sortorder#]</span></td>
			</tr>
		<cfelse>
			<cfif FLGen_HasAdminAccess(SelectList.ID,false,vGetThisAccess)>
				<cfset checkaccess = " checked">
			<cfelse>
				<cfset checkaccess = "">
			</cfif>
			<tr class="<cfif checkaccess NEQ "">selectedbgcolor<cfelse>#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))# </cfif>">
				<td valign="top"><input type="checkbox" name="lc#currentrow#_ID" value="#ID#"#checkaccess#></td>
				<td valign="top">#ID#</td>
				<td valign="top">#level_name#</td>
				<td valign="top"><span class="sub">[ #sortorder# ]</span> #Replace(note,chr(10),"<br>","ALL")#</td>
			</tr>
		</cfif>
	</cfloop>
	<tr class="content">
		<td colspan="4" align="center">
			<input type="hidden" name="TotalRecords" value="#SelectList.RecordCount#">
			<input type="hidden" name="userid" value="#userid#">
			<input type="submit" name="submit" value="   Assign Checked Access Levels   ">
		</td>
	</tr>
	</table>
</form>
</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->