<!--- function library --->
<cfinclude template="includes/function_library_local.cfm">
<cfinclude template="includes/function_library_public.cfm">
<cfinclude template="/cfscripts/dfm_common/function_library_page.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<cfset order_ID = "">
<cfset carttotal = "0">
<cfset transactionsuccessful = true>
<cfset ErrorString = "">
<cfset shipper_corrected_address = "">

<!--- TODO: Put box_charge for cost centers in admin --->
<cfset cost_center_box_charge = 4>

<cfparam name="checkout_type" default="">
<cfif checkout_type NEQ "" AND checkout_type NEQ "points" AND checkout_type NEQ "costcenter">
	<cfset checkout_type = "">
</cfif>

<!--- get user vars --->
<cfset AuthenticateProgramUserCookie()>

<!--- get user info --->
<cfif IsDefined('cookie.itc_user') AND cookie.itc_user IS NOT "" AND FLGen_CreateHash(ListGetAt(cookie.itc_user,1,"_")) EQ ListGetAt(cookie.itc_user,2,"_")>
	<!--- set user vars --->
	<cfset user_ID = ListGetAt(cookie.itc_user,1,"-")>
	
	<!--- get user info --->			
	<cfquery name="GetUserInfo" datasource="#application.DS#">
		SELECT username, fname, lname, ship_company, ship_fname, ship_lname, ship_address1, ship_address2, ship_city, ship_state, ship_zip,
				bill_company,  bill_fname, bill_lname, bill_address1,  bill_address2,  bill_city,  bill_state,  bill_zip,
				phone, 	email, uses_cost_center
		FROM #application.database#.program_user
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">
	</cfquery>
	<cfset fname = HTMLEditFormat(GetUserInfo.fname)>
	<cfset lname = HTMLEditFormat(GetUserInfo.lname)>
	<cfset ship_company = HTMLEditFormat(GetUserInfo.ship_company)>
	<cfset ship_fname = HTMLEditFormat(GetUserInfo.ship_fname)>
	<cfset ship_lname = HTMLEditFormat(GetUserInfo.ship_lname)>
	<cfset ship_address1 = HTMLEditFormat(GetUserInfo.ship_address1)>
	<cfset ship_address2 = HTMLEditFormat(GetUserInfo.ship_address2)>
	<cfset ship_city = HTMLEditFormat(GetUserInfo.ship_city)>
	<cfset ship_state = HTMLEditFormat(GetUserInfo.ship_state)>
	<cfset ship_zip = HTMLEditFormat(GetUserInfo.ship_zip)>
	<cfset phone = HTMLEditFormat(GetUserInfo.phone)>
	<cfset email = HTMLEditFormat(GetUserInfo.email)>
	<cfset bill_company = HTMLEditFormat(GetUserInfo.bill_company)>
	<cfset bill_fname = HTMLEditFormat(GetUserInfo.bill_fname)>
	<cfset bill_lname = HTMLEditFormat(GetUserInfo.bill_lname)>
	<cfset bill_address1 = HTMLEditFormat(GetUserInfo.bill_address1)>
	<cfset bill_address2 = HTMLEditFormat(GetUserInfo.bill_address2)>
	<cfset bill_city = HTMLEditFormat(GetUserInfo.bill_city)>
	<cfset bill_state = HTMLEditFormat(GetUserInfo.bill_state)>
	<cfset bill_zip = HTMLEditFormat(GetUserInfo.bill_zip)>
	<cfset uses_cost_center = GetUserInfo.uses_cost_center>
	<cfset user_total = 0>
	<cfif uses_cost_center neq 2 or checkout_type eq "points">
		<cfset user_total = ListGetAt(ListGetAt(cookie.itc_user,2,"-"),1,"_")>
		<!--- Get a fresh total from the DB.  If the two are different, kick them out. --->
		<cfset ProgramUserInfo(user_ID, false)>
		<cfif user_total GT 0 AND user_totalpoints NEQ user_total>
			<cflocation addtoken="no" url="logout.cfm">
		</cfif> 
	</cfif>
<cfelse>
	<cflocation url="cart.cfm?div=#request.division_ID#" addtoken="false" >
</cfif>

<cfparam name="address1" default="">
<cfparam name="address2" default="">
<cfparam name="city" default="">
<cfparam name="state" default="">
<cfparam name="zipcode" default="">

<!--- <cfparam name="awards_points_charge" default="0"> --->
<cfparam name="credit_card_charge" default="0">
<cfparam name="cost_center_charge" default="0">
<cfparam name="cost_center_number" default="">
<cfparam name="shipping_location_ID" default="0">

<cfif NOT isNumeric(credit_card_charge)>
	<Cfset credit_card_charge = 0>
</cfif>
<cfif NOT isNumeric(cost_center_charge)>
	<Cfset cost_center_charge = 0>
</cfif>

<cfset SoldOutString = "">

<!--- Check that there are cost centers --->
<cfset CostCenterErrorString = "">
<cfset cost_center_ID = 0>
<cfif cost_center_number neq "">
	<cfif cost_center_charge gt 0>
		<cfquery name="GetCostCenter" datasource="#application.DS#">
			SELECT ID, number, description
			FROM #application.database#.cost_centers
			WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">
			AND number = <cfqueryparam cfsqltype="cf_sql_varchar" value="#cost_center_number#" maxlength="5">
		</cfquery>
		<cfif GetCostCenter.recordcount EQ 1>
			<cfset cost_center_ID = GetCostCenter.ID>
			<cfquery name="GetLevel1" datasource="#application.DS#">
				SELECT a.admin_user_ID, u.firstname, u.lastname, u.email, u.email_cc, c.number, c.description, u.is_active, u.password
				FROM #application.database#.xref_cost_center_approvers a
				INNER JOIN #application.database#.admin_users u ON u.ID = a.admin_user_ID
				INNER JOIN #application.database#.cost_centers c ON c.ID = a.cost_center_ID
				WHERE a.cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
				AND a.level = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="1" maxlength="1">
			</cfquery>
			<cfset has_cost_center = false>
			<cfset email_list = "">
			<cfif GetLevel1.recordcount GT 0>
				<cfloop query="GetLevel1">
					<cfquery name="GetCostCenterUser" datasource="#application.DS#">
						SELECT ID
						FROM #application.database#.cost_center_user
						WHERE mgr_email = <cfqueryparam cfsqltype="varchar" value="#GetLevel1.email#" >
						AND email = <cfqueryparam cfsqltype="varchar" value="#snap_email#" >
					</cfquery>
					<cfif GetCostCenterUser.recordCount GT 0>
						<cfset email_list = ListAppend(email_list,GetLevel1.email)>
						<cfset has_cost_center = true>
					</cfif>
				</cfloop>
			</cfif>
			<cfif not has_cost_center>
				<cfset CostCenterErrorString = "Cost Center ID "& cost_center_number &" is not valid.">
				<cfset cost_center_number = "">
				<cfset cost_center_ID = 0>
			</cfif>
		<cfelse>
			<cfset CostCenterErrorString = "Cost Center ID "& cost_center_number &" is not valid.">
			<cfset cost_center_number = "">
		</cfif>
	<cfelse>
		<cfset cost_center_number = "">
	</cfif>
</cfif>

<!--- Get shipping location if selected from the drop-down --->
<cfparam name="ship_overseas" default="0">
<cfif isDefined("form.overseas")>
	<cfset shipping_location_ID = forwarder_ID>
	<cfset ship_overseas = "1">
</cfif>
<cfif shipping_location_ID gt 0>
	<cfquery name="GetSelectedShippingLocation" datasource="#application.DS#">
		SELECT location_name, company, attention, address1, address2, city, state, zip
		FROM #application.database#.shipping_locations
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">
		AND ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#shipping_location_ID#" maxlength="10">
	</cfquery>
	<cfif GetSelectedShippingLocation.recordcount eq 1>
		<cfif zipcode eq "">
			<cfset address1 =  GetSelectedShippingLocation.address1>
			<cfset address2 =  GetSelectedShippingLocation.address2>
			<cfset city = GetSelectedShippingLocation.city>
			<cfset state = GetSelectedShippingLocation.state>
			<cfset zipcode = GetSelectedShippingLocation.zip>
		</cfif>
	<cfelse>
		<cfset shipping_location = 0>
		<cfset address1 = "">
		<cfset address2 = "">
		<cfset city = "">
		<cfset state = "">
		<cfset zipcode = "">
	</cfif>
</cfif>

<cfset shipping_desc = "">
<cfset shipping_charge = 0>

<cfset Shipping_Price_Array = ArrayNew(2)>
<cfparam name="ship_type" default="1">

<cfif cc_shipping AND NOT charge_shipping>
	<!--- The way they want it is to charge shipping only when they are not using points at all --->
	<cfif IsDefined('cookie.itc_user') AND cookie.itc_user IS NOT "">
		<cfif FLGen_CreateHash(ListGetAt(cookie.itc_user,1,"_")) EQ ListGetAt(cookie.itc_user,2,"_")>
			<cfif ListGetAt(ListGetAt(cookie.itc_user,2,"-"),1,"_") lte 0 OR (uses_cost_center EQ 2 AND checkout_type EQ "costcenter")>
				<cfset charge_shipping = 1>
			</cfif>
		</cfif>
	</cfif>
</cfif>

