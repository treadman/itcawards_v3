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
<cfparam name="min_order" default="">
<cfparam name="notes" default="">
<cfparam name="is_dropshipper" default="">
<cfparam name="delete" default="">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif ID GTE 2000000000>
<cfif IsDefined('form.Submit')>
	<cfif Trim(min_order) EQ "">
		<cfset min_order = '0'>
	</cfif>
	<cfif is_dropshipper EQ "1">
		<cfset vendor = vendor & " (DROPSHIP)">
	</cfif>
	<!--- update --->
	<cfif form.pgfn EQ "edit">
		<cfquery name="UpdateQuery" datasource="#application.DS#">
			UPDATE #application.database#.vendor
			SET	vendor = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#vendor#" maxlength="60">,
				address1 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.address1#" maxlength="38" null="#YesNoFormat(NOT Len(Trim(form.address1)))#">,
				address2 = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.address2#" maxlength="38" null="#YesNoFormat(NOT Len(Trim(form.address2)))#">,
				city = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.city #" maxlength="38" null="#YesNoFormat(NOT Len(Trim(form.city )))#">,
				state = <cfqueryparam cfsqltype="CF_SQL_CHAR" value="#form.state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.state)))#">,
				zip = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.zip)))#">,
				phone = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.phone#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(form.phone)))#">,
				fax = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.fax#" maxlength="14" null="#YesNoFormat(NOT Len(Trim(form.fax)))#">,
				email = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email#" maxlength="648" null="#YesNoFormat(NOT Len(Trim(form.email)))#">,
				what_terms = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.what_terms#" maxlength="20">,
				attention = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.attention#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(form.attention)))#">,
				min_order = <cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#min_order#" maxlength="10">,
				is_dropshipper = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#is_dropshipper#" maxlength="1">,
				notes = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.notes#" null="#YesNoFormat(NOT Len(Trim(form.notes)))#">
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.ID#" maxlength="10">
		</cfquery>
	<!--- add --->
	<cfelseif form.pgfn EQ "add" OR form.pgfn EQ "copy">
		<cflock name="vendorLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.vendor
						(created_user_ID, created_datetime, vendor, address1, address2, city, state, zip, phone, fax, email, attention, notes, what_terms, min_order, is_dropshipper)
					VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#vendor#" maxlength="60">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.address1#" maxlength="38" null="#YesNoFormat(NOT Len(Trim(form.address1)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.address2#" maxlength="38" null="#YesNoFormat(NOT Len(Trim(form.address2)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.city #" maxlength="38" null="#YesNoFormat(NOT Len(Trim(form.city )))#">,
						<cfqueryparam cfsqltype="CF_SQL_CHAR" value="#form.state#" maxlength="2" null="#YesNoFormat(NOT Len(Trim(form.state)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.zip#" maxlength="10" null="#YesNoFormat(NOT Len(Trim(form.zip)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.phone#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(form.phone)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.fax#" maxlength="14" null="#YesNoFormat(NOT Len(Trim(form.fax)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.email#" maxlength="648" null="#YesNoFormat(NOT Len(Trim(form.email)))#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.attention#" maxlength="32" null="#YesNoFormat(NOT Len(Trim(form.attention)))#">,
						<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#form.notes#" null="#YesNoFormat(NOT Len(Trim(form.notes)))#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#form.what_terms#" maxlength="20">,
						<cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#min_order#" maxlength="10">,  
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#is_dropshipper#" maxlength="1">)
				</cfquery>
				<cfquery name="getID" datasource="#application.DS#">
					SELECT Max(ID) As MaxID FROM #application.database#.vendor
				</cfquery>
				<cfset ID = getID.MaxID>
			</cftransaction>  
		</cflock>
	</cfif>
	<cfset alert_msg = Application.DefaultSaveMessage>
	<cfset pgfn = "edit">
<cfelseif delete NEQ '' AND FLGen_HasAdminAccess(1000000053)>
	<cfquery name="DeleteVendor" datasource="#application.DS#">
		DELETE FROM #application.database#.vendor
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#delete#" maxlength="10">
	</cfquery>			
</cfif>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "vendors">
<cfinclude template="includes/header.cfm">

<SCRIPT LANGUAGE="JavaScript"><!-- 
function openURL()
{ 
// grab index number of the selected option
selInd = document.pageform.pageselect.selectedIndex; 
// get value of the selected option
goURL = document.pageform.pageselect.options[selInd].value;
// redirect browser to the grabbed value (hopefully a URL)
top.location.href = goURL; 
}
//--> 
</SCRIPT>

<cfparam  name="pgfn" default="list">

