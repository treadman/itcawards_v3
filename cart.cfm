<!--- function library --->
<cfinclude template="includes/function_library_local.cfm">
<cfinclude template="includes/function_library_public.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<cfparam name="extrawhere_pvmID_OR" default="">

<cfparam name="cc_max" default="0">
<cfset order_ID = "">
<cfset carttotal = "0">
<cfparam name="c" default="">
<cfparam name="url.p" default="">
<cfparam name="g" default="">
<cfparam name="set" default="0">
<cfparam name="OnPage" default="">
<cfparam name="checkout_type" default="">
<cfparam name="awards_points_charge" default="">

<cfif IsDefined('cookie.itc_user') AND cookie.itc_user IS NOT "">
	<!--- authenticate itc_user cookie --->
	<cfset AuthenticateProgramUserCookie()>
</cfif>

<!--- add to cart  --->

<!--- if passing a product ID in url --->
<cfif IsDefined('URL.iprod') AND URL.iprod IS NOT "">
	<cfif IsDefined('cookie.itc_user') AND cookie.itc_user IS NOT "">
		<!--- check for order cookie --->
		<cfif IsDefined('cookie.itc_order') AND cookie.itc_order IS NOT "">
			<!--- authenticate order cookie --->
			<cfif FLGen_CreateHash(ListGetAt(cookie.itc_order,1,"-")) EQ ListGetAt(cookie.itc_order,2,"-")>
				<cfset order_ID = ListGetAt(cookie.itc_order,1,"-")>
			<cfelse>
				<!--- order cookie not authentic --->
				<cflocation addtoken="no" url="logout.cfm">
			</cfif>
		<cfelse>
			<!--- add new order, and get order_ID --->
			<cflock name="order_infoLock" timeout="10">
				<cftransaction>
					<cfset aToday = FLGen_DateTimeToMySQL()>
					<cfquery name="StartOrder" datasource="#application.DS#">
						INSERT INTO #application.database#.order_info
							(created_user_ID, created_datetime, program_ID)
						VALUES (
							<cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">,
							'#FLGen_DateTimeToMySQL()#',
							<cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">
						)
					</cfquery>
					<cfquery datasource="#application.DS#" name="getPK">
						SELECT Max(ID) As MaxID FROM #application.database#.order_info
					</cfquery>
				</cftransaction>  
			</cflock>
			<cfset order_ID = getPK.MaxID>
			<!--- hash admin_login ID --->
			<cfset OrderIDHash = FLGen_CreateHash(getPK.MaxID)>
			<!--- write cookies --->
			<cfcookie name="itc_order" value="#getPK.MaxID#-#OrderIDHash#">
		</cfif>
		<cfset ThisPValue = 1000000>
		<!--- get the product's value --->
		<cfquery name="FindProdValue" datasource="#application.DS#">
			SELECT IFNULL(pvm.productvalue,0) AS masterCatValue, pm.productvalue, p.productvalue AS override, pm.meta_name AS meta_name, pm.description AS description, p.sku AS sku, p.is_dropshipped
			FROM #application.database#.product p
			JOIN #application.database#.product_meta pm ON pm.ID = p.product_meta_ID
			LEFT JOIN #application.database#.productvalue_master pvm ON pvm.ID = pm.productvalue_master_ID
			WHERE p.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.iprod#">
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
		<!--- get the product's options --->
		<cfset FPO_theseoptions = FindProductOptions(URL.iprod)>
		<!--- put item in the inventory table --->
		<cfquery name="InsertProduct" datasource="#application.DS#">
			INSERT INTO #application.database#.inventory
				(created_user_ID, created_datetime, product_ID, order_ID, quantity, snap_meta_name, snap_sku, snap_description, snap_productvalue, snap_options, snap_is_dropshipped)
			VALUES (
				<cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">,
				'#FLGen_DateTimeToMySQL()#',
				<cfqueryparam cfsqltype="cf_sql_integer" value="#URL.iprod#" maxlength="10">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">,
				1,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#FindProdValue.meta_name#" maxlength="64">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#FindProdValue.sku#" maxlength="64">,
				<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FindProdValue.description#">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#ThisPValue#" maxlength="80">,
				<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#FPO_theseoptions#">,
				<cfqueryparam cfsqltype="cf_sql_tinyint" value="#FindProdValue.is_dropshipped#" maxlength="1">
			)
		</cfquery>
		<cflocation addtoken="no" url="main.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#">
	<cfelse>
		<!--- if not logged into program as user, send to main_login --->
		<cflocation addtoken="no" url="main_login.cfm?iprod=#iprod#&prod=#prod#&c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#">
	</cfif>
