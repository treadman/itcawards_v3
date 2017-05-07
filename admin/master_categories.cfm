<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000015,true)>

<cfparam name="where_string" default="">
<cfparam name="ID" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="sortorder">
<cfparam name="xT" default="">
<cfparam name="xL" default="">

<!--- param a/e form fields --->
<cfparam name="ID" default="">	
<cfparam name="productvalue" default="">
<cfparam name="sortorder" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>

	<!--- update --->
	<cfif form.ID IS NOT "">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.productvalue_master
			SET	productvalue = <cfqueryparam value="#form.productvalue#" cfsqltype="cf_sql_integer" maxlength="10">,
				sortorder = <cfqueryparam value="#form.sortorder#" cfsqltype="cf_sql_integer" maxlength="5">				
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelse>
		<cflock name="productvalue_masterLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.productvalue_master
						(created_user_ID, created_datetime, productvalue, sortorder)
					VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam value="#form.productvalue#" cfsqltype="cf_sql_integer" maxlength="10">,
						<cfqueryparam value="#form.sortorder#" cfsqltype="cf_sql_integer" maxlength="5">)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.productvalue_master
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

<cfset leftnavon = "master_categories">
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

<cfparam  name="pgfn" default="list">

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">
	<!--- Set the WHERE clause --->
	<!--- First check if a search string passed --->
	<cfif LEN(xT) GT 0>
		<cfset xL = "">
	</cfif>
	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ID, productvalue, sortorder
		FROM #application.database#.productvalue_master
		<cfif LEN(xT) GT 0>
			WHERE productvalue LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">
		<cfelseif LEN(xL) GT 0>
			WHERE productvalue LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xL#%" maxlength="3">
		</cfif>
		ORDER BY sortorder ASC
	</cfquery>
	<!--- set the start/end/max display row numbers --->
	<cfparam name="OnPage" default="1">
	<cfset MaxRows_SelectList="20">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	<span class="pagetitle">Master Category List</span>
	<br /><br />
	<span class="pageinstructions">The sort order below is only used to display the categories on this page.</span>
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
			<input type="hidden" name="xL" value="#xL#">
			<input type="hidden" name="xS" value="#xS#">
			<input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20">
			<input type="submit" name="search" value="search Product Value">
		</form>
		</cfoutput>
		<br>		
		<cfoutput><cfif LEN(xL) IS 0><span class="ltrON">ALL</span><cfelse><a href="#CurrentPage#?xL=" class="ltr">ALL</a></cfif></cfoutput><span class="ltrPIPE">&nbsp;&nbsp;</span><cfloop index = "LoopCount" from = "0" to = "9"><cfoutput><cfif xL IS LoopCount><span class="ltrON">#LoopCount#</span><cfelse><a href="#CurrentPage#?xL=#LoopCount#" class="ltr">#LoopCount#</a></cfif></cfoutput><span class="ltrPIPE">&nbsp;&nbsp;</span></cfloop><cfloop index = "LoopCount" from = "1" to = "26"><cfoutput><cfif xL IS CHR(LoopCount + 64)><span class="ltrON">#CHR(LoopCount + 64)#</span><cfelse><a href="#CurrentPage#?xL=#CHR(LoopCount + 64)#" class="ltr">#CHR(LoopCount + 64)#</a></cfif></cfoutput><cfif LoopCount NEQ 26><span class="ltrPIPE">&nbsp;&nbsp;</span></cfif></cfloop>
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
						</select> of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
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
			<td><span class="headertext">Sort&nbsp;Order</span>&nbsp;<img src="../pics/contrls-asc.gif" width="7" height="6"></td>
			<td width="100%"><span class="headertext">Product Value</span></td>
		</tr>
		</cfoutput>
		<!--- if no records --->
		<cfif SelectList.RecordCount IS 0>
			<tr class="content2">
				<td colspan="3" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
			</tr>
		<cfelse>
			<!--- display found records --->
			<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
				<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
				<td align="center"><a href="#CurrentPage#?pgfn=edit&id=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Edit</a></td>
				<td valign="top" align="center">#htmleditformat(sortorder)#</td>
				<td valign="top">#htmleditformat(productvalue)#</td>
				</tr>
			</cfoutput>
		</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Master Category</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Master Category List</a> without making changes.</span>
	<br /><br />
	<cfif isDefined("form.submit")>
		<span class="pageinstructions"><a href="#CurrentPage#?pgfn=add&&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Add</a> a new Master Category.</span>
		<br /><br />
	</cfif>
	</cfoutput>
	<cfif pgfn EQ "edit">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, productvalue, sortorder
			FROM #application.database#.productvalue_master
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
		<cfset ID = ToBeEdited.ID>
		<cfset productvalue = htmleditformat(ToBeEdited.productvalue)>
		<cfset sortorder = htmleditformat(ToBeEdited.sortorder)>
	</cfif>
	<cfoutput>
	<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0">

	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Vendor</td>
	</tr>

	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="bottom"><img src="../pics/contrls-desc.gif" width="7" height="6"> Product Value is a number cooresponding to the price.</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Product Value: </td>
	<td valign="top"><input type="text" name="productvalue" value="#productvalue#" maxlength="10" size="40"></td>
	</tr>
	
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="bottom"><img src="../pics/contrls-desc.gif" width="7" height="6"> Sort order is only used on the Master Category List page.</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Sort Order: </td>
	<td valign="top"><input type="text" name="sortorder" value="#sortorder#" maxlength="5" size="6"></td>
	</tr>
						
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="xS" value="#xS#">
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	<input type="hidden" name="ID" value="#ID#">
	
	<input type="hidden" name="productvalue_required" value="Please enter a display name.">
	<input type="hidden" name="sortorder_required" value="Please enter a sort order.">
		
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