<cfset get_zipcode = false>
<cfif charge_shipping or uses_shipping_locations>
	<cfif trim(zipcode) eq "" OR trim(address1) eq "" OR trim(city) eq "" OR trim(state) eq "">
		<cfset get_zipcode = true>
	<cfelseif shipping_location_ID LTE 0 or ship_overseas EQ "1">
 		<!--- get the order number --->
		<cfif order_ID EQ "">
			<cfif IsDefined('cookie.itc_order') AND cookie.itc_order IS NOT "">
				<!--- authenticate order cookie --->
				<cfif FLGen_CreateHash(ListGetAt(cookie.itc_order,1,"-")) EQ ListGetAt(cookie.itc_order,2,"-")>
					<cfset order_ID = ListGetAt(cookie.itc_order,1,"-")>
				<cfelse>
					<!--- order cookie not authentic --->
					<cflocation addtoken="no" url="logout.cfm">
				</cfif>
			<cfelse>
				<cflocation addtoken="no" url="logout.cfm">
			</cfif>
		</cfif>
		<!--- find all inventory items for this order for emails --->
		<cfquery name="FindOrderItems" datasource="#application.DS#">
			SELECT i.quantity, i.snap_meta_name, i.snap_sku, i.snap_productvalue, i.snap_options, IFNULL(p.weight,1) AS weight
			FROM #application.database#.inventory i
			LEFT JOIN #application.database#.product p ON p.ID = i.product_ID
			WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
		</cfquery>
		<cfset CombinedWeight = 0>
		<cfif FindOrderItems.recordcount gt 0>
			<cfloop query="FindOrderItems">
				<cfset item_weight = FindOrderItems.weight>
				<cfif item_weight lte 0>
					<cfset item_weight = 1>
				</cfif>
				<cfset CombinedWeight = CombinedWeight + (FindOrderItems.quantity * item_weight)>
			</cfloop>
		</cfif>
		<cfif CombinedWeight lte 0>
			<cfset CombinedWeight = 1>
		</cfif>
		<cfset CombinedPrice = 1>
		<cfset fedex_obj = CreateObject("#Application.ComponentPath#.fedex_v2")>
		<cfset fedex_obj.recipientAddress1 = address1>
		<cfset fedex_obj.recipientAddress2 = address2>
		<cfset fedex_obj.recipientCity = city>
		<cfset fedex_obj.recipientState = state>
		<cfset fedex_obj.recipientZip = zipcode>
		<!---<cfset fedex_obj.sendErrorEmail = false>--->
		<cfset fedex_result = fedex_obj.AddressValidation()>
		<cfif NOT fedex_result.validated>
			<!--- TODO: Contact Fedex to ask why this address fails --->
			<!--- TODO: Make an exceptions list in the component, not here in the app --->
			<cfif left(trim(address1),14) EQ "545 Washington"
					AND trim(city) EQ "Jersey City"
					AND left(trim(zipcode),5) EQ "07310">
				<cfset fedex_result.validated = true>
				<cfset fedex_result.ResidentialStatus = "BUSINESS">
				<cfset fedex_result.msg = "This is KCG">
			</cfif>
		</cfif>
		<cfif NOT fedex_result.validated>
			<cfset ErrorString = fedex_result.msg>
			<cfset get_zipcode = true>
		<cfelse>
			<cfset fedex_obj.isResidential = true>
			<cfif fedex_result.ResidentialStatus EQ "BUSINESS">
				<cfset fedex_obj.isResidential = false>
			</cfif>
			<cfset fedex_obj.Weight = CombinedWeight>
			<cfset fedex_obj.Value = CombinedPrice>
			<cfset fedex_obj.addCharge = add_shipping>
			<cfset rates_result = fedex_obj.getRates()>
			<cfloop array="#rates_result.response#" index="x">
				<cfif NOT ListFind("SUCCESS",x.status)>
					<cfset ErrorString = ErrorString & x.msg & '<br>'>
				</cfif>
			</cfloop>
			<cfset rate_error = false>
			<cfif ArrayLen(rates_result.rate)>
				<cfset Shipping_Price_Array = rates_result.rate>
				<cftry>
					<cfset shipping_desc = Shipping_Price_Array[ship_type][2]>
					<cfset shipping_charge = Shipping_Price_Array[ship_type][3]>
					<cfcatch>
						<cfset rate_error = true>
					</cfcatch>
				</cftry>
			<cfelse>
				<cfset rate_error = true>
			</cfif>
			<cfif rate_error>
				<cfset fedex_result.validated = false>
				<cfif shipping_location_ID eq 0>
					<cfset get_zipcode = true>
				</cfif>
				<cfif ErrorString EQ "">
					<cfset ErrorString = 'There was an error calculating shipping charges.'>
				</cfif>
			<cfelseif StructKeyExists(fedex_result,"address") AND isStruct(fedex_result.address)>
				<!--- Update order with the address returned by fedex --->
				<cfsavecontent variable="shipper_corrected_address">
					<cfoutput>
						#fedex_result.address.streetlines#<br>
						#fedex_result.address.city#, #fedex_result.address.state# #fedex_result.address.postalcode#
					</cfoutput>
				</cfsavecontent> 
				<cfquery name="UpdateShipperAddress" datasource="#application.DS#">
					UPDATE #application.database#.order_info
					SET shipper_corrected_address = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#shipper_corrected_address#"> 
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
				</cfquery>
			</cfif>
		</cfif>
	</cfif>
</cfif>

<!--- ------------------- --->
<!--- Process transaction --->
<!--- ------------------- --->

