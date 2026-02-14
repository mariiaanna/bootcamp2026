@isTest
public class CheckPlannedSalesTest  {
    
    @testSetup
    static void setup() {
        Trigger_Settings__c settings = new Trigger_Settings__c();
        settings.Opportunity_Deactivated__c = true;
        settings.Planned_Sales_Deactivated__c = true;
        insert settings;

        Planned_Sales__c ps = new Planned_Sales__c(
            Name = 'Test',
            Month__c = Date.today().addMonths(-1).month(),
            Year__c = Date.today().addMonths(-1).year(),
            Planned_Total_Amount__c = 1000,
            Total_Amount_Earned__c = 500 
        );
        insert ps; 
    }

    @IsTest
    static void testCheckPlannedSalesBatch() {
        Test.startTest();
        Database.executeBatch(new CheckPlannedSalesBatch());
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.Assert.isFalse(jobs.isEmpty(), 'Queueable job should be enqueued by batch');
    }

    @IsTest
    static void testCheckPlannedSalesBatchWithNoRecords() {
        delete [SELECT Id FROM Planned_Sales__c];
        
        Test.startTest();
        Database.executeBatch(new CheckPlannedSalesBatch());
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.Assert.isTrue(jobs.isEmpty(), 'Queueable job should NOT be enqueued when no records');
    }

    @isTest
    static void testCheckPlannedSalesSchedulable() {
        String jobName = 'Test CheckPlannedSalesSchedulable';
        String cronExp = '0 0 0 1 * ?'; 

        Test.startTest();
        System.schedule(jobName, cronExp, new CheckPlannedSalesSchedulable());
        Test.stopTest();

        List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
        System.Assert.isTrue(!cronTriggers.isEmpty(), 'Cron job was not scheduled');
    }

    @IsTest
    static void testCheckPlannedSalesQueueable() {
        List<Planned_Sales__c> plannedSales = [SELECT Id, Name, Planned_Total_Amount__c, Total_Amount_Earned__c FROM Planned_Sales__c];
        
        Test.startTest();
        System.enqueueJob(new CheckPlannedSalesQueueable(plannedSales));
        Test.stopTest();
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.Assert.isFalse(jobs.isEmpty(), 'Queueable job should be enqueued');

    }
}