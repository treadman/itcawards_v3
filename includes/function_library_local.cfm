
<cffunction name="ProgramUserInfo" output="false">
	<cfargument name="ProgramUserInfo_userID" type="string" required="yes">
	<!--- look in the points database for the starting point amount --->
	<cfquery name="PosPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM(points),0) AS pos_pt
		FROM #application.database#.awards_points
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProgramUserInfo_userID#">
		AND is_defered = 0
	</cfquery>
	<!--- look in the order database for orders/points_used --->
	<cfquery name="NegPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) AS neg_pt, IFNULL(SUM(credit_card_charge),0) AS neg_cc
		FROM #application.database#.order_info
		WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProgramUserInfo_userID#">
		AND is_valid = 1
	</cfquery>
	<!--- find defered points --->
	<cfquery name="DefPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM(points),0) AS def_pt
		FROM #application.database#.awards_points
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProgramUserInfo_userID#">
		AND is_defered = 1
	</cfquery>
	<cfset user_awardedpoints = PosPoints.pos_pt>
	<cfset user_usedpoints = NegPoints.neg_pt>
	<cfset user_totalpoints = user_awardedpoints - user_usedpoints>
	<cfset user_deferedpoints = DefPoints.def_pt>
</cffunction>

<cffunction name="GetProgramName" output="false" returntype="string">
	<cfargument name="thisprogramID" type="string" required="yes">
	<cfset var ProgramNameQuery = "">
	<cfquery name="ProgramNameQuery" datasource="#application.DS#">
		SELECT company_name, program_name 
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.thisprogramID#">
	</cfquery>
	<cfreturn HTMLEditFormat(ProgramNameQuery.company_name) & " [" & HTMLEditFormat(ProgramNameQuery.program_name) & "]">
</cffunction>

<cffunction name="FindProductOptions" output="false" returntype="string">
	<cfargument name="FindProductOptions_productID" type="string" required="yes">
	<cfset var FindProdOptionsQuery = "">
	<cfset var ReturnValue = "">
	<!--- FPO_theseoptions --->
	<cfquery name="FindProdOptionsQuery" datasource="#application.DS#">
		SELECT pmo.option_name, pmoc.category_name
		FROM #application.database#.product p
		JOIN #application.database#.product_option po ON p.ID = po.product_ID
			JOIN #application.database#.product_meta_option pmo ON pmo.ID = po.product_meta_option_ID
			JOIN #application.database#.product_meta_option_category pmoc ON pmoc.ID = pmo.product_meta_option_category_ID
		WHERE p.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#FindProductOptions_productID#">
		ORDER BY pmoc.sortorder, pmo.sortorder
	</cfquery>
	<cfif FindProdOptionsQuery.RecordCount NEQ 0>
		<cfloop query="FindProdOptionsQuery">
			<cfset ReturnValue = ReturnValue & " [#category_name#: #option_name#] ">
		</cfloop>
		<cfset ReturnValue = Trim(ReturnValue)>
	</cfif>
	<cfreturn ReturnValue>
</cffunction>

