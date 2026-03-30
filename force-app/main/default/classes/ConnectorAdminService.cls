public with sharing class ConnectorAdminService {
    public class SharedCredentialInput {
        @AuraEnabled public String connectorDeveloperName { get; set; }
        @AuraEnabled public String clientId { get; set; }
        @AuraEnabled public String clientSecret { get; set; }
    }

    public class ConnectorConfigView {
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String authUrl { get; set; }
        @AuraEnabled public String tokenUrl { get; set; }
        @AuraEnabled public String scope { get; set; }
        @AuraEnabled public Boolean hasSharedCredential { get; set; }
        @AuraEnabled public String sharedClientId { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<ConnectorConfigView> getConnectorConfigs() {
        Map<String, ConnectorCredential__c> sharedCredentialsByConnector = new Map<String, ConnectorCredential__c>();
        for (ConnectorCredential__c row : [
            SELECT Id, Connector_Name__c, Client_Id__c
            FROM ConnectorCredential__c
            WHERE User__c = null
        ]) {
            sharedCredentialsByConnector.put(row.Connector_Name__c, row);
        }

        List<ConnectorConfigView> results = new List<ConnectorConfigView>();
        for (ConnectorConfig__mdt configRecord : ConnectorIntegrationRepository.getAllConfigs()) {
            ConnectorConfigView viewModel = new ConnectorConfigView();
            viewModel.developerName = configRecord.DeveloperName;
            viewModel.label = configRecord.MasterLabel;
            viewModel.authUrl = configRecord.Auth_URL__c;
            viewModel.tokenUrl = configRecord.Token_URL__c;
            viewModel.scope = configRecord.Scope__c;
            viewModel.hasSharedCredential = sharedCredentialsByConnector.containsKey(configRecord.DeveloperName);
            viewModel.sharedClientId = viewModel.hasSharedCredential ? sharedCredentialsByConnector.get(configRecord.DeveloperName).Client_Id__c : null;
            results.add(viewModel);
        }
        return results;
    }

    @AuraEnabled
    public static Id saveSharedCredential(SharedCredentialInput input) {
        system.debug('input - - -:'+ input);
     
        if (String.isBlank(input.clientId)) {
            throw new AuraHandledException('Client ID is required.');
        }
        if (String.isBlank(input.clientSecret)) {
            throw new AuraHandledException('Client Secret is required.');
        }

        ConnectorCredential__c recordToSave = ConnectorIntegrationRepository.getSharedCredential(input.connectorDeveloperName);
        if (recordToSave == null) {
            recordToSave = new ConnectorCredential__c(Connector_Name__c = input.connectorDeveloperName);
        }

        recordToSave.Client_Id__c = input.clientId.trim();
        recordToSave.Client_Secret__c = input.clientSecret;
        upsert recordToSave;
        return recordToSave.Id;
    }
}