<!--- START pgfn LIST --->
<cfif pgfn EQ "list">

	<!--- Set the WHERE clause --->
	<!--- First check if a search string passed --->
	<cfif LEN(xT) GT 0>
		<cfset xL = "">
	</cfif>
	
	<!--- run query --->
	<cfquery name="SelectList" datasource="#application.DS#">
		SELECT v.ID, v.vendor, COUNT(l.ID) as numVendorProducts
		FROM #application.database#.vendor v
		LEFT JOIN #application.database#.vendor_lookup l ON v.ID = l.vendor_ID
		<cfif LEN(xT) GT 0>
			WHERE v.vendor LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#PreserveSingleQuotes(xT)#%">
		<cfelseif LEN(xL) GT 0>
			WHERE v.vendor LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#xL#%">
		</cfif>
		GROUP BY v.ID
		ORDER BY v.vendor ASC
	</cfquery>
	
	<!--- set the start/end/max display row numbers --->
	<cfparam name="OnPage" default="1">
	<cfset MaxRows_SelectList="50">
	<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
	<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
	<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>
	
	<span class="pagetitle">Vendor List</span>
	<br /><br />

	<!--- search box --->
	<table cellpadding="5" cellspacing="0" border="0" width="100%">
	
	<tr class="contenthead">
	<td><span class="headertext">Search Criteria</span></td>
	<td align="right"><a href="<cfoutput>#CurrentPage#</cfoutput>" class="headertext">view all</a></td>
	</tr>
	
	<tr>
	<td class="content" colspan="2" align="center">
		<cfoutput>
		<form action="#CurrentPage#" method="post">
			<input type="hidden" name="xL" value="#xL#">
			<input type="hidden" name="xS" value="#xS#">
			<input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20">
			<input type="submit" name="search" value="search">
		</form>
		<br>		
		<cfif LEN(xL) IS 0><span class="ltrON">ALL</span><cfelse><a href="#CurrentPage#?xL=" class="ltr">ALL</a></cfif><span class="ltrPIPE">&nbsp;&nbsp;</span><cfloop index = "LoopCount" from = "0" to = "9"><cfoutput><cfif xL IS LoopCount><span class="ltrON">#LoopCount#</span><cfelse><a href="#CurrentPage#?xL=#LoopCount#" class="ltr">#LoopCount#</a></cfif></cfoutput><span class="ltrPIPE">&nbsp;&nbsp;</span></cfloop><cfloop index = "LoopCount" from = "1" to = "26"><cfoutput><cfif xL IS CHR(LoopCount + 64)><span class="ltrON">#CHR(LoopCount + 64)#</span><cfelse><a href="#CurrentPage#?xL=#CHR(LoopCount + 64)#" class="ltr">#CHR(LoopCount + 64)#</a></cfif></cfoutput><cfif LoopCount NEQ 26><span class="ltrPIPE">&nbsp;&nbsp;</span></cfif></cfloop>
		</cfoutput>
	</td>
	</tr>
	
	</table>
	
	<br />
	
	<cfif SelectList.RecordCount GT 0>
		<form name="pageform">
		<table cellpadding="0" cellspacing="0" border="0" width="100%">
		<tr>
		<td>
			<cfif OnPage GT 1>
				<a href="<cfoutput>#CurrentPage#?OnPage=1&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
			<cfelse>
				<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
			</cfif>
		</td>
		<td align="center" class="sub">[ page 	
			<cfoutput>
			<select name="pageselect" onChange="openURL()"> 
				<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
					<option value="#CurrentPage#?OnPage=#this_i#&xL=#xL#&xT=#xT#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
				</cfloop>
			</select>
			of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
			</cfoutput>
		</td>
		<td align="right">
			<cfif OnPage LT TotalPages_SelectList>
				<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xL=#xL#&xT=#xT#</cfoutput>" class="pagingcontrols">&raquo;</a>
			<cfelse>
				<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
			</cfif>
		</td>
		</tr>
		</table>
		</form>
	</cfif>
	
	<table cellpadding="5" cellspacing="1" border="0" width="100%">

	<!--- header row --->
	<cfoutput>	
		<tr class="contenthead">
		<td align="center"><a href="#CurrentPage#?pgfn=add&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Add</a></td>
		<td>
			<span class="headertext">Vendor</span> <img src="../pics/contrls-asc.gif" width="7" height="6">
		</td>
		</tr>
	</cfoutput>

	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
		<td colspan="3" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
		</tr>
	</cfif>

	<!--- display found records --->
	<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
		<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
		<td><a href="#CurrentPage#?pgfn=edit&id=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Edit</a>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?pgfn=copy&id=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Copy</a><cfif FLGen_HasAdminAccess(1000000053) and SelectList.numVendorProducts EQ 0>&nbsp;&nbsp;&nbsp;<a href="#CurrentPage#?delete=#ID#&xL=#xL#&xT=#xT#&OnPage=#OnPage#" onclick="return confirm('Are you sure you want to delete this vendor?  There is NO UNDO.')">Delete</a></cfif></td>
		<td valign="top" width="100%">#htmleditformat(vendor)#</td>
		</tr>
	</cfoutput>

	</table>
	<!--- END pgfn LIST --->
<cfelseif pgfn EQ "add" OR pgfn EQ "edit" OR pgfn EQ "copy">
	<!--- START pgfn ADD/EDIT --->
	<cfoutput>
	<span class="pagetitle"><cfif pgfn EQ "add" OR pgfn EQ "copy">Add<cfelse>Edit</cfif> a Vendor</span>
	<br /><br />
	<cfif pgfn eq 'edit'>
	<span class="pageinstructions">Open <a href="vendor_print.cfm?id=#id#" target="_blank">printable</a> page.</span>
	<br /><br />
	</cfif>
	<span class="pageinstructions">Return to <a href="#CurrentPage#?&xL=#xL#&xT=#xT#&OnPage=#OnPage#">Vendor List</a> without making changes.</span>
	<br /><br />
	</cfoutput>

	<cfif pgfn eq 'copy'>
		<span class="pageinstructions"><span class="alert">You are creating a new vendor.</span> The form below is filled with</span>
		<br />
		<span class="pageinstructions">the information from the vendor you requested to copy.</span>
		<br /><br />
	</cfif>

	<cfif pgfn EQ "edit" OR pgfn EQ "copy">
		<cfquery name="ToBeEdited" datasource="#application.DS#">
			SELECT ID, vendor, address1, address2, city, state, zip, phone, fax, email, attention, notes, min_order, what_terms, is_dropshipper 
			FROM #application.database#.vendor
			WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10">
		</cfquery>
		<cfset ID = ToBeEdited.ID>
		<cfset vendor = htmleditformat(ToBeEdited.vendor)>
		<cfif vendor CONTAINS "(DROPSHIP)">
			<cfset vendor = Replace(vendor,"(DROPSHIP)","")>
		</cfif>
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
		<cfset min_order = htmleditformat(ToBeEdited.min_order)>
		<cfset what_terms = htmleditformat(ToBeEdited.what_terms)>
		<cfset is_dropshipper = htmleditformat(ToBeEdited.is_dropshipper)>
	</cfif>

	<form method="post" action="#CurrentPage#">
	<cfoutput>

	<table cellpadding="5" cellspacing="1" border="0" width="100%">
	
	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "add" OR pgfn EQ "copy">Add<cfelse>Edit</cfif> a Vendor
		<cfif ID LT 2000000000>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="alert">Do not edit www2 vendors here</cfif>
	</td>
	</tr>

	<tr class="content">
	<td align="right" valign="top">Vendor Name: </td>
	<td valign="top"><cfif ID LT 2000000000>#vendor#<cfelse><input type="text" name="vendor" value="#vendor#" maxlength="60" size="40"></cfif></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Address Line 1: </td>
	<td valign="top"><cfif ID LT 2000000000>#address1#<cfelse><input type="text" name="address1" value="#address1#" maxlength="38" size="40"></cfif></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Address Line 2: </td>
	<td valign="top"><cfif ID LT 2000000000>#address2#<cfelse><input type="text" name="address2" value="#address2#" maxlength="38" size="40"></cfif></td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">City: </td>
	<td valign="top"><cfif ID LT 2000000000>#city#<cfelse><input type="text" name="city" value="#city#" maxlength="38" size="40"></cfif></td>
	</tr>
	<tr class="content">
	<td align="right" valign="top">State: </td>
	<td valign="top"><cfif ID LT 2000000000>#state#<cfelse><cfoutput>#FLGen_SelectState("state",state)#</cfoutput></cfif></td>
	</tr>
	
	<tr class="content">
	<td align="right" valign="top">Zip: </td>
	<td valign="top"><cfif ID LT 2000000000>#zip#<cfelse><input type="text" name="zip" value="#zip#" maxlength="10" size="10"></cfif></td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Phone: </td>
	<td valign="top"><cfif ID LT 2000000000>#phone#<cfelse><input type="text" name="phone" value="#phone#" maxlength="32" size="40"></cfif></td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Fax: </td>
	<td valign="top"><cfif ID LT 2000000000>#fax#<cfelse><input type="text" name="fax" value="#fax#" maxlength="14" size="40"></cfif></td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Email: </td>
	<td valign="top"><cfif ID LT 2000000000>#email#<cfelse><input type="text" name="email" value="#email#" maxlength="38" size="40"></cfif></td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Attention: </td>
	<td valign="top"><cfif ID LT 2000000000>#attention#<cfelse><input type="text" name="attention" value="#attention#" maxlength="32" size="40"></cfif></td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Terms: </td>
	<td valign="top"><cfif ID LT 2000000000>#what_terms#<cfelse>
		<select name="what_terms">
			<option value="Charge Credit Card"<cfif what_terms EQ "Charge Credit Card"> selected</cfif>>Charge Credit Card
			<option value="Send bill to ITC"<cfif what_terms EQ "Send bill to ITC"> selected</cfif>>Send bill to ITC
		</select></cfif>
	</td>
	</tr>
		
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif"> If you order both Dropship and Physical Inventory products from this vendor, please set them up twice with each setting</td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Dropship?: </td>
	<td valign="top"><cfif ID LT 2000000000>#is_dropshipper#<cfelse>
		<select name="is_dropshipper">
			<option value="0"<cfif is_dropshipper EQ "0"> selected</cfif>>NO DROPSHIP products assigned to this vendor
			<option value="1"<cfif is_dropshipper EQ "1"> selected</cfif>>ONLY DROPSHIP products assigned to this vendor
		</select></cfif>
	</td>
	</tr>
		
	<tr class="content2">
	<td align="right" valign="top">&nbsp;</td>
	<td valign="top"><img src="../pics/contrls-desc.gif"> Minimum Order is only used with physical inventory products ( a.k.a. products shipped from ITC) when<br>creating a PO.  It is not taken into consideration when creating a PO for dropshipped items.</td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Minimum&nbsp;Order: </td>
	<td valign="top"> $ <input type="text" name="min_order" value="#min_order#" maxlength="6" size="38"><br><span class="sub">0 (zero) means there is no minimum order.</span></td>
	</tr>
		
	<tr class="content">
	<td align="right" valign="top">Notes: </td>
	<td valign="top"><cfif ID LT 2000000000>#notes#<cfelse><textarea name="notes" cols="60" rows="10">#notes#</textarea></cfif></td>
	</tr>
				
	<tr class="content">
	<td colspan="2" align="center">
	
	<input type="hidden" name="pgfn" value="#pgfn#">
	<input type="hidden" name="xL" value="#xL#">
	<input type="hidden" name="xT" value="#xT#">
	<input type="hidden" name="OnPage" value="#OnPage#">
	
	<input type="hidden" name="ID" value="#ID#">
	<input type="hidden" name="vendor_required" value="Please enter a vendor name.">
		
	<cfif ID LT 2000000000><cfelse><input type="submit" name="submit" value="   Save Changes   " ></cfif>
	</td>
	</tr>
	</table>
	</cfoutput>
	</form>

	<cfif pgfn EQ "edit">
	
		<!--- find this vendor's product(s) --->
		<cfquery name="FindVendorsProds" datasource="#application.DS#">
			SELECT m.ID as meta_id, m.product_set_id, m.meta_sku AS meta_sku, m.meta_name AS meta_name, p.productvalue AS productvalue, prod.sku AS sku, prod.ID AS product_ID, IF(prod.is_dropshipped=1,'DROP','') AS is_dropshipped 
			FROM #application.database#.product_meta m
			JOIN #application.database#.productvalue_master p ON m.productvalue_master_ID = p.ID 
			JOIN #application.database#.product prod ON prod.product_meta_ID = m.ID 
			JOIN #application.database#.vendor_lookup vl ON vl.product_ID = prod.ID 
			WHERE vl.vendor_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ID#" maxlength="10"> 
			ORDER BY m.meta_name, p.productvalue, prod.sku
		</cfquery>
		
		<cfif FindVendorsProds.RecordCount EQ 0>
			<br><span class="alert">There are no products for this vendor.</span>
		<cfelse>
			<br>
			<table cellpadding="5" cellspacing="1" border="0" width="100%">
			
			<tr class="contenthead">
			<td colspan="4"><span class="headertext">Individual Products assigned to this Vendor</span></td>
			</tr>
			
			<tr class="contenthead">
			<td><span class="headertext">&nbsp;</span></td>
			<td><span class="headertext">ITC&nbsp;SKU&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></td>
			<td><span class="headertext">CAT</td>
			<td width="100%"><span class="headertext">Product Name</span></td>
			</tr>
			
			<cfloop query="FindVendorsProds">
				<cfoutput>
			<tr class="content">
			<td>#HTMLEditFormat(is_dropshipped)#</td>
			<td><a href="product.cfm?pgfn=edit&meta_id=#meta_id#&set_id=#product_set_id#">#HTMLEditFormat(sku)#</a></td>
			<td>#productvalue#</td>
			<td>#meta_name# #FindProductOptions(product_ID)#</td>
			</tr>
				</cfoutput>
			</cfloop>
			
			</table>
			
		</cfif>

	</cfif>
	<!--- END pgfn ADD/EDIT --->
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->