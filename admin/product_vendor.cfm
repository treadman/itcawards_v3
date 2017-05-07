<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000008,true)>

<cfparam name="where_string" default="">
<cfparam name="meta_ID" default="">
<cfparam name="set_ID" default="">
<cfparam  name="pgfn" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString xL=Letter --->
<cfparam name="xS" default="">
<cfparam name="xT" default="">
<cfparam name="xL" default="">
<cfparam name="xW" default="">
<cfparam name="xA" default="">
<cfparam name="OnPage" default="">

<!--- param a/e form fields --->
<cfparam name="vl_ID" default="">
<cfparam name="vendor_ID" default="">
<cfparam name="is_default" default="">
<cfparam name="vendor_sku" default="">
<cfparam name="vendor_PO_note" default="">
<cfparam name="vendor_cost" default="">
<cfparam name="vendor_min_qty" default="">
<cfparam name="is_dropship" default="">
<cfparam name="pack_size" default="">
<cfparam name="pack_desc" default="">
<cfparam name="pack_error" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- update --->
	<cfif IsDefined('form.vl_ID') AND form.vl_ID IS NOT "">
		<!--- massage data if physical inventory --->
		<cfif NOT is_dropshipped>
			<cfif vendor_min_qty IS "" OR vendor_min_qty EQ "0">
				<cfset vendor_min_qty = "1">
			</cfif>
			<cfif (Trim(pack_size) IS "" AND NOT Trim(pack_desc) IS "") OR (Trim(pack_desc) IS "" AND NOT Trim(pack_size) IS "")>
				<cfset pack_size = "">
				<cfset pack_desc = "">
				<cfset pack_error = "Please enter both a Pack Size and a Pack Description.">
			</cfif>
		</cfif>
		<!--- do vendor lookup update --->
		<cfquery name="UpdateVendorlookup" datasource="#application.DS#">
			UPDATE #application.database#.vendor_lookup
			SET	vendor_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#vendor_ID#" maxlength="10">,
				product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#" maxlength="10">,
				is_default = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#is_default#" maxlength="1">,
				vendor_sku = <cfqueryparam cfsqltype="cf_sql_varchar" value="#vendor_sku#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(vendor_sku)))#">,
				vendor_PO_note = <cfqueryparam cfsqltype="cf_sql_varchar" value="#vendor_PO_note#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(vendor_PO_note)))#">,
				vendor_cost = <cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#vendor_cost#" maxlength="12" null="#YesNoFormat(NOT Len(Trim(vendor_cost)))#">,
				vendor_min_qty = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#vendor_min_qty#" maxlength="6" null="#YesNoFormat(NOT Len(Trim(vendor_min_qty)))#">,
				pack_size = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pack_size#" maxlength="6" null="#YesNoFormat(NOT Len(Trim(pack_size)))#">,
				pack_desc = <cfqueryparam cfsqltype="cf_sql_varchar" value="#pack_desc#" maxlength="16" null="#YesNoFormat(NOT Len(Trim(pack_desc)))#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.vl_ID#">
		</cfquery>
	<!--- add --->
	<cfelse>
		<!--- massage data if physical inventory --->
		<cfif NOT is_dropshipped>
			<cfif vendor_min_qty IS "" OR vendor_min_qty EQ "0">
				<cfset vendor_min_qty = "1">
			</cfif>
			<cfif (Trim(pack_size) IS "" AND NOT Trim(pack_desc) IS "") OR (Trim(pack_desc) IS "" AND NOT Trim(pack_size) IS "")>
				<cfset pack_size = "">
				<cfset pack_desc = "">
				<cfset pack_error = "Please enter both a Pack Size and a Pack Description.">
			</cfif>
		</cfif>
		<cflock name="vendor_lookupLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertVendorlookup" datasource="#application.DS#">
					INSERT INTO #application.database#.vendor_lookup
						(created_user_ID, created_datetime, vendor_ID, product_ID, is_default, vendor_sku, vendor_PO_note, vendor_cost, vendor_min_qty, pack_size, pack_desc)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#vendor_ID#" maxlength="10">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#" maxlength="10">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#is_default#" maxlength="1">, 
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#vendor_sku#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(vendor_sku)))#">, 
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#vendor_PO_note#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(vendor_PO_note)))#">, 
						<cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#vendor_cost#" maxlength="12" null="#YesNoFormat(NOT Len(Trim(vendor_cost)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#vendor_min_qty#" maxlength="6" null="#YesNoFormat(NOT Len(Trim(vendor_min_qty)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pack_size#" maxlength="6" null="#YesNoFormat(NOT Len(Trim(pack_size)))#">, 
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#pack_desc#" maxlength="16" null="#YesNoFormat(NOT Len(Trim(pack_desc)))#">
					)
				</cfquery>
				<cfquery datasource="#application.DS#" name="getID">
					SELECT Max(ID) As MaxID FROM #application.database#.vendor_lookup
				</cfquery>
				<cfset vl_ID = getID.MaxID>
			</cftransaction>  
		</cflock>
	</cfif>
	<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#&alert_msg=The%20vendor%20info%20was%20saved.">