<!--- TODO:  Fix this so it doesn't break encapsulation like it's doing.  Perhaps put the return values in a structure or list. --->
<cffunction name="PhysicalInvCalc" output="false">
	<cfargument name="PIC_prodID" required="yes">
	<!--- total manual adjustments --->
	<cfquery name="PIC_manual" datasource="#application.DS#">
		SELECT SUM(quantity) AS PIC_total_manual
		FROM #application.database#.inventory
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#PIC_prodID#">
			AND is_valid = 1 
			AND quantity <> 0 
			AND snap_is_dropshipped = 0  
			AND order_ID = 0 
			AND ship_date IS NULL 
			AND po_ID = 0
			AND po_rec_date IS NULL 
	</cfquery>
	<!--- total ordered not shipped --->
	<cfquery name="PIC_ordnotshipd" datasource="#application.DS#">
		SELECT SUM(quantity) AS PIC_total_ordnotshipd
		FROM #application.database#.inventory
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#PIC_prodID#">
			AND is_valid = 1 
			AND quantity <> 0 
			AND snap_is_dropshipped = 0  
			AND order_ID <> 0 
			AND ship_date IS NULL 
			AND po_ID = 0
			AND po_rec_date IS NULL 
	</cfquery>
	<!--- total ordered and shipped --->
	<cfquery name="PIC_ordshipd" datasource="#application.DS#">
		SELECT SUM(quantity) AS PIC_total_ordshipd
		FROM #application.database#.inventory
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#PIC_prodID#">
			AND is_valid = 1 
			AND quantity <> 0 
			AND snap_is_dropshipped = 0  
			AND order_ID <> 0 
			AND ship_date IS NOT NULL 
			AND po_ID = 0
			AND po_rec_date IS NULL 
	</cfquery>
	<!--- total po not recvd --->
	<cfquery name="PIC_ponotrec" datasource="#application.DS#">
		SELECT SUM(po_quantity) AS PIC_total_ponotrec
		FROM #application.database#.inventory
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#PIC_prodID#">
			AND is_valid = 1 
			AND quantity = 0 
			AND snap_is_dropshipped = 0  
			AND order_ID = 0 
			AND ship_date IS NULL 
			AND po_ID <> 0
			AND po_rec_date IS NULL 
	</cfquery>
	<!--- total po recvd --->
	<cfquery name="PIC_porec" datasource="#application.DS#">
		SELECT SUM(quantity) AS PIC_total_porec
		FROM #application.database#.inventory
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#PIC_prodID#">
			AND is_valid = 1 
			AND quantity <> 0 
			AND snap_is_dropshipped = 0  
			AND order_ID = 0 
			AND ship_date IS NULL 
			AND po_ID <> 0
			AND po_rec_date IS NOT NULL 
	</cfquery>
	<!--- set variables --->
	<cfif PIC_manual.PIC_total_manual NEQ "">
		<cfset PIC_total_manual = PIC_manual.PIC_total_manual>
	<cfelse>
		<cfset PIC_total_manual = 0>
	</cfif>
	<cfif PIC_ordnotshipd.PIC_total_ordnotshipd NEQ "">
		<cfset PIC_total_ordnotshipd = PIC_ordnotshipd.PIC_total_ordnotshipd>
	<cfelse>
		<cfset PIC_total_ordnotshipd = 0>
	</cfif>
	<cfif PIC_ordshipd.PIC_total_ordshipd NEQ "">
		<cfset PIC_total_ordshipd = PIC_ordshipd.PIC_total_ordshipd>
	<cfelse>
		<cfset PIC_total_ordshipd = 0>
	</cfif>
	<cfif PIC_porec.PIC_total_porec NEQ "">
		<cfset PIC_total_porec = PIC_porec.PIC_total_porec>
	<cfelse>
		<cfset PIC_total_porec = 0>
	</cfif>
	<cfif PIC_ponotrec.PIC_total_ponotrec NEQ "">
		<cfset PIC_total_ponotrec = PIC_ponotrec.PIC_total_ponotrec>
	<cfelse>
		<cfset PIC_total_ponotrec = 0>
	</cfif>
	<cfset PIC_productID = PIC_prodID>
	<cfset PIC_total_physical = (PIC_total_manual + PIC_total_porec) - PIC_total_ordshipd>
	<cfset PIC_total_virtual = (PIC_total_physical + PIC_total_ponotrec) - PIC_total_ordnotshipd>
	<!--- ALL VARIABLES
		PIC_productID
		PIC_total_manual
		PIC_total_ordnotshipd
		PIC_total_ordshipd
		PIC_total_porec
		PIC_total_ponotrec
		PIC_total_physical
		PIC_total_virtual
	 --->
