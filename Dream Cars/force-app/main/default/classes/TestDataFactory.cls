@isTest
public class TestDataFactory {
   public static void setupTriggerSettings() {
        Trigger_Settings__c settings = Trigger_Settings__c.getInstance();
        settings.Opportunity_Deactivated__c = false;
        settings.Planned_Sales_Deactivated__c = false;
        upsert settings;
    }
    public static Product2 createProduct(String name, String condition, String brand, String model, String vin, Decimal mileage) {
        Product2 product = new Product2(
            Name = name, 
            IsActive = true, 
            Condition__c = condition,
            Brand__c = brand,           
            Model__c = model,           
            VIN_Number__c = vin,   
            Mileage__c = mileage  
            );
        insert product;
        return product;
    }
    public static Account createAccount(String name) {
    Account account = new Account(
        Name = name,
        BillingStreet = '111 Test Street',
        BillingCity = 'Lviv',
        BillingPostalCode = '79000',
        BillingCountry = 'Ukraine',
        ShippingStreet = '111 Test Street',
        ShippingCity = 'Lviv',
        ShippingPostalCode = '79000',
        ShippingCountry = 'Ukraine'
    );
    insert account;
    return account;
}
    public static Opportunity createOpportunity(String name, Id accountId, Date closeDate) {
        Opportunity opp = new Opportunity(
            Name = name, 
            AccountId = accountId, 
            StageName = 'Prospecting', 
            CloseDate = closeDate
            );
        insert opp;
        return opp; 
    }
    public static Opportunity buildOpportunity(String name, Id accId, Date closeDate) {
        return new Opportunity(
            Name = name,
            AccountId = accId,
            StageName = 'Prospecting',
            CloseDate = closeDate
        );
    }
    public static OpportunityLineItem buildOLI(Id oppId, Id pbeId, Decimal price, Integer quantity) {
        return new OpportunityLineItem(
            OpportunityId = oppId,
            PricebookEntryId = pbeId,
            Quantity = quantity,
            UnitPrice = price
        );
    }
    public static Planned_Sales__c createPlannedSales(String name, Integer year, Integer month, String carType) {
        return new Planned_Sales__c(
            Name = name, 
            Year__c = year, 
            Month__c = month, 
            Car_Type__c = carType
        );
    }
    public static List<OpportunityLineItem> createOLIsBulk(Id oppId, Id prodId, Integer count, Integer qty) {
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prodId, 
            UnitPrice = 1000, 
            IsActive = true
        );
        insert pbe;

        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(Integer i = 0; i < count; i++) {
            oliList.add(new OpportunityLineItem(
                OpportunityId = oppId,
                PricebookEntryId = pbe.Id,
                Quantity = qty, 
                UnitPrice = 1000
            ));
        }
        return oliList;
    }
    public static List<Planned_Sales__c> createPlannedSalesBulk(Integer count, Integer startYear, Integer startMonth, String carType) {
    List<Planned_Sales__c> psList = new List<Planned_Sales__c>();

    for (Integer i = 0; i < count; i++) {
        Integer currentMonth = Math.mod((startMonth - 1 + i), 12) + 1;
        Integer yearOffset = (startMonth - 1 + i) / 12;

        psList.add(new Planned_Sales__c(
            Name = 'Test Stat ' + i,
            Year__c = startYear + yearOffset,
            Month__c = currentMonth,
            Car_Type__c = carType
        ));
    }
    return psList;
    }
}
