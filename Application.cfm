<cfsilent>

<!--- make sure the site is secure --->
<cfif NOT CGI.SERVER_PORT_SECURE>
	<cflocation url="https://#CGI.HTTP_HOST##CGI.SCRIPT_NAME#?#CGI.QUERY_STRING#" addtoken="no">
</cfif>

<cfsetting showDebugOutput="false">

<cfset CurrentPage = GetFileFromPath(GetBaseTemplatePath())>

<!---<cfif CurrentPage NEQ "site_down.cfm">
	<cflocation url="/site_down.cfm" addtoken="false">
</cfif>--->

<cfapplication name="ITC Awards V3" applicationtimeout="#CreateTimeSpan(1, 0, 0, 0)#" sessionmanagement="yes">

<!--- Set application variables after server restart or application timeout --->
<cfif Not IsDefined("Application.Initialized") OR isDefined("url.init")>
	
	<cflock scope="application" type="exclusive" timeout="30">
		
		<cfset Application.Initialized = true>
		<cfset Application.DevApp = false>
		
		<!--- Error handling --->
		<cfset Application.ErrorEmailSubject = "Error - " & Application.ApplicationName>
		<cfset Application.ErrorEmailTo = "treadmen@hotmail.com">
		<cfset Application.ErrorEmailBCC = "">
		
		<!--- Encryption/Hashing --->
		<cfset Application.salt="ljS458lsel72g35kjhfg44DDwjohgjh8a0q332">
		
		<!--- TODO:  These should be in admin --->
		<cfset Application.AwardsProgramAdminName = "Sarah Mene">
		<cfset Application.AwardsProgramAdminEmail = "smene@itcawards.com">

		<!--- Paths --->
		<cfset Application.FilePath="/inetpub/wwwroot/content/htdocs/itcawards_v3/">
		<cfset Application.AbsPath="/itcawards_v3/">
		<cfset Application.WebPath="http://www3.itcawards.com/">
		<cfset Application.SecureWebPath = "https://www3.itcawards.com">
		<cfset Application.PlainURL="www3.itcawards.com">
		<cfset Application.BasicURL="http://www.itcawards.com">
		<cfset Application.ComponentPath = "cfscripts.dfm_common.components">
		<cfset Application.ProductSetOneURL="https://www2.itcawards.com">

		<!--- Database --->
		<cfset Application.DS="DB">
		<cfset Application.database="ITCAwards_v3">
		<cfset Application.product_database="ITCAwards">
		
		<!--- Admin --->
		<cfset Application.AdminTimeout = "60">
		<cfset Application.AdminName = "ITC">
		<cfset Application.AdminSelectProgram = "Please select a program.">
			
		<!--- Misc. Variables--->
		<cfset Application.x_login = "227itc19702">
		<cfset Application.x_tran_key="3JkdpjvRy8ibPNju">

		<!--- TODO:  Put these into admin --->
		<cfset Application.DefaultEmailFrom = "orders@itcawards.com">
		<cfset Application.AdminEmailTo = "lmene@itcsafety.com">
		<cfset Application.OrdersEmailTo = "orders@itcawards.com">
		<cfset Application.OrdersFailTo = "smene@itcawards.com">
		<cfset Application.AddressValidationEmail = "amcneill@itcawards.com">
		<cfset Application.OrdersAdminEmail = "smene@itcawards.com">
		<cfset Application.OrdersAdminMessage = "please call toll-free 1.800.915.5999 or email Sarah Mene, Awards Administrator, at smene@itcawards.com.">
		<cfset Application.DefaultSaveMessage = "Changes were saved.">
		<cfset Application.NumFormat = "0">
		<cfset Application.OverrideEmail = ""><!--- Leave this blank in production! --->
	</cflock>
	
</cfif>

<cfset request.division_ID = 0>
<cfparam name="url.div" default="">
<cfif isNumeric(url.div)>
	<cfset request.division_ID = url.div>
</cfif>

<cferror type="validation" template="z_error_validation.cfm">
<cferror type="exception" template="z_error_exception.cfm" exception="any">

<!--- include function library --->
<cfinclude template="/cfscripts/dfm_common/function_library_general.cfm">

</cfsilent>
