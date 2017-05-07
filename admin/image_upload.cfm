<!--- function library --->
<cfinclude template="/cfscripts/dfm_common/function_library_form.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000014-1000000020-1000000088",true)>

<cfparam name="delete" default="">

<!--- param search criteria xxS=ColumnSort xxT=SearchString xxL=Letter --->
<cfparam name="cri_T" default="">
<cfparam name="OnPage" default="1">

<!--- param a/e form fields --->
<cfparam name="ID" default="">	
<cfparam name="imagename" default="">	
<cfparam name="imgename_original" default="">
<cfparam name="admin_title" default="">

<cfparam name="pgfn" default="list">

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- add  --->
	<cfif pgfn EQ "add">
		<cflock name="image_contentLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.image_content
						(created_user_ID, created_datetime, admin_title)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						#FLGen_DateTimeToMySQL()#, 
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.admin_title#" maxlength="30">
					)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID 
					FROM #application.database#.image_content
				</cfquery>
				<cfset ID = getID.MaxID>
			</cftransaction>  
		</cflock>
		<cfset pgfn = "edit">
	<!--- edit --->
	<cfelseif pgfn EQ "edit" AND ID IS NOT "">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.image_content
			SET	admin_title = <cfqueryparam cfsqltype="cf_sql_varchar" value="#form.admin_title#" maxlength="30">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">
		</cfquery>
		<cfset pgfn = "list">
	</cfif>

	<!--- FOR ASSIGN XREF - delete all assigned groups --->
	<cfquery name="DeleteAssignedXrefs" datasource="#application.DS#">
		DELETE FROM #application.database#.xref_image_program
		WHERE image_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#">
	</cfquery>
	<!--- FOR ASSIGN XREF - Save xrefs --->
	<cfif IsDefined('form.assign_xref') AND form.assign_xref IS NOT "">
		<cfloop list="#form.assign_xref#" index="i">
			<cfquery name="InsertTheseXref" datasource="#application.DS#">
				INSERT INTO #application.database#.xref_image_program
				(created_user_ID, created_datetime, image_ID, program_ID)
				VALUES (
				<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
				#FLGen_DateTimeToMySQL()#, 
				<cfqueryparam cfsqltype="cf_sql_integer" value="#ID#" maxlength="10">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#i#" maxlength="10">
				)
			</cfquery>
		</cfloop>
	</cfif>
	
	<!--- UPLOAD IMAGE --->
	<cfif IsDefined('form.imagename_original') AND TRIM(form.imagename_original) IS NOT "">
		<cfset firstone = FLGen_UploadThis("imagename_original","pics/uploaded_images/",ID & "_image")>
		<cfset results = FLGen_UploadThis("imagename_original","pics/program/",ID & "_image")>
		<cfset original = ListGetAt(results,1,",")>
		<cfset image = ListGetAt(results,2,",")>
		<cfquery name="UpdateImage" datasource="#application.DS#">
			UPDATE #application.database#.image_content SET
				imagename_original = <cfqueryparam cfsqltype="cf_sql_varchar" value="#original#" maxlength="128">,
				imagename = <cfqueryparam cfsqltype="cf_sql_varchar" value="#image#" maxlength="128">
				#FLGen_UpdateModConcatSQL()#
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
	</cfif>
	
	<!--- UPLOAD TO program logo folder, if logo --->
	<cfif isDefined("form.logo")>
		<cfif form.pgfn EQ 'add'>
			<cfset results = FLGen_UploadThis("imagename_original","pics/program/",ID & "_image")>
		<cfelse>
			<!--- ALERT MSG if the image doesn't exist in the program logo file already --->
			<cfif  IsDefined('form.imagename') AND form.imagename NEQ "" AND Not FileExists(application.AbsPath & "pics/program/" & form.imagename)>
				<cfset alert_error = "IMPORTANT: Please upload this image again if you want to use it as an Award Program Logo.">
				<cfset pgfn = "edit">
			</cfif>
		</cfif>
	</cfif>

	<!--- delete all js files --->
	<cflock name="CLock" type="readonly" timeout="30">
		<cfdirectory action="list" directory="#application.AbsPath#admin/image_lists/" name="ThisList" filter="*.*" sort="Type ASC, Name ASC">
	</cflock>	
	<cfoutput query="ThisList">
		<cfset FLGen_DeleteThisFile(Name,"admin/image_lists/")>
	</cfoutput>
	
	<!--- find the programs that should have a js file --->
	<cfquery name="SelectPrograms" datasource="#application.DS#">
		SELECT DISTINCT program_ID AS list_program_ID
		FROM #application.database#.xref_image_program
		ORDER BY program_ID
	</cfquery>
	
	<!--- create a js file for each image type within each program --->
	<cfloop query="SelectPrograms">
		<cfset list_program_ID = SelectPrograms.list_program_ID>
	</cfloop>
	
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "image_upload">
<cfinclude template="includes/header.cfm">

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT ID, imagename, imagename_original, admin_title 
		FROM #application.database#.image_content
		WHERE 1 = 1
		<cfif has_program>
			AND (Select COUNT(ip.ID) FROM #application.database#.xref_image_program ip WHERE ip.image_ID = image_content.ID AND ip.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#">) > 0
		</cfif>
		<cfif LEN(cri_T) GT 0>
			AND (admin_title LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#cri_T#%"> 
				OR imagename_original LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#cri_T#%">)
		</cfif>
		ORDER BY admin_title ASC
	</cfquery>

	<!--- set the start/end/max display row numbers --->
	<cfset MaxRows_SelectList="25">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>

	<!--- find all programs --->
	<cfquery name="SelectPrograms" datasource="#application.DS#">
		SELECT ID, company_name, program_name 
		FROM #application.database#.program 
		WHERE parent_ID = 0
		ORDER BY company_name, program_name ASC
	</cfquery>

	<span class="pagetitle"><cfif NOT has_program>All </cfif>Content Images<cfif has_program> for <cfoutput>#request.program_name#</cfoutput></cfif> </span>
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
			<input type="text" name="cri_T" value="#cri_T#" size="20">
			<input type="submit" name="search" value="search">
		</form>
		</cfoutput>
		<br>		
	</td>
	</tr>
	
	</table>
	
	<br />
	
	<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr>
	<td>
		<cfif OnPage GT 1>
			<a href="<cfoutput>#CurrentPage#?OnPage=1&cri_T=#cri_T#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&cri_T=#cri_T#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
		</cfif>
	</td>
	<td align="center" class="sub"><cfoutput>[ page displayed: #OnPage# of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records displayed: #StartRow_SelectList# - #EndRow_SelectList# ]&nbsp;&nbsp;&nbsp;[ total records: #SelectList.RecordCount# ]</cfoutput></td>
	<td align="right">
		<cfif OnPage LT TotalPages_SelectList>
			<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&cri_T=#cri_T#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&cri_T=#cri_T#</cfoutput>" class="pagingcontrols">&raquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
		</cfif>
	</td>
	</tr>
	</table>
	
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<!--- header row --->
	<cfoutput>	
	<tr class="contenthead">
	<td align="center"><a href="#CurrentPage#?pgfn=add&cri_T=#cri_T#&OnPage=#OnPage#">Add</a></td>
	<td><span class="headertext">Admin&nbsp;Title</span>&nbsp;<img src="../pics/contrls-asc.gif" width="7" height="6"></td>
	<td><span class="headertext">Image Name</span></td>
	<td><span class="headertext">Preview</span></td>
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
		<tr class="content<cfif (CurrentRow MOD 2) EQ 0>2</cfif>">
		<td valign="top"><a href="#CurrentPage#?pgfn=edit&id=#ID#&cri_T=#cri_T#&OnPage=#OnPage#">Edit</a></td>
		<td valign="top">#HTMLEditFormat(admin_title)#</td>
		<td valign="top">#HTMLEditFormat(imagename_original)#</td>
		<td valign="top"><a href="/pics/uploaded_images/#HTMLEditFormat(imagename)#" target="_blank">preview image</a></td>
		</tr>
	</cfoutput>

	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit">
	<!--- START pgfn ADD/EDIT --->
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Content Image</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="#CurrentPage#?cri_T=#cri_T#&OnPage=#OnPage#">Content Image List</a> without making changes.</span>
	<br /><br />
	</cfoutput>
	<cfif pgfn EQ "edit">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT imagename, imagename_original, admin_title 
			FROM #application.database#.image_content
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ID#">
		</cfquery>
		<cfset imagename = htmleditformat(ToBeEdited.imagename)>	
		<cfset imagename_original = htmleditformat(ToBeEdited.imagename_original)>
		<cfset admin_title = htmleditformat(ToBeEdited.admin_title)>
	
		<!--- FOR ASSIGN XREF --->
		<cfquery name="FindThisItemsXrefs" datasource="#application.DS#">
			SELECT program_ID AS this_xref_ID
			FROM #application.database#.xref_image_program
			WHERE image_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#">
		</cfquery>
		<cfset this_items_xrefs = ValueList(FindThisItemsXrefs.this_xref_ID)>
	
		<!--- END XREF --->
	<cfelse>
		<cfset this_items_xrefs = "">
	</cfif>
	<cfoutput>
	<form method="post" action="#CurrentPage#" enctype="multipart/form-data">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add">Add<cfelse>Edit</cfif> a Program User</td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Admin Title: </td>
	<td valign="top"><input type="text" name="admin_title" value="#admin_title#" maxlength="30" size="40"></td>
	</tr>
	
	<!--- FOR IMAGE UPLOAD --->		
	<tr class="content">
	<td align="right" valign="top" nowrap="nowrap">Image: </td>
	<td valign="top"><input name="imagename_original" type="file" size="40"><cfif imagename NEQ "">&nbsp;&nbsp;&nbsp;<a href="/pics/uploaded_images/#imagename#" target="_blank">[ preview image ]</a>
	<input type="hidden" name="imagename" value="#imagename#"><cfelse><input type="hidden" name="imagename_original_required" value="Please upload an image."></cfif></td>
	</tr>	
	<!--- END IMAGE UPLOAD --->		
	
	<!--- FOR ASSIGN XREF -  --->
	<cfquery name="SelectAllXrefItems" datasource="#application.DS#">
		SELECT ID AS this_xitem_ID, CONCAT(company_name,' [',program_name,']') AS checkbox_text 
		FROM #application.database#.program
		WHERE parent_ID = 0
		ORDER BY company_name, program_name ASC 
	</cfquery>

	<tr class="content">
	<td valign="top" colspan="2">Award Programs that can access this image:<br><br>
	
		<cfset total_records = SelectAllXrefItems.RecordCount>
		<cfset endrow_1 = total_records \ 2 + (total_records MOD 2)>
		<cfset startrow_2 = endrow_1 + 1>
	
		<table width="90%" align="right">
		
		<tr>
		<td valign="top">
		<cfloop query="SelectAllXrefItems" startrow="1" endrow="#endrow_1#">
			<input type="checkbox" name="assign_xref" value="#this_xitem_ID#" #FLForm_Selected(this_items_xrefs,this_xitem_ID)#> <span class="<cfif IIF(FLForm_Selected(this_items_xrefs,this_xitem_ID,"yes") EQ "yes",DE(true),DE(false))>selecteditem<cfelse>reg</cfif>">#checkbox_text#</span><br>
		</cfloop>		</td>
		<td valign="top">
		<cfloop query="SelectAllXrefItems" startrow="#startrow_2#" endrow="#total_records#">
			<input type="checkbox" name="assign_xref" value="#this_xitem_ID#" #FLForm_Selected(this_items_xrefs,this_xitem_ID)#> <span class="<cfif IIF(FLForm_Selected(this_items_xrefs,this_xitem_ID,"yes") EQ "yes",DE(true),DE(false))>selecteditem<cfelse>reg</cfif>">#checkbox_text#</span><br>
		</cfloop>		</td>
		</tr>
		</table>	</td>
	</tr>

	<!--- END XREF --->
	
	
	<tr class="content">
	<td colspan="2" align="center">

	<!--- This page's variables --->	
	<input type="hidden" name="cri_T" value="#cri_T#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	<input type="hidden" name="pgfn" value="#pgfn#">
	
	<input type="hidden" name="ID" value="#ID#">
	
	<input type="hidden" name="admin_title_required" value="Please enter an admin title.">
		
	<input type="submit" name="submit" value="   Save Changes   " ></td>
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