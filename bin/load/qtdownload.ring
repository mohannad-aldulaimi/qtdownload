load 'guilib.ring'

/*
    * Function name    : QTDownload
    * Function Purpose : Sending Network Requests with Full Compatibility with QT.
    * Params           : aListParams (List)
    * Author           : Mohannad AlAyash (mohannada...@gmail.com)
    * Output           : null

    * Supported Headers (You can also write your own):

        Integer Value  | Enum Constant              | Header String Equivalent
        ----------------------------------------------------------------------
        0              | ContentTypeHeader          | Content-Type
        1              | ContentLengthHeader        | Content-Length
        2              | LocationHeader             | Location
        3              | LastModifiedHeader         | Last-Modified
        4              | CookieHeader               | Cookie
        5              | SetCookieHeader            | Set-Cookie
        6              | ContentDispositionHeader   | Content-Disposition
        7              | UserAgentHeader            | User-Agent
        8              | ServerHeader               | Server

    * Note: Body must be a string or a list (which will be converted to a string).

    * Supported Request Methods:
        - GET
        - POST
        - PUT
        - UPDATE
        - DELETE
        - Custom Requests

    * Options (Keys for aListParams):
        - String :url            : The URL Link that you want to send the request to.
        - String :body           : The Body data as a String.
        - String :Method         : The Request Method (get, post, put, ...).
        - List   :Headers        : List of Required Headers ([:ContentTypeHeader="value"], ...).
        - String :callBack       : Function name to call when request is done. Accepts:
                                   - Three Params : (QNetworkAccessManager, nState, cResponse)
                                     (nState = 0 if there is no internet/error).
                                   - Two Params   : (nState, cResponse)
                                   - One Param    : (cResponse)
        - String :BeforeRedirect : Function name called before a redirect occurs.
        - String :AfterRedirect  : Function name called after a redirect finishes.
        - Number :RetByteArray   : 0 or 1. Set to 1 if you want the response as a QByteArray object 
                                   instead of a string.

    * Example Usage:

    QTDownload([
        :url     = cScriptUrl,
        :body    = cPayLoadData,
        :method  = 'POST',
        :Headers = [ [:ContentTypeHeader, "application/json"] ],
        :callBack = func nState, cRes {
            if isnull(cRes) or nState = 0
                oQML.root.setFormStateNetworkError()
                return 
            ok
            aRes = json2list(cRes)
            if aRes[:status] = 'success'
                oQml.root.setPDFURL(aRes['url'], aRes['aImages'])
            ok
        } 
    ])
*/

