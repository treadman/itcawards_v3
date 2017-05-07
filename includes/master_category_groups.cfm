<!--- GROUP BUTTONS --->
<!--- find all the groups (where the meta category is either the selected one /or/ assigned one(s)) --->
<cfquery name="SelectGroups" datasource="#application.DS#">
	SELECT DISTINCT pmgl.product_meta_group_ID as ThisGroupID
	FROM #application.database#.product_meta_group_lookup pmgl JOIN #application.database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
	#extrawhere_pvmID_IN#
</cfquery>

<!--- CHECKING TO SEE IF ANY EXCLUDED (as long as there are groups found above) --->
<cfif SelectGroups.RecordCount NEQ 0>
	<cfquery name="FindExludeProdIDs" datasource="#application.DS#">
		SELECT product_ID 
		FROM #application.database#.program_product_exclude 
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#">
	</cfquery>
	<!--- if there are excluded products, create a list of groupIDs and prodIDs --->
	<cfif FindExludeProdIDs.RecordCount NEQ 0>
		<cfset ExcludedProdID = ValueList(FindExludeProdIDs.product_ID)>
		<!--- If there are excluded products, get their categories --->
		<cfquery name="FindExcludeGroupIDs" datasource="#application.DS#">
			SELECT DISTINCT pmgl.product_meta_group_ID 
			FROM #application.database#.product_meta_group_lookup pmgl
				JOIN #application.database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
				JOIN #application.database#.product p ON p.product_meta_ID = pm.ID 
			WHERE p.ID IN (#ExcludedProdID#)
		</cfquery>
		<cfset ExcludedProdGroups = ValueList(FindExcludeGroupIDs.product_meta_group_ID)>
	</cfif>
</cfif>

<!--- loop through the groups and make sure there is at least one active product that isn't excluded --->
<cfloop query="SelectGroups">
	<cfset show_this_group = "true">
	<!--- ONLY IF THERE ARE EXCLUDES for this group ... check the all-total and exclude-total --->
	<cfif FIND(SelectGroups.ThisGroupID,ExcludedProdGroups) NEQ 0  AND extrawhere_pvmID_IN NEQ "">
		<cfquery name="ProdsInGroup_total_all" datasource="#application.DS#">
				SELECT COUNT(pmgl.ID) AS total 
				FROM #application.database#.product_meta_group_lookup pmgl
					JOIN #application.database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
					JOIN #application.database#.product p ON p.product_meta_ID = pm.ID 
				WHERE pmgl.product_meta_group_ID = #SelectGroups.ThisGroupID# AND is_active = 1
			<cfif product_set_IDs NEQ "">
				AND pm.product_set_ID IN (#product_set_IDs#)
			<cfelse>
				AND 1 = 2
			</cfif>
			<cfif is_one_item GT 0>
				AND ( #extrawhere_pvmID_OR# )
			<cfelse>
			 AND #RemoveChars(extrawhere_pvmID_IN,2,6)#
			</cfif>
		</cfquery>
		<cfquery name="ProdsInGroup_total_excludes" datasource="#application.DS#">
			SELECT COUNT(p.ID) AS total 
			FROM #application.database#.product_meta_group_lookup pmgl
				JOIN #application.database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
				JOIN #application.database#.product p ON p.product_meta_ID = pm.ID 
			WHERE p.ID IN (#ExcludedProdID#)
			<cfif product_set_IDs NEQ "">
				AND pm.product_set_ID IN (#product_set_IDs#)
			<cfelse>
				AND 1 = 2
			</cfif>
				AND pmgl.product_meta_group_ID = #SelectGroups.ThisGroupID#
		</cfquery>
		<cfif ProdsInGroup_total_all.total LTE ProdsInGroup_total_excludes.total>
			<cfset show_this_group = "false">
		<cfelse>
			<cfset show_this_group = "true">
		</cfif>
		
	</cfif>
	<!--- check if this group has at least one meta product with at least one product that isn't discontinued or inactive --->
	<cfif show_this_group AND extrawhere_pvmID_IN NEQ "">
		<cfquery name="ProdsInGroup_active_not_discountinued" datasource="#application.DS#">
			SELECT COUNT(p.ID) AS total 
			FROM #application.database#.product_meta_group_lookup pmgl
				JOIN #application.database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
				JOIN #application.database#.product p ON p.product_meta_ID = pm.ID 
			WHERE p.is_active = 1 and p.is_discontinued = 0
			<cfif product_set_IDs NEQ "">
				AND pm.product_set_ID IN (#product_set_IDs#)
			<cfelse>
				AND 1 = 2
			</cfif>
				AND pmgl.product_meta_group_ID = #SelectGroups.ThisGroupID#
				AND #Replace(extrawhere_pvmID_IN,"WHERE ","","all")#
		</cfquery>
		<cfif ProdsInGroup_active_not_discountinued.total EQ 0>
			<cfset show_this_group = "false">
		</cfif>
	</cfif>
	<!--- create WHERE statement like "OR group ID = x" --->
	<cfif show_this_group>
		<cfset extrawhere_groupID_OR = extrawhere_groupID_OR & " OR ID = #SelectGroups.ThisGroupID# ">
	</cfif>
</cfloop>

<cfif extrawhere_groupID_OR NEQ "">
	<cfset extrawhere_groupID_OR = RemoveChars(extrawhere_groupID_OR,1,3)>
<cfelse>
	<cfset extrawhere_groupID_OR = " 1 = 2 ">
</cfif>

<!--- do a select from the group table with the concat where above that I will use to spit out the buttons --->
<!--- if there are no qualifying groups, it'll find none. --->
<cfquery name="SelectProgramsAllGroups" datasource="#application.DS#">
	SELECT name AS group_name, ID AS group_ID
	FROM #application.database#.product_meta_group
	WHERE #extrawhere_groupID_OR# 
	ORDER BY sortorder ASC
</cfquery>

<!--- create the group buttons --->

<!--- NO GROUPS for this category, just the All button --->
<cfif SelectProgramsAllGroups.RecordCount EQ 0>
	<cfoutput>
	<table cellpadding="0" cellspacing="2" border="0" width="100%">
	<tr>
	<td align="center" width="100" class="selected_group" onClick="window.location='main.cfm?c=#c#&p=#url.p#'"><b>View All</b></td>
	<td>&nbsp;</td>
	<td align="center" width="100" class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='cart.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#'"><b>#Translate(language_ID,'view_cart_button')#</b></td>
	</tr>
	</table>
	</cfoutput>
<cfelse>
	<!--- setting the variables for the group loop to dynamically create 1+ rows of buttons --->
	<cfset totalgroups = SelectProgramsAllGroups.RecordCount>
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
			<cfset thisEndRow = (thisStartRow + grouploopinc)* thisgrouploop>
			<!--- this is the first row --->
			<table cellpadding="0" cellspacing="2" border="0" width="100%">
			<tr>
			<td align="center" width="100"  <cfif g NEQ "">class="active_group" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');"<cfelse>class="selected_group"</cfif> onClick="window.location='main.cfm?c=#c#&p=#url.p#'"><b>View All</b></td>
			<cfloop query="SelectProgramsAllGroups" startrow="#thisStartRow#" endrow="#thisEndRow#">
				<cfif g EQ group_ID>
					<td align="center"  class="selected_group"><b>#group_name#</b></td>
				<cfelse>
					<td align="center"  class="active_group" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#group_ID#'"><b>#group_name#</b></td>
				</cfif>
			</cfloop>
			<td align="center" width="100" class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='cart.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#'"><b>#Translate(language_ID,'view_cart_button')#</b></td>
			</tr>
			</table>
		<cfelseif thisgrouploop EQ grouploop>
			<cfset thisStartRow = ((grouploopinc + 1) * thisgrouploop) - grouploopinc>
			<cfset thisEndRow = totalgroups>
			<!--- this is the last row --->
			<table cellpadding="0" cellspacing="2" border="0" width="100%">
			<tr>
			<cfloop query="SelectProgramsAllGroups" startrow="#thisStartRow#" endrow="#thisEndRow#">
				<cfif g EQ group_ID>
					<td align="center"  class="selected_group"><b>#group_name#</b></td>
				<cfelse>
					<td align="center"  class="active_group" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#group_ID#'"><b>#group_name#</b></td>
				</cfif>
			</cfloop>
			</tr>
			</table>
		<cfelse>
			<cfset thisStartRow = ((grouploopinc + 1) * thisgrouploop) - grouploopinc>
			<cfset thisEndRow = (grouploopinc + 1) * thisgrouploop>
			<!--- these are the middle rows --->
			<table cellpadding="0" cellspacing="2" border="0" width="100%">
			<tr>
			<cfloop query="SelectProgramsAllGroups" startrow="#thisStartRow#" endrow="#thisEndRow#">
				<cfif g EQ group_ID>
					<td align="center"  class="selected_group"><b>#group_name#</b></td>
				<cfelse>
					<td align="center"  class="active_group" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#group_ID#'"><b>#group_name#</b></td>
				</cfif>
			</cfloop>
			</tr>
			</table>
		</cfif>
	</cfloop>
	</cfoutput>
</cfif>
