<cfparam name="cp" default="1">
<cfif NOT isNumeric(cp) OR cp NEQ 2>
	<cfset cp = 1>
</cfif>

<cfparam name="set" default="0">

<cfparam name="c" default="">

<cfparam name="has_wrapper" default="true">

<cfif request.division_ID GT 0>
	<cfquery name="GetDivisionInfo" datasource="#application.DS#">
		SELECT parent_ID, welcome_instructions, welcome_button, welcome_bg, welcome_message, welcome_admin_button,
			additional_content_button, additional_content_message, email_form_button, email_form_message, help_button, help_message,
			logo, cross_color, text_active, bg_active, text_selected, bg_selected, login_prompt, display_welcomeyourname,
			display_youhavexcredits, bg_warning 
		FROM #application.database#.program
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#request.division_ID#" maxlength="10">
	</cfquery>
	<cfset welcome_bg = HTMLEditFormat(GetDivisionInfo.welcome_bg)>
	<cfset welcome_instructions = GetDivisionInfo.welcome_instructions>
	<cfset welcome_message = GetDivisionInfo.welcome_message>
	<cfset welcome_button = GetDivisionInfo.welcome_button>
	<cfset welcome_admin_button = GetDivisionInfo.welcome_admin_button>
	<cfset additional_content_button = GetDivisionInfo.additional_content_button>
	<cfset additional_content_message = GetDivisionInfo.additional_content_message>
	<cfset email_form_button = GetDivisionInfo.email_form_button>
	<cfset email_form_message = GetDivisionInfo.email_form_message>
	<cfset help_button = GetDivisionInfo.help_button>
	<cfset help_message = GetDivisionInfo.help_message>

	<cfset logo = GetDivisionInfo.logo>
	<cfset cross_color = GetDivisionInfo.cross_color>
	<cfset text_active = GetDivisionInfo.text_active>
	<cfset bg_active = GetDivisionInfo.bg_active>
	<cfset text_selected = GetDivisionInfo.text_selected>
	<cfset bg_selected = GetDivisionInfo.bg_selected>
	<cfset login_prompt = GetDivisionInfo.login_prompt>
	<cfset display_welcomeyourname = GetDivisionInfo.display_welcomeyourname>
	<cfset display_youhavexcredits = GetDivisionInfo.display_youhavexcredits>
	<cfset bg_warning = GetDivisionInfo.bg_warning>

			<!--- has the graphic cross? --->
			<cfif cross_color NEQ "">
				<cfset cross_color = ' style="background-color:###cross_color#"'>
			</cfif>



	<cfif GetDivisionInfo.parent_ID NEQ LEFT(cookie.itc_pid,10)>
		<cflocation url="logout.cfm" addtoken="false" >
	</cfif>
</cfif>


<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<link rel="shortcut icon" href="/favicon.ico" />
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>ITC Awards</title>
<cfif has_wrapper>
<cfif use_master_categories GT 2>
	<cfinclude template="program_style_tabs.cfm">
	<style type="text/css" media="screen"><!--
		#layer1 { position: absolute; top: 270px; left: 240px; width: 500px; height: 231px; visibility: visible; display: block }
	--></style>
<cfelse>
	<cfinclude template="program_style.cfm">
</cfif> 

<script>

function mOver(item, newClass) {
	item.className=newClass
}
function mOut(item, newClass) {
	item.className=newClass
}
function openHelp() {
	windowHeight = (screen.height - 150)
	helpLeft = (screen.width - 615)
	winAttributes = 'width=600, top=1, resizable=yes, scrollbars=yes, status=yes, titlebar=yes, height=' + windowHeight + ', left =' + helpLeft

	window.open('help.cfm?div=<cfoutput>#request.division_id#</cfoutput>','Help',winAttributes);

}
</script>

</head>

<body leftmargin="0" topmargin="0" marginheight="0" marginwidth="0" <cfoutput><cfif CurrentPage EQ "welcome.cfm">#welcome_bg#<cfelse>#main_bg#</cfif></cfoutput> <cfif has_divisions AND assign_div_points AND CurrentPage EQ "cart.cfm">onload="check_assign();"</cfif>>
<cfelse>
	<body>
</cfif>

<cfinclude template="environment.cfm">

<cfif has_wrapper>

