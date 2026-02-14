trigger OpportunityProductTrigger on OpportunityLineItem (before insert, before update) {
    new OpportunityProductHandler().run();
}