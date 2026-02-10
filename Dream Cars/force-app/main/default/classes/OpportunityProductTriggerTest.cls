@isTest
public class OpportunityProductTriggerTest {
    @testSetup
    static void setup() {
        TestDataFactory.setupTriggerSettings();
    }
    @isTest
    static void testQuantityValidationOnInsert() {
        Account acc = TestDataFactory.createAccount('Test Account');
        Opportunity opp = TestDataFactory.createOpportunity('Test Opportunity', acc.Id, Date.today().addDays(30));
        Product2 prod = TestDataFactory.createProduct('Test Product', 'New', 'Test Brand', 'Test Model', 'TEST123', 0);
        
        List<OpportunityLineItem> oliList = TestDataFactory.createOLIsBulk(opp.Id, prod.Id, 200, 2);

        Test.startTest();
        insert oliList;
        Test.stopTest();

        List<OpportunityLineItem> res = [SELECT Quantity FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        for(OpportunityLineItem oli : res) {
            System.assertEquals(1.0, oli.Quantity, 'Quantity should be set to 1 for all line items');
        }
        
    }
    @isTest
    static void testQuantityValidationOnUpdate() {
        Account acc = TestDataFactory.createAccount('Test Account');
        Opportunity opp = TestDataFactory.createOpportunity('Test Opportunity', acc.Id, Date.today().addDays(30));
        Product2 prod = TestDataFactory.createProduct('Test Product', 'New', 'Test Brand', 'Test Model', 'TEST123', 0);
        
        List<OpportunityLineItem> oliList = TestDataFactory.createOLIsBulk(opp.Id, prod.Id, 200, 2);
        insert oliList;
        
        for(OpportunityLineItem oli : oliList) {
          oli.Quantity = 2; 
        }

        Test.startTest();
        try {
            update oliList;
            Assert.fail('Should have thrown an error for Quantity update');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Quantity must be equal to 1'), 'Expected validation error');
        }
        Test.stopTest();
    }
} 