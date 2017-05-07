<!--- GROUP BUTTONS --->
<!--- find all the groups (where the meta category is either the selected one /or/ assigned one(s)) --->
<cfquery name="SelectGroups" datasource="#application.DS#" cachedwithin="#CreateTimeSpan(0,0,0,0)#">
	SELECT DISTINCT pmgl.product_meta_group_ID as ThisGroupID
	FROM #application.product_database#.product_meta_group_lookup pmgl JOIN #application.product_database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
	#extrawhere_pvmID_IN#
</cfquery>

<!--- CHECKING TO SEE IF ANY EXCLUDED (as long as there are groups found above) --->
<cfif SelectGroups.RecordCount NEQ 0>

	<cfquery name="FindExludeProdIDs" datasource="#application.DS#">
		SELECT product_ID 
		FROM #application.database#.program_product_exclude 
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10" >
	</cfquery>
	
	<!--- if there are excluded products, create a list of groupIDs and prodIDs --->
	<cfif FindExludeProdIDs.RecordCount NEQ 0>
		<cfset ExcludedProdID = ValueList(FindExludeProdIDs.product_ID)>
		<!--- If there are excluded products, get their categories --->
		<cfquery name="FindExcludeGroupIDs" datasource="#application.DS#" cachedwithin="#CreateTimeSpan(0,0,0,0)#">
			SELECT DISTINCT pmgl.product_meta_group_ID 
			FROM #application.product_database#.product_meta_group_lookup pmgl
				JOIN #application.product_database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
				JOIN #application.product_database#.product p ON p.product_meta_ID = pm.ID 
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
	
		<cfquery name="ProdsInGroup_total_all" datasource="#application.DS#" cachedwithin="#CreateTimeSpan(0,0,0,0)#">
				SELECT COUNT(pmgl.ID) AS total 
				FROM #application.product_database#.product_meta_group_lookup pmgl
					JOIN #application.product_database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
					JOIN #application.product_database#.product p ON p.product_meta_ID = pm.ID 
				WHERE pmgl.product_meta_group_ID = #SelectGroups.ThisGroupID# AND is_active = 1
			<cfif is_one_item GT 0>
					AND ( #extrawhere_pvmID_OR# )
			<cfelse>
			 AND #RemoveChars(extrawhere_pvmID_IN,2,6)#
			</cfif>
		</cfquery>
		
		<cfquery name="ProdsInGroup_total_excludes" datasource="#application.DS#" cachedwithin="#CreateTimeSpan(0,0,0,0)#">
			SELECT COUNT(p.ID) AS total 
			FROM #application.product_database#.product_meta_group_lookup pmgl
				JOIN #application.product_database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
				JOIN #application.product_database#.product p ON p.product_meta_ID = pm.ID 
			WHERE p.ID IN (#ExcludedProdID#)
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
		<cfquery name="ProdsInGroup_active_not_discountinued" datasource="#application.DS#" cachedwithin="#CreateTimeSpan(0,0,0,0)#">
			SELECT COUNT(p.ID) AS total 
			FROM #application.product_database#.product_meta_group_lookup pmgl
				JOIN #application.product_database#.product_meta pm ON pmgl.product_meta_ID = pm.ID 
				JOIN #application.product_database#.product p ON p.product_meta_ID = pm.ID 
			WHERE p.is_active = 1 and p.is_discontinued = 0
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
<cfquery name="SelectProgramsAllGroups" datasource="#application.DS#" cachedwithin="#CreateTimeSpan(0,0,0,0)#">
	SELECT name AS group_name, ID AS group_ID
	FROM #application.database#.product_meta_group
	WHERE #extrawhere_groupID_OR# 
	ORDER BY sortorder ASC
</cfquery>

<!--- create the group buttons --->

<!--- NO GROUPS for this category, just the All button --->
<cfif SelectProgramsAllGroups.RecordCount EQ 0>
	<!--- 
	<table cellpadding="0" cellspacing="2" border="0" width="100%">
	<tr>
	<td align="center" width="100" class="selected_group" onClick="window.location='main.cfm?c=#c#&p=#p#'"><b>View All</b></td>
	<td>&nbsp;</td>
	<td align="center" width="100" class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='cart.cfm?c=#c#&p=#p#&g=#g#&OnPage=#OnPage#&cp=#cp#'"><b>View&nbsp;Cart</b></td>
	</tr>
	</table>
	--->
<cfelse>
 	<div style="position: relative; top: -0px; left: -0px; ">
		<cfset total_width = 878>
		<table cellpadding="0" cellspacing="0" border="0" width="<cfoutput>#total_width#</cfoutput>">
			<tr height="40px;">
				<cfset total_cnt = SelectProgramsAllGroups.recordcount>
				<cfset cnt = 1>
				<cfoutput query="SelectProgramsAllGroups">
					<cfif total_width GT 199>
						<cfset this_width = 100>
					<cfelse>
						<cfset this_width = total_width>
					</cfif>
					<cfset total_width = total_width - this_width>
					<cfif g EQ group_ID>
						<td align="center" class="selected_group" width="#this_width#px;"
						<cfif CGI.SCRIPT_NAME CONTAINS "main_prod.cfm">
							onClick="window.location='main.cfm?c=#c#&p=#p#&g=#g#&OnPage=#OnPage#&cp=#cp#'"
						</cfif>	
						>#group_name#</td>
					<cfelse>
						<td align="center" class="active_group" width="#this_width#px;" onMouseOver="mOver(this,'selected_group');" onMouseOut="mOut(this,'active_group');" onClick="window.location='main.cfm?c=#c#&p=#p#&g=#group_ID#&cp=#cp#'">#group_name#</td>
					</cfif>
				</cfoutput>
				<!--- onClick="window.location='cart.cfm?c=#c#&p=#p#&g=#g#&OnPage=#OnPage#&cp=#cp#'">CART --->
			</tr>
		</table>
	</div>
</cfif>
