@isTest
public class OpportunityTriggerTest {
    @testSetup
    static void setup() {
        TestDataFactory.setupTriggerSettings();
        
        Trigger_Settings__c settings = Trigger_Settings__c.getOrgDefaults();
        settings.Planned_Sales_Deactivated__c = true;
        upsert settings;

        Account acc = TestDataFactory.createAccount('Main Test Account');
        
        Product2 car1 = TestDataFactory.createProduct('Toyota Camry', 'New', 'Toyota', 'Camry', 'VIN123', 10);
        Product2 car2 = TestDataFactory.createProduct('Tesla S', 'New', 'Tesla', 'S', 'VIN-BULK', 0);
        
        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = pbId, Product2Id = car1.Id, UnitPrice = 30000, IsActive = true
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = pbId, Product2Id = car2.Id, UnitPrice = 1000, IsActive = true
        );
        insert new List<PricebookEntry>{pbe1, pbe2};

        insert new Planned_Sales__c(
            Name = 'Jan 2026 New Stats',
            Year__c = 2026, Month__c = 1,
            Car_Type__c = 'New',
            Count_of_Cars_Sold__c = 0, Total_Amount_Earned__c = 0
        );

        Opportunity opp1 = TestDataFactory.createOpportunity('Sale Opp 1', acc.Id, Date.today().addDays(30));
        Opportunity opp2 = TestDataFactory.createOpportunity('Sale Opp 2', acc.Id, Date.today().addDays(30));

        insert new List<OpportunityLineItem>{
            TestDataFactory.buildOLI(opp1.Id, pbe1.Id, 30000, 1),
            TestDataFactory.buildOLI(opp2.Id, pbe1.Id, 30000, 1)
        };
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
        for(Opportunity o : opps) { 
            o.StageName = 'Closed Won'; 
        }
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

   
    @isTest
    static void testPositiveStageFlow() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Sale Opp 1' LIMIT 1];
        
        Test.startTest();
        opp.StageName = 'Contract Sent';
        update opp;
        
        Product2 car = [SELECT Car_Status__c, Reserved_for_Opportunity__c FROM Product2 WHERE Name = 'Toyota Camry' LIMIT 1];
        System.assertEquals('Reserved', car.Car_Status__c, 'Car should be reserved');
        System.assertEquals(opp.Id, car.Reserved_for_Opportunity__c, 'Should store Opp Id');

        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        car = [SELECT Car_Status__c, RecordType.DeveloperName FROM Product2 WHERE Name = 'Toyota Camry' LIMIT 1];
        System.assertEquals('Sold', car.Car_Status__c, 'Car should be For Sale');
            System.assertEquals('For_Sale', car.RecordType.DeveloperName, 'Record Type should switch to For Sale');
        }

    @isTest
static void testConflictBlocking() {
    Opportunity opp1 = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Sale Opp 1' LIMIT 1];
    opp1.StageName = 'Contract Sent';
    update opp1;

    Opportunity opp2 = [SELECT Id, StageName, Has_Conflict_Cars__c FROM Opportunity WHERE Name = 'Sale Opp 2' LIMIT 1];
    
    Test.startTest();
    opp2.Description = 'Triggering conflict check'; 
    update opp2;
    Test.stopTest();

    Opportunity updatedOpp2 = [SELECT Has_Conflict_Cars__c FROM Opportunity WHERE Id = :opp2.Id];
    System.assertEquals(true, updatedOpp2.Has_Conflict_Cars__c, 'Has_Conflict_Cars__c should be true when car is reserved elsewhere');
}

    @isTest
    static void testQuantityRestriction() {
        OpportunityLineItem oli = [SELECT Id, Quantity FROM OpportunityLineItem LIMIT 1];
        
        Test.startTest();
        oli.Quantity = 5;
        try {
            update oli;
            System.assert(false, 'Should have blocked quantity change');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Quantity must be equal to 1'), 'Error message mismatch');
        }
        Test.stopTest();
    }

    @isTest
    static void testBulkStageUpdate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 bulkCar = TestDataFactory.createProduct('Bulk Car', 'New', 'Ford', 'F150', 'VIN-111', 0);
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = bulkCar.Id, UnitPrice = 50000, IsActive = true);
        insert pbe;

        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i=0; i<20; i++) {
            opps.add(TestDataFactory.buildOpportunity('Bulk Opp ' + i, acc.Id, Date.today()));
        }
        insert opps;

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for(Opportunity o : opps) {
            olis.add(TestDataFactory.buildOLI(o.Id, pbe.Id, 50000, 1));
        }
        insert olis;

        Test.startTest();
        for(Opportunity o : opps) { o.StageName = 'Contract Sent'; }
        update opps;
        Test.stopTest();

        Product2 updatedCar = [SELECT Car_Status__c FROM Product2 WHERE Id = :bulkCar.Id];
        System.assertEquals('Reserved', updatedCar.Car_Status__c);
    }

    @isTest
    static void testRollbackToAvailable() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Sale Opp 1' LIMIT 1];
        
        opp.StageName = 'Contract Sent';
        update opp;

        Test.startTest();
        opp.StageName = 'Prospecting';
        update opp;
        Test.stopTest();

        Product2 car = [SELECT Car_Status__c, Reserved_for_Opportunity__c FROM Product2 WHERE Name = 'Toyota Camry' LIMIT 1];
        System.assertEquals('Available', car.Car_Status__c, 'Should be back to Available');
        System.assertEquals(null, car.Reserved_for_Opportunity__c, 'Lookup should be cleared');
    }
}