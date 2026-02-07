trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, 
    after insert, after update, after delete, after undelete) {
    Trigger_Settings__c settings = Trigger_Settings__c.getInstance();
    if (settings.Opportunity_Deactivated__c) {
        return;
    }
    new OpportunityTriggerHandler().run();
}