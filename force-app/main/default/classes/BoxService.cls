public with sharing class BoxService {
    
    // Base URL for Box API
    public static final String BOX_BASE_URL = 'https://api.box.com/2.0/';

    // Folder APIs
    public static final String GET_FOLDER = 'folders/';
    public static final String GET_FOLDER_ITEMS = '/items';
    
    public static final String GET_METHOD = 'GET';


    /*
     * Method: isBoxAuthenticated
     *
     * Purpose:
     * This method checks whether the Box integration authentication
     * is valid using the Named Credential (Box_API).
     *
     * API Used:
     * GET /2.0/users/me
     *
     * What it does:
     * - Calls the Box API endpoint that returns information about
     *   the currently authenticated Box user.
     * - If the API returns HTTP Status 200, authentication is valid.
     * - If the call fails (401 / 403 / exception), authentication
     *   is considered invalid or expired.
     *
     * Used By:
     * LWC component (boxDocumentManager) to verify authentication
     * before allowing users to upload or select files from Box.
     *
     */

    @AuraEnabled(cacheable=true)
    public static Boolean isBoxAuthenticated(){

        try{

            Http http = new Http();
            HttpRequest req = new HttpRequest();

            // Box API endpoint to get current authenticated user
            req.setEndpoint('callout:Box_API/2.0/users/me');

            req.setMethod('GET');

            HttpResponse res = http.send(req);

            // If API returns success, authentication is valid
            if(res.getStatusCode() == 200){
                return true;
            }

            return false;

        }
        catch(Exception e){

            System.debug('Box Authentication Error: ' + e.getMessage());

            return false;
        }

    }

}