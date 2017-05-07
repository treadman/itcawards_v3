<!--- function library --->
<cfinclude template="../includes/function_library_local.cfm">

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000017,true)>

<cfparam name="po_ID" default="">

<!--- param search criteria xS=ColumnSort xT=SearchString --->
<cfparam name="xT" default="">
<cfparam name="xFD" default="">
<cfparam name="xTD" default="">
<cfparam name="po_type" default="po_type_1">
<cfparam name="this_from_date" default="">
<cfparam name="this_to_date" default="">

<!--- param a/e form fields --->
<cfparam name="status" default="">	
<cfparam name="v_ID" default="">	
<cfparam name="x_date" default="">

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfset leftnavon = "purchase_orders">
<cfinclude template="includes/header.cfm">

<SCRIPT LANGUAGE="JavaScript"><!-- 
function openURL() { 
	// grab index number of the selected option
	selInd = document.pageform.pageselect.selectedIndex; 
	// get value of the selected option
	goURL = document.pageform.pageselect.options[selInd].value;
	// redirect browser to the grabbed value (hopefully a URL)
	top.location.href = goURL; 
}
function openURLAgain() { 
	// grab index number of the selected option
	selInd = document.pageform2.pageselect.selectedIndex; 
	// get value of the selected option
	goURL = document.pageform2.pageselect.options[selInd].value;
	// redirect browser to the grabbed value (hopefully a URL)
	top.location.href = goURL; 
}
//--></SCRIPT>

<cfparam  name="pgfn" default="list">

<!--- START pgfn LIST --->

<!--- massage dates --->
<cfif this_from_date NEQ "" AND IsDate(this_from_date)>
	<cfset xFD = FLGen_DateTimeToMySQL(this_from_date,'startofday')>
</cfif>
<cfif this_to_date NEQ "" AND IsDate(this_to_date)>
	<cfset xTD = FLGen_DateTimeToMySQL(this_to_date,'endofday')>
</cfif>

<cfif xFD NEQ "">
	<cfset x_date =  RemoveChars(Insert(',', Insert(',', xFD, 6),4),11,16)>
	<cfset this_from_date = ListGetAt(x_date,2) & '/' & ListGetAt(x_date,3) & '/' & ListGetAt(x_date,1)>
</cfif>
<cfif xTD NEQ "">
	<cfset x_date =  RemoveChars(Insert(',', Insert(',', xTD, 6),4),11,16)>
	<cfset this_to_date = ListGetAt(x_date,2) & '/' & ListGetAt(x_date,3) & '/' & ListGetAt(x_date,1)>
</cfif>

<!--- run query --->
<cfquery name="SelectList" datasource="#application.DS#">
	SELECT ID AS po_ID, snap_vendor, is_dropship, Date_Format(created_datetime,'%c/%d/%Y') AS created_date ,IFNULL(Date_Format(po_rec_date,'%c/%d/%Y'),"") AS po_rec_date  
	FROM #application.database#.purchase_order 
	WHERE 1 = 1 
	<cfif LEN(xT) GT 0>
		AND ID LIKE <cfqueryparam value="%#xT#"> 
	</cfif>
	<cfif v_ID NEQ "">
		AND vendor_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#v_ID#" maxlength="10">
	</cfif>
	<cfif this_from_date NEQ "">
		AND created_datetime >= <cfqueryparam value="#xFD#">
	</cfif>
	<cfif this_to_date NEQ "">
		AND created_datetime <= <cfqueryparam value="#xTD#">
	</cfif>
	<cfif IsDefined('form.po_type') AND #form.po_type# IS "po_type_2">
		AND is_dropship = 0 AND  po_rec_date IS NULL 
	<cfelseif IsDefined('form.po_type') AND #form.po_type# IS "po_type_3">
		AND is_dropship = 0 AND  po_rec_date IS NOT NULL 
	<cfelseif IsDefined('form.po_type') AND #form.po_type# IS "po_type_4">
		AND is_dropship = 1 AND  po_rec_date IS NULL 
	<cfelseif IsDefined('form.po_type') AND #form.po_type# IS "po_type_5">
		AND is_dropship = 1 AND  po_rec_date IS NOT NULL 
	</cfif>

	ORDER BY created_datetime DESC
