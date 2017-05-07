<br />
<table cellpadding="8" cellspacing="1" border="0" width="150">
<tr><td align="center" class="active_cell"><cfoutput>#menu_text#</cfoutput></td></tr>
<!--- find categories for this program --->
<cfquery name="SelectProgramCategories" datasource="#application.DS#">
	SELECT DISTINCT ID AS pvp_ID,productvalue_master_ID, displayname 
	FROM #application.database#.productvalue_program
	WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
	ORDER BY sortorder ASC
</cfquery>

<!--- if this is a one items store
		1) Set c (category selected) to nothing
		2) Create SQL for limiting product searchs to just these categories --->

<cfif is_one_item GT 0>
	<cfset these_assigned_cats = ValueList(SelectProgramCategories.productvalue_master_ID)>

	<cfloop query="SelectProgramCategories">
		<cfset extrawhere_pvmID_OR = extrawhere_pvmID_OR & " OR pm.productvalue_master_ID = #productvalue_master_ID# ">
	</cfloop>

	<cfif extrawhere_pvmID_OR NEQ "">
		<cfset extrawhere_pvmID_OR = RemoveChars(extrawhere_pvmID_OR,1,3)>
	</cfif>
	
	<cfif these_assigned_cats NEQ "">
		<cfset extrawhere_pvmID_IN =  " WHERE pm.productvalue_master_ID IN (#these_assigned_cats#)">
	</cfif>
	
<!--- If this is NOT a one item store
		1) create category nav down left side of page
		2) Create SQL for limiting product searchs to the selected category --->

<cfelseif is_one_item EQ 0>

	<cfoutput query="SelectProgramCategories">
		<cfset cat_ID = HTMLEditFormat(SelectProgramCategories.pvp_ID)>
		<cfset pvm_ID = HTMLEditFormat(SelectProgramCategories.productvalue_master_ID)>
		<cfset displayname = HTMLEditFormat(SelectProgramCategories.displayname)>
		<cfif c EQ cat_ID OR c EQ "">
			<tr>
			<td align="center" class="selected_button">#displayname#</td>
			</tr>
			<cfif c EQ "">
				<cfset c = cat_ID>
			</cfif>
		<cfelse>
			<tr>
			<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='main.cfm?c=#cat_ID#&p=#pvm_ID#&g='">#displayname#</td>
			</tr>
		</cfif>
	</cfoutput>
	<!--- url.p wasn't already set, set it using c--->
	<cfif url.p EQ "" and is_one_item EQ 0>
		<cfif NOT isDefined("c") OR NOT isNumeric(c)>
			<span class="alert">We apologize, but the gift categories have not been set up.</span>
		<cfelse>
			<cfquery name="SelectP" datasource="#application.DS#">
				SELECT productvalue_master_ID
				FROM #application.database#.productvalue_program
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#c#">
			</cfquery>
			<cfset url.p = SelectP.productvalue_master_ID>
		</cfif>
	</cfif>
	<cfif isNumeric(url.p)>
		<cfset extrawhere_pvmID_IN = " WHERE pm.productvalue_master_ID = #url.p# ">
	</cfif>
</cfif>	

<cfinclude template="menu_bottom_buttons.cfm">

</table>