<!--- Setting the vendor information for all individual products --->
<cfelseif IsDefined('form.Submit2')>
	<!--- delete the vendor asignations for all individual products --->
	<cfquery name="SelectAllIndividual" datasource="#application.DS#">
		SELECT ID AS indv_prod_ID
		FROM #application.database#.product
		WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
	</cfquery>
	<cfloop query="SelectAllIndividual">
		<cfquery name="DeleteAllIndvVendorLookups" datasource="#application.DS#">
			DELETE FROM #application.database#.vendor_lookup
			WHERE product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#SelectAllIndividual.indv_prod_ID#" maxlength="10">
		</cfquery>
	</cfloop>
	<!--- massage data if physical inventory --->
	<cfif NOT is_dropshipped>
		<cfif vendor_min_qty IS "" OR vendor_min_qty EQ "0">
			<cfset vendor_min_qty = "1">
		</cfif>
		<cfif (Trim(pack_size) IS "" AND NOT Trim(pack_desc) IS "") OR (Trim(pack_desc) IS "" AND NOT Trim(pack_size) IS "")>
			<cfset pack_size = "">
			<cfset pack_desc = "">
			<cfset pack_error = "Please enter both a Pack Size and a Pack Description.">
		</cfif>
	</cfif>
	<!--- insert vendor lookups for all individual products --->
	<cfloop query="SelectAllIndividual">
		<cflock name="vendor_lookupLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertVendorlookup" datasource="#application.DS#">
					INSERT INTO #application.database#.vendor_lookup
						(created_user_ID, created_datetime, vendor_ID, product_ID, is_default, vendor_sku, vendor_PO_note, vendor_cost, vendor_min_qty, pack_size, pack_desc)
					VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#vendor_ID#" maxlength="10">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#SelectAllIndividual.indv_prod_ID#" maxlength="10">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#is_default#" maxlength="1">, 
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#vendor_sku#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(vendor_sku)))#">, 
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#vendor_PO_note#" maxlength="128" null="#YesNoFormat(NOT Len(Trim(vendor_PO_note)))#">, 
						<cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#vendor_cost#" maxlength="12" null="#YesNoFormat(NOT Len(Trim(vendor_cost)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#vendor_min_qty#" maxlength="6" null="#YesNoFormat(NOT Len(Trim(vendor_min_qty)))#">, 
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pack_size#" maxlength="6" null="#YesNoFormat(NOT Len(Trim(pack_size)))#">, 
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#pack_desc#" maxlength="16" null="#YesNoFormat(NOT Len(Trim(pack_desc)))#">
					)
				</cfquery>
			</cftransaction>  
		</cflock>
	</cfloop>
	<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#&alert_msg=The%20vendor%20info%20was%20saved%20for%20all%20individual%20products.">
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "products">
<cfinclude template="includes/header.cfm">


<!--- START pgfn ADD/EDIT --->

<span class="pagetitle">Assign a Vendor</span>
<br /><br />
<span class="pageinstructions">Return to <a href="<cfoutput>product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#</cfoutput>">Product Detail</a> or <a href="<cfoutput>product.cfm?&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#</cfoutput>">Product List</a> without making changes.</span>
<br /><br />

