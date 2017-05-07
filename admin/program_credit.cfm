<!--- Verify that a program was selected --->
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cflocation url="program_list.cfm" addtoken="no">
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000014,true)>

<cfparam name="where_string" default="">
<cfparam name="delete" default="">
<cfparam name="unapproved" default="">

<!--- param a/e form fields --->
<cfparam name="credit_desc" default="Dollar Value Credit">
<cfparam  name="credit_multiplier" default="0">
<cfparam  name="points_multiplier" default="0">
<cfparam name="cart_exceeded_msg" default="">
<cfparam name="accepts_cc" default="">
<cfparam name="cc_exceeded_msg" default="">
<cfparam name="can_defer" default="">
<cfparam name="defer_msg" default="">
<cfparam name="charge_shipping" default="">
<cfparam name="cc_shipping" default="">
<cfparam name="add_shipping" default="">
<cfparam name="signature_charge" default="">
<cfparam name="get_shipping_address" default="1">
<cfparam name="show_thumbnail_in_cart" default="0">
<cfparam name="one_item_over_message" default="">
<cfparam name="delivery_message" default="">
<cfparam name="uses_shipping_locations" default="0">
<cfparam name="inactivate_zero_inventory" default="0">
<cfparam name="show_inventory" default="0">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<cfif NOT Find(".",credit_multiplier) AND Len(credit_multiplier) LTE 4>
		<cfset credit_multiplier = credit_multiplier>
	<cfelseif NOT Find(".",credit_multiplier) AND Len(credit_multiplier) GT 4>
		<cfset credit_multiplier = Right(credit_multiplier,4)>
	<cfelseif Find(".",credit_multiplier) AND (Len(credit_multiplier) - Find(".",credit_multiplier)) LTE 2 AND Len(credit_multiplier) LTE 7>
		<cfset credit_multiplier = credit_multiplier>
	<cfelse>
		<cfset credit_multiplier = 1>
	</cfif>
	<cfif NOT Find(".",points_multiplier) AND Len(points_multiplier) LTE 4>
		<cfset points_multiplier = points_multiplier>
	<cfelseif NOT Find(".",points_multiplier) AND Len(points_multiplier) GT 4>
		<cfset points_multiplier = Right(points_multiplier,4)>
	<cfelseif Find(".",points_multiplier) AND (Len(points_multiplier) - Find(".",points_multiplier)) LTE 2 AND Len(points_multiplier) LTE 7>
		<cfset points_multiplier = points_multiplier>
	<cfelse>
		<cfset points_multiplier = 1>
	</cfif>
	<cfif NOT isDate(charge_shipping)>
		<cfset charge_shipping = "">
	</cfif>
	<cfif NOT isNumeric(add_shipping)>
		<cfset add_shipping = 0>
	</cfif>
	<cfif NOT isNumeric(signature_charge)>
		<cfset signature_charge = 0>
	</cfif>
	<cfquery name="UpdateQuery" datasource="#application.DS#">
		UPDATE #application.database#.program
		SET	can_defer = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#can_defer#" maxlength="1">,
			defer_msg = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#defer_msg#"  null="#YesNoFormat(NOT Len(Trim(defer_msg)))#">,
			cart_exceeded_msg = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#cart_exceeded_msg#">,
			cc_exceeded_msg = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#cc_exceeded_msg#" null="#YesNoFormat(NOT Len(Trim(cc_exceeded_msg)))#">,
			credit_desc = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#credit_desc#" maxlength="40">,
			accepts_cc = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#accepts_cc#" maxlength="1">,
			cc_shipping = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#cc_shipping#" maxlength="1">,
			<cfif charge_shipping eq "">
				charge_shipping = <cfqueryparam null="yes">,
			<cfelse>
				charge_shipping = <cfqueryparam cfsqltype="cf_sql_date" value="#charge_shipping#">,
			</cfif>
			add_shipping = <cfqueryparam cfsqltype="cf_sql_float" value="#add_shipping#">,
			credit_multiplier = <cfqueryparam cfsqltype="cf_sql_float" value="#credit_multiplier#" scale="2">,
			points_multiplier = <cfqueryparam cfsqltype="cf_sql_float" value="#points_multiplier#" scale="2">,
			signature_charge = <cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#signature_charge#">,
			get_shipping_address = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#get_shipping_address#" maxlength="1">,
			uses_shipping_locations = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#uses_shipping_locations#" maxlength="1">,
			inactivate_zero_inventory = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#inactivate_zero_inventory#" maxlength="1">,
			show_inventory = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#show_inventory#" maxlength="1">,
			show_thumbnail_in_cart = <cfqueryparam cfsqltype="cf_sql_tinyint" value="#show_thumbnail_in_cart#" maxlength="1">,
			one_item_over_message = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#one_item_over_message#" null="#YesNoFormat(NOT Len(Trim(one_item_over_message)))#">,
			delivery_message = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#delivery_message#" null="#YesNoFormat(NOT Len(Trim(delivery_message)))#">,
			forwarder_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#forwarder_ID#" maxlength="10">,
			forward_button = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#forward_button#" maxlength="32">,
			shipping_location_message1 = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#shipping_location_message1#" null="#YesNoFormat(NOT Len(Trim(shipping_location_message1)))#">,
			shipping_location_message2 = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#shipping_location_message2#" null="#YesNoFormat(NOT Len(Trim(shipping_location_message2)))#">,
			shipping_location_message3 = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#shipping_location_message3#" null="#YesNoFormat(NOT Len(Trim(shipping_location_message3)))#">
			#FLGen_UpdateModConcatSQL("from program_welcome.cfm")#
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	<cflocation addtoken="no" url="program_details.cfm">
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "programs">
<cfset request.main_width = 1000>
<cfinclude template="includes/header.cfm">

