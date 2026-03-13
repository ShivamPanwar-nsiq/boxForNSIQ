public with sharing class BoxController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getBoxItems(String folderId) {

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'callout:Box_API/2.0/folders/' + folderId +
            '/items?fields=name,size,modified_at,type&limit=100'
        );

        req.setMethod('GET');

        HttpResponse res = http.send(req);

        System.debug('BOX LIST STATUS: ' + res.getStatusCode());
        System.debug('BOX LIST RESPONSE: ' + res.getBody());

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

            String type = (String)entry.get('type');
            String id = (String)entry.get('id');

            item.put('id', id);
            item.put('name', (String)entry.get('name'));
            item.put('type', type);

            if(entry.containsKey('modified_at')){
                item.put('modified', String.valueOf(entry.get('modified_at')));
            }

            if(type == 'file' && entry.containsKey('size')){

                Decimal bytes = Decimal.valueOf(String.valueOf(entry.get('size')));
                Decimal kb = bytes / 1024;
                Decimal mb = kb / 1024;

                if(mb >= 1){
                    item.put('size', mb.setScale(2) + ' MB');
                }else{
                    item.put('size', kb.setScale(2) + ' KB');
                }

                item.put('url','https://app.box.com/file/' + id);
            }

            items.add(item);
        }

        return items;
    }

}