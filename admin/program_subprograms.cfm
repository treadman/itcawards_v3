<!--- Verify that a program was selected --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cflocation url="program_list.cfm" addtoken="no">
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfparam name="ID" default="">
<cfparam name="delete" default="">

<!--- form fields --->
<cfparam name="subprogram_name" default="">
<cfparam name="is_active" default="1">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfif pgfn EQ "add">
		<cflock name="subprogramLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.subprogram
						(created_user_ID, created_datetime, program_ID, subprogram_name, is_active, sortorder)
					VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#">,
						 '#FLGen_DateTimeToMySQL()#',
						  <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">,
						  <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.subprogram_name#" maxlength="40">, 
						  <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_active#">,
						  0)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.subprogram
				</cfquery>
				<cfset ID = getID.MaxID>
			</cftransaction>  
		</cflock>
		<cfset pgfn = "list">
	<cfelseif pgfn EQ "edit" AND form.ID IS NOT "">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.subprogram
			SET	subprogram_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.subprogram_name#" maxlength="40">,
				is_active = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#form.is_active#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.ID#" maxlength="10">
		</cfquery>
		<cfset pgfn = "list">
	</cfif>
<cfelseif CGI.REQUEST_METHOD EQ "post" AND IsDefined('form.itemstosort') AND form.itemstosort NEQ "">
	<cfloop index="i" from="1" to="#ListLen(form.itemstosort)#">
			<cfquery name="UpdateQueryorderall" datasource="#application.DS#">
				UPDATE #application.database#.subprogram
				SET	sortorder = <cfqueryparam cfsqltype="cf_sql_integer" value="#i#" maxlength="5">
					#FLGen_UpdateModConcatSQL()#
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListGetAt(form.itemstosort,i)#" maxlength="10">
			</cfquery>
	</cfloop>
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000051)>
	<cfquery name="DeleteThis" datasource="#application.DS#">
		DELETE FROM #application.database#.subprogram
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>			
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<script language="JavaScript">
function Submit()
{

 f = document.forms[0]

 if (document.all) // IE only
 {
  SelectCode = document.getElementById("SelectSpan").innerHTML.replace(/^<select/i,"<select multiple ")
  document.getElementById("SelectSpan").innerHTML = SelectCode
 }

 else
 {
  f.ItemsToSort.multiple = true
 }

 for (i=0; i<f.ItemsToSort.options.length; i++)
 {f.ItemsToSort.options[i].selected = true}

 f.submit()

}


function MoveItem(Direction)
{

 FormInfo = document.forms[0].ItemsToSort

 if (FormInfo.selectedIndex == -1)
 {
 alert("Select an item.  Then use the arrows to change the display order.")
 return false
 }


 // Move Selection Up
 if (Direction == "up" && FormInfo.selectedIndex != 0)
 {

  i = FormInfo.selectedIndex - 1

  SavedValue = FormInfo.options[i].value
  SavedText = FormInfo.options[i].text

  FormInfo.options[i].value = FormInfo.options[FormInfo.selectedIndex].value
  FormInfo.options[i].text = FormInfo.options[FormInfo.selectedIndex].text

  FormInfo.options[FormInfo.selectedIndex].value = SavedValue
  FormInfo.options[FormInfo.selectedIndex].text = SavedText

  FormInfo.selectedIndex = i

 }


 // Move Selection Down
 if (Direction == "down" && FormInfo.selectedIndex != FormInfo.options.length - 1)
 {

  i = FormInfo.selectedIndex + 1

  SavedValue = FormInfo.options[i].value
  SavedText = FormInfo.options[i].text

  FormInfo.options[i].value = FormInfo.options[FormInfo.selectedIndex].value
  FormInfo.options[i].text = FormInfo.options[FormInfo.selectedIndex].text

  FormInfo.options[FormInfo.selectedIndex].value = SavedValue
  FormInfo.options[FormInfo.selectedIndex].text = SavedText

  FormInfo.selectedIndex = i

 }


 // Move Selection To Bottom
 if (Direction == "bottom" && FormInfo.selectedIndex != FormInfo.options.length - 1)
 {

  FormInfo.options[FormInfo.options.length] = new Option(FormInfo.options[FormInfo.selectedIndex].text ,FormInfo.options[FormInfo.selectedIndex].value )

  FormInfo.options[FormInfo.selectedIndex] = null

  FormInfo.selectedIndex = FormInfo.options.length - 1

 }


 // Move Selection To Top
 if (Direction == "top" && FormInfo.selectedIndex != 0)
 {

  for (i=FormInfo.selectedIndex; i>-1; i--)
  {MoveItem('up')}

 }

}
</script>

