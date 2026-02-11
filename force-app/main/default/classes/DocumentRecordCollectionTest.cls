@IsTest
public class DocumentRecordCollectionTest {

    @IsTest
    static void testDocuments_withNullId() {
        Test.startTest();
        List<Document__c> docs = DocumentRecordCollection.documents(null);
        Test.stopTest();

        System.assertNotEquals(null, docs, 'Result should not be null');
        System.assertEquals(0, docs.size(), 'No documents expected for null Id');
    }

    @IsTest
    static void testDocuments_forAccount() {
        // Create parent record
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create related document
        Document__c doc = new Document__c(
            Name__c = 'Account Doc',
            Account__c = acc.Id,
            Status__c = 'Document Not Uploaded',
            Document_Uploaded__c = false
        );
        insert doc;

        Test.startTest();
        List<Document__c> docs =
            DocumentRecordCollection.documents(acc.Id);
        Test.stopTest();

        System.assertEquals(1, docs.size(), 'One document should be returned');
        System.assertEquals(
            'Account Doc',
            docs[0].Name__c,
            'Returned document name mismatch'
        );
    }

    @IsTest
    static void testDocuments_forContact() {
        // Create Account
        Account acc = new Account(Name = 'Contact Parent');
        insert acc;

        // Create Contact
        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert con;

        // Create related document
        Document__c doc = new Document__c(
            Name__c = 'Contact Doc',
            Contact__c = con.Id,
            Status__c = 'Document Not Uploaded',
            Document_Uploaded__c = false
        );
        insert doc;

        Test.startTest();
        List<Document__c> docs =
            DocumentRecordCollection.documents(con.Id);
        Test.stopTest();

        System.assertEquals(1, docs.size(), 'One document should be returned');
        System.assertEquals(
            'Contact Doc',
            docs[0].Name__c,
            'Returned document name mismatch'
        );
    }
}