<cfset tinymce_fields = "shipping_location_message1, shipping_location_message2, shipping_location_message3">
<cfinclude template="/cfscripts/dfm_common/tinymce.cfm">

<cfquery name="ToBeEdited" datasource="#application.DS#">
	SELECT ID, credit_multiplier, points_multiplier, credit_desc, cart_exceeded_msg, can_defer, defer_msg,
			cc_exceeded_msg, accepts_cc, charge_shipping, cc_shipping, add_shipping, get_shipping_address,
			uses_shipping_locations, forward_button, forwarder_ID, signature_charge,
			shipping_location_message1, shipping_location_message2, shipping_location_message3,
			inactivate_zero_inventory, show_inventory, show_thumbnail_in_cart, one_item_over_message, delivery_message
	FROM #application.database#.program
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
</cfquery>
<cfset can_defer = htmleditformat(ToBeEdited.can_defer)>
<cfset defer_msg = htmleditformat(ToBeEdited.defer_msg)>
<cfset cart_exceeded_msg = htmleditformat(ToBeEdited.cart_exceeded_msg)>
<cfset cc_exceeded_msg = htmleditformat(ToBeEdited.cc_exceeded_msg)>
<cfset credit_desc = htmleditformat(ToBeEdited.credit_desc)>
<cfset accepts_cc = htmleditformat(ToBeEdited.accepts_cc)>
<cfset credit_multiplier = ToBeEdited.credit_multiplier>
<cfset cc_shipping = ToBeEdited.cc_shipping>
<cfset points_multiplier = ToBeEdited.points_multiplier>
<cfset get_shipping_address = ToBeEdited.get_shipping_address>
<cfset uses_shipping_locations = ToBeEdited.uses_shipping_locations>
<cfset inactivate_zero_inventory = ToBeEdited.inactivate_zero_inventory>
<cfset show_inventory = ToBeEdited.show_inventory>
<cfset show_thumbnail_in_cart = ToBeEdited.show_thumbnail_in_cart>
<cfset one_item_over_message = ToBeEdited.one_item_over_message>
<cfset delivery_message = ToBeEdited.delivery_message>
<cfset shipping_location_message1 = htmleditformat(ToBeEdited.shipping_location_message1)>
<cfset shipping_location_message2 = htmleditformat(ToBeEdited.shipping_location_message2)>
<cfset shipping_location_message3 = htmleditformat(ToBeEdited.shipping_location_message3)>
<cfset forward_button = htmleditformat(ToBeEdited.forward_button)>
<cfset forwarder_ID = ToBeEdited.forwarder_ID>

<cfif ToBeEdited.charge_shipping NEQ "">
	<cfset charge_shipping = FLGen_DateTimeToDisplay(htmleditformat(ToBeEdited.charge_shipping))>
<cfelse>
	<cfset charge_shipping = "">
</cfif>
<cfset add_shipping = NumberFormat(ToBeEdited.add_shipping,"0.00")>
<cfset signature_charge = NumberFormat(ToBeEdited.signature_charge,"0.00")>

<cfoutput>
<span class="pagetitle">Edit Program Award Credit and Credit Card Information for #request.program_name#</span>
<br />
<br />
<span class="pageinstructions">Return to <a href="program_details.cfm">Award Program Details</a> or <a href="program_list.cfm">Award Program List</a> without making changes.</span>
<br /><br />