</cfif>

<!--- recalculate button --->
<cfif IsDefined('form.recalculate') AND form.recalculate IS NOT "" AND IsDefined('Form.FieldNames') AND Form.FieldNames IS NOT "">
	<cfloop index="thisField" list="#Form.FieldNames#">
		<cfif thisField contains "q_" and Evaluate(thisField) NEQ "">
			<cfset thisinv = RemoveChars(thisField,1,2)>
			<cfset thisqty = Evaluate(thisField)>
			<cfif isNumeric(thisqty)>
				<cfif thisqty EQ 0>
					<cfquery name="DeleteInvItem" datasource="#application.DS#">
						DELETE FROM #application.database#.inventory
						WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisinv#" maxlength="10">
					</cfquery>
				<cfelse>
					<cfquery name="UpdateInvItems" datasource="#application.DS#">
						UPDATE #application.database#.inventory
						SET quantity = #thisqty#
						WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisinv#" maxlength="10">
					</cfquery>
				</cfif>
			</cfif>
		</cfif>
	</cfloop>
</cfif>

<!---  checkout button --->
<cfif IsDefined('form.checkout') AND form.checkout IS NOT "">
	<cfset thisOrderID = "">
	<cfif IsDefined('cookie.itc_order') AND cookie.itc_order IS NOT "">
		<!--- authenticate order cookie --->
		<cfif FLGen_CreateHash(ListGetAt(cookie.itc_order,1,"-")) EQ ListGetAt(cookie.itc_order,2,"-")>
			<cfset thisOrderID = ListGetAt(cookie.itc_order,1,"-")>
		</cfif>
	</cfif>
	<cfif isNumeric(thisOrderID)>
		<cfquery name="DeleteXref" datasource="#application.DS#">
			DELETE FROM #application.database#.xref_order_division
			WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#thisOrderID#" maxlength="10">
		</cfquery>
		<cfloop list="#form.fieldnames#" index="thisField">
			<cfif ListFirst(thisField,"_") EQ "p">
				<cfset thisDiv = ListLast(thisField,"_")>
				<cfset thisPts = evaluate("form."&thisField)>
				<cfif isNumeric(thisPts) AND thisPts GT 0 AND isNumeric(thisDiv) AND thisDiv GT 0>			
					<cfquery name="AssignOrderToDiv" datasource="#application.DS#">
						INSERT INTO #application.database#.xref_order_division
							(created_user_ID, created_datetime, order_ID, division_ID, award_points)
						VALUES (
							<cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">,
							'#FLGen_DateTimeToMySQL()#',
							<cfqueryparam cfsqltype="cf_sql_integer" value="#thisOrderID#" maxlength="10">,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#thisDiv#" maxlength="10">,
							<cfqueryparam cfsqltype="cf_sql_integer" value="#thisPts / points_multiplier#" maxlength="10">
						)
					</cfquery>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	<cfset ct = "">
	<cfif checkout_type NEQ "">
		<cfset ct = "&checkout_type=#checkout_type#">
	</cfif>
	<cfset ap = "">
	<cfif awards_points_charge NEQ "">
		<cfset ap = "&awards_points_charge=#awards_points_charge#">
	</cfif>
	<cflocation addtoken="no" url="checkout.cfm?div=#request.division_ID##ct##ap#">
</cfif>

<!--- ***************************** --->
<!---  get the cart display info    --->
<!--- ***************************** --->

