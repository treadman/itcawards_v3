<!--- Verify that a program was selected --->
<cfset has_program = true>
<cfif NOT isNumeric(request.selected_program_ID) OR request.selected_program_ID EQ 0>
	<cfif request.is_admin>
		<cfset has_program = false>
	<cfelse>
		<cflocation url="index.cfm" addtoken="no">
	</cfif>
</cfif>

<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess("1000000014-1000000063",true)>

<cfparam name="counter" default="0">

<!--- ************************** --->
<!--- START form processing code --->
<!--- ************************** --->

<cfif has_program AND IsDefined('form.Submit')>

	<!--- delete all exclude entries for this program --->
	<cfquery name="DeleteExProds" datasource="#application.DS#">
		DELETE FROM #application.database#.program_product_exclude
		WHERE program_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>
	
	<!--- loop through ExcludeThis and Insert into program_product_exclude --->
	<cfif IsDefined('form.ExcludeThis') AND #form.ExcludeThis# IS NOT "">
		<cfloop list="#form.ExcludeThis#" index="ThisProduct">
			<cfquery name="InsertQuery" datasource="#application.DS#">
				INSERT INTO #application.database#.program_product_exclude
				(created_user_ID, created_datetime, program_ID, product_ID)
				VALUES
				(<cfqueryparam cfsqltype="cf_sql_integer" value="#FLGen_adminID#" maxlength="10">, 
				'#FLGen_DateTimeToMySQL()#', 
				<cfqueryparam cfsqltype="cf_sql_integer" value="#request.selected_program_ID#" maxlength="10">, 
				<cfqueryparam cfsqltype="cf_sql_integer" value="#ThisProduct#" maxlength="10">)
			</cfquery>

		</cfloop>
	</cfif>
	<cfset alert_msg = Application.DefaultSaveMessage>
</cfif>

<!--- ************************--->
<!--- END form processing code --->
<!--- ************************ --->

<!--- *********************** --->
<!--- START page display code --->
<!--- *********************** --->

<cfif has_program>
	<cfquery name="SelectProgramCatProd" datasource="#application.DS#">
		SELECT pv.displayname AS cat_displayname, pvm.productvalue AS productvalue, pm.meta_name AS meta_name,
			prod.ID AS product_ID, prod.sku AS product_sku, prod.is_active
		FROM #application.database#.productvalue_program pv, #application.database#.productvalue_master pvm, #application.database#.product_meta pm, #application.database#.product prod
		WHERE pv.program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
			AND pv.productvalue_master_ID = pm.productvalue_master_ID 
			AND prod.product_meta_ID = pm.ID
			AND pv.productvalue_master_ID = pvm.ID
		ORDER BY pv.sortorder, pm.sortorder
	</cfquery>
	
	<cfquery name="SelectProgramExProducts" datasource="#application.DS#">
		SELECT product_ID
		FROM #application.database#.program_product_exclude
		WHERE program_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#request.selected_program_ID#" maxlength="10">
	</cfquery>

	<cfset ThisProgramsExProducts = ValueList(SelectProgramExProducts.product_ID)>

</cfif>

<cfset leftnavon = "program_product">
<cfinclude template="includes/header.cfm">

<cfif NOT has_program>
	<span class="pagetitle">Exclude Products</span>
	<br /><br />
	<span class="alert"><cfoutput>#application.AdminSelectProgram#</cfoutput></span>
<cfelse>
<span class="pagetitle">Exclude Products for <cfoutput>#request.program_name#</cfoutput></span>
<br /><br />
<span class="pageinstructions">Products are automatically included in a program once its category</span>
<br />
<span class="pageinstructions">is assigned to the program, unless you specifically exclude them below.</span>
<br /><br />
<span class="pageinstructions">Excluded products are checked and highlighted in blue below.  If just</span>
<br />
<span class="pageinstructions">the product name is blue, this means the product itself is marked inactive,</span>
<br />
<span class="pageinstructions">therefore will not show up on the catalog pages until it is marked active again.</span>
<br /><br />
<!--- <span class="pageinstructions"><strong>NOTE:</strong>  The column "Options (if any)" was removed.</span>
<br />
<span class="pageinstructions">&nbsp;&nbsp;&nbsp;With that column this list takes about two minutes to load.</span>
<br />
<span class="pageinstructions">&nbsp;&nbsp;&nbsp;Without it, it takes about 2-5 seconds.</span>
<br /><br /> --->

