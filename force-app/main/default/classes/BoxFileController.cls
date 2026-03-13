public with sharing class BoxFileController {

    @AuraEnabled
    public static void saveBoxFiles(List<Box_File__c> files){

        if(files.isEmpty()){
            return;
        }

        Id recordId = files[0].Parent_Record__c;

        Set<String> boxIds = new Set<String>();

        for(Box_File__c f : files){
            boxIds.add(f.Box_File_Id__c);
        }

        // Check existing files
        List<Box_File__c> existingFiles = [
            SELECT Id, Name, Box_File_Id__c
            FROM Box_File__c
            WHERE Parent_Record__c = :recordId
            AND Box_File_Id__c IN :boxIds
        ];

        if(!existingFiles.isEmpty()){

            List<String> names = new List<String>();

            for(Box_File__c bf : existingFiles){
                names.add(bf.Name);
            }

            throw new AuraHandledException(
                'Duplicate file(s) already exist: ' + String.join(names, ', ')
            );
        }

        insert files;
    }


    @AuraEnabled(cacheable=true)
    public static List<Box_File__c> getBoxFiles(Id recordId){

        return [
            SELECT Id,
                   Name,
                   Box_File_Id__c,
                   File_URL__c,
                   Size__c,
                   Modified_Date__c
            FROM Box_File__c
            WHERE Parent_Record__c = :recordId
            ORDER BY CreatedDate DESC
        ];
    }

}