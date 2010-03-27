<cfcomponent displayname="tv">

	<cfset variables.showSearchUrl = "http://services.tvrage.com/feeds/search.php?show=">
	<cfset variables.episodeUrl = "http://services.tvrage.com/feeds/episode_list.php?sid=">
	<cfset variables.showInfo = "http://services.tvrage.com/feeds/showinfo.php?sid=">
	
	<cffunction name="init">
		<cfreturn this/>
	</cffunction>
	
	<!--- 
		first step is to search by the show name and get the show id
		fortunately, tvrage's api does a good job of finding the right show (at least in my test cases)
	--->
	<cffunction name="getShowId" returnType="numeric" hint="Returns Show ID">
		<cfargument name="show">
		
		<cfset var xml = "">
		<cfset var parsedXml = "">
		<cfset var childShow = {}>
		
		<cftry>
			<cfhttp url="#variables.showSearchUrl##arguments.show#" method="GET"></cfhttp>
				
			<cfset xml=cfhttp.FileContent>
			<cfset parsedXml = XmlParse(xml)>
			<cfif IsXmlDoc(parsedXml)>
				<cfif ArrayLen(parsedXml.Results.show) EQ 0>
					<cfreturn 0/>
				<cfelse>	
					<cfset childShow = XmlSearch(parsedXml, "/Results/show")>
					<cfreturn childShow[1].showid.xmlText />
				</cfif>
			<cfelse>
				<cfreturn 0/>
			</cfif>
			
			<cfcatch type="any">
				<cfreturn 0/>
			</cfcatch>

		</cftry>		
	</cffunction>
	
	<!--- this feature was added later based on my friend's advice --->
	<cffunction name="getShowTime" returnType="string" hint="Returns Show Time">
		<cfargument name="showId">
		
		<cfset var local = {}>
		<cfset local.message = "">
			
		<cftry>
			
			<cfhttp url="#variables.showinfo##arguments.showId#" method="GET"></cfhttp>
			<cfset local.xml = cfhttp.fileContent>
			<cfset local.parsedXml = XmlParse(local.xml)>
			
			<cfif IsDefined("local.parsedXml.Showinfo.airtime.xmlText")>
				<cfset local.message &= " " & local.parsedXml.Showinfo.airtime.xmlText & " EST">
			</cfif>
			<cfif IsDefined("local.parsedXml.Showinfo.airday.xmlText") AND Len(local.parsedXml.Showinfo.airday.xmlText) GT 3>
				<cfset local.message &= " " & Left(local.parsedXml.Showinfo.airday.xmlText, 3)>	
			</cfif>
			<cfcatch type="any">
				<cfset local.message = "">
			</cfcatch>
		</cftry>
		
		<cfreturn Trim(local.message) />
	</cffunction>
	
	<!--- 
		this is the complicated part where it loops throw the episode info and finds the upcoming episode
		I had a hard time trying to decide whether to return a show on the same day as the upcoming show or consider it as already passed
		I settled for showing it as the upcoming show but you can change it here
	--->
	<cffunction name="findEpisode" returnType="string" hint="returns upcoming and past shows">
		<cfargument name="showId" required="true">
		<cfargument name="showName" required="false">
		
		<cfset var xml = "">
		<cfset var parsedXml = "">
		<cfset var childEpisode = {}>
		<cfset var epCount = 0>
		<cfset var nextDateDiff = -1>
		<cfset var prevDateDiff = 1>
		<cfset var idx = 0>
		<cfset var epDateDiff = 0>
		<cfset var epDate = 0>
		<cfset var dayText = "">
		<cfset var message = "">
		<cfset var myShowName = "">
		
		<cfset var airTime = "">
		
		<cftry>
			
			<cfset airTime = getShowTime(arguments.showId)>

			<cfhttp url="#variables.episodeUrl##arguments.showId#" method="GET"></cfhttp>
			
			<cfset xml = cfhttp.FileContent>
			<cfset parsedXml = XmlParse(xml)>
			<cfif ArrayLen(parsedXml.Show.EpisodeList.Season.episode.airdate) EQ 0>
				<cfset message = "Sorry, we could not find the episode information for #arguments.showName#.">
			<cfelse>
				<cfset childEpisode = XmlSearch(parsedXml, "/Show/Episodelist/Season/episode/airdate")>
				<cfset epCount = ArrayLen(childEpisode)>				
				
				<cfloop from="#epCount#" to="1" index="idx" step="-1">
					<cfset epdate = childEpisode[idx].xmlText>
					<cfif IsDate(epdate)>
						<cfset epDateDiff = DateDiff("d", DateFormat(Now(),"mm/dd/yyyy"), epdate)>
						<cfif nextDateDiff EQ -1 AND epDateDiff GTE 0>
							<cfset nextDateDiff = epDateDiff>
						</cfif>
						<cfif prevDateDiff EQ 1 AND epDateDiff LT 0>
							<cfset prevDateDiff = epDateDiff>
						</cfif>
						<cfif nextDateDiff GT epDateDiff AND epDateDiff GTE 0>
							<cfset nextDateDiff = epDateDiff>
						</cfif>
						<cfif prevDateDiff GT epDateDiff AND epDateDiff LT 0>
							<cfset prevDateDiff = epDateDiff>
						</cfif>
						<cfif prevDateDiff LT 1>
							<cfbreak/>
						</cfif>
					</cfif>
				</cfloop>
				
				<cfset myShowName = parsedXml.Show.name.xmlText>
				<cfif myShowName NEQ arguments.showName>
					<cfset myShowName &= "*">
				</cfif>				
				<cfif nextDateDiff EQ -1>
					<cfset message &= "Next episode for #myShowName# is TBA. ">
				<cfelse>
					<cfif Abs(nextDateDiff) NEQ 1>
						<cfset dayText = "days">
					<cfelse>
						<cfset dayText = "day">
					</cfif>
					<cfif nextDateDiff EQ 0>
						<cfset message &= "Next episode of #myShowName# is today ">
						<cfif Len(airTime)>
							<cfset message &= "at " & airTime & " ">
						</cfif>
						<cfset message &= "(" & DateFormat( DateAdd("d", nextDateDiff, Now()), "m/d/yy") & "). "> 
					<cfelse>
						<cfset message &= "Next episode of #myShowName# in #nextDateDiff# #dayText# "> 
						<cfif Len(airTime)>
							<cfset message &= "at " & airTime & " ">
						</cfif>
						<cfset message &= "(" & DateFormat( DateAdd("d", nextDateDiff, Now()), "m/d/yy") & "). ">
					</cfif>
				</cfif>
					
				<cfif prevDateDiff EQ 1>
					<cfset message &= "Sorry, we do not have information about the previous episode.">
				<cfelse>
					<cfif Abs(prevDateDiff) GT 1>
						<cfset dayText = "days">
					<cfelse>
						<cfset dayText = "day">
					</cfif>
					<cfif prevDateDiff EQ 0>
						<cfset message &= "Last episode is today (#DateFormat( DateAdd("d", prevDateDiff, Now()), "m/d/yy")#).">
					<cfelse>
						<cfset message &= "Last episode was #Abs(prevDateDiff)# #dayText# ago (#DateFormat( DateAdd("d", prevDateDiff, Now()), "m/d/yy")#).">
					</cfif>
				</cfif>	

			</cfif>
			<cfif Len(message) EQ 0>
				<cfset message = "Sorry, we could not retrieve the episode information for #arguments.showName# at this time.">
			</cfif>
			
			<cfreturn message />
			
			<cfcatch type="any">
				<cfreturn "Sorry, we could not retrieve the episode information for the show requested."/>
			</cfcatch>

		</cftry>

	</cffunction>
	
	
</cfcomponent>