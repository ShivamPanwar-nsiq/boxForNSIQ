public with sharing class StorageAuthController {

    @AuraEnabled
    public static void updateStorageSelection(String storageType){

        Auth__c setting = Auth__c.getOrgDefaults();

        if(setting == null){
            setting = new Auth__c();
            setting.SetupOwnerId = UserInfo.getOrganizationId();
        }

        // Reset all connectors
        setting.Box__c = false;
        setting.Google_Drive__c = false;
        setting.Dropbox__c = false;
        setting.SharePoint__c = false;

        // Enable selected connector
        if(storageType == 'box'){
            setting.Box__c = true;
        }

        if(storageType == 'google'){
            setting.Google_Drive__c = true;
        }

        if(storageType == 'dropbox'){
            setting.Dropbox__c = true;
        }

        if(storageType == 'sharepoint'){
            setting.SharePoint__c = true;
        }

        upsert setting;
    }


    @AuraEnabled(cacheable=true)
    public static String getSelectedStorage(){

        Auth__c setting = Auth__c.getOrgDefaults();

        if(setting == null){
            return null;
        }

        if(setting.Box__c){
            return 'box';
        }

        if(setting.Google_Drive__c){
            return 'google';
        }

        if(setting.Dropbox__c){
            return 'dropbox';
        }

        if(setting.SharePoint__c){
            return 'sharepoint';
        }

        return null;
    }

}