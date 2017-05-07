<cfparam name="address1" default="">
<cfparam name="address2" default="">
<cfparam name="city" default="">
<cfparam name="state" default="">
<cfparam name="zipcode" default="">
<cfparam name="weight" default="1">
<cfparam name="value" default="1">
<cfparam name="signature" default="0">

<cfif isDefined("form.ClearForm")>
	<cfset address1 = "">
	<cfset address2 = "">
	<cfset city = "">
	<cfset state = "">
	<cfset zipcode = "">
	<cfset weight = "1">
	<cfset value = "1">
<cfelseif isDefined("form.TestFedex")>
	<cfset fedex_obj = CreateObject("#Application.ComponentPath#.fedex_v2")>
	<cfset fedex_obj.recipientAddress1 = address1>
	<cfset fedex_obj.recipientAddress2 = address2>
	<cfset fedex_obj.recipientCity = city>
	<cfset fedex_obj.recipientState = state>
	<cfset fedex_obj.recipientZip = zipcode>
	<cfset fedex_obj.sendErrorEmail = false>
	<cfset fedex_result = fedex_obj.AddressValidation()>
	<!---<cfdump var="#fedex_result#">--->
</cfif>

<cfset leftnavon = "fedex_test">
<cfset request.main_width = 1200>
<cfinclude template="includes/header.cfm">

<span class="pagetitle">Test Fedex Rates</span>
<br><br>
<span class="pageinstructions">Enter weight, value and address to check shipping address and get rates.</span>
<br><br>

<cfoutput>
<form name="fedex_test_form" method="post">
<table cellspacing="0" cellpadding="2">
<tr>
	<td align="right">Weight (lbs): </td>
	<td>
		<input type="text" name="weight" value="#weight#" size="5" maxlength="5">
		&nbsp;&nbsp;
		<cfif not isNumeric(weight) or weight lte 0>
			<span class="alert">&lt-- not a valid number &nbsp;&nbsp;</span>
			<cfset weight=1>
		</cfif>
		Under 100 Standard &nbsp;&nbsp;
		100-150 Weight minimum met? &nbsp;&nbsp;
		151-2200 Freight rates
	</td>
</tr>
<tr>
	<td align="right">Value: </td>
	<td>
		<input type="text" name="value" value="#value#" size="5" maxlength="5">
		&nbsp;&nbsp;
		<cfif not isNumeric(value) or value lt 0>
			<span class="alert">&lt-- not a valid number &nbsp;&nbsp;</span>
			<cfset value=1>
		</cfif>
		$0 to $50,000
	</td>
</tr>
<tr>
	<td align="right">Height: </td>
	<td><input type="text" name="height" value="" size="5" maxlength="50" disabled> &nbsp;&nbsp; <span class="sub">Currently not used</span></td>
</tr>
<tr>
	<td align="right">Width: </td>
	<td><input type="text" name="width" value="" size="5" maxlength="50" disabled> &nbsp;&nbsp; <span class="sub">Currently not used</span></td>
</tr>
<tr>
	<td align="right">Length: </td>
	<td><input type="text" name="length" value="" size="5" maxlength="50" disabled> &nbsp;&nbsp; <span class="sub">Currently not used</span></td>
</tr>
<tr>
	<td align="right">Address&nbsp;Line&nbsp;1: </td>
	<td><input type="text" name="address1" value="#address1#" size="60" maxlength="30"></td>
</tr>
<tr>
	<td align="right">Address&nbsp;Line&nbsp;2: </td>
	<td><input type="text" name="address2" value="#address2#" size="60" maxlength="30"></td>
</tr>
<tr>
	<td align="right">City: </td>
	<td><input type="text" name="city" value="#city#" maxlength="30" size="60"></td>
</tr>
<tr>
	<td align="right">State: </td>
	<td>#FLGen_SelectState("state","#state#","true")#</td>
</tr>
<tr>
	<td align="right">Zip Code: </td>
	<td><input type="text" name="zipcode" value="#zipcode#" maxlength="5" size="10"></td>
</tr>
<tr>
	<td align="right">
		<input type="checkbox" name="signature" value="1" <cfif signature EQ 1>checked</cfif>>
	</td>
	<td>
		Signature Required
		&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
		<input type="submit" name="TestFedex" value="  Submit  ">&nbsp;&nbsp;&nbsp;
		<input type="submit" name="ClearForm" value="  Clear Form  ">		
	</td>