<!--- is the order var set already --->
<!--- find items in the order --->
<cfif order_ID EQ "">
	<cfif IsDefined('cookie.itc_order') AND cookie.itc_order IS NOT "">
		<!--- authenticate order cookie --->
		<cfif FLGen_CreateHash(ListGetAt(cookie.itc_order,1,"-")) EQ ListGetAt(cookie.itc_order,2,"-")>
			<cfset order_ID = ListGetAt(cookie.itc_order,1,"-")>
			<!--- *********************************      --->
			<!---  processing remove button         --->
			<!--- *********************************      --->
			<cfif IsDefined('remove') AND remove IS NOT "">
				<cfquery name="RemoveInvItem" datasource="#application.DS#">
					DELETE FROM #application.database#.inventory
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#remove#" maxlength="10">
						AND order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
				</cfquery>
			</cfif>
			<cfquery name="FindOrderItems" datasource="#application.DS#">
				SELECT I.ID AS inventory_ID, I.snap_meta_name, I.snap_description, I.snap_productvalue, I.quantity, I.snap_options,
					P.thumbnailname, P.product_set_ID
				FROM #application.database#.inventory I
				LEFT JOIN #application.database#.product X ON X.ID = I.product_ID
				LEFT JOIN #application.database#.product_meta P ON P.ID = X.product_meta_ID
				WHERE I.order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			</cfquery>
			<cfif FindOrderItems.RecordCount GT 0>
				<cfset HasOrder = true>
			<cfelse>
				<cfset HasOrder = false>
				<cfset carttotal = 0>
				<cfset user_total = 0>
			</cfif>
		<cfelse>
			<!--- order cookie not authentic --->
			<!--- <cflocation addtoken="no" url="logout.cfm"> --->
			<cfset HasOrder = false>
			<cfset carttotal = 0>
			<cfset user_total = 0>
		</cfif>
	<cfelse>
		<!--- <cflocation addtoken="no" url="logout.cfm"> --->
		<cfset HasOrder = false>
		<cfset carttotal = 0>
		<cfset user_total = 0>
	</cfif>
</cfif>
 
<cfinclude template="includes/header.cfm">

