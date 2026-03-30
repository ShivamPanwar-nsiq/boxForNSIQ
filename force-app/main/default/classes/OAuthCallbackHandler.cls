@RestResource(urlMapping='/oauth/callback/*')
global without sharing class OAuthCallbackHandler {

    @HttpGet
    global static void handleCallback() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String code = req.params.get('code');
            String state = req.params.get('state');

            if (String.isBlank(code) || String.isBlank(state)) {
                sendHtml(res, 400, 'Missing code or state');
                return;
            }

            // ✅ FIX: NO urlDecode
            String decoded = EncodingUtil.base64Decode(state).toString();

            Map<String, Object> stateMap =
                (Map<String, Object>) JSON.deserializeUntyped(decoded);

            String connector = (String) stateMap.get('connector');
            Id userId = (Id) stateMap.get('userId');

            // Process OAuth
            OAuthService.handleOAuthCallback(connector, code, userId);

            // ✅ SUCCESS PAGE (NO REDIRECT ISSUE)
            sendHtml(res, 200,
                '<h2>✅ Connected Successfully</h2>' +
                '<p>You can close this window.</p>' +
                '<script>if(window.opener){window.opener.location.reload();}window.close();</script>'
            );

        } catch (Exception e) {

            sendHtml(res, 500,
                '<h2>❌ OAuth Failed</h2>' +
                '<p>' + e.getMessage() + '</p>'
            );
        }
    }

    private static void sendHtml(RestResponse res, Integer status, String message) {
        res.statusCode = status;
        res.addHeader('Content-Type', 'text/html; charset=UTF-8');

        String html =
            '<html><body style="font-family:sans-serif;text-align:center;margin-top:50px;">' +
            message +
            '</body></html>';

        res.responseBody = Blob.valueOf(html);
    }
}