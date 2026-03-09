public with sharing class BoxUploadController {

    // RESPONSE WRAPPER
    public class UploadResponse{
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
    }

    @AuraEnabled
    public static UploadResponse uploadFileToBox(String recordId,
                                                 String objectName,
                                                 String fileName,
                                                 String base64Data){

        System.debug('===== BOX UPLOAD START =====');
        System.debug('RecordId : ' + recordId);
        System.debug('ObjectName : ' + objectName);
        System.debug('FileName : ' + fileName);

        UploadResponse response = new UploadResponse();

        try{

            if(String.isBlank(fileName)){
                response.success = false;
                response.message = 'File name missing';
                return response;
            }

            if(String.isBlank(base64Data)){
                response.success = false;
                response.message = 'File data missing for ' + fileName;
                return response;
            }

            Blob fileBlob = EncodingUtil.base64Decode(base64Data);

            System.debug('File Size : ' + fileBlob.size());

            String folderId = getOrCreateFolder(objectName);

            System.debug('Folder Id : ' + folderId);

            uploadFile(folderId,fileName,fileBlob);

            response.success = true;
            response.message = 'File "' + fileName + '" uploaded successfully to Box';

        }
        catch(Exception e){

            System.debug('BOX ERROR : ' + e.getMessage());

            String message = e.getMessage();

            if(String.isBlank(message)){
                message = 'Unknown Box upload error';
            }

            response.success = false;
            response.message = 'Error uploading "' + fileName + '" : ' + message;
        }

        return response;
    }

    // SEARCH FOLDER
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

        return null;
    }

    // CREATE FOLDER
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

    // GET OR CREATE FOLDER
    public static String getOrCreateFolder(String folderName){

        System.debug('GetOrCreateFolder : ' + folderName);

        String folderId = searchFolder(folderName);

        if(folderId != null){
            return folderId;
        }

        return createFolder(folderName);
    }

    // FILE UPLOAD
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

            System.debug('BOX ERROR BODY : ' + res.getBody());

            String errorMessage = 'Box upload failed';

            try{

                Map<String,Object> error =
                (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

                if(error.containsKey('message')){
                    errorMessage = (String)error.get('message');
                }

            }catch(Exception ex){
                System.debug('Error parsing Box response');
            }

            System.debug('BOX ERROR MESSAGE : ' + errorMessage);

            throw new AuraHandledException(errorMessage);
        }
    }
}