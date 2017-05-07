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
<cfparam name="xS" default="location_name">
<cfparam name="xT" default="">
<cfparam name="xL" default="">

<!--- param a/e form fields --->
<cfparam name="ID" default="">	
<cfparam name="location_name" default="">
<cfparam name="company" default="">
<cfparam name="attention" default="">
<cfparam name="address1" default="">
<cfparam name="address2" default="">
<cfparam name="city" default="">
<cfparam name="state" default="">
<cfparam name="zip" default="">
<cfparam name="phone" default="">
<cfparam name="delete" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif has_program>
<cfif IsDefined('form.Submit')>
	<!--- update --->
	<cfif form.pgfn EQ "edit">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.shipping_locations
			SET	location_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#location_name#" maxlength="60">,
				company = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.company#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(form.company)))#">,
				attention = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.attention#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.attention)))#">,
				address1 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.address1#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.address1)))#">,
				address2 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.address2#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.address2)))#">,
				city = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.city #" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.city )))#">,
				state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.state#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.state)))#">,
				zip = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.zip)))#">,
				phone = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.phone#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(form.phone)))#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelseif form.pgfn EQ "add" OR form.pgfn EQ "copy">
		<cflock name="slLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#" result="stResult">
					INSERT INTO #application.database#.shipping_locations
						(created_user_ID, created_datetime, program_ID, location_name, company, attention, address1, address2, city, state, zip, phone)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#',
						<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">,  
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#location_name#" maxlength="60">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.company#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(form.company)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.attention#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.attention)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.address1#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.address1)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.address2#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.address2)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.city #" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.city )))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.state#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.state)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.zip)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.phone#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(form.phone)))#">
					)
				</cfquery>
				<cfset ID = stResult.GENERATED_KEY>
			</cftransaction>  
		</cflock>
	</cfif>
	<cfset alert_msg = Application.DefaultSaveMessage>
	<cfset pgfn = "list">
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000053)>
	<cfquery name="Deletesl" datasource="#application.DS#">
		DELETE FROM #application.database#.shipping_locations
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>			
	<cfset pgfn = "list">
</cfif>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfparam  name="pgfn" default="list">

<cfif NOT has_program>
	<span class="pagetitle">Shipping Locations</span>
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
		SELECT ID, location_name, city, state, zip, is_active
		FROM #application.database#.shipping_locations
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		<cfif LEN(xT) GT 0>
			AND location_name LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">
		<cfelseif LEN(xL) GT 0>
			AND location_name LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xL#%">
		</cfif>
		ORDER BY location_name
	</cfquery>
	
	<!--- set the start/end/max display row numbers --->
	<cfparam name="OnPage" default="1">
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	
	<span class="pagetitle">Shipping Location List</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="program_list.cfm">Award Program List</a> without making changes.</span>
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
		<td class="headertext">Shipping Location</td>
		<td class="headertext">City, State, Zip</td>
		</tr>
	</cfoutput>

	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="3" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
		</tr>
	</cfif>

	<!--- display found records --->
	<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
		<tr class="#Iif(is_active EQ 1,de(Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))), de('inactivebg'))#">
		<!--- <tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">--->
		<td><a href="#CurrentPage#?pgfn=edit&id=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Edit</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?pgfn=copy&id=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Copy</a><cfif FLGen_HasAdminAccess(9990000053)>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?delete=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#" onclick="return confirm('Are you sure you want to delete this shipping location?  There is NO UNDO.')">Delete</a></cfif></td>
		<td valign="top">#htmleditformat(location_name)#</td>
		<td>#city#, #state# #zip#</td>
		</tr>
	</cfoutput>

	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit" OR pgfn EQ "copy">
	<!--- START pgfn ADD/EDIT --->
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add" OR pgfn EQ "copy">Add<cfelse>Edit</cfif> a Shipping Location</span>
	<br /><br />

	<span class="pageinstructions">Return to <a href="#CurrentPage#?&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Shipping Location List</a> without making changes.</span>
	<br /><br />
	</cfoutput>

	<cfif pgfn eq 'copy'>
		<span class="pageinstructions"><span class="alert">You are creating a new shipping location.</span> The form below is filled with</span>
		<br />
		<span class="pageinstructions">the information from the shipping location you requested to copy.</span>
		<br /><br />
	</cfif>

	<cfif pgfn EQ "edit" OR pgfn EQ "copy">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, location_name, company, attention, address1, address2, city, state, zip, phone 
			FROM #application.database#.shipping_locations
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
		<cfset ID = ToBeEdited.ID>
		<cfset location_name = htmleditformat(ToBeEdited.location_name)>
		<cfset company = htmleditformat(ToBeEdited.company)>
		<cfset attention = htmleditformat(ToBeEdited.attention)>
		<cfset address1 = htmleditformat(ToBeEdited.address1)>
		<cfset address2 = htmleditformat(ToBeEdited.address2)>
		<cfset city = htmleditformat(ToBeEdited.city)>
		<cfset state = htmleditformat(ToBeEdited.state)>
		<cfset zip = htmleditformat(ToBeEdited.zip)>
		<cfset phone = htmleditformat(ToBeEdited.phone)>
	</cfif>

	<form method="post" action="#CurrentPage#">
	<cfoutput>

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add" OR pgfn EQ "copy">Add<cfelse>Edit</cfif> a Shipping Location</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Location Name: </td>
	<td valign="top"><input type="text" name="location_name" value="#location_name#" maxlength="60" size="40"></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Company: </td>
	<td valign="top"><input type="text" name="company" value="#company#" maxlength="32" size="40"></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Attention: </td>
	<td valign="top"><input type="text" name="attention" value="#attention#" maxlength="64" size="40"></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Address Line 1: </td>
	<td valign="top"><input type="text" name="address1" value="#address1#" maxlength="30" size="40"></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Address Line 2: </td>
	<td valign="top"><input type="text" name="address2" value="#address2#" maxlength="30" size="40"></td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">City: </td>
	<td valign="top"><input type="text" name="city" value="#city#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">State: </td>
	<td valign="top"><input type="text" name="state" value="#state#" maxlength="10" size="40"></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Zip: </td>
	<td valign="top"><input type="text" name="zip" value="#zip#" maxlength="10" size="10"></td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Phone: </td>
	<td valign="top"><input type="text" name="phone" value="#phone#" maxlength="32" size="40"></td>
	</tr>
		
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="pgfn" value="#pgfn#">
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	<input type="hidden" name="ID" value="#ID#">
		
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