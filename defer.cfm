<!--- function library --->
<cfinclude template="includes/function_library_public.cfm">

<!--- authenticate program cookie and get program vars --->
<cfset GetProgramInfo(request.division_id)>

<cfset has_defered = "no">

<!--- delete order and user cookies --->
<cfcookie name="itc_order" expires="now" value="">
<cfcookie name="itc_user" expires="now" value="">

<!--- get the order_ID and user_ID from the survey cookie --->
<cfset AuthenticateSurveyCookie()>

<!--- FORM PROCESSING CODE to defer credits --->
<cfif IsDefined('form.submit') and can_defer>

	<!--- double check that they have points to defer, just in case the user refreshed --->
	<!--- get current total --->
	<cfset GetProgramUserInfo(user_ID)>
	<cfif user_totalpoints EQ user_total>
		<!--- awards_points entry for negative amount that is available --->
		<cfquery name="NegatePoints" datasource="#application.DS#">
			INSERT INTO #application.database#.awards_points
				(created_user_ID, created_datetime, user_ID, points, notes, is_defered)
			VALUES
				('#user_ID#', '#FLGen_DateTimeToMySQL()#', '#user_ID#', -#user_total#, "negating available points before deferring them", 0)
		</cfquery>
		<!--- awards_points entry for that amount set to defered ---> 
		<cfquery name="DeferPoints" datasource="#application.DS#">
			INSERT INTO #application.database#.awards_points
				(created_user_ID, created_datetime, user_ID, points, notes, is_defered)
			VALUES
				('#user_ID#', '#FLGen_DateTimeToMySQL()#', '#user_ID#', #user_total#, "deferring points at program user's request", 1)
		</cfquery>
	</cfif>
	<cfset has_defered = "yes">
</cfif>

<!---  process survey if submitted --->
<cfif IsDefined('form.submitsurvey') AND form.submitsurvey IS NOT "">
	<cfset ProcessCustomerSurvey()>
</cfif>

<cfinclude template="includes/header.cfm">

<br><br><br><br>
<cfif has_defered EQ "no">
	<table cellpadding="8" cellspacing="0" border="1" bordercolor="<cfoutput>#bg_active#</cfoutput>">
		<tr>
			<td align="center">
				<cfoutput>
				To defer your entire <span class="active_msg">#user_total#</span> #credit_desc# for<br>
				the next #company_name# Award Program, please<br>
				click the Defer Credits button.
				<br><br>
				<form method="post" action="#CurrentPage#">
					<input type="submit" name="submit" value="Defer Credits">
				</form>
				</cfoutput>
			</td>
		</tr>
	</table>
<cfelse>
	Your <cfoutput>#credit_desc#</cfoutput> have been deferred.<br>Thank you!
	<br><br>
	<cfif has_survey>
		<cfset CustomerSurvey("defer")>
	</cfif>
</cfif>

<cfinclude template="includes/footer.cfm">
