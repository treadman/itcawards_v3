<cfif is_one_item EQ 0>
<cfset request.groupName = "">
<cfquery name="FindExludeProdIDs" datasource="#application.DS#">
	SELECT product_ID 
	FROM #application.database#.program_product_exclude 
	WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
</cfquery>
<!--- <cfoutput>#g#</cfoutput> --->
<cfquery name="FindGroups" datasource="#application.DS#">
	SELECT DISTINCT g.ID, g.name
	FROM #application.database#.product_meta_group_lookup l
	LEFT JOIN #application.database#.product_meta_group g ON g.ID = l.product_meta_group_ID
	LEFT JOIN #application.database#.product_meta m ON m.ID = l.product_meta_ID
	JOIN #application.database#.product p ON p.product_meta_ID = m.ID 
	WHERE p.is_active = 1
	AND g.name > ''
	AND p.is_discontinued = 0
	<cfif product_set_tabs AND set EQ 0>
		AND 1 = 2
	<cfelse>
		<cfif product_set_IDs NEQ "">
			AND m.product_set_ID 
			<cfif set gt 0> = <cfqueryparam cfsqltype="cf_sql_integer" value="#set#">
			<cfelse> IN (#product_set_IDs#)
				<cfif use_master_categories EQ 2 AND g EQ default_group_id>
					AND m.product_set_ID != 1
				</cfif>
			</cfif>
		<cfelse>
			AND 1 = 2
		</cfif>
	</cfif>
	<cfif FindExludeProdIds.recordcount GT 0>
		AND p.ID NOT IN (#ValueList(FindExludeProdIDs.product_ID)#)
	</cfif>

	<!--- TODO: Figure out how to get empty groups out of this list (They don't count as empty if filtering)--->
	AND g.ID !=	1000000009
	<!--- Above is a fudge.  Read TODO above --->
		 
	ORDER BY g.sortorder ASC
</cfquery>
</cfif>
<!--- <cfoutput>#product_set_IDs#</cfoutput> --->
<!---<cfdump var="#FindGroups#">--->
<cfif use_master_categories GT 2>
	<div style="position: relative; top: -0px; left: -0px; ">
		<cfset total_width = 878>
		<table cellpadding="0" cellspacing="0" border="0" width="<cfoutput>#total_width#</cfoutput>">
			<tr height="40px;">
				<cfset total_cnt = FindGroups.recordcount>
				<cfset cnt = 1>
				<cfoutput query="FindGroups">
					<cfif total_width GT 199>
						<cfset this_width = 100>
					<cfelse>
						<cfset this_width = total_width>
					</cfif>
					<cfset total_width = total_width - this_width>
					<cfif g EQ FindGroups.ID>
						<td align="center" class="selected_group" width="#this_width#px;"
						<cfif CGI.SCRIPT_NAME CONTAINS "main_prod.cfm">
							onClick="window.location='main.cfm?c=#c#&p=#p#&g=#g#&OnPage=#OnPage#&cp=#cp#&set=#set#&div=#request.division_ID#'"
						</cfif>	
						>#FindGroups.name#</td>
					<cfelse>
						<td align="center" class="active_group" width="#this_width#px;" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');" onClick="window.location='main.cfm?c=#c#&p=#p#&g=#FindGroups.ID#&cp=#cp#&set=#set#&div=#request.division_ID#'">#FindGroups.name#</td>
					</cfif>
				</cfoutput>
				<!--- onClick="window.location='cart.cfm?c=#c#&p=#p#&g=#g#&OnPage=#OnPage#&cp=#cp#'">CART --->
			</tr>
		</table>
	</div>
<cfelse>
<!--- NO GROUPS for this category, just the All button --->
<cfif is_one_item GT 0 OR FindGroups.RecordCount EQ 0>
	<cfoutput>
	<table cellpadding="0" cellspacing="2" border="0" width="100%">
	

	<tr>
		<cfif is_one_item EQ 0>
	<td align="center" width="100" class="selected_group" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=x'&div=#request.division_ID#"><b>View All</b></td>
	<cfelse>
	<td align="center" width="100">&nbsp;</td>
		</cfif>
	<td>&nbsp;</td>
	<td align="center" width="100" class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='cart.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&div=#request.division_ID#'"><b>#Translate(language_ID,'view_cart_button')#</b></td>
	</tr>
	</table>
	</cfoutput>
<cfelse>
	<!--- setting the variables for the group loop to dynamically create 1+ rows of buttons --->
	<cfset totalgroups = FindGroups.RecordCount>
	<!--- right now, 5 is the most groups per row --->
	<cfset grouploopMOD = totalgroups MOD 5>
	<cfset grouploop = totalgroups\5>
	<cfif grouploopMOD NEQ 0>
		<cfset grouploop = grouploop + 1>
	</cfif>
	<cfset grouploopinc =(totalgroups \ grouploop) - 1>
	<cfoutput>
	<cfloop from="1" to="#grouploop#" index="thisgrouploop">
		<cfif thisgrouploop EQ 1>
			<cfset thisStartRow = 1>

<!--- TODO: The default_group_id goes in programs table: --->
<cfif program_ID EQ "1000000101" AND g EQ default_group_id AND use_master_categories EQ 2>
	<cfset thisEndRow = 1>
<cfelse>
			<cfset thisEndRow = (thisStartRow + grouploopinc)* thisgrouploop>
</cfif>
			<!--- this is the first row --->
			<table cellpadding="0" cellspacing="2" border="0" width="100%">
			<tr>
			<td align="center" width="100" <cfif isNumeric(g) OR g EQ "" OR g EQ "search"> class="active_group" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');"<cfelse>class="selected_group"</cfif> onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=x&set=#set#'"><b>View All</b></td>
			<cfif use_master_categories NEQ 2>
				<cfloop query="FindGroups" startrow="#thisStartRow#" endrow="#thisEndRow#">
					<cfif g EQ FindGroups.ID>
						<td align="center"  class="selected_group"><b>#FindGroups.name#</b></td>
					<cfelse>
						<td align="center"  class="active_group" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#FindGroups.ID#&set=#set#&div=#request.division_ID#'"><b>#FindGroups.name#</b></td>
					</cfif>
				</cfloop>
			<cfelse>
				<td>&nbsp;</td>
			</cfif>
			<td align="center" width="100" class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');"
			<cfif has_main_menu_button AND false>
				onClick="window.location='main.cfm?div=#request.division_ID#'"><b>&nbsp;&nbsp;Main Menu&nbsp;&nbsp;</b>
			<cfelse>
				onClick="window.location='cart.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'"><b>#Translate(language_ID,'view_cart_button')#</b>
			</cfif>
			</td>
			</tr>
			<cfif use_master_categories EQ 2>
				<cfloop query="FindGroups" startrow="#thisStartRow#" endrow="#thisEndRow#">
					<tr height="5"><td></td></tr>
					<tr>
					<cfif g EQ FindGroups.ID>
						<td align="center"  class="selected_group"><b>#FindGroups.name#</b></td>
					<cfelse>
						<td align="center"  class="active_group" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#FindGroups.ID#&set=#set#&div=#request.division_ID#'"><b>#FindGroups.name#</b></td>
					</cfif>
			<cfif has_main_menu_button>
				<td>&nbsp;</td>
				<td align="center" width="100" class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');"
				onClick="window.location='cart.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'"><b>#Translate(language_ID,'view_cart_button')#</b>
				</td>
			</cfif>
					</tr>
				</cfloop>
			</cfif>
			</table>
		<cfelseif thisgrouploop EQ grouploop>
			<cfset thisStartRow = ((grouploopinc + 1) * thisgrouploop) - grouploopinc>
			<cfset thisEndRow = totalgroups>
			<!--- this is the last row --->
			<table cellpadding="0" cellspacing="2" border="0" width="100%">
			<tr>
			<cfloop query="FindGroups" startrow="#thisStartRow#" endrow="#thisEndRow#">
				<cfif g EQ FindGroups.ID>
					<td align="center"  class="selected_group"><b>#FindGroups.name#</b></td>
				<cfelse>
					<td align="center"  class="active_group" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#FindGroups.ID#&set=#set#&div=#request.division_ID#'"><b>#FindGroups.name#</b></td>
				</cfif>
			</cfloop>
			</tr>
			</table>
		<cfelse>
<cfif g NEQ default_group_id AND use_master_categories EQ 2 AND thisGroupLoop EQ 2>
	<br>
	<cfset thisStartRow = 2>
<cfelse>
			<cfset thisStartRow = ((grouploopinc + 1) * thisgrouploop) - grouploopinc>
</cfif>
			<cfset thisEndRow = (grouploopinc + 1) * thisgrouploop>
			<!--- these are the middle rows --->
			<table cellpadding="0" cellspacing="2" border="0" width="100%">
			<tr>
			<cfloop query="FindGroups" startrow="#thisStartRow#" endrow="#thisEndRow#">
				<cfif g EQ FindGroups.ID>
					<cfset request.groupName = FindGroups.name>
					<td align="center"  class="selected_group"><b>#FindGroups.name#</b></td>
				<cfelse>
					<td align="center"  class="active_group" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#FindGroups.ID#&set=#set#&div=#request.division_ID#'"><b>#FindGroups.name#</b></td>
				</cfif>
			</cfloop>
			</tr>
			</table>
		</cfif>
	</cfloop>
	</cfoutput>
</cfif>
</cfif>