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
<cfparam name="pmoc_ID" default="">
<cfparam name="category_name" default="">
<cfparam name="pmoc_sortorder" default="">
<cfparam name="ExistingOptions" default="">
<cfparam name="b" default="1">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif IsDefined('form.Submit')>
	<!--- update --->
	<cfif form.pmoc_ID IS NOT "">
		<!--- do PMOC update --->
		<cfquery name="UpdatePMOCQuery" datasource="#application.DS#">
			UPDATE #application.database#.product_meta_option_category
			SET	category_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.category_name#" maxlength="30">
				<cfif isNumeric(form.pmoc_sortorder) and form.pmoc_sortorder gte 0 and form.pmoc_sortorder lte 999>
					, sortorder = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.pmoc_sortorder#" maxlength="3">
				</cfif>
				#FLGen_UpdateModConcatSQL()#
				WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#form.pmoc_ID#" maxlength="10">
		</cfquery>
		<!--- do PMO update --->
		<cfloop list="#ExistingOptions#" index="ind">
			<cfset thisOptName = "optionx" & ind>
			<cfset thisOptSort = "pmo_sortorderx" & ind>
			<!--- <cfset thisOptName = Evaluate(thisOptName)>
			<cfset thisOptSort = Evaluate(thisOptSort)>
			<cfif thisOptName EQ ""><cfset thisOptName="CAN NOT BE BLANK"></cfif>
			<cfif thisOptSort EQ ""><cfset thisOptSort="0"></cfif>
			 --->			
			<cftry>
				<cfset thisOptName = Evaluate(thisOptName)>
				<cfcatch type="any">
					<cfset thisOptName="CAN NOT BE BLANK">
				</cfcatch>
			</cftry>
			<cftry>
				<cfset thisOptSort = Evaluate(thisOptSort)>
				<cfcatch type="any">
					<cfset thisOptSort="0">
				</cfcatch>
			</cftry>
			<cfquery name="UpdatePMOQuery" datasource="#application.DS#">
				UPDATE #application.database#.product_meta_option
				SET	option_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisOptName#" maxlength="64">,
					<cfif isNumeric(thisOptSort) and thisOptSort gte 0 and thisOptSort lte 999>
						sortorder = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#thisOptSort#" maxlength="3">
					</cfif>
					#FLGen_UpdateModConcatSQL()#
					WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#ind#" maxlength="10">
			</cfquery>
		</cfloop>
		<!--- do PMO add --->
		<cfif isDefined("form.blank_categories")>
			<cfloop from="1" to="#form.blank_categories#" index="ix">
				<cfset thisnewOptName = "option" & ix>
				<cfset thisnewOptSort = "pmo_sortorder" & ix>
				<cfset thisnewOptName = Evaluate(thisnewOptName)>
				<cfset thisnewOptSort = Evaluate(thisnewOptSort)>
				<cfif thisnewOptName NEQ "" AND thisnewOptSort NEQ "">
					<cfquery name="InsertNewPMO" datasource="#application.DS#">
						INSERT INTO #application.database#.product_meta_option
						(created_user_ID, created_datetime, product_meta_option_category_ID, option_name, sortorder)
						VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, '#FLGen_DateTimeToMySQL()#',
						<cfqueryparam cfsqltype="cf_sql_integer" value="#form.pmoc_ID#" maxlength="10">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisnewOptName#" maxlength="64">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#thisnewOptSort#" maxlength="3">)		
					</cfquery>
				</cfif>
			</cfloop>
		</cfif>
	<!--- add --->
	<cfelse>
		<cflock name="product_meta_option_categoryLock" timeout="10">
			<cftransaction>
				<cfquery name="InsertQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.product_meta_option_category (
						created_user_ID,
						created_datetime,
						product_meta_ID,
						category_name
						<cfif isNumeric(form.sortorder) and form.sortorder gte 0 and form.sortorder lte 999>
						, sortorder
						</cfif>
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="cf_sql_integer" value="#form.meta_ID#" maxlength="10">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form.category_name#" maxlength="30">
						<cfif isNumeric(form.sortorder) and form.sortorder gte 0 and form.sortorder lte 999>
							, 
							<cfqueryparam cfsqltype="cf_sql_integer" value="#form.sortorder#" maxlength="3">
						</cfif>
					)
				</cfquery>
				<cfquery datasource="#application.DS#" name="getID">
						SELECT Max(ID) As MaxID FROM #application.database#.product_meta_option_category
				</cfquery>
				<cfset pmoc_ID = getID.MaxID>
			</cftransaction>  
		</cflock>
		<!--- now add in the options for this new category --->
		<cfset OptionList = Replace(form.options,",","XCOMMAX","ALL")>
		<cfset OptionList = Replace(OptionList,chr(13) & chr(10),",","ALL")>
		<cfloop from="1" to="#ListLen(OptionList)#" index="ii">
			<cfif Trim(ListGetAt(OptionList,ii)) NEQ "">
				<cfset ThisOptionName = Replace(ListGetAt(OptionList,ii),"XCOMMAX",",","ALL")>
				<cfquery name="InsertOptQuery" datasource="#application.DS#">
					INSERT INTO #application.database#.product_meta_option
						(created_user_ID, created_datetime, product_meta_option_category_ID, option_name, sortorder)
					VALUES
						(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">,
						'#FLGen_DateTimeToMySQL()#', 
						<cfqueryparam cfsqltype="cf_sql_integer" value="#pmoc_ID#" maxlength="10">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#ThisOptionName#" maxlength="64">,
						<cfqueryparam cfsqltype="cf_sql_integer" value="#ii#" maxlength="3">)		
				</cfquery>
			</cfif>
		</cfloop>
	</cfif>
	<cflocation addtoken="no" url="product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#&alert_msg=#urlencodedformat(Application.DefaultSaveMessage)#">
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
<span class="pagetitle">Product Options</span>
<br /><br />
<span class="pageinstructions">Return to <a href="<cfoutput>product.cfm?pgfn=edit&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#</cfoutput>">Product Detail</a> or <a href="<cfoutput>product.cfm?&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#</cfoutput>">Product List</a> without making changes.</span>
<br /><br />

