<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000014-1000000020",true)>

<!--- param search criteria xxS=ColumnSort xxT=SearchString xxL=Letter --->
<cfparam name="xxS" default="username">
<cfparam name="xxT" default="">
<cfparam name="xxL" default="">
<cfparam name="xxA" default="">
<cfparam name="xOnPage" default="1">
<cfparam name="puser_ID" default="0">
<cfparam name="prod_id" default="">

<cfparam name="url.reorder" default="0">
<cfif url.reorder EQ "1">
	<cfquery name="ResetUser" datasource="#application.DS#">
		UPDATE #application.database#.program_user
		SET is_done = 0
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">
	</cfquery>
	<cfquery name="GetOrders" datasource="#application.DS#">
		SELECT ID
		FROM #application.database#.order_info
		WHERE created_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">
	</cfquery>
	<cfif GetOrders.recordCount gt 0>
		<cfset order_nums = ValueList(GetOrders.ID)>
		<cfquery name="DeleteOrders" datasource="#application.DS#">
			DELETE FROM #application.database#.order_info
			WHERE ID IN (#order_nums#)
		</cfquery>
		<cfquery name="DeleteInvs" datasource="#application.DS#">
			DELETE FROM #application.database#.inventory
			WHERE order_ID IN (#order_nums#)
		</cfquery>
	</cfif>
</cfif>

<cfset has_user = false>
<cfquery name="GetUser" datasource="#application.DS#">
	SELECT username, fname, lname, nickname, email, phone, is_active, is_done, expiration_date,
		cc_max, defer_allowed, ship_address1, ship_address2, ship_city, ship_state,  ship_zip,
		bill_fname, bill_lname, bill_address1, bill_address2, bill_city, bill_state,  bill_zip,
		entered_by_program_admin, supervisor_email, level_of_award
	FROM #application.database#.program_user
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#">
</cfquery>
<cfif GetUser.recordcount EQ 1>
	<cfset has_user = true>
</cfif>

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->
<cfset order_placed = false>
<cfif has_program AND has_user AND isDefined("form.save_order")>
	<cfset order_ID = "">
	<cfquery name="GetLastProgramOrderNumber" datasource="#application.DS#">
		SELECT Max(order_number) As MaxID
		FROM #application.database#.order_info
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cfset order_number = IncrementValue(GetLastProgramOrderNumber.MaxID)>
	<cflock name="order_infoLock" timeout="10">
		<cftransaction>
			<cfset aToday = FLGen_DateTimeToMySQL()>
			<cfquery name="StartOrder" datasource="#application.DS#" result="stResult">
				INSERT INTO #application.database#.order_info (
					created_user_ID,
					created_datetime,
					program_ID,
					is_valid,
					order_number,
					snap_fname,
					snap_lname,
					snap_phone,
					snap_email,
					points_used
				)
				VALUES (
					<cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">,
					'#FLGen_DateTimeToMySQL()#',
					<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">,
					1,
					<cfqueryparam cfsqltype="cf_sql_integer" value="#order_number#" maxlength="10">,
					'#GetUser.fname#',
					'#GetUser.lname#',
					'#GetUser.phone#',
					'#GetUser.email#',
					0
				)
			</cfquery>
			<cfset order_ID = stResult.GENERATED_KEY>
		</cftransaction>  
	</cflock>
	<cfquery name="GetProduct" datasource="#application.DS#">
		SELECT meta_name, productvalue, meta_sku, description
		FROM #application.database#.product_meta
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#prod_ID#">
	</cfquery>
	<cfset catList = "">
	<cfset optList = "">
	<cfset this_options = "">
	<cfloop index="thisField" list="#Form.FieldNames#">
		<cfif thisField contains "cat_" and Evaluate(thisField) NEQ "">
			<cfset this_options = this_options & "[">
			<cfset thisCat = ListLast(thisField,'_')>
			<cfset catList = ListAppend(catList,thisCat)>
			<cfset thisOpt = ListLast(Evaluate(thisField),'_')>
			<cfset optList = ListAppend(optList,thisOpt)>
			<cfquery name="GetCat" datasource="#application.DS#">
				SELECT category_name
				FROM #application.database#.product_meta_option_category
				WHERE ID = #thisCat#
			</cfquery>
			<cfset this_options = this_options & GetCat.category_name & ": ">
			<cfquery name="GetOpt" datasource="#application.DS#">
				SELECT option_name
				FROM #application.database#.product_meta_option
				WHERE ID = #thisOpt#
			</cfquery>
			<cfset this_options = this_options & GetOpt.option_name & "]  ">
		</cfif>
	</cfloop>
	<cfset this_num = ListLen(optList) - 1>
	<cfquery name="GetProductID" datasource="#application.DS#">
		SELECT product_ID, count(*) as num
		FROM #application.database#.product_option
		WHERE product_meta_option_ID = #ListGetAt(optList,1)#
		<cfif ListLen(optList) GT 1>
			OR product_meta_option_ID = #ListGetAt(optList,2)#
		</cfif>
		GROUP BY product_ID
		HAVING num > #this_num#
	</cfquery>
	<cfquery name="GetProductOption" datasource="#application.DS#">
		SELECT sku
		FROM #application.database#.product
		WHERE ID = #GetProductID.product_ID#
	</cfquery>
	<cfquery name="InsertProduct" datasource="#application.DS#">
		INSERT INTO #application.database#.inventory (
			created_user_ID,
			created_datetime,
			product_ID,
			order_ID,
			quantity,
			snap_meta_name,
			snap_sku,
			snap_description,
			snap_options,
			snap_is_dropshipped,
			is_valid
		)
		VALUES (
			<cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">,
			'#FLGen_DateTimeToMySQL()#',
			<cfqueryparam cfsqltype="cf_sql_integer" value="#GetProductID.product_ID#" maxlength="10">,
			<cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">,
			1,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#GetProduct.meta_name#" maxlength="64">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#GetProductOption.sku#" maxlength="64">,
			<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#GetProduct.description#">,
			<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#trim(this_options)#">,
			0,
			1
		)
	</cfquery>
	<cfquery name="SaveOrderInfo" datasource="#application.DS#">
		UPDATE #application.database#.program_user
		SET	is_done = 1
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#puser_ID#" maxlength="10">
	</cfquery>

	<cfif Application.OverrideEmail NEQ "">
		<cfset this_to = Application.OverrideEmail>
	<cfelse>
		<cfset this_to = GetUser.email>
	</cfif>
	<cfmail to="#this_to#" from="#Application.DefaultEmailFrom#" subject="Thank you for your #request.program.company_name# Award Program order" failto="#Application.OrdersFailTo#">
		<cfif Application.OverrideEmail NEQ "">
			Emails are being overridden.<br>
			Below is the email that would have been sent to #GetUser.email#<br>
			<hr>
		</cfif>
