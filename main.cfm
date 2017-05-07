<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">
<cfinclude template="includes/function_library_local.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<!--- Get number of items in the cart --->
<cfset CartItemCount()>

<cfif is_one_item GT 0>
	<cfparam name="c" default="">
<cfelse>
	<cfparam name="c" default="#default_category#">
</cfif>

<!--- TODO: This goes in programs table: --->
<cfset default_group_id = "">
<cfif program_ID EQ "1000000101">
	<cfset default_group_id = "1000000050">
</cfif>

<cfparam name="url.p" default="">
<cfparam name="g" default="#default_group_id#">
<cfparam name="OnPage" default="1">
<cfif NOT isNumeric(OnPage)>
	<cfset OnPage = 1>
</cfif>

<cfset thisSearchText = "">
<cfif isDefined("cookie.search")>
	<cfif g NEQ "" or isDefined("url.clear")>
		<!--- They selected a group. Delete the search cookie --->
		<cfcookie name="search" expires="now">
	<cfelse>
		<!--- Use the search cookie --->
		<cfset thisSearchText = cookie.search>
	</cfif>
</cfif>
<cfset thisProductValue = "">
<cfif isDefined("cookie.prodval")>
	<cfif g NEQ "" or isDefined("url.clear")>
		<!--- They selected a group. Delete the search cookie --->
		<cfcookie name="prodval" expires="now">
	<cfelse>
		<!--- Use the search cookie --->
		<cfset thisProductValue = cookie.prodval>
	</cfif>
</cfif>
<cfif isDefined("url.clear")>
	<cfcookie name="filter" expires="now">
</cfif>

<cfif g NEQ "" OR thisSearchText NEQ "" OR thisProductValue NEQ "">
	<cfset show_landing_text = false>
</cfif>

<cfparam name="these_assigned_cats" default="">
<cfparam name="extrawhere_pvmID_IN" default="">
<cfparam name="extrawhere_pvmID_OR" default="">
<cfparam name="ExcludedProdGroups" default="">
<cfparam name="ExcludedProdID" default="">
<cfparam name="extrawhere_groupID_OR" default="">
<cfparam name="show_this_group" default="true">

<cfparam name="FirstEndRow" default="">


<cfinclude template="includes/header.cfm">
<cfswitch expression="#use_master_categories#">
	<cfcase value="0">
		<cfinclude template="includes/master_category_groups.cfm">
	</cfcase>
	<cfcase value="1,2,4">
		<cfinclude template="includes/product_group_groups.cfm">
	</cfcase>
	<cfcase value="3">
		<cfinclude template="includes/category_tab_groups.cfm">
	</cfcase>
	<cfdefaultcase>
		<span class="alert">Category style not set!</span>
	</cfdefaultcase>
</cfswitch>
<div class="main_panel" style="width:853px;">
<!--- instructions, if any --->
<cfif Trim(main_instructions) NEQ "">
	<br>
	<span class="main_instructions"><cfoutput>#main_instructions#</cfoutput></span>
	<br>
</cfif>

<!--- write user name cookie --->
<cfif IsDefined('cookie.itc_user') AND cookie.itc_user NEQ "" AND (NOT IsDefined('cookie.itc_userwelcome') OR cookie.itc_userwelcome IS "")>
	<cfquery name="GetUserName" datasource="#application.DS#">
		SELECT fname, lname
		FROM #application.database#.program_user
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListGetAt(cookie.itc_user,1,"-")#">
	</cfquery>
	<cfset welcome_text = Translate(language_ID,'welcome_user')>
	<cfif GetUserName.fname NEQ "" AND GetUserName.lname NEQ "">
		<cfcookie name="itc_userwelcome" value='<span class="main_cart_number">#welcome_text# #GetUserName.fname# #GetUserName.lname#</span>.'>
	<cfelse>
		<cfcookie name="itc_userwelcome" value='<span class="main_cart_number">#welcome_text#.</span>'>
	</cfif>