<cfquery name="SelectProdInfo" datasource="#application.DS#">
	SELECT meta_name
	FROM #application.database#.product_meta
	WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#meta_ID#" maxlength="10">
</cfquery>
<cfset meta_name = SelectProdInfo.meta_name>
	
<cfif pgfn EQ "edit" AND IsDefined('pmoc_ID') AND #pmoc_ID# IS NOT "">
	<!--- make list of the groups this meta_product is in --->
	<cfquery name="EditOptCat" datasource="#application.DS#">
		SELECT ID AS pmoc_ID, category_name, sortorder AS pmoc_sortorder
		FROM #application.database#.product_meta_option_category
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pmoc_ID#" maxlength="10">
	</cfquery>
	<cfset pmoc_ID = htmleditformat(EditOptCat.pmoc_ID)>
	<cfset category_name = htmleditformat(EditOptCat.category_name)>
	<cfset pmoc_sortorder = htmleditformat(EditOptCat.pmoc_sortorder)>

	<cfquery name="EditOptions" datasource="#application.DS#">
		SELECT ID AS pmo_ID, option_name, sortorder AS pmo_sortorder
		FROM #application.database#.product_meta_option
		WHERE product_meta_option_category_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#pmoc_ID#" maxlength="10">
		ORDER BY sortorder
	</cfquery>
	
	<cfset ExistingOptions = ValueList(EditOptions.pmo_ID)>

</cfif>