<cfoutput>
<cfif HasOrder>
	<form name="cart_form" method="post" action="#CurrentPage#?p=#url.p#&set=#set#&div=#request.division_ID#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	<tr>
		<td class="active_cell" colspan="100%">#Translate(language_ID,'cart_contents')#</td>
	</tr>
	<tr>
		<td class="cart_cell"><b>#Translate(language_ID,'remove_text')#</b></td>
		<cfif show_thumbnail_in_cart>
			<td class="cart_cell"><b>#Translate(language_ID,'item_text')#</b></td>
		</cfif>
		<td class="cart_cell"><b>#Translate(language_ID,'description_text')#</b></td>
		<cfif is_one_item EQ 0 AND NOT hide_points>
			<td class="cart_cell" align="center"><b>#Translate(language_ID,'quantity_text')#</b></td>
			<td class="cart_cell" colspan="2"><b>#credit_desc#</b></td>
		</cfif>
	</tr>
	<cfloop query="FindOrderItems">
		<tr>
			<td class="cart_cell" align="center">
				<img src="pics/remove-x.gif" width="12" height="12" onclick="window.location='#CurrentPage#?remove=#inventory_ID#&c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'" style="cursor:pointer">
			</td>
			<cfif show_thumbnail_in_cart>
				<td class="cart_cell" align="center">
					<img src="<cfif product_set_ID EQ 1>#application.ProductSetOneURL#/</cfif>pics/products/#thumbnailname#">
				</td>
			</cfif>
			<td class="cart_cell">#snap_meta_name#<cfif snap_options NEQ ""><br>#snap_options#</cfif></td>
			<cfif is_one_item EQ 0 AND NOT hide_points>
				<td class="cart_cell" align="center">
					<input type="text" size="4" maxlength="3" name="q_#inventory_ID#" value="#quantity#">
					<input type="hidden" name="q_#inventory_ID#_required" value="#Translate(language_ID,'blank_quantity')#">
				</td>
				<td class="cart_cell">#NumberFormat(snap_productvalue * credit_multiplier,Application.NumFormat)# <span class="sub">each</span></td>
				<td class="cart_cell" align="right">#NumberFormat(snap_productvalue * quantity * credit_multiplier,Application.NumFormat)#</td>
			</cfif>
		</tr>
		<cfset carttotal = carttotal + (snap_productvalue * quantity)>
	</cfloop>
	<tr><td rowspan="8" colspan="3" valign="top">
		<cfif has_divisions>
			<cfif assign_div_points>
				<table cellpadding="5" cellspacing="1" border="0" width="100%">
					<tr>
						<td align="right" colspan="3">&nbsp;</td>
					</tr>
					<cfloop query="GetDivisions">
						<tr>
							<td align="right">You have #(GetDivisions.points_awarded - divOrderPoints[GetDivisions.ID])*points_multiplier# <b>#GetDivisions.program_name# </b>#credit_desc#</td>
							<td align="right">
								<input style="text-align:right;" type="text" size="6" maxlength="10" name="p_#GetDivisions.ID#" value="<cfif isDefined('GetDivisions.points_assigned')>#GetDivisions.points_assigned*points_multiplier#</cfif>">
							</td>
							<td>
								<cfif GetDivisions.currentrow EQ GetDivisions.recordcount>
								<input type="button" value="#Translate(language_ID,'assign_points')#" onClick="check_assign();">
								</cfif>
							</td>
						</tr>
					</cfloop>
					<tr>
						<td align="right" colspan="2">
							&nbsp;&nbsp;&nbsp;&nbsp;
							<span id="assigned_points"></span>
						</td>
						<td>
							 <span id="assigned_label">points assigned.</span>
						</td>
					</tr>
				</table>
			<cfelse>
				<cfquery name="getDefaultDiv" datasource="#application.DS#">
					SELECT default_division
					FROM #application.database#.program
					WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">
				</cfquery>
				<cfset this_total = carttotal>
				<cfset main_points = 0>
				<cfset other_points = 0>
				<cfloop query="GetDivisions">
					<cfif GetDivisions.ID EQ getDefaultDiv.default_division>
						<cfset main_points = main_points + GetDivisions.points_awarded>
					<cfelse>
						<cfset other_points = other_points + GetDivisions.points_awarded>
					</cfif>
				</cfloop>
				<cfloop condition="this_total GT 0 AND main_points + other_points GT 0">
					<cfloop query="GetDivisions">
						<cfset this_points = 0>
						<cfif other_points GT 0>
							<cfif GetDivisions.ID NEQ getDefaultDiv.default_division>
								<cfset this_points = min(other_points,GetDivisions.points_awarded)>
								<cfif this_points GT this_total>
									<cfset this_points = this_total>
								</cfif>
								<cfif this_points GT 0>
									<input type="hidden" name="p_#GetDivisions.ID#" value="#this_points*points_multiplier#">
									<cfset this_total = this_total - this_points>
									<cfset other_points = other_points - this_points>
								</cfif>
							</cfif>
						<cfelseif main_points GT 0>
							<cfif GetDivisions.ID EQ getDefaultDiv.default_division>
								<cfset this_points = min(main_points,GetDivisions.points_awarded)>
								<cfif this_points GT this_total>
									<cfset this_points = this_total>
								</cfif>
								<cfif this_points GT 0>
									<input type="hidden" name="p_#GetDivisions.ID#" value="#this_points*points_multiplier#">
									<cfset this_total = this_total - this_points>
									<cfset main_points = main_points - this_points>
								</cfif>
							</cfif>
						</cfif>
					</cfloop>
				</cfloop>
			</cfif>
		</cfif>

	</td></tr>
	<cfif is_one_item EQ 0 AND NOT hide_points>
		<tr>
			<td></td>
			<td align="right"><b>#Translate(language_ID,'order_total')#: </b></td>
			<td align="right"><b>#NumberFormat(carttotal * credit_multiplier,Application.NumFormat)#</b></td>
		</tr>
		<tr>
			<td align="right" colspan="3">&nbsp;</td>
		</tr>

		<tr>
			<td></td>
			<td align="right"><b>#Translate(language_ID,'total_text')# #credit_desc#: </b></td>
			<td align="right"><b>#NumberFormat(user_total * points_multiplier,Application.NumFormat)#</b></td>
		</tr>
		<tr>
			<td></td>
			<td align="right"><b>#Translate(language_ID,'less_this_order')#:</b> </td>
			<td align="right"><b>#NumberFormat(carttotal * credit_multiplier,Application.NumFormat)#</b></td>
		</tr>
		<tr>
			<td></td>
			<td align="right"><b>#Translate(language_ID,'remaining_text')# #credit_desc#:</b> </td>
			<td align="right"><b>#NumberFormat(Max((user_total * points_multiplier) - (carttotal * credit_multiplier),0),Application.NumFormat)#</b></td>
		</tr>
		<tr>
			<td></td>
			<cfif user_total - carttotal LT 0 AND accepts_cc GTE 1>
				<!--- there is a balance due --->
				<td align="right" class="alert">#Translate(language_ID,'balance_due')#: </td>
				<td class="alert" align="right">$&nbsp;#NumberFormat(carttotal - user_total,Application.NumFormat)#</td>
			<cfelse>
				<td colspan="2"></td>
			</cfif>
		</tr>
		<tr>
			<td align="right" colspan="3">&nbsp;</td>
		</tr>
	</cfif>
	<tr>
	<td align="right" colspan="6">
		<input type="button" name="Continue Shopping" value="#Translate(language_ID,'continue_shopping')#" onclick="window.location='main.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'">
		<cfif is_one_item EQ 0 AND NOT hide_points>
			&nbsp;&nbsp;&nbsp;<input type="submit" name="recalculate" value="#Translate(language_ID,'recalculate_text')#">
		</cfif>
		&nbsp;&nbsp;&nbsp;
		<!--- only display the checkout button if:
			1) the cart total is less than the user's available credits
			2) OR if they do take cc (value 1) and the cart amount is lte the (user total PLUS the cc_max) 
			3) OR if they take cc (value 2) w/o max 
			4) OR is a one item store and there is only one item in their cart --->
		<cfif carttotal*credit_multiplier LTE user_total*points_multiplier OR (accepts_cc EQ 1 AND (carttotal LTE (cc_max + user_total))) OR accepts_cc EQ 2 OR (is_one_item EQ 1 AND FindOrderItems.RecordCount EQ 1) OR (is_one_item EQ 2 AND (FindOrderItems.RecordCount EQ 1 OR FindOrderItems.RecordCount EQ 2))>
			<cfquery name="GetUserInfo" datasource="#application.DS#">
				SELECT uses_cost_center
				FROM #application.database#.program_user
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">
			</cfquery>
			<cfif GetUserInfo.uses_cost_center GTE 2>
				<input type="hidden" name="checkout_type" value="">
				<input type="hidden" name="checkout" value="">
				<input type="button" name="cc_button" value="         Charge to Cost Center         " onclick="document.cart_form.checkout.value='1'; document.cart_form.checkout_type.value='costcenter'; document.cart_form.submit();"><br /><br />
				<input type="button" name="pt_button" value="Use Your Points and/or Credit Card" onclick="document.cart_form.checkout.value='1'; document.cart_form.checkout_type.value='points'; document.cart_form.submit();">
				<cfif GetUserInfo.uses_cost_center EQ 3>
					<br /><br />
					Use <input type="text" name="awards_points_charge" size="10"> #credit_desc# and 
					<input type="button" name="cm_button" value="Charge Remainder to Cost Center" onclick="document.cart_form.checkout.value='1'; document.cart_form.checkout_type.value='combination'; document.cart_form.submit();">
				</cfif>
			<cfelse>
				<input type="submit" name="checkout" id="checkout" value="#Translate(language_ID,'checkout_text')#">
			</cfif>
		</cfif>
		<input type="hidden" name="c" value="#c#">
		<input type="hidden" name="g" value="#g#">
		<input type="hidden" name="OnPage" value="#OnPage#">
		<input type="hidden" name="set" value="#set#">
	</td>
	</tr>
	</table>
	</form>