</cfif>

<cfif IsDefined('cookie.itc_userwelcome') AND cookie.itc_userwelcome NEQ "">
	<br>
	<center>
	<cfoutput>#display_message#</cfoutput><br>
	<!--- if stuff in cart, display message --->
	<cfif itemcount NEQ 0>
		<cfoutput>
			<span class="main_paging_number">#itemcount#</span>
			<span class="main_login">
				<cfif itemcount NEQ 1>
					#Translate(language_ID,'cart_num_plural')#
				<cfelse>
					#Translate(language_ID,'cart_num_single')#
				</cfif>
			</span>
		</cfoutput>
	</cfif>
	</center>
</cfif>

<cfquery name="SelectCountExcludes" datasource="#application.DS#">
	SELECT COUNT(ID) AS number_of_excludes 
	FROM #application.database#.program_product_exclude
	WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">
</cfquery>

<cfloop from="1" to="2" index="this_time">

<cfset numTerms = ListLen(thisSearchText," ")>
<cfset thisTerm = 0>
<cfif product_set_IDs NEQ "" AND NOT show_landing_text>
<!--- <cfoutput><pre>
		SELECT DISTINCT pm.ID AS meta_ID, pm.meta_name AS meta_name, pm.thumbnailname AS thumbnailname, pm.productvalue, pm.product_set_ID
		FROM #application.database#.product_meta pm
		JOIN #application.database#.product p ON pm.ID = p.product_meta_ID
		WHERE p.is_active = 1 AND p.is_discontinued = 0 
		<cfif product_set_tabs AND set EQ 0> AND 1 = 2 <cfelse> AND pm.product_set_ID <cfif set gt 0> = #set#> <cfelse> IN (#product_set_IDs#)</cfif></cfif>
			<cfif SelectCountExcludes.number_of_excludes GT 0>
				AND ((SELECT COUNT(ID) FROM #application.database#.program_product_exclude ppe WHERE ppe.program_ID = #program_ID# AND ppe.product_ID = p.ID) = 0) 
			</cfif>
			<cfif thisProductValue NEQ "" AND isNumeric(thisProductValue)>
				AND pm.productvalue = #thisProductValue/points_multiplier#
			</cfif>
			<cfif thisSearchText NEQ "">
				AND (
				<cfloop list="#thisSearchText#" index="thisSearchWord" delimiters=" ">
					<cfset thisTerm = thisTerm + 1>
					<cfif trim(thisSearchWord) NEQ "">
						pm.meta_name LIKE "%#thisSearchWord#% OR
						pm.description LIKE %#thisSearchWord#%
					</cfif>
					<cfif thisTerm LT numTerms>
						OR
					</cfif>
				</cfloop>
				)
			<cfelse>
				<cfif isNumeric(g)>
					AND ((SELECT COUNT(ID) FROM #application.database#.product_meta_group_lookup pmgl WHERE pmgl.product_meta_group_ID = #g# AND product_meta_ID = pm.ID) > 0)
				</cfif>
				<cfif use_master_categories EQ 0 OR use_master_categories EQ 3>
					<!--- Value is from master categories --->
					<cfif is_one_item EQ 0 AND isNumeric(url.p)>
						AND pm.productvalue_master_ID = #url.p#
					<cfelseif is_one_item GT 0>
						<cfif these_assigned_cats NEQ "">
							AND pm.productvalue_master_ID IN (#these_assigned_cats#)
						</cfif>
					</cfif>
				<cfelseif is_one_item EQ 0>
					<!--- Value is from product value --->
					AND pm.productvalue_master_ID IN (SELECT productvalue_master_ID FROM #application.database#.productvalue_program WHERE program_ID = #program_ID#)
				</cfif>
			</cfif>
			<cfif isDefined("cookie.filter") AND cookie.filter NEQ "">
				AND 
				<cfif ListFind(product_set_IDs,1)>
					<cfswitch expression="#cookie.filter#">
						<cfcase value="0">
							pm.productvalue BETWEEN 0 AND 100
						</cfcase>
						<cfcase value="101">
							pm.productvalue BETWEEN 101 AND 200
						</cfcase>
						<cfcase value="201">
							pm.productvalue BETWEEN 201 AND 300
						</cfcase>
						<cfcase value="301">
							pm.productvalue BETWEEN 301 AND 400
						</cfcase>
						<cfcase value="401">
							pm.productvalue BETWEEN 401 AND 500
						</cfcase>
						<cfcase value="501">
							pm.productvalue BETWEEN 501 AND 1000
						</cfcase>
						<cfcase value="1001">
							pm.productvalue BETWEEN 1001 AND 1500
						</cfcase>
						<cfcase value="1501">
							pm.productvalue BETWEEN 1501 AND 2000
						</cfcase>
						<cfcase value="2001">
							pm.productvalue > 2000
						</cfcase>
						<cfdefaultcase>
							pm.productvalue > -1
						</cfdefaultcase>
					</cfswitch>
				<cfelse>
					<cfswitch expression="#cookie.filter#">
						<cfcase value="0">
							pm.productvalue BETWEEN 0 AND 50
						</cfcase>
						<cfcase value="51">
							pm.productvalue BETWEEN 51 AND 100
						</cfcase>
						<cfcase value="101">
							pm.productvalue > 100
						</cfcase>
						<cfdefaultcase>
							pm.productvalue > -1
						</cfdefaultcase>
					</cfswitch>
				</cfif>
			</cfif>
		ORDER BY
			<cfif isDefined("cookie.sort") AND cookie.sort NEQ "">
				<cfswitch expression="#cookie.sort#">
					<cfcase value="low">
						pm.productvalue ASC
					</cfcase>
					<cfcase value="high">
						pm.productvalue DESC
					</cfcase>
					<cfdefaultcase>
						pm.sortorder ASC
					</cfdefaultcase>
				</cfswitch>
			<cfelse>
				pm.sortorder ASC
			</cfif>
</pre>
</cfoutput> --->
	<cfquery name="SelectDisplayProducts" datasource="#application.DS#">
		SELECT DISTINCT pm.ID AS meta_ID, pm.meta_name AS meta_name, pm.thumbnailname AS thumbnailname, pm.productvalue, pm.product_set_ID
		FROM #application.database#.product_meta pm
		JOIN #application.database#.product p ON pm.ID = p.product_meta_ID
		WHERE p.is_active = 1 AND p.is_discontinued = 0 
		<cfif product_set_tabs AND set EQ 0> AND 1 = 2 <cfelse> AND pm.product_set_ID <cfif set gt 0> = <cfqueryparam cfsqltype="cf_sql_integer" value="#set#"> <cfelse> IN (#product_set_IDs#)</cfif></cfif>
			<cfif SelectCountExcludes.number_of_excludes GT 0>
				AND ((SELECT COUNT(ID) FROM #application.database#.program_product_exclude ppe WHERE ppe.program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10"> AND ppe.product_ID = p.ID) = 0) 
			</cfif>
			<cfif thisProductValue NEQ "" AND isNumeric(thisProductValue)>
				AND pm.productvalue = <cfqueryparam cfsqltype="cf_sql_numeric" value="#thisProductValue/points_multiplier#">
			</cfif>
			<cfif thisSearchText NEQ "">
				AND (
				<cfloop list="#thisSearchText#" index="thisSearchWord" delimiters=" ">
					<cfset thisTerm = thisTerm + 1>
					<cfif trim(thisSearchWord) NEQ "">
						pm.meta_name LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#thisSearchWord#%"> OR
						pm.description LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#thisSearchWord#%">
					</cfif>
					<cfif thisTerm LT numTerms>
						OR
					</cfif>
				</cfloop>
				)
			<cfelse>
				<cfif isNumeric(g)>
					AND ((SELECT COUNT(ID) FROM #application.database#.product_meta_group_lookup pmgl WHERE pmgl.product_meta_group_ID = #g# AND product_meta_ID = pm.ID) > 0)
				</cfif>
				<cfif use_master_categories EQ 0 OR use_master_categories EQ 3>
					<!--- Value is from master categories --->
					<cfif is_one_item EQ 0 AND isNumeric(url.p)>
						AND pm.productvalue_master_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#url.p#">
					<cfelseif is_one_item GT 0>
						<cfif these_assigned_cats NEQ "">
							AND pm.productvalue_master_ID IN (#these_assigned_cats#)
						</cfif>
					</cfif>
				<cfelseif is_one_item EQ 0>
					<!--- Value is from product value --->
					AND pm.productvalue_master_ID IN (SELECT productvalue_master_ID FROM #application.database#.productvalue_program WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">)
				</cfif>
			</cfif>
			<cfif isDefined("cookie.filter") AND cookie.filter NEQ "">
				AND 
				<cfif ListFind(product_set_IDs,1)>
					<cfswitch expression="#cookie.filter#">
						<cfcase value="0">
							pm.productvalue BETWEEN 0 AND 100
						</cfcase>
						<cfcase value="101">
							pm.productvalue BETWEEN 101 AND 200
						</cfcase>
						<cfcase value="201">
							pm.productvalue BETWEEN 201 AND 300
						</cfcase>
						<cfcase value="301">
							pm.productvalue BETWEEN 301 AND 400
						</cfcase>
						<cfcase value="401">
							pm.productvalue BETWEEN 401 AND 500
						</cfcase>
						<cfcase value="501">
							pm.productvalue BETWEEN 501 AND 1000
						</cfcase>
						<cfcase value="1001">
							pm.productvalue BETWEEN 1001 AND 1500
						</cfcase>
						<cfcase value="1501">
							pm.productvalue BETWEEN 1501 AND 2000
						</cfcase>
						<cfcase value="2001">
							pm.productvalue > 2000
						</cfcase>
						<cfdefaultcase>
							pm.productvalue > -1
						</cfdefaultcase>
					</cfswitch>
				<cfelse>
					<cfswitch expression="#cookie.filter#">
						<cfcase value="0">
							pm.productvalue BETWEEN 0 AND 50
						</cfcase>
						<cfcase value="51">
							pm.productvalue BETWEEN 51 AND 100
						</cfcase>
						<cfcase value="101">
							pm.productvalue > 100
						</cfcase>
						<cfdefaultcase>
							pm.productvalue > -1
						</cfdefaultcase>
					</cfswitch>
				</cfif>
			</cfif>
		ORDER BY
			<cfif isDefined("cookie.sort") AND cookie.sort NEQ "">
				<cfswitch expression="#cookie.sort#">
					<cfcase value="low">
						pm.productvalue ASC
					</cfcase>
					<cfcase value="high">
						pm.productvalue DESC
					</cfcase>
					<cfdefaultcase>
						pm.sortorder ASC
					</cfdefaultcase>
				</cfswitch>
			<cfelse>
				pm.sortorder ASC
			</cfif>
	</cfquery>
	<cfif SelectDisplayProducts.RecordCount GT 0 OR use_master_categories NEQ 3>
		<cfbreak>
	<cfelseif g NEQ "">
		<cfset g = "">
	</cfif>
</cfif>

</cfloop>

<cfif isDefined("SelectDisplayProducts")>
<!--- <cfdump var="#SelectDisplayProducts#"> --->
	<!--- set paging variables --->
	<cfparam name="OnPage" default="1">
	<cfif NOT isNumeric(display_row)>
		<cfset display_row = 1>
	</cfif>
	<cfif NOT isNumeric(display_col)>
		<cfset display_col = 1>
	</cfif>
	<cfset MaxRows_ProductDisplay=(display_row*display_col)>
	<cfset StartRow_ProductDisplay=Min((OnPage-1)*MaxRows_ProductDisplay+1,Max(SelectDisplayProducts.RecordCount,1))>
	<cfset EndRow_ProductDisplay=Min(StartRow_ProductDisplay+MaxRows_ProductDisplay-1,SelectDisplayProducts.RecordCount)>
	<cfset TotalPages_ProductDisplay=Ceiling(SelectDisplayProducts.RecordCount/MaxRows_ProductDisplay)>
	<cfinclude template="includes/paging.cfm">
	<!--- display products --->
	<!--- this is the loop counter for the product display --->
	<cfset i_cow = 0>
	<cfset thisSize = 0>
	<cfset thisIDList = "">
	<span class="main_instructions">
		<cfoutput>
		<cfif thisSearchText NEQ "" OR thisProductValue NEQ "" OR (isDefined("cookie.filter") AND cookie.filter NEQ "")>
			<a href="main.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&clear=1&div=#request.division_ID#" class="filters" title="Click to clear filters."> 
			<!---
			<span class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&clear=1&div=#request.division_ID#'"><b>&nbsp;&nbsp;Clear Filters&nbsp;&nbsp;</b></span>
			&nbsp;&nbsp;
			--->
		</cfif>
		<cfif thisSearchText NEQ "">
			#Translate(language_ID,'search_results_for')# '#thisSearchText#'
		</cfif>
		<cfif thisProductValue NEQ "">
			<cfif thisSearchText NEQ ""> - </cfif>
			#Translate(language_ID,'search_results_for')# '#thisProductValue# #credit_desc#' 
		</cfif>
		<cfif isDefined("cookie.filter") AND cookie.filter NEQ "">
			<cfif thisSearchText NEQ "" OR thisProductValue NEQ ""> - </cfif>
			<cfset to_text = Translate(language_ID,'points_to_points')>
			<cfif ListFind(product_set_IDs,1)>
				<cfswitch expression="#cookie.filter#">
					<cfcase value="0">
						#100*points_multiplier# #credit_desc# #Translate(language_ID,'points_or_less')#
					</cfcase>
					<cfcase value="101">
						#(100*points_multiplier)+1# #to_text# #200*points_multiplier# #credit_desc#
					</cfcase>
					<cfcase value="201">
						#(200*points_multiplier)+1# #to_text# #300*points_multiplier# #credit_desc#
					</cfcase>
					<cfcase value="301">
						#(300*points_multiplier)+1# #to_text# #400*points_multiplier# #credit_desc#
					</cfcase>
					<cfcase value="401">
						#(400*points_multiplier)+1# #to_text# #500*points_multiplier# #credit_desc#
					</cfcase>
					<cfcase value="501">
						#(500*points_multiplier)+1# #to_text# #1500*points_multiplier# #credit_desc#
					</cfcase>
					<cfcase value="1501">
						#(1500*points_multiplier)+1# #to_text# #2000*points_multiplier# #credit_desc#
					</cfcase>
					<cfcase value="2001">
						#Translate(language_ID,'over_points')# #2000*points_multiplier# #credit_desc#
					</cfcase>
				</cfswitch>
			<cfelse>
				<cfswitch expression="#cookie.filter#">
					<cfcase value="0">
						#50*points_multiplier# #credit_desc# #Translate(language_ID,'points_or_less')#
					</cfcase>
					<cfcase value="51">
						#(50*points_multiplier)+1# #to_text# #100*points_multiplier# #credit_desc#
					</cfcase>
					<cfcase value="101">
						#Translate(language_ID,'over_points')# #100*points_multiplier# #credit_desc#
					</cfcase>
				</cfswitch>
			</cfif>
		</cfif>
		<cfif isDefined("cookie.sort") AND cookie.sort NEQ "">
			<cfif thisSearchText NEQ "" OR thisProductValue NEQ "" OR (isDefined("cookie.filter") AND cookie.filter NEQ "")> - </cfif>
			<cfswitch expression="#cookie.sort#">
				<cfcase value="low">
					#Translate(language_ID,'sorted_lowest_highest')#
				</cfcase>
				<cfcase value="high">
					#Translate(language_ID,'sorted_highest_lowest')#
				</cfcase>
			</cfswitch>
		</cfif>
		<cfif thisSearchText NEQ "" OR thisProductValue NEQ "" OR (isDefined("cookie.filter") AND cookie.filter NEQ "")>
			</a> 
			<!---
			<span class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&clear=1&div=#request.division_ID#'"><b>&nbsp;&nbsp;Clear Filters&nbsp;&nbsp;</b></span>
			&nbsp;&nbsp;
			--->
		</cfif>

		</cfoutput>
	</span>
	<cfif SelectDisplayProducts.RecordCount EQ 0>
		<br /><br />
		<cfif product_set_tabs AND set EQ 0>
			<span class="welcome">
			<cfif product_set_text NEQ "">
				<cfoutput>#product_set_text#</cfoutput>
			<cfelse>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Please choose from the tabs above.
			</cfif>
			</span>
		<cfelse>
			<span class="alert"><cfoutput>#Translate(language_ID,'no_products_found')#</cfoutput></span>
		</cfif>
		<br /><br />
	</cfif>
	<cfoutput query="SelectDisplayProducts" startrow="#StartRow_ProductDisplay#" maxrows="#MaxRows_ProductDisplay#">
		<cfset i_cow = IncrementValue(i_cow)> 
		<!--- open a row if this is loop one or if the loop count equals display_col + 1 --->
		<cfif i_cow EQ 1>
			<table cellpadding="2" cellspacing="0" border="0" align="center">
		</cfif>
		<cfif i_cow EQ 1 OR ((i_cow MOD display_col) EQ 1)>
			<tr>
		</cfif>
		<cfif product_set_ID EQ 1>
			<cftry>
				<cfif right(thumbnailname,3) EQ "jpg">
					<cfset thisSize = Max(FLGen_ImageSize("/inetpub/wwwroot/content/htdocs/itcawards_v2/pics/products/#thumbnailname#").imageheight,thisSize)>
				<cfelseif right(thumbnailname,3) EQ "gif">
					<cfset thisSize = Max(FLGen_ImageSize("/inetpub/wwwroot/content/htdocs/itcawards_v2/pics/products/#thumbnailname#").imagewidth,thisSize)>
				</cfif>
				<cfcatch></cfcatch>
			</cftry>
		<cfelse>
			<cftry>
				<cfif right(thumbnailname,3) EQ "jpg">
					<cfset thisSize = Max(FLGen_ImageSize(application.AbsPath & "pics/products/#thumbnailname#").imageheight,thisSize)>
				<cfelseif right(thumbnailname,3) EQ "gif">
					<cfset thisSize = Max(FLGen_ImageSize(application.AbsPath & "pics/products/#thumbnailname#").imagewidth,thisSize)>
				</cfif>
				<cfcatch></cfcatch>
			</cftry>
		</cfif>
		<cfset thisIDList = ListAppend(thisIDlist,"td_#meta_ID#")>
		<!--- Display the product --->
		<td align="center" valign="top">
			<table cellpadding="2" cellspacing="0" border="0" width="100">
			<tr>
			<td align="center"><img src="pics/shim.gif" width="100" height="1"></td>
			</tr>
			<tr>
			<td id="td_#meta_ID#" valign="bottom" align="center" width="100" height="1" onClick="window.location='main_prod.cfm?prod=#meta_ID#&c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'" style="cursor:pointer"><img src="<cfif product_set_ID EQ 1>#application.ProductSetOneURL#/</cfif>pics/products/#thumbnailname#"></td>
			</tr>
			<tr>
			<td align="center"  class="active_view" onMouseOver="mOver(this,'selected_view');" onMouseOut="mOut(this,'active_view');" onClick="window.location='main_prod.cfm?prod=#meta_ID#&c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'">#Translate(language_ID,'view_details')#</td>
			</tr>
			<tr>
			<td valign="top" class="product_thumb_name">
				#meta_name#
			</td>
			</tr>
			<cfif use_master_categories NEQ 0 AND use_master_categories NEQ 3 AND is_one_item EQ 0>
				<tr>
				<td valign="bottom" class="product_value">
					#productvalue*points_multiplier# #credit_desc#
				</td>
				</tr>
			</cfif>
			<cfif show_inventory EQ 2 or show_inventory EQ 3>
				<cfquery name="getAllProds" datasource="#application.DS#" >
					SELECT ID
					FROM #application.database#.product
					WHERE product_meta_ID = #meta_ID#
				</cfquery>
				<cfset this_onhand = 0>
				<cfloop query="getAllProds">
					<cfset PhysicalInvCalc(getAllProds.ID)>
					<cfset this_onhand = this_onhand + PIC_total_virtual>
				</cfloop>
				<tr>
				<td valign="bottom" class="product_value">
					<b>Available Quantity: #this_onhand#</b>
				</td>
				</tr>
			</cfif>

			</table>
		</td>
		<!--- pad cell if not the last cell and not the last record returned --->
		<cfif (i_cow NEQ display_col) AND ((i_cow + (MaxRows_ProductDisplay * (OnPage - 1))) NEQ SelectDisplayProducts.RecordCount)>
			<td align="center"><img src="pics/shim.gif" width="20" height="1"></td>
		</cfif>
		<!--- close a row --->
		<cfif ((i_cow MOD display_col) EQ 0) OR ((i_cow + (MaxRows_ProductDisplay * (OnPage - 1))) EQ SelectDisplayProducts.RecordCount)>
			<!--- FILL IN INCOMPLETE ROWS --->
			<!--- if is the last record from the database AND not the first row of a multi row table AND not the last record to be displayed on this page AND it's not the last cell of this row, check if fill-in cells needed for row --->
			<cfif ((i_cow + (MaxRows_ProductDisplay * (OnPage - 1))) EQ SelectDisplayProducts.RecordCount) AND display_row GT 1 AND i_cow GT display_col AND i_cow NEQ MaxRows_ProductDisplay AND (i_cow MOD display_col NEQ 0)>
				<cfset fillin = display_col - (i_cow MOD display_col)>
				<cfloop from="1" to="#fillin#" index="thisfillin">
					<cfif thisfillin EQ 1>
						<td align="center"><img src="pics/shim.gif" width="20" height="8"></td>
					</cfif>
						<td align="center">&nbsp;</td>
					<cfif (thisfillin + (i_cow MOD display_col)) NEQ display_col>
						<td align="center"><img src="pics/shim.gif" width="20" height="1"></td>
					</cfif>
				</cfloop>
			</cfif>
			</tr>
			<script>
				<cfloop list="#thisIDList#" index="thisID">
					document.getElementById("#thisID#").height = "#thisSize#";
				</cfloop>
			</script>
			<cfset thisSize = 0>
			<cfset thisIDList = "">
		</cfif>
		<cfif i_cow EQ SelectDisplayProducts.RecordCount OR i_cow EQ MaxRows_ProductDisplay OR ((i_cow + (MaxRows_ProductDisplay * (OnPage - 1))) EQ SelectDisplayProducts.RecordCount)>
			</table>
		</cfif>
	</cfoutput>
	<cfinclude template="includes/paging.cfm">
<cfelse>
	<cfoutput>
	<cfif isDefined("landing_text") AND landing_text NEQ "">
		#landing_text#
	<cfelse>
		<p align="center">#Translate(language_ID,'select_category_or_view_all')#</p>
	</cfif>
	</cfoutput>
</cfif>
</div>
<cfinclude template="includes/footer.cfm">
