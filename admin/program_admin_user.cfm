<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000067",true)>

<cfparam name="delete" default="">
<cfparam name="company_name" default="">
<cfparam name="where_string" default="">
<cfparam name="puser_ID" default="">
<cfparam name="duplicateusername" default="false">
<cfparam name="pgfn" default="list">

<!--- main program page paging/sort/search variables --->
<cfparam name="xS" default="">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="OnPage" default="1">
<cfparam name="xtrawhrere" default="">

<!--- param search criteria xxS=ColumnSort xxT=SearchString xxL=Letter --->
<cfparam name="xxS" default="username">
<cfparam name="xxT" default="">
<cfparam name="xxL" default="">
<cfparam name="xOnPage" default="1">

<!--- param a/e form fields --->
<cfparam name="username" default="">
<cfparam name="fname" default="">
<cfparam name="lname" default="">
<cfparam name="nickname" default="">
<cfparam name="email" default="">
<cfparam name="phone" default="">
<cfparam name="is_active" default="">
<cfparam name="is_done" default="">
<cfparam name="expiration_date" default="">
<cfparam name="cc_max" default="">
<cfparam name="defer_allowed" default="">
<cfparam name="ship_address1" default="">
<cfparam name="ship_address2" default="">
<cfparam name="ship_city" default="">
<cfparam name="ship_state" default="">
<cfparam name="ship_zip" default="">
<cfparam name="bill_fname" default="">
<cfparam name="bill_lname" default="">
<cfparam name="bill_address1" default="">
<cfparam name="bill_address2" default="">
<cfparam name="bill_city" default="">
<cfparam name="bill_state" default="">
<cfparam name="bill_zip" default="">

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

