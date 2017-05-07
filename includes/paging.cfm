<!--- product paging --->
<cfset MaxPages = 20>
<cfif OnPage MOD MaxPages GT 0>
	<cfset StartPage = OnPage - ( OnPage MOD MaxPages ) + 1>
<cfelse>
	<cfset StartPage = OnPage - MaxPages + 1>
</cfif>
<cfset EndPage = MIN(StartPage+MaxPages-1, TotalPages_ProductDisplay)>

<!--- 
<cfif REMOTE_ADDR EQ "63.68.13.230">
	<cfoutput>
	Total Pages: #TotalPages_ProductDisplay#<br>
	Current Page: #OnPage#<br />
	Start Page: #StartPage#<br />
	End Page: #EndPage#<br />
	Last Start Page: #TotalPages_ProductDisplay - ( TotalPages_ProductDisplay MOD MaxPages ) + 1#<br />
	</cfoutput>
</cfif>
--->

<br>
<table cellpadding="3" cellspacing="2" border="0" align="center">
<tr>
<!--- first page --->
<td align="right">
	<cfif OnPage EQ 1>
		<span class="main_paging_selected">&nbsp;</span>
	<cfelse>
		<a href="<cfoutput>#CurrentPage#?c=#c#&p=#url.p#&g=#g#&OnPage=1</cfoutput>" class="main_paging_active">&laquo;</a>
	</cfif>
</td>
<!--- previous page --->
<td align="right">
	<cfif OnPage EQ 1>
		<span class="main_paging_selected">&nbsp;</span>
	<cfelse>
		<a href="<cfoutput>#CurrentPage#?c=#c#&p=#url.p#&g=#g#&OnPage=#Max(DecrementValue(OnPage),1)#</cfoutput>" class="main_paging_active">prev</a>
	</cfif>
</td>
<cfif TotalPages_ProductDisplay GT MaxPages AND OnPage GT MaxPages>
	<td><a href="<cfoutput>#CurrentPage#?c=#c#&p=#url.p#&g=#g#&OnPage=#StartPage-MaxPages#</cfoutput>" class="main_paging_active">...</a></td>
</cfif>
<!--- page number links --->
<cfif TotalPages_ProductDisplay GT 1>
	<cfloop index="PagingLoop" from="#StartPage#" to="#EndPage#">
		<cfif OnPage EQ PagingLoop>
			<td><span class="main_paging_number"><cfoutput>#PagingLoop#</cfoutput></span></td>
		<cfelse>
			<td><cfoutput><a href="#CurrentPage#?c=#c#&p=#url.p#&g=#g#&OnPage=#PagingLoop#" class="main_paging_active">#PagingLoop#</a></cfoutput></td>
		</cfif>
	</cfloop>
<cfelse>
	<td></td>
</cfif>
<cfif TotalPages_ProductDisplay GT MaxPages AND OnPage LT TotalPages_ProductDisplay - ( TotalPages_ProductDisplay MOD MaxPages ) + 1>
	<td><a href="<cfoutput>#CurrentPage#?c=#c#&p=#url.p#&g=#g#&OnPage=#EndPage+1#</cfoutput>" class="main_paging_active">...</a></td>
</cfif>
<!--- next page --->
<td align="left">
	<cfif OnPage LT TotalPages_ProductDisplay>
		<a href="<cfoutput>#CurrentPage#?c=#c#&p=#url.p#&g=#g#&OnPage=#Min(IncrementValue(OnPage),TotalPages_ProductDisplay)#</cfoutput>" class="main_paging_active">next</a>
	<cfelse>
		<span class="main_paging_selected">&nbsp;</span>
	</cfif>
</td>
<!--- last page --->
<td align="left">
	<cfif OnPage LT TotalPages_ProductDisplay>
		<a href="<cfoutput>#CurrentPage#?c=#c#&p=#url.p#&g=#g#&OnPage=#TotalPages_ProductDisplay#</cfoutput>" class="main_paging_active">&raquo;</a>
	<cfelse>
		<span class="main_paging_selected">&nbsp;</span>
	</cfif>
</td>
</tr>
</table>
<br>
