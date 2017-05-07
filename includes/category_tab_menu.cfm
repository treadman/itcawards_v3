<table cellpadding="0" cellspacing="0" border="0" width="980">
<tr>
<td width="100" valign="top" align="right" class="active_cell">
	<br />
	<table cellpadding="0" cellspacing="0" border="0" width="100">
		
	<tr height="40px;">
	<td align="center" valign="top" class="welcome_instructions"><strong><cfoutput>#menu_text#</cfoutput></strong></td>
	</tr>
<!--- <cfif isBoolean(use_master_categories)>
<cfif use_master_categories> --->
	<cfquery name="SelectProgramCategories_AllOthers" datasource="#application.DS#">
		SELECT DISTINCT ID AS pvp_ID,productvalue_master_ID, displayname 
		FROM #application.database#.productvalue_program
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
		ORDER BY sortorder ASC
	</cfquery>
	<!---
	<pre>
		SELECT DISTINCT ID AS pvp_ID,productvalue_master_ID, displayname 
		FROM #application.database#.productvalue_program
		WHERE program_ID = #program_ID#
		ORDER BY sortorder ASC
	</pre>
	--->
	<cfset SelectProgramCategories = SelectProgramCategories_AllOthers>

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
		<tr height="2px;"><td><img src="pics/program/edge.gif" border="0" width="100" height="2"></td></tr>
		<cfoutput query="SelectProgramCategories">
		
			<cfset cat_ID = HTMLEditFormat(SelectProgramCategories.pvp_ID)>
			<cfset pvm_ID = HTMLEditFormat(SelectProgramCategories.productvalue_master_ID)>
			<cfset displayname = HTMLEditFormat(SelectProgramCategories.displayname)>
			<cfif NOT isNumeric(displayname)><cfthrow message="#displayname# is not numeric!"></cfif>
			<cfif c EQ "">
				<cfset c = cat_ID>
			</cfif>
			<cfif (cp EQ 1 AND displayname LTE 500) OR (cp EQ 2 AND displayname GT 499)>
				<cfif cp EQ 2 AND displayname EQ 500>
					<tr>
						<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='main.cfm'">
							$499-
						</td>
					</tr>
					<tr height="2px;"><td><img src="pics/program/edge.gif" border="0" width="100" height="2"></td></tr>
				</cfif>
				<tr>
					<td align="center" 
						<cfif c EQ cat_ID>
							class="selected_button"
							<cfif CGI.SCRIPT_NAME CONTAINS "main_prod.cfm">
 								onClick="window.location='main.cfm?c=#c#&p=#p#&g=#g#&OnPage=#OnPage#&cp=#cp#'"
 							</cfif>	
						<cfelse>
							class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');"
							<cfif cp EQ 1 AND displayname EQ 500>
								onClick="window.location='main.cfm?c=#cat_ID#&p=#pvm_ID#&g=#g#&cp=2'"
							<cfelse>
								onClick="window.location='main.cfm?c=#cat_ID#&p=#pvm_ID#&g=#g#&cp=#cp#'"
							</cfif>
						</cfif>>
						$#displayname#<cfif cp EQ 1 AND displayname EQ 500>+</cfif>
					</td>
				</tr>
				<tr height="2px;"><td><img src="pics/program/edge.gif" border="0" width="100" height="2"></td></tr>
			</cfif>
		</cfoutput>
		<!--- p wasn't already set, set it using c--->
		<cfif p EQ "" and is_one_item EQ 0>
			<cfif NOT isDefined("c") OR NOT isNumeric(c)>
				<span class="alert">We apologize, but the gift categories have not been set up.</span>
			<cfelse>
				<cfquery name="SelectP" datasource="#application.DS#">
					SELECT productvalue_master_ID
					FROM #application.database#.productvalue_program
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#c#">
				</cfquery>
				<cfset p = SelectP.productvalue_master_ID>
			</cfif>
		</cfif>
		<cfif isNumeric(p)>
			<cfset extrawhere_pvmID_IN = " WHERE pm.productvalue_master_ID = #p# ">
		</cfif>

	</cfif>	
	<cfif FileExists(application.AbsPath & "award_certificate/" & users_username & "_certificate_" & program_ID & ".pdf")>
		<tr>
		<td>&nbsp;</td>
		</tr>
		<tr>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="openCertificate()">View Certificate</td>
		</tr>
	</cfif>
<!---
	<cfif help_button NEQ "">
		<tr>
		<td>&nbsp;</td>
		</tr>
		<tr>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="openHelp()">#help_button#</td>
		</tr>
	</cfif>
	<cfif isBoolean(can_defer) AND can_defer>
		<tr>
		<td>&nbsp;</td>
		</tr>
		<tr>
		<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='main_login.cfm?defer=yes&c=#c#&p=#p#&g=#g#&OnPage=#OnPage#&cp=#cp#'">Deferral Options</td>
		</tr>
	</cfif>
	<cfif additional_content_button NEQ "">
		<tr><td>&nbsp;</td></tr>
		<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='additional_content.cfm'">#additional_content_button#</td></tr>
	</cfif>
--->
	</table>
</td>