<cfelse>
	<br><br>
	<span class="alert">#Translate(language_ID,'no_gifts_in_cart')#</span><br><br>
	<input type="button" name="Continue Shopping" value="#Translate(language_ID,'continue_shopping')#" onclick="window.location='main.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_ID#'">
</cfif>
<br><br>

<cfif is_one_item GT 0 AND HasOrder>
	<cfif FindOrderItems.RecordCount GT is_one_item>
		<cfset this_msg = Replace(one_item_over_message,"%OVER_NUMBER%",FindOrderItems.RecordCount - is_one_item)>
		<cfif FindOrderItems.RecordCount EQ is_one_item + 1>
			<cfset this_msg = Replace(this_msg,"%S%","")>
			<cfset this_msg = Replace(this_msg,"%ES%","")>
		<cfelse>
			<cfset this_msg = Replace(this_msg,"%S%","s")>
			<cfset this_msg = Replace(this_msg,"%ES%","es")>
		</cfif>
		<span class="warning_msg">#this_msg#</span>
	<cfelseif FindOrderItems.RecordCount EQ is_one_item>
		&nbsp;
	</cfif>
<cfelseif carttotal GT cc_max + user_total AND accepts_cc EQ 1>
	<span class="warning_msg">
		#Translate(language_ID,'exceeded_credit_card')#<br><br>#Replace(Translate(language_ID,'you_may_charge'),'[cc_max]',cc_max)#<br><br>
		#cc_exceeded_msg#
	</span>