<cfif pack_error NEQ "">
	<span class="alert"><cfoutput>#pack_error#</cfoutput></span>
	<br /><br />
</cfif>

<cfquery name="SelectProdInfo" datasource="#application.DS#">
	SELECT pm.meta_name AS meta_name, p.sku AS prod_sku, IF(p.is_dropshipped=1,"true", "false") AS is_dropshipped
	FROM #application.database#.product_meta pm
	JOIN #application.database#.product p ON p.product_meta_ID = pm.ID
	WHERE p.ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#prod_ID#">
</cfquery>
<cfset meta_name = SelectProdInfo.meta_name>
<cfset prod_sku = htmleditformat(SelectProdInfo.prod_sku)>

<!--- find the vendors for a select dropdown --->
<cfquery name="SelectVendors" datasource="#application.DS#">
	SELECT ID AS Xvendor_ID, vendor AS Xvendor_name
	FROM #application.database#.vendor
	WHERE is_dropshipper = #SelectProdInfo.is_dropshipped#
	ORDER BY vendor ASC 
</cfquery>


<cfif IsDefined('vl_ID') AND vl_ID IS NOT "">

	<!--- get vendor lookup info --->
	<cfquery name="ToBeEdited" datasource="#application.DS#">
		SELECT vendor_ID, is_default, vendor_sku, vendor_PO_note, vendor_cost, vendor_min_qty, pack_size, pack_desc
		FROM #application.database#.vendor_lookup
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#vl_ID#">
	</cfquery>
	<cfset vendor_ID = htmleditformat(ToBeEdited.vendor_ID)>
	<cfset is_default = htmleditformat(ToBeEdited.is_default)>
	<cfset vendor_sku = htmleditformat(ToBeEdited.vendor_sku)>
	<cfset vendor_PO_note = htmleditformat(ToBeEdited.vendor_PO_note)>
	<cfset vendor_cost = htmleditformat(ToBeEdited.vendor_cost)>
	<cfset vendor_min_qty = htmleditformat(ToBeEdited.vendor_min_qty)>
	<cfset pack_size = htmleditformat(ToBeEdited.pack_size)>
	<cfset pack_desc = htmleditformat(ToBeEdited.pack_desc)>

</cfif>

