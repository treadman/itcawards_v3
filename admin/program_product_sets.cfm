<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfparam name="counter" default="0">
<cfparam name="product_set_text" default="">
<cfparam name="product_set_tabs" default="0">

<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>
<cfset edit_division = false>
<cfif isNumeric(request.selected_division_ID) AND request.selected_division_ID GT 0>
	<cfset edit_division = true>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif has_program AND IsDefined('form.Submit')>

	<!--- delete all exclude entries for this program --->
	<cfquery name="DeleteExProds" datasource="#application.DS#">
		DELETE FROM #application.database#.xref_program_product_set
		WHERE program_ID =
		<cfif edit_division> 
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
		<cfelse>
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		</cfif>
	</cfquery>
	
	<!--- loop through ExcludeThis and Insert into xref_program_product_set --->
	<cfif IsDefined('form.sets') AND form.sets IS NOT "">
		<cfloop list="#form.sets#" index="ThisProductSet">
			<cfquery name="InsertQuery" datasource="#application.DS#">
				INSERT INTO #application.database#.xref_program_product_set
				(created_user_ID, created_datetime, program_ID, product_set_ID)
				VALUES
				(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
				'#FLGen_DateTimeToMySQL()#', 
				<cfif edit_division> 
					<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">,
				<cfelse>
					<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">,
				</cfif>
				<cfqueryparam cfsqltype="cf_sql_integer" value="#ThisProductSet#" maxlength="10">)
			</cfquery>

		</cfloop>
	</cfif>
	<cfquery name="UpdateQuery" datasource="#application.DS#">
		UPDATE #application.database#.program
		SET product_set_text = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#product_set_text#"  null="#YesNoFormat(NOT Len(Trim(product_set_text)))#">,
			product_set_tabs = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#product_set_tabs#">
		WHERE ID =
		<cfif edit_division> 
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
		<cfelse>
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		</cfif>
	</cfquery>

	<cfset alert_msg = Application.DefaultSaveMessage>

</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfif has_program>
	
	<cfquery name="GetSets" datasource="#application.DS#">
		SELECT ID, set_name
		FROM #application.database#.product_set
		ORDER BY sortorder
	</cfquery>

	<cfquery name="SelectedProductSets" datasource="#application.DS#">
		SELECT product_set_ID
		FROM #application.database#.xref_program_product_set
		WHERE program_ID = 
		<cfif edit_division> 
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
		<cfelse>
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		</cfif>
	</cfquery>

	<cfset SelectedIDs = ValueList(SelectedProductSets.product_set_ID)>

	<cfquery name="GetProgram" datasource="#application.DS#">
		SELECT product_set_text, product_set_tabs
		FROM #application.database#.program
		WHERE ID =
		<cfif edit_division> 
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
		<cfelse>
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		</cfif>
	</cfquery>

	<cfif GetProgram.recordcount EQ 1>
		<cfset product_set_text = GetProgram.product_set_text>
		<cfset product_set_tabs = GetProgram.product_set_tabs>
	</cfif>

</cfif>

<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfset tinymce_fields = "product_set_text">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">

<cfoutput>
<cfif NOT has_program>
	<span class="pagetitle">Products Sets</span>
	<br /><br />
	<span class="alert">#application.AdminSelectProgram#</span>
<cfelse>
	<span class="pagetitle">
	<cfif edit_division>
		<span class="highlight">Product Sets for #request.division_name#</span> a division of
	<cfelse>
		Product Sets Settings for
	</cfif>
	#request.program_name#
	</span>
	<br /><br />
	<span class="pageinstructions">Return to the <a href="program_details.cfm"><cfif edit_division>Division<cfelse>Award Program</cfif> Details</a><cfif edit_division> or the <a href="program_details.cfm?division_select=">Parent Program Details</a></cfif> or the <a href="program_list.cfm?division_select=">Award Program List</a> without making changes.</span>
	<br /><br />
	<form method="post" action="#CurrentPage#">
		<table cellpadding="5" cellspacing="1" border="0" width="100%">
			<tr class="contenthead">
				<td width="10%" class="headertext"></td>
				<td width="90%" class="headertext">Set Name</td>
			</tr>
			<cfloop query="GetSets">
				<tr class="#Iif(((GetSets.currentrow MOD 2) is 1),de('content2'),de('content'))#">
					<td align="center"><input type="checkbox" name="sets" value="#GetSets.ID#" <cfif ListFind(SelectedIDs,GetSets.ID)>checked</cfif>></td>
					<td>#GetSets.set_name#</td>
				</tr>
			</cfloop>
			<tr class="contenthead" height="5px;">
				<td colspan="100%"></td>
			</tr>
			<tr class="content2">
				<td></td>
				<td>Use tabs for each product set:
					<select name="product_set_tabs">
						<option value="0"<cfif #product_set_tabs# EQ 0> selected</cfif>>No
						<option value="1"<cfif #product_set_tabs# EQ 1> selected</cfif>>Yes
					</select>
				</td>
				<tr class="content">
				<td colspan="2">
					Message For Selecting Product Set (If using tabs for each product set)
				</td>
			</tr>
			<tr>
				<td colspan="2"><textarea name="product_set_text" cols="75" rows="10">#product_set_text#</textarea>
				</td>
			</tr>
			<tr>
				<td colspan="4" align="center">
					<input type="submit" name="submit" value="   Save Changes   " />
				</td>
			</tr>
		</table>
	</form>
</cfif>
</cfoutput>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->