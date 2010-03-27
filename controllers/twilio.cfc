<cfcomponent output="false">
	
	<cffunction name="init" access="public" returnType="any" output="false">
		<cfargument name="fw" type="any">
		<cfset variables.fw = arguments.fw>
		<cfreturn this />
	</cffunction>

	<cffunction name="tv">
		<cfargument name="rc">
		
		<cfset var message = "">
		<cfset var showId = 0>
		<cfset var tvObj = {}>
		<cfset var show = "">
		
		<cfif IsDefined("rc.body")>
			<cfset show = rc.body>
		</cfif>
		<cfif Len(Trim(show)) EQ 0>
			<cfset message = "Please reply with the name of the show you want to look up.">
		<cfelse>
			<cfset tvObj = createObject("component", "utils.tv").init()>
			<cfset showId = tvObj.getShowId(show)>
			<cfif showId EQ "" OR showId EQ 0>
				<cfset message = "Sorry, the show could not be found.">
			<cfelse>
				<cfset message = tvObj.findEpisode(showId, show)>
			</cfif>
		</cfif>

		<cfset rc.message = message>
	</cffunction>
	
	
</cfcomponent>