<cfoutput>
<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0">

	<tr class="content">
	<td colspan="2" class="headertext">Product: <span class="selecteditem">#meta_name#</span></td>
	</tr>

	<tr class="contenthead">
	<td colspan="2" class="headertext"><cfif pgfn EQ "edit">Edit<cfelse>Add</cfif> Product Options</td>
	</tr>
	
	<cfif pgfn EQ "add">
	
		<tr class="content">
		<td align="right" valign="top">Product&nbsp;Option&nbsp;Category:&nbsp;</td>
		<td valign="top"><input type="text" name="category_name" maxlength="64" size="40"></td>
		</tr>
		
		<tr class="content">
		<td align="right" valign="top">Category Sort Order: </td>
		<td valign="top"><input type="text" name="sortorder" maxlength="5" size="7"></td>
		</tr>
		
		<tr class="content2">
		<td valign="top">&nbsp;</td>
		<td valign="top"><img src="../pics/contrls-desc.gif"> Put them in the order in which you<br>&nbsp&nbsp&nbsp;would like them to appear.</td>
		</tr>
	
		<tr class="content">
		<td align="right" valign="top">Product Options: <br>(one per line)</td>
		<td valign="top">
		
		<textarea name="options" rows="7" cols="38"></textarea>
		<input type="hidden" name="set_ID" value="#set_ID#">
		<input type="hidden" name="category_name_required" value="Please enter a category name.">
		<input type="hidden" name="sortorder_required" value="Please enter a category sort order.">
		<input type="hidden" name="options_required" value="Please enter options.">
		
		</td>
		</tr>

	<cfelseif pgfn EQ "edit">

		<tr class="content">
		<td align="right" valign="top">Product&nbsp;Option&nbsp;Category:&nbsp;</td>
		<td valign="top"><input type="text" name="category_name" maxlength="64" size="40" value="#category_name#"></td>
		</tr>
		
		<tr class="content">
		<td align="right" valign="top">Category Sort Order: </td>
		<td valign="top"><input type="text" name="pmoc_sortorder" maxlength="5" size="7" value="#pmoc_sortorder#"></td>
		</tr>
		
		<tr class="content2">
		<td valign="top">&nbsp;</td>
		<td valign="top"><img src="../pics/contrls-desc.gif"> sort order&nbsp;&nbsp;&nbsp;&nbsp;<img src="../pics/contrls-desc.gif"> option name</td>
		</tr>
	
		<tr class="content">
		<td align="right" valign="top">Product Options: </td>
		<td valign="top">
		
		<!--- Loop through existing options and display each --->
		<cfloop query="EditOptions">
			<input type="text" name="pmo_sortorderx#pmo_ID#" maxlength="3" size="3" value="#pmo_sortorder#">
			&nbsp;&nbsp;<input type="text" name="optionx#pmo_ID#" maxlength="64" size="40" value="#HTMLEditFormat(option_name)#"><br>
			
			<input type="hidden" name="pmo_sortorderx#pmo_ID#_required" value="Please enter a sort order for the existing categories.">
			<input type="hidden" name="optionx#pmo_ID#_required" value="Please enter a category name for all existing categories.">
		</cfloop>
		</td>
		</tr>

		<tr class="content2">
		<td valign="top">&nbsp;</td>
		<td valign="top"><img src="../pics/contrls-desc.gif"> Click "Add Another Blank Option" to create all of the<br>&nbsp;&nbsp;&nbsp;blank fields <b>before</b> making any edits.</td>
		</tr>
	
		<tr class="content">
		<td align="right" valign="top">Add these new options:</td>
		<td>
			<!--- display empty option fields based on input --->
			<cfloop from="1" to="#b#" index="i">
				<input type="text" name="pmo_sortorder#i#" maxlength="3" size="3">&nbsp;&nbsp;<input type="text" name="option#i#" maxlength="64" size="40"><br>
			</cfloop>
			<cfset bnum = b + 1>
		<a href="#CurrentPage#?pgfn=edit&pmoc_ID=#pmoc_ID#&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&OnPage=#OnPage#&b=#bnum#&xW=#xW#&set_ID=#set_ID#">Add Another Blank Option</a>
			<input type="hidden" name="set_ID" value="#set_ID#"
			<input type="hidden" name="blank_categories" value="#b#">
			<input type="hidden" name="category_name_required" value="Please enter a category name.">
			<input type="hidden" name="pmoc_sortorder_required" value="Please enter a category sort order.">
	
			<input type="hidden" name="ExistingOptions" value="#ExistingOptions#">
			
		</td>
		</tr>
	
	
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
	<input type="hidden" name="pmoc_ID" value="#pmoc_ID#">
			
	<input type="submit" name="submit" value="   Save Changes   " >
	
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