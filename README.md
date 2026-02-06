# Qt Download Function For Ring Programming Language
## install :
    ringpm install qtdownload from mohannad-aldulaimi

# Function Info : 
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

## Author : Mohannad Alayash (mohannadazazalayash@gmail.com)