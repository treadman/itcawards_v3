<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000012,true)>

<cfparam name="where_string" default="">
<cfparam name="ID" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="vendor">
<cfparam name="xT" default="">
<cfparam name="xL" default="">

<!--- param a/e form fields --->
<cfparam name="ID" default="">	
<cfparam name="vendor" default="">
<cfparam name="address1" default="">
<cfparam name="address2" default="">
<cfparam name="city" default="">
<cfparam name="state" default="">
<cfparam name="zip" default="">
<cfparam name="phone" default="">
<cfparam name="fax" default="">
<cfparam name="email" default="">
<cfparam name="attention" default="">
<cfparam name="what_terms" default="">
<cfparam name="notes" default="">

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<!--- START pgfn ADD/EDIT --->
<cfquery name="ToBeEdited" datasource="#application.DS#">
	SELECT ID, vendor, IFNULL(address1,"-") AS address1, IFNULL(address2,"-") AS address2, IFNULL(city,"-") AS city, IFNULL(state,"-") AS state, IFNULL(zip,"-") AS zip, IFNULL(phone,"-") AS phone, IFNULL(fax,"-") AS fax, IFNULL(email,"-") AS email, IFNULL(attention,"-") AS attention, IFNULL(notes,"-") AS notes, what_terms, min_order
	FROM #application.database#.vendor
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
</cfquery>
<cfset ID = ToBeEdited.ID>
<cfset vendor = htmleditformat(ToBeEdited.vendor)>
<cfset address1 = htmleditformat(ToBeEdited.address1)>
<cfset address2 = htmleditformat(ToBeEdited.address2)>
<cfset city = htmleditformat(ToBeEdited.city)>
<cfset state = htmleditformat(ToBeEdited.state)>
<cfset zip = htmleditformat(ToBeEdited.zip)>
<cfset phone = htmleditformat(ToBeEdited.phone)>
<cfset fax = htmleditformat(ToBeEdited.fax)>
<cfset email = htmleditformat(ToBeEdited.email)>
<cfset attention = htmleditformat(ToBeEdited.attention)>
<cfset notes = htmleditformat(ToBeEdited.notes)>
<cfset what_terms = htmleditformat(ToBeEdited.what_terms)>
<cfset min_order = htmleditformat(ToBeEdited.min_order)>

<!--- find this vendor's product(s) --->
<cfquery name="FindVendorsProds" datasource="#application.DS#">
	SELECT m.meta_sku AS meta_sku, m.meta_name AS meta_name, p.productvalue AS productvalue, prod.sku AS sku, prod.ID AS product_ID 
	FROM #application.database#.product_meta m
	JOIN #application.database#.productvalue_master p ON m.productvalue_master_ID = p.ID 
		JOIN #application.database#.product prod ON prod.product_meta_ID = m.ID 
		JOIN #application.database#.vendor_lookup vl ON vl.product_ID = prod.ID 
	WHERE vl.vendor_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10"> 
	ORDER BY p.productvalue, m.sortorder
</cfquery>

<cfinclude template="includes/header_lite.cfm">

<cfoutput>

<table cellpadding="5" cellspacing="1" border="0">

<tr>
<td align="right" valign="top" class="printhead">Vendor: </td>
<td valign="top" class="printhead">#vendor#</td>
</tr>

<tr>
<td align="right" valign="top" class="printlabel">Address Line 1: </td>
<td valign="top" class="printtext">#address1#</td>
</tr>

<tr>
<td align="right" valign="top" class="printlabel">Address Line 2: </td>
<td valign="top" class="printtext">#address2#</td>
</tr>
	
<tr>
<td align="right" valign="top" class="printlabel">City, State Zip: </td>
<td valign="top" class="printtext">#city#, #state# #zip#</td>
</tr>
	
<tr>
<td align="right" valign="top" class="printlabel">Phone: </td>
<td valign="top" class="printtext">#phone#</td>
</tr>
	
<tr>
<td align="right" valign="top" class="printlabel">Fax: </td>
<td valign="top" class="printtext">#fax#</td>
</tr>
	
<tr>
<td align="right" valign="top" class="printlabel">Email: </td>
<td valign="top" class="printtext">#email#</td>
</tr>
	
<tr>
<td align="right" valign="top" class="printlabel">Attention: </td>
<td valign="top" class="printtext">#attention#</td>
</tr>
	
<tr>
<td align="right" valign="top" class="printlabel">Terms: </td>
<td valign="top" class="printtext">#what_terms#</td>
</tr>
	
<tr>
<td align="right" valign="top" class="printlabel">Min. Order: </td>
<td valign="top" class="printtext">$ #min_order#</td>
</tr>
	
<tr>
<td align="right" valign="top" class="printlabel">Notes: </td>
<td valign="top" class="printtext">#Replace(HTMLEditFormat(notes),chr(10),"<br>","ALL")#</td>
</tr>
					
<td colspan="2" valign="top" class="printlabel">Products Assigned to this vendor: </td>
</tr>

</table>

<table cellpadding="5" cellspacing="1" border="0">

<tr>
<td align="right" valign="top" class="printlabel">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>


	<cfif FindVendorsProds.RecordCount EQ 0>
		<td valign="top" class="printtext">
			There are no products for this vendor.
		</td>
		</tr>
	<cfelse>
		<td class="printtext">ITC&nbsp;SKU&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></td>
		<td width="100%" class="printtext">Product Name</td>
		</tr>
		
		<cfloop query="FindVendorsProds">
			<cfoutput>
		<tr>
		<td align="center" class="printtext">&nbsp;</td>
		<td class="printtext">#HTMLEditFormat(sku)#</td>
		<td class="printtext">#meta_name# #FindProductOptions(product_ID)#</td>
		</tr>
			</cfoutput>
		</cfloop>
		
	</cfif>

</table>
</cfoutput>
<cfinclude template="includes/footer.cfm">


