<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<cfset this_carttotal = 0>

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<!--- delete order and user cookies --->
<cfcookie name="itc_order" expires="now" value="">
<cfcookie name="itc_user" expires="now" value="">

<!--- get the order_ID and user_ID from the survey cookie --->
<cfset AuthenticateSurveyCookie()>

<!---  process survey if submitted --->
<cfif IsDefined('form.submitsurvey') AND form.submitsurvey IS NOT "">
	<cfset ProcessCustomerSurvey()>
</cfif>

<!--- ***************************** --->
<!---  get the cart display info    --->
<!--- ***************************** --->

<!--- get order info --->
<cfquery name="FindOrderInfo" datasource="#application.DS#">
	SELECT snap_fname, snap_lname, snap_ship_company, snap_ship_fname, snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip,
		snap_phone, snap_email, snap_bill_company, snap_bill_fname, snap_bill_lname, snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip,
		order_note,	shipping_desc, shipping_charge, snap_signature_charge, credit_card_charge, cost_center_charge
	FROM #application.database#.order_info
	WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
</cfquery>
<cfset snap_fname = HTMLEditFormat(FindOrderInfo.snap_fname)>
<cfset snap_lname = HTMLEditFormat(FindOrderInfo.snap_lname)>
<cfset snap_ship_company = HTMLEditFormat(FindOrderInfo.snap_ship_company)>
<cfset snap_ship_fname = HTMLEditFormat(FindOrderInfo.snap_ship_fname)>
<cfset snap_ship_lname = HTMLEditFormat(FindOrderInfo.snap_ship_lname)>
<cfset snap_ship_address1 = HTMLEditFormat(FindOrderInfo.snap_ship_address1)>
<cfset snap_ship_address2 = HTMLEditFormat(FindOrderInfo.snap_ship_address2)>
<cfset snap_ship_city = HTMLEditFormat(FindOrderInfo.snap_ship_city)>
<cfset snap_ship_state = HTMLEditFormat(FindOrderInfo.snap_ship_state)>
<cfset snap_ship_zip = HTMLEditFormat(FindOrderInfo.snap_ship_zip)>
<cfset snap_phone = HTMLEditFormat(FindOrderInfo.snap_phone)>
<cfset snap_email = HTMLEditFormat(FindOrderInfo.snap_email)>
<cfset snap_bill_company = HTMLEditFormat(FindOrderInfo.snap_bill_company)>
<cfset snap_bill_fname = HTMLEditFormat(FindOrderInfo.snap_bill_fname)>
<cfset snap_bill_lname = HTMLEditFormat(FindOrderInfo.snap_bill_lname)>
<cfset snap_bill_address1 = HTMLEditFormat(FindOrderInfo.snap_bill_address1)>
<cfset snap_bill_address2 = HTMLEditFormat(FindOrderInfo.snap_bill_address2)>
<cfset snap_bill_city = HTMLEditFormat(FindOrderInfo.snap_bill_city)>
<cfset snap_bill_state = HTMLEditFormat(FindOrderInfo.snap_bill_state)>
<cfset snap_bill_zip = HTMLEditFormat(FindOrderInfo.snap_bill_zip)>
<cfset order_note = HTMLEditFormat(FindOrderInfo.order_note)>
<cfset shipping_desc = FindOrderInfo.shipping_desc>
<cfset shipping_charge = FindOrderInfo.shipping_charge>
<cfset snap_signature_charge = FindOrderInfo.snap_signature_charge>
<cfset cost_center_charge = FindOrderInfo.cost_center_charge>
<cfset credit_card_charge = FindOrderInfo.credit_card_charge>

<!--- find order items --->
<cfquery name="FindOrderItems" datasource="#application.DS#">
	SELECT ID AS inventory_ID, snap_meta_name, snap_description, snap_productvalue, quantity, snap_options
	FROM #application.database#.inventory
	WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
</cfquery>
 
<cfinclude template="includes/header.cfm">

<cfoutput>
<span class="main_paging_number">
	<cfif cost_center_charge GT 0>
		Your order has been submitted and is pending approval.
		You will be emailed when approved/declined.
	<cfelse>
		#Translate(language_ID,'you_will_receive_email')#
	</cfif>
</span>
<br><br>

