@isTest
public class PlannedSalesTriggerTest {

    @testSetup
    static void setup() {
        TestDataFactory.setupTriggerSettings();
    }

    @isTest
    public static void PlannedSalesBulkAndActionsTest() {
        Account acc = TestDataFactory.createAccount('Unique Bulk Acc');
        
        Product2 prodNew = TestDataFactory.createProduct('Tesla New', 'New', 'Tesla', 'S', 'VIN-B1', 0);
        Product2 prodUsed = TestDataFactory.createProduct('Tesla Used', 'Used', 'Tesla', '3', 'VIN-B2', 50000);

        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbeNew = new PricebookEntry(Pricebook2Id = pbId, Product2Id = prodNew.Id, UnitPrice = 1000, IsActive = true);
        PricebookEntry pbeUsed = new PricebookEntry(Pricebook2Id = pbId, Product2Id = prodUsed.Id, UnitPrice = 1000, IsActive = true);
        insert new List<PricebookEntry>{pbeNew, pbeUsed};

        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            Integer month = (i < 100) ? 1 : 2;
            oppList.add(new Opportunity(
                Name = 'Bulk Opp ' + i, 
                AccountId = acc.Id, 
                StageName = 'Prospecting', 
                CloseDate = Date.newInstance(2026, month, 15)
            ));
        }
        insert oppList;

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (Integer i = 0; i < 200; i++) {
            olis.add(new OpportunityLineItem(
                OpportunityId = oppList[i].Id, 
                PricebookEntryId = pbeNew.Id, 
                Quantity = 1, 
                UnitPrice = 1000
            ));
        }
        insert olis;

        Trigger_Settings__c settings = Trigger_Settings__c.getOrgDefaults();
        settings.Opportunity_Deactivated__c = true;
        upsert settings;
        for (Opportunity opp : oppList) { opp.StageName = 'Closed Won'; }
        update oppList;
        settings.Opportunity_Deactivated__c = false;
        upsert settings;

        List<Planned_Sales__c> psList = TestDataFactory.createPlannedSalesBulk(12, 2026, 1, 'New');
        
        Test.startTest();
        insert psList;
        Test.stopTest();

        Planned_Sales__c checkJan = [SELECT Count_of_Cars_Sold__c FROM Planned_Sales__c 
                                    WHERE Month__c = 1 AND Car_Type__c = 'New' AND Year__c = 2026 LIMIT 1];
        System.assertEquals(100, checkJan.Count_of_Cars_Sold__c, 'Jan count mismatch');

        Planned_Sales__c psToUpdate = [SELECT Id, Car_Type__c FROM Planned_Sales__c WHERE Month__c = 3 LIMIT 1];
        
        psToUpdate.Car_Type__c = 'Used'; 
        psToUpdate.Month__c = 1; 
        update psToUpdate;

        Planned_Sales__c updatedRecord = [SELECT Count_of_Cars_Sold__c FROM Planned_Sales__c WHERE Id = :psToUpdate.Id];
        System.assertEquals(0, updatedRecord.Count_of_Cars_Sold__c);

        Planned_Sales__c negativePs = new Planned_Sales__c(Name = 'Future', Year__c = 2030, Month__c = 1, Car_Type__c = 'New');
        insert negativePs;
        System.assertEquals(0, [SELECT Count_of_Cars_Sold__c FROM Planned_Sales__c WHERE Id = :negativePs.Id].Count_of_Cars_Sold__c);
    }
}