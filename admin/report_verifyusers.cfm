<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000070,true)>

<cfparam name="remove" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif remove NEQ "">
	<cfquery name="UpdateUser" datasource="#application.DS#">
		UPDATE #application.database#.program_user
		SET	entered_by_program_admin = 0
			#FLGen_UpdateModConcatSQL()#
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#remove#">
	</cfquery>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "verifyusers">
<cfinclude template="includes/header.cfm">

<script src="../includes/showhide.js"></script>

<span class="pagetitle">Verify Users Report</span>
<br /><br />
<span class="pageinstructions">This report lists all program users that have been entered or edited by Program Admins.</span>
<br /><br />
<cfquery name="getUsers" datasource="#application.DS#">
	SELECT ID, created_user_ID, created_datetime, modified_concat, program_ID, username, fname, lname, email, cc_max, is_active, is_done, defer_allowed, expiration_date 
	FROM #application.database#.program_user
	WHERE entered_by_program_admin = 1	
	ORDER BY program_ID, created_datetime ASC
</cfquery>

<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<!--- header row --->
	<tr valign="top" class="contenthead">
	<td valign="top" class="headertext">&nbsp;</td>
	<td valign="top" class="headertext">User Info</td>
	<td valign="top" class="headertext">Points</td>
	<td valign="top" class="headertext">Deferred<br>[Allowed]</td>
	<td valign="top" class="headertext">Max CC</td>
	<td valign="top" class="headertext">&nbsp;</td>
	</tr>

	<cfif getUsers.RecordCount EQ 0>
		<tr class="content2">
		<td colspan="100%" align="center" class="alert"><br>There are no users to display.<br><br></td>
		</tr>
	</cfif>

	<cfoutput query="getUsers" group="program_ID">
		<tr class="content2">
			<td colspan="100%" class="headertext">#GetProgramName(getUsers.program_ID)#</td>
		</tr>
		<cfoutput>
			<!--- calculate points --->
			<cfset ProgramUserInfo(ID)>
			<!--- user_totalpoints // user_deferedpoints  --->
			<tr class="<cfif (CurrentRow MOD 2) EQ 0>content2<cfelse>content</cfif>">
			<td valign="top" align="right"><a href="program_user.cfm?pgfn=edit&program_select=#getUsers.program_ID#&puser_id=#getUsers.ID#">edit</a><br><span style="font-size:18px">&nbsp;</span><a href="#CurrentPage#?remove=#ID#">remove from list</a></td>
			<td valign="top">#username#<br>#fname# #lname#<br>#email#</td>
			<td valign="top">#user_totalpoints#</td>
			<td valign="top">#user_deferedpoints# [#defer_allowed#]</td>
			<td valign="top">#cc_max#</td>
			<td valign="top">
			<!--- [+] or "show xyz" --->
			<a href="##" ID="showlink_#ID#" onClick="showThis('item_#ID#');showThis('hidelink_#ID#');hideThis('showlink_#ID#'); return false">show &raquo;</a>
			<!--- [-] or "hide xyz" --->
			<a href="##" ID="hidelink_#ID#" onClick="hideThis('item_#ID#');hideThis('hidelink_#ID#');showThis('showlink_#ID#'); return false" style="display:none">hide &raquo;</a>
			</td>
			</tr>

			<tr ID="item_#ID#" style="display:none" class="BGshowhide">
			<td bgcolor="##FFFFFF">&nbsp;</td>
			<td colspan="4">Entered by #FLGen_GetAdminName(created_user_ID)# #created_datetime#<cfif modified_concat NEQ ""><br><br>Modified:<br><br>#FLGen_DisplayModConcat(modified_concat)#</cfif></td>
			<td bgcolor="##FFFFFF">&nbsp;</td>
			</tr>
		</cfoutput>
	</cfoutput>
</table>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->