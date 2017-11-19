<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">
<cfinclude template="includes/function_library_local.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<!--- c=category (productvalue_program_ID), p=productvalueID (productvalue_master_ID), g=group (?) --->
<cfparam name="url.p" default="">
<cfparam name="g" default="">
<cfparam name="c" default="">

<cfparam name="extrawhere_SelectDisplayProducts" default="">
<cfparam name="extrawhere_SelectProgramsAllGroups" default="">
<cfparam name="FirstEndRow" default="">
<cfparam name="OnPage" default="1">
<cfif NOT isNumeric(OnPage)>
	<cfset OnPage = 1>
</cfif>

<cfparam name="prod" default="">
<cfif not isNumeric(prod)>
	<cflocation url="main.cfm?c=#c#&p=#p#&g=#g#&OnPage=#OnPage#&div=#request.division_ID#" addtoken="no">
</cfif>

<cfinclude template="includes/header.cfm">

<cfquery name="SelectProductInfo" datasource="#application.DS#">
	SELECT pm.meta_name, pm.description, pm.imagename, logoname, product_set_ID
	FROM #application.database#.product_meta pm
	LEFT JOIN #application.database#.manuf_logo ml ON pm.manuf_logo_ID = ml.ID
	WHERE pm.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#prod#" maxlength="10">
		<cfif product_set_IDs NEQ "">
			AND pm.product_set_ID IN (#product_set_IDs#)
		<cfelse>
			AND 1 = 2
		</cfif>
</cfquery>
<cfset meta_name = SelectProductInfo.meta_name>
<cfset description = SelectProductInfo.description>
<cfset imagename = HTMLEditFormat(SelectProductInfo.imagename)>
<cfset logoname = HTMLEditFormat(SelectProductInfo.logoname)>
<cfset product_set_ID = SelectProductInfo.product_set_ID>
<cfquery name="SelectProductCat" datasource="#application.DS#">
	SELECT category_name, ID
	FROM #application.database#.product_meta_option_category
	WHERE product_meta_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#prod#" maxlength="10">
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
	FROM #application.database#.product p
	LEFT JOIN #application.database#.product_option po ON p.ID = po.product_ID
		LEFT JOIN #application.database#.product_meta_option pmo ON po.product_meta_option_ID = pmo.ID
		LEFT JOIN #application.database#.product_meta_option_category pmoc ON pmo.product_meta_option_category_ID = pmoc.ID
	WHERE p.product_meta_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#prod#" maxlength="10"> 
		AND is_active = 1 
		AND is_discontinued = 0 
		 #narrow_results#
	ORDER BY p.sortorder, pmoc.sortorder
</cfquery>
<cfif SelectEachProduct.recordcount GT 0>
	<cfset PhysicalInvCalc(SelectEachProduct.product_ID)>
	<!---<cfoutput>
		#PIC_productID#<br>
		#PIC_total_manual#<br>
		#PIC_total_ordnotshipd#<br>
		#PIC_total_ordshipd#<br>
		#PIC_total_porec#<br>
		#PIC_total_ponotrec#<br>
		#PIC_total_physical#<br>
		#PIC_total_virtual#<br>
	</cfoutput>--->
</cfif>
<!--- PRODUCT DISPLAY --->
<table cellpadding="0" cellspacing="1" border="0" width="700">
	<tr>
		<td class="product_name" width="100%"><cfoutput>#meta_name#</cfoutput></td>
		<td>&nbsp;</td>
		<cfoutput><td align="center" class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='cart.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'"><b>&nbsp;&nbsp;#Translate(language_ID,'view_cart_button')#&nbsp;&nbsp;</b></td></cfoutput>
	</tr>
</table>
<table cellpadding="0" cellspacing="0" border="0" width="700">
<tr>
<td align="center" width="50%" valign="top"><img src="<cfoutput><cfif product_set_ID EQ 1>#application.ProductSetOneURL#/</cfif>pics/products/#imagename#</cfoutput>" style="margin: 10px 10px 10px 0px"><br><img src="pics/<cfif logoname EQ "">shim.gif<cfelse>manuf_logos/<cfoutput>#logoname#</cfoutput></cfif>"></td>
<td valign="top" width="50%">
	<br>
	<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr>
	<td valign="top" class="product_description"><cfoutput><span class="product_instructions"><b>#Translate(language_ID,'description_text')#:</b></span><br>#Replace(description,chr(13) & chr(10),"<br>","ALL")#</cfoutput><br><br></td>
	</tr>
	<!--- ***************************   --->
	<!--- Multi Product Meta Select     --->
	<!--- ***************************   --->
	<cfif SelectProductCat.RecordCount NEQ 0>


<!--- TODO: Add show_price to admin 
	
	Set up a better way to do this.  It is duplicated below in the single product selection.
	
	--->
			<cfset show_price = true>
			<cfif show_price>

		<cfset ThisPValue = 1000000>
		<!--- get the product's value --->
		<cfquery name="FindProdValue" datasource="#application.DS#">
			SELECT IFNULL(pvm.productvalue,0) AS masterCatValue, pm.productvalue, pm.retailvalue, p.productvalue AS override,
				pm.meta_name AS meta_name, pm.description AS description, p.sku AS sku, p.is_dropshipped, pm.never_show_inventory
			FROM #application.database#.product p
			JOIN #application.database#.product_meta pm ON pm.ID = p.product_meta_ID
			LEFT JOIN #application.database#.productvalue_master pvm ON pvm.ID = pm.productvalue_master_ID
			WHERE p.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectEachProduct.product_ID#">
		</cfquery>
		<cfif use_master_categories EQ 0 OR use_master_categories EQ 3>
			<!--- Value is from master categories --->
			<cfif FindProdValue.masterCatValue GT 0>
				<cfset ThisPValue = FindProdValue.masterCatValue>
			</cfif>
		<cfelse>
			<!--- Value is from product value --->
			<cfif isNumeric(FindProdValue.override) AND FindProdValue.override GT 0>
				<cfset ThisPValue = FindProdValue.override>
			<cfelseif FindProdValue.productvalue GT 0>
				<cfset ThisPValue = FindProdValue.productvalue>
			</cfif>
		</cfif>
					<tr>
					<td>
						<p>
							Price <b><cfoutput><cfif credit_desc EQ "$">#credit_desc#</cfif>#ThisPValue*points_multiplier#<cfif credit_desc NEQ "$"> #credit_desc#</cfif></cfoutput></b>
						<cfif isNumeric(FindProdValue.retailvalue) AND FindProdValue.retailvalue GT 0>
							<br><br>Retail Price <b><cfoutput><cfif credit_desc EQ "$">#credit_desc#</cfif>#FindProdValue.retailvalue*points_multiplier#<cfif credit_desc NEQ "$"> #credit_desc#</cfif></cfoutput></b>
						</cfif>
						</p><br>
					</td>
				</tr>
			</cfif>

<!--- TODO:  SHOW PRICE end --->

		<tr>
		<td valign="top" class="active_cell" style="padding:5px ">
			<cfoutput>
			<cfif SelectProductCat.RecordCount EQ 1>
				<!---x--->#Translate(language_ID,'select_option_single')#
			<cfelse>
				<!---y--->#Translate(language_ID,'select_option_plural')#
			</cfif>
			</cfoutput>
		</td>
		</tr>

		<tr>
		<td valign="top">
			<cfoutput>
			<form method="post" action="#CurrentPage#?p=#url.p#&div=#request.division_ID#">
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
					<td align="right">#category_name#: </td>
					<td valign="top">
						<select name="cat_#cat_ID#"  onChange="submit()">
							<option value="">-- <!---z--->#Replace(Translate(language_ID,'select_one_option'),'[category_name]',category_name)# --</option>
						<cfloop query="SelectOptions">
							<cfset ThisFormField = "form.cat_" & cat_ID>
							<cfif IsDefined('Form.FieldNames') AND Form.FieldNames IS NOT "">
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
				<input type="hidden" name="prod" value="#prod#">
				<input type="hidden" name="c" value="#c#">
				<input type="hidden" name="g" value="#g#">
				<input type="hidden" name="OnPage" value="#OnPage#">
				<input type="hidden" name="set" value="#set#">
			</form>
			</cfoutput>
			<table cellpadding="3" cellspacing="0" border="0" width="100%">
				<cfif IsDefined('Form.FieldNames') AND Form.FieldNames IS NOT "">
					<tr>
					<td colspan="2" class="alert" align="right"><cfoutput><a href="#CurrentPage#?prod=#prod#&c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#">#Translate(language_ID,'clear_options')#</a></cfoutput></td>
					</tr>
				</cfif>
				<cfif SelectEachProduct.RecordCount EQ 0>
					<tr>
					<td colspan="2" class="alert" align="center">
						<cfoutput>#ListGetAt(sss,2)# #Translate(language_ID,'is_not_available')# #ListGetAt(sss,1)#.</cfoutput>
					</td>
					</tr>
				</cfif>
				<!--- set var that indicates that only one prod was found --->
				<cfif SelectProductCat.RecordCount EQ 0>
					<cfset thismeansone = 1>
				<cfelse>
					<cfset thismeansone = SelectProductCat.RecordCount>
				</cfif>
				<!--- only display products if one and only one found --->
				<cfif SelectEachProduct.RecordCount EQ thismeansone>
					<cfif NOT FindProdValue.never_show_inventory AND show_inventory EQ 1 or show_inventory EQ 3>
						<tr>
							<td><p><b>Available Quantity: <cfoutput>#PIC_total_virtual#</cfoutput></b></p><br></td>
						</tr>
					</cfif>
					<cfif inactivate_zero_inventory AND PIC_total_virtual LTE 0>
						<tr>
						<td colspan="2" class="alert" align="center">
							<cfif sss neq "">
								<cfset options_text = "">
								<cfloop list="#sss#" index="x">
									<cfset options_text = options_text & x & " ">
								</cfloop>
								<cfoutput>#Replace(Translate(language_ID,'sold_out_options'),'[options_text]',options_text)#</cfoutput>
							<cfelse>
								<cfoutput>#Translate(language_ID,'sold_out_generic')#</cfoutput>
							</cfif>
						</td>
						</tr>
					<cfelse>
						<cfoutput query="SelectEachProduct" group="product_ID">
							<tr>
							<td style="border-width:1px 0px 1px 1px; border-style:solid; border-color:###bg_active#">
								<table cellpadding="2" cellspacing="0" border="0">
								<tr>
								<td align="right">#SelectEachProduct.category_name#: </td>
								<td><b>#SelectEachProduct.option_name#</b></td>
								</tr>
								</table>
							</td>
							<td style="border-width:1px 1px 1px 0px; border-style:solid; border-color:###bg_active#">
								<table cellpadding="8" cellspacing="0" border="0">
									<tr>
									<td class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');"  onClick="window.location='cart.cfm?iprod=#product_ID#&prod=#prod#&c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'"><!---a--->#Translate(language_ID,'select_this_gift')#</td>
									</tr>
								</table>
							</td>
							</tr>
							<tr><td colspan="2"><img src="pics/shim.gif" width="1" height="1"></td></tr>
						</cfoutput>
					</cfif>
				</cfif>
			</table>
		</td>
		</tr>
	<cfelse>
		<!--- *************************** --->
		<!--- One Product Meta Select     --->
		<!--- *************************** --->
		<cfoutput query="SelectEachProduct" group="product_ID">

<!--- TODO: Add show_price to admin 
	
	Set up a better way to do this.  It is duplicated above in the multiple product selection.
	
	--->
			<cfset show_price = true>
			<cfif show_price>

		<cfset ThisPValue = 1000000>
		<!--- get the product's value --->
		<cfquery name="FindProdValue" datasource="#application.DS#">
			SELECT IFNULL(pvm.productvalue,0) AS masterCatValue, pm.productvalue, pm.retailvalue, p.productvalue AS override,
				pm.meta_name AS meta_name, pm.description AS description, p.sku AS sku, p.is_dropshipped, pm.never_show_inventory
			FROM #application.database#.product p
			JOIN #application.database#.product_meta pm ON pm.ID = p.product_meta_ID
			LEFT JOIN #application.database#.productvalue_master pvm ON pvm.ID = pm.productvalue_master_ID
			WHERE p.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#SelectEachProduct.product_ID#">
		</cfquery>
		<cfif use_master_categories EQ 0 OR use_master_categories EQ 3>
			<!--- Value is from master categories --->
			<cfif FindProdValue.masterCatValue GT 0>
				<cfset ThisPValue = FindProdValue.masterCatValue>
			</cfif>
		<cfelse>
			<!--- Value is from product value --->
			<cfif isNumeric(FindProdValue.override) AND FindProdValue.override GT 0>
				<cfset ThisPValue = FindProdValue.override>
			<cfelseif FindProdValue.productvalue GT 0>
				<cfset ThisPValue = FindProdValue.productvalue>
			</cfif>
		</cfif>
			<cfif NOT FindProdValue.never_show_inventory AND (show_inventory EQ 1 or show_inventory EQ 3)>
				<tr>
					<td><p><b>Available Quantity: #PIC_total_virtual#</b></p><br></td>
				</tr>
			</cfif>


					<tr>
					<td>
						<p>
							Price <b><cfoutput>#ThisPValue*points_multiplier# #credit_desc#</cfoutput></b>
						<cfif isNumeric(FindProdValue.retailvalue) AND FindProdValue.retailvalue GT 0>
							<br><br>Retail Price <b><cfoutput>#FindProdValue.retailvalue*points_multiplier# #credit_desc#</cfoutput></b>
						</cfif>
						</p><br>
					</td>
	
					<tr>
				</tr>
			</cfif>



<!--- TODO:  SHOW PRICE end --->


			<tr>
			<td>
				<table cellpadding="8" cellspacing="0" border="0">
					<tr>
					<td class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');"  onClick="window.location='cart.cfm?iprod=#product_ID#&prod=#prod#&c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'">#Translate(language_ID,'select_this_gift')#</td>
					</tr>
				</table>
			</td>
			</tr>
			<tr><td colspan="2"><img src="pics/shim.gif" width="1" height="1"></td>
			</tr>
		</cfoutput>
	</cfif>
	</table>
</td>
</tr>
</table>

<cfinclude template="includes/footer.cfm">