<cfparam  name="pgfn" default="list">

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ID, subprogram_name, is_active, sortorder
		FROM #application.database#.subprogram
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#">
		ORDER BY sortorder
	</cfquery>

	<cfoutput>
	<span class="pagetitle">Subprogram List for #request.program_name#</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="program_details.cfm">Award Program Details</a> or <a href="program_list.cfm">Award Program List</a> without making changes.</span>
	<br /><br />

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td><a href="#CurrentPage#?pgfn=add">Add</a></td>
	<td><cfif SelectList.RecordCount IS 0>&nbsp;<cfelse><a href="#CurrentPage#?pgfn=sort">Set&nbsp;Order</a></cfif></td>
	<td width="100%"><span class="headertext">Subprogram Name</span></td>
	</tr>
	</cfoutput>

	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="3" align="center"><span class="alert"><br>No subprograms found.  Click "add" enter a subprogram.<br><br></span></td>
		</tr>
	<cfelse>
		<cfoutput query="SelectList">

			<cfset show_delete = false>
			<cfif FLGen_HasAdminAccess(1000000051)>
				<cfquery name="FindLinks" datasource="#application.DS#">
					SELECT COUNT(ID) as thismany
					FROM #application.database#.subprogram_points
					WHERE subprogram_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#"> 
				</cfquery>
				<cfif FindLinks.thismany EQ 0>
					<cfset show_delete = true>
				</cfif>
			</cfif>
	
			<cfif is_active EQ 0>
				<cfset rowcolor = 'inactivebg'>
			<cfelseif (CurrentRow MOD 2) is 0>
				<cfset rowcolor = 'content2'>
			<cfelse>
				<cfset rowcolor = 'content'>
			</cfif>

			<tr class="#rowcolor#">
			<td nowrap><a href="#CurrentPage#?pgfn=edit&ID=#ID#">Edit</a>&nbsp;&nbsp;&nbsp;<cfif FLGen_HasAdminAccess(1000000051) and show_delete>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?delete=#ID#" onclick="return confirm('Are you sure you want to delete this subprogram?  There is NO UNDO.')">Delete</a></cfif></td>
			<td align="center">#HTMLEditFormat(sortorder)#</td>
			<td>#HTMLEditFormat(subprogram_name)#</td>
			</tr>
		</cfoutput>
	</cfif>
	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<cfif pgfn EQ "edit">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, subprogram_name, is_active
			FROM #application.database#.subprogram
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#">
		</cfquery>
		<cfset ID = ToBeEdited.ID>
		<cfset subprogram_name = htmleditformat(ToBeEdited.subprogram_name)>
		<cfset is_active = ToBeEdited.is_active>
	</cfif>
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Subprogram for #request.program_name#</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#">Subprogram List</a> or <a href="program_details.cfm">Award Program Details</a> or <a href="program_list.cfm">Award Program List</a> without making changes.</span>
	<br /><br />
	<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0">
	
	<tr class="contenthead">
	<td colspan="2"><span class="headertext"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Subprogram</span></td>
	</tr>
	
	<tr class="content">
	<td align="right">Is Active?: </td>
	<td>
		<table width="100%">
		<tr>
		<td valign="top">
		<select name="is_active" size="2">
			<option value="1"<cfif #is_active# EQ 1> selected</cfif>>Yes</option>
			<option value="0"<cfif #is_active# EQ 0> selected</cfif>>No</option>
		</select>
		</td>
		<td valign="top" style="padding-left:15px">If you make a subprogram inactive, it will no longer be an option on the user award points adjustment page, nor will it have a column on the subprogram billing report.</td>
		</tr>
		
		</table>
		
	</td>
	</tr>
	<tr class="content">
	<td align="right">Subprogram&nbsp;Name: </td>
	<td>
		<table width="100%">
		<tr>
		<td valign="top"><input type="text" name="subprogram_name" value="#subprogram_name#" maxlength="40" size="30"></td>
		<td valign="top" style="padding-left:15px"><span class="alert">IMPORTANT:</span>&nbsp;&nbsp;&nbsp;Choose the shortest possible subprogram name.</td>
		</tr>
		</table>
	</td>
	</tr>
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="ID" value="#ID#">
	<input type="hidden" name="pgfn" value="#pgfn#">
	
	<input type="hidden" name="subprogram_name_required" value="Please enter a subprogram name.">
		
	<input type="submit" name="submit" value="   Save Changes   " >

	</td>
	</tr>
		
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn ADD/EDIT --->
<cfelseif pgfn EQ "sort">
	<!--- START pgfn SORT --->
	<cfquery name="SelectToBeSorted" datasource="#application.DS#">
		SELECT ID AS sort_ID, subprogram_name, sortorder
		FROM #application.database#.subprogram
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">
		ORDER BY sortorder
	</cfquery>

	<!--- populate MetaArray with data --->
	<cfloop query="SelectToBeSorted">
		<cfset MetaArray[CurrentRow] = sort_ID>
	</cfloop>

	<cfoutput>
	<span class="pagetitle">Set Sort Order for Subprograms for #request.program_name#</span>
	<br /><br />

	<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%"> 
		
	<tr class="content">
	<td valign="top" rowspan="2">
	<span id="SelectSpan">
	<select name="ItemsToSort" ID="ItemsToSort" size="20" style="width:530px">
		<cfloop query="SelectToBeSorted">
			<option value="#sort_ID#">[#CurrentRow#] <cfif sortorder EQ 0>NO SORT &raquo; </cfif>#subprogram_name#</option>
		</cfloop>
	</select>
	</span>
	</td>
	<td valign="top">
	<a href="##" onClick="MoveItem('top');this.blur();return false" title="Move To Top"><img src="pics/MoveTop.gif" border="0" width="20" height="15"></a><br><br><br>
	<a href="##" onClick="MoveItem('up');this.blur();return false" title="Move Up"><img src="pics/MoveUp.gif" border="0" width="20" height="13"></a>
	</td>
	</tr>
	
	<tr class="content">
	<td valign="bottom">
		<a href="##" onClick="MoveItem('down');this.blur();return false" title="Move Down"><img src="pics/MoveDown.gif" border="0" width="20" height="13"></a><br><br><br>
		<a href="##" onClick="MoveItem('bottom');this.blur();return false" title="Move To Bottom"><img src="pics/MoveBottom.gif" border="0" width="20" height="15"></a>
	</td>
	</tr>
	</table>
	</form>
	</cfoutput>
	<!--- END pgfn SORT --->
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->