<cfif FLGen_HasAdminAccess(1000000014,false)>
	<span class="pageinstructions">Return to <a href="program.cfm">Award Program List</a> without making changes.</span>
	<br /><br />
</cfif>

<form method="post" action="#CurrentPage#">
	<table cellpadding="5" cellspacing="1" border="0" width="100%">
		<tr class="content">
			<td colspan="4"><span class="headertext">Program: <span class="selecteditem"><cfoutput>#request.program_name#</cfoutput></span></span></td>
		</tr>
		<cfset thisRow = 1>
		<cfoutput query="SelectProgramCatProd" group="cat_displayname">
			<tr class="contenthead">
				<td colspan="4"><span class="headertext">#cat_displayname#</span>&nbsp;&nbsp;&nbsp;<span class="sub">[Master Category #productvalue#]</span></td>
			</tr>
			<tr class="contenthead">
				<td><span class="headertext">Exclude</span></td>
				<td><span class="headertext">ITC SKU</span></td>
				<td><span class="headertext">Product Name</span></td>
				<td><span class="headertext">Options <span class="sub">(if any)</span></span></td>
			</tr>
			<cfoutput group="meta_name">
				<cfset thisMetaName = #meta_name#>
				<!--- check to see if this prod ID is in the ex prod id list --->
				<cfif ListContains(ThisProgramsExProducts, product_ID)>
					<cfset thischecked = " checked">
					<cfset thisexcluded = true>
				<cfelse>
					<cfset thischecked = "">
					<cfset thisexcluded = false>
				</cfif>

				<!--- ---------------------------------------------------------------------------
					Searching for the options makes this list take nearly two minutes to load.
					NOT showing options makes this list take only five seconds.
				--------------------------------------------------------------------------------- --->

				<!--- find options for this product, if any --->
				<cfquery name="SelectThisProdsOpt" datasource="#application.DS#">
					SELECT pmo.option_name AS option_name, pmoc.category_name
					FROM #application.database#.product_option po, #application.database#.product_meta_option pmo, #application.database#.product_meta_option_category pmoc
					WHERE po.product_ID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#product_ID#" maxlength="10"> 
						AND po.product_meta_option_ID = pmo.ID
						AND pmo.product_meta_option_category_ID = pmoc.ID
					ORDER BY pmoc.sortorder, pmo.sortorder
				</cfquery>
				<!--- this is where the individual products will get looped through --->
				<cfset thisRow = thisRow + 1>
				<tr class="<cfif  thisexcluded>inactivebg<cfelse>#Iif(((thisRow MOD 2) is 0),de('content2'),de('content'))# </cfif>">
					<td align="center"><input type="checkbox" name="ExcludeThis" value="#product_ID#"#thischecked#></td>
					<td>#product_sku#</td>
					<td<cfif NOT SelectProgramCatProd.is_active> class="inactivebg"</cfif>>#thisMetaName#</td>
					<td>
						<cfif SelectThisProdsOpt.RecordCount NEQ 0>
							<cfloop query="SelectThisProdsOpt">
								[#category_name#:&nbsp;&nbsp;<b>#option_name#</b>]<br>
							</cfloop>
						<cfelse>
							-
						</cfif>
					</td>
				</tr>
			</cfoutput>
		</cfoutput>
		<tr class="content">
			<td colspan="4" align="center">
				<input type="submit" name="submit" value="   Save Changes   " />
			</td>
		</tr>
	</table>
</form>
</cfif>
<cfinclude template="includes/footer.cfm">

<!--- ********************* --->
<!--- END page display code --->
<!--- ********************* --->