<cfif has_program>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit') AND IsDefined('form.username') AND form.username IS NOT "">

	<!--- check to see if this username is already in use for this program --->
	<cfquery name="AnyDuplicateUsernames" datasource="#application.DS#">
		SELECT ID
		FROM #application.database#.program_user
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.username#">
		AND program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		<cfif form.puser_ID IS NOT "">
			AND ID <> <cfqueryparam cfsqltype="cf_sql_integer" value="#form.puser_ID#">
		</cfif>
	</cfquery>

	<cfif AnyDuplicateUsernames.RecordCount EQ 0>
		<!--- update --->
		<cfif form.puser_ID IS NOT "">
			<cfquery name="UpdateQuery" datasource="#application.DS#">
				UPDATE #application.database#.program_user
				SET username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.username#" maxlength="16">,
					fname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.fname)))#">,
					lname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.lname)))#">,
					nickname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.nickname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.nickname)))#">,
					email = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(form.email)))#">,
					phone = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.phone#" maxlength="20" null="#YesNoFormat(NOT Len(Trim(form.phone)))#">,
					ship_address1 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_address1#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.ship_address1)))#">,
					ship_address2 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.ship_address2)))#">,
					ship_city = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.ship_city)))#">,
					ship_state = <cfqueryparam cfsqltype="cf_sql_char" value="#form.ship_state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.ship_state)))#">,
					ship_zip = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.ship_zip)))#">,
					bill_fname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_fname)))#">,
					bill_lname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_lname)))#">,
					bill_address1 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_address1#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.bill_address1)))#">,
					bill_address2 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.bill_address2)))#">,
					bill_city = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_city)))#">,
					bill_state = <cfqueryparam cfsqltype="cf_sql_char" value="#form.bill_state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.bill_state)))#">,
					bill_zip = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.bill_zip)))#">,
					is_active = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_active#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.is_active)))#">,
					is_done = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_done#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.is_done)))#">,
					expiration_date = <cfqueryparam cfsqltype="cf_sql_date" value="#form.expiration_date#" null="#YesNoFormat(NOT Len(Trim(form.expiration_date)))#">,
					entered_by_program_admin = 1
					#FLGen_UpdateModConcatSQL()#
					WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.puser_ID#">
			</cfquery>
		<!--- add --->
		<cfelse>
			<cflock name="program_userLock" timeout="10">
				<cftransaction>
					<cfquery name="InsertQuery" datasource="#application.DS#">
						INSERT INTO #application.database#.program_user
							(created_user_ID, created_datetime, username, fname, lname, nickname, email, phone, is_active, is_done, expiration_date, cc_max, defer_allowed, ship_address1, ship_address2, ship_city, ship_state,  ship_zip, bill_fname, bill_lname, bill_address1, bill_address2, bill_city, bill_state,  bill_zip, program_ID, entered_by_program_admin)
						VALUES
							(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#', 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.username#" maxlength="16">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.fname)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.lname)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.nickname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.nickname)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(form.email)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.phone#" maxlength="20" null="#YesNoFormat(NOT Len(Trim(form.phone)))#">, 
							<cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_active#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.is_active)))#">, 
							<cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_done#" maxlength="1" null="#YesNoFormat(NOT Len(Trim(form.is_done)))#">, 
							<cfqueryparam cfsqltype="cf_sql_date" value="#form.expiration_date#" null="#YesNoFormat(NOT Len(Trim(form.expiration_date)))#">, 
							0,
							0,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_address1#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.ship_address1)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.ship_address2)))#">, 
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.ship_city)))#">, 
							<cfqueryparam cfsqltype="cf_sql_char" value="#form.ship_state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.ship_state)))#">,
							 <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.ship_zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.ship_zip)))#">, 
							 <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_fname)))#">, 
							 <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_lname)))#">, 
							 <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_address1#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.bill_address1)))#">, 
							 <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_address2#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(form.bill_address2)))#">, 
							 <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(form.bill_city)))#">, 
							 <cfqueryparam cfsqltype="cf_sql_char" value="#form.bill_state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.bill_state)))#">, 
							 <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.bill_zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.bill_zip)))#">, 
							 <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
							 1)
					</cfquery>
					<cfquery name="getID" datasource="#application.DS#">
						SELECT Max(ID) As MaxID FROM #application.database#.program_user
					</cfquery>
					<cfset puser_ID = getID.MaxID>
				</cftransaction>  
			</cflock>
			<cfif trim(form.submit) EQ "Save and go to Add Points page">
				<cflocation addtoken="no" url="#CurrentPage#?pgfn=points&puser_ID=#puser_ID#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">
			</cfif>
		</cfif>
		<cfset alert_msg = Application.DefaultSaveMessage>
		<cfset pgfn = "edit">
	<cfelse>
		<cfset duplicateusername = true>
	</cfif>
	