</cfquery>

<!--- set the start/end/max display row numbers --->
<cfparam name="OnPage" default="1">
<cfset MaxRows_SelectList="50">
<cfset StartRow_SelectList=Min((OnPage-1)*MaxRows_SelectList+1,Max(SelectList.RecordCount,1))>
<cfset EndRow_SelectList=Min(StartRow_SelectList+MaxRows_SelectList-1,SelectList.RecordCount)>
<cfset TotalPages_SelectList=Ceiling(SelectList.RecordCount/MaxRows_SelectList)>

<span class="pagetitle">Purchase Order List</span>
<br /><br />
<!--- search box --->
<table cellpadding="5" cellspacing="0" border="0" width="100%">
	<tr class="contenthead">
		<td><span class="headertext">Search Criteria</span></td>
		<td align="right"><a href="<cfoutput>#CurrentPage#</cfoutput>" class="headertext">view all</a></td>
	</tr>
	<tr>
		<td class="contentsearch" colspan="2" align="center"><span class="sub">All fields are optional.  Leave unnecessary fields blank.</span></td>
	</tr>
	<tr>
		<td class="content" colspan="2" align="center">
			<cfoutput>
			<form action="#CurrentPage#" method="post">
				<table cellpadding="5" cellspacing="0" border="0" width="100%">
					<tr>
					<td align="right"><span class="sub">vendor</span>: </td>
					<td colspan="2" align="left">#SelectVendor(v_ID,"All Vendors","v_ID")#</td>
					</tr>
					<tr>
					<td align="right"><span class="sub">po type</span>: </td>
					<td colspan="2" align="left">
						<select name="po_type">
							<option value="po_type_1"<cfif po_type EQ "po_type_1"> selected</cfif>>All</option>
							<option value="po_type_2"<cfif po_type EQ "po_type_2"> selected</cfif>>Incoming ITC POs</option>
							<option value="po_type_3"<cfif po_type EQ "po_type_3"> selected</cfif>>Received ITC POs</option>
							<option value="po_type_4"<cfif po_type EQ "po_type_4"> selected</cfif>>Sent Drop POs</option>
							<option value="po_type_5"<cfif po_type EQ "po_type_5"> selected</cfif>>Confirmed Drop POs</option>
						</select>
					</td>
					</tr>
					<tr>
					<td align="right"><span class="sub">purchase order ##</span>: </td>
					<td align="left"><input type="text" name="xT" value="#HTMLEditFormat(xT)#" size="20"></td>
					<td rowspan="3" align="center">			
						<input type="submit" name="submit" value="Search">
					</td>
					</tr>
					<tr>
					<td align="right"><span class="sub">From Date:</span> </td>
					<td align="left"><input type="text" name="this_from_date" value="#this_from_date#" size="20"></td>
					</tr>
					<tr>
					<td align="right"><span class="sub">To Date</span>: </td>
					<td align="left"><input type="text" name="this_to_date" value="#this_to_date#" size="20"></td>
					</tr>
				</table>
			</form>
			</cfoutput>
		</td>
	</tr>