#DateFormat(Now(),"mm/dd/yyyy")#

Thank you for your #request.program.company_name# Award Program order.

Order #order_ID# for #GetUser.fname# #GetUser.lname# (#GetUser.email#)

ITEM IN ORDER:
#GetProduct.meta_name# #trim(this_options)#

	</cfmail>
	<cfset order_placed = true>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "program_user">
<cfinclude template="includes/header.cfm">


<cfoutput>
<cfif has_user>
	<span class="pagetitle">Place Order for #GetUser.fname# #GetUser.lname# in #request.program_name#</span>
	<br /><br />
</cfif>
<cfif not order_placed>
	<span class="pageinstructions">Return to the <a href="program_user.cfm?xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">Program Users List</a> without making changes.</span>
	<br /><br />
</cfif>
</cfoutput>

<cfif NOT has_user>
	<span class="alert">User not found!</span>
<cfelseif NOT has_program>
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelseif GetUser.is_done>
	<span class="alert">User has already ordered.</span>
<cfelseif order_placed>
	<br><span class="pageinstructions">Order has been placed.</span>
	<br><br>
	<span class="pageinstructions">Return to the <cfoutput><a href="program_user.cfm?xxS=#xxS#&xxA=#xxA#&xxL=#xxL#&xxT=#xxT#&xOnPage=#xOnPage#">Program Users List</a></cfoutput>.</span>
	<br /><br />
<cfelse>
<cfparam name="these_assigned_cats" default="">
<cfparam name="extrawhere_pvmID_IN" default="">
<cfparam name="ExcludedProdGroups" default="">
<cfparam name="ExcludedProdID" default="">
<cfparam name="extrawhere_groupID_OR" default="">
<cfparam name="show_this_group" default="true">

<cfquery name="SelectCountExcludes" datasource="#application.DS#">
	SELECT COUNT(ID) AS number_of_excludes 
	FROM #application.database#.program_product_exclude
	WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
</cfquery>
<cfquery name="GetSets" datasource="#application.DS#">
	SELECT product_set_ID
	FROM #application.database#.xref_program_product_set
	WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
