<!--- authenticate the admin user --->
<cfset FLGen_AuthenticateAdmin()>
<cfset FLGen_HasAdminAccess(1000000008,true)>

<cfif dis EQ "y">
	<!--- set all products with this meta_ID to is_discontinued = 1 --->
	<cfquery name="InactivateProducts" datasource="#application.DS#">
		UPDATE #application.database#.product
		SET	is_discontinued = 1, is_active = 0
			#FLGen_UpdateModConcatSQL()#
			WHERE product_meta_ID = '#meta_ID#'
	</cfquery>
	<cfset dis = "y">
<cfelse>
	<!--- set all products with this meta_ID to is_discontinued = 0 --->
	<cfquery name="ActivateProducts" datasource="#application.DS#">
		UPDATE #application.database#.product
		SET	is_discontinued = 0, is_active = 1
			#FLGen_UpdateModConcatSQL()#
			WHERE product_meta_ID = '#meta_ID#'
	</cfquery>
	<cfset dis = "n">
</cfif>

<!--- redirect back with msg QS --->
<cflocation addtoken="no" url="product.cfm?dis=#dis#&pgfn=#pgfn#&meta_ID=#meta_ID#&xS=#xS#&xL=#xL#&xT=#xT#&xW=#xW#&xA=#xA#&OnPage=#OnPage#&set_ID=#set_ID#">