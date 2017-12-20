<%@ page language="java" 
	import="javax.servlet.*,
			javax.servlet.http.*,
			javax.servlet.jsp.*,
			java.util.*,
			java.text.*,
			java.io.*"
%><%
/**
 * jspinfo v1.0 - created by NilsCode
 * 
 * This is a one-file jsp engine info file. It displays data about its runtime environment
 * like PHP's phpinfo().
 * This file comes without any warrenty and you use it on your own risk.
 */
String jspinfo_version = "1.0";
%><%!
 
 	// format function for displaying 'null' values correctly
	public String displayNullable(Object s) {
		if (s == null) {
			return "<span class=\"italic\">(null)</span>";
		} else {
			String tmpStr = s.toString();
			if (tmpStr.length() == 0) {
			    tmpStr = "<span class=\"italic\">(empty string)</span>";
			} else {
			    tmpStr = tmpStr.replaceAll("\r", "<span class=\"light\">&#92;r</span>");
			    tmpStr = tmpStr.replaceAll("\n", "<span class=\"light\">&#92;n</span>");
			    tmpStr = tmpStr.replaceAll("\t", "<span class=\"light\">&#92;t</span>");
			}
			return tmpStr;
		}
	}
	
	// gimmick function for streaming a logo :)
 	public void streamLogo(HttpServletRequest req, HttpServletResponse resp, JspWriter out) {
 		String picData = "ffd8ffe000104a46494600010102001c001c0000ffdb0043000201010101010201010102020202020403020202020504040304060506060605060606070908060709070606080b08090a0a0a0a0a06080b0c0b0a0c090a0a0affdb004301020202020202050303050a0706070a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0affc0001108001f005803012200021101031101ffc4001f0000010501010101010100000000000000000102030405060708090a0bffc400b5100002010303020403050504040000017d01020300041105122131410613516107227114328191a1082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9faffc4001f0100030101010101010101010000000000000102030405060708090a0bffc400b51100020102040403040705040400010277000102031104052131061241510761711322328108144291a1b1c109233352f0156272d10a162434e125f11718191a262728292a35363738393a434445464748494a535455565758595a636465666768696a737475767778797a82838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae2e3e4e5e6e7e8e9eaf2f3f4f5f6f7f8f9faffda000c03010002110311003f00fd97f045c7c3cd4f5ff08fc34ff854fa2dfea77fe108b5ad7355d52d2188883cb44df0ef8d9afa669de31204f96257dd2c88f2411cfc6681e37baf05fc3fb8f1cfc71f849f0c6f2d7c2b6d7769e35d53c296f6b65a7dc6aeda8c505b5be9f73ab4f6f1324109956eda6755172c90c4ef2c73c31fb77c37d0742d5be1df83354d5345b4b9b9d2f47b59f4cb9b8b65792d256b4f29a48988cc6c63924425704abb2f424552f067ece3f063e1ef8c349f1f7843c1bf63d5b43f03c1e10d2eeffb46e64f23458645923b5daf2156c3aa9f318190e305c8e2bba8d5c246169c2fb7cdeb7d6ead74fa2d34766d6be6d7a18f9d4bd39d96be564f96da59dda69bd5eb76ae93b2a5ff00088783fc71f07bfe135f851f0c7c1a9ab6b1e1afb6f86935ab0b59ecd6e65b7f32dc4f259191648b7b26f682470cb931b30209e03c39e20f2fe135ff00c65f127c15f8757fa2693e1dd3a796f74f861b08354b88c48dab5ed94d76363586c31fd8de73089cc523b48b04b0dc3747ad7c42f09fc65f8afe2af8197df143e18eb7e02ff8412facfc5de1eb2f1331f115b5ef9e6dee96748650b059ac0fb198ed9526603238a7783dff00626d7bc59e37f8c7e0ff0018f81b59d43523a7ea7e38d522f13c17d0c074a4ff0045ba955a578ad7ece1770915536950e4ee008da34a14a0d4e9b77b3d9bb26d68ddd35757fcb5e6bc79e75aa56a9174aaa56bc759257693f792b34eceda79deeb96d2ed745f87bf08f5ed1ed35cb1f861a4c705edb473c297be195b69951d4301243344b244f83ca3aab29c8600822ad7fc2a8f85bff44d7c3fff0082683ff89aa5a57c79f81baf788acbc21a1fc67f09deeada95a4775a769769e22b692e2ea0741224b1c6ae59d190870ca082a4107158367f19ff00e118f889f117fe16c7c57f86ba7f84bc31fd91f60f275df2b51d27ed30fcff00dafe7388a0f36529f67c6dde879c9c571ac35693768b5657b3dddda4ada6bab3d078ba11516e49dddae9ab269393beba688eaffe1547c2dffa26be1fff00c1341ffc4d1ff0aa3e16ff00d135f0ff00fe09a0ff00e268f0f7c56f85de2ef135ff0082fc27f12740d5359d2b3fda9a4e9dac413dcd9e0e0f9b123178f938f980e6be6efd967f691f88ff00b537ed4be31d7342fda8bc2d6de08f07f88eff004db0f86fa6d8d95d5d6b963044b10d5bed3bfce480cf344eb2a068df6ece3393a51c0d6ab4ea4dfbaa0aeef7ebb2564f57d2f65dda31c466786a1569535ef3a92e5566ba6edddad23d6d77d126cfa47fe1547c2dff00a26be1ff00fc1341ff00c4d1ff000aa3e16ffd135f0fff00e09a0ffe26a1f06fc68f83bf11758baf0f7c3ef8b1e19d7750b104ded8e8daedbdd4d6e01c1de91bb3273c720735e511fc58f8a5f1c7f6c0d67e0ffc2cf1c4be1ff06fc36d3231e33d4acac6da69f54d56ed0b41671b5c4522c690a0323b28ddbfe43c106a69e12b54724fdde55777bab2e9d2fab692f365d6c7e1e9460e2f99ce5ca946ceef56faa5a24dbd765df43a3fda83e1c7c3cd23f668f889ab693e03d16d6ead7c0babcd6d736fa5c2924522d9ca55d58282ac080411c8228af27b7f8d1f11f5af80dfb417ecd9f1ef598b51f1b7c3ff00096ac7fb6a3b48edc6b7a55cd84f25a5e7971aaa23edca48a836ab28ee4d15188c3cf0d55d396bb3bad9a6ae9af26b534c262a9e3682ab0badd34f74d3b34fcd34d3fc0fa4be13ff00c92df0d7fd8bf67ffa212b7ebe11d63fe0a8f77e0796dbc1bf0fb5df87173a5e97a5d9dac72ebcfaf4377e725b46b3ac8b069d247f2cc245055d8155539e6a4f0aff00c15af5ab8f1469b078d35bf8596da3bdfc2bab5c69f3788a4b88ad8b8f35e246d31559c26e2aa480480091d6b55839ba7cfcf1daff0012bfdd7dfc8c2598d38d570f673ded7e495befb5ade673dfb6ff00c24f852ffb617c43f088f12e89f0dec3c4ff00b3a4573ac788e1b01040f7f3f8b2dc79f75e4a82e67904714b2b64ed7258902b27e1ef8d3e1edcf837e377c33b4f833f0821f10e8dfb3d6b930f1f7c14bbf334bbbb47876b5acf81febd9e38e41bc96c2374c9cd5d03f6adf0adf7c45f167ed31f1abe38fc2cf1378d6fbc150785340f08d8785b5f8f426d3fedf1dccc6e1ee2c9e52dc3b05dac0938240c624b4fdb4fe1e5ff00c32f17fc13d3748f821e05d13c61e15d5b4ebbbaf07e93adc2cb733d84f15bc8d1a6928acbe73c6198e4842e4024007ea638ea31c3c6939a972f2ebcd6575cb77d1cb456ea9f4d9dfe2279662258c9578d271e7e6d391b767cdca9ef18eaef7d24b777bab6478eb4efd8b65fd81fe1ae8ffb3c2f8364f8e7789e196d0dbc34f0c9ae26b65ed8dc9b868c999147eff224210305c0185ad6fdb7bfe6f8ff00ee99ff00ed0a8be1e7ed87f0b7e025af876c3e15f86be055e6a3a0f84b4bd2e6f18dce8bad5b6a7793c5610c572cd2c7a4ef2a66594292d964da58024817f5cff8285787bc4ffdb9ff000927c37fd9ef50ff00849fecbff092fdbb4ed725fed6fb363ecff69dfa41f3fcac0d9bf76cc0db8ab8e614e15d4a32528def794e37fe2539dbc95a1a2eed99cf29ab530ae1283849c796d1a52e5d2955a77d3793756edad2d1491ebbe3bf813f07ff0067cff82847ecdf65f04fe1de97e188b57b0f16d9eacba45b088df456fa623c5e7b0e6660ce4ef72cc4e324e0578e597c32b1f0e7ec5bfb5bf887e0bfc3ed32c3c4761f17bc45a2d9df68fa4c715cdb684975a7b5c5946f1a864b65804a7c952106338ad9d53fe0a7b7fadf88b4bf17eb5a17c0dbcd5b43f3ff00b1754ba4f104973a7f9c8126f2246d24b45e6200adb48dc060e4527877fe0a777be0f5d413c25a0fc0dd2c6ada94ba86aa34e4f1041f6dbc971e6dc4bb3491e64afb57748d966c0c938ae4a58cad4e10e69c6528a8def517bdcb5253d75dacec7756cbf0f56a54e5a738c64e76b5297bbcf4a14f4d2c9a7172d3b973c53ff0c55ff0b47f675ff8609ff8467fe12dff0084eac7eddff0896cfb67fc23de43fdbffb47caf9f7f97b73e7fcff00eb3b6eaf69ff008279325af8dbf684d1f543ff001378fe3c6af71386fbff0063952136a7fdddaaf8af9dfc1bff000508f0dfc39d62ebc43f0f7e1afecf5a16a17c08bdbed1b4dd72d66b804e48778b48567e79e49e6b63c13fb68fc26f0b7c7383f697d3be327832c756f16e8ad61f14fc25159eba2cae26b6771a7dedadc7f66b319845b5240e8abb4b63279acf175e9d5c34a939af8746e6a526d4b9acedb2b5d2f3b77d35c061ab51c642baa6d5a5794634e508a8b8285d27bbbd9bebcb7b5edaf63fb48b477dfb667c6ab8d10e6dec7f647bfb6d7361e05e3dc4d2421bfdaf23a7b515e437ff00b5bfc18f879f0b3e2678afc47f1b7c2fe20f13fc50d07c4371f11b54b6d275a8fec2a9a6cb169363a72c964a258533b19a53190189f9b028af1b329c25560a0d3518c55d75b68ff1bdbcacfa9f4593c2ac28549548b8b94e52b3e8a5aafc2d7b6d2bae87ffd9";
 		resp.setContentType("image/jpeg");
		StringBuffer outData = new StringBuffer(); 		
 		for (int i = 0; i < picData.length(); i += 2) {
 		    outData.append((char)Integer.parseInt(picData.substring(i, i+2), 16));
 		}
 		resp.setContentLength(outData.length());
 		try {
 			out.print(outData.toString());
 		} catch (Exception ex) {
 		}
 	}
 