<table cellpadding="3" cellspacing="1" border="0">
	<tr>
		<td colspan="100%"><strong>#Replace(Translate(language_ID,'order_for_user'),'[user_name]',"#snap_fname# #snap_lname# (#snap_email#)")#</strong></td>
	</tr>
	<tr>
		<td colspan="100%">&nbsp;</td>
	</tr>
	<tr>
		<td><strong>#Translate(language_ID,'description_text')#</strong></td>
		<cfif is_one_item EQ 0 AND NOT hide_points>
			<td align="center"><strong>#Translate(language_ID,'quantity_text')#</strong></td>
			<td colspan="2" align="center"><strong>#credit_desc#</strong></td>
		</cfif>
	</tr>
 	<cfloop query="FindOrderItems">
		<tr>
			<td>#snap_meta_name#<cfif snap_options NEQ ""><br>#snap_options#</cfif></td>
			<cfif is_one_item EQ 0 AND NOT hide_points>
				<td align="center">#quantity#</td>
				<td>#NumberFormat(snap_productvalue * credit_multiplier,Application.NumFormat)# <span class="sub">#Translate(language_ID,'each_text')#</span></td>
				<td align="right">#NumberFormat(snap_productvalue * quantity * credit_multiplier,Application.NumFormat)#</td>
			</cfif>
		</tr>
		<cfif is_one_item EQ 0>
			<cfset this_carttotal = this_carttotal + (snap_productvalue * quantity)>
		</cfif>
	</cfloop>
	<cfif is_one_item EQ 0>
		<cfif NOT hide_points>
		<tr>
			<td align="right" colspan="3"><strong>#Translate(language_ID,'order_total')#:</strong> </td>
			<td align="right"><strong>#NumberFormat(this_carttotal * credit_multiplier,Application.NumFormat)#</strong></td>
		</tr>
		<cfif cost_center_charge EQ 0>
		<tr>
			<td align="right" colspan="100%">&nbsp;</td>
		</tr>
		<tr>
			<td align="right" colspan="3"><strong>#Translate(language_ID,'total_text')# #credit_desc#: </strong></td>
			<td align="right"><strong>#NumberFormat(user_total * points_multiplier,Application.NumFormat)#</strong></td>
		</tr>
		<tr>
			<td align="right" colspan="3"><strong>#Translate(language_ID,'less_this_order')#:</strong> </td>
			<td align="right"><strong>#NumberFormat(this_carttotal * credit_multiplier,Application.NumFormat)#</strong></td>
		</tr>
		<tr>
			<td align="right" colspan="3"><strong>#Translate(language_ID,'remaining_text')# #credit_desc#:</strong> </td>
			<td align="right"><strong>#NumberFormat(Max((user_total * points_multiplier) - (this_carttotal * credit_multiplier),0),Application.NumFormat)#</strong></td>
		</tr>
	</cfif>
		</cfif>
		<cfif cost_center_charge GT 0>
			<tr>
				<td align="right" colspan="3"><span class="alert">Amount Charged to Cost Center:</span> </td>
				<td class="alert">$ #NumberFormat(cost_center_charge,"___.__")#</td>
			</tr>
		</cfif>
		<cfif credit_card_charge GT 0>
			<tr>
				<td align="right" colspan="3"><span class="alert">Amount Charged to Credit Card:</span> </td>
				<td class="alert">$ #NumberFormat(credit_card_charge,"___.__")#</td>
			</tr>
		</cfif>

	</cfif>
</table>
	
<br><br>
	
<table cellpadding="3" cellspacing="1" border="0">
	<cfif get_shipping_address>
	<tr>
		<td><b>Shipping Information</b></td>
		<td><cfif snap_bill_fname NEQ ""><b>Billing Information</b><cfelse>&nbsp;</cfif></td>
	</tr>
	<tr>
		<td>
			<cfif snap_ship_company NEQ "">#snap_ship_company#</cfif><br>
			<cfif snap_ship_fname NEQ "">#snap_ship_fname#</cfif> <cfif snap_ship_lname NEQ "">#snap_ship_lname#</cfif><br>
			<cfif snap_ship_address1 NEQ "">#snap_ship_address1#<br></cfif>
			<cfif snap_ship_address2 NEQ "">#snap_ship_address2#<br></cfif>
			<cfif snap_ship_city NEQ "">#snap_ship_city#</cfif>, <cfif snap_ship_state NEQ "">#snap_ship_state#</cfif> <cfif snap_ship_zip NEQ "">#snap_ship_zip#</cfif><br>
			<cfif snap_phone NEQ "">Phone: #snap_phone#</cfif>
		</td>
		<td>
			<cfif snap_bill_fname NEQ "">
			<cfif snap_bill_company NEQ "">#snap_bill_company#</cfif><br>
			<cfif snap_bill_fname NEQ "">#snap_bill_fname#</cfif> <cfif snap_bill_lname NEQ "">#snap_bill_lname#</cfif><br>
			<cfif snap_bill_address1 NEQ "">#snap_bill_address1#<br></cfif>
			<cfif snap_bill_address2 NEQ "">#snap_bill_address2#<br></cfif>
			<cfif snap_bill_city NEQ "">#snap_bill_city#</cfif>, <cfif snap_bill_state NEQ "">#snap_bill_state#</cfif> <cfif snap_bill_zip NEQ "">#snap_bill_zip#</cfif><br>
			<cfelse>&nbsp;</cfif>
		</td>
	</tr>
	<tr>
		<td colspan="2">&nbsp;</td>
	</tr>
	<cfif shipping_desc NEQ "">
		<tr>
			<td colspan="2">Ship via #shipping_desc#: #shipping_charge#</td>
		</tr>
		<tr>
			<td colspan="2">&nbsp;</td>
		</tr>
	</cfif>
	<cfif snap_signature_charge GT 0>
		<tr>
			<td colspan="2"><cfif cost_center_charge EQ 0>Signature Required<cfelse>Box</cfif> Charge: #snap_signature_charge#</td>
		</tr>
		<tr>
			<td colspan="2">&nbsp;</td>
		</tr>
	</cfif>
	</cfif>
	<tr>
		<td colspan="2"><strong>#Translate(language_ID,'special_instructions')#</strong></td>
	</tr>
	<tr>
		<td colspan="2"><cfif order_note NEQ "">#Replace(order_note,chr(10),"<br>","ALL")#<cfelse>(none)</cfif></td>
	</tr>
</table>
</cfoutput>	
<br><br>

<cfif has_survey>
	<cfset CustomerSurvey("order")>
</cfif>

<cfinclude template="includes/footer.cfm">
