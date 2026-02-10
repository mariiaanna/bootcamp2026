@isTest
public class OpportunityTriggerTest {
    @testSetup
    static void setup() {
        TestDataFactory.setupTriggerSettings();
        
        Trigger_Settings__c settings = Trigger_Settings__c.getOrgDefaults();
        settings.Planned_Sales_Deactivated__c = true;
        upsert settings;

        Account acc = TestDataFactory.createAccount('Bulk Trigger Acc');
        Product2 prod = TestDataFactory.createProduct('Tesla S', 'New', 'Tesla', 'S', 'VIN-BULK', 0);
        
        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pbId, Product2Id = prod.Id, 
            UnitPrice = 1000, IsActive = true
        );
        insert pbe;

        insert new Planned_Sales__c(
            Name = 'Jan 2026 New Stats',
            Year__c = 2026, Month__c = 1,
            Car_Type__c = 'New',
            Count_of_Cars_Sold__c = 0, Total_Amount_Earned__c = 0
        );
    }

    @isTest
    static void testBulkOpportunityClosedWonRecalculatesStats() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 0; i < 200; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + i, 
                AccountId = acc.Id, 
                StageName = 'Prospecting', 
                CloseDate = Date.newInstance(2026, 1, 15)
            ));
        }
        insert opps; 

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for(Opportunity o : opps) {
            olis.add(new OpportunityLineItem(
                OpportunityId = o.Id, PricebookEntryId = pbe.Id, 
                Quantity = 1, UnitPrice = 1000
            ));
        }
        insert olis;

        Test.startTest();
        for(Opportunity o : opps) { o.StageName = 'Closed Won'; }
        update opps;
        Test.stopTest();

        Planned_Sales__c ps = [SELECT Count_of_Cars_Sold__c FROM Planned_Sales__c WHERE Month__c = 1 LIMIT 1];
        System.assertEquals(200, ps.Count_of_Cars_Sold__c);
    }

    @isTest
    static void testBulkOpportunityDeleteRecalculatesStats() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        Trigger_Settings__c settings = Trigger_Settings__c.getOrgDefaults();
        settings.Opportunity_Deactivated__c = true;
        update settings;

        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 0; i < 50; i++) {
            opps.add(new Opportunity(
                Name = 'Delete Bulk ' + i, AccountId = acc.Id, 
                StageName = 'Closed Won', CloseDate = Date.newInstance(2026, 1, 15)
            ));
        }
        insert opps;

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for(Opportunity o : opps) {
            olis.add(new OpportunityLineItem(OpportunityId = o.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 1000));
        }
        insert olis;

        settings.Opportunity_Deactivated__c = false;
        update settings;

        List<Planned_Sales__c> psToPrepare = [SELECT Id, Year__c, Month__c, Car_Type__c FROM Planned_Sales__c WHERE Month__c = 1];
        PlannedSalesCalculationService.getSalesData(psToPrepare);
        update psToPrepare;

        Test.startTest();
        delete opps;
        Test.stopTest();

        Planned_Sales__c ps = [SELECT Count_of_Cars_Sold__c FROM Planned_Sales__c WHERE Month__c = 1 LIMIT 1];
        System.assertEquals(0, ps.Count_of_Cars_Sold__c);
    }
}