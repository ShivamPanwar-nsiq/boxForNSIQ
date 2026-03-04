public with sharing class BoxController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getBoxItems(String folderId) {

        BoxSetting__c boxSetting = BoxSetting__c.getOrgDefaults();

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(BoxService.BOX_BASE_URL + BoxService.GET_FOLDER + folderId + BoxService.GET_FOLDER_ITEMS);
        req.setMethod('GET');

        req.setHeader('Authorization','Bearer ' + boxSetting.Access_Token__c);

        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200){
            throw new AuraHandledException(res.getBody());
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

            if((String)entry.get('type') == 'file'){
                item.put('url','https://app.box.com/file/' + (String)entry.get('id'));
            }

            items.add(item);
        }

        return items;
    }
}