public class CheckPlannedSalesBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    public List<Planned_Sales__c> recordsToNotify = new List<Planned_Sales__c>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date lastMonthDate = Date.today().addMonths(-1);
        Integer lastMonth = lastMonthDate.month();
        Integer currentYear = lastMonthDate.year();
        
        return Database.getQueryLocator([
            SELECT Id, Planned_Total_Amount__c, Total_Amount_Earned__c, Name 
            FROM Planned_Sales__c 
            WHERE Month__c = :lastMonth 
            AND Year__c = :currentYear
        
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Planned_Sales__c> scope) {
        for (Planned_Sales__c ps : scope) {
            Decimal earned = ps.Total_Amount_Earned__c != null ? ps.Total_Amount_Earned__c : 0;
            Decimal planned = ps.Planned_Total_Amount__c != null ? ps.Planned_Total_Amount__c : 0;
            if (earned < planned) {
                recordsToNotify.add(ps);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!recordsToNotify.isEmpty()) {
            System.enqueueJob(new CheckPlannedSalesQueueable(recordsToNotify));
        }
    }
}