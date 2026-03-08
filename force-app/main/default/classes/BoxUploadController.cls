public with sharing class BoxUploadController {

    /*
    ============================================================
    MAIN METHOD CALLED FROM LWC
    ============================================================
    This method receives:
    recordId   -> Salesforce record
    objectName -> Object API name (used as folder name)
    fileName   -> Uploaded file name
    base64Data -> File data from LWC
    ============================================================
    */

    @AuraEnabled
    public static String uploadFileToBox(String recordId,
                                         String objectName,
                                         String fileName,
                                         String base64Data) {

        System.debug('===== BOX UPLOAD START =====');
        System.debug('RecordId : ' + recordId);
        System.debug('ObjectName : ' + objectName);
        System.debug('FileName : ' + fileName);

        try{

            /* VALIDATIONS */

            if(String.isBlank(fileName)){
                throw new AuraHandledException('File name missing');
            }

            if(String.isBlank(base64Data)){
                throw new AuraHandledException('File data missing');
            }

            /* CONVERT BASE64 TO BLOB */

            Blob fileBlob = EncodingUtil.base64Decode(base64Data);

            System.debug('File Size (bytes) : ' + fileBlob.size());

            /* GET OR CREATE FOLDER */

            String folderId = getOrCreateFolder(objectName);

            System.debug('Folder Id : ' + folderId);

            /* UPLOAD FILE */

            uploadFile(folderId,fileName,fileBlob);

            System.debug('===== FILE UPLOADED SUCCESSFULLY =====');

            return 'File uploaded successfully to Box';

        }
        catch(Exception e){

            System.debug('BOX ERROR : ' + e.getMessage());

            throw new AuraHandledException(e.getMessage());
        }
    }


    /*
    ============================================================
    SEARCH FOLDER IN BOX
    ============================================================
    */
    public static String searchFolder(String folderName){

        System.debug('Searching Folder : ' + folderName);

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'callout:Box_API/2.0/search?query=' +
            EncodingUtil.urlEncode(folderName,'UTF-8') +
            '&type=folder'
        );

        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Search Folder Status : ' + res.getStatusCode());
        System.debug('Search Folder Response : ' + res.getBody());

        if(res.getStatusCode() != 200){
            return null;
        }

        Map<String,Object> result =
        (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        List<Object> entries =
        (List<Object>)result.get('entries');

        if(entries != null && entries.size() > 0){

            Map<String,Object> folder =
            (Map<String,Object>)entries[0];

            String folderId = (String)folder.get('id');

            System.debug('Folder Found Id : ' + folderId);

            return folderId;
        }

        System.debug('Folder Not Found');

        return null;
    }


    /*
    ============================================================
    CREATE FOLDER IN BOX
    ============================================================
    */

    public static String createFolder(String folderName){

        System.debug('Creating Folder : ' + folderName);

        HttpRequest req = new HttpRequest();

        req.setEndpoint('callout:Box_API/2.0/folders');

        req.setMethod('POST');

        req.setHeader('Content-Type','application/json');

        req.setBody(
            '{"name":"'+folderName+'","parent":{"id":"0"}}'
        );

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Create Folder Status : ' + res.getStatusCode());
        System.debug('Create Folder Response : ' + res.getBody());

        if(res.getStatusCode() != 201){
            throw new AuraHandledException(res.getBody());
        }

        Map<String,Object> result =
        (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        String folderId = (String)result.get('id');

        System.debug('New Folder Id : ' + folderId);

        return folderId;
    }


    /*
    ============================================================
    GET EXISTING FOLDER OR CREATE NEW ONE
    ============================================================
    */

    public static String getOrCreateFolder(String folderName){

        System.debug('GetOrCreateFolder : ' + folderName);

        String folderId = searchFolder(folderName);

        if(folderId != null){
            return folderId;
        }

        return createFolder(folderName);
    }



    /*
    ============================================================
    FILE UPLOAD TO BOX
    ============================================================
    */

    public static void uploadFile(String folderId,
                                  String fileName,
                                  Blob fileBlob){

        System.debug('Uploading File To Box');

        String boundary = 'boundary_' + String.valueOf(Crypto.getRandomInteger());

        System.debug('Boundary : ' + boundary);

        Blob finalBody = BoxMultipartHelper.buildMultipartBody(
            folderId,
            fileName,
            fileBlob,
            boundary
        );

        HttpRequest req = new HttpRequest();

        req.setEndpoint('callout:Box_Upload/api/2.0/files/content');

        req.setMethod('POST');

        req.setHeader(
            'Content-Type',
            'multipart/form-data; boundary=' + boundary
        );

        req.setHeader('Accept','application/json');

        req.setBodyAsBlob(finalBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('BOX STATUS : ' + res.getStatusCode());
        System.debug('BOX RESPONSE : ' + res.getBody());

        if(res.getStatusCode() >= 300){

            Map<String,Object> error =
            (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

            if(error.containsKey('message')){
                throw new AuraHandledException((String)error.get('message'));
            }

            throw new AuraHandledException('Box upload failed');
        }
    }
}