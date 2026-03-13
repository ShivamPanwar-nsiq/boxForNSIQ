public with sharing class StorageAuthController {

    @AuraEnabled
    public static void updateStorageSelection(String storageType){

        Auth__c setting = Auth__c.getOrgDefaults();

        if(setting == null){

            setting = new Auth__c();
            setting.SetupOwnerId = UserInfo.getOrganizationId();

        }

        setting.Box__c = (storageType == 'box');
        setting.Google_Drive__c = (storageType == 'google');
        setting.Dropbox__c = (storageType == 'dropbox');

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

        return null;
    }

}