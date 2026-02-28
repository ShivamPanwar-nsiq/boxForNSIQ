public with sharing class BoxController {
    
     
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getBoxItems(String folderId) {
        
        String accessToken = 'jfDpE2eepdwzFxlG1AkXCBs3dhQs9bmG';

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        //req.setEndpoint('https://api.box.com/2.0/folders/0/items');
        req.setEndpoint('https://api.box.com/2.0/folders/' + folderId + '/items');
        req.setMethod('GET');

        // Access Token Required
        req.setHeader('Authorization','Bearer ' + accessToken);

        HttpResponse res = http.send(req);

        System.debug('Status Code: ' + res.getStatusCode());
        System.debug('Body: ' + res.getBody());

        if(res.getStatusCode() != 200){
            throw new AuraHandledException('Box API Error: ' + res.getBody());
        }

        Map<String,Object> result =
        (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

        List<Object> entries = (List<Object>) result.get('entries');

        List<Map<String,String>> items = new List<Map<String,String>>();

        for(Object obj : entries){

            Map<String,Object> entry = (Map<String,Object>) obj;

            Map<String,String> item = new Map<String,String>();
            item.put('id',(String)entry.get('id'));
            item.put('name',(String)entry.get('name'));
            item.put('type',(String)entry.get('type'));

            items.add(item);
        }

        return items;
    }
}