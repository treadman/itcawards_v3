<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000008,true)>

<cfparam name="pgfn" default="add">
<cfparam name="prod_ID" default=0>
<cfparam name="meta_ID" default=0>
<cfparam name="xS" default="">
<cfparam name="xL" default="">
<cfparam name="xT" default="">
<cfparam name="xW" default="">
<cfparam name="xA" default="">
<cfparam name="OnPage" default=1>
<cfparam name="program_id_list" default="">

<cfset leftnavon = "products">
<cfinclude template="includes/header.cfm">

<cffunction name="FL_ExcludeProgram" returntype="numeric" output="false">
	<cfargument name="pass_product_ID" type="numeric" required="yes">
	<cfargument name="pass_program_ID_List" type="string" required="yes">

	<cfset VAR Return_Value=1>

	<cfquery name="DeleteXRef" datasource="#application.DS#">
		DELETE FROM #application.database#.program_product_exclude
		WHERE product_ID = <cfqueryparam value="#pass_product_ID#" cfsqltype="CF_SQL_INTEGER" maxlength="10">
	</cfquery>
	<cfif program_id_list GT ''>
		<cfoutput>
			<cfloop index="save_program_ID" list="#pass_program_ID_List#">
				<cfquery name="SaveXRef" datasource="#application.DS#">
					INSERT INTO #application.database#.program_product_exclude
						(created_user_ID, 
						created_datetime,
						program_ID, 
						product_ID)
					VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam value="#save_program_ID#" cfsqltype="CF_SQL_INTEGER" maxlength="10">,
						<cfqueryparam value="#pass_product_ID#" cfsqltype="CF_SQL_INTEGER" maxlength="10">)
				</cfquery>
			</cfloop>
		</cfoutput>
	</cfif>

	<cfreturn Return_Value>
</cffunction>

<cfif pgfn EQ "save">
	<cfif prod_ID GT 0>
		<cfset FL_ExcludeProgram(prod_ID, program_id_list)>
	<cfelse>	
		<cfquery name="ProductIDList" datasource="#application.DS#">
			SELECT ID
			FROM #application.database#.product
			WHERE product_meta_ID = <cfqueryparam value="#meta_ID#" cfsqltype="CF_SQL_INTEGER" maxlength="10">
		</cfquery>
		<cfloop query="ProductIDList">
			<cfset FL_ExcludeProgram(ProductIDList.ID, program_id_list)>
		</cfloop>
	</cfif>

	<cfset alert_msg = "The exclude list has been saved.">
	<cfset pgfn='add'>
</cfif>

<!--- START pgfn LIST --->
<cfif pgfn EQ "add">
	<cfquery name="ListOfActivePrograms" datasource="#application.DS#">
		SELECT PR.ID, PR.company_name, PR.program_name
		FROM #application.database#.program PR
		WHERE parent_ID = 0
		ORDER BY PR.company_name
	</cfquery>
	<span class="pagetitle">Bulk Exclude List</span>
	<br /><br />
	<span class="pageinstructions">Select the Programs that this product should be excluded from.</span>
	<br /><br />
	<span class="pageinstructions">Return to the <a href="<cfoutput>product.cfm?pgfn=edit&meta_id=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#</cfoutput>">Product Detail</a> page.<br /><br />
<SCRIPT LANGUAGE="JavaScript">
function checkAll(field)
{
for (i = 0; i < field.length; i++)
	field[i].checked = true ;
}

function uncheckAll(field)
{
for (i = 0; i < field.length; i++)
	field[i].checked = false ;
}
//  End -->
</script>
	<form method="post" action="<cfoutput>#CurrentPage#</cfoutput>" name="myform">
		<input type="button" name="CheckAll" value="Check All" onClick="checkAll(document.myform.program_id_list)">
		<input type="button" name="UnCheckAll" value="Uncheck All" onClick="uncheckAll(document.myform.program_id_list)">
		<table border="0">
			<tr><th>&nbsp;</th><th>Program</th></tr>
			<cfoutput query="ListOfActivePrograms">
				<tr>
					<td><input name="program_id_list" type="checkbox" value="#ID#"></td>
					<td>#company_name# [#program_name#]</td>
				</tr>
			</cfoutput>	
			<tr>
				 <td colspan="2" align="center">
				<input type="button" name="CheckAll" value="Check All" onClick="checkAll(document.myform.program_id_list)">
				<input type="button" name="UnCheckAll" value="Uncheck All" onClick="uncheckAll(document.myform.program_id_list)"><br />
					<cfoutput>
						<input type="hidden" name="pgfn" value="save">
						<input type="hidden" name="prod_ID" value="#prod_ID#">
						<input type="hidden" name="meta_ID" value="#meta_ID#">
						<input type="hidden" name="xS" value="#xS#">
						<input type="hidden" name="xL" value="#xL#">
						<input type="hidden" name="xT" value="#xT#">
						<input type="hidden" name="xW" value="#xW#">
						<input type="hidden" name="xA" value="#xA#">
						<input type="hidden" name="OnPage" value="#OnPage#">
						<input type="submit" name="submit" value="Exclude from these programs">
					</cfoutput>
				</td>
			</tr>
		</table>
	</form>
</cfif>
	
</td>
</tr>

</table>

<cfinclude template="includes/footer.cfm">