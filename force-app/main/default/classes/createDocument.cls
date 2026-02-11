public with sharing class createDocument implements TriggerAction.AfterInsert, 

                                          TriggerAction.AfterUpdate

                                          {

    

    // AFTER INSERT 

    public void afterInsert(List<SObject> parentRecords) {

        processDocuments(parentRecords, 'INSERT');

    }

    

    // AFTER UPDATE 

    public void afterUpdate(List<SObject> newRecords, List<SObject> oldRecords) {

        processDocuments(newRecords, 'UPDATE');

    }

    

    // Main processing logic 

    private void processDocuments(List<SObject> parentRecords, String operationType) {

        if (parentRecords == null || parentRecords.isEmpty()) {

            return;

        }



        // Get the object type of the parent record

        String objectType = parentRecords[0].getSObjectType()

                            .getDescribe().getName();

        System.debug('Trigger is on ' + objectType + ' (' + operationType + ')');



        // Get the lookup field name on the document object

        String parentLookupField = getParentLookupField(objectType);

        if (parentLookupField == null) {

            System.debug(

                'No lookup field on Document__c for object ' + objectType

            );

            return;

        }



        // Query event master

        List<Event_Master__c> eventMasters = [

            SELECT Id, Name, Object__c, Document_Master__c, Required__c,

                   Attachment_Required__c, Condition__c,

                   Document_Master__r.Is_Customer_Related__c,

                   Document_Master__r.Validate_expiry_date__c

            FROM Event_Master__c

            WHERE Object__c = :objectType

            WITH USER_MODE

        ];



        Map<Id, Event_Master__c> eventMastersWithConditions =

            new Map<Id, Event_Master__c>();

        Map<Id, Event_Master__c> eventMastersWithoutConditions =

            new Map<Id, Event_Master__c>();

        Set<Event_Master__c> eventMastersToProcess =

            new Set<Event_Master__c>();



        // Event master categorization

        for (Event_Master__c em : eventMasters) {

            if (String.isNotBlank(em.Condition__c)) {

                eventMastersWithConditions.put(em.Id, em);

            } else {

                eventMastersWithoutConditions.put(em.Id, em);

            }

        }



        // Evaluate Conditions

        List<SObject> parentRecordsSatisfyingConditions =

            new List<SObject>();



        // Process conditions with matching records

        for (Event_Master__c em : eventMastersWithConditions.values()) {

            List<String> conditions = em.Condition__c.split(';');



            for (SObject parent : parentRecords) {

                Boolean satisfies = true;



                for (String c : conditions) {

                    List<String> parts = c.split(' = ');

                    if (parts.size() != 2) {

                        satisfies = false;

                        break;

                    }



                    String fieldName = parts[0].trim();

                    String expectedValue = parts[1].trim();

                    Object actualValue = parent.get(fieldName);



                    if (actualValue == null ||

                        String.valueOf(actualValue)

                            .equalsIgnoreCase(expectedValue) == false) {

                        satisfies = false;

                        break;

                    }

                }



                if (satisfies) {

                    parentRecordsSatisfyingConditions.add(parent);

                    eventMastersToProcess.add(em);

                    // PROCESS ALL MATCHES, NO BREAK

                }

            }

        }



        // Process records without conditions

        for (Event_Master__c em : eventMastersWithoutConditions.values()) {

            eventMastersToProcess.add(em);

            parentRecordsSatisfyingConditions.addAll(parentRecords);

        }



        // Prevent Duplicates

        Map<String, Document__c> uniqueDocs =

            new Map<String, Document__c>();



        // Create document logic

        for (Event_Master__c em : eventMastersToProcess) {

            if (!em.Required__c || em.Document_Master__c == null) {

                continue;

            }



            for (SObject parent : parentRecordsSatisfyingConditions) {

                String key = parent.Id + '-' + em.Id;

                if (uniqueDocs.containsKey(key)) {

                    continue;

                }



                Document__c doc = new Document__c();

                doc.put(parentLookupField, parent.Id);



                doc.Document_Master__c = em.Document_Master__c;

                doc.Name__c = em.Name;

                doc.Status__c = 'Document Not Uploaded';

                doc.Is_Customer_Related__c =

                    em.Document_Master__r.Is_Customer_Related__c;

                doc.Attachment_Required__c =

                    em.Attachment_Required__c;

                doc.Expiry_Date_Required__c =

                    em.Document_Master__r.Validate_expiry_date__c;



                uniqueDocs.put(key, doc);

            }

        }



        if (!uniqueDocs.isEmpty()) {

            insert uniqueDocs.values();

        }

    }



    // Helper method to find parent lookup field

    private static String getParentLookupField(String parentObjectApiName) {

        Map<String, Schema.SObjectField> fields =

            Document__c.SObjectType.getDescribe()

                .fields.getMap();



        for (String fieldName : fields.keySet()) {

            Schema.DescribeFieldResult dfr =

                fields.get(fieldName).getDescribe();



            if (dfr.getType() == Schema.DisplayType.Reference) {

                for (Schema.SObjectType ref :

                     dfr.getReferenceTo()) {



                    if (ref != null && ref.getDescribe().getName()

                        == parentObjectApiName) {

                        return fieldName;

                    }

                }

            }

        }

        return null;

    }

}