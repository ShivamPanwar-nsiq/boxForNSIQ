public with sharing class BoxAuthController {

    @AuraEnabled
    public static String getBoxLoginUrl(){

        BoxSetting__c boxSetting = BoxSetting__c.getOrgDefaults();

        String authUrl =
            boxSetting.Auth_Url__c
            + '?response_type=code'
            + '&client_id=' + boxSetting.Client_Id__c
            + '&redirect_uri=' + EncodingUtil.urlEncode(boxSetting.Redirect_Url__c,'UTF-8');

        return authUrl;
    }


    // ⭐ ADD THIS METHOD HERE
    @AuraEnabled(cacheable=true)
    public static Boolean isBoxAuthenticated(){

        BoxSetting__c setting = BoxSetting__c.getOrgDefaults();

        if(setting == null){
            return false;
        }

        if(String.isBlank(setting.Access_Token__c)){
            return false;
        }

        if(setting.Token_Expiry__c == null){
            return false;
        }

        // If expired token → refresh will happen automatically
        if(setting.Token_Expiry__c <= System.now()){
            return true;
        }

        return true;
    }


    @AuraEnabled
    public static String exchangeCodeForToken(String authCode){

        try{

            BoxSetting__c setting = BoxSetting__c.getOrgDefaults();

            Http http = new Http();
            HttpRequest req = new HttpRequest();

            req.setEndpoint('https://api.box.com/oauth2/token');
            req.setMethod('POST');

            req.setHeader('Content-Type','application/x-www-form-urlencoded');

            req.setBody(
                'grant_type=authorization_code'
                + '&code=' + authCode
                + '&client_id=' + setting.Client_Id__c
                + '&client_secret=' + setting.Client_Secret__c
                + '&redirect_uri=' + EncodingUtil.urlEncode(setting.Redirect_Url__c,'UTF-8')
            );

            HttpResponse res = http.send(req);

            if(res.getStatusCode() != 200){
                throw new AuraHandledException('Box authentication failed: ' + res.getBody());
            }

            Map<String,Object> result =
                (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

            String accessToken = (String)result.get('access_token');
            String refreshToken = (String)result.get('refresh_token');
            Integer expiresIn = (Integer)result.get('expires_in');

            setting.Access_Token__c = accessToken;
            setting.Refresh_Token__c = refreshToken;
            setting.Token_Expiry__c = System.now().addSeconds(expiresIn);

            upsert setting;

            return 'SUCCESS';

        }catch(Exception e){

            throw new AuraHandledException('Authentication Error: ' + e.getMessage());

        }
    }


    public static String getValidAccessToken(){

        BoxSetting__c setting = BoxSetting__c.getOrgDefaults();

        if(setting.Token_Expiry__c == null || setting.Token_Expiry__c <= System.now()){
            return refreshAccessToken();
        }

        return setting.Access_Token__c;
    }


    public static String refreshAccessToken(){

        try{

            BoxSetting__c setting = BoxSetting__c.getOrgDefaults();

            Http http = new Http();
            HttpRequest req = new HttpRequest();

            req.setEndpoint('https://api.box.com/oauth2/token');
            req.setMethod('POST');

            req.setHeader('Content-Type','application/x-www-form-urlencoded');

            req.setBody(
                'grant_type=refresh_token'
                + '&refresh_token=' + setting.Refresh_Token__c
                + '&client_id=' + setting.Client_Id__c
                + '&client_secret=' + setting.Client_Secret__c
            );

            HttpResponse res = http.send(req);

            if(res.getStatusCode() != 200){
                throw new AuraHandledException('Token refresh failed: ' + res.getBody());
            }

            Map<String,Object> result =
                (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

            String accessToken = (String)result.get('access_token');
            String refreshToken = (String)result.get('refresh_token');
            Integer expiresIn = (Integer)result.get('expires_in');

            setting.Access_Token__c = accessToken;
            setting.Refresh_Token__c = refreshToken;
            setting.Token_Expiry__c = System.now().addSeconds(expiresIn);

            upsert setting;

            return accessToken;

        }catch(Exception e){

            throw new AuraHandledException('Refresh Token Error: ' + e.getMessage());

        }
    }

}