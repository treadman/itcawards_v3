<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000011,true)>

<cfparam name="where_string" default="">
<cfparam name="ID" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="manuf_name">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="OnPage" default="1">

<!--- param a/e form fields --->
<cfparam name="manuf_name" default="">	
<cfparam name="logoname" default="">
<cfparam name="imagename" default="">
<cfparam name="imagename_original" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- update --->
	<cfif form.ID IS NOT "">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.manuf_logo
			SET	manuf_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#manuf_name#" maxlength="20">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelse>
		<cflock name="manuf_logoLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.manuf_logo
						(created_user_ID, created_datetime, manuf_name)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#',
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#manuf_name#" maxlength="20">
					)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.manuf_logo
				</cfquery>
				<cfset ID = getID.MaxID>
			</cftransaction>  
		</cflock>
	</cfif>
	<!--- upload image, name is #meta_ID#_image.ext --->
	<cfif form.logoname_original IS NOT "">
		<cfset images = #FLGen_UploadThis("logoname_original","pics/manuf_logos/",ID & "_manuflogo")#>
<!--- 	<cfparam name="ScratchPath" default="/inetpub/wwwroot/scratch/">
		<cffile action="UPLOAD" destination="#ScratchPath#" nameconflict="OVERWRITE" FILEFIELD="#form.logoname_original#">
 --->		<cfset logoname_original = ListGetAt(images,1,",")>
		<cfset logoname = ListGetAt(images,2,",")>
	
		<!--- update this field in the database --->
		<cfquery name="UpdateQueryLogo" datasource="#application.DS#">
			UPDATE #application.database#.manuf_logo
			SET	logoname_original = <cfqueryparam cfsqltype="cf_sql_varchar" value="#logoname_original#" maxlength="64">,
				logoname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#logoname#" maxlength="64">
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
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

<cfset leftnavon = "manuflogos">
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

	<!--- Set the WHERE clause --->
	<!--- First check if a search string passed --->
	<cfif LEN(xT) GT 0>
		<cfset xL = "">
	</cfif>
	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ID, manuf_name, logoname, logoname_original
		FROM #application.database#.manuf_logo
		<cfif LEN(xT) GT 0>
			WHERE manuf_name LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">
		<cfelseif LEN(xL) GT 0>
			WHERE manuf_name LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xL#%">
		</cfif>
		ORDER BY manuf_name ASC
	</cfquery>
	<!--- set the start/end/max display row numbers --->
	<cfparam name="OnPage" default="1">
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	<span class="pagetitle">Manufacturer's Logo List</span>
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
		<td><span class="headertext">Logo</span></td>
		<td>
				<span class="headertext">Manufacturer</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		</td>
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
				<td valign="top"><cfif logoname NEQ ""><a href="../pics/manuf_logos/#htmleditformat(logoname)#" target="_blank">#htmleditformat(logoname_original)#</a><cfelse>(none)</cfif></td>
				<td valign="top">#htmleditformat(manuf_name)#</td>
				</tr>
			</cfoutput>
		</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Manufacturer's Logo</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Manufacturer's Logo List</a> without making changes.</span>
	<br /><br />
	</cfoutput>
	<cfif pgfn EQ "edit">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, manuf_name, logoname_original, logoname
			FROM #application.database#.manuf_logo
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
		<cfset ID = ToBeEdited.ID>
		<cfset manuf_name = htmleditformat(ToBeEdited.manuf_name)>
		<cfset logoname_original = htmleditformat(ToBeEdited.logoname_original)>
		<cfset logoname = htmleditformat(ToBeEdited.logoname)>
	</cfif>
	<cfoutput>
	<form method="post" action="#CurrentPage#" enctype="multipart/form-data">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Vendor</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Manufacturer's Name: </td>
	<td valign="top"><input type="text" name="manuf_name" value="#manuf_name#" maxlength="38" size="40"></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Manufacturer's Logo: </td>
	<td valign="top"><input name="logoname_original" type="FILE" value=""><cfif logoname NEQ "">&nbsp;&nbsp;&nbsp;&nbsp;current image: <a href="../pics/products/#HTMLEditFormat(imagename)#" target="_blank">#htmleditformat(imagename_original)#</a></cfif></td>
	</tr>
				
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	<input type="hidden" name="ID" value="#ID#">
	<input type="hidden" name="manuf_name_required" value="Please enter a Manufacturer's Name.">
		
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