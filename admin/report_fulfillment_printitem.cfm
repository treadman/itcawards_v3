<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfinclude template="includes/header_lite.cfm">

	<table cellpadding="5" cellspacing="0" border="0" width="90%" align="center">
	
	<tr>
	<td colspan="5" class="printlabel">I T C&nbsp;&nbsp;&nbsp;A W A R D S&nbsp;&nbsp;&nbsp;-&nbsp;&nbsp;&nbsp;
S H I P&nbsp;&nbsp;&nbsp;F R O M&nbsp;&nbsp;&nbsp;I T C&nbsp;&nbsp;&nbsp;-&nbsp;&nbsp;&nbsp;
<cfoutput>#FLGen_DateTimeToDisplay()#</cfoutput><br></td>
	</tr>
	
<!--- VARIABLES --->
<cfset ProductToPrint = form.print_product>
<cfset OrdersToPrint = form.print_orders>
<cfset QuantitiesToPrint = form.print_quantity>
<cfset ProductPhysicalInventory = CalcPhysicalInventory(ProductToPrint)>

<!--- find product info --->
<cfquery name="SelectProdInfo" datasource="#application.DS#">
	SELECT 	meta.meta_name, prod.sku, pval.productvalue, prod.ID AS ProductToPrint, 
			IF((SELECT COUNT(*) FROM #application.database#.product_meta_option_category pm WHERE meta.ID = pm.product_meta_ID)=0,"false","true") AS has_options
	FROM #application.database#.product_meta meta
	JOIN #application.database#.product prod ON prod.product_meta_ID = meta.ID 
	JOIN #application.database#.productvalue_master pval ON pval.ID = meta.productvalue_master_ID
	WHERE prod.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProductToPrint#" maxlength="10"> 
</cfquery>
		
<!--- find product's options --->
<cfset these_options = "">
<cfif SelectProdInfo.has_options>
	<cfquery name="FindProductOptionInfo" datasource="#application.DS#">
		SELECT pmoc.category_name AS category_name, pmo.option_name AS option_name
		FROM #application.database#.product_meta_option_category pmoc
		JOIN #application.database#.product_meta_option pmo ON pmoc.ID = pmo.product_meta_option_category_ID 
		JOIN  #application.database#.product_option po ON pmo.ID = po.product_meta_option_ID
		WHERE po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ProductToPrint#" maxlength="10"> 
		ORDER BY pmoc.sortorder
	</cfquery>
	<cfloop query="FindProductOptionInfo">
		<cfset these_options = these_options & "  [#category_name#: #option_name#] ">
	</cfloop>
	<cfset these_options = Trim(these_options)>
</cfif>	

<cfquery name="FindVendorSku" datasource="#application.DS#">
	SELECT vl.vendor_sku, v.vendor 
	FROM #application.database#.vendor_lookup vl
	JOIN #application.database#.vendor v ON vl.vendor_ID = v.ID 
	WHERE vl.product_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ProductToPrint#" maxlength="10">
</cfquery>

<!--- header row with product name and productvalue --->
<cfoutput>
	<tr class="printlabel">
	<td valign="top" class="printlabel"><span class="highlight">CAT: #SelectProdInfo.productvalue#</span></td>
	<td class="printlabel">
		<span class="highlight"><b>#SelectProdInfo.meta_name#</b><cfif these_options NEQ ""> #these_options#</cfif></span><br />
<span class="printtext">				ITC SKU: #SelectProdInfo.sku# 
	<cfif FindVendorSku.RecordCount GT 0>
		<cfloop query="FindVendorSku">
			<br />#vendor# Vendor SKU: #vendor_sku#
		</cfloop>
	</cfif>
</span>			</td>
	<td valign="top" class="printlabel">inventory: #ProductPhysicalInventory#</td>
	</tr>
	<tr>
	<td colspan="5" class="printlabel">&nbsp;</td>
	</tr>
</cfoutput>
		
<!---  loop through orders to print --->
<cfloop list="#OrdersToPrint#" index="i_order">

	<cfset thisindv_qty = ListGetAt(QuantitiesToPrint,ListFind(OrdersToPrint,i_order))>
	
	<cfquery name="FindOrderInfo" datasource="#application.DS#">
		SELECT program_ID AS this_program_ID, order_number, snap_fname, snap_lname, snap_ship_company, snap_ship_fname,
				snap_ship_lname, snap_ship_address1, snap_ship_address2, snap_ship_city, snap_ship_state, snap_ship_zip,
				snap_phone, snap_email, order_note, shipping_charge, snap_signature_charge, shipping_desc
		FROM #application.database#.order_info
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#i_order#">
			AND is_valid = 1
	</cfquery>
	<cfset this_program_ID = FindOrderInfo.this_program_ID>
	<cfset order_number = HTMLEditFormat(FindOrderInfo.order_number)>
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
	<cfset order_note = HTMLEditFormat(FindOrderInfo.order_note)>
	<cfset shipping_charge = FindOrderInfo.shipping_charge>
	<cfset snap_signature_charge = FindOrderInfo.snap_signature_charge>
	<cfset shipping_desc = FindOrderInfo.shipping_desc>
		
	<cfoutput>
		
	<tr class="printlabel">
	<td colspan="4">
	
		<table cellpadding="0" cellspacing="0" border="0" width="100%">
		
		<tr>
		<td valign="top" class="printlabel">
			<b>QTY: <cfif thisindv_qty GT 1><span class="highlight">#thisindv_qty#</span><cfelse>#thisindv_qty#</cfif></b>&nbsp;&nbsp;&nbsp;<span class="highlight"><span class="printpo">#GetProgramName(FindOrderInfo.this_program_ID)#</span></span>
		</td>
		</tr>
		
		<tr>
		<td valign="top" class="printlabel">
			SHIP TO:&nbsp;&nbsp;&nbsp;
			<span class="printpo"><cfif snap_ship_company NEQ "">#snap_ship_company#&nbsp;&nbsp;&nbsp;</cfif>
			<cfif snap_ship_fname NEQ "">#snap_ship_fname#</cfif> <cfif snap_ship_lname NEQ "">#snap_ship_lname#</cfif>&nbsp;&nbsp;&nbsp;
			<cfif snap_ship_address1 NEQ "">#snap_ship_address1#&nbsp;&nbsp;&nbsp;</cfif>
			<cfif snap_ship_address2 NEQ "">#snap_ship_address2#&nbsp;&nbsp;&nbsp;</cfif>
			<cfif snap_ship_city NEQ "">#snap_ship_city#</cfif>, <cfif snap_ship_state NEQ "">#snap_ship_state#</cfif> <cfif snap_ship_zip NEQ "">#snap_ship_zip#</cfif><br>
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<cfif snap_email NEQ ""><span class="printlabel">Email:</span> #snap_email#&nbsp;&nbsp;&nbsp;</cfif>
			<cfif snap_phone NEQ ""><span class="printlabel">Phone:</span> #snap_phone#&nbsp;&nbsp;&nbsp;</cfif></span><br>
			<cfif shipping_desc NEQ "">Ship via #shipping_desc#: #shipping_charge#</cfif>
			<cfif snap_signature_charge GT 0>Signature Required Charge: #snap_signature_charge#</cfif>
		</td>
		</tr>
		
		<tr>
		<td valign="top" class="printlabel">
		<cfif order_note NEQ "">ORDER NOTE: #Replace(HTMLEditFormat(order_note),chr(10),"<br>","ALL")#<cfelse><span class="sub">(no order note)</span></cfif>
		</td>
		</tr>
		
		<tr>
		<td colspan="4"><Br><br><Br><Br><br><Br><Br><br><Br><span class="sub">shipping sticker here</span><Br><Br><br><Br><Br><br><Br><Br><br></td>
		</tr>
	
		</table>
		

	</td>
	</tr>
	
	</cfoutput>
				
</cfloop>

	</table>

</table>
<cfinclude template="includes/footer.cfm">


<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->