%><%
	String doImage = request.getParameter("action");
	if (doImage != null && doImage.equals("displayLogo")) {
		streamLogo(request, response, out);
		return;
	}
%>
<html>
<head>
	<title>jspinfo() v<%= jspinfo_version %></title>
	<style type="text/css">
	<!--
		body 			{ background-color: #ffffff; }
		
		table			{ border-width: 0px; width: 100%; }
		td.category		{ background-color: #f8673d; vertical-align:top; padding: 2px;
							font-family: Tahoma, Arial; font-size: 10pt; color: #ffffff; font-weight: bold; }
		td.listCaption	{ background-color: #999999; vertical-align:top; padding: 2px;
							font-family: Tahoma, Arial; font-size: 10pt; color: #ffffff; font-weight: bold; }
		td.listKey		{ width: 20%; background-color: #dddddd; vertical-align:top; padding: 2px;
							font-family: Tahoma, Arial; font-size: 10pt; color: #000000; }
		td.listValue	{ width: 80%; background-color: #eeeeee; vertical-align:top; padding: 2px;
							font-family: Tahoma, Arial; font-size: 10pt; color: #000000; }
		td.space		{ background-color: #ffffff; vertical-align:top; padding: 2px;
							font-family: Tahoma, Arial; font-size: 10pt; color: #ffffff; }
		td.captionbig	{ background-color: #6ab7db; vertical-align:top; padding: 2px;
							font-family: Tahoma, Arial; font-size: 24pt; color: #ffffff; font-weight: bold; }
		td.caption		{ background-color: #6ab7db; vertical-align:top; text-align: right; padding: 2px;
							font-family: Tahoma, Arial; font-size: 10pt; color: #ffffff; font-weight: bold; }
		td.captionimage	{ background-color: #6ab7db; text-align: center; padding: 2px;
							font-size: 1pt; }
		span.italic		{ font-style: italic; color: #666666; }
        span.light		{ color: #666666; }
	-->
	</style>
</head>
<body>
<table>
	<tr>
		<td width="99%" class="captionbig">jspinfo() v<%= jspinfo_version %></td>
		<td width="1%" class="captionimage"><img src="jspinfo.jsp?action=displayLogo" alt="jspinfo()" /></td>
	</tr>
	<tr>
		<td colspan="2" class="caption">::: the ultimative one-file jsp info file :::</td>
	</tr>
</table>
&nbsp;
<table>
	<tr>
		<td class="category" colspan="2">System Properties</td>
	</tr>
<%
	Properties sysProperties = System.getProperties();
	Object[] keysObj = sysProperties.keySet().toArray();
	Arrays.sort(keysObj);
%>
	<tr>
		<td class="listCaption">Property Key</td>
		<td class="listCaption">Property Value</td>
	</tr>
<%
	for (int i = 0; i < keysObj.length; i++) {
%>
	<tr>
		<td class="listKey"><%= keysObj[i] %></td>
		<td class="listValue"><%
			Object val = sysProperties.get(keysObj[i]);
			out.print(displayNullable(val));
			//String valStr = String.valueOf(val);
			//if (valStr == null || valStr.trim().equals("")) {
			//	valStr = "&nbsp;";
			//}
			//out.print(valStr);
		 %></td>
	</tr>
<%
	}
%>
	<tr>
		<td class="space" colspan="2">&nbsp;</td>
	</tr>
	<tr>
		<td class="category" colspan="2">HTTP Request - Headers</td>
	</tr>
<%
	Enumeration e = request.getHeaderNames();
%>
	<tr>
		<td class="listCaption">Name</td>
		<td class="listCaption">Value</td>
	</tr>
<%
	while (e.hasMoreElements()) {
		String name = (String) e.nextElement();
		String value = request.getHeader(name);
%>
	<tr>
		<td class="listKey"><%= name %></td>
		<td class="listValue"><%= value %></td>
	</tr>
<%
	}
%>
	<tr>
		<td class="space" colspan="2">&nbsp;</td>
	</tr>
	<tr>
		<td class="category" colspan="2">HTTP Request - Infos</td>
	</tr>
	<tr>
		<td class="listCaption">Name</td>
		<td class="listCaption">Value</td>
	</tr>
	<tr>
		<td class="listKey">character encoding</td>
		<td class="listValue"><%= displayNullable(request.getCharacterEncoding()) %></td>
	</tr>
	<tr>
		<td class="listKey">content type</td>
		<td class="listValue"><%= displayNullable(request.getContentType()) %></td>
	</tr>
	<tr>
		<td class="listKey">locale</td>
		<td class="listValue"><%= displayNullable(request.getLocale()) %>
	</tr>
    <tr>
        <td class="listKey">all locales</td>
        <td class="listValue"><%
		Enumeration localeEnum = request.getLocales();
		if (localeEnum != null) {
		  while (localeEnum.hasMoreElements()) {
		      Locale oneLocale = (Locale)localeEnum.nextElement();
		      out.print(displayNullable(oneLocale) + " ");
		  }
		}
		%></td>
	</tr>
	<tr>
		<td class="listKey">http protocol</td>
		<td class="listValue"><%= displayNullable(request.getProtocol()) %></td>
	</tr>
	<tr>
		<td class="listKey">remote address</td>
		<td class="listValue"><%= displayNullable(request.getRemoteAddr()) %></td>
	</tr>
	<tr>
		<td class="listKey">remote host</td>
		<td class="listValue"><%= displayNullable(request.getRemoteHost()) %></td>
	</tr>
	<tr>
		<td class="listKey">scheme</td>
		<td class="listValue"><%= displayNullable(request.getScheme()) %></td>
	</tr>
	<tr>
		<td class="listKey">server name</td>
		<td class="listValue"><%= displayNullable(request.getServerName()) %></td>
	</tr>
	<tr>
		<td class="listKey">server port</td>
		<td class="listValue"><%= request.getServerPort() %></td>
	</tr>
	<tr>
		<td class="listKey">using secure connection</td>
		<td class="listValue"><%= request.isSecure() %></td>
	</tr>
	<tr>
		<td class="space" colspan="2">&nbsp;</td>
	</tr>
	<tr>
		<td class="category" colspan="2">Servlet / JSP Data</td>
	</tr>
	<tr>
		<td class="listCaption">Name</td>
		<td class="listCaption">Value</td>
	</tr>
	<tr>
		<td class="listKey">authentication type</td>
		<td class="listValue"><%= displayNullable(request.getAuthType()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">context path</td>
		<td class="listValue"><%= displayNullable(request.getContextPath()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">cookies</td>
		<td class="listValue"><%
			Cookie[] cookies = request.getCookies();
			if (cookies != null && cookies.length > 0) {
				for (int i = 0; i < cookies.length; i++) {
					Cookie cookie = cookies[i];
					out.println("Name: '"+cookie.getName()+"'<br />");
					out.println("Value: '"+cookie.getValue()+"'<br />");
					if (cookie.getDomain() != null) out.println("Domain: '"+cookie.getDomain()+"'<br />");
					if (cookie.getComment() != null) out.println("Comment: '"+cookie.getComment()+"'<br />");
					if (cookie.getPath() != null) out.println("Path: '"+cookie.getPath()+"'<br />");
					out.println("Max Age: '"+cookie.getMaxAge()+"' sec.<br />");
					if (cookie.getVersion() != 0) out.println("Version: '"+cookie.getVersion()+"'<br />");
					if (cookies.length > 1) out.println("<br />");
				}
			} else {
				out.print("&nbsp;");
			}
		 %></td>
	</tr>
	<tr>
		<td class="listKey">http method</td>
		<td class="listValue"><%= displayNullable(request.getMethod()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">path info</td>
		<td class="listValue"><%= displayNullable(request.getPathInfo()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">path (translated)</td>
		<td class="listValue"><%= displayNullable(request.getPathTranslated()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">query string</td>
		<td class="listValue"><%= displayNullable(request.getQueryString()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">remote user</td>
		<td class="listValue"><%= displayNullable(request.getRemoteUser()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">requested session id</td>
		<td class="listValue"><%= displayNullable(request.getRequestedSessionId()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">request uri</td>
		<td class="listValue"><%= displayNullable(request.getRequestURI()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">request url</td>
		<td class="listValue"><%= displayNullable(request.getRequestURL().toString()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">servlet path</td>
		<td class="listValue"><%= displayNullable(request.getServletPath()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">session - created at</td>
		<td class="listValue"><%
			long seesionCreated = session.getCreationTime();
			SimpleDateFormat sdf = new SimpleDateFormat("dd.MM.yyyy / HH:mm:ss.SSSS");
			String sessionCreatedStr = sdf.format(new Date(seesionCreated));
			out.print(sessionCreatedStr);
		%>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">session - last accessed</td>
		<td class="listValue"><%
			long seesionAccessed = session.getLastAccessedTime();
			String seesionAccessedStr = sdf.format(new Date(seesionAccessed));
			out.print(seesionAccessedStr);
		%>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">session - attributes</td>
		<td class="listValue"><%
			e = session.getAttributeNames();
			if (e.hasMoreElements()) {
				while (e.hasMoreElements()) {
					String name = (String) e.nextElement();
					Object value = session.getAttribute(name);
					out.println(name + ": '"+value+"'<br />");
				}
			} else {
				out.print("<span class=\"italic\">(no attribute objects bound to session)</span>");
			}
		%></td>
	</tr>
	<%
		ServletContext context = session.getServletContext();
		if (context != null) {
	%>
	<tr>
		<td class="listKey">context - servlet api - version</td>
		<td class="listValue"><%= context.getMajorVersion() + "." + context.getMinorVersion() %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">context - real path</td>
		<td class="listValue">'<%= request.getServletPath() %>':<br /><%= context.getRealPath(request.getServletPath()) %><br />&nbsp;<br />
		'/':<br /><%= context.getRealPath("/") %></td>
	</tr>
	<tr>
		<td class="listKey">context - server info</td>
		<td class="listValue"><%= displayNullable(context.getServerInfo()) %>&nbsp;</td>
	</tr>
	<tr>
		<td class="listKey">context - servlet context name</td>
		<td class="listValue"><%= displayNullable(context.getServletContextName()) %>&nbsp;</td>
	</tr>
	<%
		}
		File f = new File("");
	%>
	<tr>
		<td class="listKey">current directory</td>
		<td class="listValue"><%= f.getAbsolutePath() %>&nbsp;</td>
	</tr>
</table>
</body>
</html>
<%
%>