<form method="post" action="#CurrentPage#">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext">Award Credits and Credit Cards</td>
	</tr>
					
	<tr class="content">
	<td align="right" valign="top">Credit Description*: </td>
	<td valign="top"><input type="text" name="credit_desc" value="#credit_desc#" maxlength="40" size="40">
	<input type="hidden" name="credit_desc_required" value="Please enter a credit description."></td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top" style="white-space:nowrap;">Product Multiplier:<br /><span class="sub">Product that users see are<br>multiplied by this number.</span> </td>
	<td valign="top"><input type="text" name="credit_multiplier" value="<cfif credit_multiplier NEQ "">#NumberFormat(credit_multiplier,Application.NumFormat)#<cfelse>#NumberFormat(1,Application.NumFormat)#</cfif>" maxlength="8" size="20"> <span class="sub">(ex. <b>#NumberFormat(1,Application.NumFormat)#</b> or <b>.50</b> or <b>#NumberFormat(1000,Application.NumFormat)#</b>)</span>
	</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top" style="white-space:nowrap;">Award Points Multiplier:<br /><span class="sub">Award Points that users see are<br>multiplied by this number. </span> </td>
	<td valign="top"><input type="text" name="points_multiplier" value="<cfif points_multiplier NEQ "">#NumberFormat(points_multiplier,Application.NumFormat)#<cfelse>#NumberFormat(1,Application.NumFormat)#</cfif>" maxlength="8" size="20"> <span class="sub">(ex. <b>#NumberFormat(1,Application.NumFormat)#</b> or <b>.50</b> or <b>#NumberFormat(1000,Application.NumFormat)#</b>)</span>
	</td>
	</tr>
				
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="bottom"><img src="../pics/contrls-desc.gif" width="7" height="6"> This message appears on the cart and checkout pages. Tailor the message depending on whether credit cards are accepted.  Examples: <span class="sub">You have exceeded your credits. You will have to use your credit card to complete this order.</span> or <span class="sub">You have exceeded your credits. You will have to edit your order before you are able to checkout.</span></td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top" style="white-space:nowrap;">Exceeded Your Credits Message*: </td>
	<td valign="top"><textarea name="cart_exceeded_msg" cols="38" rows="4">#cart_exceeded_msg#</textarea>
	<input type="hidden" name="cart_exceeded_msg_required" value="Please enter a message that displays when a user's cart total exceed his available credits."></td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Accepts Credit Cards?*: </td>
	<td valign="top">
		<select name="accepts_cc">
			<option value="0"<cfif #accepts_cc# EQ 0> selected</cfif>>No
			<option value="1"<cfif #accepts_cc# EQ 1> selected</cfif>>Yes with credit card maximum
			<option value="2"<cfif #accepts_cc# EQ 2> selected</cfif>>Yes without credit card maximum
		</select>
	</td>
	</tr>
		
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="bottom"><img src="../pics/contrls-desc.gif" width="7" height="6"> Only used if the above is set to <b>Yes with credit card maximum</b>. The automatic message, "You may only charge $##." is displayed when a user exceeds their personal credit card maximum. The message you enter below will appear under that automatic message.  Example: <span class="sub">You will have to edit your order before you are able to checkout.</span></td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top" style="white-space:nowrap;">Exceeded Credit Card Maximum Message: </td>
	<td valign="top"><textarea name="cc_exceeded_msg" cols="38" rows="4">#cc_exceeded_msg#</textarea> </td>
	</tr>
												
	<tr class="content">
	<td align="right" valign="top">Can users defer points?*: </td>
	<td valign="top">
		<select name="can_defer">
			<option value="0"<cfif #can_defer# EQ 0> selected</cfif>>No
			<option value="1"<cfif #can_defer# EQ 1> selected</cfif>>Yes
		</select>
	</td>
	</tr>
		
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="bottom"><img src="../pics/contrls-desc.gif" width="7" height="6"> This is the message above the defer button.</td>
	</tr>
				
	<tr class="content">
	<td align="right" valign="top">Defer Message: </td>
	<td valign="top"><textarea name="defer_msg" cols="38" rows="4">#defer_msg#</textarea> </td>
	</tr>

	<tr><td></td></tr>
	<tr class="contenthead">
	<td colspan="2" class="headertext">Shipping</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Charge Shipping Beginning On: </td>
	<td valign="top"><input type="text" name="charge_shipping" value="#charge_shipping#" maxlength="10" size="12"><br>
	<span class="sub">(Please use 4 digit years, for example: #DateFormat(Now(),"mm/dd/yyyy")#)</span>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Charge shipping on orders when<br>user has NO points?*: </td>
	<td valign="top">
		<select name="cc_shipping">
			<option value="0"<cfif #cc_shipping# EQ 0> selected</cfif>>No
			<option value="1"<cfif #cc_shipping# EQ 1> selected</cfif>>Yes
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Additional Shipping Charge: </td>
	<td valign="top"><input type="text" name="add_shipping" value="#add_shipping#" maxlength="9" size="12"><br>
	<span class="sub">This is added to the shipping options in the dropdown.</span>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Signature Required Charge: </td>
	<td valign="top"><input type="text" name="signature_charge" value="#signature_charge#" maxlength="9" size="12"><br>
	<span class="sub">This is a line item at checkout.</span>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Get Shipping Address?*: </td>
	<td valign="top">
		<select name="get_shipping_address">
			<option value="0"<cfif #get_shipping_address# EQ 0> selected</cfif>>No
			<option value="1"<cfif #get_shipping_address# EQ 1> selected</cfif>>Yes
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Use Shipping Locations?*: </td>
	<td valign="top">
		<select name="uses_shipping_locations">
			<option value="0"<cfif #uses_shipping_locations# EQ 0> selected</cfif>>No
			<option value="1"<cfif #uses_shipping_locations# EQ 1> selected</cfif>>Yes
		</select>
	</td>
	</tr>

	<tr class="contenthead">
	<td colspan="2" class="headertext">Shipping Locations Messages</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top" style="white-space:nowrap;">
		Message When Using<br>Shipping Locations:<br>
	</td>
	<td valign="top"><textarea name="shipping_location_message1" cols="75" rows="10">#shipping_location_message1#</textarea>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top" style="white-space:nowrap;">
		Message When Charging Shipping:<br><br>
		<span class="sub">To allow users to have orders shipped<br>to a shipping location, then forwarded.</span>
	</td>
	<td valign="top"><textarea name="shipping_location_message2" cols="75" rows="10">#shipping_location_message2#</textarea>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top" style="white-space:nowrap;">
		Message at Checkout:<br><br>
		<span class="sub">Displayed above the special<br>instructions when the order is<br>forwarded from a shipping location.</span>
	</td>
	<td valign="top"><textarea name="shipping_location_message3" cols="75" rows="10">#shipping_location_message3#</textarea>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Forward Button: </td>
	<td valign="top"><input type="text" name="forward_button" value="#forward_button#" maxlength="32" size="40"></td>
	</tr>

	<cfquery name="GetShippingLocations" datasource="#application.DS#">
		SELECT ID, location_name, city, state, zip
		FROM #application.database#.shipping_locations
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
		ORDER BY location_name
	</cfquery>
	<tr class="content">
	<td align="right" style="white-space:nowrap;">
		Ship to:<br>
		<span class="sub">The shipping location that will<br>forward the orders to the user.</span>
	</td>
	<td>
		<select name="forwarder_ID">
			<option value="0"> -- Select a Shipping Location -- </option>
			<cfloop query="GetShippingLocations">
				<option value="#GetShippingLocations.ID#" <cfif forwarder_ID EQ GetShippingLocations.ID>selected</cfif>>#GetShippingLocations.location_name#</option>
			</cfloop>
		</select>
	</td>
	</tr>


	<tr><td></td></tr>
	<tr class="contenthead">
	<td colspan="2" class="headertext">Product Selection and Checkout</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Inactivate Products with no Inventory?*: </td>
	<td valign="top">
		<select name="inactivate_zero_inventory">
			<option value="0"<cfif #inactivate_zero_inventory# EQ 0> selected</cfif>>No
			<option value="1"<cfif #inactivate_zero_inventory# EQ 1> selected</cfif>>Yes
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Show Inventory On Hand?*: </td>
	<td valign="top">
		<select name="show_inventory">
			<option value="0"<cfif show_inventory EQ 0> selected</cfif>>No
			<option value="1"<cfif show_inventory EQ 1> selected</cfif>>Only on Product Page
			<option value="2"<cfif show_inventory EQ 2> selected</cfif>>Only on Main Page
			<option value="3"<cfif show_inventory EQ 3> selected</cfif>>On Both Product and Main Page
		</select>
	</td>
	</tr>
	<tr class="content">
	<td align="right" valign="top" style="white-space:nowrap;">Delivery Message:</td>
	<td valign="top"><textarea name="delivery_message" cols="38" rows="4">#delivery_message#</textarea>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Show Thumbnail in Cart?*: </td>
	<td valign="top">
		<select name="show_thumbnail_in_cart">
			<option value="0"<cfif #show_thumbnail_in_cart# EQ 0> selected</cfif>>No
			<option value="1"<cfif #show_thumbnail_in_cart# EQ 1> selected</cfif>>Yes
		</select>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top" style="white-space:nowrap;">
		Over One Item Message:<br><br>
		<span class="sub">Merge codes:</span> &nbsp; %OVER_NUMBER%<br>
		%S% #RepeatString('&nbsp;',18)#<br>
		%ES% #RepeatString('&nbsp;',16)#
	</td>
	<td valign="top"><textarea name="one_item_over_message" cols="38" rows="4">#one_item_over_message#</textarea>
	</td>
	</tr>
		

	<tr class="content">
	<td colspan="2" align="center">
		
	<input type="submit" name="submit" value="   Save Changes   " >

	</td>
	</tr>
		
	</table>

</form>

</cfoutput>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->