<cfelseif carttotal*credit_multiplier GT user_total*points_multiplier>
	<span class="main_paging_number">#cart_exceeded_msg#</span>
</cfif>

</cfoutput>

<cfinclude template="includes/footer.cfm">
<script>
	var order_total = <cfoutput>#carttotal * credit_multiplier#</cfoutput>;
	<cfloop query="GetDivisions">
		var t_<cfoutput>#GetDivisions.ID# = #(GetDivisions.points_awarded*points_multiplier - divOrderPoints[GetDivisions.ID])*points_multiplier#</cfoutput>;
	</cfloop>
	function check_assign() {
		var cButton = document.getElementById("checkout");
		var cPoints = document.getElementById("assigned_points");
		var cLabel = document.getElementById("assigned_label");
		var assign_total = 0;
		var this_value = 0;
		<cfloop query="GetDivisions">
			this_element = cart_form.p_<cfoutput>#GetDivisions.ID#</cfoutput>;
			if (isNaN(Number(this_element.value))) {
				alert('Please enter only numeric values.');
				this_element.value = 0;
			}
			if (Number(this_element.value) < 0) {
				alert('Please enter a value of zero or greater.');
				this_element.value = 0;
			}
			if (Number(this_element.value) > t_<cfoutput>#GetDivisions.ID#</cfoutput>) {
				alert('You do not have '+this_element.value+' points in <cfoutput>#GetDivisions.program_name#</cfoutput>.');
				this_element.value = t_<cfoutput>#GetDivisions.ID#</cfoutput>;
			}
			assign_total += Number(this_element.value);
		</cfloop>
		cPoints.innerHTML = assign_total;
		if (order_total != assign_total) {
			cButton.disabled = true;
			cButton.style.display = 'none';
			cPoints.style.fontWeight = 'normal';
			cLabel.style.fontWeight = 'normal';
		} else {
			cButton.disabled = false;
			cButton.style.display = 'inline';
			cPoints.style.fontWeight = 'bold';
			cLabel.style.fontWeight = 'bold';
		}
	}
</script>
