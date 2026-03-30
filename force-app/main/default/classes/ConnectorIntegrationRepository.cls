public inherited sharing class ConnectorIntegrationRepository {
    @TestVisible
    static Map<String, ConnectorConfig__mdt> configOverridesByName = new Map<String, ConnectorConfig__mdt>();

    @TestVisible
    static Map<String, ConnectorCredential__c> credentialOverridesByKey = new Map<String, ConnectorCredential__c>();

    public static ConnectorConfig__mdt getConfig(String connectorDeveloperName) {
        if (configOverridesByName.containsKey(connectorDeveloperName)) {
            return configOverridesByName.get(connectorDeveloperName);
        }

        List<ConnectorConfig__mdt> records = [
            SELECT DeveloperName, MasterLabel, Base_URL__c, Auth_Type__c, Auth_URL__c, Token_URL__c, Scope__c, Default_Headers__c
            FROM ConnectorConfig__mdt
            WHERE DeveloperName = :connectorDeveloperName
            LIMIT 1
        ];
        if (records.isEmpty()) {
            throw new AuraHandledException('Connector configuration not found: ' + connectorDeveloperName);
        }
        return records[0];
    }

    public static List<ConnectorConfig__mdt> getAllConfigs() {
        if (!configOverridesByName.isEmpty()) {
            return new List<ConnectorConfig__mdt>(configOverridesByName.values());
        }

        return [
            SELECT DeveloperName, MasterLabel, Base_URL__c, Auth_Type__c, Auth_URL__c, Token_URL__c, Scope__c, Default_Headers__c
            FROM ConnectorConfig__mdt
            ORDER BY MasterLabel
        ];
    }

    public static ConnectorCredential__c getSharedCredential(String connectorDeveloperName) {
        return getCredentialInternal(connectorDeveloperName, null);
    }

    public static ConnectorCredential__c getUserCredential(String connectorDeveloperName, Id userId) {
        return getCredentialInternal(connectorDeveloperName, userId);
    }

    public static ConnectorCredential__c getUserOrSharedCredential(String connectorDeveloperName, Id userId) {
        ConnectorCredential__c userCredential = getCredentialInternal(connectorDeveloperName, userId);
        return userCredential != null ? userCredential : getCredentialInternal(connectorDeveloperName, null);
    }

    private static ConnectorCredential__c getCredentialInternal(String connectorDeveloperName, Id userId) {
        String overrideKey = buildCredentialKey(connectorDeveloperName, userId);
        if (credentialOverridesByKey.containsKey(overrideKey)) {
            return credentialOverridesByKey.get(overrideKey);
        }

        List<ConnectorCredential__c> rows;
        if (userId == null) {
            rows = [
                SELECT Id, Name, Connector_Name__c, Connector_Label__c, Base_URL__c, User__c, Access_Token__c, Refresh_Token__c,
                    API_Key__c, Username__c, Password__c, Expiry__c, Client_Id__c, Client_Secret__c
                FROM ConnectorCredential__c
                WHERE Connector_Name__c = :connectorDeveloperName AND User__c = null
                LIMIT 1
            ];
        } else {
            rows = [
                SELECT Id, Name, Connector_Name__c, Connector_Label__c, Base_URL__c, User__c, Access_Token__c, Refresh_Token__c,
                    API_Key__c, Username__c, Password__c, Expiry__c, Client_Id__c, Client_Secret__c
                FROM ConnectorCredential__c
                WHERE Connector_Name__c = :connectorDeveloperName AND User__c = :userId
                LIMIT 1
            ];
        }
        return rows.isEmpty() ? null : rows[0];
    }

    public static Map<String, Object> parseJsonObject(String rawJson, String fieldName) {
        if (String.isBlank(rawJson)) {
            return new Map<String, Object>();
        }
        Object parsed = JSON.deserializeUntyped(rawJson);
        if (!(parsed instanceof Map<String, Object>)) {
            throw new AuraHandledException(fieldName + ' must be a JSON object.');
        }
        return (Map<String, Object>) parsed;
    }

    public static String buildCredentialKey(String connectorDeveloperName, Id userId) {
        return connectorDeveloperName + ':' + String.valueOf(userId);
    }

    public static void logCall(String connectorName, String method, String endpoint, Integer statusCode, String requestBody, String responseBody, Boolean success) {
        try {
            insert new API_Log__c(
                Connector_Name__c = connectorName,
                Request_Method__c = method,
                Endpoint__c = endpoint,
                Status_Code__c = statusCode,
                Request_Body__c = requestBody,
                Response_Body__c = responseBody,
                Success__c = success,
                Executed_By__c = UserInfo.getUserId()
            );
        } catch (Exception ignored) {
        }
    }
}