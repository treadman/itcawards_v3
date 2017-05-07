<br />
<table cellpadding="8" cellspacing="1" border="0" width="150">
<cfif is_one_item EQ 0>
<tr><td class="main_paging_number" valign="bottom">Product Search<!--- <cfoutput>#menu_text#</cfoutput>--->:</td></tr>
<tr>
	<td align="right" valign="top">
		<cfset thisSearchValue = "">
		<cfif isDefined("cookie.search")>
			<cfset thisSearchValue = cookie.search>
		</cfif>
		<cfoutput>
		<form name="SearchForm" action="search.cfm?div=#request.division_ID#" method="post" onsubmit="return document.SearchForm.searchtext.value != '';">
			<input type="hidden" name="set" value="#set#">
			<input type="text" name="searchtext" value="#thisSearchValue#" /><br /><br />
			<input type="submit" name="submitSearch" value=" Search " class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" />
		</form>
		</cfoutput>
	</td>
</tr>

<tr><td><img src="pics/shim.gif" width="155" height="2" <cfoutput>#cross_color#</cfoutput>></td></tr>

<tr><td class="main_paging_number" valign="bottom">Sort by Value:</td></tr>
<tr>
	<td align="right" valign="top">
		<cfset thisSortValue = "">
		<cfif isDefined("cookie.sort")>
			<cfset thisSortValue = cookie.sort>
		</cfif>
		<form name="SortForm" action="sort.cfm?<cfoutput>c=#c#&g=#g#&div=#request.division_ID#</cfoutput>" method="post">
			<input type="hidden" name="set" value="<cfoutput>#set#</cfoutput>">
			<select name="sortValue"><!---  onchange="document.SortForm.submit()" --->
				<option value="">Default Sort Order</option>
				<option value="low" <cfif thisSortValue EQ "low">selected</cfif>>Lowest to Highest</option>
				<option value="high" <cfif thisSortValue EQ "high">selected</cfif>>Highest to Lowest</option>
			</select><br /><br />
			<input type="submit" name="submitSort" value="   Sort   " class="active_button"  onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" />
		</form>
	</td>
</tr>

<tr><td><img src="pics/shim.gif" width="155" height="2" <cfoutput>#cross_color#</cfoutput>></td></tr>

<tr><td class="main_paging_number" valign="bottom">Product Value Filter:</td></tr>
<tr>
	<td align="right" valign="top">
		<cfset thisFilterValue = "">
		<cfif isDefined("cookie.filter")>
			<cfset thisFilterValue = cookie.filter>
		</cfif>
		<cfoutput><!--- (#thisFilterValue#) --->
		<form name="FilterForm" action="filter.cfm?c=#c#&g=#g#&div=#request.division_ID#" method="post">
			<input type="hidden" name="set" value="<cfoutput>#set#</cfoutput>">
			<select name="filterValue"><!---  onchange="document.SortForm.submit()" --->
				<option value="">All #menu_text# Values</option>
				<cfif ListFind(product_set_IDs,1)>
					<option value="0" <cfif thisFilterValue EQ "0">selected</cfif>>#100*points_multiplier# <!--- #credit_desc# ---> or less</option>
					<option value="101" <cfif thisFilterValue EQ "101">selected</cfif>>#(100*points_multiplier)+1# to #200*points_multiplier# <!--- #credit_desc# ---></option>
					<option value="201" <cfif thisFilterValue EQ "201">selected</cfif>>#(200*points_multiplier)+1# to #300*points_multiplier# <!--- #credit_desc# ---></option>
					<option value="301" <cfif thisFilterValue EQ "301">selected</cfif>>#(300*points_multiplier)+1# to #400*points_multiplier# <!--- #credit_desc# ---></option>
					<option value="401" <cfif thisFilterValue EQ "401">selected</cfif>>#(400*points_multiplier)+1# to #500*points_multiplier# <!--- #credit_desc# ---></option>
					<option value="501" <cfif thisFilterValue EQ "501">selected</cfif>>#(500*points_multiplier)+1# to #1000*points_multiplier# <!--- #credit_desc# ---></option>
					<option value="1001" <cfif thisFilterValue EQ "1001">selected</cfif>>#(1000*points_multiplier)+1# to #1500*points_multiplier# <!--- #credit_desc# ---></option>
					<option value="1501" <cfif thisFilterValue EQ "1501">selected</cfif>>#(1500*points_multiplier)+1# to #2000*points_multiplier# <!--- #credit_desc# ---></option>
					<option value="2001" <cfif thisFilterValue EQ "2001">selected</cfif>>Over #2000*points_multiplier# <!--- #credit_desc# ---></option>
				<cfelse>
					<option value="0" <cfif thisFilterValue EQ "0">selected</cfif>>#50*points_multiplier# <!--- #credit_desc# ---> or less</option>
					<option value="51" <cfif thisFilterValue EQ "51">selected</cfif>>#(50*points_multiplier)+1# to #100*points_multiplier# <!--- #credit_desc# ---></option>
					<option value="101" <cfif thisFilterValue EQ "101">selected</cfif>>Over #100*points_multiplier# <!--- #credit_desc# ---></option>
				</cfif>
			</select><br /><br />
			<input type="submit" name="submitFilter" value="   Filter   " class="active_button"  onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" />
		</form>
		</cfoutput>
	</td>
</tr>

<tr><td class="main_paging_number" valign="bottom">Search by Product Value:</td></tr>
<tr>
	<td align="right" valign="top">
		<cfset thisProductValue = "">
		<cfif isDefined("cookie.prodval")>
			<cfset thisProductValue = cookie.prodval>
		</cfif>
		<cfoutput>
		<form name="ProdValForm" action="prodval.cfm?div=#request.division_ID#" method="post" onsubmit="return document.ProdValForm.searchtext.value != '';">
			<input type="hidden" name="set" value="#set#">
			<input type="text" name="searchtext" value="#thisProductValue#" /><br /><br />
			<input type="submit" name="submitSearch" value=" Search " class="active_button"  onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" />
		</form>
		</cfoutput>
	</td>
</tr>
		<tr><td>&nbsp;</td></tr>
	<cfif has_welcomepage>
		<tr><td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='welcome.cfm?div=0'">Return To Welcome Page</td></tr>
		<tr><td>&nbsp;</td></tr>
	</cfif>
	<cfif has_promotion_button>
		<tr><td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='http://www.promoplace.com/itcspecialty'">Promotional Products</td></tr>
		<tr><td>&nbsp;</td></tr>
	</cfif>

<tr><td><img src="pics/shim.gif" width="155" height="2" <cfoutput>#cross_color#</cfoutput>></td></tr>
</cfif>
<cfinclude template="menu_bottom_buttons.cfm">
</table>
