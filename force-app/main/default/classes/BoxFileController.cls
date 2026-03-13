public with sharing class BoxFileController {

    @AuraEnabled
    public static String saveBoxFiles(List<Box_File__c> files){

        if(files == null || files.isEmpty()){
            return 'No files selected';
        }

        Id recordId = files[0].Parent_Record__c;

        Set<String> boxIds = new Set<String>();

        for(Box_File__c f : files){
            boxIds.add(f.Box_File_Id__c);
        }

        List<Box_File__c> existingFiles = [
            SELECT Id, Name, Box_File_Id__c
            FROM Box_File__c
            WHERE Parent_Record__c = :recordId
            AND Box_File_Id__c IN :boxIds
        ];

        Set<String> existingIds = new Set<String>();
        List<String> duplicateNames = new List<String>();

        for(Box_File__c bf : existingFiles){
            existingIds.add(bf.Box_File_Id__c);
            duplicateNames.add(bf.Name);
        }

        List<Box_File__c> filesToInsert = new List<Box_File__c>();

        for(Box_File__c f : files){
            if(!existingIds.contains(f.Box_File_Id__c)){
                filesToInsert.add(f);
            }
        }

        if(!filesToInsert.isEmpty()){
            insert filesToInsert;
        }

        if(!duplicateNames.isEmpty()){
            return 'Duplicate skipped: ' + String.join(duplicateNames, ', ');
        }

        return 'Files add successfully';
    }

     @AuraEnabled
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