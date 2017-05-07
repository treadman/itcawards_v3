<cfsetting requesttimeout="300" showdebugoutput="no">
<cfparam name="form.folder" default="">
<cfparam name="form.fields" default="">
<cfparam name="form.keys" default="">

<cfparam name="form.delete" default="0">
<cfif NOT isBoolean(form.delete)>
	<cfset form.delete = 0>
</cfif>

<cfset alert_msg = "">

<cfinclude template="includes/header.cfm">

<table cellpadding="5" cellpadding="8" border="0" width="800">
<tr>
	<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
	<td>

<span class="pagetitle">Orphan Delete</span><br><br>
<span class="pageinstructions">
	Search and destroy orphaned files (images, pdfs, etc.) in a folder of files that are referenced in the database<br><br>
	<strong>Database:</strong> <cfoutput>#application.database#</cfoutput>
</span>
<br><br>

<cfif isDefined("form.submit")>
	<cfif form.fields EQ "">
		<cfset alert_msg = alert_msg & "<li>Please enter one or more fields to check.</li>">
	</cfif>
	<cfif form.keys EQ "">
		<cfset alert_msg = alert_msg & "<li>Please enter the primary keys of the tables to check.</li>">
	</cfif>
	<cfif ListLen(form.fields) NEQ ListLen(form.keys)>
		<cfset alert_msg = alert_msg & "<li>The list of fields must be the same length as the list of keys.</li>">
	</cfif>
	<cfif form.fields NEQ "">
		<cfloop list="#form.fields#" index="thisField">
			<cfif ListLen(thisField,".") NEQ 2>
				<cfset alert_msg = alert_msg & "<li>#thisField# is not in table.fieldname format.</li>">
			</cfif>
		</cfloop>
	</cfif>
	<cfset badQuery = false>
	<cfif alert_msg EQ "">
		<cfset DeletedCount = 0>
		<cfdirectory action="list" directory="#application.AbsPath##form.folder#" name="fileList">
		<cfoutput>#fileList.recordcount#</cfoutput> files found.<br><br>
		<cfloop query="fileList">
			<cfset deleteMe = true>
			<cfloop from="1" to="#ListLen(form.fields)#" index="thisPos">
				<cfset thisTableField = ListGetAt(form.fields,thisPos)>
				<cfset thisTable = ListGetAt(thisTableField,1,".")>
				<cfset thisField = ListGetAt(thisTableField,2,".")>
				<cfset thisKey = ListGetAt(form.keys,thisPos)>
				<cftry>
					<cfquery name="GetRecords" datasource="#application.DS#">
						SELECT #thisKey#
						FROM #application.database#.#thisTable#
						WHERE #thisField# = '#fileList.name#'
					</cfquery>
					<cfif GetRecords.recordcount GT 0>
						<cfset deleteMe = false>
						<cfbreak>
					</cfif>
					<cfcatch>
						<cfset badQuery = true>
						<span class="alert">There is a problem with the query.  The table name, key field or image field may be misspelled.</span>
						<cfbreak>
					</cfcatch>
				</cftry>
			</cfloop>
			<cfif badQuery>
				<cfbreak>
			</cfif>
			<cfif deleteMe>
				<cfset DeletedCount = DeletedCount + 1>
				<cfoutput>#fileList.name#</cfoutput> not found.
				<cfif form.delete>
					Delete
					<cftry>
						<cfset FLGen_DeleteThisFile(fileList.name,form.folder)>
						<!--- <cffile action="delete" file="#application.AbsPath##form.folder##fileList.name#"> --->
						<cfcatch>
							<span class="alert">Unable to delete</span>
						</cfcatch>
					</cftry>
				</cfif>
				<br />
			</cfif>
		</cfloop>
	</cfif>
	<br><br>
	<cfif NOT badQuery>
		End of search.<br><br>
		<cfif DeletedCount EQ 0>
			<span class="alert">No orphans found.</span><br><br>
		<cfelse>
			<cfoutput>#DeletedCount#</cfoutput> orphan<cfif DeletedCount NEQ 1>s</cfif> found.<br><br>
		</cfif>
	</cfif>
</cfif>

<cfoutput>
<cfif alert_msg NEQ "">
	<p>The following errors were found:</p>
	<span class="alert"><ul>#alert_msg#</ul></span>
</cfif>
<form name="OrphanForm" action="#CurrentPage#" method="post">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr class="contenthead"><td colspan="2" class="headertext">Search Parameters</td></tr>
		<tr class="content">
			<td align="right">Folder containing files:<br><span class="sub">example: pics/products/<br>under #application.AbsPath#</span></td>
			<td><input type="text" name="folder" value="#form.folder#" size="60" maxlength="128"></td>
		</tr>
		<tr class="content">
			<td align="right">Table.Fields:<br><span class="sub">example: product.imagefile</span></td>
			<td><input type="text" name="fields" value="#form.fields#" size="60" maxlength="128"><br><span class="sub">Separate with commas</span></td>
		</tr>
		<tr class="content">
			<td align="right">Primary Keys of above table.fields:<br><span class="sub">example: ID</span></td>
			<td><input type="text" name="keys" value="#form.keys#" size="60" maxlength="128"><br><span class="sub">Separate with commas</span></td>
		</tr>
		<cfif isDefined("form.submit") AND NOT form.delete>
			<tr><td colspan="2" align="center">Check this box to delete the orphans:&nbsp;&nbsp;&nbsp;<input type="checkbox" name="delete" value="1"></td></tr>
		</cfif>
		<tr><td colspan="2" align="center"><input type="submit" name="submit" value="   Search   "></td></tr>
	</table>
</form>
</cfoutput>


	</td>
</tr>
</table>

<cfinclude template="includes/footer.cfm">