</cffunction>

<cffunction name="CalcPhysicalInventory" output="false" returntype="numeric">
	<cfargument name="CALC_product_ID" required="yes">
	<cfset var PIC_manualQuery = "">
	<cfset var PIC_ordshipdQuery = "">
	<cfset var PIC_total_manual = 0>
	<cfset var PIC_total_ordshipd = 0>
	<!--- total manual adjustments --->
	<cfquery name="PIC_manualQuery" datasource="#application.DS#">
		SELECT SUM(quantity) AS PIC_total_manual
		FROM #application.database#.inventory
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.CALC_product_ID#">
			AND is_valid = 1 
			AND quantity <> 0 
			AND snap_is_dropshipped = 0  
			AND order_ID = 0 
			AND ship_date IS NULL 
			AND (
				(po_ID = 0 AND po_rec_date IS NULL)
				OR
				(po_ID <> 0 AND po_rec_date IS NOT NULL)
				)
	</cfquery>
	<!--- total ordered and shipped --->
	<cfquery name="PIC_ordshipdQuery" datasource="#application.DS#">
		SELECT SUM(quantity) AS PIC_total_ordshipd
		FROM #application.database#.inventory
		WHERE product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.CALC_product_ID#">
			AND is_valid = 1 
			AND quantity <> 0 
			AND snap_is_dropshipped = 0  
			AND order_ID <> 0 
			AND ship_date IS NOT NULL 
			AND po_ID = 0
			AND po_rec_date IS NULL 
	</cfquery>
	<!--- set variables --->
	<cfif PIC_manualQuery.PIC_total_manual NEQ "">
		<cfset PIC_total_manual = PIC_manualQuery.PIC_total_manual>
	</cfif>
	<cfif PIC_ordshipdQuery.PIC_total_ordshipd NEQ "">
		<cfset PIC_total_ordshipd = PIC_ordshipdQuery.PIC_total_ordshipd>
	</cfif>
	<cfreturn (PIC_total_manual - PIC_total_ordshipd)>
</cffunction>

<cffunction name="SelectVendor" output="true">
	<cfargument name="SelectVendor_selected" required="no" default="">
	<cfargument name="SelectVendor_firstoption" required="no" default="-- Select a Vendor --">
	<cfargument name="SelectVendor_selectname" required="no" default="vendor_ID">
	<!--- do query on vendor table --->
	<cfquery name="GetVendorNames" datasource="#application.DS#">
		SELECT ID, vendor 
		FROM #application.database#.vendor
		ORDER BY vendor ASC 
	</cfquery>
	<select name="#SelectVendor_selectname#">
		<option value="">#SelectVendor_firstoption#</option>
		<cfloop query="GetVendorNames">
		<option value="#ID#"<cfif SelectVendor_selected EQ ID> selected</cfif>>#vendor#</option>
		</cfloop>
	</select>
</cffunction>

