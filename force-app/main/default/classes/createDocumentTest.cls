@IsTest
private class createDocumentTest {

    private static Id createDocumentMaster(Boolean isCustomerRelated,
                                           Boolean validateExpiry) {

        Document_Master__c dm = new Document_Master__c(
            Name = 'DM ' + String.valueOf(Crypto.getRandomLong()),
            Is_Customer_Related__c = isCustomerRelated ? 'Yes' : 'No',
            Validate_expiry_date__c = validateExpiry
        );

        insert dm;
        return dm.Id;
    }

    @TestSetup
    static void setupData() {

        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accts;

        Id dmNoCondition = createDocumentMaster(true, true);
        Id dmWithCondition = createDocumentMaster(false, true);
        Id dmNotRequired = createDocumentMaster(true, false);

        insert new Event_Master__c(
            Name = 'EM Required NoCondition',
            Object__c = 'Account',
            Required__c = true,
            Attachment_Required__c = true,
            Document_Master__c = dmNoCondition
        );

        insert new Event_Master__c(
            Name = 'EM Required WithCondition',
            Object__c = 'Account',
            Required__c = true,
            Attachment_Required__c = false,
            Condition__c = 'Type = Customer',
            Document_Master__c = dmWithCondition
        );

        insert new Event_Master__c(
            Name = 'EM Not Required',
            Object__c = 'Account',
            Required__c = false,
            Attachment_Required__c = true,
            Document_Master__c = dmNotRequired
        );
    }

    @IsTest
    static void testAfterInsertCreatesRequiredDocument() {
        Account acc = new Account(Name = 'Insert Test Account');

        Test.startTest();
        insert acc;
        Test.stopTest();

        List<Document__c> docs = [
            SELECT Id, Name__c, Status__c, Attachment_Required__c
            FROM Document__c
            WHERE Account__c = :acc.Id
        ];

        System.assertEquals(1, docs.size());
        System.assertEquals('Document Not Uploaded', docs[0].Status__c);
    }

    @IsTest
    static void testAfterUpdateConditionMatched() {
        Account acc = new Account(Name = 'Update Condition Test');
        insert acc;

        acc.Type = 'Customer';

        Test.startTest();
        update acc;
        Test.stopTest();

        List<Document__c> docs = [
            SELECT Id, Name__c
            FROM Document__c
            WHERE Account__c = :acc.Id
        ];

        Boolean foundConditionDoc = false;
        for (Document__c d : docs) {
            if (d.Name__c == 'EM Required WithCondition') {
                foundConditionDoc = true;
            }
        }

        System.assert(foundConditionDoc);
    }

    @IsTest
    static void testNotRequiredEventMasterSkipped() {
        Account acc = new Account(Name = 'Not Required Test');
        insert acc;

        Integer cnt = [
            SELECT COUNT()
            FROM Document__c
            WHERE Account__c = :acc.Id
            AND Name__c = 'EM Not Required'
        ];

        System.assertEquals(0, cnt);
    }

    @IsTest
    static void testBulkInsert() {
        List<Account> bulkAccounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            bulkAccounts.add(new Account(Name = 'Bulk Acc ' + i));
        }

        Test.startTest();
        insert bulkAccounts;
        Test.stopTest();

        Integer docCount = [
            SELECT COUNT()
            FROM Document__c
            WHERE Account__c IN :bulkAccounts
        ];

        System.assert(docCount > 0);
    }
}