</table>
<br />
<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0>
	<form name="pageform">
	<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr>
	<td>
		<cfif OnPage GT 1>
			<a href="<cfoutput>#CurrentPage#?OnPage=1&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
		</cfif>
	</td>
	<td align="center" class="sub">[ page 	
		<cfoutput>
		<select name="pageselect" onChange="openURL()"> 
			<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
				<option value="#CurrentPage#?OnPage=#this_i#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
			</cfloop>
		</select> of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
		</cfoutput>
	</td>
	<td align="right">
		<cfif OnPage LT TotalPages_SelectList>
			<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#</cfoutput>" class="pagingcontrols">&raquo;</a>
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
	<tr class="contenthead">
	<td align="center">&nbsp;</td>
	<td><span class="headertext">PO Number</span> <img src="../pics/contrls-asc.gif" width="7" height="6"></td>
	<td><span class="headertext">Date</span></td>
	<td><span class="headertext">Vendor Name</span></td>
	<td><span class="headertext">Status</span></td>
	</tr>
	<!--- if no records --->
	<cfif SelectList.RecordCount IS 0>
		<tr class="content2">
			<td colspan="7" align="center"><span class="alert"><br>No records found.  Click "view all" to see all records.<br><br></span></td>
		</tr>
	<cfelse>
		<!--- display found records --->
		<cfoutput query="SelectList" startrow="#StartRow_SelectList#" maxrows="#MaxRows_SelectList#">
			<!--- determine the order's status --->
		<!--- 	this makes incoming POs highlighted in orange
			<tr class="<cfif is_dropship EQ 0 AND po_rec_date EQ "">selectedbgcolor<cfelse>#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))# </cfif>"> --->
			<tr class="#Iif(((CurrentRow MOD 2) is 0),de('content2'),de('content'))#">
			<td align="center"><a href="po_detail.cfm?pgfn=detail&po_ID=#po_ID#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#&OnPage=#OnPage#">Detail</a></td>
			<td valign="top">#po_ID-1000000000#</td>
			<td valign="top">#HTMLEditFormat(created_date)#</td>
			<td valign="top">#HTMLEditFormat(snap_vendor)#</td>
			<td valign="top"><cfif is_dropship EQ 1 AND  po_rec_date EQ ""><span class="tooltip" title="Click 'Details' to set this PO to 'dropship confirmed.'">DROP</span> (PO Sent)<cfelseif is_dropship EQ 1 AND  po_rec_date NEQ "">DROP (PO Shipped)<cfelseif is_dropship EQ 0 AND po_rec_date EQ ""><span class="tooltip" title="Click 'Details' to set this PO to 'inventory received.'">ITC</span> (PO Sent)</span><cfelse>ITC (Received #po_rec_date#)</cfif></td>
			</tr>
		</cfoutput>
	</cfif>
</table>
<cfif IsDefined('SelectList.RecordCount') AND SelectList.RecordCount GT 0>
	<form name="pageform2">	<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr>
	<td>
		<cfif OnPage GT 1>
			<a href="<cfoutput>#CurrentPage#?OnPage=1&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#</cfoutput>" class="pagingcontrols">&laquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#Max(DecrementValue(OnPage),1)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#</cfoutput>" class="pagingcontrols">&lsaquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&laquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&lsaquo;</span>
		</cfif>
	</td>
	<td align="center" class="sub">[ page 	
	<cfoutput>
	<select name="pageselect" onChange="openURLAgain()"> 
		<cfloop from="1" to="#TotalPages_SelectList#" index="this_i">
			<option value="#CurrentPage#?OnPage=#this_i#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#"<cfif OnPage EQ this_i> selected</cfif>>#this_i#</option> 
		</cfloop>
	</select> of #TotalPages_SelectList# ]&nbsp;&nbsp;&nbsp;[ records #StartRow_SelectList# - #EndRow_SelectList# of #SelectList.RecordCount# ]
	</cfoutput>
	</td>
	<td align="right">
		<cfif OnPage LT TotalPages_SelectList>
			<a href="<cfoutput>#CurrentPage#?OnPage=#Min(IncrementValue(OnPage),TotalPages_SelectList)#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#</cfoutput>" class="pagingcontrols">&rsaquo;</a>&nbsp;&nbsp;&nbsp;<a href="<cfoutput>#CurrentPage#?OnPage=#TotalPages_SelectList#&xT=#xT#&xTD=#xTD#&xFD=#xFD#&v_ID=#v_ID#</cfoutput>" class="pagingcontrols">&raquo;</a>
		<cfelse>
			<span class="Xpagingcontrols">&rsaquo;</span>&nbsp;&nbsp;&nbsp;<span class="Xpagingcontrols">&raquo;</span>
		</cfif>
	</td>
	</tr>
	</table>
	</form>
</cfif>

<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->