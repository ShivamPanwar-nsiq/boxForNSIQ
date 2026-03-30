public class BoxAuthService {
    
    @AuraEnabled(cacheable=true)
    public static Boolean isBoxAuthenticated(){

        try{

            Http http = new Http();
            HttpRequest req = new HttpRequest();

            req.setEndpoint('callout:Box_API/2.0/users/me');
            req.setMethod('GET');

            HttpResponse res = http.send(req);

            if(res.getStatusCode() == 200){
                return true;
            }

            return false;

        }catch(Exception e){

            return false;

        }

    }

}