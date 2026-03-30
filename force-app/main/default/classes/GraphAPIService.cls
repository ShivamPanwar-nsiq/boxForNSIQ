/**
 * @description GraphAPIService handles interactions with Microsoft Graph API
 * for SharePoint sites, drives, folders, and files.
 */
public with sharing class GraphAPIService { // NOPMD:CyclomaticComplexity

    /**
     * @description Fetches all SharePoint sites available in the connected tenant.
     * @return A FromJSON object containing metadata of SharePoint sites including paging info.
     */
    @AuraEnabled
    public static FromJSON getSites() {
        String endpoint = '/v1.0/sites?search=*';
        return sendRequest(endpoint);
    }

    /**
     * @description Fetches all document drives belonging to a specific SharePoint site.
     * @param siteId The unique identifier of the SharePoint site whose drives must be retrieved.
     * @return A FromJSON object containing drive metadata, including drive IDs and URLs.
     */
    @AuraEnabled
    public static FromJSON getDrives(String siteId) {
        String endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives';
        return sendRequest(endpoint);
    }

    /**
     * @description Fetches the root-level folder items from a specific drive inside a SharePoint site.
     * @param siteId The SharePoint site identifier.
     * @param driveId The drive identifier inside the SharePoint site.
     * @return A FromJSON object containing folder items and paging information.
     */
    @AuraEnabled
    public static FromJSON getFolders(String siteId, String driveId) {
        String endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/items/root/children';
        return sendRequest(endpoint);
    }

    /**
     * @description Fetches files and folders inside a given folder.
     * @param folderId The folder identifier whose child items need to be retrieved.
     * @param siteId The ID of the SharePoint site that contains the folder.
     * @param driveId The ID of the drive inside the site where the folder resides.
     * @return A FromJSON structure containing file/folder metadata and nextLink for pagination.
     */
    @AuraEnabled
    public static FromJSON getFiles(String folderId, String siteId, String driveId) { // NOPMD:ExcessiveParameterList
        String endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/items/' + EncodingUtil.urlEncode(folderId, 'UTF-8') + '/children';
        return sendRequest(endpoint);
    }

    /**
     * @description Creates an upload session for large file uploads using Microsoft Graph.
     * @param siteId The ID of the SharePoint site where the file will be uploaded.
     * @param driveId The ID of the drive where the file will be uploaded.
     * @param folderId The ID of the parent folder; if blank, file uploads to drive root.
     * @param fileName The name of the file being uploaded.
     * @return A JSON string containing an uploadUrl used for chunk upload operations.
     */
    @AuraEnabled
    public static String createUploadSession(String siteId, String driveId, String folderId, String fileName) { // NOPMD:ExcessiveParameterList
        try {
            String encodedFileName = EncodingUtil.urlEncode(fileName, 'UTF-8').replace('+', '%20');

            String endpoint;
            if (String.isBlank(folderId)) {
                endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/root:/' + encodedFileName + ':/createUploadSession';
            } else {
                endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/items/' + EncodingUtil.urlEncode(folderId, 'UTF-8') + ':/' + encodedFileName + ':/createUploadSession';
            }

            Map<String, Object> requestBody = new Map<String, Object>{
                'item' => new Map<String, Object>{
                    '@microsoft.graph.conflictBehavior' => 'rename'
                }
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:nsiqspconn__NamedCredMicroAccessControl' + endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(requestBody));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                return res.getBody();
            } else {
                throw new CalloutException('Error creating upload session: ' + res.getStatus());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error creating upload session: ' + e.getMessage());
        }
    }

    /**
     * @description Uploads a file chunk to an existing upload session.
     * @param uploadUrl The Graph API upload session URL returned by createUploadSession.
     * @param base64Data Base64-encoded chunk of the file to upload.
     * @param startByte Starting byte index of the chunk.
     * @param endByte Ending byte index of the chunk (inclusive).
     * @param totalSize Total size of the file being uploaded.
     * @return JSON response body for completed upload or intermediate chunk metadata.
     */
    @AuraEnabled
    public static String uploadChunk(String uploadUrl, String base64Data, Integer startByte, Integer endByte, Integer totalSize) { // NOPMD:ExcessiveParameterList
        try {
            Blob chunkBlob = EncodingUtil.base64Decode(base64Data);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(uploadUrl);
            req.setMethod('PUT');
            req.setHeader('Content-Type', 'application/octet-stream');
            req.setHeader('Content-Range', 'bytes ' + startByte + '-' + endByte + '/' + totalSize);
            req.setBodyAsBlob(chunkBlob);
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (endByte == totalSize - 1) {
                if (res.getStatusCode() == 201 || res.getStatusCode() == 200) {
                    return res.getBody();
                } else {
                    throw new CalloutException('Final chunk upload error: ' + res.getStatus());
                }
            } else if (res.getStatusCode() != 202) {
                throw new CalloutException('Chunk upload error: ' + res.getStatus());
            }

            return res.getBody();
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading chunk: ' + e.getMessage());
        }
    }

    /**
     * @description Uploads a small (<=6MB) file directly to SharePoint without chunking.
     * @param siteId The site identifier where the file is stored.
     * @param driveId The drive identifier inside the site.
     * @param folderId The folder identifier; blank indicates root folder.
     * @param fileName The file name including extension.
     * @param contentType MIME type of the file (e.g., text/plain, image/png).
     * @param base64Data Base64-encoded complete file content.
     * @return A JSON response returned by the SharePoint upload API.
     */
    @AuraEnabled
    public static String uploadFileToSharePoint(String siteId, String driveId, String folderId, String fileName, String contentType, String base64Data) { // NOPMD:ExcessiveParameterList
        try {
            String endpoint;
            if (String.isBlank(folderId)) {
                endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/root:/' + EncodingUtil.urlEncode(fileName, 'UTF-8') + ':/content';
            } else {
                endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/items/' + EncodingUtil.urlEncode(folderId, 'UTF-8') + ':/' + EncodingUtil.urlEncode(fileName, 'UTF-8') + ':/content';
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:nsiqspconn__NamedCredMicroAccessControl' + endpoint);
            req.setMethod('PUT');
            req.setHeader('Content-Type', contentType);
            req.setHeader('X-File-Name', fileName);

            Blob fileBlob = EncodingUtil.base64Decode(base64Data);
            if (fileBlob.size() > 6000000) {
                throw new CalloutException('File size exceeds 6MB limit');
            }

            req.setBodyAsBlob(fileBlob);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                return res.getBody();
            } else {
                throw new CalloutException('Upload error: ' + res.getStatus());
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }

        /**
     * @description Creates a new folder inside a specified SharePoint drive or folder.
     * @param siteId The SharePoint site identifier.
     * @param driveId The drive identifier where the folder is to be created.
     * @param parentFolderId The ID of the parent folder; use "root" for the drive root.
     * @param folderName The name of the new folder to create.
     * @return JSON metadata of the created folder including its ID and URL.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static String createFolderInSharePoint(String siteId, String driveId, String parentFolderId, String folderName) 
        // NOPMD:ExcessiveParameterList
    {
        try {
            String endpoint;
            if (parentFolderId == 'root') {
                endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/root/children';
            } else {
                endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/items/' + EncodingUtil.urlEncode(parentFolderId, 'UTF-8') + '/children';
            }

            Map<String, Object> requestBody = new Map<String, Object>{
                'name' => folderName,
                'folder' => new Map<String, Object>(),
                '@microsoft.graph.conflictBehavior' => 'rename'
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:nsiqspconn__NamedCredMicroAccessControl' + endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(requestBody));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 201) {
                return res.getBody();
            } else {
                throw new CalloutException('Folder creation failed: ' + res.getStatus());
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error creating folder: ' + e.getMessage());
        }
    }

    /**
     * @description Deletes a file from a SharePoint drive using its file ID.
     * @param siteId The SharePoint site identifier.
     * @param driveId The drive identifier that contains the file.
     * @param fileId The identifier of the file to delete.
     * @return true if deletion succeeded; false is never returned because failures throw exceptions.
     */
    @AuraEnabled
    public static Boolean deleteFileFromSharePoint(String siteId, String driveId, String fileId) {
        try {
            String endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/items/' + EncodingUtil.urlEncode(fileId, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:nsiqspconn__NamedCredMicroAccessControl' + endpoint);
            req.setMethod('DELETE');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 204) {
                return true;
            } else {
                throw new CalloutException('Delete failed: ' + res.getStatus());
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error deleting file: ' + e.getMessage());
        }
    }

    /**
     * @description Renames a file or folder inside a SharePoint drive.
     * @param siteId The identifier of the SharePoint site that contains the item.
     * @param driveId The identifier of the drive where the item resides.
     * @param itemId The file or folder ID that should be renamed.
     * @param newName The new name that should be applied to the item.
     * @return JSON metadata of the renamed item.
     */
    @AuraEnabled
    public static String renameItemInSharePoint(String siteId, String driveId, String itemId, String newName) { // NOPMD:ExcessiveParameterList
        try {
            String endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') + '/items/' + EncodingUtil.urlEncode(itemId, 'UTF-8');

            Map<String, Object> requestBody = new Map<String, Object>{
                'name' => newName,
                '@microsoft.graph.conflictBehavior' => 'rename'
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:nsiqspconn__NamedCredMicroAccessControl' + endpoint);
            req.setMethod('PATCH');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(requestBody));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                return res.getBody();
            } else {
                throw new CalloutException('Rename failed: ' + res.getStatus());
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error renaming item: ' + e.getMessage());
        }
    }

    /**
     * @description Performs a global free-text search within a drive.
     * @param siteId The SharePoint site identifier.
     * @param driveId The drive where the search operation should be executed.
     * @param globalSearchValue The string to search for inside files and folders.
     * @return A FromJSON containing all matches returned by the Microsoft Graph search API.
     */
    @AuraEnabled(cacheable=true)
    public static FromJSON globalSearch(String siteId, String driveId, String globalSearchValue) {
       String endpoint = '/v1.0/sites/' + EncodingUtil.urlEncode(siteId, 'UTF-8') + '/drives/' + EncodingUtil.urlEncode(driveId, 'UTF-8') +
                         '/items/root/search(q=\'' + EncodingUtil.urlEncode(globalSearchValue, 'UTF-8') + '\')';
       return sendRequest(endpoint);
    }

    /**
     * @description Sends a generic GET request to the Microsoft Graph API.
     * @param endpoint A relative Graph API endpoint beginning with /v1.0.
     * @return A FromJSON representation containing Graph API results and paging info.
     */
    private static FromJSON sendRequest(String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:nsiqspconn__NamedCredMicroAccessControl' + endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept','*/*');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            FromJSON respValue = (FromJSON) JSON.deserialize(
                res.getBody()
                    .replaceAll('@microsoft.graph.downloadUrl','downloadUrl')
                    .replaceAll('@odata.nextLink','nextUrl'),
                FromJSON.class
            );
            return respValue.value == null ? null : respValue;
        } else {
            throw new CalloutException('Failed to fetch data: ' + res.getStatus());
        }
    }

    /**
     * @description Loads the next page of results for paginated Graph API responses.
     * @param endpoint The nextLink URL returned by Graph API; the method normalizes domain info.
     * @return A FromJSON object containing the next page of Graph API items.
     */
    @AuraEnabled
    public static FromJSON loadMoreSendRequest(String endpoint) {
        HttpRequest req = new HttpRequest();
        endpoint = endpoint.replaceAll('https://graph.microsoft.com', '');
        req.setEndpoint('callout:nsiqspconn__NamedCredMicroAccessControl' + endpoint);
        req.setMethod('GET');
        req.setHeader('Accept','*/*');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            FromJSON respValue = (FromJSON) JSON.deserialize(
                res.getBody()
                    .replaceAll('@microsoft.graph.downloadUrl','downloadUrl')
                    .replaceAll('@odata.nextLink','nextUrl'),
                FromJSON.class
            );
            return respValue.value == null ? null : respValue;
        } else {
            throw new CalloutException('Next page request failed: ' + res.getStatus());
        }
    }

    /**
     * @description Wrapper structure used for parsing Graph API list responses.
     */
    public class FromJSON {
        @AuraEnabled public String nextUrl;
        @AuraEnabled public FileData[] value;
    }

    /**
     * @description Represents file or folder metadata returned by Graph API.
     */
    public class FileData {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String downloadUrl;
        @AuraEnabled public String webUrl;
        @AuraEnabled public String size;
    }
}