<cfelseif IsDefined('form.Submit') AND IsDefined('form.point_amount') AND Trim(form.point_amount) IS NOT "">

	<cfif addsub EQ "sub">
		<cfset point_amount = - point_amount>
	</cfif>
	<!--- if user, add points for this user --->
	<cfif puser_ID NEQ "">
		<cfquery name="InsertPoints" datasource="#application.DS#">
			INSERT INTO #application.database#.awards_points
			(created_user_ID, created_datetime, user_ID, points, notes)
			VALUES
			('#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#',
				<cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#point_amount#" maxlength="8">,
				<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#note#" null="#YesNoFormat(NOT Len(Trim(note)))#">)
		</cfquery>

	<!--- if NO user, add points for all users in this program --->
	<cfelse>
	
		<cfquery name="FindAllProgramUsers" datasource="#application.DS#">
			SELECT ID AS THISpuser_ID
			FROM #application.database#.program_user
			WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		</cfquery>
		<cfloop query="FindAllProgramUsers">
			<cfquery name="InsertEachPoints" datasource="#application.DS#">
			INSERT INTO #application.database#.awards_points
			(created_user_ID, created_datetime, user_ID, points, notes)
			VALUES
			('#FLGen_adminID#', '#FLGen_DateTimeToMySQL()#',
				<cfqueryparam cfsqltype="cf_sql_integer" value="#THISpuser_ID#" maxlength="10">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#point_amount#" maxlength="8">,
				<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#note#" null="#YesNoFormat(NOT Len(Trim(note)))#">)
			</cfquery>
		</cfloop>
	</cfif>
	<cfset alert_msg = Application.DefaultSaveMessage>
<cfelseif delete NEQ ''>
	<cfquery name="DeleteLineItem" datasource="#application.DS#">
		DELETE FROM #application.database#.awards_points
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#">
	</cfquery>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

</cfif>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programadminusers">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Program User List</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">
	<cfif LEN(xxT) GT 0>
		<cfset xxL = "">
	</cfif>
	<!--- run query --->
	<cfif xxS EQ "username" OR xxS EQ "lname" OR xxS EQ "email" OR xxS EQ "is_active">
		<cfquery name="SelectList" datasource="#application.DS#">
			SELECT ID AS puser_ID, username, IFNULL(fname,"-") AS fname, IFNULL(lname,"-") AS lname, IFNULL(email,"-") AS email, If(is_active = 1,"active","inactive") AS is_active, cc_max, defer_allowed, IF(is_done=1,"ordered","not ordered") AS is_done
			FROM #application.database#.program_user
			WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
			AND (is_active = 1 OR username not like '%|merged to user_id:%')
			<cfif LEN(xxT) GT 0>
				AND (ID LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%"> 
					OR username LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%"> 
					OR fname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%"> 
					OR lname LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%"> 
					OR email LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#xxT#%">)
			<cfelseif LEN(xxL) GT 0>
				AND #xxS# LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xxL#%">
			</cfif>
			ORDER BY #xxS# ASC
		</cfquery>
	</cfif>
	<cfquery name="SelectProgramInfo" datasource="#application.DS#">
		SELECT company_name, is_one_item, can_defer
		FROM #application.database#.program
		WHERE ID=<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#">
	</cfquery>
	<cfset is_one_item = SelectProgramInfo.is_one_item>
	<!--- set the start/end/max display row numbers --->
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((xOnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	<span class="pagetitle">Program User List</span>
	<br /><br />
	<!--- search box --->
	<cfoutput>
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	<tr class="contenthead">
	<td><span class="headertext">Search Criteria</span></td>
	<td align="right"><a href="#CurrentPage#" class="headertext">view all</a></td>
	</tr>
	<tr>
	<td class="content" colspan="2" align="center">
		<form action="#CurrentPage#" method="post">
			<input type="hidden" name="xxL" value="#xxL#">
			<input type="hidden" name="xxS" value="#xxS#">
			<input type="text" name="xxT" value="#xxT#" size="20">
			<input type="submit" name="submit" value="   Search   ">
			<input type="hidden" name="xS" value="#xS#">
			<input type="hidden" name="xL" value="#xL#">
			<input type="hidden" name="xT" value="#xT#">
			<input type="hidden" name="OnPage" value="#OnPage#">
		</form>
		<br>
		<cfif LEN(xxL) IS 0><span class="ltrON">ALL</span><cfelse><a href="#CurrentPage#?xxL=&xxS=#xxS#" class="ltr">ALL</a></cfif><span class="ltrPIPE">&nbsp;&nbsp;</span><cfloop index = "LoopCount" from = "0" to = "9"><cfif xxL IS LoopCount><span class="ltrON">#LoopCount#</span><cfelse><a href="#CurrentPage#?xxL=#LoopCount#&xxS=#xxS#" class="ltr">#LoopCount#</a></cfif><span class="ltrPIPE">&nbsp;&nbsp;</span></cfloop><cfloop index = "LoopCount" from = "1" to = "26"><cfif xxL IS CHR(LoopCount + 64)><span class="ltrON">#CHR(LoopCount + 64)#</span><cfelse><a href="#CurrentPage#?xxL=#CHR(LoopCount + 64)#&xxS=#xxS#" class="ltr">#CHR(LoopCount + 64)#</a></cfif><cfif LoopCount NEQ 26><span class="ltrPIPE">&nbsp;&nbsp;</span></cfif></cfloop>
	</td>
	</tr>
	</table>
	<br />
	<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr>
	<td>
		<cfif xOnPage GT 1>
			<a href="#CurrentPage#?xOnPage=1&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?xOnPage=#Max(DecrementValue(xOnPage),1)#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#&xL=#xL#&xT=#xT#&OnPage=#OnPage#" class="pagingcontrols">&lsaquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
		</cfif>
	</td>
	<td align="center" class="sub">[ page displayed: #xOnPage# of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records displayed: #StartRow_SelectList# - #EndRow_SelectList# ]&nbsp;&nbsp;&nbsp;[ total records: #SelectList.RecordCount# ]</td>
	<td align="right">
		<cfif xOnPage LT TotalPages_SelectList>
			<a href="#CurrentPage#?xOnPage=#Min(IncrementValue(xOnPage),TotalPages_SelectList)#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?xOnPage=#TotalPages_SelectList#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#" class="pagingcontrols">&raquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
		</cfif>
	</td>
	</tr>
	</table>
	</cfoutput>
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<!--- header row --->
	<cfoutput>
	<tr class="content2">
	<td  colspan="<cfif is_one_item EQ 0>9<cfelse>5</cfif>"><span class="headertext">Program: <span class="selecteditem">#HTMLEditFormat(SelectProgramInfo.company_name)#</span></span></td>
	</tr>
	<tr class="contenthead">
	<td align="center" rowspan="2"><a href="#CurrentPage#?pgfn=add&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">Add</a></td>
	<td rowspan="2">
		<cfif xxS IS "username">
			<span class="headertext">Username</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xxS=username&xxL=#xxL#&xxT=#xxT#" class="headertext">Username</a>
		</cfif>
	</td>
	<td rowspan="2">
		<cfif xxS IS "lname">
			<span class="headertext">Name</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xxS=lname&xxL=#xxL#&xxT=#xxT#" class="headertext">Name</a>
		</cfif>
	</td>
	<td rowspan="2">
		<cfif xxS IS "email">
			<span class="headertext">Email</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		<cfelse>
			<a href="#CurrentPage#?xxS=email&xxL=#xxL#&xxT=#xxT#" class="headertext">Email</a>
		</cfif>
	</td>
	<cfif is_one_item EQ 0>
		<td colspan="3" align="center"><span class="headertext">Points</span></td>
	<cfelse>
		<td align="center"><span class="headertext">Ordered?</span></td>
	</cfif>
	</tr>
	<tr class="contenthead">
	<cfif is_one_item EQ 0>
	<td colspan="3" align="center">&nbsp;<!--- <a href="#CurrentPage#?pgfn=points&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#">+/-&nbsp;for&nbsp;all&nbsp;users</a> ---></td>
	<cfelse>
	<td align="center"><span class="sub">(one-item store)</span></td>
	</cfif>
	</tr>
	</cfoutput>
	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
			<td colspan="<cfif is_one_item EQ 0>6<cfelse>5</cfif>" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
		</tr>
	<cfelse>
		<!--- display found records --->
		<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
			<tr class="#Iif(is_active EQ "active",de(Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))), de('inactivebg'))#">
			<td align="center"><a href="#CurrentPage#?pgfn=edit&puser_id=#puser_ID#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">Edit</a></td>
			<td valign="top" colspan="3">#HTMLEditFormat(username)#<br>#HTMLEditFormat(fname)#&nbsp;#HTMLEditFormat(lname)#<br>#HTMLEditFormat(email)#</td>
			<cfif is_one_item EQ 0>
				<!--- CALCULATE USER'S POINTS --->
				<cfset ProgramUserInfo(SelectList.puser_ID)>
				<td valign="top" align="right"></td>
				<td align="right">#user_totalpoints#</td>
				<td align="center"><a href="#CurrentPage#?pgfn=points&puser_ID=#SelectList.puser_ID#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#">+/-</a></td>
			<cfelse>
				<td valign="top" align="right"><span class="sub">#is_done#</span></td>
			</cfif>
			</tr>
		</cfoutput>
	</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<cfquery name="SelectProgramInfo" datasource="#application.DS#">
		SELECT company_name, is_one_item, can_defer
		FROM #application.database#.program
		WHERE ID=<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cfset is_one_item = SelectProgramInfo.is_one_item>
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Program User</span>
	<br /><br />
	<span class="pageinstructions">Username is the only required field.</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?#xxL#&xxT=#xxT#">Program User List</a> without making changes.</span>
	<br /><br />
	<cfif duplicateusername>
		<span class="alert">No duplicate usernames are allowed in a program.  Please enter a new username.</span>
		<br /><br />
	</cfif>
	</cfoutput>
	<cfif pgfn EQ "edit">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT username, fname, lname, nickname, email, phone, is_active, is_done, expiration_date, cc_max, defer_allowed, ship_address1, ship_address2, ship_city, ship_state,  ship_zip, bill_fname, bill_lname, bill_address1, bill_address2, bill_city, bill_state,  bill_zip
			FROM #application.database#.program_user
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">
			AND (is_active = 1 OR username not like '%|merged to user_id:%')
		</cfquery>
		<cfif TobeEdited.recordcount NEQ 1>
			<cfabort showerror="program user #puser_ID# is not editable.">
		</cfif>
		<cfset username = htmleditformat(ToBeEdited.username)>	
		<cfset fname = htmleditformat(ToBeEdited.fname)>
		<cfset lname = htmleditformat(ToBeEdited.lname)>
		<cfset nickname = htmleditformat(ToBeEdited.nickname)>
		<cfset email = htmleditformat(ToBeEdited.email)>
		<cfset phone = htmleditformat(ToBeEdited.phone)>
		<cfset is_active = htmleditformat(ToBeEdited.is_active)>
		<cfset is_done = htmleditformat(ToBeEdited.is_done)>
		<cfset expiration_date = htmleditformat(ToBeEdited.expiration_date)>
		<cfset cc_max = htmleditformat(ToBeEdited.cc_max)>
		<cfset defer_allowed = htmleditformat(ToBeEdited.defer_allowed)>
		<cfset ship_address1 = htmleditformat(ToBeEdited.ship_address1)>
		<cfset ship_address2 = htmleditformat(ToBeEdited.ship_address2)>
		<cfset ship_city = htmleditformat(ToBeEdited.ship_city)>
		<cfset ship_state = htmleditformat(ToBeEdited.ship_state)>
		<cfset ship_zip = htmleditformat(ToBeEdited.ship_zip)>
		<cfset bill_fname = htmleditformat(ToBeEdited.bill_fname)>
		<cfset bill_lname = htmleditformat(ToBeEdited.bill_lname)>
		<cfset bill_address1 = htmleditformat(ToBeEdited.bill_address1)>
		<cfset bill_address2 = htmleditformat(ToBeEdited.bill_address2)>
		<cfset bill_city = htmleditformat(ToBeEdited.bill_city)>
		<cfset bill_state = htmleditformat(ToBeEdited.bill_state)>
		<cfset bill_zip = htmleditformat(ToBeEdited.bill_zip)>
	</cfif>
	<cfoutput>
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr class="content2">
	<td  colspan="2"><span class="headertext">Program: <span class="selecteditem">#request.program_name#</span></span></td>
	</tr>
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Program User</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Username: </td>
	<td valign="top"><input type="text" name="username" value="#username#" maxlength="16" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">First Name: </td>
	<td valign="top"><input type="text" name="fname" value="#fname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Last Name: </td>
	<td valign="top"><input type="text" name="lname" value="#lname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Nickname: </td>
	<td valign="top"><input type="text" name="nickname" value="#nickname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Email: </td>
	<td valign="top"><input type="text" name="email" value="#email#" maxlength="128" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Phone: </td>
	<td valign="top"><input type="text" name="phone" value="#phone#" maxlength="20" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Must use award amount before: </td>
	<td valign="top"><input type="text" name="expiration_date" value="<cfif expiration_date NEQ "">#FLGen_DateTimeToDisplay(expiration_date)#</cfif>" maxlength="12" size="15"> Please use date format, ex. 10/05/2005.</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Active: </td>
	<td valign="top">
		<select name="is_active">
			<option value="1"<cfif is_active EQ 1> selected</cfif>>yes</option>
			<option value="0"<cfif is_active EQ 0> selected</cfif>>no</option>
		</select>
	</td>
	</tr>
	<cfif is_one_item GT 0>
		<tr class="content">
		<td align="right" valign="top">Has ordered #is_one_item# item<cfif is_one_item NEQ 1>s</cfif>?: </td>
		<td valign="top">
			<select name="is_done">
				<option value="0"<cfif is_done EQ 0> selected</cfif>>no</option>
				<option value="1"<cfif is_done EQ 1> selected</cfif>>yes</option>
			</select>
		</td>
		</tr>
	<cfelse>
		<input type="hidden" name="is_done" value="0">
	</cfif>	
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6">Shipping Address</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Address Line 1: </td>
	<td valign="top"><input type="text" name="ship_address1" value="#ship_address1#" maxlength="64" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Address Line 2: </td>
	<td valign="top"><input type="text" name="ship_address2" value="#ship_address2#" maxlength="64" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">City State Zip: </td>
	<td valign="top">
		<input type="text" name="ship_city" value="#ship_city#" maxlength="30" size="30">
		&nbsp;&nbsp;&nbsp;&nbsp;
		State: <cfoutput>#FLGen_SelectState("ship_state",ship_state)#</cfoutput>
		&nbsp;&nbsp;&nbsp;&nbsp;
		Zip: <input type="text" name="ship_zip" value="#ship_zip#" maxlength="10" size="10">
	</td>
	</tr>
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6">Billing Address</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">First Name: </td>
	<td valign="top"><input type="text" name="bill_fname" value="#bill_fname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Last Name: </td>
	<td valign="top"><input type="text" name="bill_lname" value="#bill_lname#" maxlength="30" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Address Line 1: </td>
	<td valign="top"><input type="text" name="bill_address1" value="#bill_address1#" maxlength="64" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">Address Line 2: </td>
	<td valign="top"><input type="text" name="bill_address2" value="#bill_address2#" maxlength="64" size="40"></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">City State Zip: </td>
	<td valign="top">
		<input type="text" name="bill_city" value="#bill_city#" maxlength="30" size="30">
		&nbsp;&nbsp;&nbsp;&nbsp;
		State: <cfoutput>#FLGen_SelectState("bill_state",bill_state)#</cfoutput>
		&nbsp;&nbsp;&nbsp;&nbsp;
		Zip: <input type="text" name="bill_zip" value="#bill_zip#" maxlength="10" size="10">
	</td>
	</tr>
	<tr class="content">
	<td colspan="2" align="center">
	<input type="hidden" name="xxS" value="#xxS#">
	<input type="hidden" name="xxL" value="#xxL#">
	<input type="hidden" name="xxT" value="#xxT#">
	<input type="hidden" name="xOnPage" value="#xOnPage#">
	<input type="hidden" name="pgfn" value="#pgfn#">
	<input type="hidden" name="puser_ID" value="#puser_ID#">
	<input type="hidden" name="username_required" value="Please enter a username.">
	<input type="submit" name="submit" value="   Save Changes  " ><cfif pgfn EQ "add">&nbsp;&nbsp;&nbsp;<input type="submit" name="submit" value=" Save and go to Add Points page " ></cfif>
	</td>
	</tr>
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn ADD/EDIT --->
<cfelseif pgfn EQ "points">
	<!--- START pgfn POINTS --->
	<cfquery name="SelectProgramInfo" datasource="#application.DS#">
		SELECT points_multiplier, can_defer  
		FROM #application.database#.program
		WHERE ID=<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#">
	</cfquery>
	<cfset points_multiplier = SelectProgramInfo.points_multiplier>
	<!--- Get User Info IF PASSED --->
	<!--- run query --->
	<cfif puser_ID NEQ "">
		<cfquery name="SelectUserInfo" datasource="#application.DS#">
			SELECT IFNULL(fname,"-") AS fname, IFNULL(lname,"-") AS lname, is_active
			FROM #application.database#.program_user
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">
			AND (is_active = 1 OR username not like '%|merged to user_id:%')
		</cfquery>
		<cfif SelectUserInfo.recordcount NEQ 1>
			<cfabort showerror="program user #puser_ID# is not editable.">
		</cfif>
		<cfset fname = HTMLEditFormat(SelectUserInfo.fname)>
		<cfset lname = HTMLEditFormat(SelectUserInfo.lname)>
		<!--- CALCULATE USER'S POINTS --->
		<!--- look in the points database for the starting point amount --->
		<cfquery name="PosPoints" datasource="#application.DS#">
			SELECT IFNULL(SUM(points),0) AS pos_pt
			FROM #application.database#.awards_points
			WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">
		</cfquery>
		<!--- look in the order database for orders/points_used --->
		<cfquery name="NegPoints" datasource="#application.DS#">
			SELECT IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) AS neg_pt
			FROM #application.database#.order_info
			WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">
		</cfquery>
		<cfset user_total = PosPoints.pos_pt - NegPoints.neg_pt>
	<cfelse>
		<cfset fname = "">
		<cfset lname = "">
		<cfset user_total = "">
	</cfif>
	<cfoutput>
	<span class="pagetitle">Award Points for #fname# #lname#</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?xOnPage=#xOnPage#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#">Program User List</a></span>
	<br /><br />
	<!--- TODO:  Get the following to work with divisions.  See program_points.cfm --->
	<cfif NOT request.has_divisions>
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr class="content2">
	<td  colspan="3"><span class="headertext">Program: <span class="selecteditem">#request.program_name#</span></span></td>
	</tr>
	<cfif points_multiplier NEQ 1>
		<tr class="content2">
		<td  colspan="3"><span class="alert">NOTE:</span> Points will be multiplied by #points_multiplier# when displayed to the user.<br><br> For example, if a user has 10 points on this page, they will be told they have #NumberFormat(points_multiplier * 10,Application.NumFormat)# points when they are shopping.</td>
		</tr>
	</cfif>
	<cfif puser_ID NEQ "">
		<tr class="content2">
		<td  colspan="3"><span class="headertext">User: <span class="selecteditem">#fname# #lname#</span></span></td>
		</tr>
	</cfif>
	<tr class="contenthead">
	<td colspan="3" class="headertext">Award Points</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">
		<select name="addsub" size="2">
			<option value="add" selected>add (+)</option>
			<option value="sub">sub (-)</option>
		</select>
	</td>
	<td align="center"><input type="text" name="point_amount" maxlength="8" size="5">
	<input type="hidden" name="point_amount_required" value="Please enter a number of points to add or subtract."></td>
	<td align="center">points for <cfif #puser_ID# NEQ "">#fname# #lname#<cfelse>all users in this program</cfif></td>
	</tr>
	<tr class="content">
	<td colspan="3" align="center">optional note:<br><textarea name="note" cols="40" rows="3"></textarea></td>
	</tr>
	<tr class="content">
	<td colspan="3" align="center">
	<input type="hidden" name="xxS" value="#xxS#">
	<input type="hidden" name="xxL" value="#xxL#">
	<input type="hidden" name="xxT" value="#xxT#">
	<input type="hidden" name="xOnPage" value="#xOnPage#">
	<input type="hidden" name="puser_ID" value="#puser_ID#">
	<input type="submit" name="submit" value="   Save Changes   " >
	</td>
	</tr>
	</table>
	</form>
	</cfif>
	</cfoutput>
	<cfif puser_ID NEQ "">
		<cfquery name="GetPointHistory" datasource="#application.DS#">
			SELECT p.created_datetime, p.created_user_ID, p.points AS thispoints, IFNULL(p.notes,'(no note)') AS thisnote, 000 AS order_number, IF(p.is_defered = 1, 'true', 'false') AS thisdef, p.ID AS point_ID , p.division_ID, d.program_name AS division_name
			FROM #application.database#.awards_points p
			LEFT JOIN #application.database#.program d ON d.ID = p.division_ID
			WHERE p.user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">

			UNION
			
			SELECT created_datetime, created_user_ID, ((points_used * credit_multiplier)/points_multiplier) AS thispoints, '' AS thisnote, order_number AS order_number, 'false' AS thisdef, 444 AS point_ID, 0 AS division_ID, '' AS division_name
			FROM #application.database#.order_info
			WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">
				AND is_valid = 1
			ORDER BY created_datetime
		</cfquery>
		<br>
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr class="contenthead">
		<td class="headertext">Date&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
		<td class="headertext">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Points</td>
		<cfif request.has_divisions>
			<td class="headertext">Division&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
		</cfif>
		<cfif FLGen_HasAdminAccess(1000000047)>
			<td class="headertext" align="center"><span class="tooltip" title="Click the X to remove that line item.">?</span></td>
		</cfif>
		<td class="headertext" width="100%">Order Number/Inventory Note</td>
		</tr>
		<cfoutput query="GetPointHistory">
		<tr class="content">
		<td>#FLGen_DateTimeToDisplay(created_datetime)#</td>
		<td align="right"><cfif thisdef><span class="sub">[defered]</span></cfif><cfif order_number NEQ 000>-</cfif> #thispoints#</td>
		<cfif request.has_divisions>
			<td>#division_name#</td>
		</cfif>
		<cfif FLGen_HasAdminAccess(1000000047)>
		<td class="headertext" align="center"><cfif point_ID NEQ '444'><a href="#CurrentPage#?delete=#point_ID#&puser_ID=#puser_ID#&xOnPage=#xOnPage#&xxS=#xxS#&xxL=#xxL#&xxT=#xxT#" onclick="return confirm('Are you sure you want to delete this line item?  There is NO UNDO.')">X</a><cfelse>&nbsp;</cfif></td>
		</cfif>
		<td><cfif order_number NEQ 000>Order Number: #order_number#<cfelse><cfif thisnote CONTAINS "Imported from www2">Merged from old website<cfelse>#thisnote#</cfif> <span class="sub">Entered by #FLGen_GetAdminName(created_user_ID)#</span></cfif></td>
		</tr>
		</cfoutput>
		<cfset ProgramUserInfo(puser_ID)>
		<cfoutput>
		<tr class="content">
		<td align="right" class="headertext" colspan="2">#user_totalpoints#</td>
		<cfif FLGen_HasAdminAccess(1000000047)>
		<td class="headertext">&nbsp;</td>
		</cfif>
		<td class="headertext">TOTAL POINTS</td>
		<cfif request.has_divisions>
			<td class="headertext"></td>
		</cfif>
		</tr>
		<cfif SelectProgramInfo.can_defer>
		<tr class="content">
		<td align="right" colspan="2"><span class="sub">#user_deferedpoints#</span></td>
		<cfif FLGen_HasAdminAccess(1000000047)>
		<td class="headertext">&nbsp;</td>
		</cfif>
		<td><span class="sub">Deferred Points</span></td>
		<cfif request.has_divisions>
			<td class="headertext"></td>
		</cfif>
		</tr>
		</cfif>		
		</cfoutput>
		</table>
	</cfif>
</cfif>

</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->