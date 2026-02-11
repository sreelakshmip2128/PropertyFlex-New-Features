/**
 * @module            : Real_Estate_Module
 * @description       : get document records for document checklist lwc page
 * @namespace         :
 * @author            : SREERAM.R
 * @group             : Document Checklist
 * @last modified on  : 05-30-2024
 * @last modified by  : SREERAM.R
 **/
public with sharing class DocumentRecordCollection {
  /**
   * @description get document records for document checklist
   * @param recordId record id of the record page in which component is used
   * @return docs document records
   */
   @AuraEnabled(cacheable = true)
    public static List<Document__c> documents(Id recordId) {
        if (recordId == null) {
            return new List<Document__c>();
        }

        try {
            return getDocumentsForRecord(recordId);
        } catch (Exception e) {
            System.debug('DocumentRecordCollection error: ' + e.getMessage());
            return new List<Document__c>();
        }
    }

    /**
     * @description Dynamically fetch documents related to the given record
     * @param recordId Parent record Id
     * @return List<Document__c>
     */
    private static List<Document__c> getDocumentsForRecord(Id recordId) {

        // Get parent object API name
        String parentObjectApiName = recordId.getSObjectType()
                                             .getDescribe()
                                             .getName();

        // Describe Document__c fields
        Map<String, Schema.SObjectField> documentFields =
            Schema.SObjectType.Document__c.fields.getMap();

        // Collect reference fields pointing to parent object
        List<String> referenceFields = findRelationshipFields(
            parentObjectApiName,
            documentFields
        );

        if (referenceFields.isEmpty()) {
            return new List<Document__c>();
        }

        // Build dynamic WHERE clause
        List<String> whereConditions = new List<String>();
        for (String fieldName : referenceFields) {
            whereConditions.add(fieldName + ' = :recordId');
        }

        String whereClause =
            '(' + String.join(whereConditions, ' OR ') + ')';

        String soql =
            'SELECT Id, Name, Name__c, Expiry_Date__c, ' +
            'Status__c, Document_Uploaded__c ' +
            'FROM Document__c ' +
            'WHERE ' + whereClause + ' ' +
            'WITH USER_MODE';

        return Database.query(soql);
    }

    
    //Find all lookup fields in Document__c referencing the parent object
   
    private static List<String> findRelationshipFields(
        String parentObjectApiName,
        Map<String, Schema.SObjectField> documentFields
    ) {

        List<String> referenceFields = new List<String>();

        for (String fieldName : documentFields.keySet()) {
            Schema.DescribeFieldResult fieldDescribe =
                documentFields.get(fieldName).getDescribe();

            if (fieldDescribe.getType() == Schema.DisplayType.Reference) {
                for (Schema.SObjectType refType : fieldDescribe.getReferenceTo()) {
                    if (refType.getDescribe().getName() == parentObjectApiName) {
                        referenceFields.add(fieldName);
                        break;
                    }
                }
            }
        }

        return referenceFields;
    }
}