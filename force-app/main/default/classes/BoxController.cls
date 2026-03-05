public with sharing class BoxController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getBoxItems(String folderId) {

        BoxSetting__c boxSetting = BoxSetting__c.getOrgDefaults();
        Http http = new Http();

        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'https://api.box.com/2.0/folders/' + folderId +
            '/items?fields=name,size,modified_at,type'
        );

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

            String type = (String)entry.get('type');
            String id = (String)entry.get('id');

            item.put('id', id);
            item.put('name', (String)entry.get('name'));
            item.put('type', type);

            if(entry.containsKey('modified_at')){
                item.put('modified', String.valueOf(entry.get('modified_at')));
            }

            // FILE SIZE
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

            // FOLDER FILE COUNT
            if(type == 'folder'){

                HttpRequest folderReq = new HttpRequest();

                folderReq.setEndpoint(
                    'https://api.box.com/2.0/folders/' + id +
                    '?fields=item_collection'
                );

                folderReq.setMethod('GET');
                folderReq.setHeader('Authorization','Bearer ' + boxSetting.Access_Token__c);

                HttpResponse folderRes = http.send(folderReq);

                if(folderRes.getStatusCode() == 200){

                    Map<String,Object> folderData =
                    (Map<String,Object>)JSON.deserializeUntyped(folderRes.getBody());

                    if(folderData.containsKey('item_collection')){

                        Map<String,Object> collection =
                        (Map<String,Object>) folderData.get('item_collection');

                        if(collection != null && collection.containsKey('total_count')){

                            Integer total =
                            Integer.valueOf(String.valueOf(collection.get('total_count')));

                            item.put('size', total + ' File' + (total > 1 ? 's' : ''));

                        } else {
                            item.put('size', '0 Files');
                        }

                    } else {
                        item.put('size', '0 Files');
                    }

                } else {
                    item.put('size', '0 Files');
                }
            }

            items.add(item);
        }

        return items;
    }
}