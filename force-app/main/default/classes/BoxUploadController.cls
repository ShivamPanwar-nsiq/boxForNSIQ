public with sharing class BoxUploadController {

    public class UploadResponse{
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
    } 

    @AuraEnabled
    public static UploadResponse uploadFileToBox(String recordId,
                                                 String objectName,
                                                 String fileName,
                                                 String base64Data,
                                                 Boolean overwrite){

        UploadResponse response = new UploadResponse();

        try{

            if(String.isBlank(fileName)){
                response.success = false;
                response.message = 'File name missing';
                return response;
            }

            Blob fileBlob = EncodingUtil.base64Decode(base64Data);

            String folderId = getOrCreateFolder(objectName);

            if(folderId == null){
                response.success = false;
                response.message = 'Unable to find or create folder';
                return response;
            }

            String existingFileId = getExistingFileId(folderId,fileName);

            if(existingFileId != null && !overwrite){
                response.success = false;
                response.message = 'File already exists';
                return response;
            }

            String result;

            if(existingFileId != null && overwrite){
                result = updateFile(existingFileId,fileName,fileBlob);
            }else{
                result = uploadFile(folderId,fileName,fileBlob);
            }

            if(result == 'SUCCESS'){
                response.success = true;
                response.message = fileName + ' uploaded successfully';
            }else{
                response.success = false;
                response.message = result;
            }

        }
        catch(Exception e){
            response.success = false;
            response.message = e.getMessage();
        }

        return response;
    }

    // SEARCH FOLDER
    public static String searchFolder(String folderName){

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'callout:Box_API/2.0/search?query=' +
            EncodingUtil.urlEncode(folderName,'UTF-8') +
            '&type=folder'
        );

        req.setMethod('GET');
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Search Folder Response: ' + res.getBody());

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

            return (String)folder.get('id');
        }

        return null;
    }

    // CREATE FOLDER
    public static String createFolder(String folderName){

        HttpRequest req = new HttpRequest();

        req.setEndpoint('callout:Box_API/2.0/folders');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setTimeout(120000);

        req.setBody(
            '{"name":"'+folderName+'","parent":{"id":"0"}}'
        );

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Create Folder Response: ' + res.getBody());

        // SUCCESS
        if(res.getStatusCode() == 201){

            Map<String,Object> result =
            (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

            return (String)result.get('id');
        }

        // FOLDER ALREADY EXISTS
        if(res.getStatusCode() == 409){

            Map<String,Object> result =
            (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

            Map<String,Object> context =
            (Map<String,Object>)result.get('context_info');

            List<Object> conflicts =
            (List<Object>)context.get('conflicts');

            if(conflicts != null && conflicts.size() > 0){

                Map<String,Object> folder =
                (Map<String,Object>)conflicts[0];

                return (String)folder.get('id');
            }
        }

        return null;
    }

    // GET OR CREATE FOLDER
    public static String getOrCreateFolder(String folderName){

        String folderId = searchFolder(folderName);

        if(folderId != null){
            return folderId;
        }

        return createFolder(folderName);
    }

    // FIND EXISTING FILE
    public static String getExistingFileId(String folderId,String fileName){

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'callout:Box_API/2.0/folders/' + folderId + '/items'
        );

        req.setMethod('GET');
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200){
            return null;
        }

        Map<String,Object> result =
        (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        List<Object> entries =
        (List<Object>)result.get('entries');

        for(Object obj : entries){

            Map<String,Object> file =
            (Map<String,Object>)obj;

            if((String)file.get('name') == fileName){
                return (String)file.get('id');
            }
        }

        return null;
    }

    // UPLOAD FILE
    public static String uploadFile(String folderId,
                                    String fileName,
                                    Blob fileBlob){

        String boundary = 'boundary_' + String.valueOf(Crypto.getRandomInteger());

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

        req.setBodyAsBlob(finalBody);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Upload Response: ' + res.getBody());

        if(res.getStatusCode() >= 300){
            return 'Upload failed: ' + res.getBody();
        }

        return 'SUCCESS';
    }

    // OVERWRITE FILE
    public static String updateFile(String fileId,
                                    String fileName,
                                    Blob fileBlob){

        String boundary = 'boundary_' + String.valueOf(Crypto.getRandomInteger());

        Blob finalBody = BoxMultipartHelper.buildMultipartBody(
            null,
            fileName,
            fileBlob,
            boundary
        );

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'callout:Box_Upload/api/2.0/files/' + fileId + '/content'
        );

        req.setMethod('POST');

        req.setHeader(
            'Content-Type',
            'multipart/form-data; boundary=' + boundary
        );

        req.setBodyAsBlob(finalBody);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Overwrite Response: ' + res.getBody());

        if(res.getStatusCode() >= 300){
            return 'Overwrite failed: ' + res.getBody();
        }

        return 'SUCCESS';
    }
}