<cffunction name="ProgramUserInfoConstrained" output="false">
	<cfargument name="cxd_userID" required="yes">
	<cfargument name="cxd_fromdate" required="no" default="">
	<cfargument name="cxd_todate" required="no" default="">
	<!--- look in the points database for the starting point amount --->
	<cfquery name="PosPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM(points),0) AS pos_pt
		FROM #application.database#.awards_points
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#cxd_userID#">
		AND is_defered = 0
		<cfif isDate(cxd_todate)>
			AND created_datetime <= <cfqueryparam value="#cxd_todate#">
		</cfif>
	</cfquery>
	<!--- look in the order database for orders/points_used --->
	<cfquery name="NegPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM((points_used*credit_multiplier)/points_multiplier),0) AS neg_pt, IFNULL(SUM(credit_card_charge),0) AS neg_cc
		FROM #application.database#.order_info
		WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#cxd_userID#">
		AND is_valid = 1
		<cfif isDate(cxd_todate)>
			AND created_datetime <= <cfqueryparam value="#cxd_todate#">
		</cfif>
	</cfquery>
	<!--- find defered points --->
	<cfquery name="DefPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM(points),0) AS def_pt
		FROM #application.database#.awards_points
		WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#cxd_userID#">
		AND is_defered = 1
		<cfif isDate(cxd_todate)>
			AND created_datetime <= <cfqueryparam value="#cxd_todate#">
		</cfif>
	</cfquery>
	<!--- was last order within the date range --->
	<cfquery name="CheckOrderDate" datasource="#application.DS#">
		SELECT created_datetime 
		FROM #application.database#.order_info
		WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#cxd_userID#">
		AND is_valid = 1
		<cfif isDate(cxd_fromdate)>
			AND created_datetime >= <cfqueryparam value="#cxd_fromdate#">
		</cfif>
		<cfif isDate(cxd_todate)>
			AND created_datetime <= <cfqueryparam value="#cxd_todate#">
		</cfif>
		ORDER BY created_datetime DESC
		LIMIT 1
	</cfquery>
	<cfif CheckOrderDate.RecordCount EQ 0>
		<cfset BRp_order_in_range = false>
		<cfset BRp_last_order = "">
	<cfelse>
		<cfset BRp_order_in_range = true>
		<cfset BRp_last_order = FLGen_DateTimeToDisplay(CheckOrderDate.created_datetime)>
	</cfif>
	<cfset BRp_pospoints = PosPoints.pos_pt>
	<cfset BRp_negpoints = NegPoints.neg_pt>
	<cfset BRp_totalpoints = PosPoints.pos_pt - NegPoints.neg_pt>
	<cfset BRp_deferedpoints = DefPoints.def_pt>
</cffunction>


<cffunction name="hasOrdersUnassignedPoints">
	<!--- TODO: This is only making sure that at least SOME of the points have been assigned.
				Add a check of total points on order
				see includes/function_library_local.unassigned_orders --->
	<cfset var has_unassigned = false>
	<cfquery name="getOrders1" datasource="#application.DS#">
		SELECT COUNT(totalperdiv) AS totalbydiv
		FROM (
			SELECT COUNT(o.ID) as totalperdiv
			FROM #application.database#.xref_order_division x
			LEFT JOIN #application.database#.order_info o on x.order_ID = o.ID
			LEFT JOIN #application.database#.program p ON p.ID = x.division_ID
			WHERE o.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
			AND o.is_valid = 1
			AND o.points_used > 0
			GROUP BY o.ID
		) q
	</cfquery>
	<!---<cfdump var="#getOrders1#">--->
	<cfquery name="getOrders2" datasource="#application.DS#">
		SELECT COUNT(o.ID) as totalbymain
		FROM #application.database#.order_info o
		WHERE o.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
		AND o.is_valid = 1
		AND o.points_used > 0
	</cfquery>
	<!---<cfdump var="#getOrders2#">--->
	<cfif getOrders1.totalbydiv NEQ getOrders2.totalbymain>
		<cfset has_unassigned = true>
	</cfif>	
	<cfreturn has_unassigned>
</cffunction>

<cffunction name="hasUserUnassignedPoints">
	<cfset var GetDivisionPoints = ''>
	<cfquery name="GetDivisionPoints" datasource="#application.DS#">
		SELECT IFNULL(SUM(a.points),0) AS total, a.division_id, p.company_name, d.program_name as division_name
		FROM #application.database#.awards_points a
		LEFT JOIN #application.database#.program_user u ON u.ID = a.user_ID
		LEFT JOIN #application.database#.program d ON d.ID = a.division_ID
		LEFT JOIN #application.database#.program p ON p.ID = u.program_ID
		WHERE u.program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		AND a.division_ID = 0
		GROUP BY a.division_id
		ORDER BY a.division_id
	</cfquery>
	<cfreturn GetDivisionPoints>
</cffunction>