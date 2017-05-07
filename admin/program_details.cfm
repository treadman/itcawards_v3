<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- Verify that a program was selected --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cflocation url="program_list.cfm" addtoken="no">
</cfif>
<cfset edit_division = false>
<cfif isNumeric(request.selected_division_ID) AND request.selected_division_ID GT 0>
	<cfset edit_division = true>
</cfif>


<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfquery name="ToBeEdited" datasource="#application.DS#">
	SELECT parent_ID, company_name, program_name, expiration_date, is_one_item, can_defer, defer_msg, has_welcomepage,
		welcome_bg, welcome_instructions, welcome_message, welcome_congrats, welcome_button, welcome_admin_button,
		admin_logo, logo, cross_color, main_bg, main_congrats, main_instructions, return_button, text_active,
		bg_active, text_selected, bg_selected, cart_exceeded_msg, cc_exceeded_msg, orders_to, orders_from,
		conf_email_text, program_email_subject, has_survey, display_col, display_row, menu_text, credit_desc,
		accepts_cc, login_prompt, is_active, display_welcomeyourname, display_youhavexcredits, credit_multiplier, points_multiplier,
		email_form_button, email_form_message, additional_content_button, additional_content_message, help_button,
		help_message, additional_content_button_unapproved, additional_content_message_unapproved, has_password_recovery, use_master_categories,
		has_register, register_email_domain, register_page_text, email_login, cc_shipping, charge_shipping, add_shipping, signature_charge,
		get_shipping_address, show_thumbnail_in_cart,bg_warning, one_item_over_message, delivery_message, uses_shipping_locations,
		inactivate_zero_inventory, show_inventory, cost_center_notification
	FROM #application.database#.program
	WHERE ID = 
	<cfif isNumeric(request.selected_division_ID) AND request.selected_division_ID GT 0>
		<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
	<cfelse>
		<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfif>
