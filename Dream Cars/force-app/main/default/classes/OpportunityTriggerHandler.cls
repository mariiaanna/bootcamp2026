public class OpportunityTriggerHandler extends TriggerHandler {
    public override void afterUpdate(){
        Set<Id> changedOppIds = new Set<Id>();
        for (Opportunity opp : (List<Opportunity>) Trigger.new) {
            Opportunity oldOpp = (Opportunity) Trigger.oldMap.get(opp.Id);
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                changedOppIds.add(opp.Id);
            }
        }
        
        if (!changedOppIds.isEmpty()) {
            recalculateStatistics(changedOppIds);
        }
    }
    public override void beforeDelete(){
        Set<Id> deletedOppIds = new Set<Id>();
        for (Opportunity opp : (List<Opportunity>) Trigger.old) {
            if (opp.StageName == 'Closed Won') {
                deletedOppIds.add(opp.Id);
            }
        }

        if (!deletedOppIds.isEmpty()) {
            recalculateStatistics(deletedOppIds);
        }
    }
    private void recalculateStatistics(Set<Id> opportunityIds) {
            try { 
                List<OpportunityLineItem> items = [
                            SELECT Product2.Condition__c, Opportunity.CloseDate 
                            FROM OpportunityLineItem 
                            WHERE OpportunityId IN :opportunityIds
                        ];

                Set<Integer> years = new Set<Integer>();
                Set<Integer> months = new Set<Integer>();
                Set<String> carTypes = new Set<String>();

                for (OpportunityLineItem oli : items) {
                    if (oli.Opportunity.CloseDate != null) {
                        years.add(oli.Opportunity.CloseDate.year());
                        months.add(oli.Opportunity.CloseDate.month());
                        carTypes.add(oli.Product2.Condition__c);
                    }
                }
                if (!years.isEmpty()) {
                    List<Planned_Sales__c> statsToUpdate = [
                        SELECT Year__c, Month__c, Car_Type__c 
                        FROM Planned_Sales__c 
                        WHERE Year__c IN :years 
                        AND Month__c IN :months 
                        AND Car_Type__c IN :carTypes
                    ];

                    if (!statsToUpdate.isEmpty()) {
                        PlannedSalesCalculationService.getSalesData(statsToUpdate);
                        Database.SaveResult[] results = Database.update(statsToUpdate, false, AccessLevel.USER_MODE);
                        for (Integer i = 0; i < results.size(); i++) {
                            if (!results[i].isSuccess()) {
                                for (Database.Error error : results[i].getErrors()) {
                                    System.debug('Error updating Planned_Sales__c record: ' + error.getMessage());
                                }
                            }
                        }
                    } 
                } 
        } catch (Exception e) {
            List<Opportunity> sourceList = (Trigger.new != null) ? (List<Opportunity>)Trigger.new : (List<Opportunity>)Trigger.old;
            for (Opportunity opp : sourceList) {
                opp.addError('Cannot update statistics: ' + e.getMessage());
            } 
        }
    }
}