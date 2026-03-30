public without sharing class OAuthService {

    public class ConnectorSetupView {
        @AuraEnabled public String developerName;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean hasSharedCredential;
        @AuraEnabled public Boolean isConnected;
        @AuraEnabled public Datetime expiry;
        @AuraEnabled public String status;
    }

    public class TokenResponse {
        public String accessToken;
        public String refreshToken;
        public Integer expiresInSeconds;
        public String tokenType;
    }

    // 🔥 SINGLE SOURCE OF TRUTH
    public static final String CALLBACK_URL =
        'https://orgfarm-37f0d74bd8-dev-ed.develop.my.salesforce-sites.com/services/apexrest/oauth/callback';

    // ================= UI =================
    @AuraEnabled(cacheable=true)
    public static List<ConnectorSetupView> getConnectorSetupViews() {

        Map<String, ConnectorCredential__c> userMap = new Map<String, ConnectorCredential__c>();
        for (ConnectorCredential__c row :
            [SELECT Id, Connector_Name__c, Expiry__c
             FROM ConnectorCredential__c
             WHERE User__c = :UserInfo.getUserId()]) {
            userMap.put(row.Connector_Name__c, row);
        }

        Map<String, ConnectorCredential__c> sharedMap = new Map<String, ConnectorCredential__c>();
        for (ConnectorCredential__c row :
            [SELECT Id, Connector_Name__c
             FROM ConnectorCredential__c
             WHERE User__c = null]) {
            sharedMap.put(row.Connector_Name__c, row);
        }

        List<ConnectorSetupView> results = new List<ConnectorSetupView>();

        for (ConnectorConfig__mdt config :
            ConnectorIntegrationRepository.getAllConfigs()) {

            ConnectorSetupView row = new ConnectorSetupView();
            row.developerName = config.DeveloperName;
            row.label = config.MasterLabel;
            row.hasSharedCredential = sharedMap.containsKey(config.DeveloperName);
            row.isConnected = userMap.containsKey(config.DeveloperName);
            row.expiry = row.isConnected ? userMap.get(config.DeveloperName).Expiry__c : null;
            row.status = row.isConnected ? 'Connected' : 'Not Connected';

            results.add(row);
        }

        return results;
    }

    // ================= AUTH URL =================
    @AuraEnabled
    public static String getAuthorizationUrl(String connectorDeveloperName) {

        ConnectorConfig__mdt config = ConnectorIntegrationRepository.getConfig(connectorDeveloperName);
        ConnectorCredential__c shared = ConnectorIntegrationRepository.getSharedCredential(connectorDeveloperName);

        if (shared == null || String.isBlank(shared.Client_Id__c) || String.isBlank(shared.Client_Secret__c)) {
            throw new AuraHandledException('Admin must configure Client ID and Client Secret first.');
        }

        String state = EncodingUtil.base64Encode(
            Blob.valueOf(JSON.serialize(new Map<String, String>{
                'connector' => connectorDeveloperName,
                'userId' => UserInfo.getUserId()
            }))
        );

        List<String> queryParts = new List<String>{
            'response_type=code',
            'client_id=' + EncodingUtil.urlEncode(shared.Client_Id__c, 'UTF-8'),
            'redirect_uri=' + EncodingUtil.urlEncode(CALLBACK_URL, 'UTF-8'),
            'state=' + EncodingUtil.urlEncode(state, 'UTF-8')
        };

        if (!String.isBlank(config.Scope__c)) {
            queryParts.add('scope=' + EncodingUtil.urlEncode(config.Scope__c, 'UTF-8'));
        }

        if (connectorDeveloperName == 'GoogleDrive') {
            queryParts.add('access_type=offline');
            queryParts.add('prompt=consent');
        } else if (connectorDeveloperName == 'Dropbox') {
            queryParts.add('token_access_type=offline');
        }

        String separator = config.Auth_URL__c.contains('?') ? '&' : '?';

        return config.Auth_URL__c + separator + String.join(queryParts, '&');
    }

    // ================= TOKEN EXCHANGE =================
    public static TokenResponse exchangeAuthorizationCode(String connector, String code) {

        ConnectorConfig__mdt config = ConnectorIntegrationRepository.getConfig(connector);
        ConnectorCredential__c shared = ConnectorIntegrationRepository.getSharedCredential(connector);

        if (shared == null) {
            throw new AuraHandledException('Shared credentials missing for connector: ' + connector);
        }

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(config.Token_URL__c);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        req.setBody(buildFormEncodedBody(new Map<String, String>{
            'grant_type' => 'authorization_code',
            'code' => code,
            'client_id' => shared.Client_Id__c,
            'client_secret' => shared.Client_Secret__c,
            'redirect_uri' => CALLBACK_URL
        }));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new AuraHandledException('Token exchange failed: ' + res.getBody());
        }

        return parseTokenResponse(res.getBody());
    }

    // ================= CALLBACK PROCESS =================
    public static void handleOAuthCallback(String connector, String code, Id userId) {

        TokenResponse token = exchangeAuthorizationCode(connector, code);

        ConnectorCredential__c record =
            ConnectorIntegrationRepository.getUserCredential(connector, userId);

        if (record == null) {
            record = new ConnectorCredential__c(
                Connector_Name__c = connector,
                User__c = userId
            );
        }

        record.Access_Token_Long__c = token.accessToken;
record.Refresh_Token_Long__c = token.refreshToken;
        record.Expiry__c = token.expiresInSeconds == null
            ? null
            : System.now().addSeconds(token.expiresInSeconds);

        upsert record;
    }

    private static String buildFormEncodedBody(Map<String, String> params) {
        List<String> parts = new List<String>();
        for (String key : params.keySet()) {
            parts.add(
                EncodingUtil.urlEncode(key, 'UTF-8') + '=' +
                EncodingUtil.urlEncode(params.get(key), 'UTF-8')
            );
        }
        return String.join(parts, '&');
    }

    @TestVisible
    static TokenResponse parseTokenResponse(String body) {

        Map<String, Object> payload =
            ConnectorIntegrationRepository.parseJsonObject(body, 'Token response');

        TokenResponse t = new TokenResponse();
        t.accessToken = (String) payload.get('access_token');
        t.refreshToken = (String) payload.get('refresh_token');
        t.tokenType = (String) payload.get('token_type');

        if (payload.get('expires_in') != null) {
            t.expiresInSeconds = Integer.valueOf(String.valueOf(payload.get('expires_in')));
        }

        return t;
    }
}