</cfquery>
<cfset parent_ID = ToBeEdited.parent_ID>
<cfset company_name = htmleditformat(ToBeEdited.company_name)>
<cfset program_name = htmleditformat(ToBeEdited.program_name)>
<cfset expiration_date = FLGen_DateTimeToDisplay(htmleditformat(ToBeEdited.expiration_date))>
<cfset is_one_item = htmleditformat(ToBeEdited.is_one_item)>
<cfset can_defer = htmleditformat(ToBeEdited.can_defer)>
<cfset defer_msg = htmleditformat(ToBeEdited.defer_msg)>
<cfset has_welcomepage = htmleditformat(ToBeEdited.has_welcomepage)>
<cfset welcome_bg = htmleditformat(ToBeEdited.welcome_bg)>
<cfset welcome_instructions = htmleditformat(ToBeEdited.welcome_instructions)>
<cfset welcome_message = htmleditformat(ToBeEdited.welcome_message)>
<cfset welcome_congrats = htmleditformat(ToBeEdited.welcome_congrats)>
<cfset welcome_button = htmleditformat(ToBeEdited.welcome_button)>
<cfset welcome_admin_button = htmleditformat(ToBeEdited.welcome_admin_button)>
<cfset admin_logo = htmleditformat(ToBeEdited.admin_logo)>
<cfset logo = htmleditformat(ToBeEdited.logo)>
<cfset cross_color = htmleditformat(ToBeEdited.cross_color)>
<cfset main_bg = htmleditformat(ToBeEdited.main_bg)>
<cfset main_congrats = htmleditformat(ToBeEdited.main_congrats)>
<cfset main_instructions = htmleditformat(ToBeEdited.main_instructions)>
<cfset return_button = htmleditformat(ToBeEdited.return_button)>
<cfset welcome_bg = htmleditformat(ToBeEdited.welcome_bg)>
<cfset text_active = htmleditformat(ToBeEdited.text_active)>
<cfset bg_active = htmleditformat(ToBeEdited.bg_active)>
<cfset bg_warning = htmleditformat(ToBeEdited.bg_warning)>
<cfset text_selected = htmleditformat(ToBeEdited.text_selected)>
<cfset bg_selected = htmleditformat(ToBeEdited.bg_selected)>
<cfset cart_exceeded_msg = htmleditformat(ToBeEdited.cart_exceeded_msg)>
<cfset cc_exceeded_msg = htmleditformat(ToBeEdited.cc_exceeded_msg)>
<cfset orders_to = htmleditformat(ToBeEdited.orders_to)>
<cfset orders_from = htmleditformat(ToBeEdited.orders_from)>
<cfset conf_email_text = htmleditformat(ToBeEdited.conf_email_text)>
<cfset program_email_subject = htmleditformat(ToBeEdited.program_email_subject)>
<cfset has_survey = htmleditformat(ToBeEdited.has_survey)>
<cfset display_col = htmleditformat(ToBeEdited.display_col)>
<cfset display_row = htmleditformat(ToBeEdited.display_row)>
<cfset menu_text = htmleditformat(ToBeEdited.menu_text)>
<cfset credit_desc = htmleditformat(ToBeEdited.credit_desc)>
<cfset accepts_cc = htmleditformat(ToBeEdited.accepts_cc)>
<cfset login_prompt = htmleditformat(ToBeEdited.login_prompt)>
<cfset is_active = htmleditformat(ToBeEdited.is_active)>
<cfset display_welcomeyourname = htmleditformat(ToBeEdited.display_welcomeyourname)>
<cfset display_youhavexcredits = htmleditformat(ToBeEdited.display_youhavexcredits)>
<cfset credit_multiplier = ToBeEdited.credit_multiplier>
<cfset points_multiplier = ToBeEdited.points_multiplier>
<cfset email_form_button = htmleditformat(ToBeEdited.email_form_button)>
<cfset email_form_message = ToBeEdited.email_form_message>
<cfset additional_content_button = htmleditformat(ToBeEdited.additional_content_button)>
<cfset additional_content_message = ToBeEdited.additional_content_message>
<cfset help_button = htmleditformat(ToBeEdited.help_button)>
<cfset help_message = ToBeEdited.help_message>
<cfset additional_content_button_unapproved = htmleditformat(ToBeEdited.additional_content_button_unapproved)>
<cfset additional_content_message_unapproved = ToBeEdited.additional_content_message_unapproved>
<cfset has_password_recovery = ToBeEdited.has_password_recovery>
<cfset use_master_categories = ToBeEdited.use_master_categories>
<cfset has_register = ToBeEdited.has_register>
<cfset register_email_domain = ToBeEdited.register_email_domain>
<cfset register_page_text = htmleditformat(ToBeEdited.register_page_text)>
<cfset email_login = ToBeEdited.email_login>
<cfset cc_shipping = ToBeEdited.cc_shipping>
<cfset charge_shipping = ToBeEdited.charge_shipping>
<cfset add_shipping = ToBeEdited.add_shipping>
<cfset signature_charge = ToBeEdited.signature_charge>
<cfset get_shipping_address = ToBeEdited.get_shipping_address>
<cfset show_thumbnail_in_cart = ToBeEdited.show_thumbnail_in_cart>
<cfset one_item_over_message = ToBeEdited.one_item_over_message>
<cfset delivery_message = ToBeEdited.delivery_message>
<cfset uses_shipping_locations = ToBeEdited.uses_shipping_locations>
<cfset inactivate_zero_inventory = ToBeEdited.inactivate_zero_inventory>
<cfset show_inventory = ToBeEdited.show_inventory>
<cfset cost_center_notification = htmleditformat(ToBeEdited.cost_center_notification)>

<cfif edit_division>
	<cfquery name="GetParent" datasource="#application.DS#">
		SELECT ID, company_name, program_name
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cfif GetParent.ID NEQ parent_ID>
		<cflocation url="program_list.cfm" addtoken="no">
	</cfif>
	<cfquery name="GetSubdivisions" datasource="#application.DS#">
		SELECT ID, subdivision_name
		FROM #application.database#.subdivisions
		WHERE division_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
	</cfquery>
<cfelse>
	<cfquery name="GetDivisions" datasource="#application.DS#">
		SELECT ID, company_name, program_name
		FROM #application.database#.program
		WHERE parent_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
</cfif>
	
<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset request.main_width="1200">
<cfset leftnavon = "programs">
<cfinclude template="includes/header.cfm">

