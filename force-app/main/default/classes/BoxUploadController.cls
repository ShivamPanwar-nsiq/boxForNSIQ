public with sharing class BoxUploadController {

    @AuraEnabled
    public static String uploadFileToBox(String recordId,
                                         String objectName,
                                         String fileName,
                                         String base64Data) {

        try {

            Blob fileBlob = EncodingUtil.base64Decode(base64Data);

            String folderId = getOrCreateFolder(objectName);

            uploadFile(folderId, fileName, fileBlob);

            return 'SUCCESS';

        } catch (Exception e) {

            System.debug('BOX ERROR: ' + e.getMessage());

            throw new AuraHandledException('Box Upload Failed : ' + e.getMessage());
        }
    }

    public static String getOrCreateFolder(String folderName) {

        String folderId = searchFolder(folderName);

        if(folderId != null){
            return folderId;
        }

        return createFolder(folderName);
    }

    public static String searchFolder(String folderName) {

        BoxSetting__c setting = BoxSetting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'https://api.box.com/2.0/search?query=' +
            EncodingUtil.urlEncode(folderName,'UTF-8') +
            '&type=folder'
        );

        req.setMethod('GET');

        req.setHeader('Authorization','Bearer ' + setting.Access_Token__c);

        Http http = new Http();

        HttpResponse res = http.send(req);

        System.debug('BOX SEARCH RESPONSE: ' + res.getBody());

        if(res.getStatusCode() != 200){
            return null;
        }

        Map<String,Object> result =
        (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        List<Object> entries = (List<Object>)result.get('entries');

        if(entries != null && entries.size() > 0){

            Map<String,Object> folder =
            (Map<String,Object>)entries[0];

            return (String)folder.get('id');
        }

        return null;
    }

    public static String createFolder(String folderName) {

        BoxSetting__c setting = BoxSetting__c.getOrgDefaults();

        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://api.box.com/2.0/folders');

        req.setMethod('POST');

        req.setHeader('Authorization','Bearer ' + setting.Access_Token__c);

        req.setHeader('Content-Type','application/json');

        req.setBody(
            '{"name":"' + folderName + '","parent":{"id":"0"}}'
        );

        Http http = new Http();

        HttpResponse res = http.send(req);

        System.debug('BOX CREATE RESPONSE: ' + res.getBody());

        if(res.getStatusCode() != 201){
            throw new AuraHandledException(res.getBody());
        }

        Map<String,Object> result =
        (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        return (String)result.get('id');
    }

    public static void uploadFile(String folderId,String fileName,Blob fileBlob) {

        BoxSetting__c setting = BoxSetting__c.getOrgDefaults();

        String boundary = '1ff13444ed8140c7a32fc4e6451aa76d';

        Blob body = BoxMultipartHelper.buildMultipartBody(
            folderId,
            fileName,
            fileBlob,
            boundary
        );

        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://upload.box.com/api/2.0/files/content');

        req.setMethod('POST');

        req.setHeader('Authorization','Bearer ' + setting.Access_Token__c);

        req.setHeader(
            'Content-Type',
            'multipart/form-data; boundary=' + boundary
        );

        req.setBodyAsBlob(body);

        Http http = new Http();

        HttpResponse res = http.send(req);

        System.debug('BOX STATUS: ' + res.getStatusCode());
        System.debug('BOX RESPONSE: ' + res.getBody());

        if(res.getStatusCode() >= 300){
            throw new AuraHandledException(res.getBody());
        }
    }
}