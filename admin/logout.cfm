<!--- set cookies to nothing --->

<cfcookie name="admin_login" expires="now" value="">
<cfcookie name="itc_program" expires="now" value="">
<cfcookie name="program_ID" expires="now" value="">

<cflocation url="index.cfm?logout=y" addtoken="no">
