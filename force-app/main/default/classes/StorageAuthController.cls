public with sharing class StorageAuthController {

   @AuraEnabled
public static void updateStorageSelection(String storageType){

    System.debug('### Selected: ' + storageType);

    Auth__c setting;

    // ALWAYS fetch using SOQL (NOT getOrgDefaults)
    List<Auth__c> listSetting = [
        SELECT Id, Box__c, Google_Drive__c, Dropbox__c, SharePoint__c
        FROM Auth__c
        WHERE SetupOwnerId = :UserInfo.getOrganizationId()
        LIMIT 1
    ];

    if(listSetting.isEmpty()){
        // Create new org-level record
        setting = new Auth__c();
        setting.SetupOwnerId = UserInfo.getOrganizationId();
    } else {
        setting = listSetting[0];
    }

    // Reset all
    setting.Box__c = false;
    setting.Google_Drive__c = false;
    setting.Dropbox__c = false;
    setting.SharePoint__c = false;

    // Set selected
    if(storageType == 'box'){
        setting.Box__c = true;
    } 
    else if(storageType == 'google'){
        setting.Google_Drive__c = true;
    } 
    else if(storageType == 'dropbox'){
        setting.Dropbox__c = true;
    } 
    else if(storageType == 'sharepoint'){
        setting.SharePoint__c = true;
    }

    // Save properly
    if(setting.Id == null){
        insert setting;
    } else {
        update setting;
    }

    System.debug('### UPDATED SETTING: ' + setting);
}


    @AuraEnabled(cacheable=true)
public static String getSelectedStorage(){

    List<Auth__c> listSetting = [
        SELECT Box__c, Google_Drive__c, Dropbox__c, SharePoint__c
        FROM Auth__c
        WHERE SetupOwnerId = :UserInfo.getOrganizationId()
        LIMIT 1
    ];

    if(listSetting.isEmpty()){
        return null;
    }

    Auth__c setting = listSetting[0];

    if(setting.Box__c) return 'box';
    if(setting.Google_Drive__c) return 'google';
    if(setting.Dropbox__c) return 'dropbox';
    if(setting.SharePoint__c) return 'sharepoint';

    return null;
}

}