<cfcomponent extends="org.corfield.framework"><cfscript>
	this.name = 'tvshowtime';
	this.sessionManagement = true;

	this.ApplicationTimeout = CreateTimeSpan( 0, 2, 0, 0 );
	this.SessionTimeout = CreateTimeSpan(0, 1, 0, 0);
	
	this.filePath = ExpandPath(".");
	
	variables.framework = {
		reload = 'restart',
		password = 'pass',
		home = 'twilio.tv',
		preserveKeyURLKey = 'fw1pkey',
		maxNumContextsPreserved = 10,
		baseURL = 'useCgiScriptName',
		applicationKey = 'tv.show'
	};
	
	function setupApplication() 
	{
		//create object
		//setBeanFactory(createObject("component", "models.ObjectFactory").init(expandPath("./assets/config/beans.xml.cfm")));	
	}

</cfscript>
	
	<!--- 
		the code below is not required for this application but I include since I use it commonly for other applications 
	--->
	
    <cffunction name="current">
        <cfargument name="receivedaction" default=""/>
        <cfset var currentaction = getSection() & "." & getItem() />
        <cfif receivedaction eq currentaction>
            <cfreturn 'current' />
        </cfif>
        <cfreturn '' />
    </cffunction> 
    
    <cffunction name="buildURL" access="public" output="false">
		<cfargument name="action" type="string" />
		<cfargument name="path" type="string" default="#variables.framework.baseURL#" />

		<cfset var initialDelim = '/' />
		<cfset var fullyQualifiedAction = "" />

		<cfif arguments.path eq "useCgiScriptName">
			<cfset arguments.path = CGI.SCRIPT_NAME />
		</cfif>

		<cfif find( '?', arguments.path ) gt 0>
			<cfif right( arguments.path, 1 ) eq '?' or right( arguments.path,1 ) eq '&'>
				<cfset initialDelim = '' />
			<cfelse>
				<cfset initialDelim = '/' />
			</cfif>
		</cfif>

		<cfset fullyQualifiedAction = rereplace(getFullyQualifiedAction(arguments.action),"[\.|?|\&|\=]","/","all")>


		<!--- if you are using a URL rewriter please add variables.framework.URLRewrite=true; to list of variables--->
		<cfif structkeyexists(variables.framework,"URLRewrite") AND variables.framework.URLRewrite>
		<!--- remove [/index.cfm] from URL --->
			<cfset arguments.path = rereplacenocase(arguments.path,"\/index\.cfm","")>
		<!--- remove : from subsystem name --->
			<cfset fullyQualifiedAction = rereplace(fullyQualifiedAction,"\:","/")>
		</cfif>

		<cfreturn "#arguments.path##initialDelim##fullyQualifiedAction#" />

	</cffunction>


	<cffunction name="redirect" access="public" output="false"
		hint="Redirect to the specified action, optionally append specified request context items - or use session.">
		<cfargument name="action" type="string" />
		<cfargument name="preserve" type="string" default="none" />
		<cfargument name="append" type="string" default="none" />
		<cfargument name="path" type="string" default="#CGI.SCRIPT_NAME#" />

		<cfset var queryString = "" />
		<cfset var key = "" />
		<cfset var preserveKey = "" />

		<cfif arguments.preserve is not "none">
			<cfset preserveKey = saveFlashContext(arguments.preserve) />
			<cfset queryString = "/#variables.framework.preserveKeyURLKey#=#preserveKey#">
		</cfif>

		<cfif arguments.append is not "none">
			<cfif arguments.append is "all">
				<cfloop item="key" collection="#request.context#">
					<cfif isSimpleValue( request.context[key] )>
						<cfset queryString = queryString & "/" & key & "/" &rereplace(request.context[key],"[\.|?|\&|\=]","/","all") />
					</cfif>
				</cfloop>
			<cfelse>
				<cfloop index="key" list="#arguments.append#">
					<cfif structKeyExists( request.context, key ) and isSimpleValue( request.context[key] )>
						<cfset queryString = queryString & "/" & key & "/" &  rereplace(request.context[key],"[\.|?|\&|\=]","/","all") />
					</cfif>
				</cfloop>
			</cfif>
		</cfif>
		<!--- if you are using a URL rewriter please add
				variables.framework.URLRewrite=true; to list of variables--->
		<cfif structkeyexists(variables.framework,"URLRewrite") AND variables.framework.URLRewrite>
			<cfset queryString = rereplace(queryString,"[\.|?|\&|\=]","/","all")>
		</cfif>

		<cflocation url="#buildURL(arguments.action, arguments.path)##queryString#" addtoken="false" />

	</cffunction>

</cfcomponent>