</cfquery>
<cfset product_set_IDs = ValueList(GetSets.product_set_ID)>
<cfif product_set_IDs NEQ "">
	<cfquery name="SelectDisplayProducts" datasource="#application.DS#">
		SELECT DISTINCT pm.ID AS meta_ID, pm.meta_name AS meta_name, pm.thumbnailname AS thumbnailname, pm.productvalue, pm.product_set_ID
		FROM #application.database#.product_meta pm JOIN #application.database#.product p ON pm.ID = p.product_meta_ID
		WHERE p.is_active = 1 AND p.is_discontinued = 0 
		AND pm.product_set_ID IN (#product_set_IDs#)
			<cfif SelectCountExcludes.number_of_excludes GT 0>
				AND ((SELECT COUNT(ID) FROM #application.database#.program_product_exclude ppe WHERE ppe.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10"> AND ppe.product_ID = p.ID) = 0) 
			</cfif>
		ORDER BY pm.sortorder ASC
	</cfquery>

</cfif>

<cfif isDefined("SelectDisplayProducts")>
	<br><br>
	<!--- display products --->
	<cfif SelectDisplayProducts.RecordCount EQ 0>
		<span class="alert">No products found.</span><br /><br />
	<cfelse>
		<form action="<cfoutput>#CurrentPage#</cfoutput>" method="post">
			<cfoutput>
			<input type="hidden" name="xxL" value="#xxL#">
			<input type="hidden" name="xxS" value="#xxS#">
			<input type="hidden" name="xxA" value="#xxA#">
			<input type="hidden" name="xxT" value="#xxT#">
			<input type="hidden" name="xOnPage" value="#xOnPage#">
			<input type="hidden" name="puser_ID" value="#puser_ID#">
			<select name="prod_id" onChange="form.submit();">
				<option value="">--- Select Product ---</option>
				<cfloop query="SelectDisplayProducts">
					<option value="#meta_ID#" <cfif prod_id EQ meta_id>selected</cfif>>#meta_name#</option>
				</cfloop>
			</select>
			</cfoutput>
			<cfif isNumeric(prod_id)>

				<cfquery name="SelectProductInfo" datasource="#application.DS#">
					SELECT pm.meta_name, pm.description, pm.imagename, pm.thumbnailname, logoname, product_set_ID
					FROM #application.database#.product_meta pm LEFT JOIN #application.database#.manuf_logo ml ON pm.manuf_logo_ID = ml.ID
					WHERE pm.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#prod_id#" maxlength="10">
						<cfif product_set_IDs NEQ "">
							AND pm.product_set_ID IN (#product_set_IDs#)
						<cfelse>
							AND 1 = 2
						</cfif>
				</cfquery>
				<cfset meta_name = SelectProductInfo.meta_name>
				<cfset description = SelectProductInfo.description>
				<cfset thumbnailname = HTMLEditFormat(SelectProductInfo.thumbnailname)>
				<cfset logoname = HTMLEditFormat(SelectProductInfo.logoname)>
				<cfset product_set_ID = SelectProductInfo.product_set_ID>
				<cfquery name="SelectProductCat" datasource="#application.DS#">
					SELECT category_name, ID
					FROM #application.database#.product_meta_option_category
					WHERE product_meta_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#prod_id#" maxlength="10">
					ORDER BY sortorder
				</cfquery>
				<!--- narrow the results based on the dropdown --->
				<cfset narrow_results = "">
				<cfif IsDefined('Form.FieldNames') AND #Form.FieldNames# IS NOT "">
					<cfloop index="thisField" list="#Form.FieldNames#">
						<cfif thisField contains "cat_" and Evaluate(thisField) NEQ ""> 
							<cfset narrow_results = narrow_results & " AND #RemoveChars(Evaluate(thisField),1,4)#  IN (SELECT po.product_meta_option_ID FROM #application.database#.product_option po WHERE product_ID = p.ID) ">
						</cfif>
					</cfloop>
				</cfif>
				<cfquery name="SelectEachProduct" datasource="#application.DS#">
					SELECT pmo.option_name, pmoc.category_name, p.ID AS product_ID
					FROM #application.database#.product p LEFT JOIN #application.database#.product_option po ON p.ID = po.product_ID
						LEFT JOIN #application.database#.product_meta_option pmo ON po.product_meta_option_ID = pmo.ID
						LEFT JOIN #application.database#.product_meta_option_category pmoc ON pmo.product_meta_option_category_ID = pmoc.ID
					WHERE p.product_meta_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#prod_id#" maxlength="10"> 
						AND is_active = 1 
						AND is_discontinued = 0 
						 #narrow_results#
					ORDER BY p.sortorder, pmoc.sortorder
				</cfquery>
				<!--- PRODUCT DISPLAY --->
				
				<table cellpadding="0" cellspacing="0" border="0" width="500">
				<tr>
				<td align="center" width="50%" valign="top"><img src="<cfoutput><cfif product_set_ID EQ 1>#application.ProductSetOneURL#/</cfif>/pics/products/#thumbnailname#</cfoutput>" style="margin: 10px 10px 10px 0px"></td>
				<td valign="top" width="50%">
					<br>
					<table cellpadding="0" cellspacing="0" border="0" width="100%">
					<tr>
					<td valign="top" class="product_description"><span class="product_instructions"><b>Description:</b></span><br><cfoutput>#Replace(description,chr(13) & chr(10),"<br>","ALL")#</cfoutput><br><br></td>
					</tr>
					<!--- ***************************   --->
					<!--- Multi Product Meta Select     --->
					<!--- ***************************   --->
					<cfif SelectProductCat.RecordCount NEQ 0>
						<tr>
						<td valign="top" class="active_cell" style="padding:5px ">Select one option from <cfif SelectProductCat.RecordCount EQ 1>the<cfelse>each</cfif> dropdown.</td>
						</tr>
						<tr>
						<td valign="top">
							<cfoutput>
								<table width="100%" cellpadding="5" cellspacing="0" border="0">
								<cfset sss = "">
								<cfloop query="SelectProductCat">
									<cfset category_name = HTMLEditFormat(SelectProductCat.category_name)>
									<cfset cat_ID = HTMLEditFormat(SelectProductCat.ID)>
									<cfquery name="SelectOptions" datasource="#application.DS#">
										SELECT pmo.option_name, pmo.ID AS opt_ID
										FROM #application.database#.product_meta_option pmo
										WHERE pmo.product_meta_option_category_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#cat_ID#" maxlength="10">
											AND (SELECT COUNT(prod.ID) FROM #application.database#.product prod JOIN #application.database#.product_option po ON prod.ID =  po.product_ID WHERE po.product_meta_option_ID = pmo.ID AND prod.is_active = 1 AND prod.is_discontinued = 0) > 0
										ORDER BY pmo.sortorder ASC 
									</cfquery>
									<tr>
									<td valign="top" align="right">#category_name#: </td>
									<td valign="top">
										<select name="cat_#cat_ID#"  onChange="form.submit()">
											<option value="">-- SELECT ONE #category_name# option --</option>
										<cfloop query="SelectOptions">
											<cfset ThisFormField = "form.cat_" & cat_ID>
											<cfif IsDefined(ThisFormField)>
												<cfset if_selected = IIF(Evaluate(ThisFormField) EQ "opt_" & SelectOptions.opt_ID, DE(" selected"),DE(""))>
											<cfelse>
												<cfset if_selected = "">
											</cfif>
											<cfif if_selected neq "">
												<cfset sss = ListAppend(sss,option_name)>
											</cfif>
												<option value="opt_#SelectOptions.opt_ID#"#if_selected#>#option_name#</option>
										</cfloop>
										</select>
									</td>
									</tr>
								</cfloop>
								</table>
							</cfoutput>
							<table cellpadding="3" cellspacing="0" border="0" width="100%">
				
								<cfif SelectEachProduct.RecordCount EQ 0 AND ListLen(sss) GT 1>
									<tr>
									<td colspan="2" class="alert" align="center"><cfoutput>#ListGetAt(sss,2)# is not available in #ListGetAt(sss,1)#.</cfoutput></td>
									</tr>
								</cfif>
								<!--- oset var that indicates that only one prod was found --->
								<cfif SelectProductCat.RecordCount EQ 0>
									<cfset thismeansone = 1>
								<cfelse>
									<cfset thismeansone = SelectProductCat.RecordCount>
								</cfif>
								<!--- only display products if one and only one found --->
								<cfif SelectEachProduct.RecordCount EQ thismeansone>
									<input type="submit" name="save_order" value="   Place Order   ">
								</cfif>
							</table>
						</td>
						</tr>
					</cfif>
					</table>

			</cfif>
		</form>
	</cfif>
<cfelse>
	<span class="alert">Error finding products.</span>
</cfif>

</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->