func QTDownload(aListParams)
    // --- Initialize Variables ---
    poWidget            = NULL // No Parent Needed
    cURL                = ''
    cRequestMethod      = ''
    aHeaders            = []
    aBody               = []
    cBody               = ''
    cCallBackFunc       = ''
    cBeforeRedirectFunc = ''
    cAfterRedirectFunc  = ''
    lRetByteArray       = 0

    // --- Extract Parameters ---
    if find(aListParams, :URL, 1)
        cURL = aListParams[:URL]
    ok

    if find(aListParams, :HEADERS, 1)
        aHeaders = aListParams[:HEADERS]
    ok

    if find(aListParams, :BODY, 1)
        if islist(aListParams[:BODY])
            aBody = aListParams[:BODY]
        else
            cBody = aListParams[:BODY]
        ok
    ok

    if find(aListParams, :CallBack, 1)
        cCallBackFunc = aListParams[:CallBack]
    ok

    if find(aListParams, :BeforeRedirect, 1)
        cBeforeRedirectFunc = aListParams[:BeforeRedirect]
    ok

    if find(aListParams, :AfterRedirect, 1)
        cAfterRedirectFunc = aListParams[:AfterRedirect]
    ok

    if find(aListParams, :Method, 1)
        cRequestMethod = lower(aListParams[:Method])
    ok

    if find(aListParams, :RetByteArray, 1)
        lRetByteArray = aListParams[:RetByteArray]
    ok

    // --- Create Network Request ---
    oUrl    = new QUrl(cURL)
    request = new QNetworkRequest(oUrl)

    // --- Setting the Headers ---
    if len(aHeaders)
        for header in aHeaders
            switch lower(header[1])
                on :ContentTypeHeader
                    request.setHeader(0, new qvariantstring(header[2]))
                on :ContentLengthHeader
                    request.setHeader(1, new qvariantstring(header[2]))
                on :LocationHeader
                    request.setHeader(2, new qvariantstring(header[2]))
                on :LastModifiedHeader
                    request.setHeader(3, new qvariantstring(header[2]))
                on :CookieHeader
                    request.setHeader(4, new qvariantstring(header[2]))
                on :SetCookieHeader
                    request.setHeader(5, new qvariantstring(header[2]))
                on :ContentDispositionHeader
                    request.setHeader(6, new qvariantstring(header[2]))
                on :UserAgentHeader
                    request.setHeader(7, new qvariantstring(header[2]))
                on :ServerHeader
                    request.setHeader(8, new qvariantstring(header[2]))
                other 
                    // Handle Custom Headers
                    request.setRawHeader( new qBytearray().append(header[1]), new qBytearray().append(header[2]) )
            off
        next 
    ok

    // --- Setting The Body ---
    if len(cBody) or len(aBody)
        oByteArrayBody = ''
        if cBody != ''
            oByteArrayBody = new qBytearray().append(cBody)
        else
            // Convert List Body to URL Encoded String
            cBody = ''
            for i=1 to len(aBody)
                if isstring(aBody[i])
                    cBody += aBody[i]
                but islist(aBody[i])
                    if len(aBody[i])=2
                        cBody += aBody[i][1] + '=' + aBody[i][2]
                    ok
                ok
                if i != len(aBody)
                    cBody += '&'
                ok
            next
            oByteArrayBody = new qBytearray().append(cBody)
        ok
    ok

    // --- Define Internal Response Handler ---
    cResponseHandellerfunc = func nManagerPointer, cFuncCallBack {
        oManager = new QNetworkAccessManager {
            pObject = nullptr()
            setPointer(pObject, nManagerPointer)
        }

        // Retrieve redirect functions stored in properties
        cBeforeRedirectFunc = oManager.Property(:cBeforeRedirectFunc).toString()
        cAfterRedirectFunc  = oManager.Property(:cAfterRedirectFunc).toString()

        reply = new QNetworkReply { pObject = oManager.getEventParameters()[1] }    
        nStatusCode = 0 + reply.attribute(0).toString()

        // --- Check for Redirect ---
        // Attribute 2 = QNetworkRequest::RedirectionTargetAttribute
        vRedirect = reply.attribute(2)

        // If it is a redirect (e.g., 302), follow it
        if not isnull(vRedirect) and vRedirect.toString() != ""
            cRedirectUrl = vRedirect.toString()

            // Create a request for the new URL
            oUrlRedirect    = new QUrl(cRedirectUrl)
            requestRedirect = new QNetworkRequest(oUrlRedirect)

            // Handle Before Redirect Callback
            if len(cBeforeRedirectFunc)
                call cBeforeRedirectFunc()
                oManager.setProperty_double(:isRedirectDone, 1)
            ok

            // Re-use manager for the redirect
            oManager.getvalue(requestRedirect)
            return 
        ok

        // Handle After Redirect Callback
        if 0 + oManager.property(:isRedirectDone).toString()
            call cAfterRedirectFunc()
        ok

        // --- Read Final Data ---
        if 0 + oManager.property(:lRetByteArray).toString()  
            cResult = reply.readall()
        else 
            cResult = reply.readall().data()
        ok

        cErrorCallingFunctionWithExtraNumberOfPatrams = "Error (R20)"

        // --- Execute User Callback ---
        // Attempts to call the function with decreasing number of parameters
        try 
            call cFuncCallBack(oManager, nStatusCode, cResult)
        catch
            if substr(cCatchError, cErrorCallingFunctionWithExtraNumberOfPatrams)
                try 
                    call cFuncCallBack(nStatusCode, cResult)
                catch
                    if substr(cCatchError, cErrorCallingFunctionWithExtraNumberOfPatrams)
                        call cFuncCallBack(cResult)
                    ok
                done
            ok
        done 
        oManager.deletelater()
    }

    // --- Setup Network Access Manager ---
    oNetworkAccessManager = new QNetworkAccessManager(poWidget) {
        // Sending The Pointer To the cResponseHandellerfunc Function via Event String
        setFinishedEvent(cResponseHandellerfunc + "("+ getpointer(oNetworkAccessManager.pObject)+',`'+cCallBackFunc+'`)' )

        // Storing context variables in properties for the handler to access
        setProperty_string(:cBeforeRedirectFunc, cBeforeRedirectFunc)
        setProperty_string(:cAfterRedirectFunc, cAfterRedirectFunc)
        setProperty_string(:lRetByteArray, ''+lRetByteArray)

        if cRequestMethod = ''
            cRequestMethod = 'get'
        ok

        switch cRequestMethod
            on 'get'
                getvalue(request)
            on 'post'
                Post(request, oByteArrayBody) 
            on 'delete'
                deleteResource(request)
            on 'update'
                putvalue(request, oByteArrayBody)
            other
                // Supporting Custom Request
                oBuffer = new QBuffer(pObject) {
                    setdata(oByteArrayBody)
                    open(1)
                }
                sendCustomRequest(request, new qbytearray().append(aListParams[:Method]), oBuffer )
        off
    }