<cfoutput>
<form method="post" action="#CurrentPage#" name="TheOnlyForm">

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="content">
	<td colspan="2" class="headertext">Product: <span class="selecteditem">[SKU: #prod_sku#]</span> <span class="selecteditem">#meta_name# #FindProductOptions(prod_ID)#</span></td>
	</tr>

	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif IsDefined('vl_ID') AND vl_ID IS NOT "">Edit an Assigned<cfelse>Assign a</cfif> Vendor</td>
	</tr>
	
	<tr class="content">
	<td align="right">Vendor: </td>
	<td valign="top">
		<select name="vendor_ID">
				<option value="">-- Select a Vendor --</option>
			<cfloop query="SelectVendors">
				<option value="#HTMLEditFormat(Xvendor_ID)#"<cfif vendor_ID EQ HTMLEditFormat(Xvendor_ID)> selected</cfif>>#Replace(HTMLEditFormat(Xvendor_name)," (DROPSHIP)","")#</option>
			</cfloop>
		</select>
		<input type="hidden" name="vendor_ID_required" value="Please choose a vendor from the dropdown.">
	</td>
	</tr>

	<tr class="content">
	<td align="right">Is Default Vendor?: </td>
	<td valign="top">
		<select name="is_default">
			<option value="0"<cfif is_default EQ 0> selected</cfif>>No</option>
			<option value="1"<cfif is_default EQ 1> selected</cfif>>Yes</option>
		</select>
	</td>
	</tr>
	
	<tr class="content">
	<td align="right">Vendor SKU: </td>
	<td valign="top"><input type="text" name="vendor_sku" maxlength="128" size="60" value="#vendor_sku#"></td>
	</tr>
	
	<tr class="content2">
	<td align="right">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif"> <b>Does not print on PO.</b>&nbsp;&nbsp;Only Vendor SKU above prints on PO.</td>
	</tr>
	
	<tr class="content">
	<td align="right">Vendor&nbsp;PO&nbsp;Note&nbsp;</td>
	<td valign="top"><input type="text" name="vendor_PO_note" maxlength="128" size="60" value="#vendor_PO_note#"></td>
	</tr>
	
	<tr class="content">
	<td align="right">ITC Cost*: </td>
	<td valign="top"><input type="text" name="vendor_cost" maxlength="10" size="12" value="<cfif vendor_cost EQ ''>0<cfelse>#vendor_cost#</cfif>"> <span class="sub">(only enter numbers and decimal, ex. 30 or 30.25)</span>
	<input type="hidden" name="vendor_cost_required" value="Please enter an ITC cost."></td>
	</tr>
	
	<cfif NOT SelectProdInfo.is_dropshipped>	
		<tr class="content2">
		<td align="right">&nbsp;</td>
		<td valign="top"><img src="../pics/contrls-desc.gif" width="7" height="6">  If you enter a "Minimum Order Quantity" of 4 and the product comes in boxes of 4, the minimum order is 4 boxes of 4, or 16 individual items (not one box of 4).  
		<br /><br />
		You may enter a minimum quantity without entering a pack size or pack description.
		</td>
		</tr>
		<tr class="content">
		<td align="right">Minimum&nbsp;Order&nbsp;Quantity*:&nbsp;</td>
		<td valign="top"><input type="text" name="vendor_min_qty" maxlength="6" size="8" value="<cfif vendor_min_qty EQ "">1<cfelse>#vendor_min_qty#</cfif>"> <span class="sub">(Enter "1" if no minimum.)</span></td>
		</tr>
		<tr class="content">
		<td align="right">Vendor Pack Size: </td>
		<td valign="top"><input type="text" name="pack_size" maxlength="6" size="8" value="#pack_size#">
			<span class="sub">(If you have a pack size, please enter a description.)</span></td>
		</tr>
		<tr class="content">
		<td align="right">Vendor&nbsp;Pack&nbsp;Description: </td>
		<td valign="top"><input type="text" name="pack_desc" maxlength="16" size="8" value="#pack_desc#"> <span class="sub">(If you have a pack size, please enter a description.)</span></td>
		</tr>
	<cfelse>
		<input type="hidden" name="vendor_min_qty" value="">
		<input type="hidden" name="pack_size" value="">
		<input type="hidden" name="pack_desc" value="">
	</cfif>		
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="xS" value="#xS#">
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="xW" value="#xW#">
	<input type="hidden" name="xA" value="#xA#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	<input type="hidden" name="meta_ID" value="#meta_ID#">
	<input type="hidden" name="set_ID" value="#set_ID#">
	<input type="hidden" name="prod_ID" value="#prod_ID#">
	<input type="hidden" name="vl_ID" value="#vl_ID#">
	<input type="hidden" name="is_dropshipped" value="#SelectProdInfo.is_dropshipped#">
			
	<input type="submit" name="submit" value="   Save Changes   " >
	
	<cfquery name="SelectIndvProdInfo" datasource="#application.DS#">
		SELECT IF(is_dropshipped=1,"true", "false") AS is_dropshipped
		FROM #application.database#.product
		WHERE product_meta_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#">
	</cfquery>
	<cfif SelectIndvProdInfo.Recordcount GT 1>
		<cfset ship_type_check = ValueList(SelectIndvProdInfo.is_dropshipped)>
		<cfif ListValueCount(ship_type_check,"true") EQ 0 AND ListValueCount(ship_type_check,"false") GT 0>
			<cfset all_same = true>
		<cfelseif ListValueCount(ship_type_check,"true") GT 0 AND ListValueCount(ship_type_check,"false") EQ 0>
			<cfset all_same = true>
		<cfelse>
			<cfset all_same = false>
		</cfif>
		<cfif all_same>
			&nbsp;&nbsp;&nbsp;<input type="submit" name="submit2" value="Save for all Individual Products" ><br><br>If you "Save for all Individual Products", you will over-write their current vendor information.
		</cfif>
	</cfif>
	</td>
	</tr>
		
	</table>
</form>
</cfoutput>

<!--- END pgfn ADD/EDIT --->

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->
