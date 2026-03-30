public with sharing class UniversalCalloutService {
    public class CalloutRequest {
        @AuraEnabled public String connectorDeveloperName;
        @AuraEnabled public String endpointPath;
        @AuraEnabled public String method;
        @AuraEnabled public String requestBody;
    }

    public class CalloutResponseWrapper {
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String status;
        @AuraEnabled public String responseBody;
        @AuraEnabled public Boolean success;
    }

    @AuraEnabled
    public static CalloutResponseWrapper invokeConnector(CalloutRequest requestInput) {
        if (requestInput == null || String.isBlank(requestInput.connectorDeveloperName)) {
            throw new AuraHandledException('Connector developer name is required.');
        }

        ConnectorCredential__c connectorRecord = ConnectorIntegrationRepository.getUserOrSharedCredential(
            requestInput.connectorDeveloperName,
            UserInfo.getUserId()
        );
        if (connectorRecord == null) {
            throw new AuraHandledException('Connector record not found.');
        }
        if (String.isBlank(connectorRecord.Base_URL__c)) {
            throw new AuraHandledException('Base URL is missing.');
        }
        if (String.isBlank(connectorRecord.Username__c) || String.isBlank(connectorRecord.Password__c)) {
            throw new AuraHandledException('Username or password is missing.');
        }

        String endpoint = buildEndpoint(connectorRecord.Base_URL__c, requestInput.endpointPath);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(String.isBlank(requestInput.method) ? 'GET' : requestInput.method.trim().toUpperCase());
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', buildBasicHeader(connectorRecord.Username__c, connectorRecord.Password__c));

        if (!String.isBlank(requestInput.requestBody)) {
            validateRequestBody(requestInput.requestBody);
            request.setBody(requestInput.requestBody);
        }

        try {
            HttpResponse response = new Http().send(request);
            ConnectorIntegrationRepository.logCall(
                requestInput.connectorDeveloperName,
                request.getMethod(),
                endpoint,
                response.getStatusCode(),
                requestInput.requestBody,
                response.getBody(),
                response.getStatusCode() >= 200 && response.getStatusCode() < 300
            );
            CalloutResponseWrapper wrapper = new CalloutResponseWrapper();
            wrapper.statusCode = response.getStatusCode();
            wrapper.status = response.getStatus();
            wrapper.responseBody = response.getBody();
            wrapper.success = response.getStatusCode() >= 200 && response.getStatusCode() < 300;
            return wrapper;
        } catch (Exception exceptionValue) {
            ConnectorIntegrationRepository.logCall(
                requestInput.connectorDeveloperName,
                request.getMethod(),
                endpoint,
                0,
                requestInput.requestBody,
                exceptionValue.getMessage(),
                false
            );
            throw new AuraHandledException('Connector callout failed: ' + exceptionValue.getMessage());
        }
    }

    private static String buildEndpoint(String baseUrl, String endpointPath) {
        if (String.isBlank(endpointPath)) {
            return baseUrl;
        }
        if (endpointPath.startsWith('http://') || endpointPath.startsWith('https://')) {
            return endpointPath;
        }
        String normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        String normalizedPath = endpointPath.startsWith('/') ? endpointPath : '/' + endpointPath;
        return normalizedBase + normalizedPath;
    }

    private static String buildBasicHeader(String username, String password) {
        return 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
    }

    private static void validateRequestBody(String requestBody) {
        String trimmed = requestBody.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
            JSON.deserializeUntyped(trimmed);
        }
    }
}