<cfif IsDefined('form.place_order') AND form.place_order EQ "1">
	<!--- address verification --->
	<cfset is_pending_verification = false>
	<cfset state_abbr = "">
	<cfif has_address_verification>
		<cfquery name="GetAddress" datasource="#application.DS#">
			SELECT address1, address2, city, state, zip
			FROM #application.database#.program_user_address
			WHERE program_user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">
		</cfquery>
		<cfif GetAddress.recordcount NEQ 1>
			<cfset is_pending_verification = true>
		<cfelse>
			<cfset state_abbr = trim(GetAddress.state)>
			<cfif len(state_abbr) GT 2>
				<cfset state_abbr = FLGen_GetStateAbbr(GetAddress.state)>
			</cfif>
			<cfif trim(GetAddress.address1) NEQ trim(snap_ship_address1)
					OR trim(GetAddress.address2) NEQ trim(snap_ship_address2)
					OR trim(GetAddress.city) NEQ trim(snap_ship_city)
					OR trim(state_abbr) NEQ trim(snap_ship_state)
					OR trim(GetAddress.zip) NEQ trim(snap_ship_zip)>
				<cfset is_pending_verification = true>
			</cfif>
		</cfif>

		<cfif is_pending_verification AND GetUserInfo.recordcount EQ 1>
			<!--- User inits is a hack.  This whole address verification is a hack --->
			<cfset user_inits = left(GetUserInfo.username,2)>
			<cfset name_inits = left(GetUserInfo.fname,1) & left(GetUserInfo.lname,1)>
			<cfif user_inits EQ name_inits>
				<cfset is_pending_verification = false>
			</cfif>
			<!--- End of hack --->
		</cfif>

		<cfif is_pending_verification>
			<!--- See if FedEx thinks they are the same --->
			<cfset fedex_obj = CreateObject("#Application.ComponentPath#.fedex_v2")>
	
			<cfset fedex_obj.recipientAddress1 = snap_ship_address1>
			<cfset fedex_obj.recipientAddress2 = snap_ship_address2>
			<cfset fedex_obj.recipientCity = snap_ship_city>
			<cfset fedex_obj.recipientState = snap_ship_state>
			<cfset fedex_obj.recipientZip = snap_ship_zip>
			<cfset fedex_result_user = fedex_obj.AddressValidation()>
			
			<cfset fedex_obj.recipientAddress1 = GetAddress.address1>
			<cfset fedex_obj.recipientAddress2 = GetAddress.address2>
			<cfset fedex_obj.recipientCity = GetAddress.city>
			<cfset fedex_obj.recipientState = state_abbr>
			<cfset fedex_obj.recipientZip = GetAddress.zip>
			<cfset fedex_result_system = fedex_obj.AddressValidation()>
	
			<cfif fedex_result_user.address.Equals(fedex_result_system.address)><!--- Thanks Ben Nadel, for the Java snip! --->
				<cfset is_pending_verification = false>
			</cfif>
		</cfif>
	</cfif>
	<!--- get the order number --->
	<cfif order_ID EQ "">
		<cfif IsDefined('cookie.itc_order') AND cookie.itc_order IS NOT "">
			<!--- authenticate order cookie --->
			<cfif FLGen_CreateHash(ListGetAt(cookie.itc_order,1,"-")) EQ ListGetAt(cookie.itc_order,2,"-")>
				<cfset order_ID = ListGetAt(cookie.itc_order,1,"-")>
			<cfelse>
				<!--- order cookie not authentic --->
				<cflocation addtoken="no" url="logout.cfm">
			</cfif>
		<cfelse>
			<cflocation addtoken="no" url="logout.cfm">
		</cfif>
	</cfif>
	
	<cfquery name="OrderLines" datasource="#application.DS#">
		SELECT ID, product_ID, snap_meta_name, snap_options, snap_productvalue, quantity
		FROM #application.database#.inventory
		WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
	</cfquery>

	<cfset total_items = OrderLines.recordcount>
	<cfif total_items EQ 0>
		<cflocation url="cart.cfm?div=#request.division_ID#" addtoken="no">
	</cfif>
	<cfif inactivate_zero_inventory>
		<cflock name="izi_#program_ID#" timeout="30">
		<!--- Remove item from cart if sold out --->
		<cfloop query="OrderLines">
			<cfset PhysicalInvCalc(OrderLines.product_ID)>
			<cfif PIC_total_virtual LTE 0>
				<cfquery name="RemoveInvItem" datasource="#application.DS#">
					DELETE FROM #application.database#.inventory
					WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#OrderLines.ID#" maxlength="10">
				</cfquery>
				<cfset SoldOutString = SoldOutString & Replace(Translate(language_ID,'is_sold_out'),'[item]',OrderLines.snap_meta_name & " " & OrderLines.snap_options) & "<br>">
				<cfset total_items = total_items - 1>
			</cfif>
		</cfloop>
		</cflock>
	</cfif>
		
	<cfif SoldOutString EQ "">
		<!--- figure total cost --->
		<cfset snap_order_total = "0">
		<cfloop query="OrderLines">
			<cfset snap_order_total = snap_order_total + (snap_productvalue * quantity)>
		</cfloop>
	
		<cfset cost_center_code = "">
		<cfset x_auth_code = "">
		<cfset x_tran_id = "">
	
		<cfif is_one_item GT 0>
			<!--- if it's a one item store, don't save points or charges --->
			<cfset points_used = 0>
			<cfset credit_card_charge = 0>
			<cfset cost_center_charge = 0>
		<cfelse>
			<!--- if it's not a one item store, process the order normally --->
			
			<!--- figure total point used --->
			<cfif snap_order_total GTE user_total>
				<cfset points_used = user_total>
			<cfelse>
				<cfset points_used = snap_order_total>
			</cfif>
			
			<!--- figure total charges --->
			<cfif snap_order_total GTE user_total>
				<cfset total_charge = snap_order_total - user_total>
			<cfelse>
				<cfset total_charge = 0>
			</cfif>
			<cfif shipping_charge gt 0>
				<cfset total_charge = total_charge + shipping_charge>
				<cfif signature_charge gt 0>
					<cfset total_charge = total_charge + signature_charge>
				</cfif>
			</cfif>
			<cfif checkout_type EQ "costcenter" AND cost_center_box_charge GT 0>
				<cfset total_charge = total_charge + cost_center_box_charge>
			</cfif>
			<cfif CostCenterErrorString NEQ "">
				<cfset transactionsuccessful = false>
			<cfelse>
				<cfif cost_center_ID EQ 0>
					<cfset cost_center_charge = 0>
					<cfset credit_card_charge = total_charge>
				<cfelse>
					<cfset credit_card_charge = 0>
					<cfset cost_center_charge = total_charge>
				</cfif>
			</cfif>
			<cfif transactionsuccessful>
				<!--- process credit card --->
				<cfif total_charge EQ 0>
					<cfif snap_order_total * credit_multiplier GT user_total * points_multiplier>
						<cflocation url="cart.cfm?div=#request.division_ID#" addtoken="no">
					</cfif>
				<cfelseif cost_center_charge + credit_card_charge NEQ total_charge>
					<!--- This will always be false because of the thing above that sets one to zero the other to total_charge  --->
					<!--- Note that this was originally set up to do a mix of credit card and cost center, but for now it must be either one or the other --->
					<!--- Because it was originally set up for both, this check that the two equaled the total was necessary --->
					<!---<cfoutput>
						uses_cost_center: #uses_cost_center#<br>
						cost: #cost_center_charge#<br>
						credit: #credit_card_charge#<br>
						shipping: #shipping_charge#<br>
						total: #total_charge#<br>
					</cfoutput>
					<cfabort>--->
					<!--- Somehow they got past the javascript check for this (which is now disabled)--->
					<cflocation url="cart.cfm?div=#request.division_ID#" addtoken="no">
				<cfelse>
					<cfif cost_center_charge gt 0>
	
						<!--- ************************ --->
						<!--- PROCESS THE COST CENTER --->
						<!--- ************************ --->
		
						<cfif cost_center_number neq "">
							<cfquery name="GetCC" datasource="#application.DS#">
								SELECT ID
								FROM #application.database#.xref_cost_center_users
								WHERE cost_center_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#cost_center_ID#" maxlength="10">
								AND program_user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#user_ID#" maxlength="10">
							</cfquery>
							<cfif GetCC.recordcount EQ 0>
								<cfset CostCenterErrorString = "Cost Center ID "& cost_center_number &" is not valid.">
								<!---<cfset CostCenterErrorString = "You are not assigned to cost center " & cost_center_number & ".">--->
								<cfset cost_center_number = "">
							</cfif>
						</cfif>
						<cfif cost_center_number neq "">
							<cfset cost_center_code = Hash(order_ID & application.salt)>
						<cfelse>
							<cfset transactionsuccessful = false>
						</cfif>
					</cfif>
	
					<cfif transactionsuccessful and credit_card_charge gt 0>
		
						<!--- *********************** --->
						<!--- PROCESS THE CREDIT CARD --->
						<!--- *********************** --->
						
						<cfset exp_date = cc_month & cc_year>
			
						<cfif credit_card_number EQ "pass" or credit_card_number EQ "fail">
							<cfset status = credit_card_number>
						<cfelse>
							<!--- before site goes live, set this to "fail"
							after site goes live, set this to "live" --->
							<cfset status = "live">
						</cfif>
						<cfif credit_card_number NEQ "4111111111111111">
							<cfset FLGen_ChargeCreditCard(status, credit_card_charge, credit_card_number, exp_date, cid_number, snap_bill_fname, snap_bill_lname, snap_bill_company, snap_bill_address1, snap_bill_address2, snap_bill_city, snap_bill_state, snap_bill_zip, snap_phone, snap_email, snap_ship_fname, snap_ship_lname, snap_ship_company, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip)>
							<cfif ccc_ResponseCode EQ "Approved">
								<!--- the transaction is authorized --->
								<cfset x_auth_code = ccc_ResponseCode>
								<cfset x_tran_id = ccc_TransactionID>
							<cfelse>
								<!--- if the transaction fails, stop processing this page --->
								<cfset transactionsuccessful = false>
							</cfif>
						<cfelse>
							<!--- Test credit card transaction --->
							<cfset x_auth_code = "TEST AUTH CODE">
							<cfset x_tran_id = "TEST TRANS ID">
						</cfif>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
		
		<cfif transactionsuccessful>
			<cflock name="order_infoLock" timeout="10">
				<cftransaction>

					<!--- Update subdivisions on the order if any --->
					<cfquery name="GetXrefOrderDivision" datasource="#application.DS#">
						SELECT x.ID, x.created_user_ID, x.created_datetime, x.order_ID, x.division_ID, x.award_points, x.subdivision_ID,
								count(s.ID) AS num_subs
						FROM #application.database#.xref_order_division x
						LEFT JOIN #application.database#.subdivisions s ON s.division_ID = x.division_ID 
						WHERE x.order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
						GROUP BY x.division_ID
						HAVING num_subs > 0 
					</cfquery>

					<cfloop query="GetXrefOrderDivision" >
						<cfset this_points = GetXrefOrderDivision.award_points>
						<cfset this_div = GetXrefOrderDivision.division_ID>
						<cfset this_id = GetXrefOrderDivision.ID>
						<cfset this_date = GetXrefOrderDivision.created_datetime>
					
						<!--- Get the subdivisions for this division --->
						<cfquery name="GetSubdivisions" datasource="#application.DS#">
							SELECT ID
							FROM #application.database#.subdivisions
							WHERE division_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_div#" maxlength="10">
						</cfquery>
						
						<cfloop query="GetSubdivisions">
							<cfif this_points GT 0>
								<cfset this_sub = GetSubdivisions.ID>
								<!--- Get total order points for this user for this subdivision --->
								<cfquery name="GetDivOrders" datasource="#application.DS#">
									SELECT IFNULL(SUM(x.award_points),0) AS points_used
									FROM #application.database#.order_info o
									LEFT JOIN #application.database#.xref_order_division x ON x.order_ID = o.ID
									LEFT JOIN #application.database#.program p ON p.ID = x.division_ID
									WHERE o.created_user_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">
									AND ( o.is_valid = 1
									<cfif has_address_verification>
										OR o.approval = 1
									</cfif>
									)
									AND subdivision_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_sub#" maxlength="10">
									GROUP BY p.ID
								</cfquery>
								<cfset this_div_used = 0>
								<cfif GetDivOrders.recordcount GT 0>
									<cfset this_div_used = GetDivOrders.points_used>
								</cfif>
								
								<!--- Get total award points for this user for this subdivision --->
								<cfquery name="GetDivPoints" datasource="#application.DS#">
									SELECT IFNULL(SUM(points),0) AS points_awarded
									FROM #application.database#.awards_points
									WHERE user_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#">
									AND is_defered = 0
									AND division_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_div#" maxlength="10">
									AND subdivision_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_sub#" maxlength="10">
								</cfquery>
					
								<cfset sub_points = GetDivPoints.points_awarded - this_div_used>
								<cfif sub_points GT 0>
									<cfif sub_points GTE this_points>
										<cfset new_points = this_points>
										<cfset this_points = 0>
									<cfelse>
										<cfset new_points = sub_points>
										<cfset this_points = this_points - sub_points>
									</cfif>
									<cfif this_id GT 0>
										<cfquery name="UpdateXref" datasource="#application.DS#">
											UPDATE #application.database#.xref_order_division
											SET subdivision_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_sub#" maxlength="10">,
												award_points = <cfqueryparam cfsqltype="cf_sql_integer" value="#new_points#" maxlength="10">
											WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#this_id#" maxlength="10">
										</cfquery>
										<cfset this_id = 0>
									<cfelse>
										<cfquery name="AddXref" datasource="#application.DS#">
											INSERT INTO #application.database#.xref_order_division
												( created_user_id, created_datetime, order_ID, division_ID, subdivision_ID, award_points )
											VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">,
												<cfqueryparam cfsqltype="cf_sql_timestamp" value="#this_date#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#this_div#" maxlength="10">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#this_sub#" maxlength="10">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#new_points#" maxlength="10">
											)
										</cfquery>
									</cfif>
								</cfif>
							</cfif>
						</cfloop>
						<cfif this_points GT 0>
							<cfif this_id EQ 0>
								<cfquery name="AddXref" datasource="#application.DS#">
									INSERT INTO #application.database#.xref_order_division
										( created_user_id, created_datetime, order_ID, division_ID, award_points )
									VALUES (
										<cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">,
										<cfqueryparam cfsqltype="cf_sql_timestamp" value="#this_date#">,
										<cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">,
										<cfqueryparam cfsqltype="cf_sql_integer" value="#this_div#" maxlength="10">,
										<cfqueryparam cfsqltype="cf_sql_integer" value="#this_points#" maxlength="10">
									)
								</cfquery>
							</cfif>
						<cfelseif this_points LT 0>
							<cfabort showerror="Automatic assigning of subdivs not working!">
						</cfif>
					</cfloop>



					<!--- get newest order number for this program --->
					<cfquery name="GetLastProgramOrderNumber" datasource="#application.DS#">
						SELECT Max(order_number) As MaxID
						FROM #application.database#.order_info
						WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#program_ID#" maxlength="10">
					</cfquery>
					<cfset order_number = IncrementValue(GetLastProgramOrderNumber.MaxID)>
					<cfset order_note = trim(order_note)>
					<cfif ship_overseas EQ "1">
						<cfset order_note = forward_button & "  " & order_note>
					</cfif>
					<!--- save order information --->
					<cfquery name="SaveOrderInfo" datasource="#application.DS#">
						UPDATE #application.database#.order_info
						SET	snap_fname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_fname#" maxlength="30">,
							snap_lname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_lname#" maxlength="30">, 
							snap_ship_company = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_company#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_ship_company)))#">, 
							snap_ship_fname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_fname#" maxlength="30">, 
							snap_ship_lname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_lname#" maxlength="30">, 
							snap_ship_address1 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_address1#" maxlength="30">, 
							snap_ship_address2 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_address2#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_ship_address2)))#">, 
							snap_ship_city = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_city#" maxlength="30">, 
							snap_ship_state = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_state#" maxlength="10">, 
							snap_ship_zip = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_zip#" maxlength="10">, 
							snap_phone = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_phone#" maxlength="35">, 
							order_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#order_note#" null="#YesNoFormat(NOT Len(order_note))#">, 
							snap_email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_email#" maxlength="128">,
							<cfif IsDefined('snap_bill_company') AND TRIM(snap_bill_company) NEQ "">
								snap_bill_company = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_company#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_company)))#">,  
							</cfif>
							<cfif IsDefined('snap_bill_fname') AND TRIM(snap_bill_fname) NEQ "">
								snap_bill_fname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_fname)))#">, 
							</cfif>
							<cfif IsDefined('snap_bill_lname') AND TRIM(snap_bill_lname) NEQ "">
								snap_bill_lname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_lname)))#">, 
							</cfif>
							<cfif IsDefined('snap_bill_address1') AND TRIM(snap_bill_address1) NEQ "">
								snap_bill_address1 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_address1#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_address1)))#">, 
							</cfif> 
							<cfif IsDefined('snap_bill_address2') AND TRIM(snap_bill_address2) NEQ "">
								snap_bill_address2 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_address2#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_address2)))#">,  
							</cfif>
							<cfif IsDefined('snap_bill_city') AND TRIM(snap_bill_city) NEQ "">
								snap_bill_city = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_city)))#">, 
							</cfif>
							<cfif IsDefined('snap_bill_state') AND TRIM(snap_bill_state) NEQ "">
								snap_bill_state = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_state#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_state)))#">, 
							</cfif>
							<cfif IsDefined('snap_bill_zip') AND TRIM(snap_bill_zip) NEQ "">
								snap_bill_zip = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_zip#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_zip)))#">, 
							</cfif>
							is_valid = <cfif cost_center_number neq "" OR is_pending_verification>0<cfelse>1</cfif>,
							snap_order_total = <cfqueryparam cfsqltype="cf_sql_float" value="#snap_order_total#" maxlength="12">,
							points_used = <cfqueryparam cfsqltype="cf_sql_integer" value="#points_used#" maxlength="8">,
							credit_multiplier = <cfqueryparam cfsqltype="cf_sql_float" value="#credit_multiplier#" scale="2">,
							points_multiplier = <cfqueryparam cfsqltype="cf_sql_float" value="#points_multiplier#" scale="2">,
							credit_card_charge = <cfqueryparam cfsqltype="cf_sql_float" value="#credit_card_charge#" maxlength="12">,
							cost_center_charge = <cfqueryparam cfsqltype="cf_sql_float" value="#cost_center_charge#" maxlength="12">,
							order_number = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_number#" maxlength="14">,
							cost_center_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#cost_center_code#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(cost_center_code)))#">,
							x_auth_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#x_auth_code#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(x_auth_code)))#">,
							x_tran_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#x_tran_id#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(x_tran_id)))#">,
							shipping_charge = <cfqueryparam cfsqltype="cf_sql_float" value="#shipping_charge#" maxlength="12">,
							<cfif shipping_charge gt 0>
								<cfif cost_center_ID EQ 0>
									snap_signature_charge = <cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#signature_charge#" maxlength="12">,
								<cfelse>
									snap_signature_charge = <cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#cost_center_box_charge#" maxlength="12">,
								</cfif>
							</cfif>
							shipping_desc = <cfqueryparam cfsqltype="cf_sql_varchar" value="#shipping_desc#" maxlength="64" null="#YesNoFormat(NOT Len(Trim(shipping_desc)))#">,
							shipping_location_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#shipping_location_ID#" maxlength="10">,
							cost_center_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#cost_center_ID#" maxlength="10">,
							approval = <cfif cost_center_number neq "" OR is_pending_verification>1<cfelse>0</cfif>
							WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
					</cfquery>
				</cftransaction>
			</cflock>
			<!--- update all inventory items for this order to is_valid = 1 --->
			<cfif cost_center_number eq "" AND NOT is_pending_verification>
				<cfquery name="UpdateInvItems" datasource="#application.DS#">
					UPDATE #application.database#.inventory
					SET	is_valid = 1
					WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
				</cfquery>
			</cfif>
			
			<!--- update user record with first, last, shipping, and billing information --->
			<cfquery name="SaveOrderInfo" datasource="#application.DS#">
				UPDATE #application.database#.program_user
				SET	fname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_fname#" maxlength="30">,
					lname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_lname#" maxlength="30">, 
					ship_company = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_company#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_ship_company)))#">, 
					ship_fname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_fname#" maxlength="30">, 
					ship_lname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_lname#" maxlength="30">, 
					ship_address1 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_address1#" maxlength="30">, 
					ship_address2 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_address2#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_ship_address2)))#">, 
					ship_city = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_city#" maxlength="30">, 
					ship_state = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_state#" maxlength="10">, 
					ship_zip = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_ship_zip#" maxlength="10">, 
					phone = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_phone#" maxlength="35">, 
					email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_email#" maxlength="128">
						<cfif IsDefined('snap_bill_company') AND TRIM(snap_bill_company) NEQ "">
							, bill_company = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_company#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_company)))#"> 
						</cfif>
						<cfif IsDefined('snap_bill_fname') AND TRIM(snap_bill_fname) NEQ "">
							, bill_fname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_fname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_fname)))#">
						</cfif>
						<cfif IsDefined('snap_bill_lname') AND TRIM(snap_bill_lname) NEQ "">
							, bill_lname = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_lname#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_lname)))#">
						</cfif>
						<cfif IsDefined('snap_bill_address1') AND TRIM(snap_bill_address1) NEQ "">
							, bill_address1 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_address1#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_address1)))#">
						</cfif> 
						<cfif IsDefined('snap_bill_address2') AND TRIM(snap_bill_address2) NEQ "">
							, bill_address2 = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_address2#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_address2)))#">  
						</cfif>
						<cfif IsDefined('snap_bill_city') AND TRIM(snap_bill_city) NEQ "">
							, bill_city = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_city#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_city)))#">
						</cfif>
						<cfif IsDefined('snap_bill_state') AND TRIM(snap_bill_state) NEQ "">
							, bill_state = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_state#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_state)))#">
						</cfif>
						<cfif IsDefined('snap_bill_zip') AND TRIM(snap_bill_zip) NEQ "">
							, bill_zip = <cfqueryparam cfsqltype="cf_sql_varchar" value="#snap_bill_zip#" maxlength="30" null="#YesNoFormat(NOT Len(Trim(snap_bill_zip)))#">
						</cfif>
						<cfif is_one_item GT 0>
							, is_done = 1
						</cfif>
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">
			</cfquery>
			<!--- find all inventory items for this order for emails --->
			<cfquery name="FindOrderItems" datasource="#application.DS#">
				SELECT quantity, snap_meta_name, snap_sku, snap_productvalue, snap_options
				FROM #application.database#.inventory
				WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
			</cfquery>
			<cfquery name="SelectInfo" datasource="#application.DS#">
				SELECT meta_conf_email_text
				FROM #application.database#.program_meta
			</cfquery>
			<cfset meta_conf_email_text = HTMLEditFormat(SelectInfo.meta_conf_email_text)>
			<!--- send email confirmation, if requested --->
			<cfset this_subject = Replace(Translate(language_ID,'confirmation_email_subject'),'[company_name]',company_name)>
			<cfif cost_center_charge GT 0>
				<cfset this_subject = Replace(this_subject,'Award Program','Cost Center')>
			</cfif>
			<cfset order_for = Translate(language_ID,'order_number_for')>
			<cfset order_for = Replace(order_for,'[order_number]',order_number)>
			<cfif trim(snap_email) EQ "">
				<cfset snap_email = Application.OrdersAdminEmail>
			</cfif>
			<cfset order_for = Replace(order_for,'[user_name]',"#snap_fname# #snap_lname# (#snap_email#)")>
			<cfif Application.OverrideEmail NEQ "">
				<cfset this_to = Application.OverrideEmail>
			<cfelse>
				<cfset this_to = snap_email>
			</cfif>
			<cfmail to="#this_to#" from="#orders_from#" subject="#this_subject#" failto="#Application.OrdersFailTo#" type="html">
				<cfif Application.OverrideEmail NEQ "">
					Emails are being overridden.<br>
					Below is the email that would have been sent to #snap_email#<br>
					<hr>
				</cfif>
				#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
				#this_subject#<br><br>
				<cfif cost_center_charge GT 0>
					<font color="##cb0400">Your order is pending approval.  You will be emailed when approved/declined.</font><br><br>
				<cfelse>
					<cfif delivery_message NEQ "" AND meta_conf_email_text NEQ "">
						#meta_conf_email_text#<br><br>
					</cfif>
					<cfif conf_email_text NEQ "">
						#conf_email_text#<br><br>
					</cfif>
				</cfif>
				#order_for#<br><br>
				#Translate(language_ID,'phone_text')#: #snap_phone#<br><br>
				<cfif get_shipping_address>
					#Translate(language_ID,'shipping_address')#:<br>
					#snap_ship_fname# #snap_ship_lname##CHR(10)#<br>
					#snap_ship_address1##CHR(10)#<br>
					<cfif Trim(snap_ship_address2) NEQ "">
						#snap_ship_address2##CHR(10)#<br>
					</cfif>
					#snap_ship_city#, #snap_ship_state# #snap_ship_zip#<br><br>
					<cfif shipping_desc NEQ "">
						#Translate(language_ID,'ship_via')# #shipping_desc#: #shipping_charge#<br><br>
						<cfif signature_charge GT 0>
							Signature Required Charge: #signature_charge#<br><br>
						</cfif>
					</cfif>
					<cfif cost_center_box_charge gt 0 AND cost_center_ID GT 0>
						Box Charge: #cost_center_box_charge#<br><br>
					</cfif>
				</cfif>
				#Translate(language_ID,'item_in_order')#:<br>
				<cfloop query="FindOrderItems">
					#quantity# - #snap_meta_name# #snap_options#
					<cfif is_one_item EQ 0 AND NOT hide_points>
						(#NumberFormat(snap_productvalue * credit_multiplier)# #credit_desc#)
					</cfif>
					<br>
				</cfloop>
				<br>
				<cfif is_one_item EQ 0 AND NOT hide_points>
					#Translate(language_ID,'order_total')#: #NumberFormat(snap_order_total* credit_multiplier)#<br>
					<cfif cost_center_charge EQ 0>
						#credit_desc# Used: #NumberFormat(points_used * credit_multiplier)#<br>
						#credit_desc# Left: #NumberFormat((user_total* points_multiplier) - (points_used*credit_multiplier))#<br>
					</cfif>
					<cfif cost_center_charge GT 0>
						Charged to Cost Center: #cost_center_charge#<br>
					</cfif>
					<cfif credit_card_charge GT 0>
						Charged to Credit Card: #credit_card_charge#<br>
					</cfif>
				</cfif>
				<br>
				#Translate(language_ID,'order_note')#:
				<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
			</cfmail>
			<!--- Send email to cost center --->
			<cfif cost_center_number neq "">
				<cfloop query="GetLevel1">
					<cfif ListFind(email_list,GetLevel1.email)>
						<cfif Application.OverrideEmail NEQ "">
							<cfset this_to = Application.OverrideEmail>
							<cfset this_cc = Application.OverrideEmail>
						<cfelse>
							<cfset this_to = GetLevel1.email>
							<cfset this_cc = GetLevel1.email_cc>
						</cfif>
					<cfmail to="#this_to#" cc="#this_cc#" from="#orders_from#" subject="#company_name# Cost Center order" failto="#Application.OrdersFailTo#" type="html">
						<cfif Application.OverrideEmail NEQ "">
							Emails are being overridden.<br>
							Below is the email that would have been sent to #GetLevel1.email# and cc to #GetLevel1.email_cc#<br>
							<hr>
						</cfif>
						#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
						Dear #GetLevel1.firstname# #GetLevel1.lastname#,<br><br>
						An order was charged to cost center #GetLevel1.number#<cfif GetLevel1.description neq ""> - #GetLevel1.description#</cfif>.<br><br>
						Log in to <a href="#application.SecureWebPath#/admin/index.cfm?o=#cost_center_code#<cfif GetLevel1.is_active EQ 0>&v=#GetLevel1.password#&e=#GetLevel1.email#</cfif>">#application.AdminName# admin</a> to approve or decline this order.<br><br>
						Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br><br>
						PHONE: #snap_phone#<br><br>
						<cfif get_shipping_address>
							SHIPPING ADDRESS:<br>
							#snap_ship_fname# #snap_ship_lname#<br>
							#snap_ship_address1#<br>
							<cfif Trim(snap_ship_address2) NEQ "">
								#snap_ship_address2#<br>
							</cfif>
							#snap_ship_city#, #snap_ship_state# #snap_ship_zip#<br><br>
							<cfif shipping_desc NEQ "">
								Ship via #shipping_desc#: #shipping_charge#<br><br>
								<cfif signature_charge GT 0>
									Signature Required Charge: #signature_charge#<br><br>
								</cfif>
							</cfif>
							<cfif cost_center_box_charge gt 0 AND cost_center_ID GT 0>
								Box Charge: #cost_center_box_charge#<br><br>
							</cfif>
						</cfif>
						ITEM(S) IN ORDER:
						<cfloop query="FindOrderItems">
							#quantity# - #snap_meta_name# #snap_options#
							<cfif is_one_item EQ 0 AND NOT hide_points>
								(#NumberFormat(snap_productvalue * credit_multiplier)# #credit_desc#)accepts_cc
							</cfif>
							<br>
						</cfloop>
						<br>
						<cfif is_one_item EQ 0 AND NOT hide_points>
							Order Total: #NumberFormat(snap_order_total* credit_multiplier)#<br>
							<cfif cost_center_charge GT 0>
								Charged to Cost Center: #cost_center_charge#<br>
							</cfif>
							<cfif credit_card_charge GT 0>
								Charged to Credit Card: #credit_card_charge#<br>
							</cfif>
							<br>
						</cfif>
						ORDER NOTE:<br>
						<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
					</cfmail>
					</cfif>
				</cfloop>
				<!--- send notification email(s) ---->
				<cfif cost_center_notification neq "">
					<cfloop list="#cost_center_notification#" index="thisemail">
						<cfif Application.OverrideEmail NEQ "">
							<cfset this_to = Application.OverrideEmail>
						<cfelse>
							<cfset this_to = thisemail>
						</cfif>
						<cfmail to="#this_to#" from="#orders_from#" subject="#program_email_subject# - Cost Center Order #order_number#" failto="#Application.OrdersFailTo#" type="html">
							<cfif Application.OverrideEmail NEQ "">
								Emails are being overridden.<br>
								Below is the email that would have been sent to #thisemail#<br>
								<hr>
							</cfif>
							#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
							Cost Center Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br><br>
							This order needs to be approved by a cost center approver.<br><br>
							PHONE: #snap_phone#<br><br>
							<cfif get_shipping_address>
								SHIPPING ADDRESS:<br>
								#snap_ship_fname# #snap_ship_lname#<br>
								#snap_ship_address1#<br>
								<cfif Trim(snap_ship_address2) NEQ "">#snap_ship_address2#<br></cfif>
								#snap_ship_city#, #snap_ship_state# #snap_ship_zip#<br><br>
								<cfif shipping_desc NEQ "">
									Ship via #shipping_desc#: #shipping_charge#<br><br>
									<cfif signature_charge GT 0>
										Signature Required Charge: #signature_charge#<br><br>
									</cfif>
								</cfif>
							</cfif>
							<cfif cost_center_box_charge gt 0 AND cost_center_ID GT 0>
								Box Charge: #cost_center_box_charge#<br><br>
							</cfif>
							ITEM(S) IN ORDER:
							<cfloop query="FindOrderItems">
								#quantity# - [sku:#snap_sku#] #snap_meta_name# #snap_options# (#snap_productvalue*credit_multiplier# #credit_desc#)<br>
							</cfloop>
							<br>
							<cfif is_one_item GT 0>
								This is a #is_one_item#-ITEM award program<br>
							<cfelseif NOT hide_points>
								Order Total: #snap_order_total*credit_multiplier#<br>
								#credit_desc# Used: #points_used*credit_multiplier#<br>
								#credit_desc# Left: #(user_total*points_multiplier) - (points_used*credit_multiplier)#<br>
							</cfif>
							<cfif cost_center_charge GT 0>
								Charged to Cost Center: #cost_center_charge#<br>
							</cfif>
							<cfif credit_card_charge GT 0>
								Charged to Credit Card: #credit_card_charge#<br>
							</cfif>
							<br>
							ORDER NOTE:
							<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
						</cfmail>
					</cfloop>
				</cfif>
			</cfif>
			<!--- Send email to ITC --->
			<cfif cost_center_number eq "">
				<cfif is_pending_verification>
					<cfif Application.OverrideEmail NEQ "">
						<cfset this_to = Application.OverrideEmail>
					<cfelse>
						<cfset this_to = Application.AddressValidationEmail>
					</cfif>
					<cfmail to="#this_to#" from="#orders_from#" subject="#program_email_subject# - Order #order_number#" failto="#Application.OrdersFailTo#" type="html">
						<cfif Application.OverrideEmail NEQ "">
							Emails are being overridden.<br>
							Below is the email that would have been sent to #Application.AddressValidationEmail#<br>
							<hr>
						</cfif>
						#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
						Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br><br>
						Address validation required.  View orders in pending...
					</cfmail>
				<cfelse>
					<!--- send New Order email(s) ---->
					<cfloop list="#orders_to#" index="thisemail">
						<cfif Application.OverrideEmail NEQ "">
							<cfset this_to = Application.OverrideEmail>
						<cfelse>
							<cfset this_to = thisemail>
						</cfif>
						<cfmail to="#this_to#" from="#orders_from#" subject="#program_email_subject# - Order #order_number#" failto="#Application.OrdersFailTo#" type="html">
							<cfif Application.OverrideEmail NEQ "">
								Emails are being overridden.<br>
								Below is the email that would have been sent to #thisemail#<br>
								<hr>
							</cfif>
							#DateFormat(Now(),"mm/dd/yyyy")#<br><br>
							Order #order_number# for #snap_fname# #snap_lname# (#snap_email#)<br><br>
							PHONE: #snap_phone#<br><br>
							<cfif get_shipping_address>
								SHIPPING ADDRESS:<br>
								#snap_ship_fname# #snap_ship_lname#<br>
								#snap_ship_address1#<br>
								<cfif Trim(snap_ship_address2) NEQ "">#snap_ship_address2#<br></cfif>
								#snap_ship_city#, #snap_ship_state# #snap_ship_zip#<br><br>
								<cfif Trim(shipper_corrected_address) NEQ "">
									FEDEX CORRECTED:<br>
									#shipper_corrected_address#<br><br>
								</cfif>
								<cfif shipping_desc NEQ "">
									Ship via #shipping_desc#: #shipping_charge#<br><br>
									<cfif signature_charge GT 0>
										Signature Required Charge: #signature_charge#<br><br>
									</cfif>
								</cfif>
							</cfif>
							ITEM(S) IN ORDER:
							<cfloop query="FindOrderItems">
								#quantity# - [sku:#snap_sku#] #snap_meta_name# #snap_options# (#snap_productvalue*credit_multiplier# #credit_desc#)<br>
							</cfloop>
							<br>
							<cfif is_one_item GT 0>
								This is a #is_one_item#-ITEM award program<br>
							<cfelseif NOT hide_points>
								Order Total: #snap_order_total*credit_multiplier#<br>
								#credit_desc# Used: #points_used*credit_multiplier#<br>
								#credit_desc# Left: #(user_total*points_multiplier) - (points_used*credit_multiplier)#<br>
							</cfif>
							<cfif cost_center_charge GT 0>
								Charged to Cost Center: #cost_center_charge#<br>
							</cfif>
							<cfif credit_card_charge GT 0>
								Charged to Credit Card: #credit_card_charge#<br>
							</cfif>
							<br>
							ORDER NOTE:
							<cfif order_note EQ "">(none)<cfelse>#order_note#</cfif>
						</cfmail>
					</cfloop>
				</cfif>
			</cfif>
	
			<!--- write the survey cookie --->
			<cfset WriteSurveyCookie()>
	
			<!--- redirect --->
			<cflocation url="confirmation.cfm?div=#request.division_ID#" addtoken="no">	
		
		</cfif>
	</cfif>
	<!--- ----------------------------- --->
	<!--- End of transaction processing --->
	<!--- ----------------------------- --->
</cfif>

<cfinclude template="includes/header.cfm">

<cfif get_zipcode>
	<script>
	function UpdateAddress(street,city,state,zipcode) {
		var s = zip_form.state;
		var i;
		zip_form.address1.value = street;
		zip_form.city.value = city;
		for (i = 0; i < s.options.length; i++) {
			if (s.options[i].value == state) {
				s.options[i].selected = true;
			}
		}
		zip_form.zipcode.value = zipcode;
	}
	</script>
	<cfoutput>
	<form name="zip_form" action="#CGI.SCRIPT_NAME#?div=#request.division_ID#" method="post">
		<br />
		<cfif uses_shipping_locations eq 0 or charge_shipping>
			<cfif uses_shipping_locations gt 0>
				<cfif checkout_type EQ "costcenter">
					<cfset shipping_location_message2 = replace(shipping_location_message2,'<p>&lt;nocostcenter&gt;</p>','<!-- ','ALL')>
					<cfset shipping_location_message2 = replace(shipping_location_message2,'<p>&lt;/nocostcenter&gt;</p>',' -->','ALL')>
				<cfelse>
					<cfset shipping_location_message2 = replace(shipping_location_message2,'<p>&lt;nocostcenter&gt;</p>','','ALL')>
					<cfset shipping_location_message2 = replace(shipping_location_message2,'<p>&lt;/nocostcenter&gt;</p>','','ALL')>
				</cfif>
				#shipping_location_message2#
				<cfif forwarder_ID GT 0>
					<p align="center"><input type="submit" name="overseas" value="#forward_button#"></p>
				</cfif>
			</cfif>
			<br /><br />&nbsp;&nbsp;&nbsp;&nbsp;<span class="alert"><strong>Please &ndash;</strong></span>
			<ol>
				<li>Enter your shipping address to calculate the shipping charges</li>
				<li>Click Continue to complete your order</li>
				<br />
				<br />
				Thank You!
			</ol>
			<cfif ErrorString NEQ "">
				<blockquote class="alert">#ErrorString#</blockquote>
			</cfif>
			<table>
			<tr>
				<td align="right"><strong>Address&nbsp;Line&nbsp;1</strong> </td>
				<td><input type="text" name="address1" value="#address1#" size="60" maxlength="30"></td>
			</tr>
			<tr>
				<td align="right"><strong>Address&nbsp;Line&nbsp;2</strong> </td>
				<td><input type="text" name="address2" value="#address2#" size="60" maxlength="30"></td>
			</tr>
			<tr>
				<td align="right"><strong>City</strong> </td>
				<td><input type="text" name="city" value="#city#" maxlength="30" size="60"></td>
			</tr>
			<tr>
				<td align="right"><strong>State</strong> </td>
				<td>#FLGen_SelectState("state","#state#","true")# </td>
			</tr>
			<tr>
				<td align="right"><strong>Zip Code</strong> </td>
				<td><input type="text" name="zipcode" value="#zipcode#" maxlength="5" size="10"></td>
			</tr>
			</table>
			<cfif isDefined("fedex_result.validated") AND NOT fedex_result.validated>
				<cfset google_addresses = fedex_obj.GetGoogleMapsSuggestions()>
				<cfset has_google = true>
				<cfif google_addresses[1][1] EQ "NO_RESULTS">
					<cfset has_google = false>
				</cfif>
				<cfset has_fedex = false>
				<cfif StructKeyExists(fedex_result,"address") AND isStruct(fedex_result.address)>
					<cfset fedex_result.address.postalcode = left(fedex_result.address.postalcode,5)>
					<cfset has_fedex = true>
				</cfif>
				<p class="main_instructions">
					Please correct the address above<cfif has_fedex or has_google> or choose from the following:<cfelse>.</cfif> 
				</p>
				<table cellspacing="0" cellpadding="8" align="center">
				<tr>
				<cfif has_fedex>
					<td valign="top" class="address_button" onClick="UpdateAddress('#fedex_result.address.streetlines#','#fedex_result.address.city#','#fedex_result.address.state#','#fedex_result.address.postalcode#')">
						<table cellspacing="0" cellpadding="0">
							<tr>
								<td>#fedex_result.address.streetlines#&nbsp;</td>
							</tr>
							<tr>
								<td>#fedex_result.address.city#&nbsp;</td>
							</tr>
							<tr>
								<td>#fedex_result.address.state#&nbsp;</td>
							</tr>
							<tr>
								<td>#fedex_result.address.postalcode#&nbsp;</td>
							</tr>
						</table>
					</td>
				</cfif>
				<!--- Query the Google Maps API --->
				<cfif has_google>
					<cfloop array="#google_addresses#" index="g">
					<cfset g[6] = left(g[6],5)>
						<td>&nbsp;&nbsp;&nbsp;</td>
						<td valign="top" class="address_button" onClick="UpdateAddress('#g[3]#','#g[4]#','#g[5]#','#g[6]#')">
							<table cellspacing="0" cellpadding="0">
								<tr>
									<td>#g[3]#&nbsp;</td>
								</tr>
								<tr>
									<td>#g[4]#&nbsp;</td>
								</tr>
								<tr>
									<td>#g[5]#&nbsp;</td>
								</tr>
								<tr>
									<td>#g[6]#&nbsp;</td>
								</tr>
							</table>
						</td>
					</cfloop>
				</cfif>
				</tr></table>
			</cfif>
		<cfelse>
			<cfif uses_shipping_locations gt 0>
				#shipping_location_message1#
			</cfif>
			<cfif ErrorString NEQ ""><blockquote class="alert">#ErrorString#</blockquote></cfif>
			<cfquery name="GetShippingLocations" datasource="#application.DS#">
				SELECT ID, location_name, city, state, zip
				FROM #application.database#.shipping_locations
				WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#program_ID#" maxlength="10">
				AND is_active = 1
				ORDER BY location_name
			</cfquery>
			<p align="center">
				<select name="shipping_location_ID">
					<option value="0">-- Select Your Office --</option>
					<cfloop query="GetShippingLocations">
						<option value="#ID#">#location_name#<!--- [#city#, #state#, #zip#]--->
					</cfloop>
				<!---<option value="-1">Ship to your home or other location</option>--->
				</select>
			</p>
		</cfif>
		<input type="hidden" name="checkout_type" value="#checkout_type#">
		<p align="center"><input type="submit" name="submit" value="#Translate(language_ID,'continue_text')#"></p>
	</form>
	</cfoutput>
<cfelse>

	<!--- ------------------ --->
	<!--- Main checkout form --->
	<!--- ------------------ --->


	<!--- is the order var set already --->
	<!--- find items in the order --->
	<cfif order_ID EQ "">
		<cfif IsDefined('cookie.itc_order') AND cookie.itc_order IS NOT "">
			<!--- authenticate order cookie --->
			<cfif FLGen_CreateHash(ListGetAt(cookie.itc_order,1,"-")) EQ ListGetAt(cookie.itc_order,2,"-")>
				<cfset order_ID = ListGetAt(cookie.itc_order,1,"-")>
			<cfelse>
				<!--- order cookie not authentic --->
				<cflocation addtoken="no" url="logout.cfm">
			</cfif>
		<cfelse>
			<cflocation addtoken="no" url="logout.cfm">
		</cfif>
	</cfif>
	 
	<cfquery name="FindOrderItems" datasource="#application.DS#">
		SELECT ID AS inventory_ID, snap_meta_name, snap_description, snap_productvalue, quantity, snap_options
		FROM #application.database#.inventory
		WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
	</cfquery>
	<cfif uses_cost_center eq 2 AND checkout_type NEQ "costcenter">
		<cfset uses_cost_center = 0>
	</cfif>
	<cfif uses_cost_center gt 0>
		<cfquery name="GetCCs" datasource="#application.DS#">
			SELECT ID FROM #application.database#.xref_cost_center_users
			WHERE program_user_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#user_ID#" maxlength="10">
		</cfquery>
		<cfif GetCCs.recordcount EQ 0>
			<cfset uses_cost_center = 0>
		</cfif>
	</cfif>
	<cfif city eq "">
		<cfset city = HTMLEditFormat(GetUserInfo.ship_city)>
	</cfif>
	<cfif state eq "">
		<cfset state = HTMLEditFormat(GetUserInfo.ship_state)>
	</cfif>
	<cfif zipcode eq "">
		<cfset zipcode = HTMLEditFormat(GetUserInfo.ship_zip)>
	</cfif>
		
	<script>
	<cfif ArrayLen(Shipping_Price_Array) GT 0>
		var ship_desc = new Array();
		var ship_val = new Array();
		<cfloop from="1" to="#ArrayLen(Shipping_Price_Array)#" index="i">
			<cfif ArrayLen(Shipping_Price_Array[i]) GT 0>
			ship_desc[<cfoutput>#i#</cfoutput>] = '<cfoutput>#Shipping_Price_Array[i][2]#</cfoutput>';
			ship_val[<cfoutput>#i#</cfoutput>] = <cfoutput>#Shipping_Price_Array[i][3]#</cfoutput>;
			</cfif>
		</cfloop>
	</cfif>
	// function to copy shipping address to billing address 
	function CopyAddress() {
		if (document.order_form.billingsame.checked) {
			document.order_form.snap_bill_company.value = document.order_form.snap_ship_company.value;
			document.order_form.snap_bill_fname.value = document.order_form.snap_ship_fname.value;
			document.order_form.snap_bill_lname.value = document.order_form.snap_ship_lname.value;
			document.order_form.snap_bill_lname.value = document.order_form.snap_ship_lname.value;
			document.order_form.snap_bill_address1.value = document.order_form.snap_ship_address1.value;
			document.order_form.snap_bill_address2.value = document.order_form.snap_ship_address2.value;
			document.order_form.snap_bill_city.value = document.order_form.snap_ship_city.value;
			document.order_form.snap_bill_state.value = document.order_form.snap_ship_state.value;
			document.order_form.snap_bill_zip.value = document.order_form.snap_ship_zip.value;
		} 
	}
	function SameName() {
		if (document.order_form.namesame.checked) {
			document.order_form.snap_ship_fname.value = document.order_form.snap_fname.value;
			document.order_form.snap_ship_lname.value = document.order_form.snap_lname.value;
		} 
	}
	function validateOnSubmit() {
		document.getElementById('active_place_order').style.display = 'none';
		document.getElementById('inactive_place_order').style.display = 'block';

		var error = false;
		/*
		if (document.getElementById('credit_card_charge') && document.getElementById('cost_center_charge')) {
			var alert_msg = "";
			var this_total = 0;
			var this_credit_charge = document.getElementById('credit_card_charge').value;
			if(isNaN(this_credit_charge)) {
				alert_msg += "'" + document.getElementById('credit_card_charge').value + "' is not a numeric credit card amount.\n\n";
				this_credit_charge = 0;
			}
			this_credit_charge *= 100;
			//alert(this_credit_charge);
			var this_cost_charge = document.getElementById('cost_center_charge').value;
			if(isNaN(this_cost_charge)) {
				alert_msg += "'" + document.getElementById('cost_center_charge').value + "' is not a numeric cost center amount.\n\n";
				this_cost_charge = 0;
			}
			this_cost_charge *= 100;
			//alert(this_cost_charge);
			var this_total = parseInt(this_credit_charge) + parseInt(this_cost_charge);
			this_total /= 100;
			//alert(this_total);
			var total_due = document.getElementById("total_due").innerHTML;
			//alert(total_due);
			if (this_total != total_due) {
				error = true;
				alert_msg += "$"+this_total+"<cfoutput>#Translate(language_ID,'cost_center_plus_credit_card')#</cfoutput> "+total_due;
				document.getElementById("label_credit_card_charge").className = "alert";
				document.getElementById("label_cost_center_charge").className = "alert";
			} else {
				document.getElementById("label_credit_card_charge").className = "bold";
				document.getElementById("label_cost_center_charge").className = "bold";
			}
			if(error) {
				alert(alert_msg);
			}
		}
		*/
		if (!error) {
			var this_alert = true;
			for (i = 0; i < labelArray.length; i++) {
				if (document.getElementById(labelArray[i])) {
					this_alert = true;
					document.getElementById(labelArray[i]).value = document.getElementById(labelArray[i]).value.replace(/^\s+/, "").replace(/\s+$/, "").replace(/\s+/g, " ")
					if (document.getElementById(labelArray[i]).value == "") {
						if (labelArray[i] == "credit_card_number" || labelArray[i] == "cid_number") {
							// Skip credit card if they entered 0 in the amount field
							if (document.getElementById('credit_card_charge') && document.getElementById('credit_card_charge').value <= 0) {
								this_alert = false;
							}
						}
						if (labelArray[i] == "cost_center_number") {
							// Skip cost center number if they entered 0 in the amount field
							if (document.getElementById('cost_center_charge') && document.getElementById('cost_center_charge').value <= 0) {
								this_alert = false;
							}
						}
					}
					else {
						this_alert = false;
					}
					if (this_alert) {
						document.getElementById("label_" + labelArray[i]).className = "alert";
						error = true;
					}
					else {
						document.getElementById("label_" + labelArray[i]).className = "bold";
					}
				}
			}
			if (error) {
				alert("<cfoutput>#Translate(language_ID,'complete_all_fields')#</cfoutput>");
				document.getElementById('inactive_place_order').style.display = 'none';
				document.getElementById('active_place_order').style.display = 'block';
			} else {
				document.forms[0].place_order.value = "1";
				document.forms[0].submit();
			}
		}
	}
	function updateShipping() {
		var sd = document.getElementById("ship_desc");
		var sc = document.getElementById("ship_charge");
		var ship_charge = sc.innerHTML;
		var td = document.getElementById("total_due");
		var total_due = td.innerHTML;
		var st = document.getElementById('id_ship_type').options[document.getElementById('id_ship_type').selectedIndex].value;
		var new_balance = (total_due - ship_charge) + ship_val[st];
		sd.innerHTML = ship_desc[st];
		sc.innerHTML = ship_val[st];
		td.innerHTML = new_balance.toFixed(2);
	}
	</script>
	
	<cfif SoldOutString NEQ "">
		<span class="alert">
			There was a problem with your order:<br><br>
			<cfoutput>#SoldOutString#</cfoutput>
			<br><br>
		</span>
		<div align="center"><cfoutput><a href="cart.cfm?div=#request.division_ID#">#Translate(language_ID,'return_to_cart')#</a></cfoutput></div>
		<br><br>
	<cfelse>
	<cfoutput>
	<cfif NOT transactionsuccessful>
		<!---<div align="right" class="message">--->
		<div class="alert">
			<cfif CostCenterErrorString EQ "">
				Credit Card Authorization Failed.<br><br>Please enter your credit card information to try again.<br><br>
				<cfif ccc_ResponseCode NEQ "" OR ccc_ResponseReasonCode NEQ "">
					Code: #ccc_ResponseCode#&nbsp;&nbsp;&nbsp;&nbsp;Reason Code: #ccc_ResponseReasonCode#<br><br>
				</cfif>
				Reason: #ccc_ResponseReasonText#
			<cfelse>
				#CostCenterErrorString#<br><br>
				Please enter a valid Cost Center ID.<br><br>
				Need assistance - email #Application.OrdersAdminEmail#<br>
				or call 888.266.6108
			</cfif>
			<br><br>
		</div>
	</cfif>
	<table cellpadding="3" cellspacing="1" border="0" width="100%">
		
		<tr>
		<td class="active_cell" colspan="<cfif is_one_item GT 0 OR hide_points>1<cfelse>4</cfif>">#Translate(language_ID,'cart_contents')#</td>
		</tr>
		
		<tr>
		<td class="cart_cell"><b>#Translate(language_ID,'description_text')#</b></td>
		<cfif is_one_item EQ 0 AND NOT hide_points>
		<td class="cart_cell" align="center"><b>#Translate(language_ID,'quantity_text')#</b></td>
		<td class="cart_cell" colspan="2" align="center"><b>#credit_desc#</b></td>
		</cfif>
		</tr>
		
	 	<cfloop query="FindOrderItems">
			<tr>
			<td class="cart_cell">#snap_meta_name#<cfif snap_options NEQ ""><br>#snap_options#</cfif></td>
			<cfif is_one_item EQ 0 AND NOT hide_points>
			<td class="cart_cell" align="center">#quantity#</td>
			<td class="cart_cell">#NumberFormat(snap_productvalue * credit_multiplier,Application.NumFormat)# <span class="sub">#Translate(language_ID,'each_text')#</span></td>
			<td class="cart_cell" align="right">#NumberFormat(snap_productvalue * quantity * credit_multiplier,Application.NumFormat)#</td>
			</cfif>
			</tr>
			
			<cfset carttotal = carttotal + (snap_productvalue * quantity)>
		</cfloop>
		<cfset balance_due = 0>
		<cfif is_one_item EQ 0>
		<cfif accepts_cc LT 1 AND (user_total * points_multiplier) - (carttotal * credit_multiplier) LT 0>
			<cflocation url="cart.cfm?div=#request.division_ID#" addtoken="no">
		</cfif>
			<cfif NOT hide_points>
			<tr>
			<td align="right" colspan="3"><b>Order Total:</b> </td>
			<cfset num_format = Application.NumFormat>
			<cfif checkout_type EQ "costcenter">
				<cfset num_format = "___.__">
			</cfif>
			<td align="right"><b><cfif checkout_type EQ "costcenter">$ </cfif>#NumberFormat(carttotal * credit_multiplier,num_format)#</b></td>
			</tr>
			<cfif checkout_type NEQ "costcenter">
				<tr>
				<td align="right" colspan="4">&nbsp;</td>
				</tr>
				<tr>
				<td align="right" colspan="3"><b>Total #credit_desc#: </b></td>
				<td align="right"><b>#NumberFormat(user_total * points_multiplier,Application.NumFormat)#</b></td>
				</tr>
				<tr>
				<td align="right" colspan="3"><b>Less This Order:</b> </td>
				<td align="right"><b>#NumberFormat(carttotal * credit_multiplier,Application.NumFormat)#</b></td>
				</tr>
				<tr>
				<td align="right" colspan="3"><b>Remaining #credit_desc#:</b> </td>
				<td align="right"><b>#NumberFormat(Max( (user_total * points_multiplier) - (carttotal * credit_multiplier),0),Application.NumFormat)#</b></td>
				</tr>
			</cfif>
			</cfif>
			<cfif shipping_charge GT 0>
				<cfif signature_charge GT 0>
					<tr>
					<td align="right" colspan="3"><b>Signature Required Charge:</b> </td>
					<td align="right"><b>$ <span id="signature_charge">#NumberFormat(signature_charge,"___.__")#</span></b></td>
					</tr>
				</cfif>
				<tr>
				<td align="right" colspan="3"><b>Shipping <span id="ship_desc">#shipping_desc#</span>:</b> </td>
				<td align="right"><b>$ <span id="ship_charge">#NumberFormat(shipping_charge,"___.__")#</span></b></td>
				</tr>
			</cfif>
			<cfif cost_center_box_charge gt 0 AND checkout_type EQ "costcenter">
				<tr>
				<td align="right" colspan="3"><b>Box Charge:</b> </td>
				<td align="right"><b>$ <span id="box_charge">#NumberFormat(cost_center_box_charge,"___.__")#</span></b></td>
				</tr>
			</cfif>
			<cfif (user_total - carttotal LT 0 AND accepts_cc GTE 1) OR shipping_charge GT 0>
				<cfset balance_due = shipping_charge + signature_charge>
				<cfif cost_center_box_charge gt 0 AND checkout_type EQ "costcenter">
					<cfset balance_due = balance_due + cost_center_box_charge>
				</cfif>
				<cfif user_total - carttotal LT 0 AND accepts_cc GTE 1>
					<cfset balance_due = balance_due + (carttotal - user_total)>
				</cfif>
				<cfset this_num_format = Application.NumFormat>
				<cfif shipping_charge GT 0>
					<cfset this_num_format = "___.__">
				</cfif>
				<!--- there is a balance due --->
				<tr>
				<td align="right" colspan="3" class="alert">Balance Due: </td>
				<td class="alert" align="right" nowrap="nowrap">$&nbsp;<span id="total_due">#NumberFormat(balance_due,this_num_format)#</span></td>
				</tr>
			</cfif>
		</cfif>
	</table>
		
	<cfif uses_cost_center EQ 0 AND user_total - carttotal LT 0 AND accepts_cc GTE 1 AND is_one_item EQ 0><br><br><b>#cart_exceeded_msg#</b></cfif>

	<cfset alert_msg = "">
	<cfif has_divisions>
		<cfset div_total = 0>
		<cfset new_points = StructNew()>
		<cfloop query="GetDivisions">
			<cfif GetDivisions.points_assigned GT GetDivisions.points_awarded>
				<cfset alert_msg = alert_msg & "<li>You do not have #GetDivisions.points_assigned*points_multiplier# in #GetDivisions.program_name#.  You have #GetDivisions.points_awarded*points_multiplier#.</li>">
			</cfif>
			<cfset div_total = div_total + GetDivisions.points_assigned>
			<cfset new_points[GetDivisions.ID] = GetDivisions.points_assigned>
		</cfloop>
		<cfif carttotal NEQ div_total>
			<cfset this_diff = carttotal-div_total>
			<cfset total_diff = ABS(this_diff)>
			<cfset max_diff = GetDivisions.recordcount + 1>
			<cfif total_diff GT max_diff>
				<cfif assign_div_points>
				<cfset alert_msg = alert_msg & "<li>You assigned a total of #div_total*points_multiplier# #credit_desc#.  Order total is #carttotal*points_multiplier#.</li>">
				</cfif>
			<cfelse>
				<cfset do_redirect = true>
				<cfquery name="DeleteXref" datasource="#application.DS#">
					DELETE FROM #application.database#.xref_order_division
					WHERE order_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">
				</cfquery>
				<cfloop query="GetDivisions">
					<cfset thisDiv = GetDivisions.ID>
					<cfset thisPts = GetDivisions.points_assigned>
					<cfif total_diff GT 0>
						<cfif this_diff GT 0>
							<cfset thisPts = thisPts + 1>
							<cfif total_diff EQ max_diff>
								<cfset thisPts = thisPts + 1>
								<cfset total_diff = total_diff - 1>
							</cfif>
							<cfset this_diff = this_diff - 1>
						<cfelseif this_diff LT 0>
							<cfset thisPts = thisPts - 1>
							<cfif total_diff EQ max_diff>
								<cfset thisPts = thisPts - 1>
								<cfset total_diff = total_diff - 1>
							</cfif>
							<cfset total_diff = total_diff - 1>
						</cfif>
					</cfif>
					<cfif thisPts LT 0>
						<cfset do_redirect = false>
					<cfelse>
						<cfquery name="StartOrder" datasource="#application.DS#">
							INSERT INTO #application.database#.xref_order_division
								(created_user_ID, created_datetime, order_ID, division_ID, award_points)
							VALUES (
								<cfqueryparam cfsqltype="cf_sql_integer" value="#user_ID#" maxlength="10">,
								'#FLGen_DateTimeToMySQL()#',
								<cfqueryparam cfsqltype="cf_sql_integer" value="#order_ID#" maxlength="10">,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#thisDiv#" maxlength="10">,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#thisPts#" maxlength="10">
							)
						</cfquery>
					</cfif>
				</cfloop>
				<cfif total_diff EQ 0 AND do_redirect>
					<cflocation url="checkout.cfm?div=#request.division_ID#" addtoken="false">
				</cfif>
			</cfif>
		</cfif>
	</cfif>
			
	<cfif alert_msg NEQ "">
		<br><br>
		<span class="page_instructions">The following errors were found:<br></span>
		<span class="alert"><ul>#alert_msg#</ul></span>
	</cfif>
	<br><br>
	<div align="center"><a href="cart.cfm?div=#request.division_ID#">#Translate(language_ID,'return_to_cart')#</a></div>
	<br><br>
	<cfif alert_msg EQ "">
	<form method="post" action="#CurrentPage#?div=#request.division_ID#" name="order_form" >
	
	#Translate(language_ID,'bold_fields_required')#
	<br><br>
	
		<input type="hidden" name="place_order" value="0" />
		<input type="hidden" name="checkout_type" value="#checkout_type#">
		<input type="hidden" name="ship_overseas" value="#ship_overseas#">
		<table cellpadding="3" cellspacing="1" border="0" width="100%">
		
		<tr>
		<td class="active_cell" colspan="2">#Translate(language_ID,'your_name')#</td>
		</tr>
		
		<tr>
		<td align="right"><strong><span id="label_snap_fname">#Translate(language_ID,'first_name')#</span></strong>&nbsp;</td>
		<td><input type="text" size="60" maxlength="30" name="snap_fname" id="snap_fname" value="#fname#">
		<!--- input type="hidden" name="snap_fname_required" value="Please enter a first name." ---></td>
		</tr>
			
		<tr>
		<td align="right"><strong><span id="label_snap_lname">#Translate(language_ID,'last_name')#</span></strong>&nbsp;</td>
		<td><input type="text" size="60" maxlength="30" name="snap_lname" id="snap_lname" value="#lname#">
		<!--- input type="hidden" name="snap_lname_required" value="Please enter a last name." ---></td>
		</tr>
	<cfif get_shipping_address>
		<tr>
		<td class="active_cell" colspan="2">Shipping Information&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox" name="namesame" onClick="SameName()"> <span style="font-weight:normal">Use first and last name from above.</span></td>
		</tr>
		
		<tr>
		<td align="right">Company&nbsp;</td>
		<td><input type="text" size="60" maxlength="30" name="snap_ship_company" value="#left(ship_company,30)#"></td>
		</tr>
		
		<tr>
		<td align="right"><b><span id="label_snap_ship_fname">First&nbsp;Name</span></b>&nbsp;</td>
		<td><input type="text" size="60" maxlength="30" name="snap_ship_fname" id="snap_ship_fname" value="#ship_fname#">
		<!--- input type="hidden" name="snap_ship_fname_required" value="Please enter a first name for shipping." ---></td>
		</tr>
			
		<tr>
		<td align="right"><b><span id="label_snap_ship_lname">Last&nbsp;Name</span></b>&nbsp;</td>
		<td><input type="text" size="60" maxlength="30" name="snap_ship_lname" id="snap_ship_lname" value="#ship_lname#">
		<!--- input type="hidden" name="snap_ship_lname_required" value="Please enter a last name for shipping." ---></td>
		</tr>
		<cfif shipping_location_ID gt 0>
			<input type="hidden" name="shipping_location_ID" value="#shipping_location_ID#">
			<input type="hidden" name="snap_ship_address1" id="snap_ship_address1" value="#left(GetSelectedShippingLocation.address1,30)#">
			<input type="hidden" name="snap_ship_address2" value="#GetSelectedShippingLocation.address2#">

			<input type="hidden" name="address1" value="#left(GetSelectedShippingLocation.address1,30)#">
			<input type="hidden" name="address2" value="#GetSelectedShippingLocation.address2#">
			<input type="hidden" name="city" value="#GetSelectedShippingLocation.city#" />
			<input type="hidden" name="state" value="#GetSelectedShippingLocation.state#" />
			<input type="hidden" name="zipcode" value="#GetSelectedShippingLocation.zip#" />
			<input type="hidden" id="snap_ship_city" name="snap_ship_city" value="#GetSelectedShippingLocation.city#" />
			<input type="hidden" id="snap_ship_state" name="snap_ship_state" value="#GetSelectedShippingLocation.state#" />
			<input type="hidden" id="snap_ship_zip"name="snap_ship_zip" value="#GetSelectedShippingLocation.zip#" />
			<tr>
			<td align="right"><b><span id="label_snap_ship_address1">Address</span></b>&nbsp;</td>
			<td>#left(GetSelectedShippingLocation.address1,30)#
			</tr>
			<tr>
			<td align="right"></td>
			<td>#GetSelectedShippingLocation.address2#</td>
			</tr>
			<tr><td align="right"><strong><span id="label_snap_ship_city">City</span>, <span id="label_snap_ship_state">State</span> <span id="label_snap_ship_zip">Zip Code</span></strong> </td><td>
			#GetSelectedShippingLocation.city#,&nbsp;&nbsp;#GetSelectedShippingLocation.state#&nbsp;&nbsp;&nbsp;&nbsp;#GetSelectedShippingLocation.zip#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			</td></tr>
		<cfelse>
		<cfif charge_shipping>
			<tr>
			<td align="right"><b><span id="label_snap_ship_address1">Address&nbsp;Line&nbsp;1</span></b>&nbsp;</td>
			<td>&nbsp;&nbsp;&nbsp;&nbsp;#left(address1,30)#</td>
			</tr>
			<input type="hidden" name="address1" value="#address1#" />
			<input type="hidden" id="snap_ship_address1" name="snap_ship_address1" value="#address1#" />
			<tr>
			<td align="right"><b><span id="label_snap_ship_address2">Address&nbsp;Line&nbsp;2</span></b>&nbsp;</td>
			<td>&nbsp;&nbsp;&nbsp;&nbsp;#left(address2,30)#</td>
			</tr>
			<input type="hidden" name="address2" value="#address2#" />
			<input type="hidden" id="snap_ship_address2" name="snap_ship_address2" value="#address2#" />
		<cfelse>
			<tr>
			<td align="right"><b><span id="label_snap_ship_address1">Address&nbsp;Line&nbsp;1</span></b>&nbsp;</td>
			<td><input type="text" size="60" maxlength="30" name="snap_ship_address1" id="snap_ship_address1" value="#left(ship_address1,30)#">
			</tr>
			<tr>
			<td align="right">Address&nbsp;Line&nbsp;2&nbsp;</td>
			<td><input type="text" size="60" maxlength="30" name="snap_ship_address2" value="#ship_address2#"></td>
			</tr>
		</cfif>
		<cfif charge_shipping>
			<tr><td align="right"><strong><span id="label_snap_ship_city">City</span>, <span id="label_snap_ship_state">State</span> <span id="label_snap_ship_zip">Zip Code</span></strong> </td><td>
			<input type="hidden" name="city" value="#city#" />
			<input type="hidden" name="state" value="#state#" />
			<input type="hidden" name="zipcode" value="#zipcode#" />
			<input type="hidden" id="snap_ship_city" name="snap_ship_city" value="#city#" />
			<input type="hidden" id="snap_ship_state" name="snap_ship_state" value="#state#" />
			<input type="hidden" id="snap_ship_zip"name="snap_ship_zip" value="#zipcode#" />
			&nbsp;&nbsp;&nbsp;&nbsp;#city#,&nbsp;&nbsp;#state#&nbsp;&nbsp;&nbsp;&nbsp;#zipcode#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="#CGI.SCRIPT_NAME#?checkout_type=#checkout_type#&div=#request.division_ID#"><font color="##0000ff">Change shipping address</font></a>
			</td></tr>
		<cfelse>
			<tr>
			<td align="right"><b><span id="label_snap_ship_city">City</span></b> </td>
			<td valign="top"><input type="text" name="snap_ship_city" id="snap_ship_city" value="#ship_city#" maxlength="30" size="60">
			</tr>
			
			<tr>
			<td align="right" valign="top"><b><span id="label_snap_ship_state">State</span></b> </td>
			<td valign="top"><cfoutput>#FLGen_SelectState("snap_ship_state","#ship_state#","true")#</cfoutput> <span class="sub">(select last option if international)</span></td>
			</tr>
			
			<tr>
			<td align="right"><b><span id="label_snap_ship_zip">Zip Code</span></b> </td>
			<td valign="top"><input type="text" name="snap_ship_zip" id="snap_ship_zip" value="#ship_zip#" maxlength="10" size="60">
			</tr>
			
		</cfif>
		</cfif>
	<cfelse>
		<input type="hidden" name="snap_ship_company" value="#left(ship_company,30)#">
		<input type="hidden" name="snap_ship_fname" value="#ship_fname#">
		<input type="hidden" name="snap_ship_lname" value="#ship_lname#">
		<input type="hidden" name="snap_ship_address1" value="#left(ship_address1,30)#">
		<input type="hidden" name="snap_ship_address2" value="#ship_address2#">
		
		<input type="hidden" name="city" value="#city#" />
		<input type="hidden" name="state" value="#state#" />
		<input type="hidden" name="zipcode" value="#zipcode#" />
		<input type="hidden" id="snap_ship_city" name="snap_ship_city" value="#city#" />
		<input type="hidden" id="snap_ship_state" name="snap_ship_state" value="#state#" />
		<input type="hidden" id="snap_ship_zip"name="snap_ship_zip" value="#zipcode#" />
		
		</cfif>
		<tr>
		<td align="right"><strong><span id="label_snap_phone">#Translate(language_ID,'phone_text')#</span></strong> </td>
		<td><input type="text" size="60" maxlength="35" name="snap_phone" id="snap_phone" value="#phone#">
		<!--- input type="hidden" name="snap_phone_required" value="Please enter a daytime phone number." ---></td>
		</tr>
			
		<tr>
		<td align="right"><strong><span id="label_snap_email">#Translate(language_ID,'email_text')#</span></strong> </td>
		
		<td>
			<cfif trim(register_email_domain) neq ''>
				<input type="hidden" name="snap_email" id="snap_email" value="#email#">#email#
			<cfelse> 
				<input type="text" size="60" maxlength="128" name="snap_email" id="snap_email" value="#email#">
			</cfif>
			<!--- input type="hidden" name="snap_email_required" value="Please enter an email." --->
			</td>
		</tr>
		<cfif charge_shipping and get_shipping_address>
			<tr>
			<td class="active_cell" colspan="4">Shipping Options</td>
			</tr>
						<tr><td colspan="2">
						<tr>
							<td align="right"><strong>Shipping</strong></td>
							<td>
							<cfif ArrayLen(Shipping_Price_Array) GT 0>
								<cfif shipping_location_ID gt 0>
									<input type="hidden" name="ship_type" value="1">
									<cfif ArrayLen(Shipping_Price_Array[1]) gt 0>
									#Shipping_Price_Array[1][2]# - #DollarFormat(Shipping_Price_Array[1][3])#
									<cfelse>
										International Shipping
									</cfif>
								<cfelse>
									<select id="id_ship_type" name="ship_type" onchange="updateShipping();">
										<cfloop from="1" to="#ArrayLen(Shipping_Price_Array)#" index="i">
											<option value="#i#"<cfif ship_type EQ i> selected</cfif>>#Shipping_Price_Array[i][2]# - #DollarFormat(Shipping_Price_Array[i][3])#</option>
										</cfloop>
									</select>
								</cfif>
							<cfelse>
								<strong>Shipping options are unavailable.  We will invoice you separately for shipping.</strong>
							</cfif>
						<!--- </cfif> --->
							</td>
						</tr>
		</cfif>
		<!--- only if there is a balance due --->
		<!--- only if there is a balance due --->
		<!--- only if there is a balance due --->
		
		<cfif (user_total - carttotal LT 0 AND accepts_cc GTE 1 AND is_one_item EQ 0) OR charge_shipping>
			<cfif uses_cost_center GT 0>
				<cfset cost_center_charge = balance_due>
			</cfif>

			<cfif uses_cost_center GT 0>
				<tr>
					<td class="active_cell" colspan="4">Cost Center</td>
				</tr>
				<tr>
					<td align="right"><b><span id="label_cost_center_number">Enter Cost Center ID</span></b>&nbsp;</td>
					<td><input type="text" size="7" maxlength="5" name="cost_center_number" id="cost_center_number"></td>
				</tr>
				<input type="hidden" name="cost_center_charge" id="cost_center_charge" value="#cost_center_charge#">				
				<!---<tr>
					<td align="right"><b><span id="label_cost_center_charge">Charge to Cost Center</span></b>&nbsp;</td>
					<td>$<input type="text" size="7" maxlength="8" name="cost_center_charge" id="cost_center_charge" value="#cost_center_charge#"></td>
				</tr>--->
			</cfif>
			<cfif uses_cost_center EQ 0>
				<tr>
				<td class="active_cell" colspan="4">Credit Card Information</td>
				</tr>
					
				<tr>
				<td>&nbsp;</td>
				<td><img src="pics/creditcards.jpg" width="168" height="23"></td>
				</tr>
			</cfif>
			<cfif uses_cost_center GT 0>
				<input type="hidden" name="credit_card_charge" id="credit_card_charge" value="#credit_card_charge#">
				<!---<tr>
					<td align="right"><b><span id="label_credit_card_charge">Charge to Credit Card</span></b>&nbsp;</td>
					<td>$<input type="text" size="7" maxlength="8" name="credit_card_charge" id="credit_card_charge" value="#credit_card_charge#"></td>
				</tr>--->
			</cfif>
			<cfif uses_cost_center EQ 0>
				<tr>
				<td align="right"><b><span id="label_credit_card_number">Card Number</span></b>&nbsp;</td>
				<td><input type="text" size="18" maxlength="16" name="credit_card_number" id="credit_card_number">
				&nbsp;&nbsp;&nbsp;&nbsp;<b>Expires:</b>&nbsp;#FLGen_SelectCCMonths()# #FLGen_SelectCCYears()#
				</td>
				</tr>
				
				<tr>
				<td align="right"><b><span id="label_cid_number">CID</span></b>&nbsp;</td>
				<td><input type="text" size="5" maxlength="5" name="cid_number" id="cid_number"> <!--- input type="hidden" name="cid_number_required" value="Please enter a CID number." ---> <a href="checkout_CID.cfm" target="_blank">What is the CID?</a>
				</td>
				</tr>
				
				<tr>
				<td class="active_cell" colspan="2">Billing Information&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox" name="billingsame" onClick="CopyAddress()"> <span style="font-weight:normal">Same as shipping information.</span></td>
				</tr>
				
				<tr>
				<td align="right">Company&nbsp;</td>
				<td><input type="text" size="60" maxlength="30" name="snap_bill_company" value="#bill_company#"></td>
				</tr>
				
				<tr>
				<td align="right"><b><span id="label_snap_bill_fname">First&nbsp;Name</span></b>&nbsp;</td>
				<td><input type="text" size="60" maxlength="30" name="snap_bill_fname" id="snap_bill_fname" value="#bill_fname#">
				</tr>
					
				<tr>
				<td align="right"><b><span id="label_snap_bill_lname">Last&nbsp;Name</span></b>&nbsp;</td>
				<td><input type="text" size="60" maxlength="30" name="snap_bill_lname" id="snap_bill_lname" value="#bill_lname#">
				</tr>
					
				<tr>
				<td align="right"><b><span id="label_snap_bill_address1">Address&nbsp;Line&nbsp;1</span></b>&nbsp;</td>
				<td><input type="text" size="60" maxlength="30" name="snap_bill_address1" id="snap_bill_address1" value="#bill_address1#">
				</tr>
				
				<tr>
				<td align="right">Address&nbsp;Line&nbsp;2&nbsp;</td>
				<td><input type="text" size="60" maxlength="30" name="snap_bill_address2" value="#bill_address2#"></td>
				</tr>
				
				<tr>
				<td align="right"><b><span id="label_snap_bill_city">City</span></b> </td>
				<td valign="top"><input type="text" name="snap_bill_city" id="snap_bill_city" value="#bill_city#" maxlength="30" size="60">
				</tr>
				
				<tr>
				<td align="right" valign="top"><b>State</b> </td>
				<td valign="top"><cfset FLGen_SelectState("snap_bill_state","#bill_state#","true")> <span class="sub">(select last option if international)</span></td>
				</tr>
				
				<tr>
				<td align="right"><b><span id="label_snap_bill_zip">Zip</span></b> </td>
				<td valign="top"><input type="text" name="snap_bill_zip" id="snap_bill_zip" value="#bill_zip#" maxlength="10" size="60">
				</tr>
			</cfif>
		</cfif>
	
		<tr>
		<td class="active_cell" colspan="4">#Translate(language_ID,'special_instructions')#</td>
		</tr>
		<cfif ship_overseas EQ "1" and shipping_location_message3 neq "">
			<tr>
				<td colspan="2">
					#shipping_location_message3#
				</td>
			</tr>
		</cfif>
		<tr>
		<td align="right" valign="top">&nbsp;</td>
		<td><textarea name="order_note" cols="58" rows="4"></textarea></td>
		</tr>
		
		<tr>
		<td align="center" valign="top" colspan="2"><b><cfif get_shipping_address>Please review the shipping information before placing your order.<br><br></cfif>#delivery_message#</b></td>
		</tr>
		
		<tr>
		<td colspan="2" align="center">
			
			<table cellpadding="8" cellspacing="1" border="0">
				
			<tr id="active_place_order">
			<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="validateOnSubmit();">#Translate(language_ID,'place_order')#</td>
			</tr>
			<tr id="inactive_place_order" style="display:none;">
			<td align="center" class="product_select sub">#Translate(language_ID,'place_order')#</td>
			</tr>
			
			</table>
		
		</td>
		</tr>
		
		</table>
	
	
	</form>
	</cfif>
	</cfoutput>
		<cfif NOT require_email_address>
			<script language="javascript">
				labelArray = new Array("snap_fname","snap_lname","snap_ship_fname","snap_ship_lname","snap_ship_address1","snap_ship_city","snap_ship_state","snap_ship_zip","snap_phone"<cfif (user_total - carttotal LT 0 AND accepts_cc GTE 1 AND is_one_item EQ 0) OR charge_shipping>,"cost_center_number","credit_card_number","cid_number","snap_bill_fname","snap_bill_lname","snap_bill_address1","snap_bill_city","snap_bill_zip"</cfif>);
			</script>
		<cfelseif get_shipping_address>
			<script language="javascript">
				labelArray = new Array("snap_fname","snap_lname","snap_ship_fname","snap_ship_lname","snap_ship_address1","snap_ship_city","snap_ship_state","snap_ship_zip","snap_phone","snap_email"<cfif (user_total - carttotal LT 0 AND accepts_cc GTE 1 AND is_one_item EQ 0) OR charge_shipping>,"cost_center_number","credit_card_number","cid_number","snap_bill_fname","snap_bill_lname","snap_bill_address1","snap_bill_city","snap_bill_zip"</cfif>);
			</script>
		<cfelse>
			<script language="javascript">
				labelArray = new Array("snap_fname","snap_lname","snap_phone","snap_email"<cfif (user_total - carttotal LT 0 AND accepts_cc GTE 1 AND is_one_item EQ 0) OR charge_shipping>,"cost_center_number","credit_card_number","cid_number","snap_bill_fname","snap_bill_lname","snap_bill_address1","snap_bill_city","snap_bill_zip"</cfif>);
			</script>
		</cfif>
	</cfif>

	<!--- -------------------- --->
	<!--- End of checkout form --->
	<!--- -------------------- --->

</cfif>
	
<cfinclude template="includes/footer.cfm">