<cfset this_width = 1080>
<!---<cfif CurrentPage EQ "additional_content.cfm">
	<cfset this_width = 950>
<cfelseif use_master_categories GT 2 OR (has_divisions AND ListFind("cart.cfm,welcome.cfm",CurrentPage))>
	<cfset this_width = 1080>
</cfif>--->
<div class="main_div">
<cfif logo NEQ "">
	<cfset kFLGen_ImageSize = FLGen_ImageSize(application.AbsPath & "pics/program/" & Logo)>
	<cfif isDefined("kFLGen_ImageSize.ImageWidth") AND kFLGen_ImageSize.ImageWidth LT 265>
		<!--- the logo is next to congrats --->
		<table cellpadding="0" cellspacing="0" border="0" width="<cfoutput>#this_width#</cfoutput>">
			<tr>
				<td width="275" style="padding:5px"><img src="pics/program/<cfoutput>#logo#</cfoutput>" style="padding-left:21px"></td>
				<td width="525" height="40" align="left" valign="bottom" style="padding-bottom:5px"><cfoutput><cfif CurrentPage EQ "welcome.cfm">#welcome_congrats#<cfelse>#main_congrats#</cfif></cfoutput></td>
			</tr>
		</table>
	<cfelse>
		<!--- the logo extends over the congrats --->
		<table cellpadding="0" cellspacing="0" border="0" width="<cfoutput>#this_width#</cfoutput>">
			<tr>
				<td style="padding:5px" width="5%">
					<img src="pics/program/<cfoutput>#logo#</cfoutput>" style="padding-left:21px">
				</td>
				<td align="center" valign="bottom">
					<cfif product_set_tabs AND CurrentPage EQ "main.cfm">
						<cfquery name="GetSetTabs" datasource="#application.DS#">
							SELECT ID, tab_label
							FROM #application.database#.product_set
							WHERE ID IN (#product_set_IDs#)
						</cfquery>
 	<div style="position: relative; top: -0px; left: -0px; ">
		<table cellpadding="0" cellspacing="0" border="0">
			<tr height="40px;">
				<cfoutput query="GetSetTabs">
					<cfif set EQ ID>
						<td align="center" class="selected_product_tab" width="150"
							onClick="window.location='main.cfm?set=#ID#&div=#request.division_id#'">#tab_label#</td>
					<cfelse>
						<td align="center" width="150" class="active_product_tab" onMouseOver="mOver(this,'selected_product_tab');" onMouseOut="mOut(this,'active_product_tab');" onClick="window.location='main.cfm?set=#ID#&div=#request.division_id#'">#tab_label#</td>
					</cfif>
					<td width="50">&nbsp;</td>
				</cfoutput>
			</tr>
		</table>
	</div>

					</cfif>
					<br>
				</td>
				<td align="right" valign="bottom">
				<cfif use_master_categories GT 2>
					<cfif has_main_menu_button>
						<cfoutput><span class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='main.cfm?div=#request.division_id#'"><b>&nbsp;&nbsp;Main Menu&nbsp;&nbsp;</b></span></cfoutput>
						<br><br>
					</cfif>
					<cfif CurrentPage EQ "main.cfm"> 
						<cfoutput><span class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='cart.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#'"><b>&nbsp;&nbsp;#Translate(language_ID,'view_cart_button')#&nbsp;&nbsp;</b></span></cfoutput>
					</cfif>
				<cfelseif ListFindNoCase("main_prod.cfm,cart.cfm",CurrentPage)>
					<cfif has_main_menu_button>
						<cfoutput><span class="checkout_off" onMouseOver="mOver(this,'checkout_over');" onMouseOut="mOut(this,'checkout_off');" onClick="window.location='main.cfm?div=#request.division_id#'"><b>&nbsp;&nbsp;Main Menu&nbsp;&nbsp;</b></span></cfoutput>
						<br><br>
					</cfif>
				</cfif>
				<br><br>
				</td>
			</tr>
			<cfif welcome_congrats NEQ "&nbsp;" AND welcome_congrats NEQ "">
				<tr>
					<td width="275"><img src="pics/shim.gif" width="275" height="1"></td>
					<td width="525" height="40" align="left" valign="bottom"><cfoutput>#welcome_congrats#</cfoutput></td>
				</tr>
			</cfif>
		</table>
	</cfif>
<cfelse>
	<table cellpadding="0" cellspacing="0" border="0" width="800">
		<tr>
			<td width="275" style="padding:5px"><img src="pics/shim.gif" style="padding-left:21px"></td>
			<td width="525" height="40" align="left" valign="bottom" style="padding-bottom:5px"><cfoutput><cfif CurrentPage EQ "welcome.cfm">#welcome_congrats#<cfelse>#main_congrats#</cfif></cfoutput></td>
		</tr>
	</table>
</cfif>

<table cellpadding="0" cellspacing="0" border="0" width="<cfoutput>#this_width#</cfoutput>">
	<tr>
		<td colspan="100%" width="<cfoutput>#this_width#</cfoutput>" height="5"><img src="pics/shim.gif" width="25" height="5"><img src="pics/shim.gif" width="<cfif product_set_tabs>1065<cfelse>355</cfif>" height="5" <cfoutput>#cross_color#</cfoutput>></td>
	</tr>
	<tr>
		<td width="200" valign="top" align="center">
			<cfswitch expression="#CurrentPage#">
				<!--- cart  & main--->
				<cfcase value="cart.cfm,main.cfm">
					<cfswitch expression="#use_master_categories#">
						<cfcase value="0">
							<cfinclude template="master_category_menu.cfm">
						</cfcase>
						<cfcase value="1,2,4">
							<cfinclude template="product_group_menu.cfm">
						</cfcase>
						<cfcase value="3">
							<cfinclude template="category_tab_menu.cfm">
						</cfcase>
						<cfdefaultcase>
							<br><br><span class="alert">Category style not set!</span>
						</cfdefaultcase>
					</cfswitch>
				</cfcase>
				<!--- checkout & confirmation --->
				<cfcase value="checkout.cfm,confirmation.cfm">
					<br />
					<cfif help_button NEQ "">
						<table cellpadding="8" cellspacing="1" border="0" width="150">
							<tr>
								<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="openHelp()"><cfoutput>#help_button#</cfoutput></td>
							</tr>
						</table>
					</cfif>
				</cfcase>
				<!--- main_login & main_prod --->
				<cfcase value="main_login.cfm,main_prod.cfm">
					<cfoutput>
					<br />
					<table cellpadding="8" cellspacing="1" border="0" width="150">
						<tr>
							<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="window.location='main.cfm?c=#c#&p=#url.p#&g=#g#&OnPage=#OnPage#&set=#set#&div=#request.division_id#'">#return_button#</td>
						</tr>
						<cfif help_button NEQ "">
							<tr>
								<td>&nbsp;</td>
							</tr>
							<tr>
								<td align="center" class="active_button" onMouseOver="mOver(this,'selected_button');" onMouseOut="mOut(this,'active_button');" onClick="openHelp()">#help_button#</td>
							</tr>
						</cfif>
						<cfif has_promotion_button>
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onClick="window.location='http://www.promoplace.com/itcspecialty'">Promotional Products</td></tr>
						</cfif>
					</table>
					</cfoutput>
				</cfcase>
				<!--- welcome --->
				<cfcase value="welcome.cfm,additional_content.cfm">
					<img src="pics/shim.gif" width="200" height="1">
					<cfoutput>
					<br /><br />
					<table cellpadding="8" cellspacing="1" border="0" width="150">
						<cfif trim(welcome_instructions) neq ''>
						<tr><td align="left" class="welcome_instructions">#Replace(welcome_instructions,chr(10),"<br>","ALL")#</td></tr>
						<tr><td>&nbsp;</td></tr>
						</cfif>
						<cfif welcome_button NEQ "">
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='main.cfm?div=#request.division_id#'">#welcome_button#</td></tr>
						</cfif>
						<cfif additional_content_button NEQ "">
							<tr><td>&nbsp;</td></tr>
							<cfif additional_content_button EQ "Francais">
								<tr><td align="center"><a href="additional_content.cfm?div=#request.division_id#"><img src="pics/welcome/btn-francais.gif" width="147" height="99" border="0" /></a></td></tr>
							<cfelse>
								<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='additional_content.cfm?div=#request.division_id#'">#additional_content_button#</td></tr>
							</cfif>
						</cfif>
						<cfif email_form_button NEQ "">
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='email_form.cfm?div=#request.division_id#'">#email_form_button#</td></tr>
						</cfif>
						<cfif welcome_admin_button NEQ "">
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='/admin/index.cfm'">#welcome_admin_button#</td></tr>
						</cfif>
						<cfif FileExists(application.FilePath & "award_certificate/" & users_username & "_certificate_" & program_ID & ".pdf")>
							<script>
							function openCertificate() {
								winAttributes = 'width=600, top=1, resizable=yes, scrollbars=yes, status=yes, titlebar=yes'
								winPath = '<cfoutput>#application.WebPath#award_certificate/#users_username#_certificate_#program_ID#.pdf</cfoutput>'
								window.open(winPath,'Certificate',winAttributes);
							}
							</script>
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="openCertificate()">View Certificate</td></tr>
						</cfif>
						<cfif help_button NEQ "">
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="openHelp()">#help_button#</td></tr>
						</cfif>
						<cfif has_promotion_button>
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onClick="window.location='http://www.promoplace.com/itcspecialty'">Promotional Products</td></tr>
						</cfif>
					</table>
					</cfoutput>
				</cfcase>
				<!--- register --->
				<cfcase value="register.cfm">
					<img src="pics/shim.gif" width="200" height="1">
					<cfoutput>
					<br /><br />
					<table cellpadding="8" cellspacing="1" border="0" width="150">
						<cfif register_page_text NEQ ""><tr><td align="left" class="welcome_instructions">#Replace(register_page_text,chr(10),"<br>","ALL")#</td></tr></cfif>
						<tr><td>&nbsp;</td></tr>
						<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='main.cfm?div=#request.division_id#'">#welcome_button#</td></tr>
						<cfif additional_content_button NEQ "">
							<tr><td>&nbsp;</td></tr>
							<cfif additional_content_button EQ "Francais">
								<tr><td align="center"><a href="additional_content.cfm?div=#request.division_id#"><img src="pics/welcome/btn-francais.gif" width="147" height="99" border="0" /></a></td></tr>
							<cfelse>
								<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='additional_content.cfm?div=#request.division_id#'">#additional_content_button#</td></tr>
							</cfif>
						</cfif>
						<cfif email_form_button NEQ "">
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='email_form.cfm?div=#request.division_id#'">#email_form_button#</td></tr>
						</cfif>
						<cfif welcome_admin_button NEQ "">
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="window.location='/admin/index.cfm'">#welcome_admin_button#</td></tr>
						</cfif>
						<cfif FileExists(application.FilePath & "award_certificate/" & users_username & "_certificate_" & program_ID & ".pdf")>
							<script>
							function openCertificate() {
								winAttributes = 'width=600, top=1, resizable=yes, scrollbars=yes, status=yes, titlebar=yes'
								winPath = '<cfoutput>#application.WebPath#award_certificate/#users_username#_certificate_#program_ID#.pdf</cfoutput>'
								window.open(winPath,'Certificate',winAttributes);
							}
							</script>
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="openCertificate()">View Certificate</td></tr>
						</cfif>
						<cfif help_button NEQ "">
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onclick="openHelp()">#help_button#</td></tr>
						</cfif>
						<cfif has_promotion_button>
							<tr><td>&nbsp;</td></tr>
							<tr><td align="center" class="active_button" onmouseover="mOver(this,'selected_button');" onmouseout="mOut(this,'active_button');" onClick="window.location='http://www.promoplace.com/itcspecialty'">Promotional Products</td></tr>
						</cfif>
					</table>
					</cfoutput>
				</cfcase>
				<cfdefaultcase>
					<br /><br />
				</cfdefaultcase>
			</cfswitch>
			<br />
			<img src="pics/shim.gif" width="200" height="1">
		</td>
		<td width="5" height="100" valign="top"><img src="pics/shim.gif" width="5" height="175" <cfif use_master_categories LT 3><cfoutput>#cross_color#</cfoutput></cfif>></td>
		<td width="<cfoutput>#this_width-75#</cfoutput>" valign="top" style="padding:12px"><!--- or 25px in confirmation, welcome and defer --->

</cfif><!--- has_wrapper --->

<!-- ----------------- -->
<!-- End of header.cfm -->
<!-- ----------------- -->