</tr>
</table>
</form>
<br>
<cfif isDefined("fedex_result")>
	<cfset google_count = 0>
	<cfif NOT fedex_result.validated>
		<!--- Query the Google Maps API --->
		<cfset google_addresses = fedex_obj.GetGoogleMapsSuggestions()>
		<cfset google_count = ArrayLen(google_addresses)>
		<!---<cfdump var="#google_addresses#">--->
	</cfif>
	<table cellspacing="0" cellpadding="0">
		<tr class="contenthead">
			<td class="headertext"></td>
			<td>&nbsp;&nbsp;&nbsp;</td>
			<td class="headertext" align="center">Entered</td>
			<td>&nbsp;&nbsp;&nbsp;</td>
			<td class="headertext" align="center">Fedex</td>
			<td>&nbsp;&nbsp;&nbsp;</td>
			<td class="headertext" align="center">Google <cfif google_count GT 1>1</cfif></td>
			<cfif google_count GT 1>
				<cfloop from="2" to="#google_count#" index="x">
					<td>&nbsp;&nbsp;&nbsp;</td>
					<td class="headertext" align="center">Google #x#</td>
				</cfloop>
			</cfif>
		<tr>
		<tr>
			<td valign="top">
				<table cellspacing="0" cellpadding="5">
					<tr class="content">
						<td align="right">Address&nbsp;Lines: </td>
					</tr>
					<tr class="content">
						<td align="right">City: </td>
					</tr>
					<tr class="content">
						<td align="right">State: </td>
					</tr>
					<tr class="content">
						<td align="right">Zip Code: </td>
					</tr>
				</table>
			</td>
			<td>&nbsp;&nbsp;&nbsp;</td>
			<td valign="top">
				<table cellspacing="0" cellpadding="5">
					<tr class="content2">
						<td>#address1# #address2#&nbsp;</td>
					</tr>
					<tr class="content2">
						<td>#city#&nbsp;</td>
					</tr>
					<tr class="content2">
						<td>#state#&nbsp;</td>
					</tr>
					<tr class="content2">
						<td>#zipcode#&nbsp;</td>
					</tr>
				</table>
			</td>
			<td>&nbsp;&nbsp;&nbsp;</td>
			<td valign="top">
				<table cellspacing="0" cellpadding="5">
					<tr class="content2">
						<td>#fedex_result.address.streetlines#&nbsp;</td>
					</tr>
					<tr class="content2">
						<td>#fedex_result.address.city#&nbsp;</td>
					</tr>
					<tr class="content2">
						<td>#fedex_result.address.state#&nbsp;</td>
					</tr>
					<tr class="content2">
						<td>#fedex_result.address.postalcode#&nbsp;</td>
					</tr>
				</table>
			</td>
			<cfif fedex_result.validated or google_count EQ 0>
				<td>&nbsp;&nbsp;&nbsp;</td>
				<td class="sub">Not needed</td>
			<cfelse>
				<cfloop array="#google_addresses#" index="g">
					<td>&nbsp;&nbsp;&nbsp;</td>
					<td valign="top">
						<table cellspacing="0" cellpadding="5">
							<tr class="content2">
								<td>#g[3]#&nbsp;</td>
							</tr>
							<tr class="content2">
								<td>#g[4]#&nbsp;</td>
							</tr>
							<tr class="content2">
								<td>#g[5]#&nbsp;</td>
							</tr>
							<tr class="content2">
								<td>#g[6]#&nbsp;</td>
							</tr>
						</table>
					</td>
				</cfloop>
			</cfif>
		</tr>
	</table>
	<br>
	<cfif fedex_result.validated>
		<p class="pageinstructions">Fedex response:&nbsp;&nbsp;&nbsp;Valid <strong>#fedex_result.ResidentialStatus#</strong> address.</p>
		<cfif fedex_result.msg NEQ "">
			<p class="alert">#fedex_result.msg#</p>
		</cfif>
		<cfset fedex_obj.Weight = weight>
		<cfset fedex_obj.Value = value>
		<cfset fedex_obj.addCharge = 0>
		<cfset rates_result = fedex_obj.getRates()>
		<cfif signature EQ 1>
			<cfset fedex_obj.SignatureRequired(true)>
		</cfif>
		<!---<cfdump var="#rates_result#"><cfabort>--->
		<cfloop array="#rates_result.response#" index="x">
			<cfif NOT ListFind("SUCCESS",x.status)>
				<p class="alert">#x.msg#</p>
			</cfif>
		</cfloop>
		<table cellspacing="0" cellpadding="3">
			<tr <cfif ArrayLen(rates_result.rate)>class="contenthead"</cfif>>
				<td valign="top" colspan="4" class="headertext">Service for #weight# lbs and $#value# value</td>
			</tr>
			<cfif ArrayLen(rates_result.rate)>
				<cfloop from="1" to="#ArrayLen(rates_result.rate)#" index="i">
					<tr class="content<cfif i MOD 2>2</cfif>">
						<td valign="top">#rates_result.rate[i][2]#</td>
						<td valign="top" align="right">#DollarFormat(rates_result.rate[i][3])#</td>
						<td>&nbsp;&nbsp;&nbsp;</td>
						<td><cfdump label="Rate Breakdown" var="#rates_result.rate[i][4]#" expand="false"></td>
					</tr>
				</cfloop>
			</cfif>
		</table>
		<br>
		<!---<cfdump var="#fedex#">--->
	<cfelse>
		<table cellspacing="0" cellpadding="2">
			<tr><td align="right" valign="top">Fedex response: </td><td class="alert">#fedex_result.msg#</td></tr>
			<tr><td align="right">Delivery Point Validation: </td><td class="headertext">#fedex_result.DeliveryPointValidation#</td></tr>
			<tr><td align="right">Business or Residential: </td><td class="headertext">#fedex_result.ResidentialStatus#</td></tr>
		</table>
	</cfif>
	<!---<cfdump var="#fedex_result#">--->
</cfif>
</cfoutput>


<cfinclude template="includes/footer.cfm">