<cfoutput>
	<span class="pagetitle">
		<cfif edit_division>
			<span class="highlight">Division Details for #program_name#</span> - a division of #request.program_name#
		<cfelse>
			Award Program Details for #request.program_name# - <a href="program_division.cfm?pgfn=add" onClick="return confirm('Are you sure you want to add a division?');">Add Division</a>
		</cfif>
	</span>
	<br /><br />
	<span class="pageinstructions">Return to <a href="program_list.cfm?division_select=">Award Program List</a><cfif edit_division> or the <a href="program_details.cfm?division_select=">Parent Program Details</a></cfif>.</span>
	<br /><br />

	<!---  * * * * * * * * *  --->
	<!---      DIVISIONS      --->
	<!---  * * * * * * * * *  --->
	<cfif NOT edit_division>
		<cfif GetDivisions.recordCount GT 0>
			<table cellpadding="5" cellspacing="0" border="0" width="100%">
				<tr class="contenthead">
					<td colspan="2" class="headertext">Divisions</td>
				</tr>
				<cfloop query="GetDivisions">
					<tr class="content">
					<td valign="top" class="content_details">
						<a href="program_details.cfm?division_select=#GetDivisions.ID#">#GetDivisions.company_name#</a><br>
					</td>
					</tr>
				</cfloop>	
					<tr class="content">
					<td valign="top" class="content_details">
					</td>
					</tr>
			</table>
			<br>
		</cfif>		
	</cfif>
	<cfif request.has_divisions AND edit_division>
		<cfset unassigned_points = hasUserUnassignedPoints()>
	</cfif>
	<!---  * * * * * * * * *  --->
	<!--- GENERAL INFORMATION --->
	<!---  * * * * * * * * *  --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td class="headertext <cfif edit_division>highlight</cfif>"><a href="program_general.cfm?pgfn=edit">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;General Information</td>
	<td class="<cfif edit_division>highlight</cfif>" align="right">
		<cfif request.has_divisions AND edit_division>
			<cfif unassigned_points.recordcount GT 0>
				There are #unassigned_points.total# unassigned points.
				<cfif GetSubdivisions.recordcount EQ 0>
					<a href="program_division.cfm?pgfn=unassigned_points" onClick="return confirm('Are you sure you want to set all unassigned points to #company_name#?');">Set all unassigned points to this division</a>
				<cfelse>
					Set all unassigned points to:
					<a href="program_division.cfm?pgfn=unassigned_points" onClick="return confirm('Are you sure you want to set all unassigned points to #company_name# with no subdivision?');">#company_name# - no subdivision</a><br><br>
					<cfloop query="GetSubdivisions">
						<a href="program_division.cfm?pgfn=unassigned_points&subdivision_id=#GetSubdivisions.ID#" onClick="return confirm('Are you sure you want to set all unassigned points to this #company_name# - #GetSubdivisions.subdivision_name# ?');">#company_name# - #GetSubdivisions.subdivision_name#</a><br><br>
					</cfloop>
				</cfif>
			</cfif>
		</cfif>
	</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details">
   <b>#company_name# [#program_name#]</b> expires #expiration_date#<br><br>
	This Award Program:<br>
	&nbsp;&nbsp;&nbsp; is <b><cfif is_active EQ 1>Active<cfelse><em>Inactive</em></cfif></b><br>
	&nbsp;&nbsp;&nbsp; <b><cfif has_survey EQ 1>has<cfelse><em>does not have</em></cfif></b> a survey.<br>
	&nbsp;&nbsp;&nbsp; is a <b><cfif is_one_item EQ 0>multiple item<cfelse><cfif is_one_item EQ 1>one-item<cfelseif is_one_item EQ 2>two-item<cfelse>ERROR</cfif></cfif></b> store.<br>
	&nbsp;&nbsp;&nbsp; <b><cfif has_password_recovery>has<cfelse><em>does not have</em></cfif></b> password recovery.<br>
	&nbsp;&nbsp;&nbsp; <b><cfif email_login><em>requires</em><cfelse>does not require</cfif></b> email login.<br>
	&nbsp;&nbsp;&nbsp;
	<cfswitch expression="#use_master_categories#">
		<cfcase value="0"><!--- 1 went to 0--->
			uses old-style <b>category buttons</b> with <b>master categories</b>.
		</cfcase>
		<cfcase value="1"><!--- 0 went to 1--->
			uses old-style <b>category buttons</b> with <b>search options</b>.
		</cfcase>
		<cfcase value="2"><!--- 0.5 went to 2--->
			uses stacked <b>category buttons</b> with <b>search options</b>.
		</cfcase>
		<cfcase value="3"><!--- 2 went to 3--->
			uses new-style <b>category tabs</b> with <b>master categories</b>.
		</cfcase>
		<cfcase value="4"><!--- 3 went to 4--->
			uses new-style <b>category tabs</b> with <b>search options</b>.
		</cfcase>
		<cfdefaultcase>
			<span class="alert">Category style not set!</span>
		</cfdefaultcase>
	</cfswitch>
	<br>
	<cfif edit_division AND GetSubdivisions.recordcount GT 0>
		&nbsp;&nbsp;&nbsp; has <b>subdivisions</b>:<br>
		<cfloop query="GetSubdivisions">	
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;
			#GetSubdivisions.subdivision_name#
		</cfloop>
	</cfif>
	<br>
	</td>
	<td></td>
	</tr>
	
	</table>
	
	<br>
	
	<!---  * * * * * * * * * * * --->
	<!--- AWARD CREDITS AND CREDIT CARDS --->
	<!---  * * * * * * * * * * * --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><a href="program_credit.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;Award Credits, Credit Cards, Shopping Cart and Shipping Info</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap"><b>Award Credit</b> Description:</td>
	<td valign="top" width="100%">#credit_desc#<cfif credit_desc EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap"><b>Product</b> Multiplier:</td>
	<td valign="top"><cfif credit_multiplier NEQ "">#NumberFormat(credit_multiplier,Application.NumFormat)#<cfelse>#NumberFormat(1,Application.NumFormat)#</cfif></td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap"><b>Award Points</b> Multiplier:</td>
	<td valign="top"><cfif points_multiplier NEQ "">#NumberFormat(points_multiplier,Application.NumFormat)#<cfelse>#NumberFormat(1,Application.NumFormat)#</cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Exceeded <b>Award Credit</b> Message: </td>
	<td valign="top">#cart_exceeded_msg#<cfif cart_exceeded_msg EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Can users <b>Defer</b> Award Credits?:</td>
	<td valign="top"><cfif can_defer EQ 1>Yes<cfelse>No</cfif></td>
	</tr>

	<cfif can_defer EQ 1>
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Message above <b>Defer</b> button:
	<td valign="top">#defer_msg#<cfif defer_msg EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	</cfif>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Accepts <b>Credit Cards</b>?:</td>
	<td valign="top"><cfif accepts_cc EQ 0>No<cfelseif accepts_cc EQ 1>Yes with credit card maximum<cfelseif #accepts_cc# EQ 2>Yes without credit card maximum</cfif></td>
	</tr>

	<cfif accepts_cc EQ 1>
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Exceeded <b>Credit Card</b><br>Maximum Message:
	<td valign="top">#cc_exceeded_msg#<cfif cc_exceeded_msg EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	</cfif>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Charge for Shipping?:</td>
	<td valign="top"><cfif charge_shipping EQ "">No<cfelse>Yes - Beginning on #DateFormat(charge_shipping,"mm/dd/yyyy")#</cfif></td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Charge shipping on orders when user has NO points?:</td>
	<td valign="top">#YesNoFormat(cc_shipping)#</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Additional Shipping Charge:</td>
	<td valign="top">$#NumberFormat(add_shipping,"0.00")#</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Signature Required Charge:</td>
	<td valign="top">$#NumberFormat(signature_charge,"0.00")#</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Get Shipping Address:</td>
	<td valign="top">#YesNoFormat(get_shipping_address)#</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Use Shipping Locations:</td>
	<td valign="top">#YesNoFormat(uses_shipping_locations)#</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Inactivate Products with no Inventory:</td>
	<td valign="top">#YesNoFormat(inactivate_zero_inventory)#</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Show Inventory On Hand:</td>
	<td valign="top">
		<cfswitch expression="#show_inventory#">
			<cfcase value="0">
				No
			</cfcase>
			<cfcase value="1">
				Only on Product Page
			</cfcase>
			<cfcase value="2">
				Only on Main Page
			</cfcase>
			<cfcase value="3">
				On both Product and Main Page
			</cfcase>
			<cfdefaultcase>
				<span class="alert">#show_inventory# is not a valid value for this field.</span>
			</cfdefaultcase>
		</cfswitch>
	</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Delivery Message: </td>
	<td valign="top">#delivery_message#</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Show Thumbnail in Cart:</td>
	<td valign="top">#YesNoFormat(show_thumbnail_in_cart)#</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">More than <b>One Item</b> Message: </td>
	<td valign="top">#one_item_over_message#</td>
	</tr>
	
	</table>
	
	<br>
	
	<!---  * * * * * * * * * * * --->
	<!--- PRODUCT SETS --->
	<!---  * * * * * * * * * * * --->
	<cfquery name="SelectProductSets" datasource="#application.DS#">
		SELECT s.set_name
		FROM #application.database#.xref_program_product_set x
		LEFT JOIN #application.database#.product_set s ON s.ID = x.product_set_ID
		WHERE x.program_ID = 
		<cfif isNumeric(request.selected_division_ID) AND request.selected_division_ID GT 0>
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_division_ID#" maxlength="10">
		<cfelse>
			<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		</cfif>
		ORDER BY s.sortorder
	</cfquery>

	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext <cfif edit_division>highlight</cfif>"><a href="program_product_sets.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;Product Sets</td>
	</tr>
	
	<cfif SelectProductSets.RecordCount EQ 0>
	
	<tr class="content">
	<td colspan="2" valign="top" class="content_details"><span class="sub">No sets selected.</span></td>
	</tr>

	<cfelse>

	<tr class="content">
	<td colspan="2" valign="top" class="content_details">
	<cfloop query="SelectProductSets">
	#set_name#<br>
	</cfloop>
	</td>
	</tr>

	</cfif>
		
	</table>
	
	<br>
	
	<!---  * * * * *  --->
	<!--- SUBPROGRAMS --->
	<!---  * * * * *  --->
	<cfquery name="SelectSubprograms" datasource="#application.DS#">
		SELECT subprogram_name, is_active
		FROM #application.database#.subprogram
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		ORDER BY sortorder
	</cfquery>

	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><a href="program_subprograms.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;Subprograms <span class="reg">(for billing purposes only)</span></td>
	</tr>
	
	<cfif SelectSubprograms.RecordCount EQ 0>
	
	<tr class="content">
	<td colspan="2" valign="top" class="content_details"><span class="sub">There are no subprograms.</span></td>
	</tr>

	<cfelse>

	<tr class="content">
	<td colspan="2" valign="top" class="content_details">
	<cfloop query="SelectSubprograms">
	#subprogram_name#<cfif is_active EQ 0> (inactive)</cfif><br>
	</cfloop>
	</td>
	</tr>

	</cfif>
		
	</table>
	
	<br>
	
	<!---  * * * *  * * * --->
	<!--- USER CATEGORIES --->
	<!---  * * *  * * * * --->
	<cfquery name="SelectUserCategories" datasource="#application.DS#">
		SELECT category_name
		FROM #application.database#.program_user_category
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		ORDER BY sortorder
	</cfquery>

	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><a href="program_user_categories.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;User Categories <span class="reg">(for reporting only)</span></td>
	</tr>
	
	<cfif SelectUserCategories.RecordCount EQ 0>
	
	<tr class="content">
	<td colspan="2" valign="top" class="content_details"><span class="sub">There are no user categories.</span></td>
	</tr>

	<cfelse>

	<tr class="content">
	<td colspan="2" valign="top" class="content_details">
	<cfloop query="SelectUserCategories">
	#category_name#<br>
	</cfloop>
	</td>
	</tr>

	</cfif>
		
	</table>

	<br>

	<!---  * * * * * * --->
	<!--- ORDER EMAILS --->
	<!---  * * * * * * --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><a href="program_order_emails.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;Order Emails</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap"><b>Order Confirmation</b> sent FROM:</td>
	<td valign="top" width="100%">#orders_from#<cfif orders_from EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap"><b>Order Confirmation</b> Email Text:</td>
	<td valign="top">#conf_email_text#<cfif conf_email_text EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap"><b>New Order Alert</b> Email sent TO:</td>
	<td valign="top">#orders_to#<cfif orders_to EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
		
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap"><b>New Order Alert</b> Email Subject:</td>
	<td valign="top"><cfif program_email_subject EQ ""><span class="alert">Edit This Section</span><cfelse>#program_email_subject# <span class="sub">- Order ######</span></cfif></td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap"><b>Cost Center Notification</b> Email sent TO:</td>
	<td valign="top">#cost_center_notification#</td>
	</tr>
	
	</table>
	
	<br>

	<!---  * * * * * * * * * * * * --->
	<!--- GENERAL DISPLAY SETTINGS --->
	<!---  * * * * * * * * * * * * --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext <cfif edit_division>highlight</cfif>"><a href="program_display.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;General Display Settings</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Company Logo:</td>
	<td valign="top" width="100%"><cfif logo NEQ ""><div style="width:#request.main_width-400#px; overflow:auto;"><img src="/pics/program/#logo#"></div><cfelse><span class="sub">(no logo)</span></cfif></td>
	</tr>
	
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Cross Color:</td>
	<td valign="top"><cfif cross_color NEQ ""><img src="../pics/shim.gif" style="background-color:###cross_color#" width="140" height="10"><cfelse><span class="sub">(no cross)</span></cfif></td>
	</tr>
	
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Active Button:</td>
	<td valign="top">
		<cfif bg_active EQ "" AND text_active EQ "">
		<span class="alert">Edit This Section</span>
		<cfelse>
		<table cellpadding="5" cellspacing="0" border="0">
		<tr>
		<td align="center" width="130" style="background-color:###bg_active#;color:###text_active#;font-weight:bold">Active&nbsp;Colors</td>
		</tr>
		</table>
		</cfif>
	</td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Selected Button:</td>
	<td valign="top">
		<cfif bg_selected EQ "" AND text_selected EQ "">
		<span class="alert">Edit This Section</span>
		<cfelse>
		<table cellpadding="5" cellspacing="0" border="0">
		<tr>
		<td align="center" width="130" style="background-color:###bg_selected#;color:###text_selected#;font-weight:bold">Selected&nbsp;Colors</td>
		</tr>
		</table>
		</cfif>
	</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Warning Text Color:</td>
	<td valign="top"><span style="color:###bg_warning#;">#bg_warning# for cart warnings, etc.</span></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Login Prompt:</td>
	<td valign="top"><cfif login_prompt EQ ""><span class="alert">Edit This Section</span><cfelse>Please Enter Your #login_prompt# Without Dashes or Spaces</cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">On Welcome and Main pages:</td>
	<td valign="top">
	"Welcome <i>Your Name</i>" <b>will <cfif #display_welcomeyourname# EQ 0>not</cfif></b> display.<br>
	"You have #### <cfif credit_desc NEQ "">#credit_desc#<cfelse>(credit description here)</cfif>" <b>will <cfif #display_youhavexcredits# EQ 0>not</cfif></b> display.
	</td>
	</tr>
	
	</table>
	
	<br>

	<!---  * * * * * * --->
	<!--- WELCOME PAGE --->
	<!---  * * * * * * --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext <cfif edit_division>highlight</cfif>"><a href="program_welcome.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;Welcome Page</td>
	</tr>

	<cfif has_welcomepage EQ 0>
	
	<tr class="content">
	<td colspan="2" valign="top" class="content_details">
		<span class="sub">
			There is no welcome page.<br><br>
			This is the page that has the additional content and email form buttons.
		</span>
	</td>
	</tr>
	
	<cfelse>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Background Image:</td>
	<td valign="top" width="100%"><cfif welcome_bg NEQ ""><a href="#welcome_bg#" target="_blank">view in new window</a><cfelse><span class="sub">(no background image)</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Congratulations Image:</td>
	<td valign="top" width="100%"><cfif welcome_congrats NEQ ""><a href="/pics/program/#welcome_congrats#" target="_blank">view in new window</a><cfelse><span class="sub">(no congratulations image)</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Instructions:</td>
	<td valign="top" width="100%">#Left(welcome_instructions, 75)#<cfif Len(welcome_instructions) GT 50> ... <a href="program_welcome.cfm">more</a></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Message:</td>
	<td valign="top" width="100%">#Left(welcome_message, 75)#<cfif Len(welcome_message) GT 50> ... <a href="program_welcome.cfm">more</a></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Button To Main Page:</td>
	<td valign="top" width="100%">#welcome_button#</td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Button To Admin Login:</td>
	<td valign="top" width="100%">#welcome_admin_button#</td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Admin Co-Branding Logo:</td>
	<td valign="top" width="100%"><cfif admin_logo NEQ ""><img src="/pics/program/#admin_logo#"><cfelse><span class="sub">(no admin co-branding image)</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Button To Email Form:</td>
	<td valign="top" width="100%">#email_form_button#</td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Email Form Message:</td>
	<td valign="top" width="100%">#Left(email_form_message, 75)#<cfif Len(email_form_message) GT 50> ... <a href="program_welcome.cfm">complete message</a></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Button To Additional Content:</td>
	<td valign="top" width="100%">#additional_content_button#</td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Additional Content:</td>
	<td valign="top" width="100%">#Left(additional_content_message, 75)#<cfif Len(additional_content_message) GT 50> ... <a href="program_welcome.cfm">more</a></cfif></td>
	</tr>
	
		<cfif additional_content_message_unapproved NEQ "" AND additional_content_button_unapproved NEQ "">
	<tr class="content">
	<td valign="top" class="content_details" colspan="2"><span class="alert">There is Additional Content waiting to be approved.</span> <a href="program_approve_additional_content.cfm">more information ...</a></td>
	</tr>
		</cfif>
	
	</cfif>
		
	</table>
	
	<br>
	
	<!--- * * * * * * * * * --->
	<!--- REGISTRATION PAGE --->
	<!--- * * * * * * * * * --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><a href="program_register.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;Registration Page</td>
	</tr>

	<cfif has_register EQ 0>
	
		<tr class="content">
		<td colspan="2" valign="top" class="content_details">
			<span class="sub">
				There is no registration page.<br><br>
			</span>
		</td>
		</tr>
	
	<cfelse>
		<cfif register_email_domain NEQ "">
			<tr class="content">
			<td valign="top" class="content_details" align="right" nowrap="nowrap">User must have this email address domain:</td>
			<td valign="top" width="100%">#register_email_domain#</td>
			</tr>
		</cfif>
		
		<tr class="content">
		<td valign="top" class="content_details" align="right" nowrap="nowrap">Left side menu text:</td>
		<td valign="top" width="100%">#Left(register_page_text, 75)#<cfif Len(register_page_text) GT 50> ... <a href="program_register.cfm">more</a></cfif></td>
		</tr>
		
	</cfif>
		
	</table>
	
	<br>
	
	<!--- * * * * * --->
	<!--- MAIN PAGE --->
	<!--- * * * * * --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><a href="program_main_page.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp; Main Page</td>
	</tr>

	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Background Image:</td>
	<td valign="top" width="100%"><cfif main_bg NEQ ""><a href="/pics/program/#main_bg#" target="_blank">view in new window</a><cfelse><span class="sub">(no background image)</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Congratulations Image:</td>
	<td valign="top" width="100%"><cfif main_congrats NEQ ""><a href="/pics/program/#main_congrats#" target="_blank">view in new window</a><cfelse><span class="sub">(no congratulations image)</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Instructions:</td>
	<td valign="top" width="100%">#main_instructions#<cfif main_instructions EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Columns of products:</td>
	<td valign="top" width="100%">#display_col#<cfif display_col EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Rows of products:</td>
	<td valign="top" width="100%">#display_row#<cfif display_row EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Top Of Left Menu:</td>
	<td valign="top" width="100%">#menu_text#<cfif menu_text EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Return to Main Button:</td>
	<td valign="top" width="100%">#return_button#<cfif return_button EQ ""><span class="alert">Edit This Section</span></cfif></td>
	</tr>
	
	</table>
	
	<br>
	
	<!--- *  * --->
	<!--- HELP --->
	<!--- *  * --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext <cfif edit_division>highlight</cfif>"><a href="program_help.cfm">Edit</a>&nbsp;&nbsp;&nbsp;&nbsp;Help</td>
	</tr>
	
	<cfif help_button NEQ "" and help_message NEQ "">
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Button To Help:</td>
	<td valign="top" width="100%">#help_button#</td>
	</tr>
	
	<tr class="content">
	<td valign="top" class="content_details" align="right" nowrap="nowrap">Help Content:</td>
	<td valign="top" width="100%">#help_message#</td>
	</tr>
	
	<cfelse>
		
	<tr class="content">
	<td valign="top" colspan="2" class="content_details" ><span class="sub">There is no help button or content.</span></td>
	</tr>

	</cfif>
			
	</table>
	
</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->