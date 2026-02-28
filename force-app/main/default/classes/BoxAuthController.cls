public with sharing class BoxAuthController {

    private static final String CLIENT_ID = '3eq61yj0mvth91ux23ls8478deeby6td';

    private static final String REDIRECT_URI =
    'https://orgfarm-37f0d74bd8-dev-ed--c.visualforce.com/apex/BoxAuthCallback';

    @AuraEnabled
    public static String getBoxLoginUrl(){

        String authUrl =
        'https://account.box.com/api/oauth2/authorize'
        + '?response_type=code'
        + '&client_id=' + CLIENT_ID
        + '&redirect_uri=' + EncodingUtil.urlEncode(REDIRECT_URI,'UTF-8');

        return authUrl;
    }

}